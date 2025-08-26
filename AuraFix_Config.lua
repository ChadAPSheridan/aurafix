-- AuraFix Edit Mode Config Panel
-- Only works on Retail (EditModeManager)

local ADDON, ns = ...
local AuraFix = _G.AuraFix or {}

-- Default settings
AuraFixDB = AuraFixDB or {
    buffSize = 32,
    debuffSize = 32,
    buffX = 0,
    buffY = 0,
    debuffX = 0,
    debuffY = -50,
}

local function ApplyAuraFixSettings()
    if AuraFixFrame then
        AuraFixFrame:SetSize(AuraFixDB.buffSize * 10, AuraFixDB.buffSize)
        AuraFixFrame:SetPoint("CENTER", UIParent, "CENTER", AuraFixDB.buffX, AuraFixDB.buffY)
        for i, btn in ipairs(AuraFix.buttons or {}) do
            btn:SetSize(AuraFixDB.buffSize, AuraFixDB.buffSize)
        end
    end
    if AuraFixDebuffFrame then
        AuraFixDebuffFrame:SetSize(AuraFixDB.debuffSize * 10, AuraFixDB.debuffSize)
        AuraFixDebuffFrame:SetPoint("TOPLEFT", AuraFixFrame, "BOTTOMLEFT", AuraFixDB.debuffX, AuraFixDB.debuffY)
        for i, btn in ipairs(AuraFix.debuffButtons or {}) do
            btn:SetSize(AuraFixDB.debuffSize, AuraFixDB.debuffSize)
        end
    end
end

AuraFix.ApplySettings = ApplyAuraFixSettings

-- Edit Mode integration (Retail only)

-- Always create the config panel and register it with Interface Options
local panel = CreateFrame("Frame", "AuraFixConfigPanel", UIParent)
panel.name = "AuraFix"

local buffSizeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
buffSizeSlider:SetMinMaxValues(16, 64)
buffSizeSlider:SetValueStep(1)
buffSizeSlider:SetPoint("TOPLEFT", 20, -40)
buffSizeSlider:SetWidth(200)
buffSizeSlider:SetValue(AuraFixDB.buffSize)
buffSizeSlider.Text:SetText("Buff Size")
buffSizeSlider.Low:SetText("16")
buffSizeSlider.High:SetText("64")
buffSizeSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.buffSize = value
    ApplyAuraFixSettings()
end)

local debuffSizeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffSizeSlider:SetMinMaxValues(16, 64)
debuffSizeSlider:SetValueStep(1)
debuffSizeSlider:SetPoint("TOPLEFT", buffSizeSlider, "BOTTOMLEFT", 0, -40)
debuffSizeSlider:SetWidth(200)
debuffSizeSlider:SetValue(AuraFixDB.debuffSize)
debuffSizeSlider.Text:SetText("Debuff Size")
debuffSizeSlider.Low:SetText("16")
debuffSizeSlider.High:SetText("64")
debuffSizeSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.debuffSize = value
    ApplyAuraFixSettings()
end)

-- Utility to get screen size
local function GetScreenSize()
    local width = GetScreenWidth and GetScreenWidth() or 1920
    local height = GetScreenHeight and GetScreenHeight() or 1080
    return width, height
end

-- Buff and debuff position sliders (created with dummy values, updated on panel show)
local buffXSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
buffXSlider:SetMinMaxValues(-960, 960)
buffXSlider:SetValueStep(1)
buffXSlider:SetPoint("TOPLEFT", debuffSizeSlider, "BOTTOMLEFT", 0, -40)
buffXSlider:SetWidth(200)
buffXSlider:SetValue(AuraFixDB.buffX)
buffXSlider.Text:SetText("Buff X Offset")
buffXSlider.Low:SetText("-960")
buffXSlider.High:SetText("960")
buffXSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.buffX = value
    ApplyAuraFixSettings()
end)

local buffYSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
buffYSlider:SetMinMaxValues(-540, 540)
buffYSlider:SetValueStep(1)
buffYSlider:SetPoint("TOPLEFT", buffXSlider, "BOTTOMLEFT", 0, -40)
buffYSlider:SetWidth(200)
buffYSlider:SetValue(AuraFixDB.buffY)
buffYSlider.Text:SetText("Buff Y Offset")
buffYSlider.Low:SetText("-540")
buffYSlider.High:SetText("540")
buffYSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.buffY = value
    ApplyAuraFixSettings()
end)

local debuffXSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffXSlider:SetMinMaxValues(-960, 960)
debuffXSlider:SetValueStep(1)
debuffXSlider:SetPoint("TOPLEFT", buffYSlider, "BOTTOMLEFT", 0, -40)
debuffXSlider:SetWidth(200)
debuffXSlider:SetValue(AuraFixDB.debuffX)
debuffXSlider.Text:SetText("Debuff X Offset")
debuffXSlider.Low:SetText("-960")
debuffXSlider.High:SetText("960")
debuffXSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.debuffX = value
    ApplyAuraFixSettings()
end)

local debuffYSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffYSlider:SetMinMaxValues(-540, 540)
debuffYSlider:SetValueStep(1)
debuffYSlider:SetPoint("TOPLEFT", debuffXSlider, "BOTTOMLEFT", 0, -40)
debuffYSlider:SetWidth(200)
debuffYSlider:SetValue(AuraFixDB.debuffY)
debuffYSlider.Text:SetText("Debuff Y Offset")
debuffYSlider.Low:SetText("-540")
debuffYSlider.High:SetText("540")
debuffYSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.debuffY = value
    ApplyAuraFixSettings()
end)

-- Update slider bounds on panel show
panel:HookScript("OnShow", function()
    local w, h = GetScreenSize()
    buffXSlider:SetMinMaxValues(-w/2, w/2)
    buffXSlider.Low:SetText(tostring(-math.floor(w/2)))
    buffXSlider.High:SetText(tostring(math.floor(w/2)))
    buffYSlider:SetMinMaxValues(-h/2, h/2)
    buffYSlider.Low:SetText(tostring(-math.floor(h/2)))
    buffYSlider.High:SetText(tostring(math.floor(h/2)))
    debuffXSlider:SetMinMaxValues(-w/2, w/2)
    debuffXSlider.Low:SetText(tostring(-math.floor(w/2)))
    debuffXSlider.High:SetText(tostring(math.floor(w/2)))
    debuffYSlider:SetMinMaxValues(-h/2, h/2)
    debuffYSlider.Low:SetText(tostring(-math.floor(h/2)))
    debuffYSlider.High:SetText(tostring(math.floor(h/2)))
end)

-- Register the panel with Interface Options or new Settings API
if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
    -- Dragonflight+ API (WoW 10.x+)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "AuraFix")
    Settings.RegisterAddOnCategory(category)
else
    panel:Show()
end

-- Add a slash command to open the config panel
SLASH_AURAFIX1 = "/aurafix"
SlashCmdList["AURAFIX"] = function()
    if Settings and Settings.OpenToCategory then
        -- Dragonflight+ API: open to our category
        Settings.OpenToCategory(panel.name or panel)
    else
        panel:Show()
    end
end
