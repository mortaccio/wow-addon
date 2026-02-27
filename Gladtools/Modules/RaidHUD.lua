local _, GT = ...

local RaidHUD = {}
GT.RaidHUD = RaidHUD
GT:RegisterModule("RaidHUD", RaidHUD)

RaidHUD.UPDATE_INTERVAL = 0.12
RaidHUD.MAX_AURA_SCAN = 40
RaidHUD.DEFAULT_POINTER_COLOR = { 0.84, 0.84, 0.86 }
RaidHUD.DEFAULT_CC_FALLBACK_DURATION = 8
RaidHUD.DEFAULT_DEFENSIVE_ICON = 134400
RaidHUD.DEFAULT_CC_ICON = 136116
RaidHUD.DEFAULT_POINTER_TEXTURE = "Interface/Minimap/Minimap-QuestArrow"
RaidHUD.DEFAULT_CC_CATEGORIES = {
    stun = true,
    incap = true,
    fear = true,
    silence = true,
    root = true,
    disarm = true,
}
RaidHUD.CC_CATEGORY_PRIORITY = {
    stun = 7,
    incap = 6,
    fear = 5,
    silence = 4,
    root = 3,
    disarm = 2,
    taunt = 1,
}

local function getNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    elseif value > maxValue then
        return maxValue
    end
    return value
end

local function isInCombat()
    if InCombatLockdown then
        return InCombatLockdown() and true or false
    end
    return false
end

local function setTextureColor(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a or 1)
    end
end

local function buildAuraData(...)
    local first = ...
    if type(first) == "table" then
        local aura = first
        return {
            name = aura.name,
            icon = aura.icon or aura.iconFileID,
            duration = aura.duration,
            expirationTime = aura.expirationTime,
            spellID = aura.spellID or aura.spellId,
            sourceUnit = aura.sourceUnit or aura.casterUnit,
            sourceGUID = aura.sourceGUID,
            debuffType = aura.dispelName,
        }
    end

    local name, icon, _, debuffType, duration, expirationTime, sourceUnit, _, _, spellID = ...
    if not name then
        return nil
    end

    return {
        name = name,
        icon = icon,
        duration = duration,
        expirationTime = expirationTime,
        spellID = spellID,
        sourceUnit = sourceUnit,
        sourceGUID = nil,
        debuffType = debuffType,
    }
end

local function getCompactUnit(frame)
    if type(frame) ~= "table" then
        return nil
    end

    if type(frame.displayedUnit) == "string" and frame.displayedUnit ~= "" then
        return frame.displayedUnit
    end

    if type(frame.unit) == "string" and frame.unit ~= "" then
        return frame.unit
    end

    if frame.GetAttribute then
        local ok, attributeUnit = pcall(function()
            return frame:GetAttribute("unit")
        end)
        if ok and type(attributeUnit) == "string" and attributeUnit ~= "" then
            return attributeUnit
        end
    end

    if SecureButton_GetUnit then
        local ok, secureUnit = pcall(SecureButton_GetUnit, frame)
        if ok and type(secureUnit) == "string" and secureUnit ~= "" then
            return secureUnit
        end
    end

    return nil
end

local function getCompactHealthBar(frame)
    if not frame then
        return nil
    end

    if frame.healthBar then
        return frame.healthBar
    end

    if frame.HealthBar then
        return frame.HealthBar
    end

    if frame.healthbar then
        return frame.healthbar
    end

    if frame.HealthBarsContainer and frame.HealthBarsContainer.HealthBar then
        return frame.HealthBarsContainer.HealthBar
    end

    return nil
end

