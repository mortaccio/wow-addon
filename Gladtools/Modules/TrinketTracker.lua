local _, GT = ...

local TrinketTracker = {}
GT.TrinketTracker = TrinketTracker
GT:RegisterModule("TrinketTracker", TrinketTracker)

TrinketTracker.PURGE_INTERVAL = 1.0
TrinketTracker.MIN_TRACKED_DURATION = 1.5
TrinketTracker.MAX_TRACKED_DURATION = 3600
TrinketTracker.DEDUPE_SECONDS = 0.30
TrinketTracker.DEDUPE_RETENTION = 15.0
TrinketTracker.CC_BREAK_INFER_WINDOW = 2.5
TrinketTracker.INFERRED_TRINKET_SPELLS = { 336126, 336135 }

local function getSpellNameAndIcon(spellID)
    if GT and GT.GetSpellNameAndIcon then
        return GT:GetSpellNameAndIcon(spellID)
    end

    return nil, nil
end

local function isCombatDataRestricted()
    if GT and GT.IsCombatDataRestricted then
        return GT:IsCombatDataRestricted()
    end

    return false
end

function TrinketTracker:Init()
    self.activeByGUID = {}
    self.lastPurge = 0
    self.lastTrackSeenAt = {}
end

function TrinketTracker:Reset()
    self.activeByGUID = {}
    self.lastPurge = 0
    self.lastTrackSeenAt = {}
end

function TrinketTracker:IsEnabled()
    if isCombatDataRestricted() then
        return false
    end

    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local trinketSettings = settings.trinkets
    return trinketSettings and trinketSettings.enabled and true or false
end

function TrinketTracker:IsLocalPlayerGUID(guid)
    if not guid or not UnitGUID then
        return false
    end
    return UnitGUID("player") == guid
end

function TrinketTracker:GetLocalPlayerCooldownInfo(spellID)
    local startTime = nil
    local duration = nil

    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if type(info) == "table" then
            startTime = tonumber(info.startTime or info.start)
            duration = tonumber(info.duration)
        else
            local legacyStart, legacyDuration = C_Spell.GetSpellCooldown(spellID)
            startTime = tonumber(legacyStart)
            duration = tonumber(legacyDuration)
        end
    end

    if (not duration or duration <= 0) and GetSpellCooldown then
        local legacyStart, legacyDuration = GetSpellCooldown(spellID)
        startTime = tonumber(legacyStart)
        duration = tonumber(legacyDuration)
    end

    if duration and duration > self.MIN_TRACKED_DURATION and duration < self.MAX_TRACKED_DURATION then
        return startTime or 0, duration
    end

    return nil, nil
end

function TrinketTracker:GetLocalPlayerCooldownDuration(spellID)
    local _, duration = self:GetLocalPlayerCooldownInfo(spellID)
    return duration
end

function TrinketTracker:GetSpecOverrideDuration(entry, specID)
    if not entry then
        return 0
    end

    if specID and type(entry.cooldownBySpec) == "table" then
        local bySpec = entry.cooldownBySpec[specID]
        if type(bySpec) == "number" and bySpec > 0 then
            return bySpec
        end
    end

    return 0
end

function TrinketTracker:GetDuration(entry, spellID, specID, guid)
    if self:IsLocalPlayerGUID(guid) then
        local apiDuration = self:GetLocalPlayerCooldownDuration(spellID)
        if apiDuration and apiDuration > 0 then
            return apiDuration
        end
    end

    local duration = self:GetSpecOverrideDuration(entry, specID)
    if duration > 0 then
        return duration
    end

    duration = entry and entry.defaultCD or 0

    if duration <= 0 and GetSpellBaseCooldown then
        local baseMs = GetSpellBaseCooldown(spellID)
        if type(baseMs) == "number" and baseMs > 0 then
            duration = baseMs / 1000
        end
    end

    return duration
end

function TrinketTracker:ForEachSpellID(value, callback)
    if type(callback) ~= "function" then
        return
    end

    if type(value) == "number" and value > 0 then
        callback(value)
        return
    end

    if type(value) ~= "table" then
        return
    end

    for _, spellID in ipairs(value) do
        if type(spellID) == "number" and spellID > 0 then
            callback(spellID)
        end
    end
end

