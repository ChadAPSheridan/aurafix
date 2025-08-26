
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
}
AuraFixDB = AuraFixDB or {}
for k, v in pairs(defaults) do
    if AuraFixDB[k] == nil then AuraFixDB[k] = v end
end

local AuraFix = {}
_G.AuraFix = AuraFix

_G.AuraFix = AuraFix

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
	local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(button.unit, index, button.filter)
	if not aura then 
		if AuraFixDB.debugMode then
			print("AuraFix: UpdateAura no aura for", button.unit, index, button.filter)
		end
		return 
	end
	if AuraFixDB.debugMode then
		print("AuraFix: UpdateAura", aura.name, aura.icon)
	end

	local name = aura.name
	local icon = aura.icon
	local count = (aura.applications ~= nil and aura.applications) or (aura.count ~= nil and aura.count) or 0
	local debuffType = (aura.dispelName ~= nil and aura.dispelName) or (aura.debuffType ~= nil and aura.debuffType) or ""
	local duration = aura.duration
	local expiration = aura.expirationTime
	local modRate = aura.timeMod

	button.icon:SetTexture(icon or 134400) -- fallback to question mark icon if missing
	button.count:SetText(count and count > 1 and count or "")
	button.duration = duration
	button.expiration = expiration
	button.modRate = modRate or 1
	button.timeLeft = (expiration and duration and expiration - GetTime()) or 0
	
	-- Set size based on filter type
	local size = (button.filter == "HELPFUL") and AuraFixDB.buffSize or AuraFixDB.debuffSize
	button:SetSize(size, size)
	
	button.icon:Show()
	button.bg:Show()
	-- button:Show() -- handled in UpdateAllAuras
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

local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("ADDON_LOADED")
debugFrame:SetScript("OnEvent", function(self, event, addon)
	if addon == "AuraFix" then
		AuraFix_DebugLoaded()
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
			self.durationText:SetText(string.format("%.0f", self.timeLeft))
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
    button.index = index
    
    -- Set initial size based on filter type
    local size = (filter == "HELPFUL") and AuraFixDB.buffSize or AuraFixDB.debuffSize
    button:SetSize(size, size)

    -- Add a visible background to the button
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0, 0, 0, 0.4) -- semi-transparent black

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()

    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)

    button.durationText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.durationText:SetPoint("TOP", button, "BOTTOM", 0, -2)

    button:SetScript("OnUpdate", AuraFix.Button_OnUpdate)

    -- Tooltip and right-click cancel
    button:SetScript("OnEnter", function(self)
        if self.unit and self.index then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.filter == "HELPFUL" then
                GameTooltip:SetUnitBuff(self.unit, self.index)
            else
                GameTooltip:SetUnitDebuff(self.unit, self.index)
            end
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    button:SetScript("OnMouseUp", function(self, buttonName)
        if buttonName == "RightButton" and self.unit == "player" and self.index then
            if self.filter == "HELPFUL" then
                CancelUnitBuff(self.unit, self.index)
            elseif self.filter == "HARMFUL" then
                CancelUnitDebuff(self.unit, self.index)
            end
        end
    end)

    return button
end

-- Main update loop: update all auras for a unit

function AuraFix:UpdateAllAuras(parent, unit, filter, maxAuras)
    local buttonTable = (filter == "HELPFUL") and self.buttons or self.debuffButtons
    local grow = (filter == "HELPFUL") and (AuraFixDB.buffGrow or "RIGHT") or (AuraFixDB.debuffGrow or "RIGHT")
    local sortMethod = AuraFixDB.sortMethod or "INDEX"
    local filterText = (AuraFixDB.filterText or ""):lower()
    local auras = {}
    for i = 1, maxAuras do
        local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
        if aura and (filterText == "" or (aura.name and aura.name:lower():find(filterText, 1, true))) then
            table.insert(auras, {aura=aura, index=i})
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
        local button = buttonTable[i] or self:CreateAuraButton(parent, unit, filter, data.index)
        buttonTable[i] = button
        self:UpdateAura(button, data.index)
        button:ClearAllPoints()
        button:SetParent(parent)
        
        -- Set button size based on filter type
        local size = (filter == "HELPFUL") and AuraFixDB.buffSize or AuraFixDB.debuffSize
        button:SetSize(size, size)
        
        local offset = (shown * (size + 4))
        if grow == "LEFT" then
            button:SetPoint("RIGHT", parent, "RIGHT", -offset, 0)
        else
            button:SetPoint("LEFT", parent, "LEFT", offset, 0)
        end
        button:Show()
        shown = shown + 1
    end
    -- Hide unused buttons
    for i = shown + 1, #buttonTable do
        if buttonTable[i] then buttonTable[i]:Hide() end
    end
end

-- Utility to get screen size
local function GetScreenSize()
    local width = GetScreenWidth and GetScreenWidth() or 1920
    local height = GetScreenHeight and GetScreenHeight() or 1080
	print("AuraFix: Screen size", width, height)
    return width, height
end

-- Example usage: create a frame and update auras for the player
AuraFix.Frame = CreateFrame("Frame", "AuraFixFrame", UIParent)
AuraFix.Frame:SetPoint("CENTER")
AuraFix.Frame:SetSize(400, 40)
AuraFix.Frame.background = AuraFix.Frame:CreateTexture(nil, "BACKGROUND")
AuraFix.Frame.background:SetAllPoints()
AuraFix.Frame.background:SetColorTexture(0, 0.5, 1, 0.2) -- light blue, semi-transparent

AuraFix.Frame:SetScript("OnEvent", function(self, event, ...)
    AuraFix:UpdateAllAuras(self, "player", "HELPFUL", 20)
end)
AuraFix.Frame:RegisterUnitEvent("UNIT_AURA", "player")
AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)