local function createIconFrame(parent)
    local icon = CreateFrame("Frame", nil, parent, "BackdropTemplate")

    if icon.SetBackdrop then
        icon:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        icon:SetBackdropColor(0.02, 0.02, 0.02, 0.90)
        if icon.SetBackdropBorderColor then
            icon:SetBackdropBorderColor(0.12, 0.12, 0.14, 0.95)
        end
    end

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(icon)
    if icon.texture.SetTexCoord then
        icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)

    icon.timerText = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    icon.timerText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 0)
    icon.timerText:SetTextColor(0.96, 0.96, 1.00)
    if icon.timerText.SetShadowOffset then
        icon.timerText:SetShadowOffset(1, -1)
    end
    if icon.timerText.SetShadowColor then
        icon.timerText:SetShadowColor(0, 0, 0, 1)
    end

    icon:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.spellID and GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(self.spellID)
        elseif self.spellName then
            GameTooltip:SetText(self.spellName)
        else
            GameTooltip:SetText("Aura")
        end

        if self.ccCategory then
            local categoryText = string.upper(self.ccCategory)
            GameTooltip:AddLine("CC: " .. categoryText, 0.80, 0.88, 1.00)
        end

        if self.remaining and self.remaining > 0 then
            GameTooltip:AddLine("Remaining: " .. GT:FormatRemaining(self.remaining), 0.86, 0.88, 0.98)
        end

        GameTooltip:Show()
    end)

    icon:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    icon:Hide()
    return icon
end

local function setIconCooldown(icon, startTime, duration)
    if not (icon and icon.cooldown and startTime and duration and duration > 0) then
        return
    end

    if CooldownFrame_Set then
        CooldownFrame_Set(icon.cooldown, startTime, duration, true)
    elseif icon.cooldown.SetCooldown then
        icon.cooldown:SetCooldown(startTime, duration)
    end
end

local function setIconTimerText(icon, remaining)
    if not (icon and icon.timerText) then
        return
    end

    if not remaining or remaining <= 0 then
        icon.timerText:SetText("")
        return
    end

    icon.timerText:SetText(GT:FormatRemaining(remaining))
    if remaining <= 5 then
        icon.timerText:SetTextColor(1.00, 0.34, 0.34)
    elseif remaining <= 12 then
        icon.timerText:SetTextColor(1.00, 0.86, 0.34)
    else
        icon.timerText:SetTextColor(0.96, 0.96, 1.00)
    end
end

function RaidHUD:Init()
    if not UIParent or not CreateFrame then
        GT:Print("UIParent not available, deferring RaidHUD init")
        return
    end

    self.attached = setmetatable({}, { __mode = "k" })
    self.pendingAttach = setmetatable({}, { __mode = "k" })
    self.framesByUnit = {}
    self.hooksInstalled = false
    self.elapsed = 0
    self.cache = {}

    self.driver = CreateFrame("Frame", "GladtoolsRaidHUDDriver", UIParent)
    if self.driver and self.driver.SetScript then
        self.driver:SetScript("OnUpdate", function(_, elapsed)
            RaidHUD:OnUpdate(elapsed)
        end)
    end

    self:InstallHooks()
    self:SetDriverActive(self:IsEnabled())

    if self.driverActive then
        self:ScanCompactFrames()
        self:UpdateAllAttached()
    end
end

function RaidHUD:GetSettings()
    return GT:GetSetting({ "raidHUD" }) or {}
end

function RaidHUD:IsEnabled()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local raidHUD = settings.raidHUD
    return raidHUD and raidHUD.enabled and true or false
end

function RaidHUD:SetDriverActive(active)
    self.driverActive = active and true or false

    if not self.driver then
        return
    end

    if self.driverActive then
        self.elapsed = 0
        if self.driver.Show then
            self.driver:Show()
        end
    else
        self.elapsed = 0
        if self.driver.Hide then
            self.driver:Hide()
        end
        self:HideAllAttached()
    end
end

function RaidHUD:IsLikelyBlizzardCompactFrame(frame)
    if not frame then
        return false
    end

    local frameName = frame.GetName and frame:GetName()
    if type(frameName) == "string" then
        if frameName:match("^CompactRaidFrame") or frameName:match("^CompactPartyFrame") or frameName:match("^CompactArenaFrame") or frameName:match("^CompactUnitFrame") then
            return true
        end
    end

    local parent = frame.GetParent and frame:GetParent()
    for _ = 1, 8 do
        if not parent then
            break
        end

        if parent == CompactRaidFrameContainer or parent == CompactPartyFrame or parent == CompactArenaFrame then
            return true
        end

        local parentName = parent.GetName and parent:GetName()
        if parentName == "CompactRaidFrameContainer" or parentName == "CompactPartyFrame" or parentName == "CompactArenaFrame" then
            return true
        end

        parent = parent.GetParent and parent:GetParent()
    end

    return false
