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

-- a table of tradeskills by id
local TradeSkillList = {
	2259,		-- alchemy
	2018,		-- blacksmithing
--	7411,		-- enchanting
	4036,		-- engineering
	45357,		-- inscription
	25229,		-- jewelcrafting
	2108,		-- leatherworking
	2656,		-- smelting (from mining, 2575)
	2575,		-- mining
	3908,		-- tailoring
	2550,		-- cooking
	3273,		-- first aid
	53428,		-- runeforging
}

Skillet.TradeSkillAdditionalAbilities = {
--	[7411]	= {13262,"Disenchant"},		-- enchanting = disenchant
	[2550]	= {818,"Basic_Campfire"},	-- cooking = basic campfire
	[45357] = {51005,"Milling"},		-- inscription = milling
	[25229] = {31252,"Prospecting"},	-- jewelcrafting = prospecting
	[2018]	= {126462,"Thermal Anvil"},	 -- blacksmithing = thermal anvil (item:87216)
	[4036]	= {126462,"Thermal Anvil"},	 -- engineering = thermal anvil (item:87216)
	[2656]	= {126462,"Thermal Anvil"},	 -- smelting = thermal anvil (item:87216)
}
Skillet.AutoButtonsList = {}
Skillet.TradeSkillAutoTarget = {
--
-- None of these "features" exist in Classic
--
]]--
}

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

