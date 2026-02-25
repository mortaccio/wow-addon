#!/usr/bin/env python3
"""Sync Gladtools cooldown and DR datasets from OmniCD + DRList snapshots.

Usage:
  python3 tools/sync_pvp_data.py \
    --omnicd /tmp/wow_sources/omnicd_retail_latest/OmniCD/Modules/Spells/Spells_Mainline.lua \
    --drlist /tmp/wow_sources/DRList-1.0-latest/DRList-1.0/Spells.lua \
    --outdir Gladtools \
    --as-of 2026-02-25
"""

from __future__ import annotations

import argparse
import datetime as _dt
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple, Union


CLASS_ORDER = [
    "DEATHKNIGHT",
    "DEMONHUNTER",
    "DRUID",
    "EVOKER",
    "HUNTER",
    "MAGE",
    "MONK",
    "PALADIN",
    "PRIEST",
    "ROGUE",
    "SHAMAN",
    "WARLOCK",
    "WARRIOR",
    "GENERIC",
]

BUCKET_ORDER = ["interrupts", "defensives", "offensives", "utility", "trinkets"]

DEFENSIVE_TYPES = {
    "defensive",
    "tankDefensive",
    "raidDefensive",
    "externalDefensive",
    "immunity",
    "counterCC",
    "heal",
}

TYPE_PRIORITY = {
    "interrupt": 100,
    "pvptrinket": 99,
    "trinket": 97,
    "immunity": 96,
    "externalDefensive": 95,
    "raidDefensive": 93,
    "defensive": 92,
    "tankDefensive": 88,
    "counterCC": 86,
    "heal": 84,
    "offensive": 82,
    "aoeCC": 74,
    "cc": 73,
    "disarm": 71,
    "dispel": 70,
    "freedom": 69,
    "racial": 66,
    "raidMovement": 64,
    "movement": 62,
    "other": 60,
    "taunt": 42,
    "consumable": 36,
}

DR_CATEGORY_ALIASES = {
    "stun": "stun",
    "random_stun": "stun",
    "opener_stun": "stun",
    "kidney_shot": "stun",
    "chastise": "stun",
    "counterattack": "stun",
    "charge": "stun",
    "incapacitate": "incap",
    "disorient": "incap",
    "scatter": "incap",
    "cyclone": "incap",
    "mind_control": "incap",
    "bind_elemental": "incap",
    "fear": "fear",
    "horror": "fear",
    "death_coil": "fear",
    "silence": "silence",
    "unstable_affliction": "silence",
    "root": "root",
    "random_root": "root",
    "frost_shock": "root",
    "disarm": "disarm",
    "taunt": "taunt",
    "knockback": "knockback",
}

DR_CATEGORY_ORDER = ["stun", "incap", "fear", "silence", "root", "disarm", "taunt", "knockback"]
DR_CATEGORY_LABELS = {
    "stun": "STN",
    "incap": "INC",
    "fear": "FEA",
    "silence": "SIL",
    "root": "ROT",
    "disarm": "DSM",
    "taunt": "TNT",
    "knockback": "KNO",
}

VALID_SPEC_IDS = {
    62, 63, 64, 65, 66, 70, 71, 72, 73, 102, 103, 104, 105,
    1467, 1468, 1473, 250, 251, 252, 253, 254, 255, 256, 257, 258,
    259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 577, 581,
}

HEALER_SPEC_DURATION_BY_SPEC = {
    65: 90.0,
    105: 90.0,
    256: 90.0,
    257: 90.0,
    264: 90.0,
    270: 90.0,
    1468: 90.0,
}


Scalar = Union[str, int, float, bool, None]
LuaValue = Union[Scalar, Tuple[str, str]]


def _find_matching_brace(text: str, start: int) -> int:
    depth = 0
    i = start
    in_string = False
    escape = False

    while i < len(text):
        ch = text[i]

        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1

    raise ValueError(f"Unclosed brace block starting at {start}")