end

function RaidHUD:ShouldAttachToFrame(frame)
    if not frame then
        return false
    end

    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end

    local unit = getCompactUnit(frame)
    if type(unit) ~= "string" or unit == "" then
        return false
    end

    local settings = self:GetSettings()
    if settings.attachOnlyBlizzard ~= false and not self:IsLikelyBlizzardCompactFrame(frame) then
        return false
    end

    return true
end

function RaidHUD:BuildSpellLookup(spellList)
    local idLookup = {}
    local hasIds = false

    if type(spellList) == "table" then
        for _, spellID in ipairs(spellList) do
            if type(spellID) == "number" and spellID > 0 then
                idLookup[spellID] = true
                hasIds = true
            end
        end
    end

    return idLookup, hasIds
end

function RaidHUD:GetSpellCaches(settings)
    local cacheKey = settings
    if self.cache.settingsRef == cacheKey then
        return self.cache
    end

    self.cache = {
        settingsRef = cacheKey,
        defensiveLookup = {},
        hasDefensiveLookup = false,
        ccLookup = {},
        hasCCLookup = false,
        ccCategories = {},
    }

    local cooldownSettings = settings.cooldowns or {}
    local ccSettings = settings.cc or {}

    self.cache.defensiveLookup, self.cache.hasDefensiveLookup = self:BuildSpellLookup(cooldownSettings.defensiveSpells)
    self.cache.ccLookup, self.cache.hasCCLookup = self:BuildSpellLookup(ccSettings.spells)

    local configuredCategories = ccSettings.categories
    if type(configuredCategories) == "table" and next(configuredCategories) then
        for category, enabled in pairs(configuredCategories) do
            if enabled then
                self.cache.ccCategories[category] = true
            end
        end
    else
        for category, enabled in pairs(self.DEFAULT_CC_CATEGORIES) do
            if enabled then
                self.cache.ccCategories[category] = true
            end
        end
    end

    return self.cache
end

function RaidHUD:IsDefensiveEntry(entry, cache)
    if type(entry) ~= "table" then
        return false
    end

    if cache and cache.hasDefensiveLookup then
        return cache.defensiveLookup[entry.spellID] and true or false
    end

    if entry.category == "defensive" then
        return true
    end

    if entry.sourceType == "raidDefensive" then
        return true
    end

    return false
end

function RaidHUD:IsCCAura(auraData, cache)
    if type(auraData) ~= "table" then
        return false, nil
    end

    local spellID = auraData.spellID
    if type(spellID) == "number" and cache and cache.hasCCLookup and cache.ccLookup[spellID] then
        return true, (GT.DRData and GT.DRData.spellToCategory and GT.DRData.spellToCategory[spellID]) or nil
    end

    local category = nil
    if type(spellID) == "number" and GT.DRData and GT.DRData.spellToCategory then
        category = GT.DRData.spellToCategory[spellID]
    end

    if category and cache and cache.ccCategories and cache.ccCategories[category] then
        return true, category
    end

    return false, category
end

function RaidHUD:GetUnitGUID(unit)
    if not unit then
        return nil
    end

    if GT.UnitMap and GT.UnitMap.RefreshUnit then
        GT.UnitMap:RefreshUnit(unit)
    end

    if GT.UnitMap and GT.UnitMap.GetGUIDForUnit then
        local guid = GT.UnitMap:GetGUIDForUnit(unit)
        if guid then
            return guid
        end
    end

    if UnitGUID then
        return UnitGUID(unit)
    end

    return nil
end

function RaidHUD:GetUnitClassColor(unit, pointerSettings)
    local classToken = nil

    if UnitClass then
        local _, token = UnitClass(unit)
        classToken = token
    end

    if not classToken and GT.UnitMap and GT.UnitMap.GetInfoByGUID then
        local guid = self:GetUnitGUID(unit)
        local info = guid and GT.UnitMap:GetInfoByGUID(guid)
        classToken = info and info.classFile or nil
    end

    local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] or nil
    if classColor then
        return classColor.r, classColor.g, classColor.b
    end

    local fallback = pointerSettings and pointerSettings.fallbackColor
    if type(fallback) == "table" then
        local r = tonumber(fallback[1]) or self.DEFAULT_POINTER_COLOR[1]
        local g = tonumber(fallback[2]) or self.DEFAULT_POINTER_COLOR[2]
        local b = tonumber(fallback[3]) or self.DEFAULT_POINTER_COLOR[3]
        return r, g, b
    end

    return self.DEFAULT_POINTER_COLOR[1], self.DEFAULT_POINTER_COLOR[2], self.DEFAULT_POINTER_COLOR[3]
