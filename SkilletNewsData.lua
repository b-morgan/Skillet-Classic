local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
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

local L = Skillet.L
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

Skillet.NewsName = "Skillet-Classic News"
Skillet.NewsData = {
	{	version = "1.67",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Shoppinglist", body = "Better Fix #141" },
				},
			},
		},
	},
	{	version = "1.66",
		data = {
			{	name = "New Features",
				data = {
					{ header = "News", body = "Add News with options to display Always, Once (each version change) per Account, Once (each version change) per Player, and Never" },
					{ header = "Commands", body = "Add \"/skillet news\" to open (or close) the news frame" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "Shoppinglist", body = "Fix #141" },
				},
			},
		},
	},
	{	version = "1.65",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Wago", body = "Add X-Wago-ID" },
					{ header = "Debug", body = "Add second level trace function" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "Titles", body = "Fix Classic Era Titlebars" },
					{ header = "Shoppinglist", body = "Fix #140" },
				},
			},
		},
	},
	{	version = "1.64",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Plugins", body = "Fix Initialization" },
					{ header = "Plugin", body = "DataStoreAuctions: Fix DSAPlayer initialization" },
				},
			},
		},
	},
}