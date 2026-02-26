local _, GT = ...

local DRTracker = {}
GT.DRTracker = DRTracker
GT:RegisterModule("DRTracker", DRTracker)

DRTracker.PURGE_INTERVAL = 1.0
DRTracker.DEFAULT_RESET_SECONDS = 16.5

DRTracker.FALLBACK_CATEGORY_ORDER = { "stun", "incap", "fear", "silence", "root" }
DRTracker.FALLBACK_CATEGORY_LABELS = {
    stun = "STN",
    incap = "INC",
    fear = "FEA",
    silence = "SIL",
    root = "ROT",
}

DRTracker.FALLBACK_SPELL_TO_CATEGORY = {
    [408] = "stun",
    [853] = "stun",
    [1833] = "stun",
    [30283] = "stun",
    [46968] = "stun",
    [119381] = "stun",
    [179057] = "stun",
    [221562] = "stun",
    [118] = "incap",
    [2094] = "incap",
    [3355] = "incap",
    [33786] = "incap",
    [51514] = "incap",
    [115078] = "incap",
    [217832] = "incap",
    [5246] = "fear",
    [5484] = "fear",
    [5782] = "fear",
    [8122] = "fear",
    [1330] = "silence",
    [15487] = "silence",
    [47476] = "silence",
    [78675] = "silence",
    [204490] = "silence",
    [122] = "root",
    [339] = "root",
    [64695] = "root",
    [204085] = "root",
}

DRTracker.FALLBACK_CATEGORY_ALIASES = {
    incapacitate = "incap",
    disorient = "incap",
    cyclone = "incap",
    mind_control = "incap",
    bind_elemental = "incap",
    fear = "fear",
    horror = "fear",
    death_coil = "fear",
    silence = "silence",
    unstable_affliction = "silence",
    stun = "stun",
    random_stun = "stun",
    opener_stun = "stun",
    charge = "stun",
    chastise = "stun",
    kidney_shot = "stun",
    counterattack = "stun",
    root = "root",
    random_root = "root",
    frost_shock = "root",
    disarm = "disarm",
    taunt = "taunt",
    knockback = "knockback",
}

DRTracker.CATEGORY_ORDER = DRTracker.FALLBACK_CATEGORY_ORDER
DRTracker.CATEGORY_LABELS = DRTracker.FALLBACK_CATEGORY_LABELS
DRTracker.SPELL_TO_CATEGORY = DRTracker.FALLBACK_SPELL_TO_CATEGORY
DRTracker.SPELL_TO_RAW_CATEGORY = {}
DRTracker.RESET_SECONDS_BY_CATEGORY = { default = DRTracker.DEFAULT_RESET_SECONDS }
DRTracker.DIMINISHED_BY_CATEGORY = { default = { 0.50 } }
DRTracker.CATEGORY_ALIASES = DRTracker.FALLBACK_CATEGORY_ALIASES

local function getNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

local function copyArray(values)
    local out = {}
    if type(values) ~= "table" then
        return out
    end

    for index, value in ipairs(values) do
        out[index] = value
    end
    return out
end

local function copyMap(values)
    local out = {}
    if type(values) ~= "table" then
        return out
    end

    for key, value in pairs(values) do
        out[key] = value
    end
    return out
end

local function callLibraryMethod(lib, methodName, ...)
    if type(lib) ~= "table" or type(methodName) ~= "string" then
        return nil
    end

    local method = lib[methodName]
    if type(method) ~= "function" then
        return nil
    end

    local ok, result = pcall(method, lib, ...)
    if ok then
        return result
    end

    ok, result = pcall(method, ...)
    if ok then
        return result
    end

    return nil
end