end

function RaidHUD:GetFrameScaleFactor(healthBar)
    if not healthBar or not healthBar.GetWidth then
        return 1
    end

    local width = healthBar:GetWidth() or 0
    if width <= 0 then
        return 1
    end

    return clamp(width / 78, 0.75, 1.55)
end

function RaidHUD:TrackFrameUnit(frame, unit)
    local state = self.attached and self.attached[frame]
    if not state then
        return
    end

    local previousUnit = state.unit
    if previousUnit == unit then
        return
    end

    if previousUnit and self.framesByUnit[previousUnit] then
        self.framesByUnit[previousUnit][frame] = nil
        if not next(self.framesByUnit[previousUnit]) then
            self.framesByUnit[previousUnit] = nil
        end
    end

    state.unit = unit

    if unit then
        local bucket = self.framesByUnit[unit]
        if not bucket then
            bucket = {}
            self.framesByUnit[unit] = bucket
        end
        bucket[frame] = true
    end
end

function RaidHUD:CreateHUDForFrame(frame, healthBar)
    local hud = CreateFrame("Frame", nil, frame)
    hud:SetAllPoints(frame)
    hud:SetFrameStrata(frame.GetFrameStrata and frame:GetFrameStrata() or "MEDIUM")
    local frameLevel = frame.GetFrameLevel and frame:GetFrameLevel() or 1
    hud:SetFrameLevel(frameLevel + 7)

    hud.healthBar = healthBar

    hud.cooldownAnchor = CreateFrame("Frame", nil, hud)
    hud.cooldownAnchor:SetSize(1, 1)
    hud.cooldownIcons = {}

    hud.ccAnchor = CreateFrame("Frame", nil, hud)
    hud.ccAnchor:SetSize(1, 1)
    hud.ccIcons = {}

    hud.pointer = hud:CreateTexture(nil, "OVERLAY")
    hud.pointer:SetTexture(self.DEFAULT_POINTER_TEXTURE)
    if hud.pointer.SetTexCoord then
        hud.pointer:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    end

    hud:Hide()
    return hud
end

function RaidHUD:EnsureAttached(frame)
    if not self.attached then
        return nil
    end

    local state = self.attached[frame]
    if state then
        local healthBar = getCompactHealthBar(frame)
        if healthBar then
            state.hud.healthBar = healthBar
        end
        return state
    end

    if isInCombat() then
        self.pendingAttach[frame] = true
        return nil
    end

    local healthBar = getCompactHealthBar(frame)
    if not healthBar then
        return nil
    end

    local hud = self:CreateHUDForFrame(frame, healthBar)
    state = {
        frame = frame,
        hud = hud,
        unit = nil,
    }

    self.attached[frame] = state
    frame.GladtoolsRaidHUD = hud

    return state
end

function RaidHUD:EnsureIconCount(iconList, parent, count)
    for index = 1, count do
        if not iconList[index] then
            iconList[index] = createIconFrame(parent)
        end
    end
end

function RaidHUD:HideIcons(iconList)
    if not iconList then
        return
    end

    for _, icon in ipairs(iconList) do
        icon.spellID = nil
        icon.spellName = nil
        icon.remaining = nil
        icon.ccCategory = nil
        icon:Hide()
    end
end

function RaidHUD:HideFrameHUD(frame)
    local state = self.attached and self.attached[frame]
    if not state then
        return
    end

    local hud = state.hud
    if hud then
        self:HideIcons(hud.cooldownIcons)
        self:HideIcons(hud.ccIcons)
        if hud.pointer then
            hud.pointer:Hide()
        end
        hud:Hide()
    end
end