Skillet.scrollData = {
--[[
	-- Scraped from WoWhead using the following javascript:
	-- for (i=0; i<listviewitems.length; i++) console.log("["+listviewitems[i].sourcemore[0].ti+"] = "+listviewitems[i].id+", 
	-- "+listviewitems[i].name.substr(1));
]]--
}

local TradeSkillIDsByName = {}		-- filled in with ids and names for reverse matching (since the same name has multiple id's based on level)
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

local lastAutoTarget = {}
function Skillet:GetAutoTargetItem(tradeID)
	if Skillet.TradeSkillAutoTarget[tradeID] then
		local itemID = lastAutoTarget[tradeID]
		if itemID then
			local limit	 = Skillet.TradeSkillAutoTarget[tradeID][itemID]
			local count = GetItemCount(itemID)
			if count >= limit then
				return itemID
			end
		end
		for itemID,limit in pairs(Skillet.TradeSkillAutoTarget[tradeID]) do
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

-- adds an recipe source for an itemID (recipeID produces itemID)
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

-- adds a recipe usage for an itemID (recipeID uses itemID as a reagent)
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

-- goes thru the stored recipe list and collects reagent and item information as well as skill lookups
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
--				local skillData = self:GetSkill(player, trade, i)
				local skillString = self.db.realm.skillDB[player][trade][i]
				if skillString then
					local skillData = string.split(" ",skillString)
					if skillData ~= "header" or skillData ~= "subheader" then
						local recipeID = string.sub(skillData,2)
						recipeID = tonumber(recipeID) or 0
						self.data.skillIndexLookup[player][recipeID] = i
					end
				end
			end
		end
	end
end

-- Checks to see if the current trade is one that we support.
function Skillet:IsSupportedTradeskill(tradeID)
	if IsShiftKeyDown() or not tradeID or tradeID == 5419 or tradeID == 53428 then
		return false
	end
	return true
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

-- queries for vendor info for a particular itemID
function Skillet:VendorSellsReagent(itemID)
-- Check our local data first
	if missingVendorItems[itemID] or specialVendorItems[itemID] then
		return true
	end
-- Check the LibPeriodicTable data next
	if PT then
		if itemID ~= 0 and PT:ItemInSet(itemID,"Tradeskill.Mat.BySource.Vendor") then
			return true
		end
	end
	return false
end

-- resets the blizzard tradeskill search filters just to make sure no other addon has monkeyed with them
function Skillet:ExpandTradeSkillSubClass(i)
	--DA.DEBUG(0,"Skillet:ExpandTradeSkillSubClass "..tostring(i))
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
	--DA.DEBUG(0,"Skillet:GetRecipe("..tostring(id)..")")
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
						Skillet.data.recipeList[id].reagentData[i] = {}
						Skillet.data.recipeList[id].reagentData[i].id = tonumber(reagentList[1 + (i-1)*2])
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
	DA.DEBUG(0,"Skillet:GetNumSkills("..tostring(player)..", "..tostring(trade)..")")
	local r
	if not Skillet.db.realm.skillDB[player] then
		r = 0
	elseif not Skillet.db.realm.skillDB[player][trade] then
		r = 0
	else
		r = #Skillet.db.realm.skillDB[player][trade]
	end
	DA.DEBUG(2,"r= "..tostring(r))
	return r
end

function Skillet:GetSkillRanks(player, trade)
	--DA.PROFILE("Skillet:GetSkillRanks("..tostring(player)..", "..tostring(trade)..")")
	if player and trade then
		if Skillet.db.realm.tradeSkills[player] then
			return Skillet.db.realm.tradeSkills[player][trade]
		end
	end
end

function Skillet:GetSkill(player,trade,index)
	--DA.PROFILE("Skillet:GetSkill("..tostring(player)..", "..tostring(trade)..", "..tostring(index)..")")
	if player and trade and index then
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
				local data = { string.split(" ",skillString) }
				if data[1] == "header" or data[1] == "subheader" then
					skill.id = 0
				else
					local difficulty = string.sub(data[1],1,1)
					local recipeID = string.sub(data[1],2)
					skill.id = tonumber(recipeID)
					skill.difficulty = DifficultyText[difficulty]
					skill.color = skill_style_type[DifficultyText[difficulty]]
					skill.tools = nil
					recipeID = tonumber(recipeID)
					for i=2,#data do
						local subData = { string.split("=",data[i]) }
						if subData[1] == "cd" then
							skill.cooldown = tonumber(subData[2])
						elseif subData[1] == "t" then
							local recipe = Skillet:GetRecipe(recipeID)
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
		return Skillet.data.skillList[player][trade][index]
	end
	return self.unknownRecipe
end

-- collects generic tradeskill data (id to name and name to id)
function Skillet:CollectTradeSkillData()
	DA.DEBUG(0,"CollectTradeSkillData()")
	for i=1,#TradeSkillList,1 do
		local id = TradeSkillList[i]
		local name = GetSpellInfo(id)
		--DA.DEBUG(1,"id= "..tostring(id)..", name= "..tostring(name))
		if name then
			TradeSkillIDsByName[name] = id
		end
	end
	self.tradeSkillIDsByName = TradeSkillIDsByName
	self.tradeSkillList = TradeSkillList
end

-- this routine collects the basic data (which tradeskills a player has)
function Skillet:ScanPlayerTradeSkills(player)
	DA.DEBUG(0,"Skillet:ScanPlayerTradeSkills("..tostring(player)..")")
	if player == (UnitName("player")) then -- only for active player
		if not Skillet.db.realm.tradeSkills[player] then
			Skillet.db.realm.tradeSkills[player] = {}
		end
		local skillRanksData = Skillet.db.realm.tradeSkills[player]
		for i=1,#TradeSkillList,1 do
			local id = TradeSkillList[i]
			local name = GetSpellInfo(id)				-- always returns data
			if name then
				local tradeName = GetSpellInfo(name)	-- only returns data if you have this spell in your spellbook
				if tradeName then
					DA.DEBUG(0,"Collecting tradeskill data for: "..tostring(name))
					if not skillRanksData[id] then
						skillRanksData[id] = {}
						skillRanksData[id].rank = 0
						skillRanksData[id].maxRank = 0
					end
				else
					DA.DEBUG(0,"Skipping tradeskill data for: "..tostring(name))
					skillRanksData[id] = nil
				end
			end
		end
		if not Skillet.db.realm.faction then
			Skillet.db.realm.faction = {}
		end
		Skillet.db.realm.faction[player] = UnitFactionGroup("player")
	end
end

-- takes a profession and a skill index and returns the recipe
function Skillet:GetRecipeDataByTradeIndex(tradeID, index)
	if not tradeID or not index then
		return self.unknownRecipe
	end
	local skill = self:GetSkill(self.currentPlayer, tradeID, index)
	if skill then
		local recipeID = skill.id
		if recipeID then
			local recipeData = self:GetRecipe(recipeID)
			return recipeData, recipeData.spellID, recipeData.ItemID
		end
	end
	return self.unknownRecipe
end

function Skillet:ContinueCastCheckUnit(event, unit, spell, rank)
	--DA.DEBUG(0,"ContinueCastCheckUnit "..(unit or "nil"))
	if unit == "player" and spell==self.processingSpell then
		self:ContinueCast(spell)
		-- AceEvent:ScheduleEvent("Skillet_StopCast", self.StopCast, 0.1,self,event,spell)
	end
end

function Skillet:StopCastCheckUnit(event, unit, spell, rank)
	if unit == "player" then
		self:StopCast(spell)
		-- AceEvent:ScheduleEvent("Skillet_StopCast", self.StopCast, 0.1,self,event,spell)
	end
end

local rescan_time = 1
-- Internal
-- scan trade, if it fails, rescan after 1 sek, if it fails, rescan after 5 sek and give up
function Skillet:Skillet_AutoRescan()
	Skillet.scheduleRescan = false
	local start = GetTime()
	DA.DEBUG(0,"Skillet_AutoRescan Start")
	if InCombatLockdown() or not SkilletFrame:IsVisible() then
		self.auto_rescan_timer = nil
		return
	end
	local scanResult = self:RescanTrade()
	if not scanResult or Skillet.scheduleRescan then
		if rescan_time > 5 then
			rescan_time = 1
			self.auto_rescan_timer = nil
			return
		end
		self.auto_rescan_timer = self:ScheduleTimer("Skillet_AutoRescan", rescan_time)
		rescan_time = rescan_time + 4
	else
		rescan_time = 1
		self.auto_rescan_timer = nil
		self:UpdateTradeSkillWindow()
	end
	local elapsed = GetTime() - start
	DA.DEBUG(1,"Skillet_AutoRescan complete in "..(math.floor(elapsed*100+.5)/100).." seconds")
end

function Skillet:CalculateCraftableCounts(playerOverride)
	DA.DEBUG(0,"CalculateCraftableCounts("..tostring(playerOverride)..")")
	local player = playerOverride or self.currentPlayer
	--DA.DEBUG(0,tostring(player).." "..tostring(self.currentTrade))
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
	DA.DEBUG(0,"CalculateCraftableCounts Complete")
end

function Skillet:RescanTrade()
	--DA.PROFILE("Skillet:RescanTrade()")
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not player or not tradeID then return end
	Skillet.scanInProgress = true
	if not Skillet.data.skillList[player] then
		Skillet.data.skillList[player] = {}
	end
	if not Skillet.data.skillList[player][tradeID] then
		Skillet.data.skillList[player][tradeID]={}
	end
	if not Skillet.db.realm.skillDB[player] then
		Skillet.db.realm.skillDB[player] = {}
	end
	if not Skillet.db.realm.skillDB[player][tradeID] then
		Skillet.db.realm.skillDB[player][tradeID] = {}
	end
	Skillet.dataScanned = self:ScanTrade()
	Skillet.scanInProgress = false
	return Skillet.dataScanned
end

function Skillet:ScanTrade()
	DA.DEBUG(0,"Skillet:ScanTrade()")
	local profession, rank, maxRank = GetTradeSkillLine()
	local tradeID = self.tradeSkillIDsByName[profession]
	local player = Skillet.currentPlayer
	local numSkills = GetNumTradeSkills()
	for i = 1, numSkills do
		local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i)
		DA.DEBUG(3,"i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
		if skillType == "header" or skillType == "subheader" then
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
			end
		end
	end
	numSkills = GetNumTradeSkills()
	DA.DEBUG(0,"Scanning Trade "..tostring(profession)..": "..tostring(tradeID).." "..numSkills.." recipes")
	if not Skillet.data.skillIndexLookup[player] then
		Skillet.data.skillIndexLookup[player] = {}
	end
	local skillDB = Skillet.db.realm.skillDB[player][tradeID]
	local skillData = Skillet.data.skillList[player][tradeID]
	local recipeDB = Skillet.db.global.recipeDB
	if not skillData then
		self.scanInProgress = false
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
	if not Skillet.db.realm.tradeSkills[player] then
		Skillet.db.realm.tradeSkills[player] = {}
	end
	if not Skillet.db.realm.tradeSkills[player][tradeID] then
		Skillet.db.realm.tradeSkills[player][tradeID] = {}
	end
	local skillName, rank, maxRank = GetTradeSkillLine()
--	Skillet.db.realm.tradeSkills[player][tradeID].link = link
	Skillet.db.realm.tradeSkills[player][tradeID].rank = rank
	Skillet.db.realm.tradeSkills[player][tradeID].maxRank = maxRank
	local numHeaders = 0
	local parentGroup
	for i = 1, numSkills, 1 do
		local skillName, skillType, isExpanded, subSpell, extra
		local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i);
		DA.DEBUG(0,i.." "..skillName)
		DA.DEBUG(3,"i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
		if skillName then
			if skillType == "header" or skillType == "subheader" then
				numHeaders = numHeaders + 1
				if not isExpanded then
					ExpandTradeSkillSubClass(i)
				end
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
				local recipeID = skillName
				if currentGroup then
					Skillet:RecipeGroupAddRecipe(currentGroup, recipeID, i)
				else
					Skillet:RecipeGroupAddRecipe(mainGroup, recipeID, i)
				end
				-- break recipes into lists by profession for ease of sorting
				skillData[i] = {}
				skillData[i].name = skillName
				skillData[i].id = recipeID
				skillData[i].noRecipe = noRecipe
				skillData[i].difficulty = skillType
				skillData[i].color = skill_style_type[skillType]
				skillData[i].category = lastHeader
				local skillDBString = DifficultyChar[skillType]..recipeID
				local tools = { GetTradeSkillTools(i) }
				skillData[i].tools = {}
				local slot = 1
				for t=2,#tools,2 do
					skillData[i].tools[slot] = (tools[t] or 0)
					slot = slot + 1
				end
				local cd = GetTradeSkillCooldown(i)
				if cd then
					skillData[i].cooldown = cd + time()		-- this is when your cooldown will be up
					skillDBString = skillDBString.." cd=" .. cd + time()
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
						skillDBString = skillDBString.." t="..toolString
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
				local itemLink = GetTradeSkillItemLink(i)
				if not itemLink then
					break
				end
				local itemString = "0"
				if GetItemInfo(itemLink) then
					local itemID = Skillet:GetItemIDFromLink(itemLink)
					local minMade,maxMade = GetTradeSkillNumMade(i)
					recipe.itemID = itemID
					recipe.numMade = (minMade + maxMade)/2
					if recipe.numMade > 1 then
						itemString = itemID..":"..recipe.numMade
					else
						itemString = itemID
					end
					Skillet:ItemDataAddRecipeSource(itemID,recipeID) -- add a cross reference for the source of particular items
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
				end
				local reagentString = "-"
				local reagentData = {}
				for j=1, GetTradeSkillNumReagents(i), 1 do
					local reagentName, _, numNeeded = GetTradeSkillReagentInfo(i,j)
					local reagentID = 0
					if reagentName then
						local reagentLink = GetTradeSkillReagentItemLink(i,j)
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
	DA.DEBUG(0,"SkilletData:ScanTrade Complete, numSkills= "..tostring(numSkills)..", numHeaders= "..tostring(numHeaders))

	if DA.deepcopy then
		SkilletMemory.groupList1 = {}
		SkilletMemory.groupList1 = DA.deepcopy(Skillet.data.groupList)
	end

	Skillet:InventoryScan()
	Skillet:CalculateCraftableCounts()
	Skillet:SortAndFilterRecipes()
	DA.DEBUG(0,"all sorted")
	self.scanInProgress = false
	if numHeaders == 0 then
		skillData.scanned = false
		return false
	end
	skillData.scanned = true
	return true
end
