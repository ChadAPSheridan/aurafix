-- AuraFix Edit Mode Config Panel
-- Only works on Retail (EditModeManager)

local ADDON, ns = ...
local AuraFix = _G.AuraFix or {}

-- Add references to globals
local InterfaceOptionsFrame = _G.InterfaceOptionsFrame
local InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local InterfaceOptions_AddCategory = _G.InterfaceOptions_AddCategory
local AuraFixFrame = _G.AuraFixFrame or CreateFrame("Frame", "AuraFixFrame", UIParent)
local AuraFixDebuffFrame = _G.AuraFixDebuffFrame

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
    showDebuffBackground = true,
    buffColumns = 12,
    buffRows = 1,
    debuffColumns = 12,
    debuffRows = 1
}

-- Profile support
local function getDefaultProfile()
    local t = {}
    for k, v in pairs(defaults) do t[k] = v end
    -- Center bars by default
    t.buffX = 0; t.buffY = 0; t.debuffX = 0; t.debuffY = 0
    return t
end

-- Per-character currentProfile, account-wide profiles
function InitializeDB()
    _G.InitializeDB = InitializeDB
    if not AuraFixDB then AuraFixDB = {} end
    if not AuraFixDB.profiles then
        AuraFixDB.profiles = { ["Default"] = getDefaultProfile() }
    end
    if not AuraFixCharDB then AuraFixCharDB = {} end
    if not AuraFixCharDB.currentProfile then
        AuraFixCharDB.currentProfile = "Default"
    end
    -- Migrate old settings to Default profile if needed
    for k, v in pairs(defaults) do
        if AuraFixDB[k] ~= nil and (not AuraFixDB.profiles["Default"][k]) then
            AuraFixDB.profiles["Default"][k] = AuraFixDB[k]
            AuraFixDB[k] = nil
        end
    end
    -- Set active profile reference
    AuraFix.profile = AuraFixDB.profiles[AuraFixCharDB.currentProfile]
end


local function getProfile()
    if not AuraFixDB or not AuraFixDB.profiles or not AuraFixCharDB or not AuraFixCharDB.currentProfile then
        return getDefaultProfile()
    end
    return AuraFixDB.profiles[AuraFixCharDB.currentProfile] or getDefaultProfile()
end

local function ApplyAuraFixSettings()
    local prof = getProfile()
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()

    if AuraFixFrame then
        AuraFixFrame:ClearAllPoints()  -- Clear existing anchors
        local adjustedBuffX = (screenWidth / 2) + prof.buffX
        local adjustedBuffY = (screenHeight / 2) + prof.buffY
        AuraFixFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", adjustedBuffX, adjustedBuffY)
        if AuraFixDB.debugMode then
            print("AuraFixFrame adjusted position:", adjustedBuffX, adjustedBuffY)
        end
        AuraFixFrame:Show()  -- Ensure frame is visible
    end

    if AuraFixDebuffFrame then
        AuraFixDebuffFrame:ClearAllPoints()  -- Clear existing anchors
        local adjustedDebuffX = (screenWidth / 2) + prof.debuffX
        local adjustedDebuffY = (screenHeight / 2) + prof.debuffY
        AuraFixDebuffFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", adjustedDebuffX, adjustedDebuffY)
        if AuraFixDB.debugMode then
            print("AuraFixDebuffFrame adjusted position:", adjustedDebuffX, adjustedDebuffY)
        end
        AuraFixDebuffFrame:Show()  -- Ensure frame is visible
    end
end

AuraFix.ApplySettings = ApplyAuraFixSettings

local panel = CreateFrame("Frame", "AuraFixConfigPanel", UIParent)
panel.name = "AuraFix"

local leftColumn = CreateFrame("Frame", nil, panel)
leftColumn:SetPoint("TOPLEFT", 20, -20)
leftColumn:SetSize(300, 600)

local rightColumn = CreateFrame("Frame", nil, panel)
rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", 40, 0)
rightColumn:SetSize(300, 600)

