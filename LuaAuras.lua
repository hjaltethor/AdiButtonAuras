--[[
LuaAuras - Enhance action buttons using Lua handlers.
Copyright 2013 Adirelle (adirelle@gmail.com)
All rights reserved.
--]]

local addonName, addon = ...

if AdiDebug then
	AdiDebug:Embed(addon, addonName)
	addon.GetName = function() return addonName end
else
	addon.Debug = function() end
end
