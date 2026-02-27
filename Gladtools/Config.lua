local _, GT = ...

GT.POINTER_MODES = {
    OFF = "off",
    ALL_FRIENDLIES = "all_friendlies",
    HEALERS_ONLY = "healers_only",
}

GT.POINTER_MODE_ORDER = {
    GT.POINTER_MODES.OFF,
    GT.POINTER_MODES.ALL_FRIENDLIES,
    GT.POINTER_MODES.HEALERS_ONLY,
}

GT.POINTER_MODE_LABELS = {
    [GT.POINTER_MODES.OFF] = "Off",
    [GT.POINTER_MODES.ALL_FRIENDLIES] = "All Friendlies",
    [GT.POINTER_MODES.HEALERS_ONLY] = "Healers Only",
}

GT.PRESET_ORDER = {
    "healer",
    "dps",
}

local DEFAULT_RAID_HUD_DEFENSIVE_SPELLS = {
    642,    -- Divine Shield
    871,    -- Shield Wall
    48707,  -- Anti-Magic Shell
    22812,  -- Barkskin
    33206,  -- Pain Suppression
    45438,  -- Ice Block
    47585,  -- Dispersion
    61336,  -- Survival Instincts
    104773, -- Unending Resolve
    108271, -- Astral Shift
    115203, -- Fortifying Brew
    118038, -- Die by the Sword
    186265, -- Aspect of the Turtle
    196555, -- Netherwalk
    198589, -- Blur
    31224,  -- Cloak of Shadows
}

local DEFAULT_RAID_HUD_CC_SPELLS = {
    118,    -- Polymorph
    408,    -- Kidney Shot
    853,    -- Hammer of Justice
    1776,   -- Gouge
    1833,   -- Cheap Shot
    3355,   -- Freezing Trap
    5211,   -- Mighty Bash
    5782,   -- Fear
    8122,   -- Psychic Scream
    33786,  -- Cyclone
    51514,  -- Hex
    108194, -- Asphyxiate
    119381, -- Leg Sweep
    20066,  -- Repentance
    217832, -- Imprison
}

local function createRaidHUDDefaults()
    return {
        enabled = true,
        attachOnlyBlizzard = true,
        cooldowns = {
            enabled = true,
            showEnemy = true,
            showFriendly = true,
            iconSize = 26,
            maxIcons = 3,
            offsetX = 6,
            offsetY = 0,
            defensiveSpells = GT:DeepCopy(DEFAULT_RAID_HUD_DEFENSIVE_SPELLS),
        },
        pointer = {
            enabled = true,
            size = 34,
            offsetX = 0,
            offsetY = 2,
            rotationDegrees = 180,
            fallbackColor = { 0.84, 0.84, 0.86 },
        },
        cc = {
            enabled = true,
            showEnemy = true,
            showFriendly = true,
            iconSize = 22,
            maxIcons = 2,
            anchorSide = "left",
            offsetX = -6,
            offsetY = 0,
            fallbackDuration = 8,
            spells = GT:DeepCopy(DEFAULT_RAID_HUD_CC_SPELLS),
            categories = {
                stun = true,
                incap = true,
                fear = true,
                silence = true,
                root = true,
                disarm = true,
            },
        },
    }
end

