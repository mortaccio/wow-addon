local _, GT = ...

local UnitMap = {}
GT.UnitMap = UnitMap
GT:RegisterModule("UnitMap", UnitMap)

local bitBand = bit and bit.band
if not bitBand and bit32 then
    bitBand = bit32.band
end

local function removeUnitFromGuidMap(unitTable, unit)
    if not unitTable then
        return
    end
    unitTable[unit] = nil
end

function UnitMap:Init()
    self.guidByUnit = {}
    self.unitsByGUID = {}
    self.infoByGUID = {}
    self:ScanKnownUnits()
end

function UnitMap:Reset()
    self.guidByUnit = {}
    self.unitsByGUID = {}
    self.infoByGUID = {}
end

function UnitMap:IsLikelyHealer(unit, classFile, role)
    if role == "HEALER" then
        return true
    end

    -- Simple assumption: only self spec can be inferred reliably without inspect APIs.
    if unit == "player" and GetSpecialization and GetSpecializationRole then
        local specIndex = GetSpecialization()
        if specIndex then
            local specRole = GetSpecializationRole(specIndex)
            if specRole == "HEALER" then
                return true
            end
        end
    end

    return false
end

function UnitMap:ClearUnit(unit)
    if not unit then
        return
    end

    local oldGUID = self.guidByUnit[unit]
    if oldGUID then
        self.guidByUnit[unit] = nil
        local unitTable = self.unitsByGUID[oldGUID]
        removeUnitFromGuidMap(unitTable, unit)
        if unitTable and not next(unitTable) then
            self.unitsByGUID[oldGUID] = nil
        end
    end
end

function UnitMap:RefreshUnit(unit)
    if type(unit) ~= "string" or unit == "" then
        return
    end

    if not UnitExists or not UnitExists(unit) then
        self:ClearUnit(unit)
        return
    end

    local guid = UnitGUID and UnitGUID(unit)
    if not guid then
        self:ClearUnit(unit)
        return
    end

    local oldGUID = self.guidByUnit[unit]
    if oldGUID and oldGUID ~= guid then
        local oldUnits = self.unitsByGUID[oldGUID]
        removeUnitFromGuidMap(oldUnits, unit)
        if oldUnits and not next(oldUnits) then
            self.unitsByGUID[oldGUID] = nil
        end
    end

    self.guidByUnit[unit] = guid

    local guidUnits = self.unitsByGUID[guid]
    if not guidUnits then
        guidUnits = {}
        self.unitsByGUID[guid] = guidUnits
    end
    guidUnits[unit] = true

    local info = self.infoByGUID[guid]
    if not info then
        info = {
            guid = guid,
        }
        self.infoByGUID[guid] = info
    end

    local name = UnitName and UnitName(unit)
    local _, classFile = UnitClass and UnitClass(unit)
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)

    info.name = name or info.name
    info.classFile = classFile or info.classFile
    info.role = role or info.role
    info.isHealer = self:IsLikelyHealer(unit, classFile, role)
    info.isFriendly = UnitIsFriend and UnitIsFriend("player", unit) and true or false
    info.lastUnit = unit
    info.lastSeen = GetTime and GetTime() or 0
end

function UnitMap:ScanFriendlyUnits()
    self:RefreshUnit("player")

    if IsInRaid and IsInRaid() then
        local count = GetNumGroupMembers and GetNumGroupMembers() or 0
        for index = 1, count do
            self:RefreshUnit("raid" .. index)
            self:RefreshUnit("raidpet" .. index)
        end
    else
        local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for index = 1, count do
            self:RefreshUnit("party" .. index)
            self:RefreshUnit("partypet" .. index)
        end
    end
end

function UnitMap:ScanArenaUnits()
    for index = 1, 3 do
        self:RefreshUnit("arena" .. index)
    end
end

function UnitMap:ScanKnownUnits()
    self:RefreshUnit("player")
    self:RefreshUnit("target")
    self:RefreshUnit("focus")
    self:RefreshUnit("mouseover")

    self:ScanFriendlyUnits()
    self:ScanArenaUnits()

    for index = 1, 40 do
        self:RefreshUnit("nameplate" .. index)
    end
end

function UnitMap:GetGUIDForUnit(unit)
    if not unit then
        return nil
    end

    local guid = self.guidByUnit[unit]
    if guid then
        return guid
    end

    self:RefreshUnit(unit)
    return self.guidByUnit[unit]
end

function UnitMap:GetInfoByGUID(guid)
    if not guid then
        return nil
    end
    return self.infoByGUID[guid]
end

function UnitMap:IsPlayerControlledSource(sourceFlags)
    if not sourceFlags or not COMBATLOG_OBJECT_CONTROL_PLAYER then
        return true
    end

    if CombatLog_Object_IsA then
        return CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER)
    end

    if bitBand then
        return bitBand(sourceFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) ~= 0
    end

    return true
end

function UnitMap:IsFriendlySource(sourceGUID, sourceFlags)
    local info = sourceGUID and self.infoByGUID[sourceGUID]
    if info and info.isFriendly ~= nil then
        return info.isFriendly
    end

    if sourceFlags and COMBATLOG_OBJECT_REACTION_FRIENDLY then
        if CombatLog_Object_IsA then
            if CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) then
                return true
            end
        elseif bitBand and bitBand(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0 then
            return true
        end
    end

    if sourceFlags and COMBATLOG_OBJECT_REACTION_HOSTILE then
        if CombatLog_Object_IsA then
            if CombatLog_Object_IsA(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) then
                return false
            end
        elseif bitBand and bitBand(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
            return false
        end
    end

    return false
end

function UnitMap:IsHealerGUID(guid)
    local info = guid and self.infoByGUID[guid]
    return info and info.isHealer and true or false
end

function UnitMap:GetGroupFriendlyUnits(pointerMode)
    local units = {}

    if pointerMode == GT.POINTER_MODES.OFF then
        return units
    end

    local function addUnit(unit)
        if not UnitExists or not UnitExists(unit) then
            return
        end

        self:RefreshUnit(unit)
        if pointerMode == GT.POINTER_MODES.HEALERS_ONLY then
            local guid = self.guidByUnit[unit]
            if not self:IsHealerGUID(guid) then
                return
            end
        end

        units[#units + 1] = unit
    end

    if IsInRaid and IsInRaid() then
        local count = GetNumGroupMembers and GetNumGroupMembers() or 0
        for index = 1, count do
            addUnit("raid" .. index)
        end
    else
        addUnit("player")
        local partyCount = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for index = 1, partyCount do
            addUnit("party" .. index)
        end
    end

    return units
end

function UnitMap:HandleEvent(event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        self:Reset()
        self:ScanKnownUnits()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:ScanFriendlyUnits()
        self:ScanArenaUnits()
    elseif event == "ARENA_OPPONENT_UPDATE" then
        self:ScanArenaUnits()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        self:RefreshUnit(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        self:ClearUnit(arg1)
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:RefreshUnit("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        self:RefreshUnit("focus")
    elseif event == "UNIT_TARGET" then
        self:RefreshUnit(arg1)
        if arg1 then
            self:RefreshUnit(arg1 .. "target")
        end
    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_FACTION" or event == "UNIT_PET" then
        self:RefreshUnit(arg1)
    end
end
