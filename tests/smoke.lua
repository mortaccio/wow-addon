-- Minimal WoW API stubs for module smoke testing.
local function hasMask(flags, mask)
    if type(flags) ~= "number" or type(mask) ~= "number" then
        return false
    end
    return (flags % (mask * 2)) >= mask
end

local now = 1000
local currentCLEU = nil
local cooldownInfoBySpell = {}

local units = {
    player = {
        guid = "Player-1",
        class = "PRIEST",
        name = "Self",
        friendly = true,
        role = "HEALER",
        health = 100,
        maxHealth = 100,
    },
    party1 = {
        guid = "Party-1",
        class = "WARRIOR",
        name = "FriendDPS",
        friendly = true,
        role = "DAMAGER",
        health = 90,
        maxHealth = 100,
    },
    arena1 = {
        guid = "Enemy-1",
        class = "MAGE",
        name = "EnemyMage",
        friendly = false,
        role = "DAMAGER",
        health = 80,
        maxHealth = 100,
    },
}

local function makeFontString()
    return {
        SetPoint = function() end,
        SetText = function() end,
        SetWidth = function() end,
        SetJustifyH = function() end,
        SetTextColor = function() end,
    }
end

local function makeTexture()
    local shown = true
    return {
        SetAllPoints = function() end,
        SetTexture = function() end,
        SetPoint = function() end,
        ClearAllPoints = function() end,
        SetSize = function() end,
        SetHeight = function() end,
        SetWidth = function() end,
        SetRotation = function() end,
        SetTexCoord = function() end,
        SetVertexColor = function() end,
        SetAlpha = function() end,
        Hide = function() shown = false end,
        Show = function() shown = true end,
        IsShown = function() return shown end,
    }
end

_G.CreateFrame = function(_, _, _, template)
    local shown = true
    local frame = {
        RegisterEvent = function() end,
        UnregisterEvent = function() end,
        SetScript = function() end,
        SetSize = function() end,
        SetPoint = function() end,
        SetMovable = function() end,
        EnableMouse = function() end,
        RegisterForDrag = function() end,
        StartMoving = function() end,
        StopMovingOrSizing = function() end,
        SetBackdrop = function() end,
        SetBackdropColor = function() end,
        SetBackdropBorderColor = function() end,
        SetStatusBarTexture = function() end,
        SetMinMaxValues = function() end,
        SetValue = function() end,
        SetStatusBarColor = function() end,
        SetHeight = function() end,
        SetWidth = function() end,
        SetAlpha = function() end,
        GetWidth = function() return 252 end,
        GetHeight = function() return 66 end,
        SetText = function() end,
        SetTextColor = function() end,
        SetJustifyH = function() end,
        SetObeyStepOnDrag = function() end,
        SetValueStep = function() end,
        SetMinMaxValues = function() end,
        ClearAllPoints = function() end,
        SetAllPoints = function() end,
        Hide = function() shown = false end,
        Show = function() shown = true end,
        IsShown = function() return shown end,
        CreateFontString = makeFontString,
        CreateTexture = makeTexture,
    }

    if template == "UICheckButtonTemplate" then
        frame.Text = makeFontString()
        frame.GetChecked = function() return false end
        frame.SetChecked = function() end
    end

    if template == "CooldownFrameTemplate" then
        frame.SetCooldown = function() end
    end

    return frame
end