def _extract_spell_db(text: str) -> str:
    marker = "E.spell_db"
    start_marker = text.find(marker)
    if start_marker < 0:
        raise ValueError("Could not find E.spell_db assignment in OmniCD source")

    brace_start = text.find("{", start_marker)
    if brace_start < 0:
        raise ValueError("Could not find opening brace for E.spell_db")

    brace_end = _find_matching_brace(text, brace_start)
    return text[brace_start : brace_end + 1]


def _extract_class_blocks(spell_db_table: str) -> Dict[str, str]:
    blocks: Dict[str, str] = {}
    for match in re.finditer(r'\["([A-Z]+)"\]\s*=\s*\{', spell_db_table):
        class_name = match.group(1)
        brace_start = match.end() - 1
        brace_end = _find_matching_brace(spell_db_table, brace_start)
        blocks[class_name] = spell_db_table[brace_start : brace_end + 1]
    return blocks


def _extract_top_level_tables(table_body: str) -> List[str]:
    entries: List[str] = []
    i = 0
    n = len(table_body)

    while i < n:
        ch = table_body[i]
        if ch == "{":
            j = _find_matching_brace(table_body, i)
            entries.append(table_body[i : j + 1])
            i = j + 1
            continue
        i += 1

    return entries


def _parse_number_token(token: str) -> Optional[Union[int, float]]:
    token = token.strip()
    if not token:
        return None
    if re.fullmatch(r"-?\d+", token):
        return int(token)
    if re.fullmatch(r"-?\d+\.\d+", token):
        return float(token)
    return None


def _parse_value(raw: str, i: int) -> Tuple[LuaValue, int]:
    n = len(raw)
    while i < n and raw[i] in " \t\r\n":
        i += 1
    if i >= n:
        return None, i

    if raw[i] == '"':
        i += 1
        out: List[str] = []
        escape = False
        while i < n:
            ch = raw[i]
            if escape:
                out.append(ch)
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                i += 1
                break
            else:
                out.append(ch)
            i += 1
        return "".join(out), i

    if raw[i] == "{":
        j = _find_matching_brace(raw, i)
        return ("table", raw[i : j + 1]), j + 1

    j = i
    while j < n and raw[j] not in ",}":
        j += 1
    token = raw[i:j].strip()

    if token == "true":
        return True, j
    if token == "false":
        return False, j
    if token == "nil":
        return None, j

    num = _parse_number_token(token)
    if num is not None:
        return num, j

    return token, j


def _parse_entry(entry_table: str) -> Dict[str, LuaValue]:
    s = entry_table.strip()
    if not (s.startswith("{") and s.endswith("}")):
        raise ValueError("Invalid entry table")

    i = 1
    n = len(s)
    parsed: Dict[str, LuaValue] = {}

    while i < n - 1:
        while i < n - 1 and s[i] in " \t\r\n,":
            i += 1
        if i >= n - 1:
            break
        if s[i] != "[":
            i += 1
            continue

        i += 1
        if i >= n - 1:
            break

        key: Optional[str] = None
        if s[i] == '"':
            i += 1
            key_start = i
            while i < n and s[i] != '"':
                if s[i] == "\\" and i + 1 < n:
                    i += 2
                else:
                    i += 1
            key = s[key_start:i]
            i += 1
        else:
            key_start = i
            while i < n and s[i] != "]":
                i += 1
            key = s[key_start:i].strip()

        while i < n and s[i] != "]":
            i += 1
        i += 1

        while i < n and s[i] in " \t\r\n":
            i += 1
        if i >= n or s[i] != "=":
            continue
        i += 1

        value, i = _parse_value(s, i)
        if key is not None:
            parsed[key] = value

        while i < n and s[i] in " \t\r\n":
            i += 1
        if i < n and s[i] == ",":
            i += 1

    return parsed


