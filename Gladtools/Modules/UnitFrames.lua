local _, GT = ...

local UnitFrames = {}
GT.UnitFrames = UnitFrames
GT:RegisterModule("UnitFrames", UnitFrames)

UnitFrames.UPDATE_INTERVAL = 0.1

UnitFrames.UNITS = {
    enemy = { "arena1", "arena2", "arena3" },
    friendly = { "player", "party1", "party2", "party3", "party4" },
    near = { "party1", "party2", "party3", "party4" },
}

UnitFrames.GROUP_DIMENSIONS = {
    enemy = { width = 252, height = 66 },
    friendly = { width = 252, height = 66 },
    near = { width = 226, height = 58 },
}

UnitFrames.GROUP_SPACING = {
    enemy = 72,
    friendly = 72,
    near = 62,
}

UnitFrames.CATEGORY_COLORS = {
    offensive = { 0.94, 0.26, 0.26 },
    defensive = { 0.28, 0.78, 0.98 },
    utility = { 0.85, 0.70, 0.24 },
    interrupt = { 0.96, 0.52, 0.14 },
    trinket = { 0.90, 0.58, 0.18 },
}

UnitFrames.DR_COLORS = {
    stun = { 0.92, 0.24, 0.20 },
    incap = { 0.90, 0.66, 0.18 },
    fear = { 0.70, 0.40, 0.90 },
    silence = { 0.46, 0.62, 0.98 },
    root = { 0.38, 0.82, 0.48 },
}

local DEFAULT_CATEGORY_COLOR = { 0.70, 0.70, 0.74 }

local function setTextureColor(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a or 1)
    end
end

local function setBackdrop(frame, fancy)
    if not frame.SetBackdrop then
        return
    end

    if frame._fancyApplied == fancy then
        return
    end

    frame._fancyApplied = fancy

    if fancy then
        frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.03, 0.03, 0.04, 0.86)
    else
        frame:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.06, 0.06, 0.07, 0.78)
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0.18, 0.18, 0.20, 0.95)
        end
    end
end

local function applyIconColor(icon, r, g, b)
    if icon and icon.SetBackdropBorderColor then
        icon:SetBackdropBorderColor(r, g, b, 0.95)
    end

    if icon and icon.categoryAccent then
        setTextureColor(icon.categoryAccent, r, g, b, 0.95)
    end
end

local function createIcon(parent)
    local icon = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    icon:SetSize(22, 22)

    if icon.SetBackdrop then
        icon:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        icon:SetBackdropColor(0.01, 0.01, 0.01, 0.88)
    end

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(icon)
    if icon.texture.SetTexCoord then
        icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    icon.categoryAccent = icon:CreateTexture(nil, "OVERLAY")
    icon.categoryAccent:SetTexture("Interface/Buttons/WHITE8x8")
    icon.categoryAccent:SetPoint("TOPLEFT", icon, "TOPLEFT", 1, -1)
    icon.categoryAccent:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -1, -1)
    icon.categoryAccent:SetHeight(2)

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)

    icon.timerText = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    icon.timerText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 0)
    icon.timerText:SetTextColor(0.95, 0.95, 0.98)
    if icon.timerText.SetShadowOffset then
        icon.timerText:SetShadowOffset(1, -1)
    end
    if icon.timerText.SetShadowColor then
        icon.timerText:SetShadowColor(0, 0, 0, 1)
    end

    applyIconColor(icon, DEFAULT_CATEGORY_COLOR[1], DEFAULT_CATEGORY_COLOR[2], DEFAULT_CATEGORY_COLOR[3])

    icon:Hide()
    return icon
end

local function createDRBadge(parent)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(48, 14)

    badge.fill = badge:CreateTexture(nil, "BACKGROUND")
    badge.fill:SetAllPoints(badge)
    badge.fill:SetTexture("Interface/Buttons/WHITE8x8")

    if badge.SetBackdrop then
        badge:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        badge:SetBackdropColor(0.02, 0.02, 0.02, 0.80)
    end

    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    badge.text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badge.text:SetTextColor(1, 1, 1)
    if badge.text.SetShadowOffset then
        badge.text:SetShadowOffset(1, -1)
    end
    if badge.text.SetShadowColor then
        badge.text:SetShadowColor(0, 0, 0, 1)
    end

    badge:Hide()
    return badge
