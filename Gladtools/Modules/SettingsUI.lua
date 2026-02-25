local _, GT = ...

local SettingsUI = {}
GT.SettingsUI = SettingsUI
GT:RegisterModule("SettingsUI", SettingsUI)

local function createSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText(text)

    local line = parent:CreateTexture(nil, "BORDER")
    line:SetTexture("Interface/Buttons/WHITE8x8")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    line:SetPoint("TOPRIGHT", header, "BOTTOMLEFT", 220, -3)
    line:SetHeight(1)
    line:SetVertexColor(0.26, 0.34, 0.48, 0.92)

    header.line = line
    return header
end

local function createButton(parent, text, x, y, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function createSlider(parent, label, x, y, minValue, maxValue, step, onValueChanged)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetSize(240, 20)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    text:SetText(label)
    slider.label = text

    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    slider.valueText = valueText

    slider:SetScript("OnValueChanged", function(_, value)
        local rounded = math.floor((value / step) + 0.5) * step
        valueText:SetText(tostring(rounded))
        if slider.suspendCallback then
            return
        end
        if onValueChanged then
            onValueChanged(rounded)
        end
    end)

    return slider
end

local function createCard(parent, x, y, width, height, titleText, subtitleText)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", x, y)
    card:SetSize(width, height)

    if card.SetBackdrop then
        card:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        card:SetBackdropColor(0.07, 0.08, 0.11, 0.86)
        if card.SetBackdropBorderColor then
            card:SetBackdropBorderColor(0.24, 0.28, 0.36, 0.98)
        end
    end

    card.topAccent = card:CreateTexture(nil, "BORDER")
    card.topAccent:SetTexture("Interface/Buttons/WHITE8x8")
    card.topAccent:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card.topAccent:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
    card.topAccent:SetHeight(2)
    card.topAccent:SetVertexColor(0.20, 0.74, 0.98, 0.90)

    if titleText then
        card.title = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
        card.title:SetText(titleText)
    end

    if subtitleText then
        card.subtitle = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.subtitle:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -24)
        card.subtitle:SetTextColor(0.72, 0.76, 0.84)
        card.subtitle:SetText(subtitleText)
    end

    return card
end

local function enabledTag(value)
    if value then
        return "|cff5ff08eON|r"
    end
    return "|cffd08282OFF|r"
end

function SettingsUI:Init()
    self.controls = {}
    self.snapshotElapsed = 0
    self:CreatePanel()
end

