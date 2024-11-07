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
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

Skillet.NewsName = "Skillet-Classic News"
Skillet.NewsData = {
	{	version = "2.03",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "EasyMenu", body = "Replace EasyMenu calls" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Queuing", body = "Add more right-click queue to top" },
				},
			},
		},
	},
	{	version = "2.02",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Recipes", body = "Add option to select top recipe" },
					{ header = "TOC", body = "Update TOC" },
				},
			},
		},
	},
	{	version = "2.01",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Wowhead URL", body = "Add to recipe right-click menu" },
				},
			{	name = "Fixes",
				data = {
					{ header = "Options", body = "Fix Skillet:ShowOptions()" },
				},
			},
			},
		},
	},
	{	version = "2.00",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
					{ header = "Packaging", body = "Change to single build" },
				},
			},
		},
	},
	{	version = "1.99",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Skill Levels", body = "Separate skill level data into two files" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "Shopping List", body = "Fix for items displaying outside of frame" },
				},
			},
		},
	},
	{	version = "1.98",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Skill Levels", body = "Remove conditionals in SkillLevel data" },
				},
			},
		},
	},
	{	version = "1.97",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Skill Level", body = "Fix for issue #184" },
				},
			},
		},
	},
	{	version = "1.96",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Display required level", body = "Fixes for issues #181, #182" },
				},
			},
		},
	},
	{	version = "1.95",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Display required level", body = "Fix for issue #180" },
				},
			},
		},
	},
	{	version = "1.94",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
				},
			},
		},
	},
	{	version = "1.93",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Combat Crafting", body = "Fix partial fix for issue #114" },
				},
			},
		},
	},
	{	version = "1.92",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Queue Processing", body = "Fix issue #176" },
					{ header = "Combat Crafting", body = "Partial fix for issue #114" },
					{ header = "Enchanting", body = "Update Enchanting Scroll data" },
				},
			},
		},
	},
	{	version = "1.91",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Skill Levels", body = "Fix issue #173" },
				},
			},
		},
	},
	{	version = "1.90",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Skill Levels", body = "Add conditional data\nFix issue #171" },
					{ header = "Automation", body = "Add right click 'Queue' selected recipes\nAdd keybinding for 'Process' button" },
				},
			},
		},
	},
	{	version = "1.89",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Enchanting", body = "Fix for issue #168" },
				},
			},
		},
	},
	{	version = "1.88",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Skill Levels", body = "Blend Wago Tools data with Wowhead data" },
				},
			},
		},
	},
	{	version = "1.87",
		data = {
			{	name = "Changes",
				data = {
					{ header = "News", body = "Update News" },
					{ header = "Skill Levels", body = "Fix error when CraftInfoAnywhere is not loaded" },
				},
			},
		},
	},
	{	version = "1.86",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TradeSkill", body = "Fix scan trade bug" },
					{ header = "TOC", body = "Add CraftInfoAnywhere optional dependency" },
					{ header = "Skill Levels", body = "Use data from Wago Tools and CraftInfoAnywhere\nto create separate tables for Classic Era and Classic Cataclysm\n" },
				},
			},
		},
	},
	{	version = "1.85",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update News" },
				},
			},
		},
	},
	{	version = "1.84",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
				},
			},
		},
	},
	{	version = "1.83",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Skill Levels", body = "Update for WotLK recipes" },
					{ header = "Slot Filter", body = "Change itemEquipLoc from INVTYPE_ROBE to INVTYPE_CHEST" },
					{ header = "TOC", body = "Update TOC" },
					{ header = "TradeSkill", body = "Better handling of scan trade errors" },
				},
			},
		},
	},
	{	version = "1.82",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
				},
			},
		},
	},
	{	version = "1.81",
		data = {
			{	name = "New Features",
				data = {
					{ header = "Links", body = "Shift-Click detail icon to send item link to chat\nAlt-Click detail icon to send actual reagents needed to chat\nCtrl-Alt-Click to send basic reagents to chat" },
					{ header = "Queuing", body = "Ignore queued reagents. Queuing recipes which share reagents will queue all of them" },
					{ header = "Shopping", body = "Ignore items on hand. The shopping list will reflect everything needed to process the queue" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Links", body = "Remove tooltip 'to link' messages if no link can be created" },
				},
			},
		},
	},
	{	version = "1.80",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
				},
			},
		},
	},
	{	version = "1.79",
		data = {
			{	name = "New Feature",
				data = {
					{ header = "Option", body = "Add chat command to display Auctionator / Journalator API results" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Plugins", body = "Adjust debugs in Auctionator plugin" },
				},
			},
		},
	},
	{	version = "1.78",
		data = {
			{	name = "New Feature",
				data = {
					{ header = "Option", body = "Add option to play a sound when the processing queue is emptied" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "ShoppingList", body = "Fix undefined function" },
				},
			},
		},
	},
	{	version = "1.77",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Localization", body = "Fix issue #153, esES leatherworking" },
				},
			},
		},
	},
	{	version = "1.76",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Compatibility", body = "More updates for 1.14.4 compatibility" },
					{ header = "Plugins", body = "Fix error when Auctionator plugin is enabled but addon is not" },
				},
			},
		},
	},
	{	version = "1.75",
		data = {
			{	name = "Changes",
				data = {
					{ header = "Compatibility", body = "Updates for 1.14.4 compatibility" },
				},
			},
		},
	},
	{	version = "1.74",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issue", body = "Fix issue #150, Merchant Buy" },
				},
			},
		},
	},
	{	version = "1.73",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issue", body = "Fix issue #149, Scrolling" },
				},
			},
		},
	},
	{	version = "1.72",
		data = {
			{	name = "Changes",
				data = {
					{ header = "TOC", body = "Update TOC" },
				},
			},
		},
	},
	{	version = "1.71",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issue", body = "Fix issue #148, Missing C_Container. in ShoppingList" },
				},
			},
			{	name = "Changes",
				data = {
					{ header = "Plugins", body = "Update Auctionator plugin to match retail\nMove Auctionator plugin button" },
				},
			},
		},
	},
	{	version = "1.70",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issue", body = "Fix issue #146, Auctionator plugin" },
				},
			},
		},
	},
	{	version = "1.69",
		data = {
			{	name = "Fixes",
				data = {
					{ header = "Issue", body = "Fix issue #145, Classic Era search" },
				},
			},
		},
	},
	{	version = "1.68",
		data = {
			{	name = "New Features",
				data = {
					{ header = "Table", body = "Add customPrice table" },
					{ header = "Commands", body = "Add \"/skillet customadd\", \"/skillet customdel\", \"/skillet customshow\", \"/skillet customclear\"," },
					{ header = "Plugins", body = "Auctionator refactor code and use customPrice table for costs" },
				},
			},
			{	name = "Fixes",
				data = {
					{ header = "Cleanup", body = "Minor code cleanup" },
				},
			},
		},
	},
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