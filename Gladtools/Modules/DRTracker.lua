local _, GT = ...

local DRTracker = {}
GT.DRTracker = DRTracker
GT:RegisterModule("DRTracker", DRTracker)

DRTracker.RESET_SECONDS = 18
DRTracker.PURGE_INTERVAL = 1.0

DRTracker.CATEGORY_LABELS = {
    stun = "STN",
    incap = "INC",
    fear = "FEA",
    silence = "SIL",
    root = "ROT",
}

DRTracker.SPELL_TO_CATEGORY = {
    -- Stuns
    [408] = "stun", -- Kidney Shot
    [853] = "stun", -- Hammer of Justice
    [1833] = "stun", -- Cheap Shot
    [5211] = "stun", -- Mighty Bash
    [30283] = "stun", -- Shadowfury
    [46968] = "stun", -- Shockwave
    [132169] = "stun", -- Storm Bolt
    [179057] = "stun", -- Chaos Nova
    [20549] = "stun", -- War Stomp
    [119381] = "stun", -- Leg Sweep
    [221562] = "stun", -- Asphyxiate

    -- Incapacitate / disorient-style DR bucket
    [99] = "incap", -- Incapacitating Roar
    [118] = "incap", -- Polymorph
    [6770] = "incap", -- Sap
    [20066] = "incap", -- Repentance
    [2094] = "incap", -- Blind
    [3355] = "incap", -- Freezing Trap
    [51514] = "incap", -- Hex
    [115078] = "incap", -- Paralysis
    [217832] = "incap", -- Imprison
    [82691] = "incap", -- Ring of Frost

    -- Fears
    [5246] = "fear", -- Intimidating Shout
    [5484] = "fear", -- Howl of Terror
    [5782] = "fear", -- Fear
    [8122] = "fear", -- Psychic Scream
    [118699] = "fear", -- Fear (Warlock variant)

    -- Silences
    [1330] = "silence", -- Garrote - Silence
    [15487] = "silence", -- Silence
    [31935] = "silence", -- Avenger's Shield silence
    [47476] = "silence", -- Strangulate

    -- Roots
    [122] = "root", -- Frost Nova
    [339] = "root", -- Entangling Roots
    [33395] = "root", -- Freeze
    [64695] = "root", -- Earthgrab Totem
    [102359] = "root", -- Mass Entanglement
}

local function getNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

function DRTracker:Init()
    self.statesByGUID = {}
    self.lastPurge = 0
end

function DRTracker:Reset()
    self.statesByGUID = {}
    self.lastPurge = 0
end

function DRTracker:IsEnabled()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local drSettings = settings.dr
    return drSettings and drSettings.enabled and true or false
end

function DRTracker:GetOrCreateState(guid, category)
    local guidStates = self.statesByGUID[guid]
    if not guidStates then
        guidStates = {}
        self.statesByGUID[guid] = guidStates
    end

    local state = guidStates[category]
    if not state then
        state = {
            level = 0,
            resetAt = 0,
            active = false,
            lastSpellID = nil,
        }
        guidStates[category] = state
    end

    return state
end

function DRTracker:GetNextMultiplier(level)
    if level <= 0 then
        return 1.0
    elseif level == 1 then
        return 0.5
    elseif level == 2 then
        return 0.25
    end

    return 0.0
end

function DRTracker:NormalizeState(state, now)
    if not state then
        return
    end

    if state.active and state.lastApplied and (now - state.lastApplied) > self.RESET_SECONDS then
        -- Safety reset when a remove event is missed.
        state.active = false
        state.activeSpellID = nil
    end

    if not state.active and state.resetAt and state.resetAt <= now then
        state.level = 0
        state.resetAt = 0
    end
end

function DRTracker:ApplyDR(destGUID, category, spellID)
    if not (destGUID and category) then
        return
    end

    local now = getNow()
    local state = self:GetOrCreateState(destGUID, category)
    self:NormalizeState(state, now)

    if state.active then
        state.lastSpellID = spellID
        state.lastApplied = now
        state.activeSpellID = spellID
        return
    end

    if state.level < 4 then
        state.level = state.level + 1
    end

    if state.level < 1 then
        state.level = 1
    end

    state.active = true
    state.activeSpellID = spellID
    state.lastSpellID = spellID
    state.lastApplied = now
    state.resetAt = now + self.RESET_SECONDS