function TrinketTracker:ClearSharedCooldowns(guidTable, entry, spellID)
    if not guidTable then
        return
    end

    guidTable[spellID] = nil
    self:ForEachSpellID(entry and entry.sharedCD, function(linkedSpellID)
        guidTable[linkedSpellID] = nil
    end)
end

function TrinketTracker:ApplyResetCooldowns(guidTable, entry)
    if not guidTable then
        return
    end

    self:ForEachSpellID(entry and entry.resetCD, function(resetSpellID)
        guidTable[resetSpellID] = nil
    end)
end

function TrinketTracker:ShouldAcceptTrack(guid, spellID, now)
    local key = tostring(guid) .. ":" .. tostring(spellID)
    local previous = self.lastTrackSeenAt[key]
    if previous and (now - previous) < self.DEDUPE_SECONDS then
        return false
    end

    self.lastTrackSeenAt[key] = now
    return true
end

function TrinketTracker:Track(guid, name, classFile, spellID, sourceFlags)
    if not self:IsEnabled() then
        return
    end

    if not guid or type(spellID) ~= "number" then
        return
    end

    if sourceFlags and GT.UnitMap and not GT.UnitMap:IsPlayerControlledSource(sourceFlags) then
        return
    end

    local specID = GT.UnitMap and GT.UnitMap.GetSpecIDForGUID and GT.UnitMap:GetSpecIDForGUID(guid) or nil
    local entry = GT:GetTrinketEntryForSpell(spellID, classFile, specID)
    if not entry then
        return
    end

    local duration = self:GetDuration(entry, spellID, specID, guid)
    if not duration or duration <= 0 then
        return
    end

    local now = GetTime and GetTime() or 0
    if not self:ShouldAcceptTrack(guid, spellID, now) then
        return
    end

    local spellName, icon = getSpellNameAndIcon(spellID)
    local sourceInfo = GT.UnitMap and GT.UnitMap.GetInfoByGUID and GT.UnitMap:GetInfoByGUID(guid) or nil
    local guidTable = self.activeByGUID[guid]
    if not guidTable then
        guidTable = {}
        self.activeByGUID[guid] = guidTable
    end

    self:ClearSharedCooldowns(guidTable, entry, spellID)
    self:ApplyResetCooldowns(guidTable, entry)

    guidTable[spellID] = {
        spellID = spellID,
        spellName = spellName or ("Spell " .. tostring(spellID)),
        icon = entry.icon or icon,
        category = "trinket",
        classFile = classFile,
        priority = entry.priority or 80,
        sourceGUID = guid,
        sourceName = (sourceInfo and sourceInfo.name) or name,
        isFriendly = GT.UnitMap and GT.UnitMap.IsFriendlySource and GT.UnitMap:IsFriendlySource(guid, sourceFlags) or false,
        startTime = now,
        duration = duration,
        endTime = now + duration,
    }
end

function TrinketTracker:PurgeExpired()
    local now = GetTime and GetTime() or 0
    if now - self.lastPurge < self.PURGE_INTERVAL then
        return
    end

    self.lastPurge = now

    for guid, guidTable in pairs(self.activeByGUID) do
        for spellID, entry in pairs(guidTable) do
            if entry.endTime <= now then
                guidTable[spellID] = nil
            end
        end

        if not next(guidTable) then
            self.activeByGUID[guid] = nil
        end
    end

    for key, timestamp in pairs(self.lastTrackSeenAt) do
        if (now - timestamp) > self.DEDUPE_RETENTION then
            self.lastTrackSeenAt[key] = nil
        end
    end
end