def _parse_table_number_map(raw_table: str) -> Tuple[Optional[float], Dict[int, float]]:
    default_value: Optional[float] = None
    by_spec: Dict[int, float] = {}

    m_default = re.search(r'\["default"\]\s*=\s*(-?\d+(?:\.\d+)?)', raw_table)
    if not m_default:
        m_default = re.search(r"\bdefault\s*=\s*(-?\d+(?:\.\d+)?)", raw_table)
    if m_default:
        default_value = float(m_default.group(1))

    for m in re.finditer(r"\[(\d+)\]\s*=\s*(-?\d+(?:\.\d+)?)", raw_table):
        spec_id = int(m.group(1))
        by_spec[spec_id] = float(m.group(2))

    return default_value, by_spec


def _map_type(raw_type: str) -> Tuple[str, str, int]:
    if raw_type == "interrupt":
        return "interrupts", "interrupt", TYPE_PRIORITY[raw_type]
    if raw_type in {"trinket", "pvptrinket"}:
        return "trinkets", "trinket", TYPE_PRIORITY[raw_type]
    if raw_type == "offensive":
        return "offensives", "offensive", TYPE_PRIORITY[raw_type]
    if raw_type in DEFENSIVE_TYPES:
        return "defensives", "defensive", TYPE_PRIORITY.get(raw_type, 80)
    if raw_type == "racial":
        return "utility", "racial", TYPE_PRIORITY[raw_type]
    return "utility", "utility", TYPE_PRIORITY.get(raw_type, 58)


def _normalize_default_cd(duration_val: LuaValue) -> Tuple[float, Dict[int, float]]:
    cooldown_by_spec: Dict[int, float] = {}

    if isinstance(duration_val, (int, float)):
        cd = float(duration_val)
        return (cd if cd > 0 else 0.0), cooldown_by_spec

    if isinstance(duration_val, str) and duration_val == "E.HEALER_SPEC":
        cooldown_by_spec = dict(HEALER_SPEC_DURATION_BY_SPEC)
        return 120.0, cooldown_by_spec

    if isinstance(duration_val, tuple) and duration_val[0] == "table":
        default_cd, by_spec = _parse_table_number_map(duration_val[1])
        if by_spec:
            cooldown_by_spec = {k: float(v) for k, v in by_spec.items() if v > 0}
        if default_cd is not None and default_cd > 0:
            return float(default_cd), cooldown_by_spec
        if cooldown_by_spec:
            return float(max(cooldown_by_spec.values())), cooldown_by_spec

    return 0.0, cooldown_by_spec


def _lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _lua_number(value: Union[int, float]) -> str:
    if isinstance(value, int):
        return str(value)
    if value.is_integer():
        return str(int(value))
    text = f"{value:.3f}".rstrip("0").rstrip(".")
    return text if text else "0"


def _render_lua_dict_int_float(values: Dict[int, float]) -> str:
    items = sorted(values.items(), key=lambda t: t[0])
    body = ", ".join(f"[{k}] = {_lua_number(v)}" for k, v in items)
    return "{ " + body + " }"


def _render_lua_list_int(values: Iterable[int]) -> str:
    body = ", ".join(str(v) for v in values)
    return "{ " + body + " }"