_G.CooldownFrame_Set = function() end
_G.UIParent = {}
_G.RAID_CLASS_COLORS = {
    PRIEST = { r = 1, g = 1, b = 1 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
}

_G.Settings = {
    RegisterCanvasLayoutCategory = function()
        return {
            GetID = function() return 1 end,
        }
    end,
    RegisterAddOnCategory = function() end,
    OpenToCategory = function() end,
}

_G.SlashCmdList = {}
_G.UnitExists = function(unit) return units[unit] ~= nil end
_G.UnitGUID = function(unit) return units[unit] and units[unit].guid or nil end
_G.UnitClass = function(unit)
    local classFile = units[unit] and units[unit].class
    if not classFile then
        return nil, nil
    end
    return classFile, classFile
end
_G.UnitName = function(unit) return units[unit] and units[unit].name or nil end
_G.UnitPlayerControlled = function(unit) return units[unit] ~= nil end
_G.UnitIsFriend = function(_, unit) return units[unit] and units[unit].friendly or false end
_G.UnitGroupRolesAssigned = function(unit) return units[unit] and units[unit].role or "NONE" end
_G.UnitHealth = function(unit) return units[unit] and units[unit].health or 0 end
_G.UnitHealthMax = function(unit) return units[unit] and units[unit].maxHealth or 1 end
_G.UnitCastingInfo = function() return nil end
_G.UnitChannelInfo = function() return nil end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return 0 end
_G.GetNumSubgroupMembers = function() return 1 end
_G.GetSpecialization = function() return 1 end
_G.GetSpecializationRole = function() return "HEALER" end
_G.IsItemInRange = function() return 1 end
_G.CheckInteractDistance = function() return true end
_G.GetSpellBaseCooldown = function(spellID)
    if spellID == 2139 then
        return 24000
    elseif spellID == 336126 then
        return 120000
    end
    return 0
end
_G.GetSpellInfo = function(spellID)
    if spellID == 2139 then
        return "Counterspell", nil, 136122
    elseif spellID == 336126 then
        return "Gladiator's Medallion", nil, 134419
    end
    return "Spell " .. tostring(spellID), nil, 134400
end
_G.GetTime = function() return now end
_G.GetSpellCooldown = function(spellID)
    local info = cooldownInfoBySpell[spellID]
    if info then
        return info.start, info.duration
    end
    return 0, 0
end

_G.LibStub = function(name)
    if name ~= "DRList-1.0" then
        return nil
    end

    return {
        GetCategoryBySpellID = function(_, spellID)
            if spellID == 999001 then
                return "disorient"
            end
            return nil
        end,
        GetResetTime = function(_, category)
            if category == "disorient" then
                return 18
            end
            return nil
        end,
        NextDR = function(_, current, category)
            if category ~= "disorient" then
                return nil
            end
            if current >= 1 then
                return 0.5
            elseif current >= 0.5 then
                return 0.25
            elseif current >= 0.25 then
                return 0
            end
            return 0
        end,
    }
end

_G.COMBATLOG_OBJECT_CONTROL_PLAYER = 0x00000100
_G.COMBATLOG_OBJECT_REACTION_FRIENDLY = 0x00000010
_G.COMBATLOG_OBJECT_REACTION_HOSTILE = 0x00000040
_G.CombatLog_Object_IsA = function(flags, mask)
    return hasMask(flags, mask)
end
_G.CombatLogGetCurrentEventInfo = function()
    local unpackFn = table.unpack or unpack
    if currentCLEU then
        return unpackFn(currentCLEU)
    end
    return nil
end

local addon = {}
local files = {
    "Gladtools/Init.lua",
    "Gladtools/Utils.lua",
    "Gladtools/Config.lua",
    "Gladtools/CooldownData.lua",
    "Gladtools/DRData.lua",
    "Gladtools/Modules/UnitMap.lua",
    "Gladtools/Modules/CooldownTracker.lua",
    "Gladtools/Modules/TrinketTracker.lua",
    "Gladtools/Modules/DRTracker.lua",
    "Gladtools/Modules/Notifications.lua",
    "Gladtools/Modules/NameplateOverlays.lua",
    "Gladtools/Modules/UnitFrames.lua",
    "Gladtools/Modules/CastBars.lua",
    "Gladtools/Modules/PointerSystem.lua",
    "Gladtools/Modules/SettingsUI.lua",
    "Gladtools/Main.lua",
}

for _, filePath in ipairs(files) do
    local chunk, err = loadfile(filePath)
    assert(chunk, err)
    chunk("Gladtools", addon)
end

addon:Startup()

assert(addon.db.selectedPreset == "healer", "default selected preset should be healer")
assert(addon.db.presetState == "healer", "default preset state should be healer")

addon:ApplyPreset("dps")
assert(addon:GetSetting({ "pointers", "mode" }) == addon.POINTER_MODES.HEALERS_ONLY, "dps pointer mode mismatch")

local pointerUnits = addon.UnitMap:GetGroupFriendlyUnits(addon.POINTER_MODES.HEALERS_ONLY)
assert(#pointerUnits == 1 and pointerUnits[1] == "player", "healers-only pointer selection mismatch")

addon:SetSetting({ "pointers", "mode" }, addon.POINTER_MODES.OFF)
assert(addon.db.presetState == "custom", "preset state should become custom after manual change")

addon.UnitMap:RefreshUnit("arena1")
currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    2139,
    "Counterspell",
}
addon.CooldownTracker:HandleCombatLog()
local enemyCDs = addon.CooldownTracker:GetUnitCooldowns("Enemy-1")
assert(#enemyCDs == 1, "expected one enemy cooldown")
assert(enemyCDs[1].spellID == 2139, "expected Counterspell in cooldown list")

addon.CooldownIndexBySpell[900001] = {
    {
        spellID = 900001,
        defaultCD = 45,
        category = "utility",
        priority = 60,
        sourceType = "other",
        classFile = "MAGE",
        bucket = "utility",
        sharedCD = { 900001, 900002 },
    },
}
addon.CooldownIndexBySpell[900002] = {
    {
        spellID = 900002,
        defaultCD = 45,
        category = "utility",
        priority = 60,
        sourceType = "other",
        classFile = "MAGE",
        bucket = "utility",
        sharedCD = { 900001, 900002 },
    },
}
addon.CooldownIndexBySpell[900003] = {
    {
        spellID = 900003,
        defaultCD = 60,
        category = "utility",
        priority = 60,
        sourceType = "other",
        classFile = "MAGE",
        bucket = "utility",
        resetCD = { 2139 },
    },
}

now = now + 1
currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    900001,
    "Shared One",
}
addon.CooldownTracker:HandleCombatLog()

now = now + 1
currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    900002,
    "Shared Two",
}
addon.CooldownTracker:HandleCombatLog()

