local addonName,addonTable = ...
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

Skillet = LibStub("AceAddon-3.0"):NewAddon("Skillet", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Pull it into the local namespace, it's faster to access that way
local Skillet = Skillet
local DA = Skillet -- needed because LibStub changed the definition of Skillet

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")
Skillet.L = L

-- Get version info from the .toc file
local MAJOR_VERSION = GetAddOnMetadata("Skillet-Classic", "Version");
local ADDON_BUILD = ((select(4, GetBuildInfo())) < 20000 and "Classic") or ((select(4, GetBuildInfo())) < 30000 and "BCC") or ((select(4, GetBuildInfo())) < 40000 and "Wrath") or "Retail"
Skillet.version = MAJOR_VERSION
Skillet.build = ADDON_BUILD
Skillet.project = WOW_PROJECT_ID
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

Skillet.isCraft = false			-- true for the Blizzard Craft UI, false for the Blizzard TradeSkill UI
Skillet.lastCraft = false		-- help events know when to call ConfigureRecipeControls()
Skillet.ignoreClose = false		-- when switching from the Craft UI to the TradeSkill UI, ignore the other's close.
Skillet.gttScale = GameTooltip:GetScale()

Skillet.tradeUpdate = 0
Skillet.craftUpdate = 0

local nonLinkingTrade = { [2656] = true, [53428] = true }				-- smelting, runeforging

local defaults = {
	profile = {
--
-- user configurable options
--
		vendor_buy_button = true,
		vendor_auto_buy   = false,
		show_item_notes_tooltip = false,
		show_detailed_recipe_tooltip = true,			-- show any tooltips?
		display_full_tooltip = true,					-- show full blizzards tooltip
		display_item_tooltip = true,					-- show item tooltip or recipe tooltip
		link_craftable_reagents = true,
		queue_craftable_reagents = true,
		queue_tools = false,
		ignore_banked_reagents = false,
		queue_glyph_reagents = false,					-- not in Classic
		display_required_level = false,
		display_item_level = false,
		display_shopping_list_at_bank = true,
		display_shopping_list_at_auction = true,
		display_shopping_list_at_merchant = true,
		display_shopping_list_at_guildbank = false,		-- not in Classic
		use_guildbank_as_alt = false,					-- not in Classic
		use_bank_as_alt = false,
		use_blizzard_for_followers = false,				-- not in Classic
		hide_blizzard_frame = true,						-- primarily for debugging
		support_crafting = true,
		ignore_change = false,							-- not in Classic
		queue_crafts = false,
		include_craftbuttons = true,
		enchant_scrolls = false,
		use_higher_vellum = false,
		include_tradebuttons = true,
		search_includes_reagents = true,
		interrupt_clears_queue = false,
		clamp_to_screen = true,
		scale_tooltip = false,
		transparency = 1.0,
		scale = 1.0,
		ttscale = 1.0,
		plugins = {},
		SavedQueues = {},
		include_alts = true,	-- Display alt's items in shopping list
		same_faction = true,	-- Display same faction alt items only
		item_order =  false,	-- Order shopping list by item
		merge_items = false,	-- Merge same shopping list items together
		include_guild = false,	-- Use the contents of the Guild Bank
	},
	realm = {
--
-- notes added to items crafted or used in crafting
--
		notes = {},
	},
}

--
-- default options for each player/tradeskill
--
Skillet.defaultOptions = {
	["sortmethod"] = "None",
	["grouping"] = "Blizzard",
	["searchtext"] = "",
	["filterInventory-bag"] = true,
	["filterInventory-crafted"] = true,
	["filterInventory-vendor"] = true,
	["filterInventory-alts"] = false,
	["filterInventory-owned"] = true,
	["filterLevel"] = 1,
	["hideuncraftable"] = false,
}

Skillet.unknownRecipe = {
	tradeID = 0,
	name = "unknown",
	tools = {},
	reagentData = {},
	cooldown = 0,
	itemID = 0,
	numMade = 0,
	spellID = 0,
	numCraftable = 0,
	numCraftableVendor = 0,
	numCraftableAlts = 0,
}

function Skillet:DisableBlizzardFrame()
	DA.DEBUG(0,"DisableBlizzardFrame()")
	if self.BlizzardTradeSkillFrame == nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end
		self.BlizzardTradeSkillFrame = TradeSkillFrame
		self.tradeSkillHide = TradeSkillFrame:GetScript("OnHide")
		TradeSkillFrame:SetScript("OnHide", nil)
		HideUIPanel(TradeSkillFrame)
	end
	if self.BlizzardCraftFrame == nil then
		if (not IsAddOnLoaded("Blizzard_CraftUI")) then
			LoadAddOn("Blizzard_CraftUI");
		end
		self.BlizzardCraftFrame = CraftFrame
		self.craftHide = CraftFrame:GetScript("OnHide")
		CraftFrame:SetScript("OnHide", nil)
		HideUIPanel(CraftFrame)
	end
end

function Skillet:EnableBlizzardFrame()
	DA.DEBUG(0,"EnableBlizzardFrame()")
	if self.BlizzardTradeSkillFrame ~= nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end
		self.BlizzardTradeSkillFrame = nil
		TradeSkillFrame:SetScript("OnHide", Skillet.tradeSkillHide)
		Skillet.tradeSkillHide = nil
		ShowUIPanel(TradeSkillFrame)
	end
	if self.BlizzardCraftFrame ~= nil then
		if (not IsAddOnLoaded("Blizzard_CraftUI")) then
			LoadAddOn("Blizzard_CraftUI");
		end
		self.BlizzardCraftFrame = nil
		CraftFrame:SetScript("OnHide", Skillet.craftHide)
		self.craftHide = nil
		self:RestoreEnchantButton(true)
		ShowUIPanel(CraftFrame)
	end
end

--
-- Called with events that should have an existing profile.
--
function Skillet:RefreshConfig(event, database, profile)
	DA.MARK3("RefreshConfig("..tostring(event)..", "..tostring(profile)..")")
end

--
-- Called with events that need the profile created.
--
function Skillet:InitializeProfile(event, database, profile)
	DA.MARK3("InitializeProfile("..tostring(event)..", "..tostring(profile)..")")
	self:ConfigureProfile()
	self:ConfigurePlayerProfile()
end

--
-- Called from events related to profile manipulation and new characters
--
function Skillet:ConfigureProfile()
	if Skillet.db.profile.WarnLog == nil then
		Skillet.db.profile.WarnLog = true
	end
	Skillet.WarnLog = Skillet.db.profile.WarnLog
	Skillet.WarnShow = Skillet.db.profile.WarnShow
	Skillet.DebugShow = Skillet.db.profile.DebugShow
	Skillet.DebugLogging = Skillet.db.profile.DebugLogging
	Skillet.DebugLevel = Skillet.db.profile.DebugLevel
	Skillet.LogLevel = Skillet.db.profile.LogLevel
	Skillet.MAXDEBUG = Skillet.db.profile.MAXDEBUG or 4000
	Skillet.MAXPROFILE = Skillet.db.profile.MAXPROFILE or 2000
	Skillet.TableDump = Skillet.db.profile.TableDump
	Skillet.TraceShow = Skillet.db.profile.TraceShow
	Skillet.TraceLog = Skillet.db.profile.TraceLog
	Skillet.TraceLog2 = Skillet.db.profile.TraceLog2
	Skillet.ProfileShow = Skillet.db.profile.ProfileShow
--
-- Profile variable to control Skillet fixes for Blizzard bugs.
-- Can be toggled [or turned off] with "/skillet fixbugs [off]"
--
	if Skillet.db.profile.FixBugs == nil then
		Skillet.db.profile.FixBugs = true
	end
	Skillet.FixBugs = Skillet.db.profile.FixBugs
end

--
-- Called from events related to profile manipulation and new characters
--
function Skillet:ConfigurePlayerProfile()
	if not self.db.profile.groupDB then
		self.db.profile.groupDB = {}
	end
	if not self.db.profile.groupSN then
		self.db.profile.groupSN = {}
	end
	if not self.db.profile.SavedQueues then
		self.db.profile.SavedQueues = {}
	end
	if not self.db.profile.plugins then
		self.db.profile.plugins = {}
		self:InitializePlugins()
	end
end

--
-- Called when the addon is loaded
--
function Skillet:OnInitialize()
	if not SkilletWho then
		SkilletWho = {}
	end
	if not SkilletDBPC then
		SkilletDBPC = {}
	end
	if not SkilletProfile then
		SkilletProfile = {}
	end
	if not SkilletMemory then
		SkilletMemory = {}
	end
	if DA.deepcopy then			-- For serious debugging, start with a clean slate
		SkilletMemory = {}
		SkilletDBPC = {}
	end
	DA.DebugLog = SkilletDBPC
	DA.DebugProfile = SkilletProfile
	self.db = AceDB:New("SkilletDB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "InitializeProfile")
	self.db.RegisterCallback(self, "OnNewProfile", "InitializeProfile")
	self.db.RegisterCallback(self, "OnProfileDeleted", "RefreshConfig")
--
-- Clean up obsolete data
--
	if self.db.global.cachedGuildbank then
		self.db.global.cachedGuildbank = nil
	end

--
-- Change the dataVersion when (major) code changes
-- obsolete the current saved variables database.
--
-- Change the customVersion when code changes obsolete 
-- the custom group specific saved variables data.
--
-- Change the queueVersion when code changes obsolete 
-- the queue specific saved variables data.
--
-- Change the recipeVersion when code changes obsolete 
-- the recipe specific saved variables data.
--
-- When Blizzard releases a new build, there's a chance that
-- recipes have changed (i.e. different reagent requirements) so
-- we clear the saved variables recipe data just to be safe.
--
	local dataVersion = 5
	local queueVersion = 1
	local customVersion = 1
	local recipeVersion = 4
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	self.wowBuild = wowBuild
	self.wowVersion = wowVersion
	if not self.db.global.dataVersion or self.db.global.dataVersion ~= dataVersion then
		self.db.global.dataVersion = dataVersion
		self:FlushAllData()
	elseif not self.db.global.customVersion or self.db.global.customVersion ~= customVersion then
		self.db.global.customVersion = customVersion
		self:FlushCustomData()
	elseif not self.db.global.queueVersion or self.db.global.queueVersion ~= queueVersion then
		self.db.global.queueVersion = queueVersion
		self:FlushQueueData()
	elseif not self.db.global.recipeVersion or self.db.global.recipeVersion ~= recipeVersion then
		self.db.global.recipeVersion = recipeVersion
		self:FlushRecipeData()
	elseif not self.db.global.wowBuild or self.db.global.wowBuild ~= self.wowBuild then
		self.db.global.wowBuild = self.wowBuild
		self.db.global.wowVersion = self.wowVersion -- actually TOC version
		self:FlushRecipeData()
	end

--
-- Information useful for debugging
--
	self.db.global.locale = GetLocale()
	self.db.global.version = self.version
	self.db.global.build = self.build
	self.db.global.project = self.project

--
-- Initialize global data
--
	if not self.db.global.recipeDB then
		self.db.global.recipeDB = {}
	end
	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end
	if not self.db.global.itemRecipeUsedIn then
		self.db.global.itemRecipeUsedIn = {}
	end
	if not self.db.global.MissingVendorItems then
		self:InitializeMissingVendorItems()
	end
	if not self.db.global.MissingSkillLevels then
		self.db.global.MissingSkillLevels = {}
	end
	if not self.db.global.SkillLevels then
		self:InitializeSkillLevels()
	end
	if not self.db.global.cachedGuildbank then
		self.db.global.cachedGuildbank = {}
	end

--
-- Hook default tooltips
--
	local tooltipsToHook = { ItemRefTooltip, GameTooltip, ShoppingTooltip1, ShoppingTooltip2 };
	for _, tooltip in pairs(tooltipsToHook) do
		if tooltip then
			tooltip:HookScript("OnTooltipSetItem", function(tooltip)
				Skillet:AddItemNotesToTooltip(tooltip)
			end)
		end
	end
--
-- configure the addon options and the slash command handler
-- (Skillet.options is defined in SkilletOptions.lua)
--
	Skillet:ConfigureOptions()
--
-- Copy the profile debugging variables to the global table 
-- where DebugAids.lua is looking for them.
--
-- Warning:	Setting TableDump can be a performance hog, use caution.
--			Setting DebugLogging (without DebugShow) is a minor performance hit.
--			WarnLog (with or without WarnShow) can remain on as warning messages are rare.
--
-- Note:	Undefined is the same as false so we only need to predefine true variables
--
	Skillet:ConfigureProfile()
--
-- Create a static popup for changing professions
--
StaticPopupDialogs["SKILLET_CONTINUE_CHANGE"] = {
	text = "Skillet-Classic\n"..L["Press Okay to continue changing professions"],
	button1 = OKAY,
	OnAccept = function( self )
		Skillet:ContinueChange()
		return
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

--
-- Create a static popup for changing professions
--
StaticPopupDialogs["SKILLET_IGNORE_CHANGE"] = {
	text = "Skillet-Classic\n"..L["Use Action Bar button to change professions"],
	button1 = OKAY,
	OnAccept = function( self )
		return
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

--
-- Now do the character initialization
--
	self:InitializeDatabase(UnitName("player"))
	self:InitializePlugins()
end

--
-- These functions reset parts of the database primarily
-- when code changes obsolete the current database.
--
-- FlushAllData covers everything and (hopefully) is
-- rarely used. There is a dataVersion number to
-- increment to trigger a call.
--
function Skillet:FlushAllData()
	DA.DEBUG(0,"FlushAllData()");
	Skillet.data = {}
	Skillet.db.realm.tradeSkills = {}
	Skillet.db.realm.auctionData = {}
	Skillet.db.realm.inventoryData = {}
	Skillet.db.realm.bagData = {}
	Skillet.db.realm.bagDetails = {}
	Skillet.db.realm.bankData = {}
	Skillet.db.realm.bankDetails = {}
	Skillet.db.realm.userIgnoredMats = {}
	Skillet:FlushCustomData()
	Skillet:FlushQueueData()
	Skillet:FlushRecipeData()
end

--
-- Custom Groups data could represent significant
-- effort by the player so don't clear it without
-- good cause.
--
function Skillet:FlushCustomData()
	DA.DEBUG(0,"FlushCustomData()");
	Skillet.db.profile.groupDB = {}
	Skillet.db.profile.groupSN = {}
end

--
-- Saved queues are in the profile so
-- clearing these tables is just the current
-- queue and should have minimal impact.
--
function Skillet:FlushQueueData()
	DA.DEBUG(0,"FlushQueueData()");
	Skillet.db.realm.queueData = {}
	Skillet.db.realm.reagentsInQueue = {}
end

--
-- Recipe data is constantly getting rebuilt so
-- clearing it should have minimal (if any) impact.
-- Blizzard's "stealth" changes to recipes are the
-- primary reason this function exists.
--
function Skillet:FlushRecipeData()
	DA.DEBUG(0,"FlushRecipeData()");
	Skillet.db.global.recipeDB = {}
	Skillet.db.global.itemRecipeUsedIn = {}
	Skillet.db.global.itemRecipeSource = {}
	Skillet.db.realm.skillDB = {}
	Skillet.db.realm.subClass = {}
	Skillet.db.realm.invSlot = {}
end

--
-- MissingVendorItem entries can be a string when bought with gold
-- or a table when bought with an alternate currency
-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
--
-- Note: Classic doesn't have any alternate currencies yet.
--
function Skillet:InitializeMissingVendorItems()
	self.db.global.MissingVendorItems = {
		[30817] = "Simple Flour",
		[4539]  = "Goldenbark Apple",
		[17035] = "Stranglethorn Seed",
		[17034] = "Maple Seed",
		[4399]	= "Wooden Stock",
		[3857]	= "Coal",
		[52188] = "Jeweler's Setting",
	}
end

function Skillet:InitializeDatabase(player, clean)
	if clean then action = "Clean" else action = "Initialize" end
	DA.DEBUG(0,action.." database for "..tostring(player))
	if self.linkedSkill or self.isGuild then  -- Avoid adding unnecessary data to savedvariables
		return
	end
	if player then
--
-- Session data
--
		if not self.data then
			self.data = {}
		end
		if not self.data.recipeList then
			self.data.recipeList = {}
		end
		if not self.data.skillList then
			self.data.skillList = {}
		end
		if not self.data.skillList[player] or clean then
			self.data.skillList[player] = {}
		end
		if not self.data.groupList then
			self.data.groupList = {}
		end
		if not self.data.groupList[player] or clean then
			self.data.groupList[player] = {}
		end
		if not self.data.skillIndexLookup then
			self.data.skillIndexLookup = {}
		end
		if not self.data.skillIndexLookup[player] or clean then
			self.data.skillIndexLookup[player] = {}
		end
--
-- Realm data
--
		if not self.db.realm.skillDB then
			self.db.realm.skillDB = {}
		end
		if not self.db.realm.skillDB[player] or clean then
			self.db.realm.skillDB[player] = {}
		end
		if not self.db.realm.subClass then
			self.db.realm.subClass = {}
		end
		if not self.db.realm.subClass[player] or clean then
			self.db.realm.subClass[player] = {}
		end
		if not self.db.realm.invSlot then
			self.db.realm.invSlot = {}
		end
		if not self.db.realm.invSlot[player] or clean then
			self.db.realm.invSlot[player] = {}
		end
		if not self.db.realm.tradeSkills then
			self.db.realm.tradeSkills = {}
		end
		if not self.db.realm.tradeSkills[player] or clean then
			self.db.realm.tradeSkills[player] = {}
		end
		if not self.db.realm.queueData then
			self.db.realm.queueData = {}
		end
		if not self.db.realm.queueData[player] or clean then
			self.db.realm.queueData[player] = {}
		end
		if not self.db.realm.auctionData then
			self.db.realm.auctionData = {}
		end
		if not self.db.realm.auctionData[player] or clean then
			self.db.realm.auctionData[player] = {}
		end
		if not self.db.realm.trade_wait then
			self.db.realm.trade_wait = 1	-- variable to control how many TRADE_SKILL_UPDATE events to ignore
		end
		if not self.db.realm.craft_wait then
			self.db.realm.craft_wait = 1	-- variable to control how many CRAFT_UPDATE events to ignore
		end
		if not self.db.realm.faction then
			self.db.realm.faction = {}
		end
		if not self.db.realm.race then
			self.db.realm.race = {}
		end
		if not self.db.realm.class then
			self.db.realm.class = {}
		end
		if not self.db.realm.guid then
			self.db.realm.guid = {}
		end
		if not self.db.global.faction then
			self.db.global.faction = {}
		end
		if not self.db.global.server then
			self.db.global.server = {}
		end
		if player == UnitName("player") then
			if not self.db.realm.inventoryData then
				self.db.realm.inventoryData = {}
			end
			if not self.db.realm.inventoryData[player] or clean then
				self.db.realm.inventoryData[player] = {}
			end
--
-- For debugging, having the contents of bags could be useful.
--
			if not self.db.realm.bagData then
				self.db.realm.bagData = {}
			end
			if not self.db.realm.bagData[player] or clean then
				self.db.realm.bagData[player] = {}
			end
			if not self.db.realm.bagDetails then
				self.db.realm.bagDetails = {}
			end
			if not self.db.realm.bagDetails[player] or clean then
				self.db.realm.bagDetails[player] = {}
			end
--
-- In Classic, you can't craft from the bank but
-- for debugging, having the contents of the bank could be useful.
--
			if not self.db.realm.bankData then
				self.db.realm.bankData = {}
			end
			if not self.db.realm.bankData[player] or clean then
				self.db.realm.bankData[player] = {}
			end
			if not self.db.realm.bankDetails then
				self.db.realm.bankDetails = {}
			end
			if not self.db.realm.bankDetails[player] or clean then
				self.db.realm.bankDetails[player] = {}
			end
--
			if not self.db.realm.reagentsInQueue then
				self.db.realm.reagentsInQueue = {}
			end
			if not self.db.realm.reagentsInQueue[player] or clean then
				self.db.realm.reagentsInQueue[player] = {}
			end
			if not self.db.realm.userIgnoredMats then
				self.db.realm.userIgnoredMats = {}
			end
			if not self.db.realm.userIgnoredMats[player] or clean then
				self.db.realm.userIgnoredMats[player] = {}
			end
--
-- Profile data
--
			Skillet:ConfigurePlayerProfile()
		end
	end
end

function Skillet:RegisterRecipeFilter(name, namespace, initMethod, filterMethod)
	if not self.recipeFilters then
		self.recipeFilters = {}
	end
	--DA.DEBUG(0,"add recipe filter "..name)
	self.recipeFilters[name] = { namespace = namespace, initMethod = initMethod, filterMethod = filterMethod }
end

-- Called when the addon is enabled
function Skillet:OnEnable()
	DA.DEBUG(0,"OnEnable()");
--
-- Hook into the events that we care about
--
-- Trade skill window changes
--
	self:RegisterEvent("TRADE_SKILL_CLOSE")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_UPDATE")
	self:RegisterEvent("TRADE_SKILL_NAME_UPDATE")
	if not TSM_API then
		self:RegisterEvent("CRAFT_CLOSE")			-- craft event (could call SkilletClose)
		self:RegisterEvent("CRAFT_SHOW")			-- craft event (could call SkilletShow)
		self:RegisterEvent("CRAFT_UPDATE")			-- craft event
		self:RegisterEvent("UNIT_PET_TRAINING_POINTS")	-- craft event
	end
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")		-- Not sure if this is helpful but we will track it.
	self:RegisterEvent("SPELLS_CHANGED")			-- Not sure if this is helpful but we will track it.
--	self:RegisterEvent("BAG_OPEN")					-- Not sure if this is helpful but we will track it.
--	self:RegisterEvent("BAG_CLOSED")				-- Not sure if this is helpful but we will track it.
--	self:RegisterEvent("BAG_CONTAINER_UPDATE")		-- Not sure if this is helpful but we will track it.

	self:RegisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
	self:RegisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
--
-- Events that replace *_SHOW and *_CLOSED by adding a PlayerInteractionType parameter
--
--	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
--	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
--
-- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
--
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_UPDATE")
	self:RegisterEvent("MERCHANT_CLOSED")
--
-- To show a shopping list when at the bank/guildbank/auction house
--
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("BANKFRAME_CLOSED")

	if not isClassic then
		self:RegisterEvent("GUILDBANKFRAME_OPENED")
		self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
		self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	end

	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
--
-- Events needed to process the queue and to update
-- the tradeskill window to update the number of items
-- that can be crafted as we consume reagents.
--
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
--
-- Not sure these are needed for crafting but they
-- are useful for debugging.
--
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("UI_INFO_MESSAGE")
--	self:RegisterEvent("GET_ITEM_INFO_RECEIVED");
--
-- more useful for debugging (for now)
--
	self:RegisterEvent("TRADE_SHOW");
	self:RegisterEvent("TRADE_CLOSED")
	self:RegisterEvent("TRADE_MONEY_CHANGED")
	self:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
	self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
	self:RegisterEvent("TRADE_REPLACE_ENCHANT")
	self:RegisterEvent("TRADE_POTENTIAL_BIND_ENCHANT");
	self:RegisterEvent("TRADE_REQUEST")
	self:RegisterEvent("TRADE_REQUEST_CANCEL")
	self:RegisterEvent("TRADE_UPDATE");
	self:RegisterEvent("TRADE_ACCEPT_UPDATE")

--
-- Debugging cleanup if enabled
--
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("NEW_RECIPE_LEARNED") -- arg1 = recipeID
	self:RegisterEvent("SKILL_LINES_CHANGED") -- replacement for CHAT_MSG_SKILL?
	self:RegisterEvent("LEARNED_SPELL_IN_TAB") -- arg1 = professionID

	self:RegisterEvent("ADDON_ACTION_BLOCKED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self.bagsChanged = true
	self.hideUncraftableRecipes = false
	self.hideTrivialRecipes = false
	self.currentTrade = nil
	self.selectedSkill = nil
	self.currentPlayer = UnitName("player")
	self.currentGroupLabel = "Blizzard"
	self.currentGroup = nil
	self.skippedQueue = {}
	self:UpgradeDataAndOptions()		-- run the upgrade code to convert any old settings
	self:ConvertIgnoreListData()
	self:CollectTradeSkillData()
	self:CollectCurrencyData()
	self:ScanPlayerTradeSkills()
	self:CreateAdditionalButtonsList()
	self:EnablePlugins()
	self:DisableBlizzardFrame()
end

function Skillet:PLAYER_LOGIN()
	DA.TRACE("PLAYER_LOGIN")
	Skillet.loginTime = GetTime()
end

function Skillet:PLAYER_ENTERING_WORLD()
	DA.TRACE("PLAYER_ENTERING_WORLD")
	local player = UnitName("player")
	local realm = GetRealmName()
	local faction = UnitFactionGroup("player")
	local raceName, raceFile, raceID = UnitRace("player")
	local className, classFile, classId = UnitClass("player")
	local locale = GetLocale()
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	local guid = UnitGUID("player")		-- example: guid="Player-970-0002FD64" kind=="Player" server=="970" ID="0002FD64" 
--
-- PLAYER_ENTERING_WORLD happens on login and when changing zones so
-- only save the time of the first one.
--
	if not Skillet.loginTime then
		Skillet.loginTime = GetTime()
	end
--
-- Store some identifying data in the per character saved variables file
--
	SkilletWho.player = player
	SkilletWho.realm = realm
	SkilletWho.faction = faction
	SkilletWho.raceFile = raceFile
	SkilletWho.classFile = classFile
	self.db.realm.faction[player] = faction
	self.db.realm.race[player] = raceFile
	self.db.realm.class[player] = classFile
	SkilletWho.locale = locale
	SkilletWho.wowBuild = wowBuild
	SkilletWho.wowVersion = wowVersion
	SkilletWho.guid = guid
	SkilletWho.version = Skillet.version
	if guid then
		local kind, server, ID = strsplit("-", guid)
		DA.DEBUG(1,"player="..tostring(player)..", faction="..tostring(faction)..", guid="..tostring(guid)..", server="..tostring(server))
--
-- If we support data sharing across connected realms, then
-- Skillet.db.realm.* data needs to move to 
-- Skillet.db.global.* data indexed by server.
--
		self.db.realm.guid[player]= guid
		if (server) then
			self.data.server = server
			self.data.realm = realm
			if not self.db.global.server[server] then
				self.db.global.server[server] = {}
			end
			self.db.global.server[server][realm] = player
			if not self.db.global.faction[server] then
				self.db.global.faction[server] = {}
			end
			self.db.global.faction[server][player] = faction
		end
	end
end

--
-- Skillet-Classic doesn't do well in combat. These functions need to be
-- flushed out to deal with it gracefully.
--
function Skillet:ADDON_ACTION_BLOCKED()
	DA.TRACE("ADDON_ACTION_BLOCKED()")
--	print("|cf0f00000Skillet-Classic|r: Combat lockdown restriction." ..
--								  " Leave combat and try again.")
--	self:HideAllWindows()
end

function Skillet:PLAYER_REGEN_DISABLED()
	DA.TRACE("PLAYER_REGEN_DISABLED()")
--	print("|cf0f00000Skillet-Classic|r: Combat lockdown restriction." ..
--								  " Leave combat and try again.")
--	self:HideAllWindows()
end

function Skillet:PLAYER_REGEN_ENABLED()
	DA.TRACE("PLAYER_REGEN_ENABLED()")
end

function Skillet:PLAYER_LOGOUT()
	DA.TRACE("PLAYER_LOGOUT")
--
-- Make a copy of the in memory data for debugging. Note: DeepCopy.lua needs to be added to the .toc
--
	if DA.deepcopy then
		self.data.sortedSkillList = {"Removed"}	-- This table is huge so don't save it unless needed.
--		SkilletMemory = DA.deepcopy(self.data)	-- Everything else
--
-- For RecipeGroups debugging:
--
		local tradeID, rest
		for tradeID in pairs(self.db.realm.tradeSkills[self.currentPlayer]) do
			DA.DEBUG(0,"tradeID= "..tostring(tradeID))
			if self.data.groupList[self.currentPlayer][tradeID] then
				self.data.groupList[self.currentPlayer][tradeID]["Blizzard"] = {"Removed"}
			end
		end
		SkilletMemory = DA.deepcopy(self.data.groupList) -- minus all the group "Blizzard" stuff
	end
	for tradeID in pairs(self.db.realm.tradeSkills[self.currentPlayer]) do
		--DA.DEBUG(0,"tradeID= "..tostring(tradeID)..", count= "..tostring(self.db.realm.tradeSkills[self.currentPlayer][tradeID].count))
		self.db.realm.tradeSkills[self.currentPlayer][tradeID].count = 0
	end
end

function Skillet:LEARNED_SPELL_IN_TAB(event, profession)
	DA.TRACE("LEARNED_SPELL_IN_TAB")
	DA.TRACE("profession= "..tostring(profession))
	if Skillet.tradeSkillOpen then
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_UPDATE
	end
end

function Skillet:NEW_RECIPE_LEARNED(event, recipeID)
	DA.TRACE("NEW_RECIPE_LEARNED")
	DA.TRACE("recipeID= "..tostring(recipeID))
	if Skillet.tradeSkillOpen then
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_UPDATE
	end
end

function Skillet:TRADE_SKILL_NAME_UPDATE()
	DA.TRACE("TRADE_SKILL_NAME_UPDATE")
	DA.TRACE("TRADE_SKILL_NAME_UPDATE: tradeShow= "..tostring(Skillet.tradeShow)..", linkedSkill= "..tostring(Skillet.linkedSkill))
	if not Skillet.tradeShow then return end
	if Skillet.linkedSkill then
		Skillet:ConfigureRecipeControls()
		Skillet:SkilletShow()
	end
end

function Skillet:TRADE_SKILL_UPDATE()
	DA.TRACE("TRADE_SKILL_UPDATE")
	Skillet.tradeUpdate = Skillet.tradeUpdate + 1
	DA.TRACE("TRADE_SKILL_UPDATE: closingTrade= "..tostring(Skillet.closingTrade)..", tradeShow= "..tostring(Skillet.tradeShow)..", tradeUpdate= "..tostring(Skillet.tradeUpdate))
	if Skillet.closingTrade or not Skillet.tradeShow then return end
	if Skillet.tradeUpdate < Skillet.db.realm.trade_wait then return end
	if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
		Skillet:ConfigureRecipeControls()
	end
	DA.TRACE("TRADE_SKILL_UPDATE: dataSourceChanged= "..tostring(Skillet.dataSourceChanged)..", dataScanned= "..tostring(Skillet.dataScanned))
	if Skillet.dataSourceChanged or not Skillet.dataScanned then
		Skillet.dataSourceChanged = false
		Skillet:SkilletShowWindow()
	end
end

function Skillet:CRAFT_UPDATE()
	DA.TRACE("CRAFT_UPDATE")
	Skillet.craftUpdate = Skillet.craftUpdate + 1
	DA.TRACE("CRAFT_UPDATE: closingTrade= "..tostring(Skillet.closingTrade)..", tradeShow= "..tostring(Skillet.tradeShow)..", craftUpdate= "..tostring(Skillet.craftUpdate))
	if Skillet.closingTrade or not Skillet.craftShow then return end
	if Skillet.craftUpdate < Skillet.db.realm.craft_wait then return end
	if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
		Skillet:ConfigureRecipeControls()
	end
	DA.TRACE("CRAFT_UPDATE: dataSourceChanged= "..tostring(Skillet.dataSourceChanged)..", dataScanned= "..tostring(Skillet.dataScanned))
	if Skillet.dataSourceChanged or not Skillet.dataScanned then
		Skillet.dataSourceChanged = false
		Skillet:SkilletShowWindow()
	end
end

function Skillet:SKILL_LINES_CHANGED()
	DA.TRACE("SKILL_LINES_CHANGED")
	if Skillet.tradeSkillOpen then
		Skillet.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_UPDATE
	end
end

function Skillet:TRADE_SKILL_CLOSE()
	DA.TRACE("TRADE_SKILL_CLOSE")
	if not Skillet.tradeShow then return end
	if Skillet.ignoreClose then
		Skillet.ignoreClose = false
		return
	end
	Skillet:SkilletClose()
	Skillet.hideTradeSkillFrame = nil
	Skillet.tradeShow = false
end

function Skillet:CRAFT_CLOSE()
	DA.TRACE("CRAFT_CLOSE")
	if not Skillet.craftShow then return end
	if Skillet.ignoreClose then
		Skillet.ignoreClose = false
		return
	end
	Skillet:SkilletClose()
	Skillet.hideCraftFrame = nil
	Skillet.craftShow = false
end

function Skillet:TRADE_SKILL_SHOW()
	DA.TRACE("TRADE_SKILL_SHOW")
	Skillet.tradeUpdate = 0
	DA.TRACE("TRADE_SKILL_SHOW: hideTradeSkillFrame= "..tostring(Skillet.hideTradeSkillFrame))
	if Skillet.hideTradeSkillFrame then
		HideUIPanel(TradeSkillFrame)
		Skillet.hideTradeSkillFrame = nil
	end
	Skillet.tradeShow = true
	Skillet.isCraft = false
	local name = GetTradeSkillLine()
	DA.TRACE("TRADE_SKILL_SHOW: name= '"..tostring(name).."'")
	DA.TRACE("TRADE_SKILL_SHOW: lastCraft= "..tostring(Skillet.lastCraft))
	Skillet:ConfigureRecipeControls()
--	SkilletEnchantButton:Hide()				-- Hide our button
	if not Skillet.changingTrade then		-- wait for UNIT_SPELLCAST_SUCCEEDED
		Skillet:SkilletShow()
	end
end

function Skillet:CRAFT_SHOW()
	DA.TRACE("CRAFT_SHOW")
	if Skillet.castSpellID == 5149 then
--
-- Beast Training opened
--   close the Skillet frame and
--   make sure the "Training" button is visible
--
		DA.TRACE("Beast Training opened")
		Skillet:RestoreEnchantButton(false)
		if Skillet.tradeSkillFrame and Skillet.tradeSkillFrame:IsVisible() then
			Skillet.isCraft = nil
			Skillet:SkilletClose()
			Skillet.changingTrade = nil
			Skillet.processingSpell = nil
		end
		ShowUIPanel(CraftFrame)
		return
	end
	if Skillet.hideCraftFrame then
		HideUIPanel(CraftFrame)
		Skillet.hideCraftFrame = nil
	end
	Skillet.craftShow = true
	Skillet.isCraft = true
	Skillet.hideCraftFrame = true
	Skillet.craftUpdate = 0
	local name = GetCraftDisplaySkillLine()
	DA.TRACE("CRAFT_SHOW: name= '"..tostring(name).."'")
	DA.TRACE("CRAFT_SHOW: lastCraft= "..tostring(Skillet.lastCraft))
	if Skillet.lastCraft ~= Skillet.isCraft then
		Skillet:ConfigureRecipeControls()
	end
	if Skillet.db.profile.support_crafting then
		SkilletEnchantButton:Hide()
	else
		SkilletEnchantButton:Disable()		-- because DoCraft is restricted
		SkilletEnchantButton:Show()
	end
	DA.TRACE("CRAFT_SHOW: changingTrade= "..tostring(Skillet.changingTrade))
	if not Skillet.changingTrade then		-- wait for UNIT_SPELLCAST_SUCCEEDED
		Skillet:SkilletShow()
	end
end

function Skillet:SPELLS_CHANGED()
	DA.TRACE("SPELLS_CHANGED")
end

function Skillet:UNIT_PORTRAIT_UPDATE()
	DA.TRACE("UNIT_PORTRAIT_UPDATE")
end

function Skillet:UNIT_PET_TRAINING_POINTS()
	DA.TRACE("UNIT_PET_TRAINING_POINTS")
end

--
-- Called when the addon is disabled
--
function Skillet:OnDisable()
	--DA.DEBUG(0,"OnDisable()")
	self:DisablePlugins()
	self:UnregisterAllEvents()
	self:EnableBlizzardFrame()
end

function Skillet:IsTradeSkillLinked()
	local isLinked = false
	local linkedPlayer
	local isGuild = false
	if IsTradeSkillLinked then
		isLinked, linkedPlayer = IsTradeSkillLinked()
	end
	if IsTradeSkillGuild then 
		isGuild = IsTradeSkillGuild()
	end
	DA.DEBUG(0,"IsTradeSkillLinked, isLinked="..tostring(isLinked)..", linkedPlayer="..tostring(linkedPlayer)..", isGuild="..tostring(isGuild))
	if isLinked or isGuild then
		if not linkedPlayer then
			if isGuild then
				linkedPlayer = "Guild Recipes" -- This can be removed when InitializeDatabase gets smarter.
			end
		end
		return isLinked, linkedPlayer, isGuild
	end
	return false, nil, false
end

--
-- Allow modifier keys that change initial frame behavior to be disabled.
-- Modifier keys within the Skillet frame are not effected.
-- Type "/skillet nomodkeys" to toggle.
--
-- Make modifier key to open Blizzard frame optional.
--
function Skillet:IsModKey1Down()
	if not Skillet.db.profile.nomodkeys and IsShiftKeyDown() then
		return true
	end
	return false
end

--
-- Make modifier key to alter some behaviors optional.
--
function Skillet:IsModKey2Down()
	if not Skillet.db.profile.nomodkeys and IsControlKeyDown() then
		return true
	end
	return false
end

--
-- Make modifier key to alter some behaviors optional.
--
function Skillet:IsModKey3Down()
	if not Skillet.db.profile.nomodkeys and IsAltKeyDown() then
		return true
	end
	return false
end

--
-- Checks to see if the current trade is one that we support.
-- Control key says we do (even if we don't, debugging)
-- Shift key says we don't support it (even if we do)
--
function Skillet:IsSupportedTradeskill(tradeID)
	--DA.DEBUG(0,"IsSupportedTradeskill("..tostring(tradeID)..")")
	if self:IsModKey2Down() then
		return true
	end
	if self:IsModKey1Down() then
		return false
	end
--
-- No support for Beast Training or Runeforging
--
	if not tradeID or tradeID == 5419 or tradeID == 53428 or UnitAffectingCombat("player") then
		return false
	end
	return true
end

--
-- Show the tradeskill window, called from TRADE_SKILL_SHOW or CRAFT_SHOW event or when changing trades.
--
function Skillet:SkilletShow()
	DA.DEBUG(0,"SkilletShow(), currentTrade= "..tostring(self.currentTrade))
	self.linkedSkill, self.currentPlayer, self.isGuild = Skillet:IsTradeSkillLinked()
	if self.linkedSkill then
		if not self.currentPlayer then
			DA.DEBUG(0,"Waiting for TRADE_SKILL_NAME_UPDATE")
			return -- Wait for TRADE_SKILL_NAME_UPDATE
		end
	else
		self.currentPlayer = (UnitName("player"))
	end
	local name, rank, maxRank
	if self.isCraft then
		name, rank, maxRank = GetCraftDisplaySkillLine()
	else
		name, rank, maxRank = GetTradeSkillLine()
	end
	--DA.DEBUG(0,"name= '"..tostring(name).."', rank= "..tostring(rank)..", maxRank= "..tostring(maxRank))
	if name then self.currentTrade = self.tradeSkillIDsByName[name] end
	if self:IsSupportedTradeskill(self.currentTrade) and not self.linkedSkill then
		DA.DEBUG(0,"SkilletShow: "..self.currentTrade..", name= '"..tostring(name).."', rank= "..tostring(rank)..", maxRank= "..tostring(maxRank))
		self.selectedSkill = nil
		self.dataScanned = false
		self.tradeSkillOpen = true
		if self.db.profile.hide_blizzard_frame and not TSM_API then
			if self.isCraft then
				DA.DEBUG(0,"HideUIPanel(CraftFrame)")
				Skillet.hideCraftFrame = true
				HideUIPanel(CraftFrame)
				if Skillet.tradeShow then
					CloseTradeSkill()
				end
			else
				DA.DEBUG(0,"HideUIPanel(TradeSkillFrame)")
				Skillet.hideTradeSkillFrame = true
				HideUIPanel(TradeSkillFrame)
				if Skillet.craftShow then
					self:RestoreEnchantButton()
					CloseCraft()
				end
			end
		end
--
-- Processing will continue in SkilletShowWindow when the TRADE_SKILL_UPDATE or CRAFT_UPDATE event fires
-- (Wrath needs a little help)
--
		if isWrath then
			if self.isCraft then
				Skillet:CRAFT_UPDATE()
			else
				Skillet:TRADE_SKILL_UPDATE()
			end
		end
	else
--
-- give Hunter Beast Training a pass
-- for everything else bring up the appropriate Blizzard UI
--
		if self.castSpellID == 5149 then
			return
		elseif not self:IsModKey1Down() and not UnitAffectingCombat("player") and not self.linkedSkill then
			DA.DEBUG(0,"SkilletShow: "..tostring(self.currentTrade).." ("..tostring(name)..") is not supported")
			DA.DEBUG(0,"tradeSkillIDsByName= "..DA.DUMP(self.tradeSkillIDsByName))
		end
		self:HideAllWindows()
		if self.isCraft then
			self:RestoreEnchantButton(true)
			ShowUIPanel(CraftFrame)
		else
			ShowUIPanel(TradeSkillFrame)
		end
	end
end

--
-- Called from various events that indicate there may be new data
--
function Skillet:SkilletShowWindow()
	DA.DEBUG(0,"SkilletShowWindow(), currentTrade= "..tostring(self.currentTrade)..", scanInProgress= "..tostring(scanInProgress))
	if self:IsModKey2Down() then
		self.db.realm.skillDB[self.currentPlayer][self.currentTrade] = {}
	end
	if not self:RescanTrade() then
		if TSM_API or ZygorGuidesViewerClassicSettings then
			if TSM_API then
				DA.MARK3(L["Conflict with the addon TradeSkillMaster"])
				self.db.profile.TSM_API = true
			end
			if ZygorGuidesViewerClassicSettings then
				DA.MARK3(L["Conflict with the addon Zygor Guides"])
				self.db.profile.ZYGOR = true
			end
		else
--
-- Changed from DA.CHAT because this state can happen before enough
-- TRADE_SKILL_UPDATE or CRAFT_UPDATE events have occurred.
--
			DA.WARN(L["No headers, try again"])
		end
		return
	end
	if self.isCraft then
		if Skillet.db.profile.support_crafting then
			self:StealEnchantButton()
		end
	end
	self.currentGroup = nil
	self.currentGroupLabel = self:GetTradeSkillOption("grouping")
	self:RecipeGroupDropdown_OnShow()
	self:ShowTradeSkillWindow()
	local searchbox = _G["SkilletSearchBox"]
	local oldtext = searchbox:GetText()
	local searchText = self:GetTradeSkillOption("searchtext")
--
-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
--
	if searchText ~= oldtext then
		searchbox:SetText(searchText)
	else
		self:UpdateTradeSkillWindow()
	end
end

function Skillet:SkilletClose()
	DA.DEBUG(0,"SkilletClose()")
	self.tradeSkillOpen = false
	self.lastCraft = self.isCraft
	if self.isCraft then
		self:RestoreEnchantButton(false)
	end
	self:HideAllWindows()
	self.closingTrade = nil
end

function Skillet:GET_ITEM_INFO_RECEIVED(event, itemID, success)
	DA.TRACE("GET_ITEM_INFO_RECEIVED( "..tostring(itemID)..", "..tostring(success).." )")
end

--
-- Trade window events (debugging only for now)
--
function Skillet:TRADE_SHOW()
	DA.TRACE("TRADE_SHOW()")
end

function Skillet:TRADE_MONEY_CHANGED()
	DA.TRACE("TRADE_MONEY_CHANGED()")
end

function Skillet:TRADE_PLAYER_ITEM_CHANGED(event, tradeSlotIndex)
	DA.TRACE("TRADE_PLAYER_ITEM_CHANGED( "..tostring(tradeSlotIndex).." )")
end

function Skillet:TRADE_TARGET_ITEM_CHANGED(event, tradeSlotIndex)
	DA.TRACE("TRADE_TARGET_ITEM_CHANGED( "..tostring(tradeSlotIndex).." )")
end

function Skillet:TRADE_REPLACE_ENCHANT()
	DA.TRACE("TRADE_REPLACE_ENCHANT()")
end

function Skillet:TRADE_POTENTIAL_BIND_ENCHANT(event, canBecomeBoundForTrade)
	DA.TRACE("TRADE_POTENTIAL_BIND_ENCHANT( "..tostring(canBecomeBoundForTrade).." )")
end

function Skillet:TRADE_REQUEST(event, name)
	DA.TRACE("TRADE_REQUEST( "..tostring(name).." )")
end

function Skillet:TRADE_REQUEST_CANCEL()
	DA.TRACE("TRADE_REQUEST_CANCEL()")
end

function Skillet:TRADE_UPDATE()
	DA.TRACE("TRADE_UPDATE()")
end

function Skillet:TRADE_ACCEPT_UPDATE(event, playerAccepted, targetAccepted)
	DA.TRACE("TRADE_ACCEPT_UPDATE( "..tostring(playerAccepted)..", "..tostring(targetAccepted).." )")
end

--
-- Make sure profession changes are spaced out
--   delayChange is set when ChangeTradeSkill is called
--     and cleared here when the timer expires.
--
function Skillet:DelayChange()
	DA.DEBUG(0,"DelayChange()")
	Skillet.delayChange = false
	if Skillet.delayNeeded then
		Skillet.delayNeeded = false
		Skillet:ChangeTradeSkill(Skillet.delayTrade, Skillet.delayName)
	end
end

--
-- Change to a different profession but
--   not more often than once every .5 seconds.
-- If called too quickly, delayNeeded is set and
--   the change is deferred until DelayChange is called.
--
function Skillet:ChangeTradeSkill(tradeID, tradeName)
	DA.DEBUG(0,"ChangeTradeSkill("..tostring(tradeID)..", "..tostring(tradeName)..")")
	if not self.delayChange then
		local spellID = tradeID
		if tradeID == 2575 then spellID = 2656 end		-- Ye old Mining vs. Smelting issue
		local spell = self:GetTradeName(spellID)
		DA.DEBUG(1,"tradeID= "..tostring(tradeID)..", tradeName= "..tostring(tradeName)..", Mining= "..tostring(Mining)..", Smelting= "..tostring(Smelting))
		if Skillet.db.profile.ignore_change or isClassic then
			if not self.db.realm.tradeSkills[self.currentPlayer][tradeID].count or self.db.realm.tradeSkills[self.currentPlayer][tradeID].count < 1 then
				DA.DEBUG(1,"ChangeTradeSkill: executing ChangeTrade("..tostring(tradeID).."), count= "..tostring(self.db.realm.tradeSkills[self.currentPlayer][tradeID].count)..", tradeName= "..tostring(tradeName))
				self.db.realm.tradeSkills[self.currentPlayer][tradeID].count = 1
				self.closingTrade = true
				self:SkilletClose()
				StaticPopup_Show("SKILLET_IGNORE_CHANGE")
				return
			end
		end
		DA.DEBUG(1,"ChangeTradeSkill: executing CastSpellByName("..tostring(spell)..")")
		self.processingSpell = spell
		CastSpellByName(spell) -- trigger the whole rescan process via a TRADE_SKILL_SHOW or CRAFT_SHOW event
		self.delayTrade = tradeID
		self.delayName = tradeName
		self.delayChange = true
		self:ScheduleTimer("DelayChange", 0.5)
	else
		DA.DEBUG(1,"ChangeTradeSkill: waiting for callback")
		self.delayNeeded = true
	end
end

function Skillet:ChangeTrade(tradeID)
	DA.DEBUG(0,"ChangeTrade("..tostring(tradeID)..")")
	self.closingTrade = true
	if self.isCraft then
		CloseCraft()
	else
		CloseTradeSkill()
	end
	self:HideAllWindows()
	self.changingTrade = tradeID
	self.changingName = self.tradeSkillNamesByID[tradeID]
	DA.DEBUG(0,"ChangeTrade: changingTrade= "..tostring(self.changingTrade)..", changingName= "..tostring(self.changingName)..", isCraft= "..tostring(self.isCraft))
	StaticPopup_Show("SKILLET_CONTINUE_CHANGE")
end

--
-- Called from a static popup to change professions
--   changingTrade and changingName should be set to
--   the target profession.
--
function Skillet:ContinueChange()
	DA.DEBUG(0,"ContinueChange()")
	self.isCraft = self.skillIsCraft[self.changingTrade]
	DA.DEBUG(1,"ContinueChange: changingTrade= "..tostring(self.changingTrade)..", changingName= "..tostring(self.changingName)..
	  ", isCraft= "..tostring(self.isCraft))
	self.currentTrade = self.changingTrade
	self:ChangeTradeSkill(self.changingTrade, self.changingName)
end

--
-- Either change to a different profession or change the currently selected recipe
--
function Skillet:SetTradeSkill(player, tradeID, skillIndex)
	DA.DEBUG(0,"SetTradeSkill("..tostring(player)..", "..tostring(tradeID)..", "..tostring(skillIndex)..")")
	if player ~= self.currentPlayer then
		DA.DEBUG(0,"player not currentPlayer is not supported in Classic")
		return
	end
	if tradeID ~= self.currentTrade then
		local oldTradeID = self.currentTrade
		local tradeName = self:GetTradeName(tradeID)
		if self.skillIsCraft[oldTradeID] ~= self.skillIsCraft[TradeID] then
			self.ignoreClose = true
			self.isCraft = self.skillIsCraft[TradeID]	-- the skill we are going to
			self:ConfigureRecipeControls()
		end
		self.currentTrade = nil
		self.selectedSkill = nil
		self.currentGroup = nil
		self:HideNotesWindow()
		self:ChangeTradeSkill(tradeID, tradeName)
	else
		self:SetSelectedSkill(skillIndex, false)
	end
end

--
-- Shows the trade skill frame.
--
function Skillet:ShowTradeSkillWindow()
	DA.DEBUG(0,"ShowTradeSkillWindow()")
	local frame = self.tradeSkillFrame
	if not frame then
		frame = self:CreateTradeSkillWindow()
		self.tradeSkillFrame = frame
	end
	self:ResetTradeSkillWindow()
	Skillet:ShowFullView()
	if not frame:IsVisible() then
		frame:Show()
		self:UpdateTradeSkillWindow()
	else
		self:UpdateTradeSkillWindow()
	end
	DA.DEBUG(0,"ShowTradeSkillWindow complete")
end

--
-- Hides the Skillet trade skill window. Does nothing if the window is not visible
--
function Skillet:HideTradeSkillWindow()
	local closed -- was anything closed by us?
	local frame = self.tradeSkillFrame
	if frame and frame:IsVisible() then
		self:DisablePauseButton()
		self:StopCast()
		frame:Hide()
		closed = true
	end
	return closed
end

--
-- Hides any and all Skillet windows that are open
--
function Skillet:HideAllWindows()
	--DA.DEBUG(0,"HideAllWindows()")
	local closed -- was anything closed?
--
-- Cancel anything currently being created
--
	if self:HideTradeSkillWindow() then
		closed = true
	end
	if self:HideNotesWindow() then
		closed = true
	end
	if self:HideShoppingList() then
		closed = true
	end
	if self:HideStandaloneQueue() then
		closed = true
	end
	self.currentTrade = nil
	self.selectedSkill = nil
	self.queueCasting = nil
	return closed
end

--
-- Sets the specific trade skill that the user wants to see details on.
--
function Skillet:SetSelectedSkill(skillIndex)
	--DA.DEBUG(0,"SetSelectedSkill("..tostring(skillIndex)..")")
	if not skillIndex then
--
-- no skill selected
--
		self:HideNotesWindow()
	elseif self.selectedSkill and self.selectedSkill ~= skillIndex then
--
-- new skill selected
--
		self:HideNotesWindow()
	end
	self:ConfigureRecipeControls()
	if Skillet.db.profile.support_crafting and self.isCraft and CraftFrame_SetSelection then
		CraftFrame_SetSelection(skillIndex)
		if CraftFrame:IsVisible() then
			CraftFrame_Update()
		end
	end
	self.selectedSkill = skillIndex
	self:ScrollToSkillIndex(skillIndex)
	self:UpdateDetailsWindow(skillIndex)
end

--
-- Updates the text we filter the list of recipes against.
--
function Skillet:UpdateSearch(text)
	--DA.DEBUG(0,"UpdateSearch("..tostring(text)..")")
	self:SetTradeSkillOption("searchtext", text)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

--
-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
--
function Skillet:GetItemNote(key)
	--DA.DEBUG(0,"GetItemNote("..tostring(key)..")")
	local result
	if not self.db.realm.notes[self.currentPlayer] then
		return
	end
	local kind, id = string.split(":", key)
	if kind == "enchant" then 					-- get the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
	--DA.DEBUG(0,"GetItemNote itemID="..tostring(id))
	if id then
		result = self.db.realm.notes[self.currentPlayer][id]
	else
		self:Print("Skillet:GetItemNote() could not determine item ID for " .. key)
	end
	if result and result == "" then
		result = nil
		self.db.realm.notes[self.currentPlayer][id] = nil
	end
	return result
end

--
-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
--
function Skillet:SetItemNote(key, note)
	--DA.DEBUG(0,"SetItemNote("..tostring(key)..", "..tostring(note)..")")
	local kind, id = string.split(":", key)
	if kind == "enchant" then 					-- store the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
	--DA.DEBUG(0,"SetItemNote itemID="..tostring(id))
	if not self.db.realm.notes[self.currentPlayer] then
		self.db.realm.notes[self.currentPlayer] = {}
	end
	if id then
		self.db.realm.notes[self.currentPlayer][id] = note
	else
		self:Print("Skillet:SetItemNote() could not determine item ID for " .. key)
	end
end

--
-- Adds the skillet notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
--
function Skillet:AddItemNotesToTooltip(tooltip, altID)
	--DA.DEBUG(0,"AddItemNotesToTooltip()")
	if self:IsModKey2Down() then
		return
	end
	local notes_enabled = self.db.profile.show_item_notes_tooltip or false
	local crafters_enabled = self.db.profile.show_crafters_tooltip or false
	if not notes_enabled and not crafters_enabled then
		return -- nothing to be added to the tooltip
	end
--
-- get item name
--
	local id
	if not altID then
		local name,link = tooltip:GetItem()
		if not link then 
			--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine link")
			return
		end
		id = self:GetItemIDFromLink(link)
	else
		id = altID
	end
	if not id then
		DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine id")
		return
	end
	--DA.DEBUG(1,"name= "..tostring(name)..", link= "..tostring(link)..", id= "..tostring(id)..", notes= "..tostring(notes_enabled)..", crafters= "..tostring(crafters_enabled))
	if notes_enabled then
		local header_added = false
		for player,notes_table in pairs(self.db.realm.notes) do
			local note = notes_table[tostring(id)]
			--DA.DEBUG(1,"player= "..tostring(player)..", table= "..DA.DUMP1(notes_table)..", note= '"..tostring(note).."'")
			if note then
				if not header_added then
					tooltip:AddLine("Skillet " .. L["Notes"] .. ":")
					header_added = true
				end
				if player ~= UnitName("player") then
					note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
				end
				tooltip:AddLine(" " .. note, 1, 1, 1, true) -- r,g,b, wrap
			end
		end
	end
	return header_added
end

function Skillet:ToggleTradeSkillOption(option)
	local v = self:GetTradeSkillOption(option)
	self:SetTradeSkillOption(option, not v)
end

--
-- Returns the state of a craft specific option
--
function Skillet:GetTradeSkillOption(option, playerOverride, tradeOverride)
	local r
	local player = playerOverride or self.currentPlayer
	local trade = tradeOverride or self.currentTrade
	local options = self.db.realm.options
	if not options or not options[player] or not options[player][trade] then
		r = Skillet.defaultOptions[option]
	elseif options[player][trade][option] == nil then
		r =  Skillet.defaultOptions[option]
	else
		r = options[player][trade][option]
	end
	--DA.DEBUG(0,"GetTradeSkillOption("..tostring(option)..", "..tostring(playerOverride)..", "..tostring(tradeOverride)..")= "..tostring(r)..", player= "..tostring(player)..", trade= "..tostring(trade))
	return r
end

--
-- sets the state of a craft specific option
--
function Skillet:SetTradeSkillOption(option, value, playerOverride, tradeOverride)
	if not self.linkedSkill and not self.isGuild then
		local player = playerOverride or self.currentPlayer
		local trade = tradeOverride or self.currentTrade
		if not self.db.realm.options then
			self.db.realm.options = {}
		end
		if not self.db.realm.options[player] then
			self.db.realm.options[player] = {}
		end
		if not self.db.realm.options[player][trade] then
			self.db.realm.options[player][trade] = {}
		end
		self.db.realm.options[player][trade][option] = value
	end
end

function Skillet:IsActive()
	return Skillet:IsEnabled()
end

function Skillet:IsCraft()
	return Skillet.isCraft
end

