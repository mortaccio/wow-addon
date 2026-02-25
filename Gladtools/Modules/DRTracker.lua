local _, GT = ...

local DRTracker = {}
GT.DRTracker = DRTracker
GT:RegisterModule("DRTracker", DRTracker)

DRTracker.RESET_SECONDS = 18
DRTracker.PURGE_INTERVAL = 1.0

local CATEGORY_ORDER = { "stun", "incap", "fear", "silence", "root" }

DRTracker.CATEGORY_DEFINITIONS = {
    stun = {
        label = "STN",
        spells = {
            408, -- Kidney Shot
            853, -- Hammer of Justice
            1833, -- Cheap Shot
            5211, -- Mighty Bash
            30283, -- Shadowfury
            46968, -- Shockwave
            132169, -- Storm Bolt
            179057, -- Chaos Nova
            20549, -- War Stomp
            119381, -- Leg Sweep
            221562, -- Asphyxiate
            108194, -- Asphyxiate (legacy)
            24394, -- Intimidation
            117526, -- Binding Shot stun
            91797, -- Monstrous Blow
            91800, -- Gnaw
            200166, -- Metamorphosis (DH)
            211881, -- Fel Eruption
            255941, -- Wake of Ashes
            22570, -- Maim
            64044, -- Psychic Horror
            202346, -- Double Barrel
            118905, -- Static Charge
            22703, -- Infernal Awakening
            305485, -- Lightning Lasso
        },
    },
    incap = {
        label = "INC",
        spells = {
            99, -- Incapacitating Roar
            118, -- Polymorph
            28272, -- Polymorph: Pig
            28271, -- Polymorph: Turtle
            61305, -- Polymorph: Black Cat
            61721, -- Polymorph: Rabbit
            61780, -- Polymorph: Turkey
            126819, -- Polymorph: Porcupine
            161353, -- Polymorph variants
            161354, -- Polymorph variants
            6770, -- Sap
            1776, -- Gouge
            20066, -- Repentance
            2094, -- Blind
            3355, -- Freezing Trap
            203337, -- Freezing Trap (variant)
            51514, -- Hex
            210873, -- Hex: Compy
            211004, -- Hex: Spider
            211010, -- Hex: Snake
            211015, -- Hex: Cockroach
            269352, -- Hex: Skeletal Hatchling
            277778, -- Hex: Zandalari Tendonripper
            115078, -- Paralysis
            217832, -- Imprison
            82691, -- Ring of Frost
            31661, -- Dragon's Breath
            207167, -- Blinding Sleet
            710, -- Banish
            33786, -- Cyclone
            107079, -- Quaking Palm
            2637, -- Hibernate
        },
    },
    fear = {
        label = "FEA",
        spells = {
            5246, -- Intimidating Shout
            5484, -- Howl of Terror
            5782, -- Fear
            118699, -- Fear (variant)
            8122, -- Psychic Scream
            10326, -- Turn Evil
            1513, -- Scare Beast
            6358, -- Seduction
            205369, -- Mind Bomb
            226943, -- Mind Bomb (legacy)
            130616, -- Fear (glyph variant)
            207685, -- Sigil of Misery
        },
    },
    silence = {
        label = "SIL",
        spells = {
            1330, -- Garrote - Silence
            15487, -- Silence
            31935, -- Avenger's Shield silence
            47476, -- Strangulate
            204490, -- Sigil of Silence
            202933, -- Spider Sting
            81261, -- Solar Beam silence aura
            217824, -- Shield of Virtue
            25046, -- Arcane Torrent (legacy)
        },
    },
    root = {
        label = "ROT",
        spells = {
            122, -- Frost Nova
            339, -- Entangling Roots
            33395, -- Freeze
            64695, -- Earthgrab Totem
            102359, -- Mass Entanglement
            170855, -- Entangling Roots (proc variants)
            204085, -- Deathchill
            162480, -- Steel Trap
            157997, -- Ice Nova
            212638, -- Tracker's Net
            45334, -- Immobilized
            285515, -- Frostweave Net
        },
    },
}

DRTracker.CATEGORY_LABELS = {}
DRTracker.SPELL_TO_CATEGORY = {}

for _, category in ipairs(CATEGORY_ORDER) do
    local definition = DRTracker.CATEGORY_DEFINITIONS[category]
    if definition then
        DRTracker.CATEGORY_LABELS[category] = definition.label or string.upper(category)
        for _, spellID in ipairs(definition.spells or {}) do
            if type(spellID) == "number" and spellID > 0 then
                DRTracker.SPELL_TO_CATEGORY[spellID] = category
            end
        end
    end
end

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

function DRTracker:GetActiveCounts()
    if not self:IsEnabled() then
        return 0, 0
    end

    self:PurgeExpired()

    local tracked = 0
    local active = 0
    local now = getNow()

    for _, guidStates in pairs(self.statesByGUID or {}) do
        for _, state in pairs(guidStates) do
            self:NormalizeState(state, now)
            if state.level and state.level > 0 then
                tracked = tracked + 1
                if state.active then
                    active = active + 1
                end
            end
        end
    end

    return tracked, active
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
