-- AuraFix Edit Mode Config Panel
-- Only works on Retail (EditModeManager)

local ADDON, ns = ...
local AuraFix = _G.AuraFix or {}

-- Add references to globals
local InterfaceOptionsFrame = _G.InterfaceOptionsFrame
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory
local AuraFixFrame = _G.AuraFixFrame
local AuraFixDebuffFrame = _G.AuraFixDebuffFrame

-- Initialize default settings
local defaults = {
    buffSize = 32,
    debuffSize = 32,
    buffX = 0,
    buffY = 0,
    debuffX = 0,
    debuffY = -50,
    buffGrow = "RIGHT",
    debuffGrow = "RIGHT",
    sortMethod = "INDEX",
    showBuffBackground = true,
    showDebuffBackground = true
}

local function InitializeDB()
    if not AuraFixDB then
        AuraFixDB = {}
    end
    -- Apply defaults for any missing values
    for k, v in pairs(defaults) do
        if AuraFixDB[k] == nil then
            AuraFixDB[k] = v
        end
    end
end

local function ApplyAuraFixSettings()
    if AuraFixFrame then
        AuraFixFrame:SetSize(AuraFixDB.buffSize * 10, AuraFixDB.buffSize)
        AuraFixFrame:SetPoint("CENTER", UIParent, "CENTER", AuraFixDB.buffX, AuraFixDB.buffY)
        for i, btn in ipairs(AuraFix.buttons or {}) do
            btn:SetSize(AuraFixDB.buffSize, AuraFixDB.buffSize)
        end
        if AuraFixFrame.background then
            if AuraFixDB.showBuffBackground then
                AuraFixFrame.background:Show()
            else
                AuraFixFrame.background:Hide()
            end
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
        if AuraFixDebuffFrame.background then
            if AuraFixDB.showDebuffBackground then
                AuraFixDebuffFrame.background:Show()
            else
                AuraFixDebuffFrame.background:Hide()
            end
        end
        if AuraFix.UpdateAllAuras then
            AuraFix:UpdateAllAuras(AuraFixDebuffFrame, "player", "HARMFUL", 20)
        end
    end
end

AuraFix.ApplySettings = ApplyAuraFixSettings

local panel = CreateFrame("Frame", "AuraFixConfigPanel", UIParent)
panel.name = "AuraFix"

-- Create left and right columns
local leftColumn = CreateFrame("Frame", nil, panel)
leftColumn:SetPoint("TOPLEFT", 20, -20)
leftColumn:SetSize(300, 600)

local rightColumn = CreateFrame("Frame", nil, panel)
rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", 40, 0)
rightColumn:SetSize(300, 600)

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
local buffSizeSlider = CreateFrame("Slider", nil, leftColumn, "OptionsSliderTemplate")
buffSizeSlider:SetMinMaxValues(16, 64)
buffSizeSlider:SetValueStep(1)
buffSizeSlider:SetPoint("TOPLEFT", 0, -20)
buffSizeSlider:SetWidth(200)
buffSizeSlider:SetValue(AuraFixDB.buffSize)
buffSizeSlider.Text:SetText("Buff Size")
buffSizeSlider.Low:SetText("16")
buffSizeSlider.High:SetText("64")
-- Create value textbox for buff size
local buffSizeBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
buffSizeBox:SetSize(50, 20)
buffSizeBox:SetPoint("LEFT", buffSizeSlider, "RIGHT", 10, 0)
buffSizeBox:SetAutoFocus(false)
buffSizeBox:SetMaxLetters(2)
buffSizeBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(16, math.min(64, value))
        self:SetText(value)
        buffSizeSlider:SetValue(value)
    end
    self:ClearFocus()
end)

buffSizeSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.buffSize = value
    buffSizeBox:SetText(tostring(math.floor(value)))
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
-- Create value textbox for debuff size
local debuffSizeBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
debuffSizeBox:SetSize(50, 20)
debuffSizeBox:SetPoint("LEFT", debuffSizeSlider, "RIGHT", 10, 0)
debuffSizeBox:SetAutoFocus(false)
debuffSizeBox:SetMaxLetters(2)
debuffSizeBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(16, math.min(64, value))
        self:SetText(tostring(value))
        debuffSizeSlider:SetValue(value)
    end
    self:ClearFocus()
end)

debuffSizeSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.debuffSize = value
    debuffSizeBox:SetText(tostring(math.floor(value)))
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
-- Create value textbox for buff X offset
local buffXBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
buffXBox:SetSize(50, 20)
buffXBox:SetPoint("LEFT", buffXSlider, "RIGHT", 10, 0)
buffXBox:SetAutoFocus(false)
buffXBox:SetMaxLetters(4)
buffXBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(-960, math.min(960, value))
        self:SetText(tostring(value))
        buffXSlider:SetValue(value)
    end
    self:ClearFocus()
end)

buffXSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.buffX = value
    buffXBox:SetText(tostring(math.floor(value)))
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
-- Create value textbox for buff Y offset
local buffYBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
buffYBox:SetSize(50, 20)
buffYBox:SetPoint("LEFT", buffYSlider, "RIGHT", 10, 0)
buffYBox:SetAutoFocus(false)
buffYBox:SetMaxLetters(4)
buffYBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(-540, math.min(540, value))
        self:SetText(tostring(value))
        buffYSlider:SetValue(value)
    end
    self:ClearFocus()
end)

buffYSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.buffY = value
    buffYBox:SetText(tostring(math.floor(value)))
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
-- Create value textbox for debuff X offset
local debuffXBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
debuffXBox:SetSize(50, 20)
debuffXBox:SetPoint("LEFT", debuffXSlider, "RIGHT", 10, 0)
debuffXBox:SetAutoFocus(false)
debuffXBox:SetMaxLetters(4)
debuffXBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(-960, math.min(960, value))
        self:SetText(tostring(value))
        debuffXSlider:SetValue(value)
    end
    self:ClearFocus()