end

local function formatDRNext(nextMultiplier)
    if nextMultiplier <= 0 then
        return "IMM"
    end

    local percent = math.floor((nextMultiplier * 100) + 0.5)
    return tostring(percent)
end

function UnitFrames:Init()
    self.frames = {
        enemy = {},
        friendly = {},
        near = {},
    }

    self.frameByUnit = {
        enemy = {},
        friendly = {},
        near = {},
    }

    self.driver = CreateFrame("Frame", "GladtoolsUnitFramesDriver", UIParent)
    self.driver:SetScript("OnUpdate", function(_, elapsed)
        UnitFrames:OnUpdate(elapsed)
    end)

    self.elapsed = 0
    self:CreateAllFrames()
    self:RefreshLayout()
end

function UnitFrames:GetGroupDimensions(groupName)
    local dims = self.GROUP_DIMENSIONS[groupName]
    if not dims then
        return 252, 66
    end

    return dims.width or 252, dims.height or 66
end

function UnitFrames:CreateAllFrames()
    local groupOrder = { "enemy", "friendly", "near" }
    for _, groupName in ipairs(groupOrder) do
        local units = self.UNITS[groupName]
        for index, unit in ipairs(units) do
            local frame = self:CreateUnitFrame(groupName, unit, index)
            self.frames[groupName][#self.frames[groupName] + 1] = frame
            self.frameByUnit[groupName][unit] = frame
        end
    end
end

function UnitFrames:CreateUnitFrame(groupName, unit, index)
    local width, height = self:GetGroupDimensions(groupName)

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame.unit = unit
    frame.groupName = groupName
    frame.index = index

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(frame)
    frame.bg:SetTexture("Interface/Buttons/WHITE8x8")
    setTextureColor(frame.bg, 0.02, 0.02, 0.03, 0.68)

    frame.topAccent = frame:CreateTexture(nil, "BORDER")
    frame.topAccent:SetTexture("Interface/Buttons/WHITE8x8")
    frame.topAccent:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.topAccent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.topAccent:SetHeight(2)
    setTextureColor(frame.topAccent, 0.45, 0.45, 0.48, 0.95)

    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.nameText:SetPoint("TOPLEFT", 10, -7)
    frame.nameText:SetWidth(width - 118)
    frame.nameText:SetJustifyH("LEFT")
    if frame.nameText.SetShadowOffset then
        frame.nameText:SetShadowOffset(1, -1)
    end
    if frame.nameText.SetShadowColor then
        frame.nameText:SetShadowColor(0, 0, 0, 1)
    end

    frame.healthBarBG = frame:CreateTexture(nil, "ARTWORK")
    frame.healthBarBG:SetTexture("Interface/Buttons/WHITE8x8")
    frame.healthBarBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -22)
    frame.healthBarBG:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -22)
    frame.healthBarBG:SetHeight(groupName == "near" and 12 or 14)
    setTextureColor(frame.healthBarBG, 0.08, 0.08, 0.09, 0.92)

    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
    frame.healthBar:SetPoint("TOPLEFT", frame.healthBarBG, "TOPLEFT", 1, -1)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame.healthBarBG, "BOTTOMRIGHT", -1, 1)
    frame.healthBar:SetMinMaxValues(0, 1)
    frame.healthBar:SetValue(1)

    frame.healthValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.healthValue:SetPoint("RIGHT", frame.healthBarBG, "RIGHT", -3, 0)
    frame.healthValue:SetJustifyH("RIGHT")
    frame.healthValue:SetTextColor(0.96, 0.96, 0.98)

    frame.cooldownRow = CreateFrame("Frame", nil, frame)
    frame.cooldownRow:SetPoint("TOPLEFT", frame.healthBarBG, "BOTTOMLEFT", 0, -4)
    frame.cooldownRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -40)
    frame.cooldownRow:SetHeight(24)
    frame.cooldownIcons = {}

    frame.trinketIcon = createIcon(frame)
    frame.trinketIcon:SetSize(22, 22)
    frame.trinketIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -19)

    frame.drContainer = CreateFrame("Frame", nil, frame)
    frame.drContainer:SetPoint("TOPRIGHT", frame.trinketIcon, "TOPLEFT", -4, -1)
    frame.drContainer:SetPoint("LEFT", frame.nameText, "RIGHT", 4, 0)
    frame.drContainer:SetHeight(14)
    frame.drBadges = {}

    frame.castAnchor = CreateFrame("Frame", nil, frame)
    frame.castAnchor:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -3)
    frame.castAnchor:SetSize(width, 18)

    frame:Hide()
    return frame
