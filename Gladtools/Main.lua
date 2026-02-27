local ADDON_NAME, GT = ...

local eventFrame = CreateFrame("Frame", "GladtoolsEventFrame")
GT.COMBAT_LOG_SPELL_SUBEVENTS = {
    SPELL_CAST_SUCCESS = true,
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true,
    SPELL_DISPEL = true,
}
GT.COMBAT_LOG_RESTRICTED_SAMPLE_MIN = 12

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
    self:ApplyRuntimeEvents(reason or "settings_changed")
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
    local raidHUDAttached, raidHUDVisible = 0, 0
    if self.RaidHUD and self.RaidHUD.GetAttachedCounts then
        raidHUDAttached, raidHUDVisible = self.RaidHUD:GetAttachedCounts()
    end

    self:Print(string.format("Frames E:%d F:%d N:%d | Casts:%d Pointers:%d", visibleEnemy, visibleFriendly, visibleNear, activeCasts, pointerCount))
    self:Print(string.format("Cooldowns: %d (%d enemy / %d friendly) | Trinkets: %d (%d enemy / %d friendly)", cdTotal, cdEnemy, cdFriendly, trinketTotal, trinketEnemy, trinketFriendly))
    self:Print(string.format("DR: %d tracked (%d active)", drTracked, drActive))
    self:Print(string.format("Raid HUD: %d attached (%d visible)", raidHUDAttached, raidHUDVisible))
    if self:IsCombatDataRestricted() then
        self:Print("Combat data: restricted in current instance (Midnight PvP API mode)")
    end
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
    self:ApplyRuntimeEvents("startup")
end

function GT:IsArenaContext()
    if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then
        return true
    end

    if C_PvP and C_PvP.IsArena and C_PvP.IsArena() then
        return true
    end

    if IsInInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "arena" or instanceType == "pvp") then
            return true
        end
    end

    return false
end

function GT:IsCombatDataRestricted()
    return self.combatDataRestricted and true or false
end

function GT:ResetCombatDataProbe()
    local wasRestricted = self.combatDataRestricted and true or false
    self.combatDataRestricted = false
    self.combatLogSpellSamples = 0
    self.combatLogSpellWithIDs = 0

    if wasRestricted then
        self:ApplyRuntimeEvents("combat_data_probe_reset")
        self:IterateModules("OnSettingsChanged", "combat_data_probe_reset")
    end
end

function GT:HandleCombatDataRestrictionDetected()
    if self.combatDataRestricted then
        return
    end

    self.combatDataRestricted = true
    self:Print("Midnight restriction detected: spell-level combat data unavailable here. Cooldown, trinket, and DR tracking paused.")

    if self.CooldownTracker and self.CooldownTracker.Reset then
        self.CooldownTracker:Reset()
    end
    if self.TrinketTracker and self.TrinketTracker.Reset then
        self.TrinketTracker:Reset()
    end
    if self.DRTracker and self.DRTracker.Reset then
        self.DRTracker:Reset()
    end
    if self.NameplateOverlays and self.NameplateOverlays.Reset then
        self.NameplateOverlays:Reset()
    end
    if self.Notifications and self.Notifications.Reset then
        self.Notifications:Reset()
    end

    self:ApplyRuntimeEvents("combat_data_restricted")
    self:IterateModules("OnSettingsChanged", "combat_data_restricted")
end

function GT:ObserveCombatLogSpellData()
    if self:IsCombatDataRestricted() then
        return
    end

    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, _, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if not subEvent or not self.COMBAT_LOG_SPELL_SUBEVENTS[subEvent] then
        return
    end

    self.combatLogSpellSamples = (self.combatLogSpellSamples or 0) + 1
    if type(spellID) == "number" and spellID > 0 then
        self.combatLogSpellWithIDs = (self.combatLogSpellWithIDs or 0) + 1
        return
    end

    local samples = self.combatLogSpellSamples or 0
    local withIDs = self.combatLogSpellWithIDs or 0
    if samples >= self.COMBAT_LOG_RESTRICTED_SAMPLE_MIN and withIDs == 0 then
        self:HandleCombatDataRestrictionDetected()
    end
end

