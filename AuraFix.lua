-- Main addon namespace initialization (first file loaded)
local ADDON, AuraFix = ...
AuraFix = AuraFix or _G[ADDON] or {}
_G[ADDON] = AuraFix

-- Local alias for faster access inside this file
local AF = AuraFix

-- Create a global debug functions
function AuraFix.Debug(msg, level)
    -- for compatibility, default level to 0 if not provided or invalid
    level = tonumber(level) or 0
    if AuraFixDB and AuraFixDB.debugMode and (AuraFixDB.debugLevel or 0) >= level then
        print("AuraFix: " .. tostring(msg))
    end
end
-- Helper to get current profile (for profile-aware settings)
local function GetCurrentProfile()
    if _G.AuraFixDB and _G.AuraFixCharDB and _G.AuraFixDB.profiles and _G.AuraFixCharDB.currentProfile then
        AF.Debug("AuraFix: Current profile is '".._G.AuraFixCharDB.currentProfile.."'", 1)
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
    debugLevel = 0,     -- debug level (0 = off, higher = more verbose)
    buffColumns = 12,   -- new setting for buff columns
    buffRows = 1,       -- new setting for buff rows
    debuffColumns = 12, -- new setting for debuff columns
    debuffRows = 1      -- new setting for debuff rows
}
AuraFixDB = AuraFixDB or {}
for k, v in pairs(defaults) do
    if AuraFixDB[k] == nil then AuraFixDB[k] = v end
end


local AuraFix = AF

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
local addon = AF

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
AF.buttons = {}
AF.debuffButtons = {}

-- Aura update logic (simplified, standalone)
function AF:UpdateAura(button, index)
    local aura = button.aura or (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(button.unit, index, button.filter))

    -- output the contents of aura for debugging
        for k, v in pairs(aura) do
            local msg = string.format("AuraFix: UpdateAura %s = %s", tostring(k), tostring(v))
            AF.Debug(msg, 3)
        end
    if not aura then
            local msg = string.format("AuraFix: UpdateAura no aura for %s, %d, %s", button.unit, index, button.filter)
            AF.Debug(msg, 3)
        return
    end
        local msg = string.format("AuraFix: UpdateAura %s = %s", aura.name, aura.icon)
        AF.Debug(msg, 3)

    local name = aura.name
    local icon = aura.icon
    local count = aura.applications or 0
    local debuffType = (aura and aura.dispelName) or ""
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
    if not AF._debugPrinted then
        print("|cff00ff00AuraFix loaded and active!|r")
        AF._debugPrinted = true
    end

    if AuraFixDB.debugMode then
        print("|cff00ff00AuraFix debug mode is enabled at level |r" .. (AuraFixDB.debugLevel or 0) .. "|cff00ff00.|r")
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
        _G.AuraFix:UpdateAllAuras(_G.AuraFix.Frame, "player", "HELPFUL")
    end
    if _G.AuraFix and _G.AuraFix.UpdateAllAuras and _G.AuraFix.DebuffFrame then
        _G.AuraFix:UpdateAllAuras(_G.AuraFix.DebuffFrame, "player", "HARMFUL")
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
    msg = (msg or ""):match("^%s*(.-)%s*$") -- trim

    local n = tonumber(msg)
    if n then
        -- numeric argument: store level and set debugMode based on zero/non-zero
        AuraFixDB.debugLevel = n
        AuraFixDB.debugMode = (n ~= 0)
        print(("|cff00ff00AuraFix debug level set to %d. Debug mode %s.|r"):format(n, AuraFixDB.debugMode and "enabled" or "disabled"))
        return
    end

    -- If msg is empty or contains anything else, set level to 0 and disable debug
    AuraFixDB.debugLevel = 0
    AuraFixDB.debugMode = false
    if msg == "" then
        print("|cffff0000AuraFix debug input empty: debug disabled and level set to 0.|r")
    else
        print(("|cffff0000Invalid debug input '%s': debug disabled and level set to 0.|r"):format(msg))
    end
end

