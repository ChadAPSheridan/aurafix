-- Helper to get current profile (for profile-aware settings)
local function GetCurrentProfile()
    if _G.AuraFixDB and _G.AuraFixCharDB and _G.AuraFixDB.profiles and _G.AuraFixCharDB.currentProfile then
        if _G.AuraFixDB.debugMode then
            print("AuraFix: Current profile is '".._G.AuraFixCharDB.currentProfile.."'")
        end
        return _G.AuraFixDB.profiles[_G.AuraFixCharDB.currentProfile] or {}
    end
    return AuraFixDB or {}
end
-- Persistent settings DB (must be initialized before any use)
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
    filterText = "",
    debugMode = false,  -- debug mode flag
    buffColumns = 12,   -- new setting for buff columns
    buffRows = 1,       -- new setting for buff rows
    debuffColumns = 12, -- new setting for debuff columns
    debuffRows = 1      -- new setting for debuff rows
}
AuraFixDB = AuraFixDB or {}
for k, v in pairs(defaults) do
    if AuraFixDB[k] == nil then AuraFixDB[k] = v end
end


local AuraFix = {}
_G.AuraFix = AuraFix

-- DevTool integration for debugging
function AuraFix:DevInspect(data, label)
    if DevTool then
        DevTool:AddData(data, label or "AuraFix Data")
    else
        print("DevTool is not loaded.")
    end
end

-- Slash command to inspect AuraFixDB in DevTool
SLASH_AURAFIXDEV1 = "/afdev"
SlashCmdList["AURAFIXDEV"] = function()
    if AuraFix and AuraFix.DevInspect then
        AuraFix:DevInspect(AuraFixDB, "AuraFixDB")
        AuraFix:DevInspect(AuraFixCharDB, "AuraFixCharDB")
        AuraFix:DevInspect(AuraFix.profile, "Current Profile")
        AuraFix:DevInspect(AuraFixDB.profiles, "All Profiles")
        AuraFix:DevInspect(AuraFixDB.profiles[AuraFixCharDB.currentProfile], "Active Profile Settings")
    end
end

-- BlizzardEditMode integration
local addon = AuraFix

local API, L = {}, {}
addon.API = API
addon.L = L

-- Provide a Blizzard-style checkbutton for Edit Mode UI
function API.CreateBlizzardCheckButton(parent)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    function cb:SetLabel(text)
        if self.Text then self.Text:SetText(text) end
    end

    function cb:SetDBKey(key)
        self.dbKey = key
    end

    function cb:SetTooltip(func)
        self.tooltipFunc = func
        self:SetScript("OnEnter", function(self)
            if self.tooltipFunc then
                local h, d = self.tooltipFunc()
                if h then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(h, 1, 1, 1)
                    if d then GameTooltip:AddLine(d, nil, nil, nil, true) end
                    GameTooltip:Show()
                end
            end
        end)
        self:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    function cb:SetOnCheckedFunc(func)
        self:SetScript("OnClick", function(self) func(self:GetChecked()) end)
    end

    return cb
end

