local _, GT = ...

local NameplateOverlays = {}
GT.NameplateOverlays = NameplateOverlays
GT:RegisterModule("NameplateOverlays", NameplateOverlays)

NameplateOverlays.UPDATE_INTERVAL = 0.05
NameplateOverlays.PURGE_INTERVAL = 1.0
NameplateOverlays.CC_FALLBACK_DURATION = 8
NameplateOverlays.PLAYER_DEBUFF_FALLBACK_DURATION = 12
NameplateOverlays.MAX_PLATE_COOLDOWNS = 4

NameplateOverlays.CC_CATEGORIES = {
    stun = true,
    incap = true,
    fear = true,
    silence = true,
    root = true,
}

NameplateOverlays.CC_PRIORITY = {
    stun = 5,
    incap = 4,
    fear = 3,
    silence = 2,
    root = 1,
}

local function getNow()
    if GetTime then
        return GetTime()
    end
    return 0
end

local function setTextureColor(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a or 1)
    end
end

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

local function buildAuraData(...)
    local first = ...
    if type(first) == "table" then
        local aura = first
        return {
            name = aura.name,
            icon = aura.icon or aura.iconFileID,
            duration = aura.duration,
            expirationTime = aura.expirationTime,
            spellID = aura.spellId or aura.spellID,
            sourceUnit = aura.sourceUnit or aura.casterUnit,
            sourceGUID = aura.sourceGUID,
        }
    end

    local name, icon, _, _, duration, expirationTime, sourceUnit, _, _, spellID = ...
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

    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local spellName = nil
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            spellName = info and info.name or nil
        elseif GetSpellInfo then
            spellName = GetSpellInfo(spellID)
        end

        if spellName then
            local auraData = buildAuraData(C_UnitAuras.GetAuraDataBySpellName(unit, spellName, filter))
            if auraData and auraData.spellID == spellID then
                return auraData
            end
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

local function applyHealerRoleTexCoords(texture)
    if not texture then
        return
    end

    if texture.SetTexture then
        texture:SetTexture("Interface/LFGFrame/UI-LFG-ICON-ROLES")
    end

    local left, right, top, bottom = nil, nil, nil, nil
    if GetTexCoordsForRole then
        left, right, top, bottom = GetTexCoordsForRole("HEALER")
    end

    if texture.SetTexCoord then
        if left and right and top and bottom then
            texture:SetTexCoord(left, right, top, bottom)
        else
            texture:SetTexCoord(0.26171875, 0.5234375, 0, 0.26171875)
        end
    end
end

local function getNameplateHealthBar(nameplate)
    local unitFrame = nameplate and nameplate.UnitFrame
    if not unitFrame then
        return nil
    end

    if unitFrame.healthBar then
        return unitFrame.healthBar
    end

    local container = unitFrame.HealthBarsContainer
    if container and container.HealthBar then
        return container.HealthBar
    end

    return nil
end

local function createAuraIcon(parent, size)
    local icon = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    icon:SetSize(size, size)

    if icon.SetBackdrop then
        icon:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        icon:SetBackdropColor(0.02, 0.02, 0.02, 0.90)
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
    icon.timerText:SetTextColor(0.98, 0.98, 1.0)
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
        else
            GameTooltip:SetText(self.spellName or "Aura")
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