function AF:Button_OnUpdate(elapsed)
    if self.expiration and self.duration and self.duration > 0 then
        self.timeLeft = (self.expiration - GetTime()) / (self.modRate or 1)
        if self.timeLeft < 0.1 then
            self:Hide()
        else
            if self.timeLeft >= 86400 then
            local days = math.floor(self.timeLeft / 86400)
            local hours = math.floor((self.timeLeft % 86400) / 3600)
            if hours > 0 then
                self.durationText:SetText(string.format("%dd %dh", days, hours))
            else
                self.durationText:SetText(string.format("%dd", days))
            end
            elseif self.timeLeft >= 3600 then
            local hours = math.floor(self.timeLeft / 3600)
            local mins = math.floor((self.timeLeft % 3600) / 60)
            if mins > 0 then
                self.durationText:SetText(string.format("%dh %dm", hours, mins))
            else
                self.durationText:SetText(string.format("%dh", hours))
            end
            elseif self.timeLeft > 60 then
            local mins = math.floor(self.timeLeft / 60)
            self.durationText:SetText(string.format("%dm", mins))
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
function AF:CreateAuraButton(parent, unit, filter, index)
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

    button:SetScript("OnUpdate", AF.Button_OnUpdate)

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

function AF:UpdateAllAuras(parent, unit, filter, dummyAuraTable)
    local prof = GetCurrentProfile()
    local buttonTable = (filter == "HELPFUL") and self.buttons or self.debuffButtons
    local grow = (filter == "HELPFUL") and (prof.buffGrow or "RIGHT") or (prof.debuffGrow or "RIGHT")
    local sortMethod = prof.sortMethod or "TIME"
    local filterText = (prof.filterText or ""):lower()
    local auraBlacklist = prof.auraBlacklist or {}
    -- Build a list for name substrings (lowercased) and a lookup table for spell IDs
    local nameBlacklist = {}
    local idBlacklist = {}
    for _, v in pairs(auraBlacklist) do
        if type(v) == "string" then
            table.insert(nameBlacklist, v:lower())
        elseif type(v) == "number" then
            idBlacklist[v] = true
        end
    end
    local numColumns = (filter == "HELPFUL") and (prof.buffColumns or 12) or (prof.debuffColumns or 12)
    local numRows = (filter == "HELPFUL") and (prof.buffRows or 1) or (prof.debuffRows or 1)
    local size = (filter == "HELPFUL") and (prof.buffSize or 32) or (prof.debuffSize or 32)
    local auras = {}
    local maxAuras = numColumns * numRows
    if dummyAuraTable then
        for i = 1, math.min(maxAuras, #dummyAuraTable) do
            local aura = dummyAuraTable[i]
            table.insert(auras, { aura = aura, index = i })
        end
    else
        -- First handle regular auras
        for i = 1, maxAuras do
            local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and
                C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if aura and (filterText == "" or (aura.name and aura.name:lower():find(filterText, 1, true))) then
                local isBlacklisted = false
                if aura.name then
                    local lowerName = aura.name:lower()
                    for _, substr in ipairs(nameBlacklist) do
                        if lowerName:find(substr, 1, true) then
                            isBlacklisted = true
                            break
                    end
                end
                if not isBlacklisted and aura.spellId and idBlacklist[aura.spellId] then
                    isBlacklisted = true
                end
                if not isBlacklisted then
                    table.insert(auras, { aura = aura, index = i })
                end
            end
        end
    end
        
        -- If we're looking for buffs and this is the player, check weapon enchants
        if filter == "HELPFUL" and unit == "player" then
            local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()
            
            if hasMainHandEnchant then
                local mainHandAura = {
                    name = "Weapon Enchant",
                    icon = GetInventoryItemTexture("player", 16) or 134400, -- Main hand slot
                    count = mainHandCharges or 0,
                    duration = mainHandExpiration and mainHandExpiration/1000 or 0,
                    expirationTime = mainHandExpiration and (GetTime() + mainHandExpiration/1000) or 0,
                    isWeaponEnchant = true,
                    slot = 16
                }
                table.insert(auras, { aura = mainHandAura, index = maxAuras + 1 })
            end
            
            if hasOffHandEnchant then
                local offHandAura = {
                    name = "Off-Hand Enchant",
                    icon = GetInventoryItemTexture("player", 17) or 134400, -- Off hand slot
                    count = offHandCharges or 0,
                    duration = offHandExpiration and offHandExpiration/1000 or 0,
                    expirationTime = offHandExpiration and (GetTime() + offHandExpiration/1000) or 0,
                    isWeaponEnchant = true,
                    slot = 17
                }
                table.insert(auras, { aura = offHandAura, index = maxAuras + 2 })
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

AF.Frame = CreateFrame("Frame", "AuraFixFrame", UIParent)
AF.Frame:SetPoint("CENTER")

AF.DebuffFrame = CreateFrame("Frame", "AuraFixDebuffFrame", UIParent)
AF.DebuffFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -50) -- Default position