-- Load BlizzardEditMode.lua (assumes it's in the same folder and loaded via TOC)
-- If not, require it here or ensure it's loaded before this file.

-- Utility: Safe GetTime
local GetTime = _G.GetTime or function() return 0 end

-- Table for aura buttons
AuraFix.buttons = {}
AuraFix.debuffButtons = {}

-- Aura update logic (simplified, standalone)
function AuraFix:UpdateAura(button, index)
    local aura = button.aura or (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(button.unit, index, button.filter))
    if not aura then
        if AuraFixDB and AuraFixDB.debugMode then
            print("AuraFix: UpdateAura no aura for", button.unit, index, button.filter)
        end
        return
    end
    if AuraFixDB and AuraFixDB.debugMode then
        print("AuraFix: UpdateAura", aura.name, aura.icon)
    end

    local name = aura.name
    local icon = aura.icon
    local count = (aura and (aura.applications or aura.count)) or 0
    local debuffType = (aura and (aura.dispelName or aura.debuffType)) or ""
    local duration = aura.duration
    local expiration = aura.expirationTime
    local modRate = aura.timeMod

    button.icon:SetTexture(icon or 134400)
    button.count:SetText(count > 1 and count or "")
    button.duration = duration
    button.expiration = expiration
    button.modRate = modRate or 1
    button.timeLeft = (expiration and duration and expiration - GetTime()) or 0

    local prof = GetCurrentProfile()
    local isBuff = (button.filter == "HELPFUL")
    local size = isBuff and (prof.buffSize or 32) or (prof.debuffSize or 32)
    button:SetSize(size, size)
    button.icon:Show()
end

-- Debug: Print a message when AuraFix is loaded
local function AuraFix_DebugLoaded()
    if not AuraFix._debugPrinted then
        print("|cff00ff00AuraFix loaded and active!|r")
        AuraFix._debugPrinted = true
    end

    if AuraFixDB.debugMode then
        print("|cff00ff00AuraFix debug mode is enabled.|r")
    end
end


-- Initialization: ensure DB and profile are set up before anything else
local function AuraFix_InitializeDBAndProfile()
    if not _G.AuraFixDB then _G.AuraFixDB = {} end
    if not _G.AuraFixDB.profiles then
        _G.AuraFixDB.profiles = { ["Default"] = {} }
    end
    if not _G.AuraFixCharDB then _G.AuraFixCharDB = {} end
    if not _G.AuraFixCharDB.currentProfile then
        _G.AuraFixCharDB.currentProfile = "Default"
    end
    if not _G.AuraFixDB.profiles[_G.AuraFixCharDB.currentProfile] then
        _G.AuraFixDB.profiles[_G.AuraFixCharDB.currentProfile] = {}
    end
    -- Set active profile reference
    _G.AuraFix = _G.AuraFix or {}
    _G.AuraFix.profile = _G.AuraFixDB.profiles[_G.AuraFixCharDB.currentProfile]
end

local function AuraFix_ApplyAllSettingsAndUpdate()
    if _G.ApplyAuraFixSettings then _G.ApplyAuraFixSettings() end
    if _G.AuraFix and _G.AuraFix.UpdateAllAuras and _G.AuraFix.Frame then
        _G.AuraFix:UpdateAllAuras(_G.AuraFix.Frame, "player", "HELPFUL", 20)
    end
    if _G.AuraFix and _G.AuraFix.UpdateAllAuras and _G.AuraFix.DebuffFrame then
        _G.AuraFix:UpdateAllAuras(_G.AuraFix.DebuffFrame, "player", "HARMFUL", 20)
    end
end


local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("ADDON_LOADED")
debugFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
debugFrame:RegisterEvent("UI_SCALE_CHANGED")
debugFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
debugFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "AuraFix" then
            AuraFix_InitializeDBAndProfile()
            if _G.InitializeDB then _G.InitializeDB() end -- call config's DB init if present
            AuraFix_DebugLoaded()
            -- Don't apply settings yet, wait for PLAYER_ENTERING_WORLD
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        -- Now the UI is fully loaded or display changed, apply settings with correct screen size
        C_Timer.After(0.1, AuraFix_ApplyAllSettingsAndUpdate)
    end
end)

-- Add debug toggle command
SLASH_AURAFIXDEBUG1 = "/afdb"
SlashCmdList["AURAFIXDEBUG"] = function(msg)
    AuraFixDB.debugMode = not AuraFixDB.debugMode
    if AuraFixDB.debugMode then
        print("|cff00ff00AuraFix debug mode enabled.|r")
    else
        print("|cffff0000AuraFix debug mode disabled.|r")
    end
end

function AuraFix:Button_OnUpdate(elapsed)
    if self.expiration and self.duration and self.duration > 0 then
        self.timeLeft = (self.expiration - GetTime()) / (self.modRate or 1)
        if self.timeLeft < 0.1 then
            self:Hide()
        else
            if self.timeLeft > 60 then
                self.durationText:SetText(string.format("%dm", math.floor(self.timeLeft / 60),
                    math.floor(self.timeLeft % 60)))
            else
                self.durationText:SetText(string.format("%.0f", self.timeLeft))
            end
        end
    else
        -- Static buff: no duration, just clear the timer text
        self.durationText:SetText("")
    end
end