def build_cooldown_data(omnicd_path: Path, as_of: str) -> Tuple[str, Dict[str, int]]:
    src = omnicd_path.read_text(encoding="utf-8")
    table_text = _extract_spell_db(src)
    class_blocks = _extract_class_blocks(table_text)

    cooldown_data: Dict[str, Dict[str, List[Dict[str, object]]]] = {
        class_file: {bucket: [] for bucket in BUCKET_ORDER} for class_file in CLASS_ORDER
    }

    seen = set()
    source_count = 0

    for raw_class, class_block in class_blocks.items():
        body = class_block[1:-1]
        for entry_table in _extract_top_level_tables(body):
            raw = _parse_entry(entry_table)
            spell_id = raw.get("spellID")
            raw_type = raw.get("type")
            if type(spell_id) is not int:
                continue
            if not isinstance(raw_type, str):
                raw_type = "other"

            source_count += 1

            class_file = raw_class
            if class_file in {"TRINKET", "PVPTRINKET", "RACIAL"}:
                class_file = "GENERIC"

            if class_file not in cooldown_data:
                continue

            bucket, category, priority = _map_type(raw_type)

            default_cd, cooldown_by_spec = _normalize_default_cd(raw.get("duration"))

            icon = raw.get("icon")
            if type(icon) is not int:
                icon = None

            name = raw.get("name")
            if not isinstance(name, str):
                name = None

            charges = raw.get("charges")
            max_charges = charges if type(charges) is int and charges > 1 else None

            specs: Optional[List[int]] = None
            spec_val = raw.get("spec")
            if type(spec_val) is int and spec_val in VALID_SPEC_IDS:
                specs = [spec_val]

            dedupe_key = (
                class_file,
                bucket,
                spell_id,
                tuple(specs or ()),
                category,
                raw_type,
            )
            if dedupe_key in seen:
                continue
            seen.add(dedupe_key)

            normalized = {
                "spellID": spell_id,
                "defaultCD": float(default_cd),
                "category": category,
                "priority": int(priority),
                "icon": icon,
                "name": name,
                "sourceType": raw_type,
                "specs": specs,
                "cooldownBySpec": cooldown_by_spec or None,
                "maxCharges": max_charges,
            }

            cooldown_data[class_file][bucket].append(normalized)

    for class_file in CLASS_ORDER:
        for bucket in BUCKET_ORDER:
            cooldown_data[class_file][bucket].sort(
                key=lambda e: (
                    -int(e["priority"]),
                    int(e["spellID"]),
                    (e["specs"] or [0])[0],
                )
            )

    lines: List[str] = []
    lines.append("local _, GT = ...")
    lines.append("")
    lines.append("--[[")
    lines.append("PvP cooldown dataset sync")
    lines.append(f"Source: OmniCD Retail Spells_Mainline.lua")
    lines.append(f"Snapshot date: {as_of}")
    lines.append("Normalization:")
    lines.append("- OmniCD types are mapped into Gladtools buckets and categories.")
    lines.append("- Enemy cooldown timers are still event-driven estimates (Blizzard API does not expose enemy cooldowns directly).")
    lines.append("- TODO: Apply talent/spec modifier tables from Modifiers_Mainline.lua when talent certainty is available.")
    lines.append("]]")
    lines.append("")

    lines.append("GT.CooldownData = {")

    total_written = 0
    for class_file in CLASS_ORDER:
        lines.append(f"    {class_file} = {{")
        class_table = cooldown_data[class_file]
        for bucket in BUCKET_ORDER:
            entries = class_table[bucket]
            lines.append(f"        {bucket} = {{")
            for entry in entries:
                parts = [
                    f"spellID = {entry['spellID']}",
                    f"defaultCD = {_lua_number(entry['defaultCD'])}",
                    f"category = {_lua_string(str(entry['category']))}",
                    f"priority = {entry['priority']}",
                ]

                if entry["icon"] is not None:
                    parts.append(f"icon = {entry['icon']}")
                if entry["name"]:
                    parts.append(f"name = {_lua_string(str(entry['name']))}")
                parts.append(f"sourceType = {_lua_string(str(entry['sourceType']))}")
                if entry["specs"]:
                    parts.append(f"specs = {_render_lua_list_int(entry['specs'])}")
                if entry["cooldownBySpec"]:
                    parts.append(f"cooldownBySpec = {_render_lua_dict_int_float(entry['cooldownBySpec'])}")
                if entry["maxCharges"]:
                    parts.append(f"maxCharges = {entry['maxCharges']}")

                lines.append("            { " + ", ".join(parts) + " },")
                total_written += 1
            lines.append("        },")
        lines.append("    },")

    lines.append("}")
    lines.append("")
    lines.append("GT.CooldownIndexBySpell = {}")
    lines.append("GT.TrinketIndexBySpell = {}")
    lines.append("")
    lines.append("local INDEX_CLASS_ORDER = { " + ", ".join(_lua_string(c) for c in CLASS_ORDER) + " }")
    lines.append("local INDEX_BUCKET_ORDER = { \"interrupts\", \"defensives\", \"offensives\", \"utility\", \"trinkets\" }")
    lines.append("")
    lines.append("local function normalizeSpecData(entry)")
    lines.append("    local specs = entry.specs")
    lines.append("    if type(specs) ~= \"table\" or #specs == 0 then")
    lines.append("        entry.specLookup = nil")
    lines.append("        entry.specID = nil")
    lines.append("        return")
    lines.append("    end")
    lines.append("")
    lines.append("    local lookup = {}")
    lines.append("    local uniqueCount = 0")
    lines.append("    local onlySpecID = nil")
    lines.append("    for _, specID in ipairs(specs) do")
    lines.append("        if type(specID) == \"number\" and specID > 0 and not lookup[specID] then")
    lines.append("            lookup[specID] = true")
    lines.append("            uniqueCount = uniqueCount + 1")
    lines.append("            onlySpecID = specID")
    lines.append("        end")
    lines.append("    end")
    lines.append("")
    lines.append("    entry.specLookup = next(lookup) and lookup or nil")
    lines.append("    if uniqueCount == 1 then")
    lines.append("        entry.specID = onlySpecID")
    lines.append("    else")
    lines.append("        entry.specID = nil")
    lines.append("    end")
    lines.append("end")
    lines.append("")
    lines.append("local function addIndexedEntry(indexTable, spellID, entry)")
    lines.append("    if not spellID then")
    lines.append("        return")
    lines.append("    end")
    lines.append("")
    lines.append("    local list = indexTable[spellID]")
    lines.append("    if not list then")
    lines.append("        list = {}")
    lines.append("        indexTable[spellID] = list")
    lines.append("    end")
    lines.append("")
    lines.append("    list[#list + 1] = entry")
    lines.append("end")
    lines.append("")
    lines.append("for _, classFile in ipairs(INDEX_CLASS_ORDER) do")
    lines.append("    local buckets = GT.CooldownData[classFile]")
    lines.append("    if buckets then")
    lines.append("        for _, bucketName in ipairs(INDEX_BUCKET_ORDER) do")
    lines.append("            local entries = buckets[bucketName]")
    lines.append("            if entries then")
    lines.append("                for _, entry in ipairs(entries) do")
    lines.append("                    entry.classFile = classFile")
    lines.append("                    entry.bucket = bucketName")
    lines.append("                    normalizeSpecData(entry)")
    lines.append("")
    lines.append("                    addIndexedEntry(GT.CooldownIndexBySpell, entry.spellID, entry)")
    lines.append("                    if bucketName == \"trinkets\" or entry.category == \"trinket\" then")
    lines.append("                        addIndexedEntry(GT.TrinketIndexBySpell, entry.spellID, entry)")
    lines.append("                    end")
    lines.append("                end")
    lines.append("            end")
    lines.append("        end")
    lines.append("    end")
    lines.append("end")
    lines.append("")
    lines.append("local function selectEntry(entries, classFile, specID)")
    lines.append("    if type(entries) ~= \"table\" then")
    lines.append("        return nil")
    lines.append("    end")
    lines.append("")
    lines.append("    local classFallback = nil")
    lines.append("    local genericFallback = nil")
    lines.append("")
    lines.append("    for _, entry in ipairs(entries) do")
    lines.append("        if classFile and entry.classFile == classFile then")
    lines.append("            if specID and entry.specLookup then")
    lines.append("                if entry.specLookup[specID] then")
    lines.append("                    return entry")
    lines.append("                end")
    lines.append("            elseif not entry.specLookup then")
    lines.append("                classFallback = classFallback or entry")
    lines.append("            elseif not specID then")
    lines.append("                classFallback = classFallback or entry")
    lines.append("            end")
    lines.append("        elseif entry.classFile == \"GENERIC\" then")
    lines.append("            genericFallback = genericFallback or entry")
    lines.append("        end")
    lines.append("    end")
    lines.append("")
    lines.append("    if classFallback then")
    lines.append("        return classFallback")
    lines.append("    end")
    lines.append("")
    lines.append("    return genericFallback or entries[1]")
    lines.append("end")
    lines.append("")
    lines.append("function GT:GetCooldownEntryForSpell(spellID, classFile, specID)")
    lines.append("    local entries = self.CooldownIndexBySpell[spellID]")
    lines.append("    return selectEntry(entries, classFile, specID)")
    lines.append("end")
    lines.append("")
    lines.append("function GT:GetTrinketEntryForSpell(spellID, classFile, specID)")
    lines.append("    local entries = self.TrinketIndexBySpell[spellID]")
    lines.append("    return selectEntry(entries, classFile, specID)")
    lines.append("end")

    stats = {
        "source_entries": source_count,
        "written_entries": total_written,
    }
    return "\n".join(lines) + "\n", stats