local function ApplyAuraFixSettings()
    local prof = GetCurrentProfile()
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    -- Buff frame
    AF.Frame:ClearAllPoints()
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
        AF.Frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", baseX, baseY)
    else
        AF.Frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", baseX, baseY)
    end
    AF.Frame:SetSize(buffWidth, buffHeight)
    -- Debuff frame (anchor logic matches buff frame)
    AF.DebuffFrame:ClearAllPoints()
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
        AF.DebuffFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", debuffBaseX, debuffBaseY)
    else
        AF.DebuffFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", debuffBaseX, debuffBaseY)
    end
    AF.DebuffFrame:SetSize(debuffWidth, debuffHeight)
end
_G.ApplyAuraFixSettings = ApplyAuraFixSettings
ApplyAuraFixSettings()

AF.Frame:SetScript("OnEvent", function(self)
    AF:UpdateAllAuras(self, "player", "HELPFUL")
end)
AF.Frame:RegisterUnitEvent("UNIT_AURA", "player")
AF:UpdateAllAuras(AF.Frame, "player", "HELPFUL")

AF.DebuffFrame:SetScript("OnEvent", function(self)
    AF:UpdateAllAuras(self, "player", "HARMFUL")
end)
AF.DebuffFrame:RegisterUnitEvent("UNIT_AURA", "player")
AF:UpdateAllAuras(AF.DebuffFrame, "player", "HARMFUL")

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
    AF.Frame:EnableMouse(true)
    AF.Frame:SetMovable(true)
    AF.Frame:RegisterForDrag("LeftButton")
    AF.Frame:SetScript("OnDragStart", AF.Frame.StartMoving)
    AF.Frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        AuraFixDB.buffX = x - (GetScreenWidth() / 2)
        AuraFixDB.buffY = y - (GetScreenHeight() / 2)
        ApplyAuraFixSettings()
    end)
    AF.Frame:Show()

    AF.DebuffFrame:EnableMouse(true)
    AF.DebuffFrame:SetMovable(true)
    AF.DebuffFrame:RegisterForDrag("LeftButton")
    AF.DebuffFrame:SetScript("OnDragStart", AF.DebuffFrame.StartMoving)
    AF.DebuffFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        AuraFixDB.debuffX = x - (GetScreenWidth() / 2)
        AuraFixDB.debuffY = y - (GetScreenHeight() / 2)
        ApplyAuraFixSettings()
    end)
    AF.DebuffFrame:Show()
end

local function exitEditMode_AuraFix()
    -- Disable movement and mouse for both frames
    AF.Frame:EnableMouse(false)
    AF.Frame:SetMovable(false)
    AF.Frame:SetScript("OnDragStart", nil)
    AF.Frame:SetScript("OnDragStop", nil)
    AF.DebuffFrame:EnableMouse(false)
    AF.DebuffFrame:SetMovable(false)
    AF.DebuffFrame:SetScript("OnDragStart", nil)
    AF.DebuffFrame:SetScript("OnDragStop", nil)
    AF.Frame:Show()
    AF.DebuffFrame:Show()
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
        for _, btn in ipairs(AF.buttons) do
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
        for _, btn in ipairs(AF.debuffButtons) do
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