-- Profile dropdown and new profile button
local profileLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profileLabel:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 20, -4)
profileLabel:SetText("Profile:")

local profileDD = CreateFrame("Frame", nil, leftColumn, "UIDropDownMenuTemplate")
profileDD:SetPoint("LEFT", profileLabel, "RIGHT", 4, 0)

local function RefreshProfileDropdown()
    if not AuraFixDB or not AuraFixDB.profiles then return end
    local items = {}
    for k in pairs(AuraFixDB.profiles) do table.insert(items, k) end
    table.sort(items)
    ForceAuraFixVisualUpdate()
    UIDropDownMenu_Initialize(profileDD, function(self, level)
        for _, name in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.checked = (name == AuraFixCharDB.currentProfile)
            info.func = function()
                AuraFixCharDB.currentProfile = name
                AuraFix.profile = AuraFixDB.profiles[name]
                ApplyAuraFixSettings()
                if panel.OnShow then panel:OnShow() end
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(profileDD, AuraFixCharDB.currentProfile)
end

local newProfileBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
newProfileBtn:SetSize(100, 22)
newProfileBtn:SetPoint("TOPLEFT", 20, 7)
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
newProfileBtn:SetText("New Profile")
newProfileBtn:SetScript("OnClick", function()
    StaticPopupDialogs["AURAFIX_NEW_PROFILE"] = {
        text = "Enter new profile name:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 32,
        OnAccept = function(self)
            local name = self.editBox:GetText():gsub("^%s+",""):gsub("%s+$","")
            if name ~= "" and not AuraFixDB.profiles[name] then
                AuraFixDB.profiles[name] = getDefaultProfile()
                AuraFixCharDB.currentProfile = name
                AuraFix.profile = AuraFixDB.profiles[name]
                ApplyAuraFixSettings()
                RefreshProfileDropdown()
                if panel.OnShow then panel:OnShow() end
                ForceAuraFixVisualUpdate()
            end
        end,
    timeout = 0,
    whileDead = true,
    exclusive = true,
    hideOnEscape = true,
    preferredIndex = 3,
    }
    StaticPopup_Show("AURAFIX_NEW_PROFILE")
end)

RefreshProfileDropdown()

local function CreateDropdown(parent, label, items, value, onChange)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd.Label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dd.Label:SetPoint("TOPLEFT", dd, "TOPLEFT", 16, 8)
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
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
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dd, value())
    return dd
end
-- Buff section label
local buffHeaderLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
buffHeaderLabel:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", 0, -20)
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
buffHeaderLabel:SetText("Buff Settings")

-- Debuff section label
local debuffHeaderLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
debuffHeaderLabel:SetPoint("TOPLEFT", newProfileBtn, "BOTTOMLEFT", 0, -20)
debuffHeaderLabel:SetText("Debuff Settings")

    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
-- Create all sliders
local buffSizeSlider = CreateFrame("Slider", nil, leftColumn, "OptionsSliderTemplate")
buffSizeSlider:SetMinMaxValues(16, 64)
buffSizeSlider:SetValueStep(1)
buffSizeSlider:SetPoint("TOPLEFT", buffHeaderLabel, "BOTTOMLEFT", 0, -20)
buffSizeSlider:SetWidth(200)
buffSizeSlider:SetValue(AuraFixDB.buffSize)
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
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
                if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end