end

function UnitFrames:GetUnitFrame(unit)
    return self.frameByUnit.enemy[unit] or self.frameByUnit.friendly[unit] or self.frameByUnit.near[unit]
end

function UnitFrames:RefreshLayout()
    local enemyStartX, enemyStartY = -300, 160
    local friendlyStartX, friendlyStartY = 40, 160
    local nearStartX, nearStartY = 40, -120

    local enemyStep = self.GROUP_SPACING.enemy
    local friendlyStep = self.GROUP_SPACING.friendly
    local nearStep = self.GROUP_SPACING.near

    for index, frame in ipairs(self.frames.enemy) do
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", enemyStartX, enemyStartY - ((index - 1) * enemyStep))
    end

    for index, frame in ipairs(self.frames.friendly) do
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", friendlyStartX, friendlyStartY - ((index - 1) * friendlyStep))
    end

    for index, frame in ipairs(self.frames.near) do
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", nearStartX, nearStartY - ((index - 1) * nearStep))
    end
end

function UnitFrames:IsNearUnitInRange(unit)
    if not UnitExists or not UnitExists(unit) then
        return false
    end

    local nearSettings = GT:GetSetting({ "unitFrames", "near" }) or {}
    local itemID = nearSettings.rangeItem

    -- TODO: Add robust range backend options (e.g., LibRangeCheck) for more accurate near frame filtering.
    if IsItemInRange and itemID then
        local inRange = IsItemInRange(itemID, unit)
        if inRange ~= nil then
            return inRange == 1
        end
    end

    if CheckInteractDistance then
        return CheckInteractDistance(unit, 4) and true or false
    end

    return true
end

function UnitFrames:ShouldShowFrame(frame)
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    if frame.groupName == "enemy" then
        if not settings.unitFrames.enemy.enabled then
            return false
        end
        return UnitExists and UnitExists(frame.unit)
    end

    if frame.groupName == "friendly" then
        if not settings.unitFrames.friendly.enabled then
            return false
        end

        if frame.unit == "player" then
            return settings.unitFrames.friendly.includePlayer and true or false
        end

        return UnitExists and UnitExists(frame.unit)
    end

    if frame.groupName == "near" then
        if not settings.unitFrames.near.enabled then
            return false
        end

        return self:IsNearUnitInRange(frame.unit)
    end

    return false
end

function UnitFrames:GetFrameStyle(frame)
    local styleSettings = GT:GetSetting({ "unitFrames", frame.groupName }) or {}
    return styleSettings.fancy and true or false
end

function UnitFrames:ApplyFrameChrome(frame, classFile, fancy)
    local r, g, b = GT:GetClassColor(classFile)
    if not fancy then
        r, g, b = 0.56, 0.56, 0.60
    end

    setTextureColor(frame.topAccent, r, g, b, fancy and 0.95 or 0.70)

    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(
            math.min(1, (r * 0.38) + 0.10),
            math.min(1, (g * 0.38) + 0.10),
            math.min(1, (b * 0.38) + 0.10),
            0.95
        )
    end
end

function UnitFrames:EnsureIconCount(frame, count, iconSize)
    for index = 1, count do
        local icon = frame.cooldownIcons[index]
        if not icon then
            icon = createIcon(frame.cooldownRow)
            frame.cooldownIcons[index] = icon
        end

        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", frame.cooldownRow, "LEFT", (index - 1) * (iconSize + 3), 0)
    end
end

function UnitFrames:HideCooldownIcons(frame)
    frame.cooldownRow:Hide()
    for _, icon in ipairs(frame.cooldownIcons) do
        icon:Hide()
    end
end

