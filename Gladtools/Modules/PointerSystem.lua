local _, GT = ...

local PointerSystem = {}
GT.PointerSystem = PointerSystem
GT:RegisterModule("PointerSystem", PointerSystem)

PointerSystem.UPDATE_INTERVAL = 0.20
PointerSystem.PULSE_SPEED = 6.0
PointerSystem.PULSE_BASE = 0.56
PointerSystem.PULSE_RANGE = 0.18

PointerSystem.COLORS = {
    healer = { 0.28, 0.95, 0.56 },
    friendly = { 0.26, 0.72, 0.96 },
    explicit = { 0.96, 0.84, 0.22 },
}

local function setTextureColor(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a or 1)
    end
end

local function getPulseOffset(unit)
    if type(unit) ~= "string" then
        return 0
    end

    local total = 0
    for index = 1, #unit do
        total = total + string.byte(unit, index)
    end

    return (total % 10) / 10
end

local function createPointerFrame(unit)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(22, 22)

    GT:ApplyWoWBackdrop(frame, "icon")

    frame.fill = frame:CreateTexture(nil, "BACKGROUND")
    frame.fill:SetAllPoints(frame)
    frame.fill:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    setTextureColor(frame.fill, 0.20, 0.34, 0.52, 0.18)

    frame.ring = frame:CreateTexture(nil, "BORDER")
    frame.ring:SetAllPoints(frame)
    frame.ring:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    setTextureColor(frame.ring, 1, 0.82, 0.40, 0.10)

    frame.texture = frame:CreateTexture(nil, "OVERLAY")
    frame.texture:SetAllPoints(frame)
    frame.texture:SetTexture("Interface/Minimap/Minimap-QuestArrow")
    if frame.texture.SetRotation then
        frame.texture:SetRotation(math.rad(-90))
    end
    if frame.texture.SetTexCoord then
        frame.texture:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    end

    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.label:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.label:SetText("")
    if frame.label.SetShadowOffset then
        frame.label:SetShadowOffset(1, -1)
    end
    if frame.label.SetShadowColor then
        frame.label:SetShadowColor(0, 0, 0, 1)
    end

    frame.unit = unit
    frame.isExplicit = false
    frame.pulseOffset = getPulseOffset(unit)
    frame:Hide()

    return frame
end

function PointerSystem:Init()
    if not UIParent or not CreateFrame then
        GT:Print("UIParent not available, deferring PointerSystem init")
        return
    end

    self.pointerFrames = {}
    self.explicitTargets = {}

    self.driver = CreateFrame("Frame", "GladtoolsPointerDriver", UIParent)
    if self.driver and self.driver.SetScript then
        self.driver:SetScript("OnUpdate", function(_, elapsed)
            PointerSystem:OnUpdate(elapsed)
        end)
    end

    self.elapsed = 0
    self:SetDriverActive(self:ShouldRunUpdates())
end

function PointerSystem:SetPointerTarget(unitToken, enabled)
    if not unitToken then
        return
    end

    self.explicitTargets[unitToken] = enabled and true or nil
    self:SetDriverActive(self:ShouldRunUpdates())
    if GT.ApplyRuntimeEvents then
        GT:ApplyRuntimeEvents("pointer_target")
    end
    self:RefreshPointers()
end

function PointerSystem:ShouldRunUpdates()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return false
    end

    local mode = settings.pointers and settings.pointers.mode or GT.POINTER_MODES.OFF
    if mode ~= GT.POINTER_MODES.OFF then
        return true
    end

    return next(self.explicitTargets or {}) ~= nil
end

function PointerSystem:HideAllPointers()
    for _, pointer in pairs(self.pointerFrames or {}) do
        pointer:Hide()
    end
end

function PointerSystem:SetDriverActive(active)
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
        self:HideAllPointers()
        if self.driver.Hide then
            self.driver:Hide()
        end
    end
end

function PointerSystem:GetOrCreatePointer(unit)
    local frame = self.pointerFrames[unit]
    if not frame then
        frame = createPointerFrame(unit)
        self.pointerFrames[unit] = frame
    end
    return frame
end

function PointerSystem:IsHealerUnit(unit)
    if not unit then
        return false
    end

    if UnitExists and not UnitExists(unit) then
        return false
    end

    if GT.UnitMap then
        GT.UnitMap:RefreshUnit(unit)
        local guid = GT.UnitMap:GetGUIDForUnit(unit)
        if guid and GT.UnitMap:IsHealerGUID(guid) then
            return true
        end
    end

    if UnitGroupRolesAssigned then
        return UnitGroupRolesAssigned(unit) == "HEALER"
    end

    return false
end

function PointerSystem:GetPointerColor(unit, isExplicit)
    if isExplicit then
        return self.COLORS.explicit[1], self.COLORS.explicit[2], self.COLORS.explicit[3], true
    end

    if self:IsHealerUnit(unit) then
        return self.COLORS.healer[1], self.COLORS.healer[2], self.COLORS.healer[3], true
    end

    return self.COLORS.friendly[1], self.COLORS.friendly[2], self.COLORS.friendly[3], false
end

function PointerSystem:GetPointerLabel(unit, isExplicit, isPriority)
    if isExplicit then
        return "!"
    end

    if isPriority then
        return "H"
    end

    local partyIndex = type(unit) == "string" and unit:match("^party(%d)$")
    if partyIndex then
        return tostring(partyIndex)
    end

    if unit == "player" then
        return "P"
    end

    return ""
end