function DRTracker:LoadData()
    local drData = GT.DRData
    if type(drData) ~= "table" then
        self.CATEGORY_ORDER = copyArray(self.FALLBACK_CATEGORY_ORDER)
        self.CATEGORY_LABELS = copyMap(self.FALLBACK_CATEGORY_LABELS)
        self.SPELL_TO_CATEGORY = copyMap(self.FALLBACK_SPELL_TO_CATEGORY)
        self.SPELL_TO_RAW_CATEGORY = {}
        self.SNAPSHOT_SPELL_TO_CATEGORY = copyMap(self.FALLBACK_SPELL_TO_CATEGORY)
        self.SNAPSHOT_SPELL_TO_RAW_CATEGORY = {}
        self.CATEGORY_ALIASES = copyMap(self.FALLBACK_CATEGORY_ALIASES)
        self.RESET_SECONDS_BY_CATEGORY = { default = self.DEFAULT_RESET_SECONDS }
        self.DIMINISHED_BY_CATEGORY = { default = { 0.50 } }
        for category in pairs(self.CATEGORY_LABELS) do
            self.CATEGORY_ALIASES[category] = category
        end
        return
    end

    local categoryOrder = copyArray(drData.categoryOrder)
    if #categoryOrder == 0 then
        categoryOrder = copyArray(self.FALLBACK_CATEGORY_ORDER)
    end

    local categoryLabels = copyMap(drData.categoryLabels)
    for _, category in ipairs(categoryOrder) do
        categoryLabels[category] = categoryLabels[category] or string.upper(string.sub(category, 1, 3))
    end

    local spellToCategory = copyMap(drData.spellToCategory)
    if not next(spellToCategory) then
        spellToCategory = copyMap(self.FALLBACK_SPELL_TO_CATEGORY)
    end

    local spellToRawCategory = copyMap(drData.spellToRawCategory)

    local categoryAliases = copyMap(drData.categoryAliases)
    if not next(categoryAliases) then
        categoryAliases = {}
    end

    for rawCategory, normalizedCategory in pairs(self.FALLBACK_CATEGORY_ALIASES) do
        if type(categoryAliases[rawCategory]) ~= "string" then
            categoryAliases[rawCategory] = normalizedCategory
        end
    end

    for _, category in ipairs(categoryOrder) do
        if type(categoryAliases[category]) ~= "string" then
            categoryAliases[category] = category
        end
    end

    local resetSeconds = copyMap(drData.resetSeconds)
    if type(resetSeconds.default) ~= "number" or resetSeconds.default <= 0 then
        resetSeconds.default = self.DEFAULT_RESET_SECONDS
    end

    local diminished = copyMap(drData.diminished)
    if type(diminished.default) ~= "table" or #diminished.default == 0 then
        diminished.default = { 0.50 }
    end

    self.CATEGORY_ORDER = categoryOrder
    self.CATEGORY_LABELS = categoryLabels
    self.SPELL_TO_CATEGORY = copyMap(spellToCategory)
    self.SPELL_TO_RAW_CATEGORY = copyMap(spellToRawCategory)
    self.SNAPSHOT_SPELL_TO_CATEGORY = spellToCategory
    self.SNAPSHOT_SPELL_TO_RAW_CATEGORY = spellToRawCategory
    self.CATEGORY_ALIASES = categoryAliases
    self.RESET_SECONDS_BY_CATEGORY = resetSeconds
    self.DIMINISHED_BY_CATEGORY = diminished
end

function DRTracker:GetDRLibrary()
    if self.drListSearched then
        return self.drList
    end

    self.drListSearched = true
    self.drList = nil

    if type(LibStub) ~= "function" then
        return nil
    end

    local ok, lib = pcall(LibStub, "DRList-1.0", true)
    if ok and type(lib) == "table" then
        self.drList = lib
    end

    return self.drList
end

function DRTracker:NormalizeCategory(rawCategory)
    if type(rawCategory) ~= "string" or rawCategory == "" then
        return nil
    end

    local normalizedRaw = string.lower(rawCategory)
    local aliases = self.CATEGORY_ALIASES or {}
    local mapped = aliases[normalizedRaw] or aliases[rawCategory]
    if type(mapped) == "string" and mapped ~= "" then
        return mapped
    end

    if self.CATEGORY_LABELS and self.CATEGORY_LABELS[normalizedRaw] then
        return normalizedRaw
    end

    return normalizedRaw