function UnitFrames:UpdateCooldownRow(frame, guid)
    local cooldownSettings = GT:GetSetting({ "unitFrames", "cooldowns" })
    if not cooldownSettings or not cooldownSettings.enabled then
        self:HideCooldownIcons(frame)
        return
    end

    local showSide = frame.groupName == "enemy" and cooldownSettings.showEnemy or cooldownSettings.showFriendly
    if not showSide then
        self:HideCooldownIcons(frame)
        return
    end

    frame.cooldownRow:Show()

    local iconSize = math.max(16, math.min(40, cooldownSettings.iconSize or 24))
    local maxIcons = math.max(1, math.min(10, cooldownSettings.maxIcons or 6))

    self:EnsureIconCount(frame, maxIcons, iconSize)

    local entries = guid and GT.CooldownTracker:GetUnitCooldowns(guid) or {}
    local now = GetTime and GetTime() or 0

    for index = 1, maxIcons do
        local icon = frame.cooldownIcons[index]
        local entry = entries[index]

        if entry then
            local remaining = entry.endTime - now
            icon.texture:SetTexture(entry.icon or 134400)
            icon.timerText:SetText(GT:FormatRemaining(remaining))

            if remaining <= 5 then
                icon.timerText:SetTextColor(1, 0.32, 0.32)
            elseif remaining <= 15 then
                icon.timerText:SetTextColor(1, 0.86, 0.35)
            else
                icon.timerText:SetTextColor(0.95, 0.95, 0.98)
            end

            local color = self.CATEGORY_COLORS[entry.category] or DEFAULT_CATEGORY_COLOR
            applyIconColor(icon, color[1], color[2], color[3])

            if CooldownFrame_Set then
                CooldownFrame_Set(icon.cooldown, entry.startTime, entry.duration, true)
            elseif icon.cooldown.SetCooldown then
                icon.cooldown:SetCooldown(entry.startTime, entry.duration)
            end

            icon:Show()
        else
            icon:Hide()
        end
    end

    for index = maxIcons + 1, #frame.cooldownIcons do
        frame.cooldownIcons[index]:Hide()
    end
end

function UnitFrames:UpdateTrinket(frame, guid)
    if frame.groupName ~= "enemy" and frame.groupName ~= "friendly" then
        frame.trinketIcon:Hide()
        return
    end

    local trinketEnabled = GT:GetSetting({ "trinkets", "enabled" })
    if not trinketEnabled then
        frame.trinketIcon:Hide()
        return
    end

    local trinketEntry = guid and GT.TrinketTracker:GetPrimaryTrinket(guid) or nil
    if not trinketEntry then
        frame.trinketIcon:Hide()
        return
    end

    local now = GetTime and GetTime() or 0
    local remaining = trinketEntry.endTime - now
    if remaining <= 0 then
        frame.trinketIcon:Hide()
        return
    end

    frame.trinketIcon.texture:SetTexture(trinketEntry.icon or 132344)
    frame.trinketIcon.timerText:SetText(GT:FormatRemaining(remaining))
    if remaining <= 10 then
        frame.trinketIcon.timerText:SetTextColor(1, 0.80, 0.25)
    else
        frame.trinketIcon.timerText:SetTextColor(0.95, 0.95, 0.98)
    end

    local trinketColor = self.CATEGORY_COLORS.trinket
    applyIconColor(frame.trinketIcon, trinketColor[1], trinketColor[2], trinketColor[3])

    if CooldownFrame_Set then
        CooldownFrame_Set(frame.trinketIcon.cooldown, trinketEntry.startTime, trinketEntry.duration, true)
    elseif frame.trinketIcon.cooldown.SetCooldown then
        frame.trinketIcon.cooldown:SetCooldown(trinketEntry.startTime, trinketEntry.duration)
    end

    frame.trinketIcon:Show()
end

function UnitFrames:UpdateHealthAndName(frame)
    local name = UnitName and UnitName(frame.unit) or frame.unit
    local _, classFile = UnitClass and UnitClass(frame.unit)
    local r, g, b = GT:GetClassColor(classFile)

    frame.nameText:SetText(name or frame.unit)
    frame.nameText:SetTextColor(r, g, b)

    local health = UnitHealth and UnitHealth(frame.unit) or 0
    local maxHealth = UnitHealthMax and UnitHealthMax(frame.unit) or 1
    if maxHealth < 1 then
        maxHealth = 1
    end

    frame.healthBar:SetMinMaxValues(0, maxHealth)
    frame.healthBar:SetValue(math.max(0, health))
    frame.healthBar:SetStatusBarColor((r * 0.78) + 0.18, (g * 0.78) + 0.18, (b * 0.78) + 0.18, 1)

    local percent = math.floor(((health / maxHealth) * 100) + 0.5)
    if percent < 0 then
        percent = 0
    elseif percent > 100 then
        percent = 100
    end
    frame.healthValue:SetText(string.format("%d%%", percent))
    if percent <= 35 then
        frame.healthValue:SetTextColor(1, 0.35, 0.35)
    elseif percent <= 60 then
        frame.healthValue:SetTextColor(1, 0.86, 0.35)
    else
        frame.healthValue:SetTextColor(0.95, 0.95, 0.98)
    end

    return classFile
