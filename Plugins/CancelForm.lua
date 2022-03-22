local addonName,addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
--[[
Skillet: A tradeskill window replacement.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

--
-- If the addon CancelFormForCrafting is loaded,
--
Skillet.CFFCPlugin = {}

local plugin = Skillet.CFFCPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "CancelFormForCrafting",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.CFFC.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.CFFC.enabled = value
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	--DA.DEBUG(0,"CFFC Plugin OnInitialize")
	if not Skillet.db.profile.plugins.CFFC then
		Skillet.db.profile.plugins.CFFC = {}
		Skillet.db.profile.plugins.CFFC.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

--
-- This function is called within the Skillet:UpdateTradeSkillWindow function
--
function plugin.ProcessQueue()
	DA.DEBUG(0,"CFFC Plugin ProcessQueue")
end

Skillet:RegisterProcessQueuePlugin("CFFCPlugin")		-- we have an ProcessQueue function
