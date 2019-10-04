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

local PT = LibStub("LibPeriodicTable-3.1")
local L = Skillet.L

--
-- Smelting and Mining are bipolar so
-- give them names to remember
--
local SMELTING = 2656
local MINING = 2575

--
-- a table of tradeskills by id
--
local TradeSkillList = {
	2259,		-- alchemy
	2018,		-- blacksmithing
	4036,		-- engineering
	2108,		-- leatherworking
	SMELTING,	-- smelting
	MINING,		-- mining
	3908,		-- tailoring
	2550,		-- cooking
	3273,		-- first aid
	2842,		-- poisons
--	45357,		-- inscription (not in Classic)
--	25229,		-- jewelcrafting (not in Classic)
--	53428,		-- runeforging (not in Classic)
}

--
-- a table of crafts by id
--
local CraftList = {
	7411,		-- enchanting (Blizzard has restricted DoCraft(index) to anything but their own UI)
}

--
--  a table of locale specific translations by id
--- needed to fix Blizzard inconsistent translations
--
-- [tradeID] = {locale, old, new}
--   locale is what GetLocale() returns
--   old is the return from GetSpellInfo(tradeID)
--   new is the return from GetTradeSkillLine() when the tradeskill / craft is opened
--
local TranslateList = {
	[4036] = {"frFR", "Ingénieur", "Ingénierie"},	-- Engineering
	[3273] = {"frFR", "Premiers soins", "???"},		-- First Aid
}