local function createPlateCastBar(parent)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetSize(130, 14)
    bar:SetPoint("TOP", parent, "BOTTOM", 0, -6)

    if bar.SetBackdrop then
        bar:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        bar:SetBackdropColor(0.03, 0.03, 0.04, 0.90)
        if bar.SetBackdropBorderColor then
            bar:SetBackdropBorderColor(0.18, 0.18, 0.20, 0.95)
        end
    end

    bar.icon = bar:CreateTexture(nil, "ARTWORK")
    bar.icon:SetPoint("TOPLEFT", bar, "TOPLEFT", 2, -2)
    bar.icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", 14, 2)
    if bar.icon.SetTexCoord then
        bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetTexture("Interface/Buttons/WHITE8x8")
    bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT", 16, -2)
    bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 2)
    setTextureColor(bar.bg, 0.09, 0.09, 0.10, 0.96)

    bar.status = CreateFrame("StatusBar", nil, bar)
    bar.status:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
    bar.status:SetPoint("TOPLEFT", bar.bg, "TOPLEFT", 0, 0)
    bar.status:SetPoint("BOTTOMRIGHT", bar.bg, "BOTTOMRIGHT", 0, 0)
    bar.status:SetMinMaxValues(0, 1)
    bar.status:SetValue(0)

    bar.spellText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.spellText:SetPoint("LEFT", bar.status, "LEFT", 3, 0)
    bar.spellText:SetPoint("RIGHT", bar.status, "RIGHT", -30, 0)
    bar.spellText:SetJustifyH("LEFT")
    if bar.spellText.SetShadowOffset then
        bar.spellText:SetShadowOffset(1, -1)
    end
    if bar.spellText.SetShadowColor then
        bar.spellText:SetShadowColor(0, 0, 0, 1)
    end

    bar.timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.timeText:SetPoint("RIGHT", bar.status, "RIGHT", -3, 0)
    bar.timeText:SetJustifyH("RIGHT")

    bar:Hide()
    return bar
end

function NameplateOverlays:Init()
    self.overlaysByUnit = {}
    self.ccAurasByGUID = {}
    self.playerDebuffsByGUID = {}
    self.lastPurge = 0

    self.driver = CreateFrame("Frame", "GladtoolsNameplateOverlaysDriver", UIParent)
    self.driver:SetScript("OnUpdate", function(_, elapsed)
        NameplateOverlays:OnUpdate(elapsed)
    end)

    self.elapsed = 0
    self.playerGUID = UnitGUID and UnitGUID("player") or nil

    self:ScanVisiblePlates()
end

function NameplateOverlays:GetSettings()
    return GT:GetSetting({ "nameplates" }) or {}
end

function NameplateOverlays:IsEnabled()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local plateSettings = settings.nameplates
    if not plateSettings then
        return true
    end

    return plateSettings.enabled ~= false
end

function NameplateOverlays:Reset()
    self.ccAurasByGUID = {}
    self.playerDebuffsByGUID = {}
    self.playerGUID = UnitGUID and UnitGUID("player") or nil

    for unit, overlay in pairs(self.overlaysByUnit or {}) do
        self:HideOverlay(overlay)
        self.overlaysByUnit[unit] = nil
    end
end

function NameplateOverlays:ScanVisiblePlates()
    for index = 1, 40 do
        local unit = "nameplate" .. index
        if UnitExists and UnitExists(unit) then
            self:EnsureOverlay(unit)
        end
    end
end

function NameplateOverlays:CreateOverlay(nameplate)
    local overlay = CreateFrame("Frame", nil, nameplate, "BackdropTemplate")
    overlay:SetAllPoints(nameplate)

    overlay.arenaLabel = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overlay.arenaLabel:SetPoint("BOTTOM", overlay, "TOP", 0, 2)
    overlay.arenaLabel:SetTextColor(0.96, 0.84, 0.30)
    overlay.arenaLabel:SetText("")

    overlay.healerIcon = overlay:CreateTexture(nil, "OVERLAY")
    overlay.healerIcon:SetSize(14, 14)
    overlay.healerIcon:SetPoint("RIGHT", overlay, "LEFT", -3, 0)
    applyHealerRoleTexCoords(overlay.healerIcon)
    overlay.healerIcon:Hide()

    overlay.ccAnchor = CreateFrame("Frame", nil, overlay)
    overlay.ccAnchor:SetPoint("LEFT", overlay, "RIGHT", 5, 0)
    overlay.ccAnchor:SetSize(26, 120)
    overlay.ccIcons = {}

    overlay.playerDebuffAnchor = CreateFrame("Frame", nil, overlay)
    overlay.playerDebuffAnchor:SetPoint("BOTTOM", overlay, "TOP", 0, 15)
    overlay.playerDebuffAnchor:SetSize(120, 16)
    overlay.playerDebuffIcons = {}

    overlay.cooldownAnchor = CreateFrame("Frame", nil, overlay)
    overlay.cooldownAnchor:SetPoint("TOPLEFT", overlay, "BOTTOMLEFT", 0, -6)
    overlay.cooldownAnchor:SetSize(150, 16)
    overlay.cooldownIcons = {}

    overlay.castBar = createPlateCastBar(overlay)
    return overlay
