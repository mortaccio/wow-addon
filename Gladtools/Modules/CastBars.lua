local _, GT = ...

local CastBars = {}
GT.CastBars = CastBars
GT:RegisterModule("CastBars", CastBars)

CastBars.UPDATE_INTERVAL = 0.05

local trackedUnits = {
    "arena1",
    "arena2",
    "arena3",
    "target",
    "focus",
}

local function createCastBar(unit)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(218, 20)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
    end

    frame.statusBar = CreateFrame("StatusBar", nil, frame)
    frame.statusBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.statusBar:SetPoint("TOPLEFT", 1, -1)
    frame.statusBar:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.statusBar:SetMinMaxValues(0, 1)
    frame.statusBar:SetValue(0)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("RIGHT", frame, "LEFT", -4, 0)
    frame.icon:SetSize(18, 18)

    frame.spellText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.spellText:SetPoint("LEFT", frame, "LEFT", 5, 0)
    frame.spellText:SetPoint("RIGHT", frame, "RIGHT", -36, 0)
    frame.spellText:SetJustifyH("LEFT")

    frame.timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.timeText:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    frame.timeText:SetJustifyH("RIGHT")

    frame.unit = unit
    frame.isActive = false
    frame.stopAt = nil
    frame:Hide()

    return frame
end

local function isArenaUnit(unit)
    return unit and unit:match("^arena%d$") ~= nil
end

function CastBars:Init()
    self.bars = {}
    for _, unit in ipairs(trackedUnits) do
        self.bars[unit] = createCastBar(unit)
    end

    self.driver = CreateFrame("Frame", "GladtoolsCastBarsDriver", UIParent)
    self.driver:SetScript("OnUpdate", function(_, elapsed)
        CastBars:OnUpdate(elapsed)
    end)

    self.elapsed = 0
end

function CastBars:IsEnabledForUnit(unit)
    local castSettings = GT:GetSetting({ "castBars" })
    if not castSettings or not castSettings.enabled then
        return false
    end

    if isArenaUnit(unit) then
        return castSettings.arena and true or false
    end

    if unit == "target" then
        return castSettings.target and true or false
    end

    if unit == "focus" then
        return castSettings.focus and true or false
    end

    return false
end

function CastBars:AnchorBar(unit)
    local bar = self.bars[unit]
    if not bar then
        return
    end

    bar:ClearAllPoints()

    local hostFrame = GT.UnitFrames and GT.UnitFrames:GetUnitFrame(unit)
    if hostFrame and hostFrame.castAnchor then
        bar:SetPoint("TOPLEFT", hostFrame.castAnchor, "TOPLEFT", 0, 0)
        return
    end

    if unit == "target" then
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    elseif unit == "focus" then
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -248)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", -300, -130)
    end
end

function CastBars:StartCast(unit, isChannel)
    local bar = self.bars[unit]
    if not bar then
        return
    end

    if not self:IsEnabledForUnit(unit) then
        bar:Hide()
        bar.isActive = false
        return
    end

    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible
    if isChannel then
        name, _, texture, startTimeMS, endTimeMS, _, notInterruptible = UnitChannelInfo(unit)
    else
        name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unit)
    end

    if not name or not startTimeMS or not endTimeMS then
        return
    end

    local startTime = startTimeMS / 1000
    local endTime = endTimeMS / 1000
    local duration = math.max(0.1, endTime - startTime)

    bar.spellName = name
    bar.icon:SetTexture(texture)
    bar.startTime = startTime
    bar.endTime = endTime
    bar.duration = duration
    bar.isChannel = isChannel and true or false
    bar.isActive = true
    bar.stopAt = nil

    bar.statusBar:SetMinMaxValues(0, duration)
    if bar.isChannel then
        bar.statusBar:SetValue(duration)
    else
        bar.statusBar:SetValue(0)
    end

    if notInterruptible then
        bar.statusBar:SetStatusBarColor(0.45, 0.45, 0.45, 1)
    else
        bar.statusBar:SetStatusBarColor(0.90, 0.70, 0.10, 1)
    end

    bar.spellText:SetText(name)
    self:AnchorBar(unit)
    bar:Show()
end

function CastBars:StopCast(unit, text, r, g, b)
    local bar = self.bars[unit]
    if not bar then
        return
    end

    if text then
        bar.spellText:SetText(text)
        bar.timeText:SetText("")
        bar.statusBar:SetStatusBarColor(r or 0.8, g or 0.2, b or 0.2, 1)
        bar.stopAt = (GetTime and GetTime() or 0) + 0.6
        bar.isActive = false
        bar:Show()
        return
    end

    bar.isActive = false
    bar.stopAt = nil
    bar:Hide()
end

function CastBars:UpdateActiveBar(bar, now)
    if bar.isActive then
        local remaining = bar.endTime - now
        if remaining <= 0 then
            self:StopCast(bar.unit)
            return
        end

        if bar.isChannel then
            bar.statusBar:SetValue(remaining)
        else
            bar.statusBar:SetValue(bar.duration - remaining)
        end

        bar.timeText:SetText(GT:FormatRemaining(remaining))
    elseif bar.stopAt and now >= bar.stopAt then
        bar.stopAt = nil
        bar:Hide()
    end
end

function CastBars:OnUpdate(elapsed)
    self.elapsed = self.elapsed + (elapsed or 0)
    if self.elapsed < self.UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0

    local now = GetTime and GetTime() or 0
    for _, bar in pairs(self.bars) do
        self:UpdateActiveBar(bar, now)
    end
end

function CastBars:OnSettingsChanged()
    for unit, bar in pairs(self.bars) do
        if self:IsEnabledForUnit(unit) then
            self:AnchorBar(unit)
        else
            bar:Hide()
            bar.isActive = false
            bar.stopAt = nil
        end
    end
end

function CastBars:HandleEvent(event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "ARENA_OPPONENT_UPDATE" then
        self:OnSettingsChanged()
        return
    end

    if event ~= "UNIT_SPELLCAST_START"
        and event ~= "UNIT_SPELLCAST_STOP"
        and event ~= "UNIT_SPELLCAST_FAILED"
        and event ~= "UNIT_SPELLCAST_INTERRUPTED"
        and event ~= "UNIT_SPELLCAST_CHANNEL_START"
        and event ~= "UNIT_SPELLCAST_CHANNEL_STOP"
        and event ~= "UNIT_SPELLCAST_CHANNEL_UPDATE"
        and event ~= "UNIT_SPELLCAST_DELAYED"
    then
        return
    end

    local unit = arg1
    if not unit or not self.bars[unit] then
        return
    end

    if event == "UNIT_SPELLCAST_START" then
        self:StartCast(unit, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:StartCast(unit, true)
    elseif event == "UNIT_SPELLCAST_DELAYED" then
        self:StartCast(unit, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        self:StartCast(unit, true)
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        self:StopCast(unit, "Interrupted", 0.9, 0.2, 0.2)
    elseif event == "UNIT_SPELLCAST_FAILED" then
        self:StopCast(unit, "Failed", 0.9, 0.35, 0.2)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        self:StopCast(unit)
    end
end