buffSizeSlider:SetScript("OnValueChanged", function(self, value)
    if AuraFixDB.debugMode then
        print("Buff Size Slider Changed: ", value)
    end
    local prof = getProfile()
    prof.buffSize = value
    buffSizeBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

local debuffSizeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffSizeSlider:SetMinMaxValues(16, 64)
debuffSizeSlider:SetValueStep(1)
debuffSizeSlider:SetPoint("TOPLEFT", debuffHeaderLabel, "BOTTOMLEFT", 0, -20)
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
    if AuraFixDB.debugMode then
        print("Debuff Size Slider Changed: ", value)
    end
    local prof = getProfile()
    prof.debuffSize = value
    debuffSizeBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

local buffXSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
buffXSlider:SetMinMaxValues(-960, 960)
buffXSlider:SetValueStep(1)
buffXSlider:SetPoint("TOPLEFT", buffSizeSlider, "BOTTOMLEFT", 0, -40)
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
    if AuraFixDB.debugMode then
        print("Buff X Offset Slider Changed: ", value)
    end
    local prof = getProfile()
    prof.buffX = value
    buffXBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
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
    if AuraFixDB.debugMode then
        print("Buff Y Offset Slider Changed: ", value)
    end
    local prof = getProfile()
    prof.buffY = value
    buffYBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

-- Create buff columns slider
local buffColsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
buffColsSlider:SetMinMaxValues(1, 24)
buffColsSlider:SetValueStep(1)
buffColsSlider:SetPoint("TOPLEFT", buffYSlider, "BOTTOMLEFT", 0, -40)
buffColsSlider:SetWidth(200)
buffColsSlider:SetValue(AuraFixDB.buffColumns)
buffColsSlider.Text:SetText("Buff Columns")
buffColsSlider.Low:SetText("1")
buffColsSlider.High:SetText("24")

-- Create value textbox for buff columns
local buffColsBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
buffColsBox:SetSize(50, 20)
buffColsBox:SetPoint("LEFT", buffColsSlider, "RIGHT", 10, 0)
buffColsBox:SetAutoFocus(false)
buffColsBox:SetMaxLetters(2)
buffColsBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(1, math.min(24, value))
        self:SetText(tostring(value))
        buffColsSlider:SetValue(value)
    end
    self:ClearFocus()
end)

buffColsSlider:SetScript("OnValueChanged", function(self, value)
    local prof = getProfile()
    prof.buffColumns = value
    buffColsBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

-- Create buff rows slider
local buffRowsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
buffRowsSlider:SetMinMaxValues(1, 10)
buffRowsSlider:SetValueStep(1)
buffRowsSlider:SetPoint("TOPLEFT", buffColsSlider, "BOTTOMLEFT", 0, -40)
buffRowsSlider:SetWidth(200)
buffRowsSlider:SetValue(AuraFixDB.buffRows)
buffRowsSlider.Text:SetText("Buff Rows")
buffRowsSlider.Low:SetText("1")
buffRowsSlider.High:SetText("10")

-- Create value textbox for buff rows
local buffRowsBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
buffRowsBox:SetSize(50, 20)
buffRowsBox:SetPoint("LEFT", buffRowsSlider, "RIGHT", 10, 0)
buffRowsBox:SetAutoFocus(false)
buffRowsBox:SetMaxLetters(2)
buffRowsBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(1, math.min(10, value))
        self:SetText(tostring(value))
        buffRowsSlider:SetValue(value)
    end
    self:ClearFocus()
end)

buffRowsSlider:SetScript("OnValueChanged", function(self, value)
    local prof = getProfile()
    prof.buffRows = value
    buffRowsBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

-- Create explanatory label between buff and debuff sections
-- local explanatoryLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
-- explanatoryLabel:SetPoint("TOPLEFT", buffRowsSlider, "BOTTOMLEFT", 0, -20)
-- explanatoryLabel:SetText("Debuff position is now independent from buff position")

local debuffXSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffXSlider:SetMinMaxValues(-960, 960)
debuffXSlider:SetValueStep(1)
debuffXSlider:SetPoint("TOPLEFT", debuffSizeSlider, "BOTTOMLEFT", 0, -40)
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
    if AuraFixDB.debugMode then
        print("Debuff X Offset Slider Changed: ", value)
    end
    local prof = getProfile()
    prof.debuffX = value
    debuffXBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
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
    if AuraFixDB.debugMode then
        print("Debuff Y Offset Slider Changed: ", value)
    end
    local prof = getProfile()
    prof.debuffY = value
    debuffYBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

-- Create debuff columns slider
local debuffColsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffColsSlider:SetMinMaxValues(1, 24)
debuffColsSlider:SetValueStep(1)
debuffColsSlider:SetPoint("TOPLEFT", debuffYSlider, "BOTTOMLEFT", 0, -40)
debuffColsSlider:SetWidth(200)
debuffColsSlider:SetValue(AuraFixDB.debuffColumns)
debuffColsSlider.Text:SetText("Debuff Columns")
debuffColsSlider.Low:SetText("1")
debuffColsSlider.High:SetText("24")

-- Create value textbox for debuff columns
local debuffColsBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
debuffColsBox:SetSize(50, 20)
debuffColsBox:SetPoint("LEFT", debuffColsSlider, "RIGHT", 10, 0)
debuffColsBox:SetAutoFocus(false)
debuffColsBox:SetMaxLetters(2)
debuffColsBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(1, math.min(24, value))
        self:SetText(tostring(value))
        debuffColsSlider:SetValue(value)
    end
    self:ClearFocus()
end)