end)

debuffXSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.debuffX = value
    debuffXBox:SetText(tostring(math.floor(value)))
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
-- Create value textbox for debuff Y offset
local debuffYBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
debuffYBox:SetSize(50, 20)
debuffYBox:SetPoint("LEFT", debuffYSlider, "RIGHT", 10, 0)
debuffYBox:SetAutoFocus(false)
debuffYBox:SetMaxLetters(4)
debuffYBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(-540, math.min(540, value))
        self:SetText(tostring(value))
        debuffYSlider:SetValue(value)
    end
    self:ClearFocus()
end)

debuffYSlider:SetScript("OnValueChanged", function(self, value)
    AuraFixDB.debuffY = value
    debuffYBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
end)

-- Create dropdowns and filter box
-- Create dropdowns in right column
local buffGrowDD = CreateDropdown(rightColumn, "Buff Bar Growth", {"LEFT", "RIGHT"}, function() return AuraFixDB.buffGrow end, function(v) AuraFixDB.buffGrow = v; ApplyAuraFixSettings() end)
buffGrowDD:SetPoint("TOPLEFT", 0, -20)

local debuffGrowDD = CreateDropdown(rightColumn, "Debuff Bar Growth", {"LEFT", "RIGHT"}, function() return AuraFixDB.debuffGrow end, function(v) AuraFixDB.debuffGrow = v; ApplyAuraFixSettings() end)
debuffGrowDD:SetPoint("TOPLEFT", buffGrowDD, "BOTTOMLEFT", 0, -40)

local sortDD = CreateDropdown(rightColumn, "Sort Auras By", {"INDEX", "TIME", "NAME"}, function() return AuraFixDB.sortMethod end, function(v) AuraFixDB.sortMethod = v; ApplyAuraFixSettings() end)
sortDD:SetPoint("TOPLEFT", debuffGrowDD, "BOTTOMLEFT", 0, -40)

-- Create background toggle checkboxes
local buffBackgroundCheck = CreateFrame("CheckButton", nil, rightColumn, "InterfaceOptionsCheckButtonTemplate")
buffBackgroundCheck:SetPoint("TOPLEFT", sortDD, "BOTTOMLEFT", 0, -40)
buffBackgroundCheck.Text:SetText("Show Buff Background")
buffBackgroundCheck:SetChecked(AuraFixDB.showBuffBackground)
buffBackgroundCheck:SetScript("OnClick", function(self)
    AuraFixDB.showBuffBackground = self:GetChecked()
    ApplyAuraFixSettings()
end)

local debuffBackgroundCheck = CreateFrame("CheckButton", nil, rightColumn, "InterfaceOptionsCheckButtonTemplate")
debuffBackgroundCheck:SetPoint("TOPLEFT", buffBackgroundCheck, "BOTTOMLEFT", 0, -10)
debuffBackgroundCheck.Text:SetText("Show Debuff Background")
debuffBackgroundCheck:SetChecked(AuraFixDB.showDebuffBackground)
debuffBackgroundCheck:SetScript("OnClick", function(self)
    AuraFixDB.showDebuffBackground = self:GetChecked()
    ApplyAuraFixSettings()
end)

-- local filterBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
-- filterBox:SetSize(120, 24)
-- filterBox:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 16, -20)
-- filterBox:SetAutoFocus(false)
-- filterBox:SetText(AuraFixDB.filterText or "")
-- filterBox:SetScript("OnTextChanged", function(self)
--     AuraFixDB.filterText = self:GetText()
--     ApplyAuraFixSettings()
-- end)

-- local filterLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- filterLabel:SetPoint("BOTTOMLEFT", filterBox, "TOPLEFT", 0, 4)
-- filterLabel:SetText("Filter (substring)")

-- Update panel on show
panel:HookScript("OnShow", function()
    buffSizeSlider:SetValue(AuraFixDB.buffSize or 32)
    debuffSizeSlider:SetValue(AuraFixDB.debuffSize or 32)
    buffXSlider:SetValue(AuraFixDB.buffX or 0)
    buffYSlider:SetValue(AuraFixDB.buffY or 0)
    debuffXSlider:SetValue(AuraFixDB.debuffX or 0)
    debuffYSlider:SetValue(AuraFixDB.debuffY or -50)
    
    -- Update text boxes
    buffSizeBox:SetText(tostring(AuraFixDB.buffSize or 32))
    debuffSizeBox:SetText(tostring(AuraFixDB.debuffSize or 32))
    buffXBox:SetText(tostring(AuraFixDB.buffX or 0))
    buffYBox:SetText(tostring(AuraFixDB.buffY or 0))
    debuffXBox:SetText(tostring(AuraFixDB.debuffX or 0))
    debuffYBox:SetText(tostring(AuraFixDB.debuffY or -50))
    
    -- filterBox:SetText(AuraFixDB.filterText or "")
    UIDropDownMenu_SetSelectedValue(buffGrowDD, AuraFixDB.buffGrow or "RIGHT")
    UIDropDownMenu_SetSelectedValue(debuffGrowDD, AuraFixDB.debuffGrow or "RIGHT")
    UIDropDownMenu_SetSelectedValue(sortDD, AuraFixDB.sortMethod or "INDEX")
    buffBackgroundCheck:SetChecked(AuraFixDB.showBuffBackground)
    debuffBackgroundCheck:SetChecked(AuraFixDB.showDebuffBackground)
end)



-- Create event frame and register ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == ADDON then
        InitializeDB()
        ApplyAuraFixSettings()
        self:UnregisterEvent("ADDON_LOADED")
    end
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