-- Create a simple aura button
function AuraFix:CreateAuraButton(parent, unit, filter, index)
    local button = CreateFrame("Button", nil, parent)
    button.unit = unit
    button.filter = filter
    button.auraIndex = index -- Changed to auraIndex to be more specific

    -- Set initial size based on filter type and current profile
    local prof = GetCurrentProfile()
    local size = (filter == "HELPFUL") and (prof.buffSize or 32) or (prof.debuffSize or 32)
    button:SetSize(size, size)

    -- Add a visible background to the button
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetPoint("TOPLEFT", -1, 1) -- Extend 1 pixel outward
    button.bg:SetPoint("BOTTOMRIGHT", 1, -1) -- Extend 1 pixel outward
    -- Set background color based on highlight options
    if filter == "HELPFUL" then
        button.bg:SetColorTexture(0, 0.4, 1, 0.4) -- blue highlight
    elseif filter == "HARMFUL" then
        button.bg:SetColorTexture(1, 0, 0, 0.4) -- red highlight
    else
        button.bg:SetColorTexture(0, 0, 0, 0.4) -- semi-transparent black
    end

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()

    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)

    button.durationText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.durationText:SetPoint("TOP", button, "BOTTOM", 0, 0)

    button:SetScript("OnUpdate", AuraFix.Button_OnUpdate)

    -- Tooltip and right-click cancel
    button:SetScript("OnEnter", function(self)
        if self.unit and self.auraIndex then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.filter == "HELPFUL" then
                GameTooltip:SetUnitBuff(self.unit, self.auraIndex)
            else
                GameTooltip:SetUnitDebuff(self.unit, self.auraIndex)
            end
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    button:SetScript("OnMouseUp", function(self, buttonName)
        if buttonName == "RightButton" and self.unit == "player" and self.auraIndex then
            if self.filter == "HELPFUL" then
                CancelUnitBuff(self.unit, self.auraIndex)
            elseif self.filter == "HARMFUL" then
                CancelUnitDebuff(self.unit, self.auraIndex)
            end
        end
    end)

    return button
end

-- Main update loop: update all auras for a unit

function AuraFix:UpdateAllAuras(parent, unit, filter, maxAuras, dummyAuraTable)
    local prof = GetCurrentProfile()
    local buttonTable = (filter == "HELPFUL") and self.buttons or self.debuffButtons
    local grow = (filter == "HELPFUL") and (prof.buffGrow or "RIGHT") or (prof.debuffGrow or "RIGHT")
    local sortMethod = prof.sortMethod or "INDEX"
    local filterText = (prof.filterText or ""):lower()
    local numColumns = (filter == "HELPFUL") and (prof.buffColumns or 12) or (prof.debuffColumns or 12)
    local numRows = (filter == "HELPFUL") and (prof.buffRows or 1) or (prof.debuffRows or 1)
    local size = (filter == "HELPFUL") and (prof.buffSize or 32) or (prof.debuffSize or 32)
    local auras = {}
    if dummyAuraTable then
        for i = 1, math.min(maxAuras, #dummyAuraTable) do
            local aura = dummyAuraTable[i]
            if aura and (filterText == "" or (aura.name and aura.name:lower():find(filterText, 1, true))) then
                table.insert(auras, { aura = aura, index = i })
            end
        end
    else
        for i = 1, maxAuras do
            local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and
            C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if aura and (filterText == "" or (aura.name and aura.name:lower():find(filterText, 1, true))) then
                table.insert(auras, { aura = aura, index = i })
            end
        end
    end
    -- Sorting
    if sortMethod == "TIME" then
        table.sort(auras, function(a, b)
            return (a.aura.expirationTime or 0) < (b.aura.expirationTime or 0)
        end)
    elseif sortMethod == "NAME" then
        table.sort(auras, function(a, b)
            return (a.aura.name or "") < (b.aura.name or "")
        end)
    end
    -- Place buttons
    local shown = 0
    for i, data in ipairs(auras) do
        if math.floor(shown / numColumns) >= numRows then
            break
        end
        local button = buttonTable[i] or self:CreateAuraButton(parent, unit, filter, data.index)
        buttonTable[i] = button
        button.auraIndex = data.index
        button.aura = data.aura -- Set the full aura table for dummy auras
        button:ClearAllPoints()
        button:SetParent(parent)
        self:UpdateAura(button, data.index)
        button:SetSize(size, size)
        local row = math.floor(shown / numColumns)
        local col = shown % numColumns
        local xOffset = (col * (size + 4))
        local yOffset = -((row * (size + 10)) + 4)
        if grow == "LEFT" then
            xOffset = -xOffset
            button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", xOffset, yOffset)
        else
            button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
        end
        button:Show()
        shown = shown + 1
    end

    -- Also update all visible buttons even if auras didn't change (for live settings update)
    for i = shown + 1, #buttonTable do
        if buttonTable[i] then
            self:UpdateAura(buttonTable[i], buttonTable[i].auraIndex or 1)
            buttonTable[i]:Hide()
        end
    end

    -- Update parent frame height based on actual number of rows used
    local usedRows = math.min(math.ceil(shown / numColumns), numRows)
    parent:SetHeight(usedRows * (size + 8))
    -- Hide unused buttons
    for i = shown + 1, #buttonTable do
        if buttonTable[i] then buttonTable[i]:Hide() end
    end
end

-- Utility to get screen size
local function GetScreenSize()
    local width = GetScreenWidth and GetScreenWidth() or 1920
    local height = GetScreenHeight and GetScreenHeight() or 1080
    return width, height
end
-- Apply settings from DB to frames

AuraFix.Frame = CreateFrame("Frame", "AuraFixFrame", UIParent)
AuraFix.Frame:SetPoint("CENTER")

AuraFix.DebuffFrame = CreateFrame("Frame", "AuraFixDebuffFrame", UIParent)
AuraFix.DebuffFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50) -- Default position

local function ApplyAuraFixSettings()
    local prof = GetCurrentProfile()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    -- Buff frame
    AuraFix.Frame:ClearAllPoints()
    local buffWidth = (prof.buffColumns or 12) * ((prof.buffSize or 32) + 4)
    local buffHeight = (prof.buffRows or 1) * ((prof.buffSize or 32) + 8)
    local buffAnchor, parentAnchor
    if (prof.buffGrow or "RIGHT") == "LEFT" then
        buffAnchor = "TOPRIGHT"
        parentAnchor = "TOPRIGHT"
    else
        buffAnchor = "TOPLEFT"
        parentAnchor = "TOPLEFT"
    end
    -- Position relative to screen center plus offset, but keep the correct corner fixed
    local baseX = (screenWidth / 2) + (prof.buffX or 0)
    local baseY = (screenHeight / 2) + (prof.buffY or 0)
    -- Convert center-based offset to top left/right anchor
    if buffAnchor == "TOPLEFT" then
        AuraFix.Frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", baseX, baseY)
    else
        AuraFix.Frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", baseX, baseY)
    end
    AuraFix.Frame:SetSize(buffWidth, buffHeight)
    -- Debuff frame (anchor logic matches buff frame)
    AuraFix.DebuffFrame:ClearAllPoints()
    local debuffWidth = (prof.debuffColumns or 12) * ((prof.debuffSize or 32) + 4)
    local debuffHeight = (prof.debuffRows or 1) * ((prof.debuffSize or 32) + 8)
    local debuffAnchor, debuffParentAnchor
    if (prof.debuffGrow or "RIGHT") == "LEFT" then
        debuffAnchor = "TOPRIGHT"
        debuffParentAnchor = "TOPRIGHT"
    else
        debuffAnchor = "TOPLEFT"
        debuffParentAnchor = "TOPLEFT"
    end
    local debuffBaseX = (screenWidth / 2) + (prof.debuffX or 0)
    local debuffBaseY = (screenHeight / 2) + (prof.debuffY or -50)
    if debuffAnchor == "TOPLEFT" then
        AuraFix.DebuffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", debuffBaseX, debuffBaseY)
    else
        AuraFix.DebuffFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", debuffBaseX, debuffBaseY)
    end
    AuraFix.DebuffFrame:SetSize(debuffWidth, debuffHeight)
end
_G.ApplyAuraFixSettings = ApplyAuraFixSettings
ApplyAuraFixSettings()

AuraFix.Frame:SetScript("OnEvent", function(self)
    AuraFix:UpdateAllAuras(self, "player", "HELPFUL", 20)
end)
AuraFix.Frame:RegisterUnitEvent("UNIT_AURA", "player")
AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)

