local _, GT = ...

local PointerSystem = {}
GT.PointerSystem = PointerSystem
GT:RegisterModule("PointerSystem", PointerSystem)

PointerSystem.UPDATE_INTERVAL = 0.20

local function createPointerFrame(unit)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(24, 24)

    frame.texture = frame:CreateTexture(nil, "OVERLAY")
    frame.texture:SetAllPoints(frame)
    frame.texture:SetTexture("Interface/Minimap/Minimap-QuestArrow")
    frame.texture:SetRotation(math.rad(-90))

    frame.unit = unit
    frame:Hide()

    return frame
end

function PointerSystem:Init()
    self.pointerFrames = {}
    self.explicitTargets = {}

    self.driver = CreateFrame("Frame", "GladtoolsPointerDriver", UIParent)
    self.driver:SetScript("OnUpdate", function(_, elapsed)
        PointerSystem:OnUpdate(elapsed)
    end)

    self.elapsed = 0
end

function PointerSystem:SetPointerTarget(unitToken, enabled)
    if not unitToken then
        return
    end

    self.explicitTargets[unitToken] = enabled and true or nil
    self:RefreshPointers()
end

function PointerSystem:GetOrCreatePointer(unit)
    local frame = self.pointerFrames[unit]
    if not frame then
        frame = createPointerFrame(unit)
        self.pointerFrames[unit] = frame
    end
    return frame
end

function PointerSystem:AnchorPointer(pointerFrame, unit)
    local size = GT:GetSetting({ "pointers", "size" }) or 24
    size = math.max(16, math.min(42, size))
    pointerFrame:SetSize(size, size)

    local unitFrame = GT.UnitFrames and GT.UnitFrames:GetUnitFrame(unit)
    if unitFrame and unitFrame:IsShown() then
        pointerFrame:ClearAllPoints()
        pointerFrame:SetPoint("RIGHT", unitFrame, "LEFT", -4, 0)
        pointerFrame:Show()
        return true
    end

    if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
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
        return {}
    end

    local mode = settings.pointers and settings.pointers.mode or GT.POINTER_MODES.OFF
    local units = GT.UnitMap:GetGroupFriendlyUnits(mode)

    for unit in pairs(self.explicitTargets) do
        units[#units + 1] = unit
    end

    return units
end

function PointerSystem:RefreshPointers()
    local units = self:GetPointerUnits()
    local active = {}

    for _, unit in ipairs(units) do
        active[unit] = true
        local pointer = self:GetOrCreatePointer(unit)
        self:AnchorPointer(pointer, unit)
    end

    for unit, pointer in pairs(self.pointerFrames) do
        if not active[unit] then
            pointer:Hide()
        end
    end
end

function PointerSystem:OnUpdate(elapsed)
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:RefreshPointers()
end

function PointerSystem:OnSettingsChanged()
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