debuffColsSlider:SetScript("OnValueChanged", function(self, value)
    local prof = getProfile()
    prof.debuffColumns = value
    debuffColsBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

-- Create debuff rows slider
local debuffRowsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
debuffRowsSlider:SetMinMaxValues(1, 10)
debuffRowsSlider:SetValueStep(1)
debuffRowsSlider:SetPoint("TOPLEFT", debuffColsSlider, "BOTTOMLEFT", 0, -40)
debuffRowsSlider:SetWidth(200)
debuffRowsSlider:SetValue(AuraFixDB.debuffRows)
debuffRowsSlider.Text:SetText("Debuff Rows")
debuffRowsSlider.Low:SetText("1")
debuffRowsSlider.High:SetText("10")

-- Create value textbox for debuff rows
local debuffRowsBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
debuffRowsBox:SetSize(50, 20)
debuffRowsBox:SetPoint("LEFT", debuffRowsSlider, "RIGHT", 10, 0)
debuffRowsBox:SetAutoFocus(false)
debuffRowsBox:SetMaxLetters(2)
debuffRowsBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        value = math.max(1, math.min(10, value))
        self:SetText(tostring(value))
        debuffRowsSlider:SetValue(value)
    end
    self:ClearFocus()
end)

debuffRowsSlider:SetScript("OnValueChanged", function(self, value)
    local prof = getProfile()
    prof.debuffRows = value
    debuffRowsBox:SetText(tostring(math.floor(value)))
    ApplyAuraFixSettings()
    if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
end)

-- Create dropdowns and filter box
-- Helper to update all visuals immediately
function ForceAuraFixVisualUpdate()
    if AuraFix and AuraFix.Frame and AuraFix.UpdateAllAuras then
        AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)
    end
    if AuraFix and AuraFix.DebuffFrame and AuraFix.UpdateAllAuras then
        AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20)
    end
end

local buffGrowDD = CreateDropdown(leftColumn, "Buff Bar Growth", {"LEFT", "RIGHT"}, function() return getProfile().buffGrow end, function(v) local prof = getProfile(); prof.buffGrow = v; ApplyAuraFixSettings(); ForceAuraFixVisualUpdate() end)
buffGrowDD:SetPoint("TOPLEFT", buffRowsSlider, "BOTTOMLEFT", 0, -20)

local debuffGrowDD = CreateDropdown(rightColumn, "Debuff Bar Growth", {"LEFT", "RIGHT"}, function() return getProfile().debuffGrow end, function(v) local prof = getProfile(); prof.debuffGrow = v; ApplyAuraFixSettings(); ForceAuraFixVisualUpdate() end)
debuffGrowDD:SetPoint("TOPLEFT", debuffRowsSlider, "BOTTOMLEFT", 0, -20)