function GT:GetRuntimeEventSet()
    local events = {
        PLAYER_ENTERING_WORLD = true,
        ZONE_CHANGED_NEW_AREA = true,
    }

    local settings = self.db and self.db.settings
    if not settings or settings.enabled == false then
        return events
    end

    local unitFrames = settings.unitFrames or {}
    local cooldowns = unitFrames.cooldowns or {}
    local castBars = settings.castBars or {}
    local dr = settings.dr or {}
    local trinkets = settings.trinkets or {}
    local notifications = settings.notifications or {}
    local nameplates = settings.nameplates or {}
    local pointers = settings.pointers or {}
    local raidHUD = settings.raidHUD or {}
    local combatDataRestricted = self:IsCombatDataRestricted()

    local wantUnitFrames = (unitFrames.enemy and unitFrames.enemy.enabled)
        or (unitFrames.friendly and unitFrames.friendly.enabled)
        or (unitFrames.near and unitFrames.near.enabled)
    local wantCooldowns = cooldowns.enabled and (cooldowns.showEnemy or cooldowns.showFriendly)
    local wantTrinkets = trinkets.enabled ~= false
    local wantDR = dr.enabled and true or false
    local wantNotifications = notifications.enabled ~= false
    local wantNameplates = nameplates.enabled ~= false
    local hasExplicitPointers = self.PointerSystem and self.PointerSystem.explicitTargets and next(self.PointerSystem.explicitTargets) ~= nil
    local wantPointers = ((pointers.mode and pointers.mode ~= self.POINTER_MODES.OFF) or hasExplicitPointers) and true or false
    local wantCastBars = castBars.enabled
        and (castBars.arena or castBars.friendly or castBars.target or castBars.focus)
        and true or false
    local wantNearFrames = unitFrames.near and unitFrames.near.enabled and true or false
    local wantCombatLogNotifications = wantNotifications and (not combatDataRestricted)
    local wantCombatLogNameplates = wantNameplates and (not combatDataRestricted)
    local wantRaidHUD = raidHUD.enabled and true or false

    if combatDataRestricted then
        wantCooldowns = false
        wantTrinkets = false
        wantDR = false
    end

    local wantUnitMap = wantUnitFrames or wantCooldowns or wantTrinkets or wantDR or wantNotifications or wantNameplates or wantPointers or wantCastBars
    if wantUnitMap then
        events.GROUP_ROSTER_UPDATE = true
        events.PLAYER_FOCUS_CHANGED = true
        events.PLAYER_TARGET_CHANGED = true
        events.UNIT_FACTION = true
        events.UNIT_NAME_UPDATE = true
        events.UNIT_PET = true
        events.UNIT_TARGET = true
    end

    if wantNameplates or wantNearFrames or wantPointers then
        events.NAME_PLATE_UNIT_ADDED = true
        events.NAME_PLATE_UNIT_REMOVED = true
    end

    if wantRaidHUD then
        events.GROUP_ROSTER_UPDATE = true
        events.UNIT_AURA = true
        events.UNIT_HEALTH = true
        events.UNIT_MAXHEALTH = true
        events.UNIT_CONNECTION = true
        events.UNIT_NAME_UPDATE = true
        events.UNIT_FACTION = true
        events.UNIT_TARGET = true
        events.PLAYER_REGEN_DISABLED = true
        events.PLAYER_REGEN_ENABLED = true
        events.PLAYER_LOGIN = true
    end

    if wantCooldowns or wantTrinkets or wantDR or wantCombatLogNotifications or wantCombatLogNameplates then
        events.COMBAT_LOG_EVENT_UNFILTERED = true
    end

    if wantCooldowns or wantNotifications or wantCastBars then
        events.UNIT_SPELLCAST_START = true
        events.UNIT_SPELLCAST_SUCCEEDED = true
        events.UNIT_SPELLCAST_STOP = true
        events.UNIT_SPELLCAST_FAILED = true
        events.UNIT_SPELLCAST_INTERRUPTED = true
        events.UNIT_SPELLCAST_CHANNEL_START = true
        events.UNIT_SPELLCAST_CHANNEL_STOP = true
        events.UNIT_SPELLCAST_CHANNEL_UPDATE = true
        events.UNIT_SPELLCAST_DELAYED = true
    end

    if self:IsArenaContext() then
        events.ARENA_OPPONENT_UPDATE = true
        events.ARENA_PREP_OPPONENT_SPECIALIZATIONS = true
    end

    return events
end

function GT:ApplyRuntimeEvents()
    local desired = self:GetRuntimeEventSet()
    local active = self.activeRuntimeEvents or {}

    if eventFrame.UnregisterEvent then
        for eventName in pairs(active) do
            if not desired[eventName] then
                eventFrame:UnregisterEvent(eventName)
            end
        end
    end

    for eventName in pairs(desired) do
        if not active[eventName] then
            eventFrame:RegisterEvent(eventName)
        end
    end

    self.activeRuntimeEvents = desired
end

function GT:Startup()
    self:InitDB()
    self:ResetCombatDataProbe()
    self:RegisterSlashCommands()
    self:IterateModules("Init")
    
    -- If any module failed to init due to missing UIParent, retry after a short delay
    local retryLoading = false
    for _, module in ipairs(self.moduleOrder) do
        if not module.name then
            retryLoading = true
            break
        end
    end
    
    if retryLoading and UIParent then
        -- Retry initialization for modules that deferred due to missing UIParent
        self:IterateModules("Init")
    end
    
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

    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        GT:ResetCombatDataProbe()
        GT:ApplyRuntimeEvents("zone_context")
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        GT:ObserveCombatLogSpellData()
    end

    GT:IterateModules("HandleEvent", event, ...)
end)
