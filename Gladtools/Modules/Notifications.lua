local _, GT = ...

local Notifications = {}
GT.Notifications = Notifications
GT:RegisterModule("Notifications", Notifications)

Notifications.UPDATE_INTERVAL = 0.05
Notifications.DISPLAY_SECONDS = 3.2
Notifications.FADE_SECONDS = 0.45
Notifications.BURST_PRIORITY_MIN = 75
Notifications.RENOTIFY_SECONDS = 8
Notifications.CC_FALLBACK_SECONDS = 12
Notifications.CC_ON_YOU_RENOTIFY = 3.0

Notifications.HEALER_CC_CATEGORIES = {
    stun = true,
    incap = true,
    fear = true,
    silence = true,
}

Notifications.CC_ON_YOU_CATEGORIES = {
    stun = true,
    incap = true,
    fear = true,
    silence = true,
    root = true,
}

Notifications.BURST_RACIALS = {
    [20572] = true, -- Blood Fury
    [26297] = true, -- Berserking
    [265221] = true, -- Fireblood
    [274738] = true, -- Ancestral Call
    [436344] = true, -- Azerite Surge
}

Notifications.BURST_TRINKETS = {
    [345228] = true, -- Gladiator's Badge
}

local function getNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

local function getSpellName(spellID, fallback)
    if GT and GT.GetSpellName then
        return GT:GetSpellName(spellID, fallback)
    end

    return fallback or ("Spell " .. tostring(spellID))
end

local function buildAuraData(...)
    local first = ...
    if type(first) == "table" then
        local aura = first
        return {
            name = aura.name,
            spellID = aura.spellId or aura.spellID,
            duration = aura.duration,
            expirationTime = aura.expirationTime,
        }
    end

    local name, _, _, _, duration, expirationTime, _, _, _, spellID = ...
    if not name then
        return nil
    end

    return {
        name = name,
        spellID = spellID,
        duration = duration,
        expirationTime = expirationTime,
    }
end

local function findAuraBySpellID(unit, spellID, filter)
    if not unit or type(spellID) ~= "number" then
        return nil
    end

    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local auraData = buildAuraData(AuraUtil.FindAuraBySpellID(spellID, unit, filter))
        if auraData then
            return auraData
        end
    end

    if UnitAura then
        for index = 1, 40 do
            local auraData = buildAuraData(UnitAura(unit, index, filter))
            if not auraData then
                break
            end
            if auraData.spellID == spellID then
                return auraData
            end
        end
    end

    return nil
end

local function setTextureColor(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a or 1)
    end
end

function Notifications:Init()
    self.healerCCByGUID = {}
    self.lastBurstNotice = {}
    self.queue = {}
    self.currentNotice = nil
    self.displayUntil = 0
    self.fadeUntil = 0
    self.elapsed = 0
    self.lastIncomingCCNotice = {}

    if not UIParent then
        GT:Print("UIParent not available, deferring Notifications init")
        return
    end

    self:CreateBanner()

    if CreateFrame then
        self.driver = CreateFrame("Frame", "GladtoolsNotificationDriver", UIParent)
        if self.driver and self.driver.SetScript then
            self.driver:SetScript("OnUpdate", function(_, elapsed)
                Notifications:OnUpdate(elapsed)
            end)
        end
    end

    self:SetDriverActive(self:IsEnabled())
end

function Notifications:CreateBanner()
    if not UIParent or not CreateFrame then
        return
    end

    local frame = CreateFrame("Frame", "GladtoolsNotificationBanner", UIParent, "BackdropTemplate")
    if not frame then
        return
    end

    frame:SetSize(860, 34)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -94)

    if frame.SetFrameStrata then
        frame:SetFrameStrata("HIGH")
    end
    if frame.SetFrameLevel then
        frame:SetFrameLevel(30)
    end

    GT:ApplyWoWBackdrop(frame, "alert")

    frame.accent = frame:CreateTexture(nil, "BORDER")
    frame.accent:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    frame.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.accent:SetHeight(2)
    setTextureColor(frame.accent, 1, 0.82, 0.45, 0.88)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, -1)
    frame.text:SetWidth(840)
    frame.text:SetJustifyH("CENTER")
    if frame.text.SetShadowOffset then
        frame.text:SetShadowOffset(1, -1)
    end
    if frame.text.SetShadowColor then
        frame.text:SetShadowColor(0, 0, 0, 1)
    end

    frame:Hide()
    self.banner = frame