function RaidHUD:HideAllAttached()
    for frame in pairs(self.attached or {}) do
        self:HideFrameHUD(frame)
    end
end

function RaidHUD:GetCooldownEntriesForUnit(unit, cache, settings)
    local cooldownSettings = settings.cooldowns or {}
    if cooldownSettings.enabled == false then
        return {}
    end

    local isFriendly = UnitIsFriend and UnitIsFriend("player", unit) and true or false
    if isFriendly and cooldownSettings.showFriendly == false then
        return {}
    end
    if (not isFriendly) and cooldownSettings.showEnemy == false then
        return {}
    end

    if GT.IsCombatDataRestricted and GT:IsCombatDataRestricted() then
        return {}
    end

    local tracker = GT.CooldownTracker
    if not (tracker and tracker.GetUnitCooldowns) then
        return {}
    end

    local guid = self:GetUnitGUID(unit)
    if not guid then
        return {}
    end

    local entries = tracker:GetUnitCooldowns(guid)
    if #entries == 0 then
        return entries
    end

    local filtered = {}
    for _, entry in ipairs(entries) do
        if self:IsDefensiveEntry(entry, cache) then
            filtered[#filtered + 1] = entry
        end
    end

    return filtered
end

function RaidHUD:UpdateCooldownIcons(state, unit, settings, cache, now, scale)
    local hud = state.hud
    if not hud then
        return
    end

    local cooldownSettings = settings.cooldowns or {}
    if cooldownSettings.enabled == false then
        self:HideIcons(hud.cooldownIcons)
        return
    end

    local healthBar = hud.healthBar
    if not healthBar then
        self:HideIcons(hud.cooldownIcons)
        return
    end

    local maxIcons = clamp(tonumber(cooldownSettings.maxIcons) or 3, 1, 8)
    local iconSize = clamp((tonumber(cooldownSettings.iconSize) or 26) * scale, 16, 64)

    hud.cooldownAnchor:ClearAllPoints()
    hud.cooldownAnchor:SetPoint(
        "LEFT",
        healthBar,
        "RIGHT",
        tonumber(cooldownSettings.offsetX) or 6,
        tonumber(cooldownSettings.offsetY) or 0
    )
    hud.cooldownAnchor:SetSize((iconSize + 2) * maxIcons, iconSize)

    self:EnsureIconCount(hud.cooldownIcons, hud.cooldownAnchor, maxIcons)

    local entries = self:GetCooldownEntriesForUnit(unit, cache, settings)

    for index = 1, maxIcons do
        local icon = hud.cooldownIcons[index]
        local entry = entries[index]

        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", hud.cooldownAnchor, "LEFT", (index - 1) * (iconSize + 2), 0)

        if entry then
            local remaining = math.max(0, (entry.endTime or now) - now)
            icon.spellID = entry.spellID
            icon.spellName = entry.spellName
            icon.remaining = remaining
            icon.ccCategory = nil
            icon.texture:SetTexture(entry.icon or self.DEFAULT_DEFENSIVE_ICON)
            setIconTimerText(icon, remaining)
            setIconCooldown(icon, entry.startTime or now, entry.duration or remaining)

            if icon.SetBackdropBorderColor then
                icon:SetBackdropBorderColor(0.24, 0.74, 0.98, 0.95)
            end

            icon:Show()
        else
            icon.spellID = nil
            icon.spellName = nil
            icon.remaining = nil
            icon.ccCategory = nil
            icon:Hide()
        end
    end

    for index = maxIcons + 1, #hud.cooldownIcons do
        hud.cooldownIcons[index]:Hide()
    end
end

function RaidHUD:CollectCCAuras(unit, settings, cache, now)
    local ccSettings = settings.cc or {}
    if ccSettings.enabled == false then
        return {}
    end

    local isFriendly = UnitIsFriend and UnitIsFriend("player", unit) and true or false
    if isFriendly and ccSettings.showFriendly == false then
        return {}
    end
    if (not isFriendly) and ccSettings.showEnemy == false then
        return {}
    end

    if UnitExists and not UnitExists(unit) then
        return {}
    end

    local list = {}
    local dedupe = {}

    local function addAura(auraData)
        local isCC, category = self:IsCCAura(auraData, cache)
        if not isCC then
            return
        end

        local spellID = auraData.spellID
        if type(spellID) == "number" and dedupe[spellID] then
            return
        end

        if type(spellID) == "number" then
            dedupe[spellID] = true
        end

        local duration = tonumber(auraData.duration) or 0
        local expirationTime = tonumber(auraData.expirationTime) or 0
        local remaining = 0

        if expirationTime > now then
            remaining = expirationTime - now
        end

        if duration <= 0 then
            if remaining > 0 then
                duration = remaining
            else
                duration = tonumber(ccSettings.fallbackDuration) or self.DEFAULT_CC_FALLBACK_DURATION
            end
        end

        local startTime = (expirationTime > 0 and duration > 0) and (expirationTime - duration) or now

        local spellName = auraData.name
        local icon = auraData.icon

        if (not spellName or spellName == "") and spellID then
            spellName = GT:GetSpellName(spellID, "Control")
        end

        if not icon and spellID then
            local _, spellIcon = GT:GetSpellNameAndIcon(spellID)
            icon = spellIcon
        end

        list[#list + 1] = {
            spellID = spellID,
            spellName = spellName,
            icon = icon,
            category = category,
            startTime = startTime,
            duration = duration,
            remaining = remaining,
        }
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for index = 1, self.MAX_AURA_SCAN do
            local auraData = buildAuraData(C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL"))
            if not auraData then
                break
            end
            addAura(auraData)
        end
    elseif UnitAura then
        for index = 1, self.MAX_AURA_SCAN do
            local auraData = buildAuraData(UnitAura(unit, index, "HARMFUL"))
            if not auraData then
                break
            end
            addAura(auraData)
        end
    end

    table.sort(list, function(a, b)
        local aPriority = self.CC_CATEGORY_PRIORITY[a.category] or 0
        local bPriority = self.CC_CATEGORY_PRIORITY[b.category] or 0
        if aPriority == bPriority then
            return (a.remaining or 0) > (b.remaining or 0)
        end
        return aPriority > bPriority
    end)

    return list
end

function RaidHUD:UpdateCCIcons(state, unit, settings, cache, now, scale)
    local hud = state.hud
    if not hud then
        return
    end

    local ccSettings = settings.cc or {}
    if ccSettings.enabled == false then
        self:HideIcons(hud.ccIcons)
        return
    end

    local healthBar = hud.healthBar
    if not healthBar then
        self:HideIcons(hud.ccIcons)
        return
    end

    local maxIcons = clamp(tonumber(ccSettings.maxIcons) or 2, 1, 6)
    local iconSize = clamp((tonumber(ccSettings.iconSize) or 22) * scale, 14, 56)

    local anchorSide = string.lower(tostring(ccSettings.anchorSide or "left"))
    if anchorSide ~= "left" and anchorSide ~= "right" then
        anchorSide = "left"
    end

    hud.ccAnchor:ClearAllPoints()
    if anchorSide == "left" then
        hud.ccAnchor:SetPoint(
            "RIGHT",
            healthBar,
            "LEFT",
            tonumber(ccSettings.offsetX) or -6,
            tonumber(ccSettings.offsetY) or 0
        )
    else
        hud.ccAnchor:SetPoint(
            "LEFT",
            healthBar,
            "RIGHT",
            tonumber(ccSettings.offsetX) or 6,
            tonumber(ccSettings.offsetY) or 0
        )
    end
    hud.ccAnchor:SetSize((iconSize + 2) * maxIcons, iconSize)

    self:EnsureIconCount(hud.ccIcons, hud.ccAnchor, maxIcons)

    local auras = self:CollectCCAuras(unit, settings, cache, now)

    for index = 1, maxIcons do
        local icon = hud.ccIcons[index]
        local entry = auras[index]

        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()

        if anchorSide == "left" then
            icon:SetPoint("RIGHT", hud.ccAnchor, "RIGHT", -((index - 1) * (iconSize + 2)), 0)
        else
            icon:SetPoint("LEFT", hud.ccAnchor, "LEFT", (index - 1) * (iconSize + 2), 0)
        end

        if entry then
            icon.spellID = entry.spellID
            icon.spellName = entry.spellName
            icon.remaining = entry.remaining
            icon.ccCategory = entry.category
            icon.texture:SetTexture(entry.icon or self.DEFAULT_CC_ICON)
            setIconTimerText(icon, entry.remaining)
            setIconCooldown(icon, entry.startTime, entry.duration)

            local priority = self.CC_CATEGORY_PRIORITY[entry.category] or 0
            if icon.SetBackdropBorderColor then
                if priority >= 6 then
                    icon:SetBackdropBorderColor(1.00, 0.34, 0.34, 0.95)
                elseif priority >= 4 then
                    icon:SetBackdropBorderColor(1.00, 0.72, 0.24, 0.95)
                else
                    icon:SetBackdropBorderColor(0.84, 0.84, 0.92, 0.95)
                end
            end

            icon:Show()
        else
            icon.spellID = nil
            icon.spellName = nil
            icon.remaining = nil
            icon.ccCategory = nil
            icon:Hide()
        end
    end

    for index = maxIcons + 1, #hud.ccIcons do
        hud.ccIcons[index]:Hide()
    end
end

function RaidHUD:UpdatePointer(state, unit, settings, scale)
    local hud = state.hud
    local pointer = hud and hud.pointer
    local pointerSettings = settings.pointer or {}

    if not pointer or pointerSettings.enabled == false then
        if pointer then
            pointer:Hide()
        end
        return
    end

    local healthBar = hud.healthBar
    if not healthBar then
        pointer:Hide()
        return
    end

    local pointerSize = clamp((tonumber(pointerSettings.size) or 32) * scale, 16, 90)
    pointer:SetSize(pointerSize, pointerSize)
    pointer:ClearAllPoints()
    pointer:SetPoint(
        "BOTTOM",
        healthBar,
        "TOP",
        tonumber(pointerSettings.offsetX) or 0,
        tonumber(pointerSettings.offsetY) or 2
    )

    local texturePath = pointerSettings.texture or self.DEFAULT_POINTER_TEXTURE
    pointer:SetTexture(texturePath)

    if pointer.SetTexCoord then
        pointer:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    end

    if pointer.SetRotation then
        local rotation = tonumber(pointerSettings.rotationDegrees) or 0
        pointer:SetRotation(math.rad(rotation))
    end

    local r, g, b = self:GetUnitClassColor(unit, pointerSettings)
    setTextureColor(pointer, r, g, b, 0.95)
    pointer:Show()
end

function RaidHUD:UpdateFrame(frame)
    if not self.driverActive then
        return
    end

    if not self:ShouldAttachToFrame(frame) then
        self:TrackFrameUnit(frame, nil)
        self:HideFrameHUD(frame)
        return
    end

    local state = self:EnsureAttached(frame)
    if not state then
        return
    end

    local unit = getCompactUnit(frame)
    self:TrackFrameUnit(frame, unit)

    if type(unit) ~= "string" or unit == "" then
        self:HideFrameHUD(frame)
        return
    end

    if UnitExists and not UnitExists(unit) then
        self:HideFrameHUD(frame)
        return
    end

    if frame.IsShown and not frame:IsShown() then
        self:HideFrameHUD(frame)
        return
    end

    local healthBar = getCompactHealthBar(frame)
    if not healthBar then
        self:HideFrameHUD(frame)
        return
    end

    state.hud.healthBar = healthBar

    local settings = self:GetSettings()
    local cache = self:GetSpellCaches(settings)
    local now = getNow()
    local scale = self:GetFrameScaleFactor(healthBar)

    state.hud:Show()
    self:UpdatePointer(state, unit, settings, scale)
    self:UpdateCooldownIcons(state, unit, settings, cache, now, scale)
    self:UpdateCCIcons(state, unit, settings, cache, now, scale)
end

function RaidHUD:RefreshUnit(unit)
    if type(unit) ~= "string" or unit == "" then
        return
    end

    local bucket = self.framesByUnit and self.framesByUnit[unit]
    if not bucket then
        return
    end

    for frame in pairs(bucket) do
        self:UpdateFrame(frame)
    end
end

function RaidHUD:UpdateAllAttached()
    for frame in pairs(self.attached or {}) do
        self:UpdateFrame(frame)
    end
end

function RaidHUD:AttachPending()
    if isInCombat() then
        return
    end

    for frame in pairs(self.pendingAttach or {}) do
        self.pendingAttach[frame] = nil
        if self:ShouldAttachToFrame(frame) then
            self:EnsureAttached(frame)
            self:UpdateFrame(frame)
        end
    end
end

function RaidHUD:OnCompactFrameUpdated(frame)
    if not self.driverActive then
        return
    end

    self:UpdateFrame(frame)
end

function RaidHUD:InstallHooks()
    if self.hooksInstalled then
        return
    end

    if type(hooksecurefunc) ~= "function" then
        return
    end

    if type(CompactUnitFrame_UpdateAll) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
            RaidHUD:OnCompactFrameUpdated(frame)
        end)
    end

    if type(CompactUnitFrame_SetUnit) == "function" then
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            RaidHUD:OnCompactFrameUpdated(frame)
        end)
    end

    if type(CompactUnitFrame_UpdateHealth) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
            RaidHUD:OnCompactFrameUpdated(frame)
        end)
    end

    if type(CompactUnitFrame_UpdateAuras) == "function" then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
            RaidHUD:OnCompactFrameUpdated(frame)
        end)
    end

    self.hooksInstalled = true
