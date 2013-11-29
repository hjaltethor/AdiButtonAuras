--[[
AdiButtonAuras - Display auras on action buttons.
Copyright 2013 Adirelle (adirelle@gmail.com)
All rights reserved.

This file is part of AdiButtonAuras.

AdiButtonAuras is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

AdiButtonAuras is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with AdiButtonAuras.  If not, see <http://www.gnu.org/licenses/>.
--]]

local addonName, addon = ...

------------------------------------------------------------------------------
-- Button overlays for selection
------------------------------------------------------------------------------

local selectedKey, selectedName

local configParent = CreateFrame("Frame", addonName.."ConfigOverlay", UIParent)
tinsert(UISpecialFrames, configParent:GetName())
configParent:Hide()

local configOverlays = {}

local overlayPrototype = setmetatable({	Debug = addon.Debug}, { __index = CreateFrame("Button") })
local overlayMeta = { __index = overlayPrototype }

local function SpawnConfigOverlay(overlay)
	local conf = setmetatable(
		CreateFrame("Button", overlay:GetName().."Config", configParent),
		overlayMeta
	)
	conf:Initialize(overlay)
	return conf
end

configParent:SetScript('OnShow', function()
	for _, overlay in addon:IterateOverlays() do
		if not configOverlays[overlay] then
			configOverlays[overlay] = SpawnConfigOverlay(overlay)
		end
		configOverlays[overlay]:SetShown(overlay:IsVisible())
	end
end)
configParent:SetScript('OnEvent', configParent.Hide)
configParent:RegisterEvent('PLAYER_REGEN_DISABLED')

local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

function overlayPrototype:Initialize(overlay)
	self:Hide()

	self:SetFrameStrata("HIGH")

	self:SetBackdrop(backdrop)
	self:SetBackdropBorderColor(0,0,0,0)

	self:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]], "ADD")

	self.overlay = overlay
	self:SetAllPoints(overlay)
	self:RegisterForClicks('LeftButtonUp')

	self:SetScript('OnShow', self.Update)
	self:SetScript('OnClick', self.OnClick)
	self:SetScript('OnEnter', self.OnEnter)
	self:SetScript('OnLeave', self.OnLeave)

	overlay:HookScript('OnShow', function() self:Show() end)
	overlay:HookScript('OnHide', function() self:Hide() end)
end

function overlay:Update()
	self.conf, self.enabled, self.key, self.type, self.id = addon:GetActionConfiguration(self.overlay.spellId)
	if self.type == "spell" then
		self.name = GetSpellInfo(id)
	elseif self.type == "item" then
		self.name = GetItemInfo(id)
	end
	if self.conf then
		self:Enable()
		if self.enabled then
			self:SetBackdropColor(0, 1, 0, 1)
		else
			self:SetBackdropColor(0, 0, 1, 1)
		end
	else
		self:Disable()
		self:SetBackdropColor(0, 0, 0, 1)
	end
end


function overlayPrototype:OnClick()
	selectedKey, selectedName = self.key, self.name
	configParent:Hide()
end

