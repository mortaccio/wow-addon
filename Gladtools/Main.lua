local ADDON_NAME, GT = ...

local eventFrame = CreateFrame("Frame", "GladtoolsEventFrame")

function GT:InitDB()
    GladToolsDB = GladToolsDB or {}

    self.db = GladToolsDB
    self:MergeDefaults(self.db, self.DEFAULTS)

    if not self.PRESETS[self.db.selectedPreset] then
        self.db.selectedPreset = self.DEFAULTS.selectedPreset
    end

    self:EvaluatePresetState()
end

function GT:OnSettingsChanged(reason)
    self:EvaluatePresetState()
    self:IterateModules("OnSettingsChanged", reason)
end

function GT:PrintHelp()
    self:Print("Commands:")
    self:Print("/gladtools - Open Blizzard settings panel")
    self:Print("/gladtools preset <healer|dps> - Apply preset")
    self:Print("/gladtools resetpreset - Reset to selected preset")
    self:Print("/gladtools pointers <off|all|healers> - Set pointer mode")
    self:Print("/gladtools state - Show current preset state")
    self:Print("/gladtools snapshot - Print live tracker snapshot")
    self:Print("/gladtools help - Show this help")
end

function GT:PrintRuntimeSnapshot()
    local counts = (self.UnitFrames and self.UnitFrames.GetVisibleGroupCounts and self.UnitFrames:GetVisibleGroupCounts()) or {}
    local visibleEnemy = counts.enemy or 0
    local visibleFriendly = counts.friendly or 0
    local visibleNear = counts.near or 0

    local cdTotal, cdFriendly, cdEnemy = 0, 0, 0
    if self.CooldownTracker and self.CooldownTracker.GetActiveCounts then
        cdTotal, cdFriendly, cdEnemy = self.CooldownTracker:GetActiveCounts()
    end

    local trinketTotal, trinketFriendly, trinketEnemy = 0, 0, 0
    if self.TrinketTracker and self.TrinketTracker.GetActiveCounts then
        trinketTotal, trinketFriendly, trinketEnemy = self.TrinketTracker:GetActiveCounts()
    end

    local drTracked, drActive = 0, 0
    if self.DRTracker and self.DRTracker.GetActiveCounts then
        drTracked, drActive = self.DRTracker:GetActiveCounts()
    end

    local activeCasts = self.CastBars and self.CastBars.GetActiveCount and self.CastBars:GetActiveCount() or 0
    local pointerCount = self.PointerSystem and self.PointerSystem.GetVisibleCount and self.PointerSystem:GetVisibleCount() or 0

    self:Print(string.format("Frames E:%d F:%d N:%d | Casts:%d Pointers:%d", visibleEnemy, visibleFriendly, visibleNear, activeCasts, pointerCount))
    self:Print(string.format("Cooldowns: %d (%d enemy / %d friendly) | Trinkets: %d (%d enemy / %d friendly)", cdTotal, cdEnemy, cdFriendly, trinketTotal, trinketEnemy, trinketFriendly))
    self:Print(string.format("DR: %d tracked (%d active)", drTracked, drActive))
end

function GT:SetPointerModeFromSlash(value)
    local lowered = string.lower(value or "")
    local mode = nil

    if lowered == "off" then
        mode = self.POINTER_MODES.OFF
    elseif lowered == "all" or lowered == "all_friendlies" then
        mode = self.POINTER_MODES.ALL_FRIENDLIES
    elseif lowered == "healers" or lowered == "healers_only" then
        mode = self.POINTER_MODES.HEALERS_ONLY
    end

    if not mode then
        self:Print("Usage: /gladtools pointers <off|all|healers>")
        return
    end

    self:SetSetting({ "pointers", "mode" }, mode, "slash_pointer_mode")
    self:Print("Pointer mode: " .. (self.POINTER_MODE_LABELS[mode] or mode))
end

function GT:HandleSlashCommand(message)
    local input = self:Trim(message)
    if input == "" then
        if self.SettingsUI then
            self.SettingsUI:Open()
        end
        return
    end

    local command, rest = input:match("^(%S+)%s*(.-)$")
    command = string.lower(command or "")
    rest = self:Trim(rest)

    if command == "preset" then
        local presetKey = string.lower(rest)
        if presetKey == "" then
            self:Print("Usage: /gladtools preset <healer|dps>")
            return
        end
        self:ApplyPreset(presetKey)
    elseif command == "resetpreset" then
        self:ResetToSelectedPreset()
    elseif command == "pointers" then
        self:SetPointerModeFromSlash(rest)
    elseif command == "snapshot" then
        self:PrintRuntimeSnapshot()
    elseif command == "state" then
        self:Print("Preset state: " .. self:GetPresetStateLabel())
    elseif command == "help" then
        self:PrintHelp()
    else
        self:Print("Unknown command. Use /gladtools help")
    end
end

function GT:RegisterSlashCommands()
    SLASH_GLADTOOLS1 = "/gladtools"
    SLASH_GLADTOOLS2 = "/gt"

    SlashCmdList.GLADTOOLS = function(message)
        GT:HandleSlashCommand(message)
    end
end

function GT:RegisterRuntimeEvents()
    if self.runtimeEventsRegistered then
        return
    end

    local events = {
        "ARENA_OPPONENT_UPDATE",
        "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
        "COMBAT_LOG_EVENT_UNFILTERED",
        "GROUP_ROSTER_UPDATE",
        "NAME_PLATE_UNIT_ADDED",
        "NAME_PLATE_UNIT_REMOVED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_FOCUS_CHANGED",
        "PLAYER_TARGET_CHANGED",
        "UNIT_FACTION",
        "UNIT_NAME_UPDATE",
        "UNIT_PET",
        "UNIT_TARGET",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_DELAYED",
        "ZONE_CHANGED_NEW_AREA",
    }

    for _, eventName in ipairs(events) do
        eventFrame:RegisterEvent(eventName)
    end

    self.runtimeEventsRegistered = true
end

function GT:Startup()
    self:InitDB()
    self:RegisterSlashCommands()
    self:IterateModules("Init")
    self:RegisterRuntimeEvents()
    self:OnSettingsChanged("startup")

    self.initialized = true
    self:Print("Loaded. Preset state: " .. self:GetPresetStateLabel())
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            GT:Startup()
        end
        return
    end

    if not GT.initialized then
        return
    end

    GT:IterateModules("HandleEvent", event, ...)
end)
