-- Default settings for profiles
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
    buffColumns = 12,
    buffRows = 1,
    debuffColumns = 12,
    debuffRows = 1
}

local function getDefaultProfile()
    local t = {}
    for k, v in pairs(defaults) do t[k] = v end
    t.buffX = 0; t.buffY = 0; t.debuffX = 0; t.debuffY = 0
    return t
end

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


-- Use ApplyAuraFixSettings from AuraFix.lua only
AuraFix.ApplySettings = _G.ApplyAuraFixSettings

local panel

function CreateAuraFixOptionsPanel()
    if panel then return panel end
    panel = CreateFrame("Frame", "AuraFixConfigPanel", UIParent)
    panel.name = "AuraFix"

    local leftColumn = CreateFrame("Frame", nil, panel)
    leftColumn:SetPoint("TOPLEFT", 20, -20)
    leftColumn:SetSize(300, 600)

    local rightColumn = CreateFrame("Frame", nil, panel)
    rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", 40, 0)
    rightColumn:SetSize(300, 600)

    -- Dummy aura update helper (must be defined before RefreshProfileDropdown)
    function ForceAuraFixVisualUpdate()
        if AuraFix and AuraFix.Frame and AuraFix.UpdateAllAuras then
            if AuraFixDB and AuraFixDB.configMode and AuraFix.DummyBuffs then
                AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20, AuraFix.DummyBuffs)
            else
                AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)
            end
        end
        if AuraFix and AuraFix.DebuffFrame and AuraFix.UpdateAllAuras then
            if AuraFixDB and AuraFixDB.configMode and AuraFix.DummyDebuffs then
                AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20, AuraFix.DummyDebuffs)
            else
                AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20)
            end
        end
    end

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
                local name = self.editBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
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
        dd.Label:SetPoint("RIGHT", dd, "LEFT", -8, 0)
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
    local screenWidth = GetScreenWidth()
    buffXSlider:SetMinMaxValues(-math.floor(screenWidth / 2), math.floor(screenWidth / 2))
    buffXSlider:SetValueStep(1)
    buffXSlider:SetPoint("TOPLEFT", buffSizeSlider, "BOTTOMLEFT", 0, -40)
    buffXSlider:SetWidth(200)
    buffXSlider:SetValue(math.floor(AuraFixDB.buffX))
    buffXSlider.Text:SetText("Buff X Offset")
    buffXSlider.Low:SetText(-math.floor(screenWidth / 2))
    buffXSlider.High:SetText(math.floor(screenWidth / 2))
    -- Create value textbox for buff X offset
    local buffXBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    buffXBox:SetSize(50, 20)
    buffXBox:SetPoint("LEFT", buffXSlider, "RIGHT", 10, 0)
    buffXBox:SetAutoFocus(false)
    buffXBox:SetMaxLetters(4)
    buffXBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.floor(math.max(-math.floor(screenWidth / 2), math.min(math.floor(screenWidth / 2), value)))
            self:SetText(tostring(value))
            buffXSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    buffXSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        if AuraFixDB.debugMode then
            print("Buff X Offset Slider Changed: ", value)
        end
        local prof = getProfile()
        prof.buffX = value
        buffXBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    local buffYSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    local screenHeight = GetScreenHeight()
    buffYSlider:SetMinMaxValues(-math.floor(screenHeight / 2), math.floor(screenHeight / 2))
    buffYSlider:SetValueStep(1)
    buffYSlider:SetPoint("TOPLEFT", buffXSlider, "BOTTOMLEFT", 0, -40)
    buffYSlider:SetWidth(200)
    buffYSlider:SetValue(math.floor(AuraFixDB.buffY))
    buffYSlider.Text:SetText("Buff Y Offset")
    buffYSlider.Low:SetText(-math.floor(screenHeight / 2))
    buffYSlider.High:SetText(math.floor(screenHeight / 2))
    -- Create value textbox for buff Y offset
    local buffYBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    buffYBox:SetSize(50, 20)
    buffYBox:SetPoint("LEFT", buffYSlider, "RIGHT", 10, 0)
    buffYBox:SetAutoFocus(false)
    buffYBox:SetMaxLetters(4)
    buffYBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.floor(math.max(-math.floor(screenHeight / 2), math.min(math.floor(screenHeight / 2), value)))
            self:SetText(tostring(value))
            buffYSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    buffYSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        if AuraFixDB.debugMode then
            print("Buff Y Offset Slider Changed: ", value)
        end
        local prof = getProfile()
        prof.buffY = value
        buffYBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    -- Create buff columns slider
    local buffColsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    buffColsSlider:SetMinMaxValues(1, 24)
    buffColsSlider:SetValueStep(1)
    buffColsSlider:SetPoint("TOPLEFT", buffYSlider, "BOTTOMLEFT", 0, -40)
    buffColsSlider:SetWidth(200)
    buffColsSlider:SetValue(math.floor(AuraFixDB.buffColumns))
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
            value = math.floor(math.max(1, math.min(24, value)))
            self:SetText(tostring(value))
            buffColsSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    buffColsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        local prof = getProfile()
        prof.buffColumns = value
        buffColsBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    -- Create buff rows slider
    local buffRowsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    buffRowsSlider:SetMinMaxValues(1, 10)
    buffRowsSlider:SetValueStep(1)
    buffRowsSlider:SetPoint("TOPLEFT", buffColsSlider, "BOTTOMLEFT", 0, -40)
    buffRowsSlider:SetWidth(200)
    buffRowsSlider:SetValue(math.floor(AuraFixDB.buffRows))
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
            value = math.floor(math.max(1, math.min(10, value)))
            self:SetText(tostring(value))
            buffRowsSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    buffRowsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        local prof = getProfile()
        prof.buffRows = value
        buffRowsBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    -- Create explanatory label between buff and debuff sections
    -- local explanatoryLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    -- explanatoryLabel:SetPoint("TOPLEFT", buffRowsSlider, "BOTTOMLEFT", 0, -20)
    -- explanatoryLabel:SetText("Debuff position is now independent from buff position")
    local debuffXSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    local screenWidth = GetScreenWidth()
    debuffXSlider:SetMinMaxValues(-screenWidth / 2, screenWidth / 2)
    debuffXSlider:SetValueStep(1)
    debuffXSlider:SetPoint("TOPLEFT", debuffSizeSlider, "BOTTOMLEFT", 0, -40)
    debuffXSlider:SetWidth(200)
    debuffXSlider:SetValue(math.floor(AuraFixDB.debuffX))
    debuffXSlider.Text:SetText("Debuff X Offset")
    debuffXSlider.Low:SetText(-math.floor(screenWidth / 2))
    debuffXSlider.High:SetText(math.floor(screenWidth / 2))
    -- Create value textbox for debuff X offset
    local debuffXBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    debuffXBox:SetSize(50, 20)
    debuffXBox:SetPoint("LEFT", debuffXSlider, "RIGHT", 10, 0)
    debuffXBox:SetAutoFocus(false)
    debuffXBox:SetMaxLetters(4)
    debuffXBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.floor(math.max(-screenWidth / 2, math.min(screenWidth / 2, value)))
            self:SetText(tostring(value))
            debuffXSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    debuffXSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        if AuraFixDB.debugMode then
            print("Debuff X Offset Slider Changed: ", value)
        end
        local prof = getProfile()
        prof.debuffX = value
        debuffXBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    local debuffYSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    local screenHeight = GetScreenHeight()
    debuffYSlider:SetMinMaxValues(-screenHeight / 2, screenHeight / 2)
    debuffYSlider:SetValueStep(1)
    debuffYSlider:SetPoint("TOPLEFT", debuffXSlider, "BOTTOMLEFT", 0, -40)
    debuffYSlider:SetWidth(200)
    debuffYSlider:SetValue(math.floor(AuraFixDB.debuffY))
    debuffYSlider.Text:SetText("Debuff Y Offset")
    debuffYSlider.Low:SetText(-math.floor(screenHeight / 2))
    debuffYSlider.High:SetText(math.floor(screenHeight / 2))
    -- Create value textbox for debuff Y offset
    local debuffYBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    debuffYBox:SetSize(50, 20)
    debuffYBox:SetPoint("LEFT", debuffYSlider, "RIGHT", 10, 0)
    debuffYBox:SetAutoFocus(false)
    debuffYBox:SetMaxLetters(4)
    debuffYBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.floor(math.max(-screenHeight / 2, math.min(screenHeight / 2, value)))
            self:SetText(tostring(value))
            debuffYSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    debuffYSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        if AuraFixDB.debugMode then
            print("Debuff Y Offset Slider Changed: ", value)
        end
        local prof = getProfile()
        prof.debuffY = value
        debuffYBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    -- Create debuff columns slider
    local debuffColsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    debuffColsSlider:SetMinMaxValues(1, 24)
    debuffColsSlider:SetValueStep(1)
    debuffColsSlider:SetPoint("TOPLEFT", debuffYSlider, "BOTTOMLEFT", 0, -40)
    debuffColsSlider:SetWidth(200)
    debuffColsSlider:SetValue(math.floor(AuraFixDB.debuffColumns))
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
            value = math.floor(math.max(1, math.min(24, value)))
            self:SetText(tostring(value))
            debuffColsSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    debuffColsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        local prof = getProfile()
        prof.debuffColumns = value
        debuffColsBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    -- Create debuff rows slider
    local debuffRowsSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    debuffRowsSlider:SetMinMaxValues(1, 10)
    debuffRowsSlider:SetValueStep(1)
    debuffRowsSlider:SetPoint("TOPLEFT", debuffColsSlider, "BOTTOMLEFT", 0, -40)
    debuffRowsSlider:SetWidth(200)
    debuffRowsSlider:SetValue(math.floor(AuraFixDB.debuffRows))
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
            value = math.floor(math.max(1, math.min(10, value)))
            self:SetText(tostring(value))
            debuffRowsSlider:SetValue(value)
        end
        self:ClearFocus()
    end)

    debuffRowsSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        local prof = getProfile()
        prof.debuffRows = value
        debuffRowsBox:SetText(tostring(value))
        ApplyAuraFixSettings()
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
    end)

    -- Create dropdowns and filter box
    function ForceAuraFixVisualUpdate()
        if AuraFix and AuraFix.Frame and AuraFix.UpdateAllAuras then
            if AuraFixDB and AuraFixDB.configMode and AuraFix.DummyBuffs then
                AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20, AuraFix.DummyBuffs)
            else
                AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)
            end
        end
        if AuraFix and AuraFix.DebuffFrame and AuraFix.UpdateAllAuras then
            if AuraFixDB and AuraFixDB.configMode and AuraFix.DummyDebuffs then
                AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20, AuraFix.DummyDebuffs)
            else
                AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20)
            end
        end
    end

    local sortDD = CreateDropdown(rightColumn, "Sort Auras By", { "INDEX", "TIME", "NAME" },
        function() return getProfile().sortMethod end,
        function(v)
            local prof = getProfile(); prof.sortMethod = v; ApplyAuraFixSettings(); ForceAuraFixVisualUpdate()
        end)
    sortDD:SetPoint("TOPRIGHT", debuffRowsBox, "BOTTOMRIGHT", 0, -40)

    -- Config Mode Checkbox
    local configModeCheck = CreateFrame("CheckButton", nil, leftColumn, "InterfaceOptionsCheckButtonTemplate")
    configModeCheck:SetPoint("TOPLEFT", buffRowsSlider, "BOTTOMLEFT", 0, -45)
    configModeCheck.Text:SetText("Config Mode (Show Dummy Auras)")
    configModeCheck:SetChecked(AuraFixDB and AuraFixDB.configMode)

    local buffGrowDD = CreateDropdown(leftColumn, "Buff Bar Growth", { "LEFT", "RIGHT" },
        function() return getProfile().buffGrow end,
        function(v)
            local prof = getProfile(); prof.buffGrow = v; ApplyAuraFixSettings(); ForceAuraFixVisualUpdate()
        end)
    buffGrowDD:SetPoint("TOPLEFT", configModeCheck, "BOTTOMRIGHT", 70, -20)

    local debuffGrowDD = CreateDropdown(rightColumn, "Debuff Bar Growth", { "LEFT", "RIGHT" },
        function() return getProfile().debuffGrow end,
        function(v)
            local prof = getProfile(); prof.debuffGrow = v; ApplyAuraFixSettings(); ForceAuraFixVisualUpdate()
        end)
    debuffGrowDD:SetPoint("TOPRIGHT", sortDD, "BOTTOMRIGHT", 0, -20)


    -- Dummy aura generation helpers
    local function GenerateDummyAuras()
        if not AuraFix then return end
        local now = GetTime()
        -- Helper for random duration between 1 and 10 minutes
        local function randomDuration()
            return math.random(60, 600) -- seconds
        end
        -- Dummy Buffs
        AuraFix.DummyBuffs = {}
        for i = 1, 32 do
            local dur = randomDuration()
            AuraFix.DummyBuffs[i] = {
                name = "Dummy Buff " .. i,
                icon = "Interface\\AddOns\\AuraFix\\AuraFix.png",
                count = i % 5,
                duration = dur,
                expirationTime = now + math.random(0, dur), -- random time left
                debuffType = nil,
                isStealable = false,
                shouldConsolidate = false,
                spellId = 1000 + i,
            }
        end
        -- Dummy Debuffs
        AuraFix.DummyDebuffs = {}
        for i = 1, 32 do
            local dur = randomDuration()
            AuraFix.DummyDebuffs[i] = {
                name = "Dummy Debuff " .. i,
                icon = "Interface\\AddOns\\AuraFix\\AuraFix.png",
                count = i % 3,
                duration = dur,
                expirationTime = now + math.random(0, dur),
                debuffType = (i % 2 == 0) and "Magic" or "Poison",
                isStealable = false,
                shouldConsolidate = false,
                spellId = 2000 + i,
            }
        end
    end

    local function ClearDummyAuras()
        if not AuraFix then return end
        AuraFix.DummyBuffs = nil
        AuraFix.DummyDebuffs = nil
        AuraFix.ConfigDummyStartTime = nil
    end

    configModeCheck:SetScript("OnClick", function(self)
        if not AuraFixDB then return end
        AuraFixDB.configMode = self:GetChecked()
        if self:GetChecked() then
            AuraFix.ConfigDummyStartTime = GetTime()
            GenerateDummyAuras()
        else
            ClearDummyAuras()
        end
        if ForceAuraFixVisualUpdate then ForceAuraFixVisualUpdate() end
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
        local buffGrowOptions = { ["LEFT"] = true, ["RIGHT"] = true }
        local debuffGrowOptions = { ["LEFT"] = true, ["RIGHT"] = true }
        local sortOptions = { ["INDEX"] = true, ["TIME"] = true, ["NAME"] = true }
        -- Validate and fix profile values if needed
        if not buffGrowOptions[prof.buffGrow] then prof.buffGrow = "RIGHT" end
        if not debuffGrowOptions[prof.debuffGrow] then prof.debuffGrow = "RIGHT" end
        if not sortOptions[prof.sortMethod] then prof.sortMethod = "INDEX" end
        C_Timer.After(0.1, function()
            if ApplyAuraFixSettings then ApplyAuraFixSettings() end
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
            -- background options removed
            configModeCheck:SetChecked(AuraFixDB and AuraFixDB.configMode)
            if AuraFixDB and AuraFixDB.configMode then
                if type(GenerateDummyAuras) == "function" then GenerateDummyAuras() end
            else
                if type(ClearDummyAuras) == "function" then ClearDummyAuras() end
            end
            RefreshProfileDropdown()
        end)
    end

    panel:HookScript("OnShow", panel.OnShow)

    panel:HookScript("OnHide", function()
        C_Timer.After(0.1, function()
            local stillVisible = (panel:IsVisible() or (InterfaceOptionsFrame and InterfaceOptionsFrame:IsVisible()) or (Settings and SettingsPanel and SettingsPanel:IsVisible()))
            if not stillVisible and AuraFixDB and AuraFixDB.configMode then
                AuraFixDB.configMode = false
                if configModeCheck then configModeCheck:SetChecked(false) end
                if type(ClearDummyAuras) == "function" then ClearDummyAuras() end
                if type(ForceAuraFixVisualUpdate) == "function" then ForceAuraFixVisualUpdate() end
            end
        end)
    end)

    return panel
end





-- Create event frame and register relevant events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")

local panelRegistered = false

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == ADDON then
            InitializeDB()
            -- Don't apply settings yet, wait for PLAYER_ENTERING_WORLD
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        -- Now the UI is fully loaded or display changed, apply settings with correct screen size
        C_Timer.After(0.1, function()
            if not panelRegistered then
                RegisterAuraFixPanel()
                panelRegistered = true
            end
            ApplyAuraFixSettings()
        end)
    end
end)

-- Register panel

local panelCategory
function RegisterAuraFixPanel()
    if panelRegistered then return end
    -- print("[AuraFix] RegisterAuraFixPanel called")
    CreateAuraFixOptionsPanel() -- Always call to ensure panel exists
    if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
        panelCategory = Settings.RegisterCanvasLayoutCategory(panel, "AuraFix")
        Settings.RegisterAddOnCategory(panelCategory)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
    panelRegistered = true
end

-- Slash command
SLASH_AURAFIX1 = "/aurafix"
SlashCmdList["AURAFIX"] = function()
    RegisterAuraFixPanel()
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