def _extract_retail_dr_block(dr_text: str) -> str:
    start = dr_text.find('if Lib.gameExpansion == "retail" then')
    if start < 0:
        raise ValueError("Could not locate retail block in DRList Spells.lua")

    start_spell_list = dr_text.find("Lib.spellList", start)
    if start_spell_list < 0:
        raise ValueError("Could not locate Lib.spellList assignment in retail block")

    brace_start = dr_text.find("{", start_spell_list)
    if brace_start < 0:
        raise ValueError("Could not locate opening spell list brace")

    brace_end = _find_matching_brace(dr_text, brace_start)
    return dr_text[brace_start + 1 : brace_end]


def build_dr_data(drlist_path: Path, as_of: str) -> Tuple[str, Dict[str, int]]:
    src = drlist_path.read_text(encoding="utf-8")
    retail_block = _extract_retail_dr_block(src)

    spell_to_raw: Dict[int, str] = {}

    for line in retail_block.splitlines():
        m_simple = re.search(r"\[(\d+)\]\s*=\s*\"([^\"]+)\"", line)
        if m_simple:
            spell_id = int(m_simple.group(1))
            raw_cat = m_simple.group(2)
            spell_to_raw[spell_id] = raw_cat
            continue

        m_multi = re.search(r"\[(\d+)\]\s*=\s*\{\s*\"([^\"]+)\"", line)
        if m_multi:
            spell_id = int(m_multi.group(1))
            raw_cat = m_multi.group(2)
            spell_to_raw[spell_id] = raw_cat

    spell_to_category: Dict[int, str] = {}
    skipped = 0
    for spell_id, raw_category in spell_to_raw.items():
        normalized = DR_CATEGORY_ALIASES.get(raw_category)
        if normalized:
            spell_to_category[spell_id] = normalized
        else:
            skipped += 1

    category_counts: Dict[str, int] = {k: 0 for k in DR_CATEGORY_ORDER}
    for cat in spell_to_category.values():
        category_counts[cat] = category_counts.get(cat, 0) + 1

    lines: List[str] = []
    lines.append("local _, GT = ...")
    lines.append("")
    lines.append("--[[")
    lines.append("PvP DR dataset sync")
    lines.append("Source: DRList-1.0 Retail Spells.lua")
    lines.append(f"Snapshot date: {as_of}")
    lines.append("Normalization:")
    lines.append("- DRList raw categories are mapped to Gladtools categories for consistent UI and alerts.")
    lines.append("- Retail reset/diminish values follow DRList-1.0 defaults as of this snapshot.")
    lines.append("]]")
    lines.append("")

    lines.append("GT.DRData = {")
    lines.append("    source = {")
    lines.append("        provider = \"DRList-1.0\",")
    lines.append(f"        snapshotDate = {_lua_string(as_of)},")
    lines.append("    },")
    lines.append("    resetSeconds = {")
    lines.append("        default = 16.5,")
    lines.append("        knockback = 10.5,")
    lines.append("    },")
    lines.append("    diminished = {")
    lines.append("        default = { 0.50 },")
    lines.append("        taunt = { 0.65, 0.42, 0.27 },")
    lines.append("        knockback = {},")
    lines.append("    },")
    lines.append("    categoryOrder = { " + ", ".join(f'"{c}"' for c in DR_CATEGORY_ORDER) + " },")
    lines.append("    categoryLabels = {")
    for cat in DR_CATEGORY_ORDER:
        lines.append(f"        {cat} = {_lua_string(DR_CATEGORY_LABELS[cat])},")
    lines.append("    },")
    lines.append("    categoryAliases = {")
    for raw_cat in sorted(DR_CATEGORY_ALIASES):
        lines.append(f"        [{_lua_string(raw_cat)}] = {_lua_string(DR_CATEGORY_ALIASES[raw_cat])},")
    lines.append("    },")
    lines.append("    spellToRawCategory = {")
    for spell_id in sorted(spell_to_raw):
        lines.append(f"        [{spell_id}] = {_lua_string(spell_to_raw[spell_id])},")
    lines.append("    },")
    lines.append("    spellToCategory = {")
    for spell_id in sorted(spell_to_category):
        lines.append(f"        [{spell_id}] = {_lua_string(spell_to_category[spell_id])},")
    lines.append("    },")
    lines.append("}")

    stats = {
        "raw_entries": len(spell_to_raw),
        "normalized_entries": len(spell_to_category),
        "skipped_entries": skipped,
    }
    for cat, count in sorted(category_counts.items()):
        stats[f"cat_{cat}"] = count

    return "\n".join(lines) + "\n", stats


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync Gladtools PvP data snapshots")
    parser.add_argument("--omnicd", required=True, type=Path, help="Path to OmniCD Spells_Mainline.lua")
    parser.add_argument("--drlist", required=True, type=Path, help="Path to DRList Spells.lua")
    parser.add_argument("--outdir", required=True, type=Path, help="Addon directory (contains CooldownData.lua)")
    parser.add_argument("--as-of", default=_dt.date.today().isoformat(), help="Snapshot date label YYYY-MM-DD")
    args = parser.parse_args()

    if not args.omnicd.exists():
        print(f"error: OmniCD file not found: {args.omnicd}", file=sys.stderr)
        return 2
    if not args.drlist.exists():
        print(f"error: DRList file not found: {args.drlist}", file=sys.stderr)
        return 2
    if not args.outdir.exists():
        print(f"error: output dir not found: {args.outdir}", file=sys.stderr)
        return 2

    cooldown_lua, cooldown_stats = build_cooldown_data(args.omnicd, args.as_of)
    dr_lua, dr_stats = build_dr_data(args.drlist, args.as_of)

    cooldown_path = args.outdir / "CooldownData.lua"
    dr_path = args.outdir / "DRData.lua"

    cooldown_path.write_text(cooldown_lua, encoding="utf-8")
    dr_path.write_text(dr_lua, encoding="utf-8")

    print(f"Wrote {cooldown_path}")
    print(f"  source entries: {cooldown_stats['source_entries']}")
    print(f"  written entries: {cooldown_stats['written_entries']}")
    print(f"Wrote {dr_path}")
    print(f"  raw entries: {dr_stats['raw_entries']}")
    print(f"  normalized entries: {dr_stats['normalized_entries']}")
    print(f"  skipped entries: {dr_stats['skipped_entries']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
