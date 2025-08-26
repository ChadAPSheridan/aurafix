-- AuraFix: Standalone Aura Update Optimizer
-- Extracted and adapted from ElvUI by ChadAPSheridan

local AuraFix = {}

-- Utility: Safe GetTime
local GetTime = _G.GetTime or function() return 0 end

-- Table for aura buttons
AuraFix.buttons = {}
AuraFix.debuffButtons = {}

-- Aura update logic (simplified, standalone)
function AuraFix:UpdateAura(button, index)
	local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(button.unit, index, button.filter)
	if not aura then print("AuraFix: UpdateAura no aura for", button.unit, index, button.filter) return end
	print("AuraFix: UpdateAura", aura.name, aura.icon)

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
	button:SetSize(32, 32)
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
end

local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("ADDON_LOADED")
debugFrame:SetScript("OnEvent", function(self, event, addon)
	if addon == "AuraFix" then
		AuraFix_DebugLoaded()
	end
end)

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
	button:SetSize(32, 32)

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

	return button
end

-- Main update loop: update all auras for a unit

function AuraFix:UpdateAllAuras(parent, unit, filter, maxAuras)
    local buttonTable = (filter == "HELPFUL") and self.buttons or self.debuffButtons
    local shown = 0
    for i = 1, maxAuras do
        local button = buttonTable[i] or self:CreateAuraButton(parent, unit, filter, i)
        buttonTable[i] = button
        local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
        if aura then
            print("AuraFix: Found aura", i, aura.name, aura.icon)
            self:UpdateAura(button, i)
            button:ClearAllPoints()
            button:SetParent(parent)
            button:SetPoint("LEFT", parent, "LEFT", (shown * (button:GetWidth() + 4)), 0)
            button:Show()
            shown = shown + 1
        else
            print("AuraFix: No aura at index", i)
            button:Hide()
        end
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
-- Add a visible background
local bg1 = AuraFix.Frame:CreateTexture(nil, "BACKGROUND")
bg1:SetAllPoints()
bg1:SetColorTexture(0, 0.5, 1, 0.2) -- light blue, semi-transparent

AuraFix.Frame:SetScript("OnEvent", function(self, event, ...)
    AuraFix:UpdateAllAuras(self, "player", "HELPFUL", 20)
end)
AuraFix.Frame:RegisterUnitEvent("UNIT_AURA", "player")
AuraFix:UpdateAllAuras(AuraFix.Frame, "player", "HELPFUL", 20)

-- Debuff support: create a second row for debuffs
AuraFix.DebuffFrame = CreateFrame("Frame", "AuraFixDebuffFrame", UIParent)
AuraFix.DebuffFrame:SetPoint("TOPLEFT", AuraFix.Frame, "BOTTOMLEFT", 0, -10)
AuraFix.DebuffFrame:SetSize(400, 40)
-- Add a visible background
local bg2 = AuraFix.DebuffFrame:CreateTexture(nil, "BACKGROUND")
bg2:SetAllPoints()
bg2:SetColorTexture(1, 0.2, 0.2, 0.2) -- light red, semi-transparent

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
        AuraFix.Frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", AuraFixDB.buffX + width/2, AuraFixDB.buffY + height/2)
        for i, btn in ipairs(AuraFix.buttons or {}) do
            btn:SetSize(AuraFixDB.buffSize, AuraFixDB.buffSize)
        end
    end
    if AuraFix.DebuffFrame then
        AuraFix.DebuffFrame:SetSize(AuraFixDB.debuffSize * 10, AuraFixDB.debuffSize)
        AuraFix.DebuffFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", AuraFixDB.debuffX + width/2, AuraFixDB.debuffY + height/2)
        for i, btn in ipairs(AuraFix.debuffButtons or {}) do
            btn:SetSize(AuraFixDB.debuffSize, AuraFixDB.debuffSize)
        end
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

-- Edit Mode integration for AuraFix frames
if EditModeManagerFrame and EditModeManagerFrame.RegisterSystem then
    local auraSystem = EditModeManagerFrame:CreateSystem("AuraFixFrame", AuraFix.Frame, "AuraFix Buffs")
    EditModeManagerFrame:RegisterSystem(auraSystem)
    local debuffSystem = EditModeManagerFrame:CreateSystem("AuraFixDebuffFrame", AuraFix.DebuffFrame, "AuraFix Debuffs")
    EditModeManagerFrame:RegisterSystem(debuffSystem)
end
