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

local function getNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

local function getSpellName(spellID, fallback)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end

    if GetSpellInfo then
        local name = GetSpellInfo(spellID)
        if name then
            return name
        end
    end

    return fallback or ("Spell " .. tostring(spellID))
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

    self:CreateBanner()

    self.driver = CreateFrame("Frame", "GladtoolsNotificationDriver", UIParent)
    self.driver:SetScript("OnUpdate", function(_, elapsed)
        Notifications:OnUpdate(elapsed)
    end)
end

function Notifications:CreateBanner()
    local frame = CreateFrame("Frame", "GladtoolsNotificationBanner", UIParent, "BackdropTemplate")
    frame:SetSize(860, 34)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -94)

    if frame.SetFrameStrata then
        frame:SetFrameStrata("HIGH")
    end
    if frame.SetFrameLevel then
        frame:SetFrameLevel(30)
    end

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        frame:SetBackdropColor(0.08, 0.03, 0.03, 0.84)
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0.62, 0.16, 0.16, 0.95)
        end
    end

    frame.accent = frame:CreateTexture(nil, "BORDER")
    frame.accent:SetTexture("Interface/Buttons/WHITE8x8")
    frame.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.accent:SetHeight(2)
    setTextureColor(frame.accent, 1, 0.25, 0.25, 0.90)

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

    local category = GT.DRTracker and GT.DRTracker.SPELL_TO_CATEGORY and GT.DRTracker.SPELL_TO_CATEGORY[spellID]
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

function Notifications:NormalizeCCState()
    local now = getNow()

    for guid, state in pairs(self.healerCCByGUID) do
        local count = 0
        for spellID, entry in pairs(state.spells) do
            if entry.expiresAt and entry.expiresAt <= now then
                state.spells[spellID] = nil
            else
                count = count + 1
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
        local resolvedName = spellName or getSpellName(spellID)
        state.spells[spellID] = {
            spellID = spellID,
            spellName = resolvedName,
            category = category,
            expiresAt = getNow() + self.CC_FALLBACK_SECONDS,
        }
        state.lastSpellName = resolvedName
        state.lastCategory = category
        state.lastApplied = getNow()
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

    if entry.category ~= "offensive" then
        return false
    end

    return (entry.priority or 0) >= self.BURST_PRIORITY_MIN
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

    local category = GT.DRTracker and GT.DRTracker.SPELL_TO_CATEGORY and GT.DRTracker.SPELL_TO_CATEGORY[spellID]
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
    local entry = GT:GetCooldownEntryForSpell(spellID, classFile)
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
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:NormalizeCCState()
    self:UpdateBanner(getNow())
end

function Notifications:OnSettingsChanged()
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