end

function Notifications:IsEnabled()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local notifications = settings.notifications
    if not notifications then
        return true
    end

    return notifications.enabled ~= false
end

function Notifications:SetDriverActive(active)
    self.driverActive = active and true or false
    if not self.driver then
        return
    end

    if self.driverActive then
        if self.driver.Show then
            self.driver:Show()
        end
    else
        self.elapsed = 0
        if self.driver.Hide then
            self.driver:Hide()
        end
    end
end

function Notifications:Reset()
    self.healerCCByGUID = {}
    self.lastBurstNotice = {}
    self.queue = {}
    self.currentNotice = nil
    self.displayUntil = 0
    self.fadeUntil = 0
    self.lastIncomingCCNotice = {}

    if self.banner then
        if self.banner.SetAlpha then
            self.banner:SetAlpha(1)
        end
        self.banner:Hide()
    end
end

function Notifications:IsCCSpell(spellID)
    if type(spellID) ~= "number" then
        return false
    end

    local category = GT.DRTracker and GT.DRTracker.GetCategoryForSpell and GT.DRTracker:GetCategoryForSpell(spellID)
    if not category then
        category = GT.DRTracker and GT.DRTracker.SPELL_TO_CATEGORY and GT.DRTracker.SPELL_TO_CATEGORY[spellID]
    end
    if not category then
        return false
    end

    return self.CC_ON_YOU_CATEGORIES[category] and true or false
end

function Notifications:ShouldNotifyIncomingCC(unit, spellID)
    local key = tostring(unit or "?") .. ":" .. tostring(spellID)
    local now = getNow()
    local previous = self.lastIncomingCCNotice[key]
    if previous and (now - previous) < self.CC_ON_YOU_RENOTIFY then
        return false
    end

    self.lastIncomingCCNotice[key] = now
    return true
end

function Notifications:HandleIncomingCCCast(unit, isChannel)
    if not self:IsEnabled() or not unit then
        return
    end

    if UnitExists and not UnitExists(unit) then
        return
    end

    if UnitIsFriend and UnitIsFriend("player", unit) then
        return
    end

    if UnitExists and UnitIsUnit then
        local targetUnit = unit .. "target"
        if not UnitExists(targetUnit) or not UnitIsUnit(targetUnit, "player") then
            return
        end
    end

    local spellName, _, _, _, _, _, _, _, spellID
    if isChannel then
        spellName, _, _, _, _, _, _, spellID = UnitChannelInfo and UnitChannelInfo(unit)
    else
        spellName, _, _, _, _, _, _, _, spellID = UnitCastingInfo and UnitCastingInfo(unit)
    end

    if not spellName then
        return
    end

    if not self:IsCCSpell(spellID) then
        return
    end

    if not self:ShouldNotifyIncomingCC(unit, spellID) then
        return
    end

    local enemyName = UnitName and UnitName(unit) or "Enemy"
    local message = string.format("CC ON YOU: %s casting %s", enemyName, spellName)
    self:EnqueueNotice(message, 1.00, 0.70, 0.22)
end