AuraFix.DebuffFrame:SetScript("OnEvent", function(self)
    AuraFix:UpdateAllAuras(self, "player", "HARMFUL", 20)
end)
AuraFix.DebuffFrame:RegisterUnitEvent("UNIT_AURA", "player")
AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20)

-- Hide Blizzard's default buff and debuff frames if AuraFix is loaded
local function HideBlizzardAuras()
    if BuffFrame then
        BuffFrame:UnregisterAllEvents()
        BuffFrame:Hide()
        BuffFrame.Show = function() end
    end
    if DebuffFrame then
        DebuffFrame:UnregisterAllEvents()
        DebuffFrame:Hide()
        DebuffFrame.Show = function() end
    end
end

-- Call on load
HideBlizzardAuras()


local function enterEditMode_AuraFix()
    -- Enable movement and mouse for both frames
    AuraFix.Frame:EnableMouse(true)
    AuraFix.Frame:SetMovable(true)
    AuraFix.Frame:RegisterForDrag("LeftButton")
    AuraFix.Frame:SetScript("OnDragStart", AuraFix.Frame.StartMoving)
    AuraFix.Frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        AuraFixDB.buffX = x - (GetScreenWidth() / 2)
        AuraFixDB.buffY = y - (GetScreenHeight() / 2)
        ApplyAuraFixSettings()
    end)
    AuraFix.Frame:Show()

    AuraFix.DebuffFrame:EnableMouse(true)
    AuraFix.DebuffFrame:SetMovable(true)
    AuraFix.DebuffFrame:RegisterForDrag("LeftButton")
    AuraFix.DebuffFrame:SetScript("OnDragStart", AuraFix.DebuffFrame.StartMoving)
    AuraFix.DebuffFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        AuraFixDB.debuffX = x - (GetScreenWidth() / 2)
        AuraFixDB.debuffY = y - (GetScreenHeight() / 2)
        ApplyAuraFixSettings()
    end)
    AuraFix.DebuffFrame:Show()