local sortDD = CreateDropdown(rightColumn, "Sort Auras By", {"INDEX", "TIME", "NAME"}, function() return getProfile().sortMethod end, function(v) local prof = getProfile(); prof.sortMethod = v; ApplyAuraFixSettings(); ForceAuraFixVisualUpdate() end)
sortDD:SetPoint("TOPLEFT", debuffGrowDD, "BOTTOMLEFT", 0, -40)

-- Create background toggle checkboxes
local buffBackgroundCheck = CreateFrame("CheckButton", nil, leftColumn, "InterfaceOptionsCheckButtonTemplate")
buffBackgroundCheck:SetPoint("TOPLEFT", sortDD, "BOTTOMLEFT", 0, -40)
buffBackgroundCheck.Text:SetText("Show Buff Background")
buffBackgroundCheck:SetChecked(AuraFixDB.showBuffBackground)
buffBackgroundCheck:SetScript("OnClick", function(self)
    local prof = getProfile()
    prof.showBuffBackground = self:GetChecked()
    ApplyAuraFixSettings()
    ForceAuraFixVisualUpdate()
end)

local debuffBackgroundCheck = CreateFrame("CheckButton", nil, rightColumn, "InterfaceOptionsCheckButtonTemplate")
debuffBackgroundCheck:SetPoint("TOPLEFT", buffBackgroundCheck, "BOTTOMLEFT", 0, -10)
debuffBackgroundCheck.Text:SetText("Show Debuff Background")
debuffBackgroundCheck:SetChecked(AuraFixDB.showDebuffBackground)
debuffBackgroundCheck:SetScript("OnClick", function(self)
    local prof = getProfile()
    prof.showDebuffBackground = self:GetChecked()
    ApplyAuraFixSettings()
    ForceAuraFixVisualUpdate()
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
panel.OnShow = function()
    local prof = getProfile()
    buffSizeSlider:SetValue(prof.buffSize or 32)
    debuffSizeSlider:SetValue(prof.debuffSize or 32)
    buffXSlider:SetValue(prof.buffX or 0)
    buffYSlider:SetValue(prof.buffY or 0)
    debuffXSlider:SetValue(prof.debuffX or 0)
    debuffYSlider:SetValue(prof.debuffY or 0)
    -- Update text boxes
    buffSizeBox:SetText(tostring(prof.buffSize or 32))
    debuffSizeBox:SetText(tostring(prof.debuffSize or 32))
    buffXBox:SetText(tostring(prof.buffX or 0))
    buffYBox:SetText(tostring(prof.buffY or 0))
    debuffXBox:SetText(tostring(prof.debuffX or 0))
    debuffYBox:SetText(tostring(prof.debuffY or 0))
    -- Update row/column settings
    buffColsSlider:SetValue(prof.buffColumns or 12)
    buffRowsSlider:SetValue(prof.buffRows or 1)
    debuffColsSlider:SetValue(prof.debuffColumns or 12)
    debuffRowsSlider:SetValue(prof.debuffRows or 1)
    buffColsBox:SetText(tostring(prof.buffColumns or 12))
    buffRowsBox:SetText(tostring(prof.buffRows or 1))
    debuffColsBox:SetText(tostring(prof.debuffColumns or 12))
    debuffRowsBox:SetText(tostring(prof.debuffRows or 1))
    -- filterBox:SetText(prof.filterText or "")
    UIDropDownMenu_SetSelectedValue(buffGrowDD, prof.buffGrow or "RIGHT")
    UIDropDownMenu_SetSelectedValue(debuffGrowDD, prof.debuffGrow or "RIGHT")
    UIDropDownMenu_SetSelectedValue(sortDD, prof.sortMethod or "INDEX")
    buffBackgroundCheck:SetChecked(prof.showBuffBackground)
    debuffBackgroundCheck:SetChecked(prof.showDebuffBackground)
    RefreshProfileDropdown()
end
panel:HookScript("OnShow", panel.OnShow)



-- Ensure ApplyAuraFixSettings is globally accessible
_G.ApplyAuraFixSettings = ApplyAuraFixSettings

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