function TrinketTracker:GetUnitTrinkets(guid)
    if not guid then
        return {}
    end

    self:PurgeExpired()

    local guidTable = self.activeByGUID[guid]
    if not guidTable then
        return {}
    end

    local now = GetTime and GetTime() or 0
    local list = {}

    for _, entry in pairs(guidTable) do
        local remaining = entry.endTime - now
        if remaining > 0 then
            entry.remaining = remaining
            list[#list + 1] = entry
        end
    end

    table.sort(list, function(a, b)
        if a.priority == b.priority then
            return a.endTime < b.endTime
        end
        return a.priority > b.priority
    end)

    return list
end

function TrinketTracker:GetPrimaryTrinket(guid)
    local list = self:GetUnitTrinkets(guid)
    return list[1]
end

function TrinketTracker:GetActiveCounts()
    self:PurgeExpired()

    local total = 0
    local friendly = 0
    local enemy = 0
    local now = GetTime and GetTime() or 0

    for _, guidTable in pairs(self.activeByGUID or {}) do
        for _, entry in pairs(guidTable) do
            if entry.endTime and entry.endTime > now then
                total = total + 1
                if entry.isFriendly then
                    friendly = friendly + 1
                else
                    enemy = enemy + 1
                end
            end
        end
    end

    return total, friendly, enemy
end

function TrinketTracker:IsCCSpell(spellID)
    if type(spellID) ~= "number" then
        return false
    end

    if GT.DRTracker then
        if GT.DRTracker.GetCategoryForSpell and GT.DRTracker:GetCategoryForSpell(spellID) then
            return true
        end
        if GT.DRTracker.SPELL_TO_CATEGORY and GT.DRTracker.SPELL_TO_CATEGORY[spellID] then
            return true
        end
    end

    return false
end

function TrinketTracker:GetRecentlyTriggeredLocalTrinketSpell(now)
    local playerGUID = UnitGUID and UnitGUID("player") or nil
    if not playerGUID then
        return nil
    end

    local bestSpellID = nil
    local bestElapsed = nil

    for _, spellID in ipairs(self.INFERRED_TRINKET_SPELLS) do
        local startTime, duration = self:GetLocalPlayerCooldownInfo(spellID)
        if startTime and duration and duration > 0 then
            local elapsed = now - startTime
            if elapsed >= 0 and elapsed <= self.CC_BREAK_INFER_WINDOW then
                if not bestElapsed or elapsed < bestElapsed then
                    bestElapsed = elapsed
                    bestSpellID = spellID
                end
            end
        end
    end

    return bestSpellID
end

function TrinketTracker:HandlePossibleCCBreakTrinket(destGUID, destName, destFlags, removedSpellID, removedAuraType)
    if not self:IsEnabled() then
        return
    end

    if not destGUID or not self:IsLocalPlayerGUID(destGUID) then
        return
    end

    if removedAuraType and removedAuraType ~= "DEBUFF" then
        return
    end

    if destFlags and GT.UnitMap and not GT.UnitMap:IsPlayerControlledSource(destFlags) then
        return
    end

    if not self:IsCCSpell(removedSpellID) then
        return
    end

    local now = GetTime and GetTime() or 0
    local inferredSpellID = self:GetRecentlyTriggeredLocalTrinketSpell(now)
    if not inferredSpellID then
        return
    end

    local sourceInfo = GT.UnitMap and GT.UnitMap.GetInfoByGUID and GT.UnitMap:GetInfoByGUID(destGUID) or nil
    local classFile = sourceInfo and sourceInfo.classFile
    self:Track(destGUID, destName, classFile, inferredSpellID, destFlags)
end

function TrinketTracker:HandleCombatLog()
    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, _, _, auraType, extraSpellID, _, _, extraAuraType = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_AURA_BROKEN" or subEvent == "SPELL_AURA_BROKEN_SPELL" or subEvent == "SPELL_DISPEL" then
        local removedSpellID = subEvent == "SPELL_AURA_BROKEN" and spellID or extraSpellID
        local removedAuraType = subEvent == "SPELL_AURA_BROKEN" and auraType or extraAuraType
        self:HandlePossibleCCBreakTrinket(destGUID, destName, destFlags, removedSpellID, removedAuraType)
        return
    end

    if type(spellID) ~= "number" then
        return
    end

    if subEvent ~= "SPELL_CAST_SUCCESS" and subEvent ~= "SPELL_AURA_APPLIED" and subEvent ~= "SPELL_AURA_REFRESH" then
        return
    end

    local actorGUID = sourceGUID
    local actorName = sourceName
    local actorFlags = sourceFlags

    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        actorGUID = destGUID or sourceGUID
        actorName = destName or sourceName
        actorFlags = destFlags or sourceFlags
    end

    if not actorGUID then
        return
    end

    if not GT.UnitMap:IsPlayerControlledSource(actorFlags) then
        return
    end

    local sourceInfo = GT.UnitMap:GetInfoByGUID(actorGUID)
    local classFile = sourceInfo and sourceInfo.classFile

    self:Track(actorGUID, actorName, classFile, spellID, actorFlags)
end

function TrinketTracker:HandleEvent(event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Reset()
    end
end