local sharedCooldownCount = 0
local sharedHasLatest = false
for _, entry in ipairs(addon.CooldownTracker:GetUnitCooldowns("Enemy-1")) do
    if entry.spellID == 900001 or entry.spellID == 900002 then
        sharedCooldownCount = sharedCooldownCount + 1
        sharedHasLatest = sharedHasLatest or entry.spellID == 900002
    end
end
assert(sharedCooldownCount == 1 and sharedHasLatest, "shared cooldown should keep one active shared spell")

now = now + 1
currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    2139,
    "Counterspell",
}
addon.CooldownTracker:HandleCombatLog()

now = now + 1
currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    900003,
    "Reset Spell",
}
addon.CooldownTracker:HandleCombatLog()

local hasCounterspell = false
local hasResetSpell = false
for _, entry in ipairs(addon.CooldownTracker:GetUnitCooldowns("Enemy-1")) do
    hasCounterspell = hasCounterspell or entry.spellID == 2139
    hasResetSpell = hasResetSpell or entry.spellID == 900003
end
assert(hasResetSpell and not hasCounterspell, "reset spell should clear tracked resetCD spells")

currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    336126,
    "Gladiator's Medallion",
}
addon.TrinketTracker:HandleCombatLog()
local trinket = addon.TrinketTracker:GetPrimaryTrinket("Enemy-1")
assert(trinket and trinket.spellID == 336126, "expected tracked trinket cooldown")

now = now + 1
currentCLEU = {
    0,
    "SPELL_CAST_SUCCESS",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    336135,
    "Adaptation",
}
addon.TrinketTracker:HandleCombatLog()