end

function NameplateOverlays:EnsureOverlay(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return nil
    end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then
        return nil
    end

    local overlay = self.overlaysByUnit[unit]
    if overlay and overlay._nameplate == nameplate then
        return overlay
    end

    overlay = self:CreateOverlay(nameplate)
    overlay._nameplate = nameplate
    overlay.unit = unit
    self.overlaysByUnit[unit] = overlay
    return overlay
end

function NameplateOverlays:HideAuraIcons(list)
    if not list then
        return
    end
    for _, icon in ipairs(list) do
        icon.spellID = nil
        icon.spellName = nil
        icon.remaining = nil
        icon:Hide()
    end
end

function NameplateOverlays:HideOverlay(overlay)
    if not overlay then
        return
    end

    if overlay.arenaLabel then
        overlay.arenaLabel:SetText("")
    end
    if overlay.healerIcon then
        overlay.healerIcon:Hide()
    end
    if overlay.castBar then
        overlay.castBar:Hide()
    end
    self:HideAuraIcons(overlay.ccIcons)
    self:HideAuraIcons(overlay.playerDebuffIcons)
    self:HideAuraIcons(overlay.cooldownIcons)
    overlay:Hide()
end

function NameplateOverlays:IsFriendlyUnit(unit)
    return UnitIsFriend and UnitIsFriend("player", unit) and true or false
end

function NameplateOverlays:ShouldShowOverlay(unit)
    if not self:IsEnabled() then
        return false
    end

    if not (UnitExists and UnitExists(unit)) then
        return false
    end

    if UnitIsPlayer and not UnitIsPlayer(unit) then
        return false
    end

    local settings = self:GetSettings()
    if self:IsFriendlyUnit(unit) and not settings.showFriendly then
        return false
    end

    return true
end

function NameplateOverlays:GetArenaIndexForGUID(guid)
    if not guid then
        return nil
    end

    if GT.UnitMap and GT.UnitMap.unitsByGUID then
        local units = GT.UnitMap.unitsByGUID[guid]
        if units then
            for unit in pairs(units) do
                local index = unit:match("^arena(%d)$")
                if index then
                    return tonumber(index)
                end
            end
        end
    end

    if UnitGUID then
        for index = 1, 3 do
            if UnitGUID("arena" .. index) == guid then
                return index
            end
        end
    end

    return nil
end

function NameplateOverlays:EnsureIconCount(list, parent, count, size)
    for index = 1, count do
        if not list[index] then
            list[index] = createAuraIcon(parent, size)
        end
    end
end

function NameplateOverlays:ApplyClassColorHealthBar(unit, overlay, classFile)
    local settings = self:GetSettings()
    if not settings.classColorHealth then
        return
    end

    local healthBar = getNameplateHealthBar(overlay._nameplate)
    if not (healthBar and healthBar.SetStatusBarColor) then
        return
    end

    local r, g, b = GT:GetClassColor(classFile)
    healthBar:SetStatusBarColor(r, g, b, 1)
end

function NameplateOverlays:GetOrCreateAuraBucket(bucket, guid)
    local byGUID = bucket[guid]
    if not byGUID then
        byGUID = {}
        bucket[guid] = byGUID
    end
    return byGUID
end

function NameplateOverlays:SetAuraState(bucket, guid, spellID, data)
    if not guid then
        return
    end

    local byGUID = self:GetOrCreateAuraBucket(bucket, guid)
    if data then
        byGUID[spellID] = data
    else
        byGUID[spellID] = nil
    end

    if not next(byGUID) then
        bucket[guid] = nil
    end
end

function NameplateOverlays:FindVisibleUnitForGUID(guid)
    if not (guid and GT.UnitMap and GT.UnitMap.unitsByGUID) then
        return nil
    end

    local units = GT.UnitMap.unitsByGUID[guid]
    if not units then
        return nil
    end

    local fallbackUnit = nil
    for unit in pairs(units) do
        if UnitExists and UnitExists(unit) then
            if unit:match("^nameplate%d+$") then
                return unit
            end
            fallbackUnit = fallbackUnit or unit
        end
    end

    return fallbackUnit
end

function NameplateOverlays:IsAuraFromPlayer(entry, auraData)
    if not entry or not auraData then
        return false
    end

    local playerGUID = self.playerGUID or (UnitGUID and UnitGUID("player")) or nil
    if not playerGUID then
        return false
    end

    if auraData.sourceUnit and UnitGUID then
        local sourceGUID = UnitGUID(auraData.sourceUnit)
        if sourceGUID then
            return sourceGUID == playerGUID
        end
    end

    if auraData.sourceGUID then
        return auraData.sourceGUID == playerGUID
    end

    if entry.sourceGUID then
        return entry.sourceGUID == playerGUID
    end

    -- Keep entry when source cannot be resolved from aura payload.
    return true
end

function NameplateOverlays:UpdateEntryFromAura(entry, auraData, now)
    if not (entry and auraData) then
        return false
    end

    local duration = tonumber(auraData.duration) or 0
    local expiresAt = tonumber(auraData.expirationTime) or 0

    if duration <= 0 and expiresAt > now then
        duration = expiresAt - now
    end
    if duration < 0 then
        duration = 0
    end

    if expiresAt <= now and duration > 0 then
        expiresAt = now + duration
    elseif expiresAt <= 0 and duration > 0 then
        expiresAt = now + duration
    elseif expiresAt <= 0 and duration <= 0 then
        expiresAt = now + 0.1
        duration = 0.1
    end

    entry.spellName = auraData.name or entry.spellName
    entry.icon = auraData.icon or entry.icon
    entry.duration = duration
    entry.expiresAt = expiresAt
    entry.startTime = expiresAt - duration
    entry.needsResolve = nil
    return true
end

function NameplateOverlays:RefreshBucketFromUnit(bucket, guid, unit, filter, requirePlayerSource, pruneMissing)
    local byGUID = bucket[guid]
    if not (byGUID and unit) then
        return
    end

    if pruneMissing == nil then
        pruneMissing = true
    end

    local now = getNow()
    local toRemove = nil
    for spellID, entry in pairs(byGUID) do
        local auraData = findAuraBySpellID(unit, spellID, filter)
        if auraData and (not requirePlayerSource or self:IsAuraFromPlayer(entry, auraData)) then
            self:UpdateEntryFromAura(entry, auraData, now)
        elseif pruneMissing then
            toRemove = toRemove or {}
            toRemove[#toRemove + 1] = spellID
        end
    end

    if toRemove then
        for _, spellID in ipairs(toRemove) do
            byGUID[spellID] = nil
        end
    end

    if not next(byGUID) then
        bucket[guid] = nil
    end
end

function NameplateOverlays:RefreshTrackedAurasForUnit(unit, guid)
    if not (unit and guid) then
        return
    end

    self:RefreshBucketFromUnit(self.ccAurasByGUID, guid, unit, "HARMFUL", false)
    self:RefreshBucketFromUnit(self.playerDebuffsByGUID, guid, unit, "HARMFUL", true)
end

function NameplateOverlays:GetBucketEntries(bucket, guid)
    local byGUID = bucket[guid]
    if not byGUID then
        return {}
    end

    local now = getNow()
    local list = {}
    for spellID, entry in pairs(byGUID) do
        if not entry.expiresAt or entry.expiresAt > now then
            entry.spellID = spellID
            list[#list + 1] = entry
        end
    end
    return list
end

function NameplateOverlays:PurgeExpiredAuras()
    local now = getNow()
    if now - self.lastPurge < self.PURGE_INTERVAL then
        return
    end

    self.lastPurge = now

    local function purgeBucket(bucket)
        for guid, byGUID in pairs(bucket) do
            for spellID, entry in pairs(byGUID) do
                if entry.expiresAt and entry.expiresAt <= now then
                    byGUID[spellID] = nil
                end
            end
            if not next(byGUID) then
                bucket[guid] = nil
            end
        end
    end

    purgeBucket(self.ccAurasByGUID)
    purgeBucket(self.playerDebuffsByGUID)
end

function NameplateOverlays:UpdateAuraIcon(icon, entry, now, r, g, b)
    icon.spellID = entry.spellID
    icon.spellName = entry.spellName
    icon.texture:SetTexture(entry.icon or 134400)
    local remaining = entry.expiresAt and (entry.expiresAt - now) or 0
    icon.remaining = remaining
    icon.timerText:SetText(GT:FormatRemaining(remaining))

    if icon.SetBackdropBorderColor then
        icon:SetBackdropBorderColor(r or 0.8, g or 0.8, b or 0.85, 0.95)
    end

    if CooldownFrame_Set then
        CooldownFrame_Set(icon.cooldown, entry.startTime or now, entry.duration or 1, true)
    elseif icon.cooldown.SetCooldown then
        icon.cooldown:SetCooldown(entry.startTime or now, entry.duration or 1)
    end

    icon:Show()
end

function NameplateOverlays:ShouldShowPlateCooldowns(isFriendly)
    local settings = self:GetSettings()
    if settings.showCooldowns == false then
        return false
    end

    local cooldownSettings = GT:GetSetting({ "unitFrames", "cooldowns" }) or {}
    if cooldownSettings.enabled == false then
        return false
    end

    if isFriendly then
        return cooldownSettings.showFriendly ~= false
    end

    return cooldownSettings.showEnemy ~= false
end

function NameplateOverlays:CollectPlateCooldowns(guid)
    if not guid then
        return {}
    end

    local list = {}
    local now = getNow()

    local cooldowns = GT.CooldownTracker and GT.CooldownTracker.GetUnitCooldowns and GT.CooldownTracker:GetUnitCooldowns(guid) or {}
    for _, entry in ipairs(cooldowns) do
        if entry and entry.endTime and entry.endTime > now then
            list[#list + 1] = entry
        end
    end

    local trinketsEnabled = GT:GetSetting({ "trinkets", "enabled" })
    if trinketsEnabled then
        local trinket = GT.TrinketTracker and GT.TrinketTracker.GetPrimaryTrinket and GT.TrinketTracker:GetPrimaryTrinket(guid) or nil
        if trinket and trinket.endTime and trinket.endTime > now then
            list[#list + 1] = trinket
        end
    end

    table.sort(list, function(a, b)
        local ap = a.priority or 0
        local bp = b.priority or 0
        if ap == bp then
            return (a.endTime or 0) < (b.endTime or 0)
        end
        return ap > bp
    end)

    return list
end

function NameplateOverlays:UpdateCooldownIcons(overlay, guid, now, isFriendly)
    if not self:ShouldShowPlateCooldowns(isFriendly) then
        self:HideAuraIcons(overlay.cooldownIcons)
        return
    end

    local entries = self:CollectPlateCooldowns(guid)
    if #entries == 0 then
        self:HideAuraIcons(overlay.cooldownIcons)
        return
    end

    local frameCooldownSettings = GT:GetSetting({ "unitFrames", "cooldowns" }) or {}
    local maxIcons = frameCooldownSettings.maxIcons or self.MAX_PLATE_COOLDOWNS
    maxIcons = math.max(1, math.min(self.MAX_PLATE_COOLDOWNS, maxIcons))

    local baseSize = frameCooldownSettings.iconSize or 22
    local iconSize = math.max(12, math.min(16, baseSize - 6))

    local shown = math.min(maxIcons, #entries)
    self:EnsureIconCount(overlay.cooldownIcons, overlay.cooldownAnchor, shown, iconSize)

    local castBarShown = overlay.castBar and overlay.castBar:IsShown()
    local anchorFrame = castBarShown and overlay.castBar or overlay
    local xOffset = castBarShown and 16 or 0
    local yOffset = castBarShown and -2 or -6

    for index = 1, shown do
        local icon = overlay.cooldownIcons[index]
        local entry = entries[index]
        local remaining = math.max(0, (entry.endTime or now) - now)

        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", xOffset + ((index - 1) * (iconSize + 2)), yOffset)

        icon.spellID = entry.spellID
        icon.spellName = entry.spellName
        icon.remaining = remaining
        icon.texture:SetTexture(entry.icon or 134400)
        icon.timerText:SetText(GT:FormatRemaining(remaining))

        if remaining <= 5 then
            icon.timerText:SetTextColor(1, 0.35, 0.35)
        elseif remaining <= 15 then
            icon.timerText:SetTextColor(1, 0.84, 0.34)
        else
            icon.timerText:SetTextColor(0.94, 0.95, 1.0)
        end

        local category = entry.category or "utility"
        local categoryColor = GT.UnitFrames and GT.UnitFrames.CATEGORY_COLORS and GT.UnitFrames.CATEGORY_COLORS[category]
        if icon.SetBackdropBorderColor then
            if categoryColor then
                icon:SetBackdropBorderColor(categoryColor[1], categoryColor[2], categoryColor[3], 0.95)
            else
                icon:SetBackdropBorderColor(0.72, 0.72, 0.76, 0.95)
            end
        end

        if CooldownFrame_Set then
            CooldownFrame_Set(icon.cooldown, entry.startTime or now, entry.duration or 1, true)
        elseif icon.cooldown.SetCooldown then
            icon.cooldown:SetCooldown(entry.startTime or now, entry.duration or 1)
        end

        icon:Show()
    end

    for index = shown + 1, #overlay.cooldownIcons do
        local icon = overlay.cooldownIcons[index]
        icon.spellID = nil
        icon.spellName = nil
        icon.remaining = nil
        icon:Hide()
    end
end

function NameplateOverlays:UpdateCCIcons(overlay, guid, now)
    local settings = self:GetSettings()
    if not settings.showCCDebuffs then
        self:HideAuraIcons(overlay.ccIcons)
        return
    end

    local entries = self:GetBucketEntries(self.ccAurasByGUID, guid)
    if #entries == 0 then
        self:HideAuraIcons(overlay.ccIcons)
        return
    end

    table.sort(entries, function(a, b)
        local ap = self.CC_PRIORITY[a.category] or 0
        local bp = self.CC_PRIORITY[b.category] or 0
        if ap == bp then
            return (a.expiresAt or 0) < (b.expiresAt or 0)
        end
        return ap > bp
    end)

    local shown = math.min(3, #entries)
    self:EnsureIconCount(overlay.ccIcons, overlay.ccAnchor, shown, 22)

    for index = 1, shown do
        local icon = overlay.ccIcons[index]
        local entry = entries[index]
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", overlay.ccAnchor, "TOPLEFT", 0, -((index - 1) * 24))

        local color = GT.UnitFrames and GT.UnitFrames.DR_COLORS and GT.UnitFrames.DR_COLORS[entry.category]
        self:UpdateAuraIcon(icon, entry, now, color and color[1], color and color[2], color and color[3])
    end

    for index = shown + 1, #overlay.ccIcons do
        overlay.ccIcons[index]:Hide()
    end
end

function NameplateOverlays:UpdatePlayerDebuffIcons(overlay, guid, now, isFriendly)
    local settings = self:GetSettings()
    if not settings.showPlayerDebuffs or isFriendly then
        self:HideAuraIcons(overlay.playerDebuffIcons)
        return
    end

    local entries = self:GetBucketEntries(self.playerDebuffsByGUID, guid)
    if #entries == 0 then
        self:HideAuraIcons(overlay.playerDebuffIcons)
        return
    end

    table.sort(entries, function(a, b)
        return (a.expiresAt or 0) < (b.expiresAt or 0)
    end)

    local shown = math.min(5, #entries)
    self:EnsureIconCount(overlay.playerDebuffIcons, overlay.playerDebuffAnchor, shown, 14)

    for index = 1, shown do
        local icon = overlay.playerDebuffIcons[index]
        local entry = entries[index]
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", overlay.playerDebuffAnchor, "LEFT", (index - 1) * 16, 0)
        self:UpdateAuraIcon(icon, entry, now, 0.56, 0.72, 1.0)
    end

    for index = shown + 1, #overlay.playerDebuffIcons do
        overlay.playerDebuffIcons[index]:Hide()
    end
end

function NameplateOverlays:UpdateArenaLabel(overlay, guid)
    local settings = self:GetSettings()
    if not settings.showArenaLabels then
        overlay.arenaLabel:SetText("")
        return
    end

    local index = self:GetArenaIndexForGUID(guid)
    if index then
        overlay.arenaLabel:SetText("Arena " .. tostring(index))
    else
        overlay.arenaLabel:SetText("")
    end
end

function NameplateOverlays:UpdateHealerIcon(overlay, guid)
    local settings = self:GetSettings()
    if not settings.showHealerIcon then
        overlay.healerIcon:Hide()
        return
    end

    if GT.UnitMap and guid and GT.UnitMap:IsHealerGUID(guid) then
        overlay.healerIcon:Show()
    else
        overlay.healerIcon:Hide()
    end
end

function NameplateOverlays:UpdateCastBar(overlay, unit, now)
    local settings = self:GetSettings()
    local bar = overlay.castBar
    if not settings.showCastBars then
        bar:Hide()
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo and UnitCastingInfo(unit)
    local isChannel = false
    if not name then
        name, _, texture, startTimeMS, endTimeMS, _, notInterruptible = UnitChannelInfo and UnitChannelInfo(unit)
        isChannel = true
    end

    if not name or not startTimeMS or not endTimeMS then
        bar:Hide()
        return
    end

    local startTime = startTimeMS / 1000
    local endTime = endTimeMS / 1000
    local duration = math.max(0.1, endTime - startTime)
    local remaining = endTime - now
    if remaining <= 0 then
        bar:Hide()
        return
    end

    bar.icon:SetTexture(texture or 134400)
    bar.status:SetMinMaxValues(0, duration)
    if isChannel then
        bar.status:SetValue(remaining)
        bar.status:SetStatusBarColor(0.26, 0.76, 0.98, 0.95)
    else
        bar.status:SetValue(duration - remaining)
        if notInterruptible then
            bar.status:SetStatusBarColor(0.52, 0.52, 0.52, 0.95)
        else
            bar.status:SetStatusBarColor(0.92, 0.72, 0.20, 0.95)
        end
    end

    bar.spellText:SetText(name)
    bar.timeText:SetText(GT:FormatRemaining(remaining))
    bar:Show()
end

function NameplateOverlays:UpdateOverlay(unit, overlay, now)
    if not self:ShouldShowOverlay(unit) then
        self:HideOverlay(overlay)
        return
    end

    GT.UnitMap:RefreshUnit(unit)
    local guid = GT.UnitMap:GetGUIDForUnit(unit)
    if not guid then
        self:HideOverlay(overlay)
        return
    end

    local _, classFile = UnitClass and UnitClass(unit)
    self:ApplyClassColorHealthBar(unit, overlay, classFile)
    self:RefreshTrackedAurasForUnit(unit, guid)
    self:UpdateArenaLabel(overlay, guid)
    self:UpdateHealerIcon(overlay, guid)
    self:UpdateCCIcons(overlay, guid, now)
    self:UpdatePlayerDebuffIcons(overlay, guid, now, self:IsFriendlyUnit(unit))
    self:UpdateCastBar(overlay, unit, now)
    self:UpdateCooldownIcons(overlay, guid, now, self:IsFriendlyUnit(unit))
    overlay:Show()
end

function NameplateOverlays:UpdateAllPlates()
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return
    end

    local now = getNow()
    for unit, overlay in pairs(self.overlaysByUnit) do
        if UnitExists and UnitExists(unit) then
            self:UpdateOverlay(unit, overlay, now)
        else
            self:HideOverlay(overlay)
            self.overlaysByUnit[unit] = nil
        end
    end
end

function NameplateOverlays:TrackCCAura(subEvent, destGUID, destFlags, spellID, spellName, auraType)
    if type(spellID) ~= "number" or not destGUID then
        return
    end

    if auraType and auraType ~= "DEBUFF" then
        return
    end

    if GT.UnitMap and not GT.UnitMap:IsPlayerControlledSource(destFlags) then
        return
    end

    local category = GT.DRTracker and GT.DRTracker.SPELL_TO_CATEGORY and GT.DRTracker.SPELL_TO_CATEGORY[spellID]
    if not category or not self.CC_CATEGORIES[category] then
        return
    end

    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        local now = getNow()
        local resolvedName, resolvedIcon = getSpellNameAndIcon(spellID)
        local duration = self.CC_FALLBACK_DURATION
        self:SetAuraState(self.ccAurasByGUID, destGUID, spellID, {
            spellName = spellName or resolvedName or tostring(spellID),
            icon = resolvedIcon,
            category = category,
            startTime = now,
            duration = duration,
            expiresAt = now + duration,
        })

        local unit = self:FindVisibleUnitForGUID(destGUID)
        if unit then
            self:RefreshBucketFromUnit(self.ccAurasByGUID, destGUID, unit, "HARMFUL", false, false)
        end
    else
        self:SetAuraState(self.ccAurasByGUID, destGUID, spellID, nil)
    end
end

function NameplateOverlays:TrackPlayerDebuff(subEvent, sourceGUID, destGUID, spellID, spellName, auraType)
    if type(spellID) ~= "number" or not destGUID then
        return
    end

    if auraType and auraType ~= "DEBUFF" then
        return
    end

    if subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        local playerGUID = self.playerGUID or (UnitGUID and UnitGUID("player")) or nil
        if not playerGUID or sourceGUID ~= playerGUID then
            return
        end

        local now = getNow()
        local resolvedName, resolvedIcon = getSpellNameAndIcon(spellID)
        local duration = self.PLAYER_DEBUFF_FALLBACK_DURATION
        self:SetAuraState(self.playerDebuffsByGUID, destGUID, spellID, {
            spellName = spellName or resolvedName or tostring(spellID),
            icon = resolvedIcon,
            sourceGUID = sourceGUID,
            startTime = now,
            duration = duration,
            expiresAt = now + duration,
        })

        local unit = self:FindVisibleUnitForGUID(destGUID)
        if unit then
            self:RefreshBucketFromUnit(self.playerDebuffsByGUID, destGUID, unit, "HARMFUL", true, false)
        end
    else
        self:SetAuraState(self.playerDebuffsByGUID, destGUID, spellID, nil)
    end
end

function NameplateOverlays:HandleCombatLog()
    if not CombatLogGetCurrentEventInfo then
        return
    end

    local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, destFlags, _, spellID, spellName, _, auraType = CombatLogGetCurrentEventInfo()
    if subEvent == "SPELL_AURA_APPLIED"
        or subEvent == "SPELL_AURA_REFRESH"
        or subEvent == "SPELL_AURA_REMOVED"
        or subEvent == "SPELL_AURA_BROKEN"
    then
        self:TrackCCAura(subEvent, destGUID, destFlags, spellID, spellName, auraType)
        self:TrackPlayerDebuff(subEvent, sourceGUID, destGUID, spellID, spellName, auraType)
        return
    end

    if subEvent == "SPELL_AURA_BROKEN_SPELL" or subEvent == "SPELL_DISPEL" then
        local _, _, _, breakSourceGUID, _, _, _, breakDestGUID, _, breakDestFlags, _, _, _, _, extraSpellID, extraSpellName, _, extraAuraType = CombatLogGetCurrentEventInfo()
        self:TrackCCAura("SPELL_AURA_REMOVED", breakDestGUID, breakDestFlags, extraSpellID, extraSpellName, extraAuraType)
        self:TrackPlayerDebuff("SPELL_AURA_REMOVED", breakSourceGUID, breakDestGUID, extraSpellID, extraSpellName, extraAuraType)
    end

    if subEvent == "UNIT_DIED" then
        self.ccAurasByGUID[destGUID] = nil
        self.playerDebuffsByGUID[destGUID] = nil
    end
end

function NameplateOverlays:OnUpdate(elapsed)
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self.playerGUID = UnitGUID and UnitGUID("player") or self.playerGUID
    self:PurgeExpiredAuras()
    self:UpdateAllPlates()
end

function NameplateOverlays:OnSettingsChanged()
    if not self:IsEnabled() then
        for _, overlay in pairs(self.overlaysByUnit) do
            self:HideOverlay(overlay)
        end
        return
    end

    self:UpdateAllPlates()
end

function NameplateOverlays:HandleEvent(event, arg1)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local overlay = self:EnsureOverlay(arg1)
        if overlay then
            self:UpdateOverlay(arg1, overlay, getNow())
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local overlay = self.overlaysByUnit[arg1]
        if overlay then
            self:HideOverlay(overlay)
        end
        self.overlaysByUnit[arg1] = nil
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:Reset()
        self:ScanVisiblePlates()
    end
end