end

function RaidHUD:ScanCompactFrames()
    if not self.driverActive then
        return
    end

    local visited = setmetatable({}, { __mode = "k" })

    local function pushFrame(frame)
        if not frame or visited[frame] then
            return
        end
        visited[frame] = true
        RaidHUD:UpdateFrame(frame)
    end

    local function walkChildren(parent, depth)
        if not parent or depth > 4 or not parent.GetChildren then
            return
        end

        local children = { parent:GetChildren() }
        for _, child in ipairs(children) do
            pushFrame(child)
            walkChildren(child, depth + 1)
        end
    end

    if CompactRaidFrameContainer then
        pushFrame(CompactRaidFrameContainer)
        walkChildren(CompactRaidFrameContainer, 1)
    end

    if CompactPartyFrame then
        pushFrame(CompactPartyFrame)
        walkChildren(CompactPartyFrame, 1)
    end

    if CompactArenaFrame then
        pushFrame(CompactArenaFrame)
        walkChildren(CompactArenaFrame, 1)
    end

    for index = 1, 80 do
        pushFrame(_G["CompactRaidFrame" .. index])
    end

    for index = 1, 8 do
        pushFrame(_G["CompactPartyFrameMember" .. index])
    end

    for index = 1, 8 do
        pushFrame(_G["CompactArenaFrameMember" .. index])
    end