function SettingsUI:CreatePanel()
    if self.panel then
        return
    end

    local panel = CreateFrame("Frame", "GladtoolsSettingsPanel", UIParent)
    panel.name = "Gladtools"

    panel:SetScript("OnShow", function()
        SettingsUI.snapshotElapsed = 0
        SettingsUI:RefreshControls()
        SettingsUI:RefreshRuntimeSnapshot()
    end)

    panel:SetScript("OnUpdate", function(_, elapsed)
        if not panel.IsShown or not panel:IsShown() then
            return
        end

        SettingsUI.snapshotElapsed = (SettingsUI.snapshotElapsed or 0) + (elapsed or 0)
        if SettingsUI.snapshotElapsed >= 0.5 then
            SettingsUI.snapshotElapsed = 0
            SettingsUI:RefreshRuntimeSnapshot()
        end
    end)

    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        panel:SetBackdropColor(0.04, 0.05, 0.07, 0.92)
        if panel.SetBackdropBorderColor then
            panel:SetBackdropBorderColor(0.20, 0.24, 0.32, 0.98)
        end
    end

    panel.headerGlow = panel:CreateTexture(nil, "BORDER")
    panel.headerGlow:SetTexture("Interface/Buttons/WHITE8x8")
    panel.headerGlow:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    panel.headerGlow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    panel.headerGlow:SetHeight(42)
    panel.headerGlow:SetVertexColor(0.18, 0.74, 1.0, 0.10)

    panel.leftAura = panel:CreateTexture(nil, "BACKGROUND")
    panel.leftAura:SetTexture("Interface/Buttons/WHITE8x8")
    panel.leftAura:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -44)
    panel.leftAura:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 1, 1)
    panel.leftAura:SetWidth(190)
    panel.leftAura:SetVertexColor(0.22, 0.60, 0.96, 0.05)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Gladtools Arena Settings")

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Real-time arena cooldown, trinket, cast bar, and pointer tracking.")

    self.cards = self.cards or {}
    self.cards.presets = createCard(panel, 16, -68, 426, 86)
    self.cards.core = createCard(panel, 16, -162, 426, 372)
    self.cards.display = createCard(panel, 456, -68, 298, 250)
    self.cards.snapshot = createCard(panel, 456, -328, 298, 154, "Live Arena Snapshot", "Current runtime activity")

    createSectionHeader(panel, "Presets", 20, -76)

    self.controls.presetState = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.controls.presetState:SetPoint("TOPLEFT", 20, -98)
    self.controls.presetState:SetText("Preset State: Unknown")

    createButton(panel, "Apply Healer", 20, -122, 120, function()
        GT:ApplyPreset("healer")
        SettingsUI:RefreshControls()
    end)

    createButton(panel, "Apply DPS", 150, -122, 120, function()
        GT:ApplyPreset("dps")
        SettingsUI:RefreshControls()
    end)

    createButton(panel, "Reset To Selected", 280, -122, 150, function()
        GT:ResetToSelectedPreset()
        SettingsUI:RefreshControls()
    end)

    createSectionHeader(panel, "Core Toggles", 20, -170)

    self.controls.enableAddon = GT:CreateBasicCheckbox(panel, "Enable addon", 20, -190, function(value)
        GT:SetSetting({ "enabled" }, value, "settings_ui")
    end)

    self.controls.showFriendly = GT:CreateBasicCheckbox(panel, "Show friendly frames", 20, -218, function(value)
        GT:SetSetting({ "unitFrames", "friendly", "enabled" }, value, "settings_ui")
    end)

    self.controls.showEnemy = GT:CreateBasicCheckbox(panel, "Show enemy frames", 20, -246, function(value)
        GT:SetSetting({ "unitFrames", "enemy", "enabled" }, value, "settings_ui")
    end)

    self.controls.showNear = GT:CreateBasicCheckbox(panel, "Show near frames", 20, -274, function(value)
        GT:SetSetting({ "unitFrames", "near", "enabled" }, value, "settings_ui")
    end)

    self.controls.showCastBars = GT:CreateBasicCheckbox(panel, "Show cast bars", 20, -302, function(value)
        GT:SetSetting({ "castBars", "enabled" }, value, "settings_ui")
    end)

    self.controls.showDR = GT:CreateBasicCheckbox(panel, "Show DR tracking on enemy frames", 20, -330, function(value)
        local settings = GT.db and GT.db.settings
        if not (settings and settings.dr) then
            return
        end

        settings.dr.enabled = value and true or false
        settings.dr.showOnEnemyFrames = value and true or false
        GT:EvaluatePresetState()
        GT:OnSettingsChanged("settings_ui")
    end)

    self.controls.showCooldownIcons = GT:CreateBasicCheckbox(panel, "Show cooldown icons", 20, -358, function(value)
        GT:SetSetting({ "unitFrames", "cooldowns", "enabled" }, value, "settings_ui")
    end)

    self.controls.trackTrinkets = GT:CreateBasicCheckbox(panel, "Track trinkets", 20, -386, function(value)
        GT:SetSetting({ "trinkets", "enabled" }, value, "settings_ui")
    end)

    self.controls.topNotifications = GT:CreateBasicCheckbox(panel, "Top alerts: healer CC + enemy burst", 20, -414, function(value)
        GT:SetSetting({ "notifications", "enabled" }, value, "settings_ui")
    end)

    self.controls.showFriendlyCastBars = GT:CreateBasicCheckbox(panel, "Friendly cast bars under friendly frames", 20, -442, function(value)
        GT:SetSetting({ "castBars", "friendly" }, value, "settings_ui")
    end)

    self.controls.enableNameplates = GT:CreateBasicCheckbox(panel, "Enable enhanced player nameplates", 20, -470, function(value)
        GT:SetSetting({ "nameplates", "enabled" }, value, "settings_ui")
    end)

    self.controls.showFriendlyPlates = GT:CreateBasicCheckbox(panel, "Show overlays on friendly nameplates", 20, -498, function(value)
        GT:SetSetting({ "nameplates", "showFriendly" }, value, "settings_ui")
    end)

    createSectionHeader(panel, "Display", 460, -76)

    self.controls.pointerModeButton = createButton(panel, "Pointer Mode", 460, -104, 220, function()
        local current = GT:GetSetting({ "pointers", "mode" }) or GT.POINTER_MODES.ALL_FRIENDLIES
        local nextIndex = 1
        for index, mode in ipairs(GT.POINTER_MODE_ORDER) do
            if mode == current then
                nextIndex = index + 1
                break
            end
        end
        if nextIndex > #GT.POINTER_MODE_ORDER then
            nextIndex = 1
        end

        local nextMode = GT.POINTER_MODE_ORDER[nextIndex]
        GT:SetSetting({ "pointers", "mode" }, nextMode, "settings_ui")
        SettingsUI:RefreshControls()
    end)

    self.controls.pointerSize = createSlider(panel, "Pointer Size", 460, -160, 16, 42, 1, function(value)
        GT:SetSetting({ "pointers", "size" }, value, "settings_ui")
    end)

    self.controls.iconSize = createSlider(panel, "Cooldown Icon Size", 460, -228, 16, 40, 1, function(value)
        GT:SetSetting({ "unitFrames", "cooldowns", "iconSize" }, value, "settings_ui")
    end)

    self.controls.maxIcons = createSlider(panel, "Max Cooldown Icons", 460, -296, 1, 10, 1, function(value)
        GT:SetSetting({ "unitFrames", "cooldowns", "maxIcons" }, value, "settings_ui")
    end)

    self.controls.runtimeSnapshot = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.controls.runtimeSnapshot:SetPoint("TOPLEFT", 468, -360)
    self.controls.runtimeSnapshot:SetWidth(282)
    self.controls.runtimeSnapshot:SetJustifyH("LEFT")
    if self.controls.runtimeSnapshot.SetJustifyV then
        self.controls.runtimeSnapshot:SetJustifyV("TOP")
    end
    self.controls.runtimeSnapshot:SetText("Waiting for combat data...")

    panel:Hide()
    self.panel = panel

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Gladtools")
        if ok and category then
            self.category = category
            pcall(Settings.RegisterAddOnCategory, category)
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function SettingsUI:BuildRuntimeSnapshotText()
    local counts = (GT.UnitFrames and GT.UnitFrames.GetVisibleGroupCounts and GT.UnitFrames:GetVisibleGroupCounts()) or {}
    local visibleEnemy = counts.enemy or 0
    local visibleFriendly = counts.friendly or 0
    local visibleNear = counts.near or 0

    local cdTotal, cdFriendly, cdEnemy = 0, 0, 0
    if GT.CooldownTracker and GT.CooldownTracker.GetActiveCounts then
        cdTotal, cdFriendly, cdEnemy = GT.CooldownTracker:GetActiveCounts()
    end

    local trinketTotal, trinketFriendly, trinketEnemy = 0, 0, 0
    if GT.TrinketTracker and GT.TrinketTracker.GetActiveCounts then
        trinketTotal, trinketFriendly, trinketEnemy = GT.TrinketTracker:GetActiveCounts()
    end

    local drTracked, drActive = 0, 0
    if GT.DRTracker and GT.DRTracker.GetActiveCounts then
        drTracked, drActive = GT.DRTracker:GetActiveCounts()
    end

    local activeCasts = GT.CastBars and GT.CastBars.GetActiveCount and GT.CastBars:GetActiveCount() or 0
    local pointers = GT.PointerSystem and GT.PointerSystem.GetVisibleCount and GT.PointerSystem:GetVisibleCount() or 0

    local lines = {
        "Preset: " .. GT:GetPresetStateLabel() .. "    Addon: " .. enabledTag(GT:GetSetting({ "enabled" })),
        string.format("Frames  E:%d  F:%d  N:%d", visibleEnemy, visibleFriendly, visibleNear),
        string.format("Cooldowns  %d total  (%d enemy / %d friendly)", cdTotal, cdEnemy, cdFriendly),
        string.format("Trinkets   %d total  (%d enemy / %d friendly)", trinketTotal, trinketEnemy, trinketFriendly),
        string.format("DR States  %d tracked  (%d active)", drTracked, drActive),
        string.format("Cast Bars  %d active    Pointers %d", activeCasts, pointers),
    }

    return table.concat(lines, "\n")