end

function DRTracker:EnsureCategoryKnown(category)
    if type(category) ~= "string" or category == "" then
        return
    end

    if type(self.CATEGORY_LABELS[category]) ~= "string" then
        self.CATEGORY_LABELS[category] = string.upper(string.sub(category, 1, 3))
    end

    local exists = false
    for _, knownCategory in ipairs(self.CATEGORY_ORDER) do
        if knownCategory == category then
            exists = true
            break
        end
    end

    if not exists then
        self.CATEGORY_ORDER[#self.CATEGORY_ORDER + 1] = category
    end
end

function DRTracker:BuildDiminishedChainFromLibrary(rawCategory, normalizedCategory)
    local drLib = self:GetDRLibrary()
    if not drLib then
        return nil
    end

    local chain = {}
    local current = 1.0
    for _ = 1, 6 do
        local nextDR = callLibraryMethod(drLib, "NextDR", current, rawCategory)
        if type(nextDR) ~= "number" then
            nextDR = callLibraryMethod(drLib, "NextDR", current, normalizedCategory)
        end

        if type(nextDR) ~= "number" then
            break
        end

        if nextDR >= current then
            break
        end

        chain[#chain + 1] = nextDR
        current = nextDR

        if nextDR <= 0 then
            break
        end
    end

    if #chain == 0 then
        return nil
    end

    return chain
end

function DRTracker:ApplyLiveCategoryMetadata(normalizedCategory, rawCategory)
    if type(normalizedCategory) ~= "string" or normalizedCategory == "" then
        return
    end

    self.liveCategoryMetadata = self.liveCategoryMetadata or {}
    if self.liveCategoryMetadata[normalizedCategory] then
        return
    end

    self.liveCategoryMetadata[normalizedCategory] = true

    local drLib = self:GetDRLibrary()
    if not drLib then
        return
    end

    local resetSeconds = callLibraryMethod(drLib, "GetResetTime", rawCategory)
    if type(resetSeconds) ~= "number" or resetSeconds <= 0 then
        resetSeconds = callLibraryMethod(drLib, "GetResetTime", normalizedCategory)
    end
    if type(resetSeconds) == "number" and resetSeconds > 0 then
        self.RESET_SECONDS_BY_CATEGORY[normalizedCategory] = resetSeconds
    end

    local chain = self:BuildDiminishedChainFromLibrary(rawCategory, normalizedCategory)
    if type(chain) == "table" then
        self.DIMINISHED_BY_CATEGORY[normalizedCategory] = chain
    end
end

function DRTracker:GetCategoryForSpell(spellID)
    if type(spellID) ~= "number" then
        return nil
    end

    local drLib = self:GetDRLibrary()
    if drLib then
        self.liveLookupCache = self.liveLookupCache or {}
        local cached = self.liveLookupCache[spellID]
        if cached ~= nil then
            if cached then
                return cached
            end
        else
            local rawCategory = callLibraryMethod(drLib, "GetCategoryBySpellID", spellID)
            local normalizedCategory = self:NormalizeCategory(rawCategory)
            if normalizedCategory then
                self.SPELL_TO_CATEGORY[spellID] = normalizedCategory
                self.SPELL_TO_RAW_CATEGORY[spellID] = rawCategory
                self:EnsureCategoryKnown(normalizedCategory)
                self:ApplyLiveCategoryMetadata(normalizedCategory, rawCategory)
                self.liveLookupCache[spellID] = normalizedCategory
                return normalizedCategory
            end

            self.liveLookupCache[spellID] = false
        end
    end

    local category = self.SPELL_TO_CATEGORY[spellID]
    if category then
        return category
    end

    if self.SNAPSHOT_SPELL_TO_CATEGORY then
        category = self.SNAPSHOT_SPELL_TO_CATEGORY[spellID]
        if category then
            self.SPELL_TO_CATEGORY[spellID] = category
            return category
        end
    end

    local rawCategory = self.SPELL_TO_RAW_CATEGORY[spellID]
    if not rawCategory and self.SNAPSHOT_SPELL_TO_RAW_CATEGORY then
        rawCategory = self.SNAPSHOT_SPELL_TO_RAW_CATEGORY[spellID]
    end

    local normalized = self:NormalizeCategory(rawCategory)
    if normalized then
        self.SPELL_TO_CATEGORY[spellID] = normalized
        self.SPELL_TO_RAW_CATEGORY[spellID] = rawCategory
        self:EnsureCategoryKnown(normalized)
    end
    return normalized
end

function DRTracker:Init()
    self:LoadData()
    self.statesByGUID = {}
    self.lastPurge = 0
    self.drList = nil
    self.drListSearched = false
    self.liveLookupCache = {}
    self.liveCategoryMetadata = {}
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

function DRTracker:GetResetSeconds(category)
    local byCategory = self.RESET_SECONDS_BY_CATEGORY or {}
    local value = byCategory[category] or byCategory.default or self.DEFAULT_RESET_SECONDS
    value = tonumber(value)
    if not value or value <= 0 then
        return self.DEFAULT_RESET_SECONDS
    end
    return value
end

function DRTracker:GetDiminishedChain(category)
    local byCategory = self.DIMINISHED_BY_CATEGORY or {}
    local chain = byCategory[category]
    if type(chain) ~= "table" then
        chain = byCategory.default
    end
    if type(chain) ~= "table" then
        chain = { 0.50 }
    end
    return chain
end

function DRTracker:GetMaxLevelForCategory(category)
    local chain = self:GetDiminishedChain(category)
    local maxIndex = 0
    for index, value in ipairs(chain) do
        if type(value) == "number" then
            maxIndex = index
        end
    end

    -- Plus the initial full-duration application.
    return math.max(1, maxIndex + 1)
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

function DRTracker:GetNextMultiplier(level, category)
    if level <= 0 then
        return 1.0
    end

    local chain = self:GetDiminishedChain(category)
    local value = chain[level]
    if type(value) ~= "number" then
        return 0.0
    end

    if value < 0 then
        return 0.0
    end
    if value > 1 then
        return 1.0
    end

    return value
end

function DRTracker:NormalizeState(state, now, category)
    if not state then
        return
    end

    local resetSeconds = self:GetResetSeconds(category)

    if state.active and state.lastApplied and (now - state.lastApplied) > resetSeconds then
        -- Safety reset when remove events are missed.
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
    self:NormalizeState(state, now, category)

    if state.active then
        state.lastSpellID = spellID
        state.lastApplied = now
        state.activeSpellID = spellID
        return
    end

    local maxLevel = self:GetMaxLevelForCategory(category)
    if state.level < maxLevel then
        state.level = state.level + 1
    end

    if state.level < 1 then
        state.level = 1
    end

    state.active = true
    state.activeSpellID = spellID
    state.lastSpellID = spellID
    state.lastApplied = now
    state.resetAt = now + self:GetResetSeconds(category)
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
        state.resetAt = now + self:GetResetSeconds(category)
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
            self:NormalizeState(state, now, category)
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
        self:NormalizeState(state, now, category)
        if state.level > 0 then
            local remaining = math.max(0, (state.resetAt or 0) - now)
            if state.active or remaining > 0 then
                list[#list + 1] = {
                    category = category,
                    label = self.CATEGORY_LABELS[category] or string.upper(string.sub(category, 1, 3)),
                    level = state.level,
                    nextMultiplier = self:GetNextMultiplier(state.level, category),
                    resetRemaining = remaining,
                    isActive = state.active and true or false,
                    lastSpellID = state.lastSpellID,
                    rawCategory = self.SPELL_TO_RAW_CATEGORY[state.lastSpellID or 0],
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
        for category, state in pairs(guidStates) do
            self:NormalizeState(state, now, category)
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

        local category = self:GetCategoryForSpell(spellID)
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
        local category = self:GetCategoryForSpell(spellID)
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

        local category = self:GetCategoryForSpell(extraSpellID)
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