local enemyTrinkets = addon.TrinketTracker:GetUnitTrinkets("Enemy-1")
local sharedTrinketCount = 0
local hasAdaptation = false
for _, entry in ipairs(enemyTrinkets) do
    if entry.spellID == 336126 or entry.spellID == 336135 then
        sharedTrinketCount = sharedTrinketCount + 1
        hasAdaptation = hasAdaptation or entry.spellID == 336135
    end
end
assert(sharedTrinketCount == 1 and hasAdaptation, "shared trinket cooldowns should collapse to one tracked entry")

cooldownInfoBySpell[336126] = { start = now - 0.4, duration = 120 }
now = now + 1
currentCLEU = {
    0,
    "SPELL_AURA_BROKEN_SPELL",
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    0,
    "",
    0,
    "DEBUFF",
    118,
    "Polymorph",
    0,
    "DEBUFF",
}
addon.TrinketTracker:HandleCombatLog()
local localTrinket = addon.TrinketTracker:GetPrimaryTrinket("Player-1")
assert(localTrinket and localTrinket.spellID == 336126, "expected local trinket inferred from cc-break event")
cooldownInfoBySpell[336126] = nil

currentCLEU = {
    0,
    "SPELL_AURA_APPLIED",
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    118,
    "Polymorph",
}
addon.DRTracker:HandleCombatLog()
local drStates = addon.DRTracker:GetUnitDRStates("Enemy-1")
assert(#drStates >= 1, "expected DR state after aura apply")
assert(drStates[1].category == "incap", "expected incap DR category for Polymorph")
assert(drStates[1].level == 1, "expected first DR level after first CC")
assert(drStates[1].isActive == true, "expected DR active while aura is active")

currentCLEU = {
    0,
    "SPELL_AURA_REMOVED",
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    "Enemy-1",
    "EnemyMage",
    COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    118,
    "Polymorph",
}
addon.DRTracker:HandleCombatLog()
local drAfterRemove = addon.DRTracker:GetUnitDRStates("Enemy-1")
assert(#drAfterRemove >= 1, "expected DR state to persist during reset window")
assert(drAfterRemove[1].isActive == false, "expected DR inactive after aura removal")
assert(drAfterRemove[1].resetRemaining > 0, "expected DR timer after aura removal")

now = now + 1
currentCLEU = {
    0,
    "SPELL_AURA_APPLIED",
    0,
    "Player-1",
    "Self",
    COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_FRIENDLY,
    0,
    "Enemy-2",
    "EnemyRogue",
    COMBATLOG_OBJECT_REACTION_HOSTILE,
    0,
    999001,
    "Live DR Spell",
    0,
    "DEBUFF",
}
addon.DRTracker:HandleCombatLog()
local drLive = addon.DRTracker:GetUnitDRStates("Enemy-2")
assert(#drLive >= 1 and drLive[1].category == "incap", "expected live DRList category alias mapping")
assert(drLive[1].resetRemaining >= 17 and drLive[1].resetRemaining <= 18.1, "expected live DRList reset time override")

for _ = 1, addon.COMBAT_LOG_RESTRICTED_SAMPLE_MIN do
    currentCLEU = {
        0,
        "SPELL_AURA_APPLIED",
        0,
        "Enemy-1",
        "EnemyMage",
        COMBATLOG_OBJECT_CONTROL_PLAYER + COMBATLOG_OBJECT_REACTION_HOSTILE,
        0,
        "Player-1",
        "Self",
        COMBATLOG_OBJECT_REACTION_FRIENDLY,
        0,
    }
    addon:ObserveCombatLogSpellData()
end

assert(addon:IsCombatDataRestricted(), "expected combat data restriction auto-detection")
assert(not addon.CooldownTracker:IsEnabled(), "cooldown tracker should pause in restricted mode")
assert(not addon.TrinketTracker:IsEnabled(), "trinket tracker should pause in restricted mode")
assert(not addon.DRTracker:IsEnabled(), "dr tracker should pause in restricted mode")

addon:ResetCombatDataProbe()
assert(not addon:IsCombatDataRestricted(), "combat data restriction should clear on probe reset")

print("Gladtools modular smoke test passed")
