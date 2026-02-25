local _, GT = ...

local TrinketTracker = {}
GT.TrinketTracker = TrinketTracker
GT:RegisterModule("TrinketTracker", TrinketTracker)

TrinketTracker.PURGE_INTERVAL = 1.0

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

function TrinketTracker:Init()
    self.activeByGUID = {}
    self.lastPurge = 0
end

function TrinketTracker:Reset()
    self.activeByGUID = {}
    self.lastPurge = 0
end

function TrinketTracker:IsEnabled()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local trinketSettings = settings.trinkets
    return trinketSettings and trinketSettings.enabled and true or false
end

function TrinketTracker:GetDuration(entry, spellID)
    local duration = entry and entry.defaultCD or 0

    if duration <= 0 and GetSpellBaseCooldown then
        local baseMs = GetSpellBaseCooldown(spellID)
        if type(baseMs) == "number" and baseMs > 0 then
            duration = baseMs / 1000
        end
    end

    return duration
end

function TrinketTracker:Track(guid, name, classFile, spellID, sourceFlags)
    if not self:IsEnabled() then
        return
    end

    local entry = GT:GetTrinketEntryForSpell(spellID, classFile)
    if not entry then
        return
    end

    local duration = self:GetDuration(entry, spellID)
    if not duration or duration <= 0 then
        return
    end

    local spellName, icon = getSpellNameAndIcon(spellID)
    local sourceInfo = GT.UnitMap:GetInfoByGUID(guid)

    local now = GetTime and GetTime() or 0
    local guidTable = self.activeByGUID[guid]
    if not guidTable then
        guidTable = {}
        self.activeByGUID[guid] = guidTable
    end

    guidTable[spellID] = {
        spellID = spellID,
        spellName = spellName or ("Spell " .. tostring(spellID)),
        icon = entry.icon or icon,
        category = "trinket",
        classFile = classFile,
        priority = entry.priority or 80,
        sourceGUID = guid,
        sourceName = (sourceInfo and sourceInfo.name) or name,
        isFriendly = GT.UnitMap:IsFriendlySource(guid, sourceFlags),
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

function TrinketTracker:HandleCombatLog()
    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID = CombatLogGetCurrentEventInfo()
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
