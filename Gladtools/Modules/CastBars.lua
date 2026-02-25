local _, GT = ...

local CastBars = {}
GT.CastBars = CastBars
GT:RegisterModule("CastBars", CastBars)

CastBars.UPDATE_INTERVAL = 0.05

CastBars.COLORS = {
    cast = { 0.92, 0.72, 0.20 },
    channel = { 0.26, 0.76, 0.98 },
    locked = { 0.52, 0.52, 0.52 },
    interrupted = { 0.90, 0.20, 0.20 },
    failed = { 0.95, 0.45, 0.22 },
}

local trackedUnits = {
    "arena1",
    "arena2",
    "arena3",
    "target",
    "focus",
}

local function setTextureColor(texture, r, g, b, a)
    if texture and texture.SetVertexColor then
        texture:SetVertexColor(r, g, b, a or 1)
    end
end

local function applyBarColor(bar, color, borderAlpha)
    local r = color and color[1] or 0.9
    local g = color and color[2] or 0.7
    local b = color and color[3] or 0.2

    bar.statusBar:SetStatusBarColor(r, g, b, 0.95)
    setTextureColor(bar.statusBG, (r * 0.20) + 0.05, (g * 0.20) + 0.05, (b * 0.20) + 0.05, 0.95)

    if bar.SetBackdropBorderColor then
        bar:SetBackdropBorderColor((r * 0.46) + 0.10, (g * 0.46) + 0.10, (b * 0.46) + 0.10, borderAlpha or 0.95)
    end
end

local function createCastBar(unit)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(252, 18)

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface/Buttons/WHITE8x8",
            edgeFile = "Interface/Buttons/WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.03, 0.03, 0.04, 0.88)
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0.18, 0.18, 0.20, 0.95)
        end
    end

    frame.iconBG = frame:CreateTexture(nil, "BACKGROUND")
    frame.iconBG:SetTexture("Interface/Buttons/WHITE8x8")
    frame.iconBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    frame.iconBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 18, 2)
    setTextureColor(frame.iconBG, 0.02, 0.02, 0.02, 0.86)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 17, 3)
    if frame.icon.SetTexCoord then
        frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    frame.statusBG = frame:CreateTexture(nil, "BORDER")
    frame.statusBG:SetTexture("Interface/Buttons/WHITE8x8")
    frame.statusBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -2)
    frame.statusBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    setTextureColor(frame.statusBG, 0.09, 0.09, 0.10, 0.95)

    frame.statusBar = CreateFrame("StatusBar", nil, frame)
    frame.statusBar:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
    frame.statusBar:SetPoint("TOPLEFT", frame.statusBG, "TOPLEFT", 0, 0)
    frame.statusBar:SetPoint("BOTTOMRIGHT", frame.statusBG, "BOTTOMRIGHT", 0, 0)
    frame.statusBar:SetMinMaxValues(0, 1)
    frame.statusBar:SetValue(0)

    frame.spellText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.spellText:SetPoint("LEFT", frame.statusBar, "LEFT", 4, 0)
    frame.spellText:SetPoint("RIGHT", frame.statusBar, "RIGHT", -48, 0)
    frame.spellText:SetJustifyH("LEFT")
    if frame.spellText.SetShadowOffset then
        frame.spellText:SetShadowOffset(1, -1)
    end
    if frame.spellText.SetShadowColor then
        frame.spellText:SetShadowColor(0, 0, 0, 1)
    end

    frame.flagText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.flagText:SetPoint("RIGHT", frame.statusBar, "RIGHT", -28, 0)
    frame.flagText:SetJustifyH("RIGHT")
    frame.flagText:SetText("")

    frame.timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.timeText:SetPoint("RIGHT", frame.statusBar, "RIGHT", -4, 0)
    frame.timeText:SetJustifyH("RIGHT")
    if frame.timeText.SetShadowOffset then
        frame.timeText:SetShadowOffset(1, -1)
    end
    if frame.timeText.SetShadowColor then
        frame.timeText:SetShadowColor(0, 0, 0, 1)
    end

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
        local width = hostFrame.GetWidth and hostFrame:GetWidth() or 252
        bar:SetSize(width, 18)
        bar:SetPoint("TOPLEFT", hostFrame.castAnchor, "TOPLEFT", 0, 0)
        return
    end

    bar:SetSize(252, 18)

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
    bar.icon:SetTexture(texture or 134400)
    bar.startTime = startTime
    bar.endTime = endTime
    bar.duration = duration
    bar.isChannel = isChannel and true or false
    bar.isActive = true
    bar.stopAt = nil
    bar.interruptible = not notInterruptible

    bar.statusBar:SetMinMaxValues(0, duration)
    if bar.isChannel then
        bar.statusBar:SetValue(duration)
    else
        bar.statusBar:SetValue(0)
    end

    local color = self.COLORS.cast
    if not bar.interruptible then
        color = self.COLORS.locked
    elseif bar.isChannel then
        color = self.COLORS.channel
    end
    applyBarColor(bar, color)

    if bar.interruptible then
        bar.flagText:SetText("")
    else
        bar.flagText:SetText("NI")
        bar.flagText:SetTextColor(0.92, 0.92, 0.92)
    end

    bar.spellText:SetText(name)
    bar.timeText:SetText(GT:FormatRemaining(duration))
    if bar.SetAlpha then
        bar:SetAlpha(1)
    end

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
        bar.flagText:SetText("")
        applyBarColor(bar, { r or 0.8, g or 0.2, b or 0.2 }, 1)
        bar.stopAt = (GetTime and GetTime() or 0) + 0.65
        bar.isActive = false
        if bar.SetAlpha then
            bar:SetAlpha(1)
        end
        bar:Show()
        return
    end

    bar.isActive = false
    bar.stopAt = nil
    if bar.SetAlpha then
        bar:SetAlpha(1)
    end
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
    elseif bar.stopAt then
        local fadeRemaining = bar.stopAt - now
        if fadeRemaining <= 0 then
            bar.stopAt = nil
            if bar.SetAlpha then
                bar:SetAlpha(1)
            end
            bar:Hide()
            return
        end

        if bar.SetAlpha then
            bar:SetAlpha(math.max(0.25, fadeRemaining / 0.65))
        end
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
            if bar.SetAlpha then
                bar:SetAlpha(1)
            end
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
        local interrupted = self.COLORS.interrupted
        self:StopCast(unit, "Interrupted", interrupted[1], interrupted[2], interrupted[3])
    elseif event == "UNIT_SPELLCAST_FAILED" then
        local failed = self.COLORS.failed
        self:StopCast(unit, "Failed", failed[1], failed[2], failed[3])
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        self:StopCast(unit)
    end
end