function Notifications:GetVisibleUnitsForGUID(guid)
    local units = {}
    if not (guid and GT.UnitMap and GT.UnitMap.unitsByGUID) then
        return units
    end

    local mappedUnits = GT.UnitMap.unitsByGUID[guid]
    if not mappedUnits then
        return units
    end

    for unit in pairs(mappedUnits) do
        if UnitExists and UnitExists(unit) then
            units[#units + 1] = unit
        end
    end

    return units
end

function Notifications:GetAuraTimingForUnits(units, spellID)
    if type(units) ~= "table" then
        return nil, nil, nil
    end

    for _, unit in ipairs(units) do
        local auraData = findAuraBySpellID(unit, spellID, "HARMFUL")
        if auraData then
            return auraData.duration, auraData.expirationTime, auraData.name
        end
    end

    return nil, nil, nil
end

function Notifications:GetAuraTimingForGUID(guid, spellID)
    local units = self:GetVisibleUnitsForGUID(guid)
    return self:GetAuraTimingForUnits(units, spellID)
end

function Notifications:NormalizeCCState()
    local now = getNow()

    for guid, state in pairs(self.healerCCByGUID) do
        local visibleUnits = self:GetVisibleUnitsForGUID(guid)
        local hasVisibleUnit = #visibleUnits > 0
        local count = 0
        local toRemove = nil
        for spellID, entry in pairs(state.spells) do
            local auraDuration, auraExpiresAt, auraName = self:GetAuraTimingForUnits(visibleUnits, spellID)
            if auraExpiresAt and auraExpiresAt > now then
                local duration = auraDuration
                if not duration or duration <= 0 then
                    duration = math.max(0.1, auraExpiresAt - now)
                end
                entry.duration = duration
                entry.expiresAt = auraExpiresAt
                entry.startTime = auraExpiresAt - duration
                entry.spellName = auraName or entry.spellName
                count = count + 1
            elseif hasVisibleUnit then
                toRemove = toRemove or {}
                toRemove[#toRemove + 1] = spellID
            elseif entry.expiresAt and entry.expiresAt <= now then
                toRemove = toRemove or {}
                toRemove[#toRemove + 1] = spellID
            else
                count = count + 1
            end
        end

        if toRemove then
            for _, spellID in ipairs(toRemove) do
                state.spells[spellID] = nil
            end
        end

        state.count = count
        if count <= 0 then
            self.healerCCByGUID[guid] = nil
        end
    end
end

function Notifications:IsFriendlyHealer(guid, flags)
    if not guid then
        return false
    end

    local isFriendly = GT.UnitMap and GT.UnitMap:IsFriendlySource(guid, flags)
    if not isFriendly then
        return false
    end

    if GT.UnitMap and GT.UnitMap:IsHealerGUID(guid) then
        return true
    end

    local info = GT.UnitMap and GT.UnitMap:GetInfoByGUID(guid)
    if info and info.role == "HEALER" then
        return true
    end

    if UnitGUID and UnitGroupRolesAssigned and UnitGUID("player") == guid then
        return UnitGroupRolesAssigned("player") == "HEALER"
    end

    return false
end

function Notifications:SetHealerCC(guid, spellID, spellName, category, active)
    if not guid or type(spellID) ~= "number" then
        return
    end

    local state = self.healerCCByGUID[guid]
    if not state then
        state = {
            spells = {},
            count = 0,
            lastSpellName = nil,
            lastCategory = nil,
            lastApplied = 0,
        }
        self.healerCCByGUID[guid] = state
    end

    if active then
        local now = getNow()
        local resolvedName = spellName or getSpellName(spellID)
        local auraDuration, auraExpiresAt, auraName = self:GetAuraTimingForGUID(guid, spellID)
        local duration = self.CC_FALLBACK_SECONDS
        local expiresAt = now + duration

        if auraExpiresAt and auraExpiresAt > now then
            expiresAt = auraExpiresAt
            if auraDuration and auraDuration > 0 then
                duration = auraDuration
            else
                duration = math.max(0.1, auraExpiresAt - now)
            end
            resolvedName = auraName or resolvedName
        end

        state.spells[spellID] = {
            spellID = spellID,
            spellName = resolvedName,
            category = category,
            startTime = expiresAt - duration,
            duration = duration,
            expiresAt = expiresAt,
        }
        state.lastSpellName = resolvedName
        state.lastCategory = category
        state.lastApplied = now
    else
        state.spells[spellID] = nil
    end

    local count = 0
    for _, _ in pairs(state.spells) do
        count = count + 1
    end

    state.count = count
    if count <= 0 then
        self.healerCCByGUID[guid] = nil
    end
end

function Notifications:GetActiveHealerCCInfo()
    self:NormalizeCCState()

    local selectedGUID = nil
    local selectedState = nil
    for guid, state in pairs(self.healerCCByGUID) do
        if state.count and state.count > 0 then
            if not selectedState or (state.lastApplied or 0) > (selectedState.lastApplied or 0) then
                selectedGUID = guid
                selectedState = state
            end
        end
    end

    if not selectedGUID or not selectedState then
        return nil, nil
    end

    local info = GT.UnitMap and GT.UnitMap:GetInfoByGUID(selectedGUID)
    local healerName = (info and info.name) or "Healer"
    local ccName = selectedState.lastSpellName or "CC"
    return healerName, ccName
end

function Notifications:IsBurstEntry(entry)
    if not entry then
        return false
    end

    if entry.category == "offensive" then
        return (entry.priority or 0) >= self.BURST_PRIORITY_MIN
    end

    if entry.category == "racial" then
        return self.BURST_RACIALS[entry.spellID] and true or false
    end

    if entry.category == "trinket" then
        return self.BURST_TRINKETS[entry.spellID] and true or false
    end

    return false
end

function Notifications:ShouldNotifyBurst(sourceGUID, spellID)
    local key = tostring(sourceGUID or "?") .. ":" .. tostring(spellID)
    local now = getNow()
    local previous = self.lastBurstNotice[key]
    if previous and (now - previous) < self.RENOTIFY_SECONDS then
        return false
    end

    self.lastBurstNotice[key] = now
    return true
end

function Notifications:EnqueueNotice(text, r, g, b)
    if not self:IsEnabled() then
        return
    end

    if type(text) ~= "string" or text == "" then
        return
    end

    self.queue[#self.queue + 1] = {
        text = text,
        r = r or 1,
        g = g or 0.30,
        b = b or 0.30,
    }

    if #self.queue > 8 then
        table.remove(self.queue, 1)
    end
end

function Notifications:ShowNextNotice(now)
    if not self.banner then
        return
    end

    local nextNotice = table.remove(self.queue, 1)
    if not nextNotice then
        return
    end

    self.currentNotice = nextNotice
    self.displayUntil = now + self.DISPLAY_SECONDS
    self.fadeUntil = self.displayUntil + self.FADE_SECONDS

    self.banner.text:SetText(nextNotice.text)
    self.banner.text:SetTextColor(nextNotice.r, nextNotice.g, nextNotice.b)
    if self.banner.SetAlpha then
        self.banner:SetAlpha(1)
    end
    self.banner:Show()
end

function Notifications:UpdateBanner(now)
    if not self:IsEnabled() then
        self.queue = {}
        self.currentNotice = nil
        if self.banner then
            if self.banner.SetAlpha then
                self.banner:SetAlpha(1)
            end
            self.banner:Hide()
        end
        return
    end

    if not self.currentNotice then
        if #self.queue > 0 then
            self:ShowNextNotice(now)
        end
        return
    end

    if now <= self.displayUntil then
        return
    end

    local fadeRemaining = self.fadeUntil - now
    if fadeRemaining <= 0 then
        self.currentNotice = nil
        if self.banner then
            if self.banner.SetAlpha then
                self.banner:SetAlpha(1)
            end
            self.banner:Hide()
        end

        if #self.queue > 0 then
            self:ShowNextNotice(now)
        end
        return
    end

    if self.banner and self.banner.SetAlpha then
        self.banner:SetAlpha(math.max(0, fadeRemaining / self.FADE_SECONDS))
    end
end

function Notifications:HandleCCAura(subEvent, destGUID, destFlags, spellID, spellName, auraType)
    if type(spellID) ~= "number" then
        return
    end

    if auraType and auraType ~= "DEBUFF" then
        return
    end

    local category = GT.DRTracker and GT.DRTracker.GetCategoryForSpell and GT.DRTracker:GetCategoryForSpell(spellID)
    if not category then
        category = GT.DRTracker and GT.DRTracker.SPELL_TO_CATEGORY and GT.DRTracker.SPELL_TO_CATEGORY[spellID]
    end
    if not category or not self.HEALER_CC_CATEGORIES[category] then
        return
    end

    if not self:IsFriendlyHealer(destGUID, destFlags) then
        return
    end

    local isApplied = subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH"
    self:SetHealerCC(destGUID, spellID, spellName, category, isApplied)
end

function Notifications:HandleBurstCast(sourceGUID, sourceName, sourceFlags, spellID, spellName)
    if not self:IsEnabled() then
        return
    end

    if not sourceGUID or type(spellID) ~= "number" then
        return
    end

    if GT.UnitMap and not GT.UnitMap:IsPlayerControlledSource(sourceFlags) then
        return
    end

    if GT.UnitMap and GT.UnitMap:IsFriendlySource(sourceGUID, sourceFlags) then
        return
    end

    local sourceInfo = GT.UnitMap and GT.UnitMap:GetInfoByGUID(sourceGUID)
    local classFile = sourceInfo and sourceInfo.classFile
    local specID = sourceInfo and sourceInfo.specID
    local entry = GT:GetCooldownEntryForSpell(spellID, classFile, specID)
    if not self:IsBurstEntry(entry) then
        return
    end

    local healerName, ccName = self:GetActiveHealerCCInfo()
    if not healerName then
        return
    end

    if not self:ShouldNotifyBurst(sourceGUID, spellID) then
        return
    end

    local enemyName = (sourceInfo and sourceInfo.name) or sourceName or "Enemy"
    local burstName = spellName or getSpellName(spellID)

    local message = string.format("%s in CC (%s) - %s used %s", healerName, ccName, enemyName, burstName)
    self:EnqueueNotice(message, 1.00, 0.34, 0.34)
end

function Notifications:HandleCombatLog()
    if GT.IsCombatDataRestricted and GT:IsCombatDataRestricted() then
        return
    end

    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, _, destFlags, _, spellID, spellName, _, auraType = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_CAST_SUCCESS" then
        self:HandleBurstCast(sourceGUID, sourceName, sourceFlags, spellID, spellName)
        return
    end

    if subEvent == "SPELL_AURA_APPLIED"
        or subEvent == "SPELL_AURA_REFRESH"
        or subEvent == "SPELL_AURA_REMOVED"
        or subEvent == "SPELL_AURA_BROKEN"
    then
        self:HandleCCAura(subEvent, destGUID, destFlags, spellID, spellName, auraType)
        return
    end

    if subEvent == "SPELL_AURA_BROKEN_SPELL" or subEvent == "SPELL_DISPEL" then
        local _, _, _, _, _, _, _, breakDestGUID, _, breakDestFlags, _, _, _, _, extraSpellID, extraSpellName, _, extraAuraType = CombatLogGetCurrentEventInfo()
        self:HandleCCAura("SPELL_AURA_REMOVED", breakDestGUID, breakDestFlags, extraSpellID, extraSpellName, extraAuraType)
    end
end

function Notifications:OnUpdate(elapsed)
    if not self.driverActive then
        return
    end

    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:NormalizeCCState()
    self:UpdateBanner(getNow())
end

function Notifications:OnSettingsChanged()
    self:SetDriverActive(self:IsEnabled())
    if not self:IsEnabled() and self.banner then
        self.queue = {}
        self.currentNotice = nil
        if self.banner.SetAlpha then
            self.banner:SetAlpha(1)
        end
        self.banner:Hide()
    end
end

function Notifications:HandleEvent(event, arg1)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "UNIT_SPELLCAST_START" then
        self:HandleIncomingCCCast(arg1, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:HandleIncomingCCCast(arg1, true)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Reset()
    end
end