function overlayPrototype:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddDoubleLine(self.name, self.type)
	--@debug@
	if self.conf then
		if self.enabled then
			GameTooltip:AddDoubleLine('Status', 'Enabled', nil, nil, nil, 0, 1, 0)
		else
			GameTooltip:AddDoubleLine('Status', 'Disabled', nil, nil, nil, 0, 0, 1)
		end
		local title = "Units"
		for unit in pairs(self.conf.units) do
			GameTooltip:AddDoubleLine(title, unit, nil, nil, nil, 1, 1, 1)
			title = " "
		end
		title = "Events"
		for event in pairs(self.conf.events) do
			GameTooltip:AddDoubleLine(title, event, nil, nil, nil, 1, 1, 1)
			title = " "
		end
		GameTooltip:AddDoubleLine('Handlers', #(self.conf.handlers), nil, nil, nil, 1, 1, 1)
	else
		GameTooltip:AddDoubleLine('Status', 'Unknown', nil, nil, nil, 0.5, 0.5, 0.5)
	end
	--@end-debug@
	GameTooltip:Show()
end

function overlayPrototype:OnLeave()
	if GameTooltip:GetOwner() == self then
		GameTooltip:Hide()
	end
end
------------------------------------------------------------------------------
-- Version display
------------------------------------------------------------------------------

local function ColorClass(c, ...)
	if c then
		return "|c"..RAID_CLASS_COLORS[c].colorStr..c.."|r", ColorClass(...)
	end
end

local function IdToLink(idstr, ...)
	if not idstr then return end
	local id = tonumber(strmatch(idstr, "^spell:(%d+)$"))
	if id then
		local name, _, icon = GetSpellInfo(id)
		return format("|T%s:0|t %s", icon, name), IdToLink(...)
	else
		return IdToLink(...)
	end
end

local GetVersionInfo
do
	local t = {}
	local p = function(...) tinsert(t, strjoin(" ", tostringall(...))) end
	function GetVersionInfo()
		wipe(t)

		p("\nPlease note there is no configuration options right now. This panel just is just there for debugging purpose.")

		p("\nVersion", "|cffffffff"..tostring(GetAddOnMetadata(addonName, "Version")).."|r")

		p("\nLibraries:")
		for i, lib in ipairs{"CallbackHandler-1.0", "AceTimer-3.0", "LibDispellable-1.0", "DRData-1.0", "LibSpellbook-1.0", "LibPlayerSpells-1.0" } do
			local found, minor = LibStub(lib, true)
			if found then
				p("-", lib, "|cffffffff v"..tostring(minor).."|r")
			else
				p("-", lib, "|cffff0000NOT FOUND|r")
			end
		end

		local bugGrabber
		if addon.BugGrabber then
			bugGrabber = 'Embedded BugGrabber'
			p("\nError grabber:", "|cffffffff", name, "|r")
		elseif IsAddOnLoaded("!BugGrabber") or _G.BugGrabber then
			bugGrabber = "BugGrabber"
		elseif IsAddOnLoaded("!Swatter") or _G.Swatter then
			bugGrabber = "Swatter"
		elseif IsAddOnLoaded("!ImprovedErrorFrame") then
			bugGrabber = "ImprovedErrorFrame"
		elseif GetCVarBool('scriptErrors') then
			bugGrabber = "Blizzard Lua display"
		end
		p("\nError handler:", bugGrabber and ("|cffffffff"..bugGrabber.."|r") or "|cffff0000NONE|r")

		p("\nSpecific configuration for classes: ", strjoin(", ", ColorClass(addon.getkeys(addon.knownClasses))))

		p("\nConfigured spells (spells that are both in your spellbook and", addonName, "rules:")

		p("|cffffffff", strjoin(", ", IdToLink(addon.getkeys(addon.spells))), "|r")

		return table.concat(t, "\n")
	end
end

------------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------------

local options
local function GetOptions()
	if options then return options end

	options = {
		--@debug@
		name = addonName..' DEV',
		--@end-debug@
		--[===[@non-debug@
		name = addonName..' @project-version@',
		--@end-non-debug@]===]
		type = 'group',
		handler = handler,
		get = 'Get',
		set =' Set',
		childGroups = 'tab',
		args = {
			global = {
				name = 'Global',
				type = 'group',
				order = 10,
				args = {
				},
			},
			spells = {
				name = 'Spells',
				type = 'group',
				order = 20,
				args = {
					select = {
						name = function()
							return configParent:IsShown() and "Cancel" or "Select a button"
						end,
						order = 10,
						type = 'execute',
						width = "double",
						func = function()
							selectedKey, selectedName = nil, nil
							configParent:SetShown(not configParent:IsShown())
						end,
					},
					selected = {
						name = function() return selectedName end,
						type = 'group',
						order = 20,
						inline = true,
						hidden = function() return not selectedKey end,
						args = {
							enabled = {
								name = 'Enabled',
								desc = 'Uncheck to ignore this spell/item.',
								type = 'toggle',
								get = function()
									return addon.db.profile.enabled[selectedKey]
								end,
								set = function(_, flag)
									addon.db.profile.enabled[selectedKey] = flag
									addon:SendMessage(addon.CONFIG_CHANGED)
								end
							},
						},
					},
				},
			},
			debug = {
				name = 'Debug information',
				type = 'group',
				order = -1,
				args = {
					_text = {
						name = GetVersionInfo,
						type = "description",
						width = 'full',
					},
				},
			},
		},
	}

	return options
end

------------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------------

LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, GetOptions)
local blizPanel = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(addonName, addonName)

function addon:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(blizPanel)
end
