-- AuraFix Edit Mode Config Panel
-- Only works on Retail (EditModeManager)

local ADDON, ns = ...
local AuraFix = _G.AuraFix or {}

local function ApplyAuraFixSettings()
    if AuraFixFrame then
        AuraFixFrame:SetSize(AuraFixDB.buffSize * 10, AuraFixDB.buffSize)
        AuraFixFrame:SetPoint("CENTER", UIParent, "CENTER", AuraFixDB.buffX, AuraFixDB.buffY)
        for i, btn in ipairs(AuraFix.buttons or {}) do
            btn:SetSize(AuraFixDB.buffSize, AuraFixDB.buffSize)
        end
        if AuraFix.UpdateAllAuras then
            AuraFix:UpdateAllAuras(AuraFixFrame, "player", "HELPFUL", 20)
        end
    end
    if AuraFixDebuffFrame then
        AuraFixDebuffFrame:SetSize(AuraFixDB.debuffSize * 10, AuraFixDB.debuffSize)
        AuraFixDebuffFrame:SetPoint("TOPLEFT", AuraFixFrame, "BOTTOMLEFT", AuraFixDB.debuffX, AuraFixDB.debuffY)
        for i, btn in ipairs(AuraFix.debuffButtons or {}) do
            btn:SetSize(AuraFixDB.debuffSize, AuraFixDB.debuffSize)
        end
        if AuraFix.UpdateAllAuras then
            AuraFix:UpdateAllAuras(AuraFixDebuffFrame, "player", "HARMFUL", 20)
        end
    end
end

AuraFix.ApplySettings = ApplyAuraFixSettings

local panel = CreateFrame("Frame", "AuraFixConfigPanel", UIParent)
panel.name = "AuraFix"

local function CreateDropdown(parent, label, items, value, onChange)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd.Label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dd.Label:SetPoint("TOPLEFT", dd, "TOPLEFT", 16, 8)
    dd.Label:SetText(label)
    UIDropDownMenu_SetWidth(dd, 120)
    UIDropDownMenu_Initialize(dd, function(self, level)
        for _, v in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v
            info.checked = (v == value())
            info.func = function()
                onChange(v)
                UIDropDownMenu_SetSelectedValue(dd, v)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dd, value())
    return dd
end

-- Create all sliders
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

-- Create dropdowns and filter box
local lastAnchor = debuffYSlider

local buffGrowDD = CreateDropdown(panel, "Buff Bar Growth", {"LEFT", "RIGHT"}, function() return AuraFixDB.buffGrow end, function(v) AuraFixDB.buffGrow = v; ApplyAuraFixSettings() end)
buffGrowDD:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -40)
lastAnchor = buffGrowDD

local debuffGrowDD = CreateDropdown(panel, "Debuff Bar Growth", {"LEFT", "RIGHT"}, function() return AuraFixDB.debuffGrow end, function(v) AuraFixDB.debuffGrow = v; ApplyAuraFixSettings() end)
debuffGrowDD:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -40)
lastAnchor = debuffGrowDD

local sortDD = CreateDropdown(panel, "Sort Auras By", {"INDEX", "TIME", "NAME"}, function() return AuraFixDB.sortMethod end, function(v) AuraFixDB.sortMethod = v; ApplyAuraFixSettings() end)
sortDD:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -40)
lastAnchor = sortDD

local filterBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
filterBox:SetSize(120, 24)
filterBox:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 16, -20)
filterBox:SetAutoFocus(false)
filterBox:SetText(AuraFixDB.filterText or "")
filterBox:SetScript("OnTextChanged", function(self)
    AuraFixDB.filterText = self:GetText()
    ApplyAuraFixSettings()
end)

local filterLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterLabel:SetPoint("BOTTOMLEFT", filterBox, "TOPLEFT", 0, 4)
filterLabel:SetText("Filter (substring)")

-- Update panel on show
panel:HookScript("OnShow", function()
    buffSizeSlider:SetValue(AuraFixDB.buffSize or 32)
    debuffSizeSlider:SetValue(AuraFixDB.debuffSize or 32)
    buffXSlider:SetValue(AuraFixDB.buffX or 0)
    buffYSlider:SetValue(AuraFixDB.buffY or 0)
    debuffXSlider:SetValue(AuraFixDB.debuffX or 0)
    debuffYSlider:SetValue(AuraFixDB.debuffY or -50)
    filterBox:SetText(AuraFixDB.filterText or "")
    UIDropDownMenu_SetSelectedValue(buffGrowDD, AuraFixDB.buffGrow or "RIGHT")
    UIDropDownMenu_SetSelectedValue(debuffGrowDD, AuraFixDB.debuffGrow or "RIGHT")
    UIDropDownMenu_SetSelectedValue(sortDD, AuraFixDB.sortMethod or "INDEX")
end)

-- Register panel
local panelCategory
if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
    panelCategory = Settings.RegisterCanvasLayoutCategory(panel, "AuraFix")
    Settings.RegisterAddOnCategory(panelCategory)
else
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- Slash command
SLASH_AURAFIX1 = "/aurafix"
SlashCmdList["AURAFIX"] = function()
    if Settings and Settings.OpenToCategory then
        if panelCategory then
            Settings.OpenToCategory(panelCategory)
        else
            Settings.OpenToCategory(panel)
        end
        C_Timer.After(0.5, function()
            if panel then panel:Show() end
        end)
    elseif InterfaceOptionsFrame_OpenToCategory and panel then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
        if InterfaceOptionsFrame then InterfaceOptionsFrame:Show() end
    else
        panel:Show()
    end
end
