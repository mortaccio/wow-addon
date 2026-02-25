local _, GT = ...

local SettingsUI = {}
GT.SettingsUI = SettingsUI
GT:RegisterModule("SettingsUI", SettingsUI)

local function createSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", x, y)
    header:SetText(text)
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

function SettingsUI:Init()
    self.controls = {}
    self:CreatePanel()
end

function SettingsUI:CreatePanel()
    if self.panel then
        return
    end

    local panel = CreateFrame("Frame", "GladtoolsSettingsPanel", UIParent)
    panel.name = "Gladtools"

    panel:SetScript("OnShow", function()
        SettingsUI:RefreshControls()
    end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Gladtools Arena Settings")

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Real-time arena cooldown, trinket, cast bar, and pointer tracking.")

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

    createSectionHeader(panel, "Core Toggles", 20, -168)

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

    self.controls.iconSize = createSlider(panel, "Cooldown Icon Size", 460, -160, 16, 40, 1, function(value)
        GT:SetSetting({ "unitFrames", "cooldowns", "iconSize" }, value, "settings_ui")
    end)

    self.controls.maxIcons = createSlider(panel, "Max Cooldown Icons", 460, -228, 1, 10, 1, function(value)
        GT:SetSetting({ "unitFrames", "cooldowns", "maxIcons" }, value, "settings_ui")
    end)

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

    local pointerMode = settings.pointers.mode or GT.POINTER_MODES.OFF
    local pointerLabel = GT.POINTER_MODE_LABELS[pointerMode] or pointerMode
    self.controls.pointerModeButton:SetText("Pointer Mode: " .. pointerLabel)

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
