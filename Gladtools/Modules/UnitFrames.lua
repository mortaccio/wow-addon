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
            edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.05, 0.05, 0.08, 0.88)
    else
        frame:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.08, 0.08, 0.08, 0.7)
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
        icon:SetBackdropColor(0, 0, 0, 0.7)
    end

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(icon)

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)

    icon.timerText = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    icon.timerText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 1)

    icon:Hide()
    return icon
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
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(218, 58)
    frame.unit = unit
    frame.groupName = groupName
    frame.index = index

    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.nameText:SetPoint("TOPLEFT", 8, -6)
    frame.nameText:SetWidth(185)
    frame.nameText:SetJustifyH("LEFT")

    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.healthBar:SetPoint("TOPLEFT", 8, -20)
    frame.healthBar:SetPoint("TOPRIGHT", -34, -20)
    frame.healthBar:SetHeight(16)
    frame.healthBar:SetMinMaxValues(0, 1)
    frame.healthBar:SetValue(1)

    frame.healthValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.healthValue:SetPoint("RIGHT", frame.healthBar, "RIGHT", -2, 0)
    frame.healthValue:SetJustifyH("RIGHT")

    frame.cooldownRow = CreateFrame("Frame", nil, frame)
    frame.cooldownRow:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, -4)
    frame.cooldownRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -40)
    frame.cooldownRow:SetHeight(24)

    frame.cooldownIcons = {}

    frame.trinketIcon = createIcon(frame)
    frame.trinketIcon:SetPoint("TOPRIGHT", -8, -18)

    frame.castAnchor = CreateFrame("Frame", nil, frame)
    frame.castAnchor:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
    frame.castAnchor:SetSize(200, 16)

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

    for index, frame in ipairs(self.frames.enemy) do
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", enemyStartX, enemyStartY - ((index - 1) * 70))
    end

    for index, frame in ipairs(self.frames.friendly) do
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", friendlyStartX, friendlyStartY - ((index - 1) * 70))
    end

    for index, frame in ipairs(self.frames.near) do
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", nearStartX, nearStartY - ((index - 1) * 60))
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

function UnitFrames:EnsureIconCount(frame, count, iconSize)
    for index = 1, count do
        local icon = frame.cooldownIcons[index]
        if not icon then
            icon = createIcon(frame.cooldownRow)
            frame.cooldownIcons[index] = icon
        end

        icon:SetSize(iconSize, iconSize)
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", frame.cooldownRow, "LEFT", (index - 1) * (iconSize + 2), 0)
    end
end

function UnitFrames:UpdateCooldownRow(frame, guid)
    local cooldownSettings = GT:GetSetting({ "unitFrames", "cooldowns" })
    if not cooldownSettings or not cooldownSettings.enabled then
        for _, icon in ipairs(frame.cooldownIcons) do
            icon:Hide()
        end
        return
    end

    local showSide = frame.groupName == "enemy" and cooldownSettings.showEnemy or cooldownSettings.showFriendly
    if not showSide then
        for _, icon in ipairs(frame.cooldownIcons) do
            icon:Hide()
        end
        return
    end

    local iconSize = math.max(16, math.min(40, cooldownSettings.iconSize or 24))
    local maxIcons = math.max(1, math.min(10, cooldownSettings.maxIcons or 6))

    self:EnsureIconCount(frame, maxIcons, iconSize)

    local entries = guid and GT.CooldownTracker:GetUnitCooldowns(guid) or {}
    local now = GetTime and GetTime() or 0

    for index = 1, maxIcons do
        local icon = frame.cooldownIcons[index]
        local entry = entries[index]

        if entry then
            icon.texture:SetTexture(entry.icon or 134400)
            icon.timerText:SetText(GT:FormatRemaining(entry.endTime - now))
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
    frame.healthBar:SetValue(health)
    frame.healthBar:SetStatusBarColor(r * 0.8, g * 0.8, b * 0.8, 1)
    frame.healthValue:SetText(string.format("%d%%", (health / maxHealth) * 100))
end

function UnitFrames:UpdateFrame(frame)
    if not self:ShouldShowFrame(frame) then
        frame:Hide()
        return
    end

    frame:Show()
    setBackdrop(frame, self:GetFrameStyle(frame))

    GT.UnitMap:RefreshUnit(frame.unit)
    local guid = GT.UnitMap:GetGUIDForUnit(frame.unit)
    frame.guid = guid

    self:UpdateHealthAndName(frame)
    self:UpdateCooldownRow(frame, guid)
    self:UpdateTrinket(frame, guid)
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