end

local function exitEditMode_AuraFix()
    -- Disable movement and mouse for both frames
    AuraFix.Frame:EnableMouse(false)
    AuraFix.Frame:SetMovable(false)
    AuraFix.Frame:SetScript("OnDragStart", nil)
    AuraFix.Frame:SetScript("OnDragStop", nil)
    AuraFix.DebuffFrame:EnableMouse(false)
    AuraFix.DebuffFrame:SetMovable(false)
    AuraFix.DebuffFrame:SetScript("OnDragStart", nil)
    AuraFix.DebuffFrame:SetScript("OnDragStop", nil)
    AuraFix.Frame:Show()
    AuraFix.DebuffFrame:Show()
end

-- Register AuraFix as a module for BlizzardEditMode
if addon.AddEditModeVisibleModule then
    addon.AddEditModeVisibleModule({
        name = "AuraFix",
        dbKey = "EditModeShowAuraFixUI",
        enterEditMode = enterEditMode_AuraFix,
        exitEditMode = exitEditMode_AuraFix,
    })
end

function addon.GetDBBool(key)
    if key == "EditModeShowAuraFixUI" then
        return true -- Always show for now, or hook to your savedvars
    end
    return false
end


-- SETTINGS PANEL: Add highlight checkboxes under config mode
local function AddAuraFixSettingsPanel()
    if not Settings or not Settings.RegisterAddonCategory then return end

    local category, layout = Settings.RegisterVerticalLayoutCategory("AuraFix")

    -- Buff Highlight Checkbox
    local buffCB = Settings.CreateCheckBox(category, "Show Buff Background Highlight", function()
        return AuraFixDB.showBuffBackground or false
    end, function(checked)
        AuraFixDB.showBuffBackground = checked
        for _, btn in ipairs(AuraFix.buttons) do
            if btn.bg and btn.filter == "HELPFUL" then
                if checked then
                    btn.bg:SetColorTexture(0, 0.4, 1, 0.4)
                else
                    btn.bg:SetColorTexture(0, 0, 0, 0.4)
                end
            end
        end
    end)

    -- Debuff Highlight Checkbox
    local debuffCB = Settings.CreateCheckBox(category, "Show Debuff Background Highlight", function()
        return AuraFixDB.showDebuffBackground or false
    end, function(checked)
        AuraFixDB.showDebuffBackground = checked
        for _, btn in ipairs(AuraFix.debuffButtons) do
            if btn.bg and btn.filter == "HARMFUL" then
                if checked then
                    btn.bg:SetColorTexture(1, 0, 0, 0.4)
                else
                    btn.bg:SetColorTexture(0, 0, 0, 0.4)
                end
            end
        end
    end)

    Settings.RegisterAddonCategory(category)
end

AddAuraFixSettingsPanel()