end

function DRTracker:EndDR(destGUID, category)
    if not (destGUID and category) then
        return
    end

    local guidStates = self.statesByGUID[destGUID]
    if not guidStates then
        return
    end

    local state = guidStates[category]
    if not state then
        return
    end

    local now = getNow()
    state.active = false
    state.activeSpellID = nil

    if state.level > 0 then
        state.resetAt = now + self.RESET_SECONDS
    else
        state.resetAt = 0
    end
end

function DRTracker:PurgeExpired()
    local now = getNow()
    if now - self.lastPurge < self.PURGE_INTERVAL then
        return
    end

    self.lastPurge = now

    for guid, guidStates in pairs(self.statesByGUID) do
        for category, state in pairs(guidStates) do
            self:NormalizeState(state, now)
            if (not state.active) and (not state.resetAt or state.resetAt <= now) then
                guidStates[category] = nil
            end
        end

        if not next(guidStates) then
            self.statesByGUID[guid] = nil
        end
    end
end

function DRTracker:GetUnitDRStates(guid)
    if not self:IsEnabled() or not guid then
        return {}
    end

    self:PurgeExpired()

    local guidStates = self.statesByGUID[guid]
    if not guidStates then
        return {}
    end

    local now = getNow()
    local list = {}

    for category, state in pairs(guidStates) do
        self:NormalizeState(state, now)
        if state.level > 0 then
            local remaining = math.max(0, (state.resetAt or 0) - now)
            if state.active or remaining > 0 then
                list[#list + 1] = {
                    category = category,
                    label = self.CATEGORY_LABELS[category] or category,
                    level = state.level,
                    nextMultiplier = self:GetNextMultiplier(state.level),
                    resetRemaining = remaining,
                    isActive = state.active and true or false,
                    lastSpellID = state.lastSpellID,
                }
            end
        end
    end

    table.sort(list, function(a, b)
        if a.isActive ~= b.isActive then
            return a.isActive
        end

        if a.level == b.level then
            return a.resetRemaining < b.resetRemaining
        end

        return a.level > b.level
    end)

    return list
end

function DRTracker:HandleCombatLog()
    if not self:IsEnabled() or not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, _, _, sourceFlags, _, destGUID, _, _, _, spellID, _, _, auraType = CombatLogGetCurrentEventInfo()
    if not destGUID or type(spellID) ~= "number" then
        return
    end

    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        if auraType and auraType ~= "DEBUFF" then
            return
        end

        local category = self.SPELL_TO_CATEGORY[spellID]
        if not category then
            return
        end

        if sourceFlags and not GT.UnitMap:IsPlayerControlledSource(sourceFlags) then
            return
        end
        self:ApplyDR(destGUID, category, spellID)
        return
    end

    if subEvent == "SPELL_AURA_REMOVED" or subEvent == "SPELL_AURA_BROKEN" then
        local category = self.SPELL_TO_CATEGORY[spellID]
        if not category then
            return
        end

        if auraType and auraType ~= "DEBUFF" then
            return
        end

        self:EndDR(destGUID, category)
        return
    end

    if subEvent == "SPELL_AURA_BROKEN_SPELL" or subEvent == "SPELL_DISPEL" then
        local _, _, _, _, _, _, _, _, _, _, _, _, _, _, extraSpellID, _, _, extraAuraType = CombatLogGetCurrentEventInfo()
        if type(extraSpellID) ~= "number" then
            return
        end

        if extraAuraType and extraAuraType ~= "DEBUFF" then
            return
        end

        local category = self.SPELL_TO_CATEGORY[extraSpellID]
        if not category then
            return
        end

        self:EndDR(destGUID, category)
    end
end

function DRTracker:HandleEvent(event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Reset()
    end
end
