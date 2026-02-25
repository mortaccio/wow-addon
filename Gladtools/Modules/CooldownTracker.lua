local _, GT = ...

local CooldownTracker = {}
GT.CooldownTracker = CooldownTracker
GT:RegisterModule("CooldownTracker", CooldownTracker)

CooldownTracker.PURGE_INTERVAL = 1.0
CooldownTracker.DEDUPE_SECONDS = 0.30
CooldownTracker.DEDUPE_RETENTION = 15.0
CooldownTracker.MIN_TRACKED_DURATION = 1.5
CooldownTracker.MAX_TRACKED_DURATION = 3600
CooldownTracker.CLEU_TRACKED_SUBEVENTS = {
    SPELL_CAST_SUCCESS = true,
    SPELL_AURA_APPLIED = true,
}

local function getSpellNameAndIcon(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, info.iconID
        end
    end

    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end

    return nil, nil
end

function CooldownTracker:Init()
    self.activeByGUID = {}
    self.lastPurge = 0
    self.lastCastSeenAt = {}
end

function CooldownTracker:Reset()
    self.activeByGUID = {}
    self.lastPurge = 0
    self.lastCastSeenAt = {}
end

function CooldownTracker:IsEnabled()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local cooldownSettings = settings.unitFrames and settings.unitFrames.cooldowns
    return cooldownSettings and cooldownSettings.enabled and true or false
end

function CooldownTracker:ShouldTrackSide(isFriendly)
    local cooldownSettings = GT.db and GT.db.settings and GT.db.settings.unitFrames and GT.db.settings.unitFrames.cooldowns
    if not cooldownSettings then
        return false
    end

    if isFriendly then
        return cooldownSettings.showFriendly and true or false
    end

    return cooldownSettings.showEnemy and true or false
end

function CooldownTracker:GetSpecOverrideDuration(entry, specID)
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

function CooldownTracker:GetDefaultEntryDuration(entry)
    if not entry then
        return 0
    end

    local defaultCD = tonumber(entry.defaultCD) or 0
    if defaultCD > 0 then
        return defaultCD
    end

    return 0
end

function CooldownTracker:GetBaseCooldownDuration(spellID)
    if GetSpellBaseCooldown then
        local baseMs = GetSpellBaseCooldown(spellID)
        if type(baseMs) == "number" and baseMs > 0 then
            return baseMs / 1000
        end
    end
    return nil
end

function CooldownTracker:GetLocalPlayerCooldownDuration(spellID)
    local duration = nil

    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if type(info) == "table" then
            duration = tonumber(info.duration)
        else
            local _, legacyDuration = C_Spell.GetSpellCooldown(spellID)
            duration = tonumber(legacyDuration)
        end
    end

    if (not duration or duration <= 0) and GetSpellCooldown then
        local _, legacyDuration = GetSpellCooldown(spellID)
        duration = tonumber(legacyDuration)
    end

    if duration and duration > self.MIN_TRACKED_DURATION and duration < self.MAX_TRACKED_DURATION then
        return duration
    end

    return nil
end

function CooldownTracker:GetLocalPlayerChargeDuration(spellID)
    if not (C_Spell and C_Spell.GetSpellCharges) then
        return nil
    end

    local duration = nil
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if type(chargeInfo) == "table" then
        duration = tonumber(chargeInfo.cooldownDuration or chargeInfo.chargeDuration or chargeInfo.duration)
    else
        local legacyCharges = C_Spell.GetSpellCharges(spellID)
        if type(legacyCharges) == "number" then
            local _, _, _, chargeDuration = C_Spell.GetSpellCharges(spellID)
            duration = tonumber(chargeDuration)
        end
    end

    if duration and duration > self.MIN_TRACKED_DURATION and duration < self.MAX_TRACKED_DURATION then
        return duration
    end

    return nil
end

function CooldownTracker:IsLocalPlayerGUID(guid)
    if not guid or not UnitGUID then
        return false
    end
    return UnitGUID("player") == guid
end

function CooldownTracker:GetDuration(entry, spellID, sourceGUID, sourceInfo)
    local specID = sourceInfo and sourceInfo.specID
    local duration = 0

    -- Blizzard does not expose enemy cooldown timers directly; use local-player API when available.
    if self:IsLocalPlayerGUID(sourceGUID) then
        local apiDuration = self:GetLocalPlayerCooldownDuration(spellID)
        local chargeDuration = self:GetLocalPlayerChargeDuration(spellID)
        if chargeDuration and (not apiDuration or chargeDuration > apiDuration) then
            apiDuration = chargeDuration
        end

        if apiDuration and apiDuration > 0 then
            return apiDuration
        end
    end

    duration = self:GetSpecOverrideDuration(entry, specID)
    if duration > 0 then
        return duration
    end

    local baseDuration = self:GetBaseCooldownDuration(spellID)
    if baseDuration and baseDuration > 0 then
        return baseDuration
    end

    return self:GetDefaultEntryDuration(entry)
end

function CooldownTracker:ShouldAcceptCast(sourceGUID, spellID, now)
    local key = tostring(sourceGUID) .. ":" .. tostring(spellID)
    local previous = self.lastCastSeenAt[key]
    if previous and (now - previous) < self.DEDUPE_SECONDS then
        return false
    end
    self.lastCastSeenAt[key] = now
    return true
end

function CooldownTracker:TrackSpell(sourceGUID, sourceName, sourceFlags, spellID, spellName)
    if not self:IsEnabled() then
        return
    end

    if not sourceGUID or type(spellID) ~= "number" then
        return
    end

    if not GT.UnitMap:IsPlayerControlledSource(sourceFlags) then
        return
    end

    local sourceInfo = GT.UnitMap:GetInfoByGUID(sourceGUID)
    local classFile = sourceInfo and sourceInfo.classFile
    local sourceSpecID = sourceInfo and sourceInfo.specID
    local entry = GT:GetCooldownEntryForSpell(spellID, classFile, sourceSpecID)
    if not entry then
        return
    end

    if entry.bucket == "trinkets" or entry.category == "trinket" then
        return
    end

    local isFriendly = GT.UnitMap:IsFriendlySource(sourceGUID, sourceFlags)
    if not self:ShouldTrackSide(isFriendly) then
        return
    end

    if (not sourceSpecID) and entry.specID and GT.UnitMap.SetSpecForGUID then
        GT.UnitMap:SetSpecForGUID(sourceGUID, entry.specID, "cooldown_spell")
        sourceInfo = GT.UnitMap:GetInfoByGUID(sourceGUID) or sourceInfo
        sourceSpecID = sourceInfo and sourceInfo.specID
    end

    local duration = self:GetDuration(entry, spellID, sourceGUID, sourceInfo)
    if not duration or duration <= 0 then
        return
    end

    local resolvedSpellName, resolvedIcon = getSpellNameAndIcon(spellID)
    resolvedSpellName = spellName or resolvedSpellName or ("Spell " .. tostring(spellID))
    resolvedIcon = entry.icon or resolvedIcon

    local now = GetTime and GetTime() or 0
    if not self:ShouldAcceptCast(sourceGUID, spellID, now) then
        return
    end

    local guidTable = self.activeByGUID[sourceGUID]
    if not guidTable then
        guidTable = {}
        self.activeByGUID[sourceGUID] = guidTable
    end

    guidTable[spellID] = {
        spellID = spellID,
        spellName = resolvedSpellName,
        icon = resolvedIcon,
        category = entry.category,
        sourceType = entry.sourceType,
        classFile = classFile,
        specID = sourceSpecID,
        priority = entry.priority or 50,
        sourceGUID = sourceGUID,
        sourceName = (sourceInfo and sourceInfo.name) or sourceName,
        isFriendly = isFriendly,
        startTime = now,
        duration = duration,
        endTime = now + duration,
    }
end

function CooldownTracker:PurgeExpired()
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

    for key, timestamp in pairs(self.lastCastSeenAt) do
        if (now - timestamp) > self.DEDUPE_RETENTION then
            self.lastCastSeenAt[key] = nil
        end
    end
end

function CooldownTracker:GetUnitCooldowns(guid)
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

function CooldownTracker:GetActiveCounts()
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

function CooldownTracker:HandleCombatLog()
    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, sourceGUID, sourceName, sourceFlags, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    if not self.CLEU_TRACKED_SUBEVENTS[subEvent] then
        return
    end

    self:TrackSpell(sourceGUID, sourceName, sourceFlags, spellID, spellName)
end

function CooldownTracker:HandleUnitSpellcastSucceeded(unit, _, spellID)
    if type(spellID) ~= "number" or not unit then
        return
    end

    if UnitExists and not UnitExists(unit) then
        return
    end

    if UnitIsPlayer and not UnitIsPlayer(unit) then
        return
    end

    if GT.UnitMap and GT.UnitMap.RefreshUnit then
        GT.UnitMap:RefreshUnit(unit)
    end

    local guid = GT.UnitMap and GT.UnitMap.GetGUIDForUnit and GT.UnitMap:GetGUIDForUnit(unit)
    if not guid and UnitGUID then
        guid = UnitGUID(unit)
    end
    if not guid then
        return
    end

    local unitName = UnitName and UnitName(unit) or nil
    self:TrackSpell(guid, unitName, nil, spellID, nil)
end

function CooldownTracker:HandleEvent(event, arg1, arg2, arg3)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:HandleUnitSpellcastSucceeded(arg1, arg2, arg3)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Reset()
    end
end