GT.PRESETS = {
    healer = {
        label = "Healer",
        settings = {
            enabled = true,
            pointers = {
                mode = GT.POINTER_MODES.ALL_FRIENDLIES,
                size = 22,
            },
            unitFrames = {
                enemy = {
                    enabled = true,
                    fancy = true,
                },
                friendly = {
                    enabled = true,
                    fancy = true,
                    includePlayer = true,
                },
                near = {
                    enabled = true,
                    fancy = true,
                    rangeItem = 34368,
                },
                cooldowns = {
                    enabled = true,
                    iconSize = 22,
                    maxIcons = 5,
                    showEnemy = true,
                    showFriendly = true,
                },
            },
            castBars = {
                enabled = true,
                arena = true,
                friendly = true,
                target = false,
                focus = false,
            },
            dr = {
                enabled = true,
                showOnEnemyFrames = true,
            },
            trinkets = {
                enabled = true,
            },
            notifications = {
                enabled = true,
            },
            nameplates = {
                enabled = true,
                showFriendly = false,
                classColorHealth = true,
                showArenaLabels = true,
                showHealerIcon = true,
                showCCDebuffs = true,
                showPlayerDebuffs = true,
                showCastBars = true,
                showCooldowns = true,
            },
            raidHUD = createRaidHUDDefaults(),
        },
    },
    dps = {
        label = "DPS",
        settings = {
            enabled = true,
            pointers = {
                mode = GT.POINTER_MODES.HEALERS_ONLY,
                size = 22,
            },
            unitFrames = {
                enemy = {
                    enabled = true,
                    fancy = true,
                },
                friendly = {
                    enabled = true,
                    fancy = true,
                    includePlayer = true,
                },
                near = {
                    enabled = false,
                    fancy = true,
                    rangeItem = 34368,
                },
                cooldowns = {
                    enabled = true,
                    iconSize = 22,
                    maxIcons = 5,
                    showEnemy = true,
                    showFriendly = true,
                },
            },
            castBars = {
                enabled = true,
                arena = true,
                friendly = true,
                target = false,
                focus = false,
            },
            dr = {
                enabled = true,
                showOnEnemyFrames = true,
            },
            trinkets = {
                enabled = true,
            },
            notifications = {
                enabled = true,
            },
            nameplates = {
                enabled = true,
                showFriendly = false,
                classColorHealth = true,
                showArenaLabels = true,
                showHealerIcon = true,
                showCCDebuffs = true,
                showPlayerDebuffs = true,
                showCastBars = true,
                showCooldowns = true,
            },
            raidHUD = createRaidHUDDefaults(),
        },
    },
}

GT.DEFAULTS = {
    selectedPreset = "healer",
    presetState = "healer",
    settings = GT:DeepCopy(GT.PRESETS.healer.settings),
}

function GT:GetSetting(path)
    local root = self.db and self.db.settings
    if not root then
        return nil
    end
    
    if type(root) ~= "table" then
        -- Repair corrupted settings
        self.db.settings = {}
        return nil
    end
    
    return self:GetByPath(root, path)
end

function GT:SetSetting(path, value, reason)
    local root = self.db and self.db.settings
    if not root then
        return
    end

    if not self:SetByPath(root, path, value) then
        return
    end

    self:EvaluatePresetState()
    self:OnSettingsChanged(reason or "manual_update")
end

function GT:EvaluatePresetState()
    if not self.db then
        return
    end

    local currentSettings = self.db.settings
    for _, presetKey in ipairs(self.PRESET_ORDER) do
        local preset = self.PRESETS[presetKey]
        if preset and self:TablesEqual(currentSettings, preset.settings) then
            self.db.presetState = presetKey
            return
        end
    end

    self.db.presetState = "custom"
end

function GT:ApplyPreset(presetKey)
    local preset = self.PRESETS[presetKey]
    if not preset then
        self:Print("Unknown preset: " .. tostring(presetKey))
        return false
    end

    self.db.selectedPreset = presetKey
    self.db.presetState = presetKey
    self:MergeOverwrite(self.db.settings, self:DeepCopy(preset.settings))
    self:OnSettingsChanged("preset_apply")
    self:Print("Applied preset: " .. preset.label)
    return true
end

function GT:ResetToSelectedPreset()
    local presetKey = self.db and self.db.selectedPreset
    if not presetKey or not self.PRESETS[presetKey] then
        presetKey = self.DEFAULTS.selectedPreset
    end

    local ok = self:ApplyPreset(presetKey)
    if ok then
        self:Print("Reset to " .. self.PRESETS[presetKey].label .. " defaults")
    end
    return ok
end

function GT:GetPresetStateLabel()
    if not self.db then
        return "Unknown"
    end

    local state = self.db.presetState
    if state == "custom" then
        return "Custom"
    end

    local preset = state and self.PRESETS[state]
    if preset then
        return preset.label
    end

    return "Custom"
end