function PointerSystem:ApplyPointerStyle(pointerFrame, unit, isExplicit)
    local r, g, b, isPriority = self:GetPointerColor(unit, isExplicit)
    setTextureColor(pointerFrame.texture, r, g, b, 0.95)
    setTextureColor(pointerFrame.fill, r, g, b, isPriority and 0.20 or 0.12)
    setTextureColor(pointerFrame.ring, r, g, b, isPriority and 0.18 or 0.10)

    if pointerFrame.label then
        pointerFrame.label:SetText(self:GetPointerLabel(unit, isExplicit, isPriority))
        pointerFrame.label:SetTextColor(0.98, 0.98, 1.00)
    end

    if pointerFrame.SetBackdropBorderColor then
        pointerFrame:SetBackdropBorderColor((r * 0.30) + 0.34, (g * 0.30) + 0.34, (b * 0.30) + 0.34, 0.98)
    end
end

function PointerSystem:CanUseUnitNameplate(unit)
    if not unit then
        return false
    end

    local isFriendly = UnitIsFriend and UnitIsFriend("player", unit)
    if not isFriendly then
        return true
    end

    local settings = GT:GetSetting({ "nameplates" }) or {}
    if settings.enabled == false then
        return false
    end

    return settings.showFriendly and true or false
end

function PointerSystem:AnchorPointer(pointerFrame, unit, isExplicit)
    local size = GT:GetSetting({ "pointers", "size" }) or 24
    size = math.max(16, math.min(42, size))
    pointerFrame:SetSize(size, size)
    self:ApplyPointerStyle(pointerFrame, unit, isExplicit)

    local unitFrame = GT.UnitFrames and GT.UnitFrames:GetUnitFrame(unit)
    if unitFrame and unitFrame.IsShown and unitFrame:IsShown() then
        pointerFrame:ClearAllPoints()
        pointerFrame:SetPoint("RIGHT", unitFrame, "LEFT", -4, 0)
        pointerFrame:Show()
        return true
    end

    if self:CanUseUnitNameplate(unit) and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        if nameplate then
            pointerFrame:ClearAllPoints()
            pointerFrame:SetPoint("BOTTOM", nameplate, "TOP", 0, 12)
            pointerFrame:Show()
            return true
        end
    end

    pointerFrame:Hide()
    return false
end

function PointerSystem:GetPointerUnits()
    local settings = GT.db and GT.db.settings
    if not settings or not settings.enabled then
        return {}, {}
    end

    local mode = settings.pointers and settings.pointers.mode or GT.POINTER_MODES.OFF
    local modeUnits = GT.UnitMap:GetGroupFriendlyUnits(mode)

    local units = {}
    local seen = {}
    local explicitByUnit = {}

    local function addUnit(unit, isExplicit)
        if not unit then
            return
        end

        if seen[unit] then
            if isExplicit then
                explicitByUnit[unit] = true
            end
            return
        end

        seen[unit] = true
        explicitByUnit[unit] = isExplicit and true or false
        units[#units + 1] = unit
    end

    for _, unit in ipairs(modeUnits) do
        addUnit(unit, false)
    end

    for unit in pairs(self.explicitTargets) do
        addUnit(unit, true)
    end

    return units, explicitByUnit
end

function PointerSystem:RefreshPointers()
    local units, explicitByUnit = self:GetPointerUnits()
    local active = {}

    for _, unit in ipairs(units) do
        active[unit] = true
        local pointer = self:GetOrCreatePointer(unit)
        pointer.isExplicit = explicitByUnit[unit] and true or false
        self:AnchorPointer(pointer, unit, pointer.isExplicit)
    end

    for unit, pointer in pairs(self.pointerFrames) do
        if not active[unit] then
            pointer:Hide()
        end
    end
end

function PointerSystem:UpdatePulse()
    local now = GetTime and GetTime() or 0
    for _, pointer in pairs(self.pointerFrames) do
        if pointer.IsShown and pointer:IsShown() and pointer.SetAlpha then
            local wave = math.sin((now + (pointer.pulseOffset or 0)) * self.PULSE_SPEED)
            local alpha = self.PULSE_BASE + ((wave + 1) * 0.5 * self.PULSE_RANGE)
            pointer:SetAlpha(alpha)

            if pointer.ring then
                local ringAlpha = 0.05 + ((wave + 1) * 0.5 * 0.12)
                local currentR, currentG, currentB = 0.32, 0.70, 0.96
                if pointer.texture and pointer.texture.GetVertexColor then
                    currentR, currentG, currentB = pointer.texture:GetVertexColor()
                end
                setTextureColor(pointer.ring, currentR, currentG, currentB, ringAlpha)
            end
        end
    end
end

function PointerSystem:GetVisibleCount()
    local count = 0
    for _, pointer in pairs(self.pointerFrames or {}) do
        if pointer.IsShown and pointer:IsShown() then
            count = count + 1
        end
    end
    return count
end

function PointerSystem:OnUpdate(elapsed)
    if not self.driverActive then
        return
    end

    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:RefreshPointers()
    self:UpdatePulse()
end

function PointerSystem:OnSettingsChanged()
    self:SetDriverActive(self:ShouldRunUpdates())
    self:RefreshPointers()
end

function PointerSystem:HandleEvent(event)
    if event == "PLAYER_ENTERING_WORLD"
        or event == "GROUP_ROSTER_UPDATE"
        or event == "ARENA_OPPONENT_UPDATE"
        or event == "NAME_PLATE_UNIT_ADDED"
        or event == "NAME_PLATE_UNIT_REMOVED"
    then
        self:RefreshPointers()
    end
end