end

function RaidHUD:OnUpdate(elapsed)
    if not self.driverActive then
        return
    end

    self.elapsed = (self.elapsed or 0) + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:AttachPending()
    self:UpdateAllAttached()
end

function RaidHUD:GetAttachedCounts()
    local attached = 0
    local visible = 0

    for _, state in pairs(self.attached or {}) do
        attached = attached + 1
        if state and state.hud and state.hud.IsShown and state.hud:IsShown() then
            visible = visible + 1
        end
    end

    return attached, visible
end

function RaidHUD:OnSettingsChanged()
    self.cache = {}
    self:SetDriverActive(self:IsEnabled())

    if self.driverActive then
        self:ScanCompactFrames()
        self:UpdateAllAttached()
    else
        self:HideAllAttached()
    end
end

function RaidHUD:HandleEvent(event, arg1)
    if not self.driverActive and event ~= "PLAYER_REGEN_ENABLED" then
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        self:ScanCompactFrames()
        self:UpdateAllAttached()
    elseif event == "GROUP_ROSTER_UPDATE" then
        self:ScanCompactFrames()
        self:UpdateAllAttached()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- New frame attachment is deferred automatically during combat lockdown.
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.driverActive then
            self:AttachPending()
            self:ScanCompactFrames()
            self:UpdateAllAttached()
        end
    elseif event == "UNIT_AURA" or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_CONNECTION" or event == "UNIT_TARGET" then
        self:RefreshUnit(arg1)
    elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_FACTION" then
        self:RefreshUnit(arg1)
    end
end
