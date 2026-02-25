-- Minimal WoW API stubs for module smoke testing.
local function hasMask(flags, mask)
    if type(flags) ~= "number" or type(mask) ~= "number" then
        return false
    end
    return (flags % (mask * 2)) >= mask
end

local now = 1000
local currentCLEU = nil

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
    return {
        SetAllPoints = function() end,
        SetTexture = function() end,
        SetPoint = function() end,
        SetSize = function() end,
        SetRotation = function() end,
    }
end

_G.CreateFrame = function(_, _, _, template)
    local shown = true
    local frame = {
        RegisterEvent = function() end,
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
        SetStatusBarTexture = function() end,
        SetMinMaxValues = function() end,
        SetValue = function() end,
        SetStatusBarColor = function() end,
        SetHeight = function() end,
        SetWidth = function() end,
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
    "Gladtools/Modules/UnitMap.lua",
    "Gladtools/Modules/CooldownTracker.lua",
    "Gladtools/Modules/TrinketTracker.lua",
    "Gladtools/Modules/DRTracker.lua",
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

print("Gladtools modular smoke test passed")