end

function UnitFrames:EnsureDRBadgeCount(frame, count)
    for index = 1, count do
        local badge = frame.drBadges[index]
        if not badge then
            badge = createDRBadge(frame.drContainer)
            frame.drBadges[index] = badge
        end

        badge:ClearAllPoints()
        badge:SetPoint("RIGHT", frame.drContainer, "RIGHT", -((index - 1) * 50), 0)
    end
end

function UnitFrames:HideDRBadges(frame)
    if not frame.drBadges then
        return
    end

    for _, badge in ipairs(frame.drBadges) do
        badge:Hide()
    end
end

function UnitFrames:UpdateDR(frame, guid)
    if frame.groupName ~= "enemy" then
        self:HideDRBadges(frame)
        return
    end

    local drSettings = GT:GetSetting({ "dr" })
    if not (drSettings and drSettings.enabled and drSettings.showOnEnemyFrames) then
        self:HideDRBadges(frame)
        return
    end

    local entries = guid and GT.DRTracker and GT.DRTracker:GetUnitDRStates(guid) or {}
    if #entries == 0 then
        self:HideDRBadges(frame)
        return
    end

    local maxShown = math.min(3, #entries)
    self:EnsureDRBadgeCount(frame, maxShown)

    for index = 1, maxShown do
        local badge = frame.drBadges[index]
        local entry = entries[index]

        local color = self.DR_COLORS[entry.category] or DEFAULT_CATEGORY_COLOR
        local nextText = formatDRNext(entry.nextMultiplier or 1)
        local remainText = GT:FormatRemaining(entry.resetRemaining or 0)
        local label = entry.label or "DR"

        local text = label .. " " .. nextText
        if remainText ~= "" then
            text = text .. " " .. remainText
        end

        badge.text:SetText(text)
        badge.text:SetTextColor(color[1], color[2], color[3], entry.isActive and 1 or 0.90)
        setTextureColor(badge.fill, color[1], color[2], color[3], entry.isActive and 0.24 or 0.10)

        if badge.SetBackdropBorderColor then
            badge:SetBackdropBorderColor(color[1], color[2], color[3], entry.isActive and 0.95 or 0.55)
        end

        badge:Show()
    end

    for index = maxShown + 1, #frame.drBadges do
        frame.drBadges[index]:Hide()
    end
end

function UnitFrames:UpdateFrame(frame)
    if not self:ShouldShowFrame(frame) then
        self:HideDRBadges(frame)
        frame:Hide()
        return
    end

    frame:Show()

    local fancy = self:GetFrameStyle(frame)
    setBackdrop(frame, fancy)

    GT.UnitMap:RefreshUnit(frame.unit)
    local guid = GT.UnitMap:GetGUIDForUnit(frame.unit)
    frame.guid = guid

    local classFile = self:UpdateHealthAndName(frame)
    self:ApplyFrameChrome(frame, classFile, fancy)

    self:UpdateCooldownRow(frame, guid)
    self:UpdateTrinket(frame, guid)
    self:UpdateDR(frame, guid)
end

function UnitFrames:UpdateAll()
    for _, groupFrames in pairs(self.frames) do
        for _, frame in ipairs(groupFrames) do
            self:UpdateFrame(frame)
        end
    end
end

function UnitFrames:OnUpdate(elapsed)
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:UpdateAll()
end

function UnitFrames:OnSettingsChanged()
    self:RefreshLayout()
    self:UpdateAll()
end

function UnitFrames:HandleEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UpdateAll()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "ARENA_OPPONENT_UPDATE" then
        self:UpdateAll()
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        self:UpdateAll()
    end
end
