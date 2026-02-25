local _, GT = ...

local CooldownTracker = {}
GT.CooldownTracker = CooldownTracker
GT:RegisterModule("CooldownTracker", CooldownTracker)

CooldownTracker.PURGE_INTERVAL = 1.0

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
end

function CooldownTracker:Reset()
    self.activeByGUID = {}
    self.lastPurge = 0
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

function CooldownTracker:GetDuration(entry, spellID)
    local duration = entry and entry.defaultCD or 0

    if duration <= 0 and GetSpellBaseCooldown then
        local baseMs = GetSpellBaseCooldown(spellID)
        if type(baseMs) == "number" and baseMs > 0 then
            duration = baseMs / 1000
        end
    end

    if duration <= 0 and C_Spell and C_Spell.GetSpellCharges then
        local charges = C_Spell.GetSpellCharges(spellID)
        if type(charges) == "table" then
            if type(charges.cooldownDuration) == "number" and charges.cooldownDuration > 0 then
                duration = charges.cooldownDuration
            end
        else
            local _, _, _, chargeDuration = C_Spell.GetSpellCharges(spellID)
            if type(chargeDuration) == "number" and chargeDuration > 0 then
                duration = chargeDuration
            end
        end
    end

    return duration
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
    local entry = GT:GetCooldownEntryForSpell(spellID, classFile)
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

    local duration = self:GetDuration(entry, spellID)
    if not duration or duration <= 0 then
        return
    end

    local resolvedSpellName, resolvedIcon = getSpellNameAndIcon(spellID)
    resolvedSpellName = spellName or resolvedSpellName or ("Spell " .. tostring(spellID))
    resolvedIcon = entry.icon or resolvedIcon

    local now = GetTime and GetTime() or 0

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
        classFile = classFile,
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

function CooldownTracker:HandleCombatLog()
    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, sourceGUID, sourceName, sourceFlags, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    if subEvent ~= "SPELL_CAST_SUCCESS" then
        return
    end

    self:TrackSpell(sourceGUID, sourceName, sourceFlags, spellID, spellName)
end

function CooldownTracker:HandleEvent(event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Reset()
    end
end