local TradeSkillIDsByName = {}		-- filled in with ids and names for reverse matching (since the same name may have multiple id's based on level)
local TradeSkillNamesByID = {}		-- filled in with names and ids for reverse matching

Skillet.AdditionalAbilities = {
	[7411]	= {13262,"Disenchant"},		-- enchanting = disenchant (will disappear because enchanting is disabled)
	[2550]	= {818,"Basic_Campfire"},	-- cooking = basic campfire
	[45357] = {51005,"Milling"},		-- inscription = milling
	[25229] = {31252,"Prospecting"},	-- jewelcrafting = prospecting
	[2018]	= {126462,"Thermal Anvil"},	 -- blacksmithing = thermal anvil (item:87216)
	[4036]	= {126462,"Thermal Anvil"},	 -- engineering = thermal anvil (item:87216)
	[SMELTING]	= {126462,"Thermal Anvil"},	 -- smelting = thermal anvil (item:87216)
}

--
-- Checks to see if the current trade is one that we support.
--
function Skillet:IsSupportedTradeskill(tradeID)
	if IsShiftKeyDown() or not tradeID or tradeID == 5419 or tradeID == 53428 then
		return false
	end
	return true
end

--
-- Collects generic tradeskill and craft data (id to name and name to id)
--
-- self.tradeSkillList contains data from both.
-- self.skillIsCraft contains boolean (tradeskill or craft)
-- self.tradeSkillIDsByName contains name to id data
-- self.tradeSkillNamesByID contains id to name data
--
function Skillet:CollectTradeSkillData()
	DA.DEBUG(0,"CollectTradeSkillData()")
	self.tradeSkillList = {}
	self.skillIsCraft = {}
	for i=1,#TradeSkillList,1 do
		local id = TradeSkillList[i]
		local name = GetSpellInfo(id)
		DA.DEBUG(2,"id= "..tostring(id)..", name= "..tostring(name))
		if name then
			table.insert(self.tradeSkillList,id)
			self.skillIsCraft[id] = false
			TradeSkillIDsByName[name] = id
			TradeSkillNamesByID[id] = name
		end
	end
	if self.db.profile.support_crafting then
		for i=1,#CraftList,1 do
			local id = CraftList[i]
			local name = GetSpellInfo(id)
			DA.DEBUG(2,"id= "..tostring(id)..", name= "..tostring(name))
			if name then
				table.insert(self.tradeSkillList,id)
				self.skillIsCraft[id] = true
				TradeSkillIDsByName[name] = id
				TradeSkillNamesByID[id] = name
			end
		end
	end
	local locale = GetLocale()
	DA.DEBUG(2,"locale= "..tostring(locale))
	for id,t in pairs(TranslateList) do
		local loc = t[1]
		local old = t[2]
		local new = t[3]
		DA.DEBUG(2,"id= "..tostring(id)..", loc= "..tostring(loc)..", old= "..tostring(old)..", new= "..tostring(new))
		if loc == locale then
			TradeSkillIDsByName[new] = id
		end
	end

	self.tradeSkillIDsByName = TradeSkillIDsByName
	self.tradeSkillNamesByID = TradeSkillNamesByID
end

--
-- this routine collects the basic data (which tradeskills a player has)
--
function Skillet:ScanPlayerTradeSkills(player)
	--DA.DEBUG(0,"ScanPlayerTradeSkills("..tostring(player)..")")
	if player == self.currentPlayer then -- only for active player
		if not self.db.realm.tradeSkills[player] then
			self.db.realm.tradeSkills[player] = {}
		end
		local skillRanksData = self.db.realm.tradeSkills[player]
		if self.tradeSkillList then
			for i=1,#self.tradeSkillList,1 do
				local id = self.tradeSkillList[i]
				local name = GetSpellInfo(id)				-- always returns data
				if name then
					local tradeName = GetSpellInfo(name)	-- only returns data if you have this spell in your spellbook
					if tradeName then
						--DA.DEBUG(2,"Collecting tradeskill data for: "..tostring(name)..", id= "..tostring(id)..", isCraft= "..tostring(self.skillIsCraft[id]))
						if not skillRanksData[id] then
							skillRanksData[id] = {}
							skillRanksData[id].name = name
							skillRanksData[id].rank = 0
							skillRanksData[id].maxRank = 0
							skillRanksData[id].isCraft = self.skillIsCraft[id]
						end
					else
						--DA.DEBUG(2,"Skipping tradeskill data for: "..tostring(name)..", id= "..tostring(id)..", isCraft= "..tostring(self.skillIsCraft[id]))
						skillRanksData[id] = nil
					end
				end
			end
		end
		if not self.db.realm.faction then
			self.db.realm.faction = {}
		end
		self.db.realm.faction[player] = UnitFactionGroup("player")
	else
		DA.DEBUG(0,"Player "..tostring(player).." is not currentPlayer")
	end
end

--
-- Items in this list are ignored because they can cause infinite loops.
--
local TradeSkillIgnoredMats	 = {
	[11479] = 1 , -- Transmute: Iron to Gold
	[11480] = 1 , -- Transmute: Mithril to Truesilver
	[60350] = 1 , -- Transmute: Titanium
	[17559] = 1 , -- Transmute: Air to Fire
	[17560] = 1 , -- Transmute: Fire to Earth
	[17561] = 1 , -- Transmute: Earth to Water
	[17562] = 1 , -- Transmute: Water to Air
	[17563] = 1 , -- Transmute: Undeath to Water
	[17565] = 1 , -- Transmute: Life to Earth
	[17566] = 1 , -- Transmute: Earth to Life
	[28585] = 1 , -- Transmute: Primal Earth to Life
	[28566] = 1 , -- Transmute: Primal Air to Fire
	[28567] = 1 , -- Transmute: Primal Earth to Water
	[28568] = 1 , -- Transmute: Primal Fire to Earth
	[28569] = 1 , -- Transmute: Primal Water to Air
	[28580] = 1 , -- Transmute: Primal Shadow to Water
	[28581] = 1 , -- Transmute: Primal Water to Shadow
	[28582] = 1 , -- Transmute: Primal Mana to Fire
	[28583] = 1 , -- Transmute: Primal Fire to Mana
	[28584] = 1 , -- Transmute: Primal Life to Earth
	[53771] = 1 , -- Transmute: Eternal Life to Shadow
	[53773] = 1 , -- Transmute: Eternal Life to Fire
	[53774] = 1 , -- Transmute: Eternal Fire to Water
	[53775] = 1 , -- Transmute: Eternal Fire to Life
	[53776] = 1 , -- Transmute: Eternal Air to Water
	[53777] = 1 , -- Transmute: Eternal Air to Earth
	[53779] = 1 , -- Transmute: Eternal Shadow to Earth
	[53780] = 1 , -- Transmute: Eternal Shadow to Life
	[53781] = 1 , -- Transmute: Eternal Earth to Air
	[53782] = 1 , -- Transmute: Eternal Earth to Shadow
	[53783] = 1 , -- Transmute: Eternal Water to Air
	[53784] = 1 , -- Transmute: Eternal Water to Fire
	[45765] = 1 , -- Void Shatter
	[42615] = 1 , -- small prismatic shard
	[42613] = 1 , -- nexus transformation
	[28022] = 1 , -- large prismatic shard
	[118239] = 1 , -- sha shatter
	[118238] = 1 , -- ethereal shard shatter
	[118237] = 1 , -- mysterious diffusion
	[181637] = 1 , -- Transmute: Sorcerous-air-to-earth
	[181633] = 1 , -- Transmute: Sorcerous-air-to-fire
	[181636] = 1 , -- Transmute: Sorcerous-air-to-water
	[181631] = 1 , -- Transmute: Sorcerous-earth-to-air
	[181632] = 1 , -- Transmute: Sorcerous-earth-to-fire
	[181635] = 1 , -- Transmute: Sorcerous-earth-to-water
	[181627] = 1 , -- Transmute: Sorcerous-fire-to-air
	[181625] = 1 , -- Transmute: Sorcerous-fire-to-earth
	[181628] = 1 , -- Transmute: Sorcerous-fire-to-water
	[181630] = 1 , -- Transmute: Sorcerous-water-to-air
	[181629] = 1 , -- Transmute: Sorcerous-water-to-earth
	[181634] = 1 , -- Transmute: Sorcerous-water-to-fire
	[181643] = 1 , -- Transmute: Savage Blood
}
Skillet.TradeSkillIgnoredMats = TradeSkillIgnoredMats

--
-- None of these "features" exist in Classic
--
Skillet.scrollData = {
--[[
-- Scraped from WoWhead using the following javascript:
-- for (i=0; i<listviewitems.length; i++) console.log("["+listviewitems[i].sourcemore[0].ti+"] = "+listviewitems[i].id+", 
-- "+listviewitems[i].name.substr(1));
]]--
}

Skillet.TradeSkillAutoTarget = {
}

local lastAutoTarget = {}
function Skillet:GetAutoTargetItem(tradeID)
	if self.TradeSkillAutoTarget[tradeID] then
		local itemID = lastAutoTarget[tradeID]
		if itemID then
			local limit	 = self.TradeSkillAutoTarget[tradeID][itemID]
			local count = GetItemCount(itemID)
			if count >= limit then
				return itemID
			end
		end
		for itemID,limit in pairs(self.TradeSkillAutoTarget[tradeID]) do
			local count = GetItemCount(itemID)
			if count >= limit then
				lastAutoTarget[tradeID] = itemID
				return itemID
			end
		end
		lastAutoTarget[tradeID] = nil
	end
end

function Skillet:GetAutoTargetMacro(additionalSpellId)
	local itemID = Skillet:GetAutoTargetItem(additionalSpellId)
	if itemID then
		return "/cast "..(GetSpellInfo(additionalSpellId) or "").."\n/use "..(GetItemInfo(itemID) or "")
	else
		return "/cast "..(GetSpellInfo(additionalSpellId) or "")
	end
end
--
--  end of "features" not in Classic
--

local DifficultyText = {
	x = "unknown",
	o = "optimal",
	m = "medium",
	e = "easy",
	t = "trivial",
	u = "unavailable",
}
local DifficultyChar = {
	unknown = "x",
	optimal = "o",
	medium = "m",
	easy = "e",
	trivial = "t",
	unavailable = "u", 
}
local skill_style_type = {
	["unknown"]			= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
	["optimal"]			= { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
	["medium"]			= { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",	cstring = "|cffffff00"},
	["easy"]			= { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",	cstring = "|cff40c000"},
	["trivial"]			= { r = 0.60, g = 0.60, b = 0.60, level = 1, alttext="",	cstring = "|cff909090"},
	["header"]			= { r = 1.00, g = 0.82, b = 0,	  level = 0, alttext="",	cstring = "|cffffc800"},
	["unavailable"]		= { r = 0.3, g = 0.3, b = 0.3,	  level = 6, alttext="",	cstring = "|cff606060"},
}

--
-- adds an recipe source for an itemID (recipeID produces itemID)
--
function Skillet:ItemDataAddRecipeSource(itemID,recipeID)
	if not itemID or not recipeID then return end
	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end
	if not self.db.global.itemRecipeSource[itemID] then
		self.db.global.itemRecipeSource[itemID] = {}
	end
	self.db.global.itemRecipeSource[itemID][recipeID] = true
end

--
-- adds a recipe usage for an itemID (recipeID uses itemID as a reagent)
--
function Skillet:ItemDataAddUsedInRecipe(itemID,recipeID)
	if not itemID or not recipeID then return end
	if not self.db.global.itemRecipeUsedIn then
		self.db.global.itemRecipeUsedIn = {}
	end
	if not self.db.global.itemRecipeUsedIn[itemID] then
		self.db.global.itemRecipeUsedIn[itemID] = {}
	end
	self.db.global.itemRecipeUsedIn[itemID][recipeID] = true
end

--
-- goes thru the stored recipe list and collects reagent and item information as well as skill lookups
--
function Skillet:CollectRecipeInformation()
	for recipeID, recipeString in pairs(self.db.global.recipeDB) do
		local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
		local itemID, numMade = 0, 1
		local slot = nil
		if itemString ~= "0" then
			local a, b = string.split(":",itemString)
			if a ~= "0" then
				itemID, numMade = a,b
			else
				itemID = 0
				numMade = 1
				slot = tonumber(b)
			end
			if not numMade then
				numMade = 1
			end
		end
		itemID = tonumber(itemID)
		if itemID ~= 0 then
			self:ItemDataAddRecipeSource(itemID, recipeID)
		end
		if reagentString ~= "-" then
			local reagentList = { string.split(":",reagentString) }
			local numReagents = #reagentList / 2
			for i=1,numReagents do
				local reagentID = tonumber(reagentList[1 + (i-1)*2])
				self:ItemDataAddUsedInRecipe(reagentID, recipeID)
			end
		end
	end
	for player,tradeList in pairs(self.db.realm.skillDB) do
		self.data.skillIndexLookup[player] = {}
		for trade,skillList in pairs(tradeList) do
			for i=1,#skillList do
				local skillString = self.db.realm.skillDB[player][trade][i]
				if skillString then
				--DA.DEBUG(0,"skillString= '"..skillString.."'")
				local skillData = { string.split("@", skillString) }
				--DA.DEBUG(0,"skillData= "..DA.DUMP1(skillData))
					local skillHeader = { string.split(" ", skillData[1]) }
					if skillHeader[1] ~= "header" or skillHeader[1] ~= "subheader" then
						local recipeID = string.sub(skillData[1],2)
						self.data.skillIndexLookup[player][recipeID] = i
					end
				end
			end
		end
	end
end

local missingVendorItems = {
	[30817] = true,				-- simple flour
	[4539] = true,				-- Goldenbark Apple
	[17035] = true,				-- Stranglethorn seed
	[17034] = true,				-- Maple seed
	[52188] = true,				-- Jeweler's Setting
	[4399]	= true,				-- Wooden Stock
	[38682] = true,				-- Enchanting Vellum
	[3857]	= true,				-- Coal
}

local topink = 113111				-- Warbinder's Ink
local specialVendorItems = {
	[37101] = {1, topink},			--Ivory Ink
	[39469] = {1, topink},			--Moonglow Ink
	[39774] = {1, topink},			--Midnight Ink
	[43116] = {1, topink},			--Lions Ink
	[43118] = {1, topink},			--Jadefire Ink
	[43120] = {1, topink},			--Celestial Ink
	[43122] = {1, topink},			--Shimmering Ink
	[43124] = {1, topink},			--Ethereal Ink
	[43126] = {1, topink},			--Ink of the Sea
	[61978] = {1, topink},			--Blackfallow Ink
	[79254] = {1, topink},			--Ink of Dreams

	[43127] = {10, topink},			--Snowfall Ink
	[61981] = {10, topink},			--Inferno Ink
	[79255] = {10, topink},			--Starlight Ink
}

function Skillet:VendorItemAvailable(itemID)
	if specialVendorItems[itemID] then
		local divider = specialVendorItems[itemID][1]
		local currency = specialVendorItems[itemID][2]
		local reagentAvailability = self:GetInventory(self.currentPlayer, currency)
		local reagentAvailableAlts = 0
		for alt in pairs(self.db.realm.inventoryData) do
			if alt ~= self.currentPlayer then
				local altBoth = self:GetInventory(alt, currency)
				reagentAvailableAlts = reagentAvailableAlts + (altBoth or 0)
			end
		end
		return math.floor(reagentAvailability / divider), math.floor(reagentAvailableAlts / divider)
	else
		return 100000, 100000
	end
end

--
-- queries for vendor info for a particular itemID
--
function Skillet:VendorSellsReagent(itemID)
--
-- Check our local data first
--
	if missingVendorItems[itemID] or specialVendorItems[itemID] then
		return true
	end
--
-- Check the LibPeriodicTable data next
--
	if PT then
		if itemID ~= 0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
			return true
		end
	end
	return false
end

--
-- resets the blizzard tradeskill search filters just to make sure no other addon has monkeyed with them
--
function Skillet:ExpandTradeSkillSubClass(i)
	--DA.DEBUG(0,"ExpandTradeSkillSubClass "..tostring(i))
end

function Skillet:GetRecipeName(id)
	if not id then return "unknown" end
	local name
	if tonumber(id) ~= nil then
		name = GetSpellInfo(id)
	else
		name = id
	end
	return name, id 
end

function Skillet:GetRecipe(id)
	--DA.DEBUG(0,"GetRecipe("..tostring(id)..")")
	if id and id ~= 0 then 
		if Skillet.data.recipeList[id] then
			return Skillet.data.recipeList[id]
		end
		if Skillet.db.global.recipeDB[id] then
			local recipeString = Skillet.db.global.recipeDB[id]
			DA.DEBUG(3,"recipeString= "..tostring(recipeString))
			local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
			local itemID, numMade = 0, 1
			local slot = nil
			if itemString then
				if itemString ~= "0" then
					local a, b = string.split(":",itemString)
					DA.DEBUG(3,"itemString a= "..tostring(a)..", b= "..tostring(b))
					if a ~= "0" then
						itemID, numMade = a,b
					else
						itemID = 0
						numMade = 1
						slot = tonumber(b)
					end
					if not numMade then
						numMade = 1
					end
				end
			else
				DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			Skillet.data.recipeList[id] = {}
			Skillet.data.recipeList[id].spellID = tonumber(id)
			Skillet.data.recipeList[id].name = GetSpellInfo(tonumber(id))
			Skillet.data.recipeList[id].tradeID = tonumber(tradeID)
			Skillet.data.recipeList[id].itemID = tonumber(itemID)
			Skillet.data.recipeList[id].numMade = tonumber(numMade)
			Skillet.data.recipeList[id].slot = slot
			Skillet.data.recipeList[id].reagentData = {}
			if reagentString then
				if reagentString ~= "-" then
					local reagentList = { string.split(":",reagentString) }
					local numReagents = #reagentList / 2
					for i=1,numReagents do
						local itemID = tonumber(reagentList[1 + (i-1)*2])
						Skillet.data.recipeList[id].reagentData[i] = {}
						Skillet.data.recipeList[id].reagentData[i].id = itemID
						Skillet.data.recipeList[id].reagentData[i].name = GetItemInfo(itemID)
						Skillet.data.recipeList[id].reagentData[i].numNeeded = tonumber(reagentList[2 + (i-1)*2])
					end
				end
			else
				DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			if toolString then
				if toolString ~= "-" then
					Skillet.data.recipeList[id].tools = {}
					local toolList = { string.split(":",toolString) }
					for i=1,#toolList do
						Skillet.data.recipeList[id].tools[i] = string.gsub(toolList[i],"_"," ")
					end
				end
			else
				DA.DEBUG(0,"id= "..tostring(id)..", recipeString= "..tostring(recipeString))
			end
			return Skillet.data.recipeList[id]
		end
	end
	return Skillet.unknownRecipe
end

function Skillet:GetNumSkills(player, trade)
	--DA.DEBUG(3,"GetNumSkills("..tostring(player)..", "..tostring(trade).."), tradeName= "..tostring(self.tradeSkillNamesByID[trade]))
	local r
	if not Skillet.db.realm.skillDB[player] then
		r = 0
	elseif not Skillet.db.realm.skillDB[player][trade] then
		r = 0
	else
		r = #Skillet.db.realm.skillDB[player][trade]
	end
	--DA.DEBUG(3,"GetNumSkills= "..tostring(r))
	return r
end

function Skillet:GetSkillRanks(player, trade)
	--DA.DEBUG(3,"GetSkillRanks("..tostring(player)..", "..tostring(trade)..")")
	if player and trade then
		if Skillet.db.realm.tradeSkills[player] then
			return Skillet.db.realm.tradeSkills[player][trade]
		end
	end
end

function Skillet:GetSkill(player,trade,index)
	--DA.DEBUG(0,"GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	if not index then return end
	if (player and trade and index) then
		if not Skillet.data.skillList[player] then
			Skillet.data.skillList[player] = {}
		end
		if not Skillet.data.skillList[player][trade] then
			Skillet.data.skillList[player][trade] = {}
		end
		if not Skillet.data.skillList[player][trade][index] and Skillet.db.realm.skillDB[player][trade][index] then
			local skillString = Skillet.db.realm.skillDB[player][trade][index]
			if skillString then
				local skill = {}
				--DA.DEBUG(0,"skillString= '"..skillString.."'")
				local skillData = { string.split("@", skillString) }
				--DA.DEBUG(0,"skillData= "..DA.DUMP1(skillData))
				local skillHeader = { string.split(" ", skillData[1]) }
				if skillHeader[1] == "header" or skillHeader[1] == "subheader" then
					skill.id = 0
					skill.index = index
				else
					local difficulty = string.sub(skillData[1],1,1)
					local recipeID = string.sub(skillData[1],2)
					skill.id = recipeID
					skill.index = index
					skill.difficulty = DifficultyText[difficulty]
					skill.color = skill_style_type[DifficultyText[difficulty]]
					skill.tools = nil
					for i=2,#skillData do
						local subData = { string.split("=",skillData[i]) }
						if subData[1] == "cd" then
							skill.cooldown = tonumber(subData[2])
						elseif subData[1] == "t" then
							skill.tools = {}
							for j=1,string.len(subData[2]) do
								local missingTool = tonumber(string.sub(subData[2],j,j))
								skill.tools[missingTool] = true
							end
						end
					end
				end
				Skillet.data.skillList[player][trade][index] = skill
			end
		end
		--DA.DEBUG(0,"GetSkill= "..DA.DUMP1(Skillet.data.skillList[player][trade][index]))
		return Skillet.data.skillList[player][trade][index]
	end
	--DA.DEBUG(0,"GetSkill= "..DA.DUMP1(self.unknownRecipe))
	return self.unknownRecipe
end

--
-- takes a profession and a skill index and returns the recipe
--
function Skillet:GetRecipeDataByTradeIndex(tradeID, index)
	--DA.DEBUG(2,"GetRecipeDataByTradeIndex("..tostring(tradeID)..", "..tostring(index)..")")
	if not tradeID or not index then
		return self.unknownRecipe
	end
	local skill = self:GetSkill(self.currentPlayer, tradeID, index)
	if skill then
		local recipeID = skill.id
		if recipeID then
			local recipeData = self:GetRecipe(recipeID)
			--DA.DEBUG(2,"GetRecipeDataByTradeIndex= "..DA.DUMP1(recipeData))
			return recipeData, recipeData.spellID, recipeData.ItemID
		end
	end
	return self.unknownRecipe
end

function Skillet:CalculateCraftableCounts()
	--DA.DEBUG(0,"CalculateCraftableCounts()")
	local player = self.currentPlayer
	self.visited = {}
	local n = self:GetNumSkills(player, self.currentTrade)
	if n then
		for i=1,n do
			local skill = self:GetSkill(player, self.currentTrade, i)
			if skill then -- skip headers
				skill.numCraftable, skill.numRecursive, skill.numCraftableVendor, skill.numCraftableAlts = self:InventorySkillIterations(self.currentTrade, i, player)
				--DA.DEBUG(2,"name= "..tostring(skill.name)..", numCraftable= "..tostring(skill.numCraftable)..", numRecursive= "..tostring(skill.numRecursive)..", numCraftableVendor= "..tostring(skill.numCraftableVendor)..", numCraftableAlts= "..tostring(skill.numCraftableAlts))
			end
		end
	end
	--DA.DEBUG(0,"CalculateCraftableCounts Complete")
end

--
-- This is a local function only called from Skillet:ReScanTrade() which
-- is defined after this one
--
local function ScanTrade()
	--DA.DEBUG(2,"ScanTrade()")
	local profession, rank, maxRank
	if Skillet.isCraft then
		profession, rank, maxRank = GetCraftDisplaySkillLine()
	else
		profession, rank, maxRank = GetTradeSkillLine()
	end
	--DA.DEBUG(2,"profession= "..tostring(profession)..", rank= "..tostring(rank)..", maxRank= "..tostring(maxRank))
	if profession == "UNKNOWN" then
		return false
	end
	local tradeID = Skillet.tradeSkillIDsByName[profession]
	local player = Skillet.currentPlayer
	local numSkills = GetNumTradeSkills()
	local numCrafts = GetNumCrafts()
	--DA.DEBUG(2,"numSkills= "..tostring(numSkills)..", numCrafts= "..tostring(numCrafts))
--
-- First, loop through all the recipes and make sure they are expanded
--
	for i = 1, numSkills do
		local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i)
		--DA.DEBUG(2,"i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
		if skillType == "header" or skillType == "subheader" then
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
			end
		end
	end
	for i = 1, numCrafts do
		local skillName, skillType, numAvailable, isExpanded = GetCraftInfo(i)
		--DA.DEBUG(2,"i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
		if skillType == "header" or skillType == "subheader" then
			if not isExpanded then
				ExpandCraftSubClass(i)
			end
		end
	end
	if Skillet.isCraft then
		numSkills = GetNumCrafts()
	else
		numSkills = GetNumTradeSkills()
	end
	--DA.DEBUG(2,"Scanning Trade "..tostring(profession)..": "..tostring(tradeID).." "..numSkills.." recipes")
	local skillDB = Skillet.db.realm.skillDB[player][tradeID]
	local subClass = Skillet.db.realm.subClass[player][tradeID]
	local invSlot = Skillet.db.realm.invSlot[player][tradeID]
	local skillData = Skillet.data.skillList[player][tradeID]
	local recipeDB = Skillet.db.global.recipeDB
	if not skillData then
		return false
	end
	local lastHeader = nil
	local gotNil = false
	local currentGroup = nil
	local mainGroup = Skillet:RecipeGroupNew(player,tradeID,"Blizzard")
	mainGroup.locked = true
	mainGroup.autoGroup = true
	Skillet:RecipeGroupClearEntries(mainGroup)
	local groupList = {}
--	Skillet.db.realm.tradeSkills[player][tradeID].link = link		-- Classic has no link for the profession
	Skillet.db.realm.tradeSkills[player][tradeID].name = profession
	Skillet.db.realm.tradeSkills[player][tradeID].rank = rank
	Skillet.db.realm.tradeSkills[player][tradeID].maxRank = maxRank
	Skillet.db.realm.tradeSkills[player][tradeID].isCraft = Skillet.isCraft
--
-- Mining and Smelting have a bipolar relationship 
--
	if tradeID == MINING then
		if not Skillet.db.realm.tradeSkills[player][SMELTING] then
			Skillet.db.realm.tradeSkills[player][SMELTING] = {}
		end
		Skillet.db.realm.tradeSkills[player][tradeID].name = "Smelting ("..profession..")"
		Skillet.db.realm.tradeSkills[player][SMELTING].rank = rank
		Skillet.db.realm.tradeSkills[player][SMELTING].maxRank = maxRank
	end
	local numHeaders = 0
	local parentGroup
	local numSubClass = {}
	local numInvSlot = {}
--
-- Now actually process each recipe (skill)
--
	for i = 1, numSkills, 1 do
		local _, skillName, skillType, numAvailable, isExpanded, subSpell, extra
		if Skillet.isCraft then
--
-- GetCraftInfo() returns are: craftName, craftSubSpellName, craftType, numAvailable, isExpanded, trainingPointCost, requiredLevel
--
			skillName, _, skillType, numAvailable, isExpanded = GetCraftInfo(i)
		else
			skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i)
		end
		--DA.DEBUG(2,"i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
		if skillName then
			if skillType == "header" or skillType == "subheader" then
--
-- for headers (and subheaders) define groups and
-- add a header entry in the skillDB (SavedVariables)
--
				numHeaders = numHeaders + 1
				lastHeader = skillName
				local groupName
				if groupList[skillName] then
					groupList[skillName] = groupList[skillName]+1
					groupName = skillName.." "..groupList[skillName]
				else
					groupList[skillName] = 1
					groupName = skillName
				end
				skillDB[i] = "header "..skillName
				skillData[i] = nil
				currentGroup = Skillet:RecipeGroupNew(player, tradeID, "Blizzard", groupName)
				currentGroup.autoGroup = true
				if skillType == "header" then
					parentGroup = currentGroup
					Skillet:RecipeGroupAddSubGroup(mainGroup, currentGroup, i)
				else
					Skillet:RecipeGroupAddSubGroup(parentGroup, currentGroup, i)
				end
			else
--
-- In Classic, recipes do not have a numerical ID so
-- use the name as the id and 
-- (break everything than assumes it is a number)
--
				local recipeID = skillName
				if currentGroup then
					Skillet:RecipeGroupAddRecipe(currentGroup, recipeID, i)
				else
					Skillet:RecipeGroupAddRecipe(mainGroup, recipeID, i)
				end
--
-- break recipes into lists and tables by profession for ease of sorting
--
-- SavedVariables:
--   skillDB(skillDBstring) fields are separated by "|"
--   recipeDB (recipeString) list by recipeID of fields separated by " ",
--     (tools have spaces replaced by "_")
--   ItemDataAddUsedInRecipe(reagentID, recipeID)  -- add a cross reference for where a particular item is used
--   ItemDataAddRecipeSource(itemID,recipeID)      -- add a cross reference for the source of particular items
--
-- Temporary (data):
--   skillData is a table
--   skillIndexLookup contains the (player specific) spellIndex of the recipe
--   recipeList is a list of "recipe" tables
--
				skillData[i] = {}
				skillData[i].name = skillName
				skillData[i].id = recipeID
				skillData[i].difficulty = skillType
				skillData[i].color = skill_style_type[skillType]
				skillData[i].category = lastHeader
				local skillDBString = DifficultyChar[skillType]..recipeID
				local tools
				if Skillet.isCraft then
					tools = { GetCraftSpellFocus(i) }
				else
					tools = { GetTradeSkillTools(i) }
				end
				skillData[i].tools = {}
				local slot = 1
				for t=2,#tools,2 do
					skillData[i].tools[slot] = (tools[t] or 0)
					slot = slot + 1
				end
				if not Skillet.isCraft then
					local cd = GetTradeSkillCooldown(i)
					if cd then
						skillData[i].cooldown = cd + time()		-- this is when your cooldown will be up
						skillDBString = skillDBString.."@cd="..cd + time()
					end
				end
				local numTools = #tools+1
				if numTools > 1 then
					local toolString = ""
					local toolsAbsent = false
					local slot = 1
					for t=2,numTools,2 do
						if not tools[t] then
							toolsAbsent = true
							toolString = toolString..slot
						end
						slot = slot + 1
					end
					if toolsAbsent then										-- only point out missing tools
						skillDBString = skillDBString.."@t="..toolString
					end
				end
				skillDB[i] = skillDBString
				Skillet.data.skillIndexLookup[player][recipeID] = i
				Skillet.data.recipeList[recipeID] = {}
				local recipe = Skillet.data.recipeList[recipeID]
				local recipeString
				local toolString = "-"
				recipe.tradeID = tradeID
				recipe.spellID = recipeID
				recipe.name = skillName
				if #tools >= 1 then
					recipe.tools = { tools[1] }
					toolString = string.gsub(tools[1]," ", "_")
					for t=3,#tools,2 do
						table.insert(recipe.tools, tools[t])
						toolString = toolString..":"..string.gsub(tools[t]," ", "_")
					end
				end
				local itemLink
				if Skillet.isCraft then
					itemLink = GetCraftItemLink(i)
				else
					itemLink = GetTradeSkillItemLink(i)
				end
				if not itemLink then
					DA.DEBUG(0,"break caused by no itemLink")
					break
				end
				local itemString = "0"
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
				  itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, 
				  isCraftingReagent = GetItemInfo(itemLink)
--[[
				1. itemName
				String - The localized name of the item.
				2. itemLink
				String - The localized item link of the item.
				3. itemRarity
				Number - The quality of the item. The value is 0 to 7, which represents Poor to Heirloom. This appears to include gains from upgrades/bonuses.
				4. itemLevel
				Number - The base item level of this item, not including item levels gained from upgrades. Use GetDetailedItemLevelInfo to get the actual current level of the item.
				5. itemMinLevel
				Number - The minimum level required to use the item, 0 meaning no level requirement.
				6. itemType
				String - The localized type of the item: Armor, Weapon, Quest, Key, etc.
				7. itemSubType
				String - The localized sub-type of the item: Enchanting, Cloth, Sword, etc. See itemType.
				8. itemStackCount
				Number - How many of the item per stack: 20 for Runecloth, 1 for weapon, 100 for Alterac Ram Hide, etc.
				9. itemEquipLoc
				String - The type of inventory equipment location in which the item may be equipped, or "" if it can't be equippable. The string returned is also the name of a global string variable e.g. if "INVTYPE_WEAPONMAINHAND" is returned, _G["INVTYPE_WEAPONMAINHAND"] will be the localized, displayable name of the location.
				10. itemIcon
				Number (fileID) - The icon texture for the item.
				11. itemSellPrice
				Number - The price, in copper, a vendor is willing to pay for this item, 0 for items that cannot be sold.
				12. itemClassID
				Number - This is the numerical value that determines the string to display for 'itemType'.
				13. itemSubClassID
				Number - This is the numerical value that determines the string to display for 'itemSubType'
				14. bindType
				Number - Item binding type: 0 - none; 1 - on pickup; 2 - on equip; 3 - on use; 4 - quest.
				15. expacID
				Number - ?
				16. itemSetID
				Number - ?
				17. isCraftingReagent
				Boolean - ?
]]--
				if itemName then
					local itemID = Skillet:GetItemIDFromLink(itemLink)
					local minMade,maxMade
					if Skillet.isCraft then
						minMade,maxMade = GetCraftNumMade(i)
					else
						minMade,maxMade = GetTradeSkillNumMade(i)
					end
					recipe.itemID = itemID
					recipe.numMade = (minMade + maxMade)/2
					if recipe.numMade > 1 then
						itemString = itemID..":"..recipe.numMade
					else
						itemString = itemID
					end
					Skillet:ItemDataAddRecipeSource(itemID,recipeID) -- add a cross reference for the source of particular items
--
-- Our own filter data: subClass, invSlot
--
					if itemSubType then
						if not subClass.name then
							subClass.name = {}
						end
						numSubClass[itemSubType] = (numSubClass[itemSubType] or 0) + 1
						subClass.name[itemSubType] = numSubClass[itemSubType]
						subClass[itemID] = itemSubType
					end
					if itemEquipLoc then
						if not invSlot.name then
							invSlot.name = {}
						end
						numInvSlot[itemEquipLoc] = (numInvSlot[itemEquipLoc] or 0) + 1
						invSlot.name[itemEquipLoc] = numInvSlot[itemEquipLoc]
						invSlot[itemID] = itemEquipLoc
					end
--[[
--
-- Not implemented in Classic
--
				else
					recipe.numMade = 1
					if Skillet.scrollData[recipeID] then
						local itemID = Skillet.scrollData[recipeID]
						recipe.itemID = itemID
						itemString = itemID
						Skillet:ItemDataAddRecipeSource(itemID,recipeID)	-- add a cross reference for the source of particular items
					else
						recipe.itemID = 0									-- indicates an enchant
					end
]]--
				end
				local reagentString = "-"
				local reagentData = {}
				local numReagents
				if Skillet.isCraft then
					numReagents = GetCraftNumReagents(i)
				else
					numReagents = GetTradeSkillNumReagents(i)
				end
				--DA.DEBUG(2,"i= "..tostring(i)..", numReagents= "..tostring(numReagents))
				for j=1, numReagents, 1 do
					local reagentName, _, numNeeded
					if Skillet.isCraft then
						reagentName, _, numNeeded = GetCraftReagentInfo(i,j)	-- reagentName, reagentTexture, reagentCount, playerReagentCount
					else
						reagentName, _, numNeeded = GetTradeSkillReagentInfo(i,j)
					end
					--DA.DEBUG(2,"i= "..tostring(i)..", j= "..tostring(j)..", reagentName= "..tostring(reagentName)..", numNeeded= "..tostring(numNeeded))
					local reagentID = 0
					if reagentName then
						local reagentLink
						if Skillet.isCraft then
							reagentLink = GetCraftReagentItemLink(i,j)
						else
							reagentLink = GetTradeSkillReagentItemLink(i,j)
						end
						--DA.DEBUG(2,"reagentLink= "..DA.PLINK(reagentLink))
						reagentID = Skillet:GetItemIDFromLink(reagentLink)
					else
						gotNil = true
						break
					end
					reagentData[j] = {}
					reagentData[j].id = reagentID
					reagentData[j].numNeeded = numNeeded
					if reagentString ~= "-" then
						reagentString = reagentString..":"..reagentID..":"..numNeeded
					else
						reagentString = reagentID..":"..numNeeded
					end
					Skillet:ItemDataAddUsedInRecipe(reagentID, recipeID)	-- add a cross reference for where a particular item is used
				end
				recipe.reagentData = reagentData
				recipeString = tradeID.." "..itemString.." "..reagentString
				if #tools then
					recipeString = recipeString.." "..toolString
				end
				recipeDB[recipeID] = recipeString
			end
		end
	end
--
-- SkilletMemory is a saved variable snapshot of data tables
--
	if DA.deepcopy then
		SkilletMemory.groupList1 = {}
		SkilletMemory.groupList1 = DA.deepcopy(Skillet.data.groupList)
	end
--
-- all the lists have been built so
-- use them to collect information based
-- on the player's inventory
--
	Skillet:InventoryScan()
	Skillet:CalculateCraftableCounts()
	Skillet:SortAndFilterRecipes()
	--DA.DEBUG(2,"ScanTrade Complete, numSkills= "..tostring(numSkills)..", numHeaders= "..tostring(numHeaders))
--
-- return a boolean:
--   true means we got good data for this profession (skill)
--   false means there was no data available
-- Note: Enchanting (the only Craft) has no headers
--
	if not Skillet.isCraft and numHeaders == 0 then
		skillData.scanned = false
		return false
	end
	skillData.scanned = true
	return true
end

--
-- This is the global function everyone else should use
--
function Skillet:RescanTrade()
	--DA.DEBUG(0,"RescanTrade()")
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not player or not tradeID then return end
--
-- Make sure all the data structures exist
--
--	if not Skillet.data.skillList[player] then
--		Skillet.data.skillList[player] = {}
--	end
	if not Skillet.data.skillList[player][tradeID] then
		Skillet.data.skillList[player][tradeID]={}
	end
--	if not Skillet.data.skillIndexLookup[player] then
--		Skillet.data.skillIndexLookup[player] = {}
--	end
--	if not Skillet.db.realm.skillDB[player] then
--		Skillet.db.realm.skillDB[player] = {}
--	end
	if not Skillet.db.realm.skillDB[player][tradeID] then
		Skillet.db.realm.skillDB[player][tradeID] = {}
	end
--	if not Skillet.db.realm.tradeSkills[player] then
--		Skillet.db.realm.tradeSkills[player] = {}
--	end
	if not Skillet.db.realm.tradeSkills[player][tradeID] then
		Skillet.db.realm.tradeSkills[player][tradeID] = {}
	end
--
-- Our own filter data: subClass, invSlot
--
--	if not Skillet.db.realm.subClass[player] then
--		Skillet.db.realm.subClass[player] = {}
--	end
	if not Skillet.db.realm.subClass[player][tradeID] then
		Skillet.db.realm.subClass[player][tradeID] = {}
	end
--	if not Skillet.db.realm.invSlot[player] then
--		Skillet.db.realm.invSlot[player] = {}
--	end
	if not Skillet.db.realm.invSlot[player][tradeID] then
		Skillet.db.realm.invSlot[player][tradeID] = {}
	end
--
-- Reset Blizzard's filters because they will effect what
-- data gets returned
--
	if TradeSkillSubClassDropDown then
		UIDropDownMenu_SetSelectedID(TradeSkillSubClassDropDown, 1)
	end
	if TradeSkillInvSlotDropDown then
		UIDropDownMenu_SetSelectedID(TradeSkillInvSlotDropDown, 1)
	end
--
-- Now the hard work begins
--
	Skillet.scanInProgress = true
	Skillet.dataScanned = ScanTrade()	-- local function that does all the work
	Skillet.scanInProgress = false
	return Skillet.dataScanned
end