end

function SettingsUI:RefreshRuntimeSnapshot()
    if not self.controls or not self.controls.runtimeSnapshot then
        return
    end

    if not GT.db then
        self.controls.runtimeSnapshot:SetText("Waiting for addon data...")
        return
    end

    self.controls.runtimeSnapshot:SetText(self:BuildRuntimeSnapshotText())
end

function SettingsUI:RefreshControls()
    if not self.panel or not GT.db then
        return
    end

    local settings = GT.db.settings

    if self.controls.presetState then
        self.controls.presetState:SetText("Preset State: " .. GT:GetPresetStateLabel())
    end

    self.controls.enableAddon:SetChecked(settings.enabled and true or false)
    self.controls.showFriendly:SetChecked(settings.unitFrames.friendly.enabled and true or false)
    self.controls.showEnemy:SetChecked(settings.unitFrames.enemy.enabled and true or false)
    self.controls.showNear:SetChecked(settings.unitFrames.near.enabled and true or false)
    self.controls.showCastBars:SetChecked(settings.castBars.enabled and true or false)
    self.controls.showDR:SetChecked(settings.dr.enabled and settings.dr.showOnEnemyFrames and true or false)
    self.controls.showCooldownIcons:SetChecked(settings.unitFrames.cooldowns.enabled and true or false)
    self.controls.trackTrinkets:SetChecked(settings.trinkets.enabled and true or false)
    self.controls.showFriendlyCastBars:SetChecked(settings.castBars.friendly and true or false)

    local notifications = settings.notifications or {}
    self.controls.topNotifications:SetChecked(notifications.enabled ~= false)

    local plateSettings = settings.nameplates or {}
    self.controls.enableNameplates:SetChecked(plateSettings.enabled ~= false)
    self.controls.showFriendlyPlates:SetChecked(plateSettings.showFriendly and true or false)

    local pointerMode = settings.pointers.mode or GT.POINTER_MODES.OFF
    local pointerLabel = GT.POINTER_MODE_LABELS[pointerMode] or pointerMode
    self.controls.pointerModeButton:SetText("Pointer Mode: " .. pointerLabel)

    local pointerSize = settings.pointers.size or 22
    self.controls.pointerSize.suspendCallback = true
    self.controls.pointerSize:SetValue(pointerSize)
    self.controls.pointerSize.suspendCallback = false
    self.controls.pointerSize.valueText:SetText(tostring(pointerSize))

    local iconSize = settings.unitFrames.cooldowns.iconSize or 24
    self.controls.iconSize.suspendCallback = true
    self.controls.iconSize:SetValue(iconSize)
    self.controls.iconSize.suspendCallback = false
    self.controls.iconSize.valueText:SetText(tostring(iconSize))

    local maxIcons = settings.unitFrames.cooldowns.maxIcons or 6
    self.controls.maxIcons.suspendCallback = true
    self.controls.maxIcons:SetValue(maxIcons)
    self.controls.maxIcons.suspendCallback = false
    self.controls.maxIcons.valueText:SetText(tostring(maxIcons))

    self:RefreshRuntimeSnapshot()
end

function SettingsUI:Open()
    if Settings and Settings.OpenToCategory and self.category then
        local categoryID = self.category.GetID and self.category:GetID() or self.category
        pcall(Settings.OpenToCategory, categoryID)
        return
    end

    if InterfaceOptionsFrame_OpenToCategory and self.panel then
        InterfaceOptionsFrame_OpenToCategory(self.panel)
        InterfaceOptionsFrame_OpenToCategory(self.panel)
    end
end

function SettingsUI:OnSettingsChanged()
    if self.panel and self.panel:IsShown() then
        self:RefreshControls()
    end
end