-- Debuff support: create a second row for debuffs
AuraFix.DebuffFrame = CreateFrame("Frame", "AuraFixDebuffFrame", UIParent)
AuraFix.DebuffFrame:SetPoint("TOPLEFT", AuraFix.Frame, "BOTTOMLEFT", 0, -10)
AuraFix.DebuffFrame:SetSize(400, 40)
AuraFix.DebuffFrame.background = AuraFix.DebuffFrame:CreateTexture(nil, "BACKGROUND")
AuraFix.DebuffFrame.background:SetAllPoints()
AuraFix.DebuffFrame.background:SetColorTexture(1, 0.2, 0.2, 0.2) -- light red, semi-transparent

AuraFix.DebuffFrame:SetScript("OnEvent", function(self, event, ...)
    AuraFix:UpdateAllAuras(self, "player", "HARMFUL", 20)
end)
AuraFix.DebuffFrame:RegisterUnitEvent("UNIT_AURA", "player")
AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20)

-- Patch for AuraFix.lua:
function ApplyAuraFixSettings()
    local width, height = GetScreenSize()
    if AuraFix.Frame then
        AuraFix.Frame:SetSize(AuraFixDB.buffSize * 10, AuraFixDB.buffSize)
        local anchor = AuraFixDB.buffGrow == "LEFT" and "TOPRIGHT" or "TOPLEFT"
        AuraFix.Frame:SetPoint(anchor, UIParent, "BOTTOMLEFT", AuraFixDB.buffX + width/2, AuraFixDB.buffY + height/2)
        for i, btn in ipairs(AuraFix.buttons or {}) do
            btn:SetSize(AuraFixDB.buffSize, AuraFixDB.buffSize)
        end
    end
    if AuraFix.DebuffFrame then
        AuraFix.DebuffFrame:SetSize(AuraFixDB.debuffSize * 10, AuraFixDB.debuffSize)
        local anchor = AuraFixDB.debuffGrow == "LEFT" and "TOPRIGHT" or "TOPLEFT"
        AuraFix.DebuffFrame:SetPoint(anchor, UIParent, "BOTTOMLEFT", AuraFixDB.debuffX + width/2, AuraFixDB.debuffY + height/2)
        for i, btn in ipairs(AuraFix.debuffButtons or {}) do
            btn:SetSize(AuraFixDB.debuffSize, AuraFixDB.debuffSize)
        end
    end
    -- Force update all auras to reposition with new growth direction
    if AuraFix.UpdateAllAuras then
        AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)
        AuraFix:UpdateAllAuras(AuraFix.DebuffFrame, "player", "HARMFUL", 20)
    end
end

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


-- BlizzardEditMode modular integration
local function enterEditMode_AuraFix()
    -- Enable movement and mouse for both frames
    AuraFix.Frame:EnableMouse(true)
    AuraFix.Frame:SetMovable(true)
    AuraFix.Frame:RegisterForDrag("LeftButton")
    AuraFix.Frame:SetScript("OnDragStart", AuraFix.Frame.StartMoving)
    AuraFix.Frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        AuraFixDB.buffX = x - (GetScreenWidth()/2)
        AuraFixDB.buffY = y - (GetScreenHeight()/2)
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
        AuraFixDB.debuffX = x - (GetScreenWidth()/2)
        AuraFixDB.debuffY = y - (GetScreenHeight()/2)
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

-- Optionally, set up a DB key for the checkbox
function addon.GetDBBool(key)
    if key == "EditModeShowAuraFixUI" then
        return true -- Always show for now, or hook to your savedvars
    end
    return false
end
