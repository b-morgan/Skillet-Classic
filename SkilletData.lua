local addonName,addonTable = ...
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local DA
if isRetail then
	DA = _G[addonName] -- for DebugAids.lua
else
	DA = LibStub("AceAddon-3.0"):GetAddon("Skillet") -- for DebugAids.lua
end
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
	25229,		-- jewelcrafting
	45357,		-- inscription
	53428,		-- runeforging
}

--
-- a table of crafts by id
-- Enchanting is a Craft in Classic Era, Season of Mastery, Burning Crusade Classic
-- and a TradeSkill in Wrath of the Lich King Classic
-- This will be fixed in CollectTradeSkillData()
--
local CraftList = {
--	5149,		-- beast training
	7411,		-- enchanting (Blizzard has restricted DoCraft(index) to anything but their own UI)
}

--
--  a table of locale specific translations by id
-- needed to fix Blizzard inconsistent translations
--
-- [tradeID] = {locale, old, new}
--   locale is what GetLocale() returns
--   old is the return from GetSpellInfo(tradeID)
--   new is the return from GetTradeSkillLine() when the tradeskill / craft is opened
--
local TranslateList = {
	[4036] = {"frFR", "Ingénieur", "Ingénierie"},			-- engineering
	[3273] = {"frFR", "Premiers soins", "Secourisme"},		-- first aid
	[2108] = {"esES", "Peletería", "Marroquinería"},		-- leatherworking
	[3908] = {"esES", "Sastrería", "Costura"},				-- tailoring
	[2108] = {"koKR", "가죽세공", "가죽 세공"},					-- leatherworking
}

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
	self.tradeSkillIDsByName = {}
	self.tradeSkillNamesByID = {}
	for i=1,#TradeSkillList,1 do
		local id = TradeSkillList[i]
		local name = GetSpellInfo(id)
		--DA.DEBUG(2,"id= "..tostring(id)..", name= "..tostring(name))
		if name then
			table.insert(self.tradeSkillList,id)
			self.skillIsCraft[id] = false
			self.tradeSkillIDsByName[name] = id
			self.tradeSkillNamesByID[id] = name
		end
	end
	if isWrath or (self.db.profile.support_crafting and not TSM_API) then
		for i=1,#CraftList,1 do
			local id = CraftList[i]
			local name = GetSpellInfo(id)
			--DA.DEBUG(2,"id= "..tostring(id)..", name= "..tostring(name))
			if name then
				table.insert(self.tradeSkillList,id)
				if self.build == "Wrath" and id == 7411 then
					self.skillIsCraft[id] = false
				else
					self.skillIsCraft[id] = true
				end
				self.tradeSkillIDsByName[name] = id
				self.tradeSkillNamesByID[id] = name
			end
		end
	end
	local locale = GetLocale()
	for id,t in pairs(TranslateList) do
		local loc = t[1]
		local old = t[2]
		local new = t[3]
		--DA.DEBUG(2,"id= "..tostring(id)..", loc= "..tostring(loc)..", old= "..tostring(old)..", new= "..tostring(new))
		if loc == locale then
			self.tradeSkillIDsByName[new] = id
		end
	end
end

--
-- Collects currency data (id to name and name to id)
--
function Skillet:CollectCurrencyData()
	DA.DEBUG(0,"CollectCurrencyData()")
	self.currencyIDsByName = {}
	self.currencyNamesByID = {}
end

function Skillet:AddCurrencyData(name,id)
	DA.DEBUG(0,"AddCurrencyData("..tostring(name)..", "..tostring(id)..")")
	if name and id then
		self.currencyIDsByName[name] = id
		self.currencyNamesByID[id] = name
	end
end

--
-- this routine collects the basic data (which tradeskills a player has)
--
function Skillet:ScanPlayerTradeSkills()
	DA.DEBUG(0,"ScanPlayerTradeSkills()")
	local player = self.currentPlayer
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
						skillRanksData[id].opened = 0
						skillRanksData[id].isCraft = self.skillIsCraft[id]
					end
				else
					--DA.DEBUG(2,"Skipping tradeskill data for: "..tostring(name)..", id= "..tostring(id)..", isCraft= "..tostring(self.skillIsCraft[id]))
					skillRanksData[id] = nil
				end
			end
		end
	end
end

--
-- Items in this list are ignored because they can cause infinite loops.
--
local TradeSkillIgnoredMats	 = {
	[11479] = 1 , -- Transmute: Iron to Gold
	[11480] = 1 , -- Transmute: Mithril to Truesilver
	[17559] = 1 , -- Transmute: Air to Fire
	[17560] = 1 , -- Transmute: Fire to Earth
	[17561] = 1 , -- Transmute: Earth to Water
	[17562] = 1 , -- Transmute: Water to Air
	[17563] = 1 , -- Transmute: Undeath to Water
	[17565] = 1 , -- Transmute: Life to Earth
	[17566] = 1 , -- Transmute: Earth to Life
	[28022] = 1 , -- large prismatic shard
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
	[42613] = 1 , -- nexus transformation
	[42615] = 1 , -- small prismatic shard
	[45765] = 1 , -- Void Shatter
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
	[60350] = 1 , -- Transmute: Titanium
	[118237] = 1 , -- mysterious diffusion
	[118238] = 1 , -- ethereal shard shatter
	[118239] = 1 , -- sha shatter
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

function Skillet:ConvertIgnoreListData()
	DA.DEBUG(0,"ConvertIgnoreListData()")
	self.TradeSkillIgnoredMats = {}
	for id in pairs(TradeSkillIgnoredMats) do
		local name = GetSpellInfo(id)
		--DA.DEBUG(1,"ConvertIgnoreListData: id= "..tostring(id)..", name= "..tostring(name))
		if name then
			self.TradeSkillIgnoredMats[name] = id
			self.TradeSkillIgnoredMats[id] = name
		else
			--DA.DEBUG(1,"ConvertIgnoreListData: id= "..tostring(id).." is unknown")
			self.TradeSkillIgnoredMats[id] = 1
		end
	end
end

--
-- Enchants that produce items (needed in Classic Era, Season of Mastery)
--
Skillet.EnchantSpellToItem = {
	[14293] = 11287 , -- Lesser Magic Wand
	[25124] = 20744 , -- Minor Wizard Oil
	[14807] = 11288 , -- Greater Magic Wand
	[25125] = 20745 , -- Minor Mana Oil
	[14809] = 11289 , -- Lesser Mystic Wand
	[14810] = 11290 , -- Greater Mystic Wand
	[25126] = 20746 , -- Lesser Wizard Oil
	[25127] = 20747 , -- Lesser Mana Oil
	[15596] = 11811 , -- Smoking Heart of the Mountain
	[25128] = 20750 , -- Wizard Oil
	[17180] = 12655 , -- Enchanted Thorium Bar
	[17181] = 12810 , -- Enchanted Leather
	[25130] = 20748 , -- Brilliant Mana Oil
	[25129] = 20749 , -- Brilliant Wizard Oil
	[28027] = 22460 , -- Prismatic Sphere
	[28016] = 22521 , -- Superior Mana Oil
	[28022] = 22449 , -- Large Prismatic Shard
	[28019] = 22522 , -- Superior Wizard Oil
	[28028] = 22459 , -- Void Sphere
	[42615] = 22448 , -- Small Prismatic Shard
}

--
-- ItemIDs that can be produced by multiple professions
--
Skillet.duplicateItemID = {
	[12655] = true		-- Enchanted Thorium Bar, Enchanting and Mining
}

--
-- Table of items that Enchanting, Prospecting, and Inscription 
-- can auto target (UseItemByName).
--
Skillet.TradeSkillAutoTarget = {
	[31252] = {  -- Prospecting
		[2770] = 5, --Copper Ore
		[2771] = 5, --Tin Ore
		[2772] = 5, --Iron Ore
		[3858] = 5, --Mithril Ore
		[10620] = 5, --Thorium Ore
		[23424] = 5, --Fel Iron Ore
		[23425] = 5, --Adamantite Ore
		[36909] = 5, --Cobalt Ore
		[36910] = 5, --Titanium Ore
		[36912] = 5, --Saronite Ore
		[53038] = 5, -- Obsidium Ore
		[52183] = 5, -- Pyrite Ore
		[52185] = 5, -- Elementium Ore
		[72092] = 5, -- Ghost Iron Ore
		[72103] = 5, -- White Trillium Ore
		[72094] = 5, -- Black Trillium Ore
		[152512] = 5, -- Monelite Ore
		[152513] = 5, -- Platinum Ore
		[152579] = 5, -- Storm Silver-ore
		[168185] = 5, -- Osmenite Ore
		[171829] = 5, -- Solenium Ore
		[171830] = 5, -- Oxxein Ore
		[171831] = 5, -- Phaedrum Ore
		[171832] = 5, -- Sinvyr Ore
	},
	[51005] = {  -- Milling
		[765] = 5, -- Silverleaf
		[785] = 5, -- Mageroyal
		[2449] = 5, -- Earthroot
		[2447] = 5, -- Peacebloom
		[2450] = 5, -- Briarthorn
		[2453] = 5, -- Bruiseweed
		[3820] = 5, -- Stranglekelp
		[2452] = 5, -- Swiftthistle
		[3355] = 5, -- Wild Steelbloom
		[3369] = 5, -- Grave Moss
		[3357] = 5, -- Liferoot
		[3356] = 5, -- Kingsblood
		[3818] = 5, -- Fadeleaf
		[3821] = 5, -- Goldthorn
		[3358] = 5, -- Khadgar\'s Whisker
		[3819] = 5, -- Dragon\'s Teeth
		[8831] = 5, -- Purple Lotus
		[8836] = 5, -- Arthas\' Tears
		[8838] = 5, -- Sungrass
		[4625] = 5, -- Firebloom
		[8839] = 5, -- Blindweed
		[8845] = 5, -- Ghost Mushroom
		[8846] = 5, -- Gromsblood
		[13463] = 5, -- Dreamfoil
		[13464] = 5, -- Golden Sansam
		[13465] = 5, -- Mountain Silversage
		[13466] = 5, -- Sorrowmoss
		[13467] = 5, -- Icecap
		[39969] = 5, -- Fire Seed (no longer in game)
-- Added in the Burning Crusade
		[22789] = 5, -- Terocone
		[22786] = 5, -- Dreaming Glory
		[22787] = 5, -- Ragveil
		[22785] = 5, -- Felweed
		[22790] = 5, -- Ancient Lichen
		[22792] = 5, -- Nightmare Vine
		[22793] = 5, -- Mana Thistle
		[22791] = 5, -- Netherbloom
--Added in Wrath of the Lich King
		[36901] = 5, -- Goldclover
		[36907] = 5, -- Talandra\'s Rose
		[37921] = 5, -- Deadnettle
		[36904] = 5, -- Tiger Lily
		[36905] = 5, -- Lichbloom
		[36906] = 5, -- Icethorn
		[36903] = 5, -- Adder\'s Tongue
		[39970] = 5, -- Fire Leaf
	},
	[7411] =  {  -- Enchanting
		[38682] = 1, -- Armor Vellum
		[37602] = 1, -- Armor Vellum II
		[43145] = 1, -- Armor Vellum III
		[39349] = 1, -- Weapon Vellum
		[39350] = 1, -- Weapon Vellum II
		[43146] = 1, -- Weapon Vellum III
	},
}

local defaultVellum = 38682
Skillet.subVellum = {
		[38682] = {37602, 43145}, -- Armor Vellum
		[37602] = {43145}, -- Armor Vellum II
		[39349] = {39350, 43146}, -- Weapon Vellum
		[39350] = {43146}, -- Weapon Vellum II
}

local lastAutoTarget = {}
function Skillet:GetAutoTargetItem(tradeID, spellID)
	DA.DEBUG(0,"GetAutoTargetItem("..tostring(tradeID)..", "..tostring(spellID)..")")
	local itemID, limit, count, itemName
	if self.TradeSkillAutoTarget[tradeID] then
		if not Skillet.isCraft and tradeID == 7411 then
			itemID = self.vellumData[spellID] or defaultVellum
			limit = self.TradeSkillAutoTarget[tradeID][itemID]
			itemName = GetItemInfo(itemID)
			count = GetItemCount(itemID)
			if count >= limit then
				DA.DEBUG(1,"GetAutoTargetItem: itemID= "..tostring(itemID).." ("..tostring(itemName)..")")
				return itemID, itemName
			else
				DA.DEBUG(1,"GetAutoTargetItem: need itemID= "..tostring(itemID).." ("..tostring(itemName)..")")
				if self.db.profile.use_higher_vellum and self.subVellum[itemID] then
					for i=1,#self.subVellum[itemID],1 do
						local subItem = self.subVellum[itemID][i]
						local subName = GetItemInfo(subItem)
						count = GetItemCount(subItem)
						if count >= limit then
							DA.DEBUG(1,"GetAutoTargetItem: found itemID= "..tostring(subItem).." ("..tostring(subName)..")")
							return subItem, subName
						end
					end
				end
			end
			return nil, itemName
		else
			itemID = lastAutoTarget[tradeID]
			DA.DEBUG(1,"GetAutoTargetItem: itemID= "..tostring(itemID))
			if itemID then
				limit	 = self.TradeSkillAutoTarget[tradeID][itemID]
				count = GetItemCount(itemID)
				if count >= limit then
					return itemID
				end
			end
			for itemID,limit in pairs(self.TradeSkillAutoTarget[tradeID]) do
				count = GetItemCount(itemID)
				--DA.DEBUG(2,"GetAutoTargetItem: itemID= "..tostring(itemID)..", limit= "..tostring(limit)..", count= "..tostring(count))
				if count >= limit then
					lastAutoTarget[tradeID] = itemID
					DA.DEBUG(1,"GetAutoTargetItem: itemID= "..tostring(itemID))
					return itemID
				end
			end
			lastAutoTarget[tradeID] = nil
		end
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
Skillet.skill_style_type = skill_style_type

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
-- Inscription 
--
local topink = 43126				-- Ink of the Sea
local specialVendorItems = {
	[37101] = {1, topink},			--Ivory Ink
	[39469] = {1, topink},			--Moonglow Ink
	[39774] = {1, topink},			--Midnight Ink
	[43116] = {1, topink},			--Lions Ink
	[43118] = {1, topink},			--Jadefire Ink
	[43120] = {1, topink},			--Celestial Ink
	[43122] = {1, topink},			--Shimmering Ink
	[43124] = {1, topink},			--Ethereal Ink
--	[43126] = {1, topink},			--Ink of the Sea
--	[61978] = {1, topink},			--Blackfallow Ink
--	[79254] = {1, topink},			--Ink of Dreams

	[43127] = {10, topink},			--Snowfall Ink
--	[61981] = {10, topink},			--Inferno Ink
--	[79255] = {10, topink},			--Starlight Ink
}
Skillet.SpecialVendorItems = specialVendorItems

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
		if Skillet.currentTrade and Skillet.db.global.recipeDB[Skillet.currentTrade][id] then
			local recipeString = Skillet.db.global.recipeDB[Skillet.currentTrade][id]
			--DA.DEBUG(3,"recipeString= "..tostring(recipeString))
			local tradeID, itemString, reagentString, toolString = string.split(" ",recipeString)
			local itemID, numMade = 0, 1
			local slot = nil
			if itemString then
				if itemString ~= "0" then
					local a, b = string.split(":",itemString)
					--DA.DEBUG(3,"itemString a= "..tostring(a)..", b= "..tostring(b))
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
	if player == self.currentPlayer and trade == self.currentTrade then
		if Skillet.isCraft then
			r = GetNumCrafts()
		else
			r = GetNumTradeSkills()
		end
	else
		if not Skillet.db.realm.skillDB[player] then
			r = 0
		elseif not Skillet.db.realm.skillDB[player][trade] then
			r = 0
		else
			r = #Skillet.db.realm.skillDB[player][trade]
		end
	end
	--DA.DEBUG(3,"GetNumSkills= "..tostring(r))
	return r
end

function Skillet:GetSkillRanks(player, trade)
	--DA.DEBUG(3,"GetSkillRanks("..tostring(player)..", "..tostring(trade)..")")
	local name, rank, maxRank
	if player and trade then
		if player == self.currentPlayer and trade == self.currentTrade then
			if self.isCraft then
				name, rank, maxRank = GetCraftDisplaySkillLine()
			else
				name, rank, maxRank = GetTradeSkillLine()
			end
			if self.db.realm.tradeSkills[player] and self.db.realm.tradeSkills[player][trade] then
				if rank ~= 0 and maxRank ~= 0 then
					self.db.realm.tradeSkills[player][trade].rank = rank
					self.db.realm.tradeSkills[player][trade].maxRank = maxRank
				end
			end
		end
		if self.db.realm.tradeSkills[player] then
			return self.db.realm.tradeSkills[player][trade]
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
		if not Skillet.db.realm.skillDB[player][trade][index] then
			DA.DEBUG(0,"GetSkill: skillDB missing for "..tostring(player)..", "..tostring(trade)..", "..tostring(index))
			return
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
	DA.DEBUG(0,"ScanTrade()")
	local profession, rank, maxRank
	local numSkills, numCrafts
	if Skillet.isCraft then
		profession, rank, maxRank = GetCraftDisplaySkillLine()
		numCrafts = GetNumCrafts()
	else
		profession, rank, maxRank = GetTradeSkillLine()
		numSkills = GetNumTradeSkills()
	end
	--DA.DEBUG(2,"ScanTrade: profession= "..tostring(profession)..", rank= "..tostring(rank)..", maxRank= "..tostring(maxRank)..", numCrafts= "..tostring(numCrafts)..", numSkills= "..tostring(numSkills))
	if profession == "UNKNOWN" then
		return false
	end
	local tradeID = Skillet.tradeSkillIDsByName[profession]
	if not tradeID then
		DA.DEBUG(0,"ScanTrade: tradeID is missing")
		return false
	end
	Skillet.currentTrade = tradeID
	local player = Skillet.currentPlayer
--
-- First, loop through all the recipe groups and make sure they are expanded
--
	if numSkills then
		--DA.DEBUG(2,"ScanTrade: Expanding Tradeskill Groups")
		for i = 1, numSkills do
			local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i)
			--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
			if skillType == "header" or skillType == "subheader" then
				if not isExpanded then
					ExpandTradeSkillSubClass(i)
				end
			end
		end
	end
	if numCrafts then
		--DA.DEBUG(2,"ScanTrade: Expanding Craft Groups")
		for i = 1, numCrafts do
			local skillName, skillType, numAvailable, isExpanded = GetCraftInfo(i)
			DA.DEBUG(2,"ScanCraft: i= "..tostring(i)..", skillName= "..tostring(skillName)..", skillType="..tostring(skillType)..", isExpanded= "..tostring(isExpanded))
			if skillType == "header" or skillType == "subheader" then
				if not isExpanded then
					ExpandCraftSubClass(i)
				end
			end
		end
		numSkills = numCrafts
	end
--
-- From here on, just one loop variable needed
--
	--DA.DEBUG(2,"ScanTrade: "..tostring(profession)..": "..tostring(tradeID).." "..numSkills.." recipes")
	if not Skillet.db.global.recipeDB[tradeID] then
		Skillet.db.global.recipeDB[tradeID] = {}
	end
	local recipeDB = Skillet.db.global.recipeDB[tradeID]
	local skillDB = Skillet.db.realm.skillDB[player][tradeID]
	local tradeSkill = Skillet.db.realm.tradeSkills[player][tradeID]
	local skillData = Skillet.data.skillList[player][tradeID]
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
	Skillet.groupList = {}
--
-- Update the tradeSkill data
--
	tradeSkill.name = profession
	tradeSkill.rank = rank
	tradeSkill.maxRank = maxRank
	tradeSkill.isCraft = Skillet.isCraft
	tradeSkill.numSkills = numSkills
	local login = Skillet.loginTime or 1
	local opened = tradeSkill.opened or 0
	if opened < login then
		tradeSkill.count = 0
		tradeSkill.opened = GetTime()
	end
	tradeSkill.count = Skillet.db.realm.tradeSkills[player][tradeID].count + 1
--
-- Mining and Smelting have a bipolar relationship 
--
	if tradeID == MINING then
		if not Skillet.db.realm.tradeSkills[player][SMELTING] then
			Skillet.db.realm.tradeSkills[player][SMELTING] = {}
		end
		Skillet.db.realm.tradeSkills[player][SMELTING].name = "Smelting ("..profession..")"
		Skillet.db.realm.tradeSkills[player][SMELTING].rank = rank
		Skillet.db.realm.tradeSkills[player][SMELTING].maxRank = maxRank
		Skillet.db.realm.tradeSkills[player][SMELTING].isCraft = Skillet.isCraft
		local opened = Skillet.db.realm.tradeSkills[player][SMELTING].opened or 0
		if opened < login then
			Skillet.db.realm.tradeSkills[player][SMELTING].count = 0
			Skillet.db.realm.tradeSkills[player][SMELTING].opened = GetTime()
		end
		Skillet.db.realm.tradeSkills[player][SMELTING].count = Skillet.db.realm.tradeSkills[player][SMELTING].count + 1
	end
	local numHeaders = 0
	local parentGroup
--
-- Data needed for filtering
--
	local numSubClass = {}
	local numInvSlot = {}
--
-- Now actually process each recipe (skill)
--
	local s = 1
--	if Skillet.isCraft then
--		s = 0
--	end
	local skillNameSeen = {}
	for i = s, numSkills, 1 do
		local skillName, craftSubSpellName, skillType, numAvailable, isExpanded, subSpell, extra
		if Skillet.isCraft then
--
-- If needed (by uncommenting three lines above), 
-- Skillet-Classic can insert a fake header for Crafts
--
			if i == 0 then
				skillName = "Enchanting"
				skillType = "header"
				isExpanded = true
			else
--
-- GetCraftInfo() returns are: craftName, craftSubSpellName, craftType, numAvailable, isExpanded, trainingPointCost, requiredLevel
--
				skillName, craftSubSpellName, skillType, numAvailable, isExpanded = GetCraftInfo(i)
			end
		else
			skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i)
		end
		--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", skillName= "..tostring(skillName)..", craftSubSpellName= "..tostring(craftSubSpellName)..", skillType="..tostring(skillType)..", numAvailable= "..tostring(numAvailable)..", isExpanded= "..tostring(isExpanded))
		if skillName then
			if skillType == "header" or skillType == "subheader" then
--
-- For headers (and subheaders) define groups and
-- add a header entry in the skillDB (SavedVariables)
--
				numHeaders = numHeaders + 1
				lastHeader = skillName
				local groupName
				if Skillet.groupList[skillName] then
					Skillet.groupList[skillName] = Skillet.groupList[skillName] + 1
					groupName = skillName.." "..Skillet.groupList[skillName]
				else
					Skillet.groupList[skillName] = 1
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
-- In Classic, recipes do not have a numerical ID so use the name as the id and 
-- break everything that assumes it is a number and assumes it is unique
--
				local recipeID
				recipeID = skillName
				if skillNameSeen[recipeID] then
					--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", skillName= "..tostring(skillName)..", craftSubSpellName= "..tostring(craftSubSpellName).." is not unique")
--
-- Make an attempt to create a unique recipeID
--
					if craftSubSpellName and craftSubSpellName ~= "" then
						recipeID = recipeID..craftSubSpellName
					else
						recipeID = recipeID.."("..tostring(i)..")"
					end
					DA.DEBUG(0,"ScanTrade: using '"..tostring(recipeID).."' instead")
				end
				skillNameSeen[recipeID] = true
				if currentGroup then
					Skillet:RecipeGroupAddRecipe(currentGroup, recipeID, i)
				else
					Skillet:RecipeGroupAddRecipe(mainGroup, recipeID, i)
				end
--
-- Break recipes into lists and tables by profession for ease of sorting
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
				local cd, tools
				if Skillet.isCraft then
					cd = GetCraftCooldown(i)
					tools = { GetCraftSpellFocus(i) }
				else
					cd = GetTradeSkillCooldown(i)
					tools = { GetTradeSkillTools(i) }
				end
				if cd then
					skillData[i].cooldown = cd + time()		-- this is when your cooldown will be up
					skillDBString = skillDBString.."@cd="..cd + time()
				end
				--DA.DEBUG(1,"ScanTrade: #tools= "..tostring(#tools)..", tools= "..DA.DUMP1(tools))
				skillData[i].tools = {}
				local slot = 1
				for t=2,#tools,2 do
					skillData[i].tools[slot] = (tools[t] or 0)
					slot = slot + 1
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
					if toolsAbsent then									-- only point out missing tools
						skillDBString = skillDBString.."@t="..toolString
					end
				end
				--DA.DEBUG(2,"ScanTrade: skillDB["..tostring(i).."] ("..tostring(recipeID)..") = "..tostring(skillDBString))
				skillDB[i] = skillDBString
				Skillet.data.skillIndexLookup[player][recipeID] = i
				Skillet.data.recipeList[recipeID] = {}
				local recipe = Skillet.data.recipeList[recipeID]
				local recipeString
				local toolString = "-"
				recipe.tradeID = tradeID
				recipe.spellID = Skillet:GetItemIDFromLink(GetTradeSkillRecipeLink(i))
				recipe.scrollID = Skillet.scrollData[recipe.spellID]
				recipe.name = skillName
				if #tools >= 1 then
					recipe.tools = { tools[1] }
					toolString = string.gsub(tools[1]," ", "_")
					for t=3,#tools,2 do
						table.insert(recipe.tools, tools[t])
						toolString = toolString..":"..string.gsub(tools[t]," ", "_")
					end
				end
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType
				local itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID
				local bindType, expacID, itemSetID, isCraftingReagent
				local itemString = "0"
				local itemLinkCraft = GetCraftItemLink(i)
				itemLink = GetTradeSkillItemLink(i)
				if itemLink and strfind(itemLink,"item::") then
--
-- itemLink is malformed, ignore it
--
					DA.WARN("ScanTrade: malformed itemLink, tradeID= "..tostring(tradeID)..", i= "..tostring(i)..", name= "..tostring(skillName)..", link= "..DA.PLINK(itemLink))
					itemLink = nil
				end
--
-- Enchants don't have an itemLink
-- Use the recipeID instead (for GetItemInfo)
--
				if not itemLink then
					if itemLinkCraft then
						--DA.DEBUG(2,"ScanTrade: use itemLinkCraft instead")
						itemLink = itemLinkCraft
					else
						--DA.DEBUG(2,"ScanTrade: use recipeID instead")
						itemLink = recipeID
						recipe.itemID = 0
						recipe.numMade = 1
					end
				end
				if not Skillet.isCraft then
					itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
					  itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID,
					  bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)
				else
					itemName = "e"..tostring(Skillet:GetItemIDFromLink(itemLink))
				end
				if itemName then
					local itemID, linkType = Skillet:GetItemIDFromLink(itemLink)
					--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", itemID= "..tostring(itemID)..", linkType= "..tostring(linkType))
					local minMade,maxMade = 1, 1
					if not Skillet.isCraft then
						minMade,maxMade = GetTradeSkillNumMade(i)
					end
					recipe.itemID = itemID
					recipe.numMade = (minMade + maxMade)/2
					--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", minMade= "..tostring(minMade)..", maxMade= "..tostring(maxMade))
					if recipe.numMade > 1 then
						itemString = itemID..":"..recipe.numMade
					else
						itemString = tostring(itemID)
					end
					Skillet:ItemDataAddRecipeSource(itemID,recipeID) -- add a cross reference for the source of particular items
--
-- Our own filter data: subClass, invSlot
--
					if itemSubType then
						if not Skillet.db.realm.subClass[player][tradeID].name then
							Skillet.db.realm.subClass[player][tradeID].name = {}
							Skillet.db.realm.subClass[player][tradeID].selected = "None"
						end
						numSubClass[itemSubType] = (numSubClass[itemSubType] or 0) + 1
						Skillet.db.realm.subClass[player][tradeID].name[itemSubType] = numSubClass[itemSubType]
						Skillet.db.realm.subClass[player][tradeID][itemID] = itemSubType
					end
					if itemEquipLoc then
						if not Skillet.db.realm.invSlot[player][tradeID].name then
							Skillet.db.realm.invSlot[player][tradeID].name = {}
							Skillet.db.realm.invSlot[player][tradeID].selected = "None"
						end
						numInvSlot[itemEquipLoc] = (numInvSlot[itemEquipLoc] or 0) + 1
						Skillet.db.realm.invSlot[player][tradeID].name[itemEquipLoc] = numInvSlot[itemEquipLoc]
						Skillet.db.realm.invSlot[player][tradeID][itemID] = itemEquipLoc
					end
--[[
				elseif not Skillet.isCraft then
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
				--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", numReagents= "..tostring(numReagents))
				for j=1, numReagents, 1 do
					local reagentName, _, numNeeded
					if Skillet.isCraft then
						reagentName, _, numNeeded = GetCraftReagentInfo(i,j)	-- reagentName, reagentTexture, reagentCount, playerReagentCount
					else
						reagentName, _, numNeeded = GetTradeSkillReagentInfo(i,j)
					end
					--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", j= "..tostring(j)..", reagentName= "..tostring(reagentName)..", numNeeded= "..tostring(numNeeded))
					local reagentID = 0
					if reagentName then
						local reagentLink
						if Skillet.isCraft then
							reagentLink = GetCraftReagentItemLink(i,j)
						else
							reagentLink = GetTradeSkillReagentItemLink(i,j)
						end
						--DA.DEBUG(2,"ScanTrade: i= "..tostring(i)..", reagentLink= "..DA.PLINK(reagentLink))
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
				if not recipeDB[recipeID] then
					recipeDB[recipeID] = recipeString
				elseif recipeDB[recipeID] ~= recipeString then
--
-- Another sanity check. A change of tradeID should have already been caught.
--
					local oldTradeID, oldItemString, oldReagentString, oldToolString = string.split(" ",recipeDB[recipeID])
					if oldItemString == itemString and oldReagentString == reagentString and oldToolString == toolString then
						DA.WARN("ScanTrade: recipeID="..tostring(recipeID)..", oldTradeID="..tostring(oldTradeID)..", tradeID="..tostring(tradeID).." (match)")
					elseif oldTradeID ~= tostring(tradeID) then
						DA.WARN("ScanTrade:  recipeID="..tostring(recipeID)..", oldTradeID="..tostring(oldTradeID)..", tradeID="..tostring(tradeID).." (no match)")
					end
					DA.WARN("ScanTrade: replacing recipeID="..tostring(recipeID)..", '"..tostring(recipeDB[recipeID]).."' with '"..tostring(recipeString).."'")
					recipeDB[recipeID] = recipeString
				end
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
	--DA.DEBUG(2,"ScanTrade: Complete, numSkills= "..tostring(numSkills)..", numHeaders= "..tostring(numHeaders))
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
	DA.DEBUG(0,"RescanTrade(), currentTrade= "..tostring(Skillet.currentTrade)..", lastTrade= "..tostring(lastTrade))
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not player or not tradeID then return end
--
-- Make sure all the data structures exist
--
	if not Skillet.data.skillList[player][tradeID] then
		Skillet.data.skillList[player][tradeID]={}
	end
	if not Skillet.db.realm.skillDB[player][tradeID] then
		Skillet.db.realm.skillDB[player][tradeID] = {}
	end
	if not Skillet.db.realm.tradeSkills[player][tradeID] then
		Skillet.db.realm.tradeSkills[player][tradeID] = {}
	end
--
-- Our own filter data: subClass, invSlot
--
	if not Skillet.db.realm.subClass[player][tradeID] then
		Skillet.db.realm.subClass[player][tradeID] = {}
	end
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
	Skillet.lastTrade = Skillet.currentTrade
	return Skillet.dataScanned
end

--
-- Table used to convert Enchant to Scroll
--
Skillet.scrollData = {
	-- Scraped from WoWhead using the following javascript:
	-- for (i=0; i<listviewitems.length; i++) console.log("["+listviewitems[i].sourcemore[0].ti+"] = "+listviewitems[i].id+",
	-- "+listviewitems[i].name.substr(1));
	[158914] = 110638, -- Enchant Ring - Gift of Critical Strike
	[158915] = 110639, -- Enchant Ring - Gift of Haste
	[158916] = 110640, -- Enchant Ring - Gift of Mastery
	[158917] = 110641, -- Enchant Ring - Gift of Multistrike
	[158918] = 110642, -- Enchant Ring - Gift of Versatility
	[158899] = 110645, -- Enchant Neck - Gift of Critical Strike
	[158900] = 110646, -- Enchant Neck - Gift of Haste
	[158901] = 110647, -- Enchant Neck - Gift of Mastery
	[158902] = 110648, -- Enchant Neck - Gift of Multistrike
	[158903] = 110649, -- Enchant Neck - Gift of Versatility
	[158884] = 110652, -- Enchant Cloak - Gift of Critical Strike
	[158885] = 110653, -- Enchant Cloak - Gift of Haste
	[158886] = 110654, -- Enchant Cloak - Gift of Mastery
	[158887] = 110655, -- Enchant Cloak - Gift of Multistrike
	[158889] = 110656, -- Enchant Cloak - Gift of Versatility
	[159235] = 110682, -- Enchant Weapon - Mark of the Thunderlord
	[159236] = 112093, -- Enchant Weapon - Mark of the Shattered Hand
	[159673] = 112115, -- Enchant Weapon - Mark of Shadowmoon
	[159674] = 112160, -- Enchant Weapon - Mark of Blackrock
	[159671] = 112164, -- Enchant Weapon - Mark of Warsong
	[159672] = 112165, -- Enchant Weapon - Mark of the Frostwolf
	[173323] = 118015, -- Enchant Weapon - Mark of Bleeding Hollow
	[158907] = 110617, -- Enchant Ring - Breath of Critical Strike
	[158908] = 110618, -- Enchant Ring - Breath of Haste
	[158909] = 110619, -- Enchant Ring - Breath of Mastery
	[158910] = 110620, -- Enchant Ring - Breath of Multistrike
	[158911] = 110621, -- Enchant Ring - Breath of Versatility
	[158892] = 110624, -- Enchant Neck - Breath of Critical Strike
	[158893] = 110625, -- Enchant Neck - Breath of Haste
	[158894] = 110626, -- Enchant Neck - Breath of Mastery
	[158895] = 110627, -- Enchant Neck - Breath of Multistrike
	[158896] = 110628, -- Enchant Neck - Breath of Versatility
	[158877] = 110631, -- Enchant Cloak - Breath of Critical Strike
	[158878] = 110632, -- Enchant Cloak - Breath of Haste
	[158879] = 110633, -- Enchant Cloak - Breath of Mastery
	[158880] = 110634, -- Enchant Cloak - Breath of Multistrike
	[158881] = 110635, -- Enchant Cloak - Breath of Versatility
	[104425] = 74723, -- Enchant Weapon - Windsong
	[104427] = 74724, -- Enchant Weapon - Jade Spirit
	[104430] = 74725, -- Enchant Weapon - Elemental Force
	[104434] = 74726, -- Enchant Weapon - Dancing Steel
	[104440] = 74727, -- Enchant Weapon - Colossus
	[104442] = 74728, -- Enchant Weapon - River's Song
	[104338] = 74700, -- Enchant Bracer - Mastery
	[104385] = 74701, -- Enchant Bracer - Major Dodge
	[104389] = 74703, -- Enchant Bracer - Super Intellect
	[104390] = 74704, -- Enchant Bracer - Exceptional Strength
	[104391] = 74705, -- Enchant Bracer - Greater Agility
	[104392] = 74706, -- Enchant Chest - Super Resilience
	[104393] = 74707, -- Enchant Chest - Mighty Spirit
	[104395] = 74708, -- Enchant Chest - Glorious Stats
	[104397] = 74709, -- Enchant Chest - Superior Stamina
	[104398] = 74710, -- Enchant Cloak - Accuracy
	[104401] = 74711, -- Enchant Cloak - Greater Protection
	[104403] = 74712, -- Enchant Cloak - Superior Intellect
	[104404] = 74713, -- Enchant Cloak - Superior Critical Strike
	[104407] = 74715, -- Enchant Boots - Greater Haste
	[104408] = 74716, -- Enchant Boots - Greater Precision
	[104409] = 74717, -- Enchant Boots - Blurred Speed
	[104414] = 74718, -- Enchant Boots - Pandaren's Step
	[104416] = 74719, -- Enchant Gloves - Greater Haste
	[104417] = 74720, -- Enchant Gloves - Superior Haste
	[104419] = 74721, -- Enchant Gloves - Super Strength
	[104420] = 74722, -- Enchant Gloves - Superior Mastery
	[104445] = 74729, -- Enchant Off-Hand - Major Intellect
	[130758] = 89737, -- Enchant Shield - Greater Parry
	[74195] = 52747, -- Enchant Weapon - Mending
	[96264] = 68784, -- Enchant Bracer - Agility
	[96261] = 68785, -- Enchant Bracer - Major Strength
	[96262] = 68786, -- Enchant Bracer - Mighty Intellect
	[74132] = 52687, -- Enchant Gloves - Mastery
	[74189] = 52743, -- Enchant Boots - Earthen Vitality
	[74191] = 52744, -- Enchant Chest - Mighty Stats
	[74192] = 52745, -- Enchant Cloak - Lesser Power
	[74193] = 52746, -- Enchant Bracer - Speed
	[74197] = 52748, -- Enchant Weapon - Avalanche
	[74198] = 52749, -- Enchant Gloves - Haste
	[74199] = 52750, -- Enchant Boots - Haste
	[74200] = 52751, -- Enchant Chest - Stamina
	[74201] = 52752, -- Enchant Bracer - Critical Strike
	[74202] = 52753, -- Enchant Cloak - Intellect
	[74207] = 52754, -- Enchant Shield - Protection
	[74211] = 52755, -- Enchant Weapon - Elemental Slayer
	[74212] = 52756, -- Enchant Gloves - Exceptional Strength
	[74213] = 52757, -- Enchant Boots - Major Agility
	[74214] = 52758, -- Enchant Chest - Mighty Resilience
	[74220] = 52759, -- Enchant Gloves - Greater Haste
	[74223] = 52760, -- Enchant Weapon - Hurricane
	[74225] = 52761, -- Enchant Weapon - Heartsong
	[74226] = 52762, -- Enchant Shield - Mastery
	[74229] = 52763, -- Enchant Bracer - Superior Dodge
	[74230] = 52764, -- Enchant Cloak - Critical Strike
	[74231] = 52765, -- Enchant Chest - Exceptional Spirit
	[74232] = 52766, -- Enchant Bracer - Precision
	[74234] = 52767, -- Enchant Cloak - Protection
	[74235] = 52768, -- Enchant Off-Hand - Superior Intellect
	[74236] = 52769, -- Enchant Boots - Precision
	[74237] = 52770, -- Enchant Bracer - Exceptional Spirit
	[74238] = 52771, -- Enchant Boots - Mastery
	[74239] = 52772, -- Enchant Bracer - Greater Haste
	[74240] = 52773, -- Enchant Cloak - Greater Intellect
	[74242] = 52774, -- Enchant Weapon - Power Torrent
	[74244] = 52775, -- Enchant Weapon - Windwalk
	[74246] = 52776, -- Enchant Weapon - Landslide
	[74247] = 52777, -- Enchant Cloak - Greater Critical Strike
	[74248] = 52778, -- Enchant Bracer - Greater Critical Strike
	[74250] = 52779, -- Enchant Chest - Peerless Stats
	[74251] = 52780, -- Enchant Chest - Greater Stamina
	[74252] = 52781, -- Enchant Boots - Assassin's Step
	[74253] = 52782, -- Enchant Boots - Lavawalker
	[74254] = 52783, -- Enchant Gloves - Mighty Strength
	[74255] = 52784, -- Enchant Gloves - Greater Mastery
	[74256] = 52785, -- Enchant Bracer - Greater Speed
	[95471] = 68134, -- Enchant 2H Weapon - Mighty Agility
	[42974] = 38948, -- Enchant Weapon - Executioner
	[44510] = 38963, -- Enchant Weapon - Exceptional Spirit
	[44524] = 38965, -- Enchant Weapon - Icebreaker
	[44576] = 38972, -- Enchant Weapon - Lifeward
	[44595] = 38981, -- Enchant 2H Weapon - Scourgebane
	[44621] = 38988, -- Enchant Weapon - Giant Slayer
	[44629] = 38991, -- Enchant Weapon - Exceptional Spellpower
	[44630] = 38992, -- Enchant 2H Weapon - Greater Savagery
	[44633] = 38995, -- Enchant Weapon - Exceptional Agility
	[46578] = 38998, -- Enchant Weapon - Deathfrost
	[59625] = 43987, -- Enchant Weapon - Black Magic
	[60621] = 44453, -- Enchant Weapon - Greater Potency
	[60691] = 44463, -- Enchant 2H Weapon - Massacre
	[60707] = 44466, -- Enchant Weapon - Superior Potency
	[60714] = 44467, -- Enchant Weapon - Mighty Spellpower
	[59621] = 44493, -- Enchant Weapon - Berserking
	[59619] = 44497, -- Enchant Weapon - Accuracy
	[62948] = 45056, -- Enchant Staff - Greater Spellpower
	[62959] = 45060, -- Enchant Staff - Spellpower
	[27958] = 38912, -- Enchant Chest - Exceptional Mana
	[44484] = 38951, -- Enchant Gloves - Haste
	[44488] = 38953, -- Enchant Gloves - Precision
	[44489] = 38954, -- Enchant Shield - Dodge
	[44492] = 38955, -- Enchant Chest - Mighty Health
	[44500] = 38959, -- Enchant Cloak - Superior Agility
	[44508] = 38961, -- Enchant Boots - Greater Spirit
	[44509] = 38962, -- Enchant Chest - Greater Mana Restoration
	[44513] = 38964, -- Enchant Gloves - Greater Assault
	[44528] = 38966, -- Enchant Boots - Greater Fortitude
	[44529] = 38967, -- Enchant Gloves - Major Agility
	[44555] = 38968, -- Enchant Bracer - Exceptional Intellect
	[60616] = 38971, -- Enchant Bracer - Assault
	[44582] = 38973, -- Enchant Cloak - Minor Power
	[44584] = 38974, -- Enchant Boots - Greater Vitality
	[44588] = 38975, -- Enchant Chest - Exceptional Resilience
	[44589] = 38976, -- Enchant Boots - Superior Agility
	[44591] = 38978, -- Enchant Cloak - Superior Dodge
	[44592] = 38979, -- Enchant Gloves - Exceptional Spellpower
	[44593] = 38980, -- Enchant Bracer - Major Spirit
	[44598] = 38984, -- Enchant Bracer - Haste
	[60623] = 38986, -- Enchant Boots - Icewalker
	[44616] = 38987, -- Enchant Bracer - Greater Stats
	[44623] = 38989, -- Enchant Chest - Super Stats
	[44625] = 38990, -- Enchant Gloves - Armsman
	[44631] = 38993, -- Enchant Cloak - Shadow Armor
	[44635] = 38997, -- Enchant Bracer - Greater Spellpower
	[47672] = 39001, -- Enchant Cloak - Mighty Stamina
	[47766] = 39002, -- Enchant Chest - Greater Dodge
	[47898] = 39003, -- Enchant Cloak - Greater Speed
	[47899] = 39004, -- Enchant Cloak - Wisdom
	[47900] = 39005, -- Enchant Chest - Super Health
	[47901] = 39006, -- Enchant Boots - Tuskarr's Vitality
	[60606] = 44449, -- Enchant Boots - Assault
	[60653] = 44455, -- Shield Enchant - Greater Intellect
	[60609] = 44456, -- Enchant Cloak - Speed
	[60663] = 44457, -- Enchant Cloak - Major Agility
	[60668] = 44458, -- Enchant Gloves - Crusher
	[60692] = 44465, -- Enchant Chest - Powerful Stats
	[60763] = 44469, -- Enchant Boots - Greater Assault
	[60767] = 44470, -- Enchant Bracer - Superior Spellpower
	[44575] = 44815, -- Enchant Bracer - Greater Assault
	[62256] = 44947, -- Enchant Bracer - Major Stamina
	[27967] = 38917, -- Enchant Weapon - Major Striking
	[27968] = 38918, -- Enchant Weapon - Major Intellect
	[27971] = 38919, -- Enchant 2H Weapon - Savagery
	[27972] = 38920, -- Enchant Weapon - Potency
	[27975] = 38921, -- Enchant Weapon - Major Spellpower
	[27977] = 38922, -- Enchant 2H Weapon - Major Agility
	[27981] = 38923, -- Enchant Weapon - Sunfire
	[27982] = 38924, -- Enchant Weapon - Soulfrost
	[27984] = 38925, -- Enchant Weapon - Mongoose
	[28003] = 38926, -- Enchant Weapon - Spellsurge
	[28004] = 38927, -- Enchant Weapon - Battlemaster
	[34010] = 38946, -- Enchant Weapon - Major Healing
	[42620] = 38947, -- Enchant Weapon - Greater Agility
	[27951] = 37603, -- Enchant Boots - Dexterity
	[25086] = 38895, -- Enchant Cloak - Dodge
	[27899] = 38897, -- Enchant Bracer - Brawn
	[27905] = 38898, -- Enchant Bracer - Stats
	[27906] = 38899, -- Enchant Bracer - Greater Dodge
	[27911] = 38900, -- Enchant Bracer - Superior Healing
	[27913] = 38901, -- Enchant Bracer - Restore Mana Prime
	[27914] = 38902, -- Enchant Bracer - Fortitude
	[27917] = 38903, -- Enchant Bracer - Spellpower
	[27944] = 38904, -- Enchant Shield - Lesser Dodge
	[27945] = 38905, -- Enchant Shield - Intellect
	[27946] = 38906, -- Enchant Shield - Parry
	[27948] = 38908, -- Enchant Boots - Vitality
	[27950] = 38909, -- Enchant Boots - Fortitude
	[27954] = 38910, -- Enchant Boots - Surefooted
	[27957] = 38911, -- Enchant Chest - Exceptional Health
	[27960] = 38913, -- Enchant Chest - Exceptional Stats
	[27961] = 38914, -- Enchant Cloak - Major Armor
	[33990] = 38928, -- Enchant Chest - Major Spirit
	[33991] = 38929, -- Enchant Chest - Restore Mana Prime
	[33992] = 38930, -- Enchant Chest - Major Resilience
	[33993] = 38931, -- Enchant Gloves - Blasting
	[33994] = 38932, -- Enchant Gloves - Precise Strikes
	[33995] = 38933, -- Enchant Gloves - Major Strength
	[33996] = 38934, -- Enchant Gloves - Assault
	[33997] = 38935, -- Enchant Gloves - Major Spellpower
	[33999] = 38936, -- Enchant Gloves - Major Healing
	[34001] = 38937, -- Enchant Bracer - Major Intellect
	[34002] = 38938, -- Enchant Bracer - Lesser Assault
	[34003] = 38939, -- Enchant Cloak - PvP Power
	[34004] = 38940, -- Enchant Cloak - Greater Agility
	[34005] = 38941, -- Enchant Cloak - Greater Arcane Resistance
	[34006] = 38942, -- Enchant Cloak - Greater Shadow Resistance
	[34007] = 38943, -- Enchant Boots - Cat's Swiftness
	[34008] = 38944, -- Enchant Boots - Boar's Speed
	[34009] = 38945, -- Enchant Shield - Major Stamina
	[44383] = 38949, -- Enchant Shield - Resilience
	[44483] = 38950, -- Enchant Cloak - Superior Frost Resistance
	[44494] = 38956, -- Enchant Cloak - Superior Nature Resistance
	[44556] = 38969, -- Enchant Cloak - Superior Fire Resistance
	[44590] = 38977, -- Enchant Cloak - Superior Shadow Resistance
	[44596] = 38982, -- Enchant Cloak - Superior Arcane Resistance
	[46594] = 38999, -- Enchant Chest - Dodge
	[47051] = 39000, -- Enchant Cloak - Greater Dodge
	[7745] = 38772, -- Enchant 2H Weapon - Minor Impact
	[7786] = 38779, -- Enchant Weapon - Minor Beastslayer
	[7788] = 38780, -- Enchant Weapon - Minor Striking
	[7793] = 38781, -- Enchant 2H Weapon - Lesser Intellect
	[13380] = 38788, -- Enchant 2H Weapon - Lesser Spirit
	[13503] = 38794, -- Enchant Weapon - Lesser Striking
	[13529] = 38796, -- Enchant 2H Weapon - Lesser Impact
	[13653] = 38813, -- Enchant Weapon - Lesser Beastslayer
	[13655] = 38814, -- Enchant Weapon - Lesser Elemental Slayer
	[13693] = 38821, -- Enchant Weapon - Striking
	[13695] = 38822, -- Enchant 2H Weapon - Impact
	[13898] = 38838, -- Enchant Weapon - Fiery Weapon
	[13915] = 38840, -- Enchant Weapon - Demonslaying
	[13937] = 38845, -- Enchant 2H Weapon - Greater Impact
	[13943] = 38848, -- Enchant Weapon - Greater Striking
	[20029] = 38868, -- Enchant Weapon - Icy Chill
	[20030] = 38869, -- Enchant 2H Weapon - Superior Impact
	[20031] = 38870, -- Enchant Weapon - Superior Striking
	[20032] = 38871, -- Enchant Weapon - Lifestealing
	[20033] = 38872, -- Enchant Weapon - Unholy Weapon
	[20034] = 38873, -- Enchant Weapon - Crusader
	[20035] = 38874, -- Enchant 2H Weapon - Major Spirit
	[20036] = 38875, -- Enchant 2H Weapon - Major Intellect
	[21931] = 38876, -- Enchant Weapon - Winter's Might
	[22749] = 38877, -- Enchant Weapon - Spellpower
	[22750] = 38878, -- Enchant Weapon - Healing Power
	[23799] = 38879, -- Enchant Weapon - Strength
	[23800] = 38880, -- Enchant Weapon - Agility
	[23803] = 38883, -- Enchant Weapon - Mighty Spirit
	[23804] = 38884, -- Enchant Weapon - Mighty Intellect
	[27837] = 38896, -- Enchant 2H Weapon - Agility
	[64441] = 46026, -- Enchant Weapon - Blade Ward
	[64579] = 46098, -- Enchant Weapon - Blood Draining
	[7418] = 38679, -- Enchant Bracer - Minor Health
	[7420] = 38766, -- Enchant Chest - Minor Health
	[7426] = 38767, -- Enchant Chest - Minor Absorption
	[7428] = 38768, -- Enchant Bracer - Minor Dodge
	[7443] = 38769, -- Enchant Chest - Minor Mana
	[7454] = 38770, -- Enchant Cloak - Minor Resistance
	[7457] = 38771, -- Enchant Bracer - Minor Stamina
	[7748] = 38773, -- Enchant Chest - Lesser Health
	[7766] = 38774, -- Enchant Bracer - Minor Spirit
	[7771] = 38775, -- Enchant Cloak - Minor Protection
	[7776] = 38776, -- Enchant Chest - Lesser Mana
	[7779] = 38777, -- Enchant Bracer - Minor Agility
	[7782] = 38778, -- Enchant Bracer - Minor Strength
	[7857] = 38782, -- Enchant Chest - Health
	[7859] = 38783, -- Enchant Bracer - Lesser Spirit
	[7861] = 38784, -- Enchant Cloak - Lesser Fire Resistance
	[7863] = 38785, -- Enchant Boots - Minor Stamina
	[7867] = 38786, -- Enchant Boots - Minor Agility
	[13378] = 38787, -- Enchant Shield - Minor Stamina
	[13419] = 38789, -- Enchant Cloak - Minor Agility
	[13421] = 38790, -- Enchant Cloak - Lesser Protection
	[13464] = 38791, -- Enchant Shield - Lesser Protection
	[13485] = 38792, -- Enchant Shield - Lesser Spirit
	[13501] = 38793, -- Enchant Bracer - Lesser Stamina
	[13522] = 38795, -- Enchant Cloak - Lesser Shadow Resistance
	[13536] = 38797, -- Enchant Bracer - Lesser Strength
	[13538] = 38798, -- Enchant Chest - Lesser Absorption
	[13607] = 38799, -- Enchant Chest - Mana
	[13612] = 38800, -- Enchant Gloves - Mining
	[13617] = 38801, -- Enchant Gloves - Herbalism
	[13620] = 38802, -- Enchant Gloves - Fishing
	[13622] = 38803, -- Enchant Bracer - Lesser Intellect
	[13626] = 38804, -- Enchant Chest - Minor Stats
	[13631] = 38805, -- Enchant Shield - Lesser Stamina
	[13635] = 38806, -- Enchant Cloak - Defense
	[13637] = 38807, -- Enchant Boots - Lesser Agility
	[13640] = 38808, -- Enchant Chest - Greater Health
	[13642] = 38809, -- Enchant Bracer - Spirit
	[13644] = 38810, -- Enchant Boots - Lesser Stamina
	[13646] = 38811, -- Enchant Bracer - Lesser Dodge
	[13648] = 38812, -- Enchant Bracer - Stamina
	[13657] = 38815, -- Enchant Cloak - Fire Resistance
	[13659] = 38816, -- Enchant Shield - Spirit
	[13661] = 38817, -- Enchant Bracer - Strength
	[13663] = 38818, -- Enchant Chest - Greater Mana
	[13687] = 38819, -- Enchant Boots - Lesser Spirit
	[13689] = 38820, -- Enchant Shield - Lesser Parry
	[13698] = 38823, -- Enchant Gloves - Skinning
	[13700] = 38824, -- Enchant Chest - Lesser Stats
	[13746] = 38825, -- Enchant Cloak - Greater Defense
	[13794] = 38826, -- Enchant Cloak - Resistance
	[13815] = 38827, -- Enchant Gloves - Agility
	[13817] = 38828, -- Enchant Shield - Stamina
	[13822] = 38829, -- Enchant Bracer - Intellect
	[13836] = 38830, -- Enchant Boots - Stamina
	[13841] = 38831, -- Enchant Gloves - Advanced Mining
	[13846] = 38832, -- Enchant Bracer - Greater Spirit
	[13858] = 38833, -- Enchant Chest - Superior Health
	[13868] = 38834, -- Enchant Gloves - Advanced Herbalism
	[13882] = 38835, -- Enchant Cloak - Lesser Agility
	[13887] = 38836, -- Enchant Gloves - Strength
	[13890] = 38837, -- Enchant Boots - Minor Speed
	[13905] = 38839, -- Enchant Shield - Greater Spirit
	[13917] = 38841, -- Enchant Chest - Superior Mana
	[13931] = 38842, -- Enchant Bracer - Dodge
	[13935] = 38844, -- Enchant Boots - Agility
	[13933] = 38843, -- Enchant Shield - Frost Resistance
	[13939] = 38846, -- Enchant Bracer - Greater Strength
	[13941] = 38847, -- Enchant Chest - Stats
	[13945] = 38849, -- Enchant Bracer - Greater Stamina
	[13947] = 38850, -- Enchant Gloves - Riding Skill
	[13948] = 38851, -- Enchant Gloves - Minor Haste
	[20008] = 38852, -- Enchant Bracer - Greater Intellect
	[20009] = 38853, -- Enchant Bracer - Superior Spirit
	[20010] = 38854, -- Enchant Bracer - Superior Strength
	[20011] = 38855, -- Enchant Bracer - Superior Stamina
	[20012] = 38856, -- Enchant Gloves - Greater Agility
	[20013] = 38857, -- Enchant Gloves - Greater Strength
	[20014] = 38858, -- Enchant Cloak - Greater Resistance
	[20015] = 38859, -- Enchant Cloak - Superior Defense
	[20016] = 38860, -- Enchant Shield - Vitality
	[20017] = 38861, -- Enchant Shield - Greater Stamina
	[20020] = 38862, -- Enchant Boots - Greater Stamina
	[20023] = 38863, -- Enchant Boots - Greater Agility
	[20024] = 38864, -- Enchant Boots - Spirit
	[20025] = 38865, -- Enchant Chest - Greater Stats
	[20026] = 38866, -- Enchant Chest - Major Health
	[20028] = 38867, -- Enchant Chest - Major Mana
	[23801] = 38881, -- Enchant Bracer - Mana Regeneration
	[23802] = 38882, -- Enchant Bracer - Healing Power
	[25072] = 38885, -- Enchant Gloves - Threat
	[25073] = 38886, -- Enchant Gloves - Shadow Power
	[25074] = 38887, -- Enchant Gloves - Frost Power
	[25078] = 38888, -- Enchant Gloves - Fire Power
	[25079] = 38889, -- Enchant Gloves - Healing Power
	[25080] = 38890, -- Enchant Gloves - Superior Agility
	[25081] = 38891, -- Enchant Cloak - Greater Fire Resistance
	[25082] = 38892, -- Enchant Cloak - Greater Nature Resistance
	[25083] = 38893, -- Enchant Cloak - Stealth
	[25084] = 38894, -- Enchant Cloak - Subtlety
	[27947] = 38907, -- Enchant Shield - Resistance
	[27962] = 38915, -- Enchant Cloak - Major Resistance
	[44506] = 38960, -- Enchant Gloves - Gatherer
	[63746] = 45628, -- Enchant Boots - Lesser Accuracy
	[71692] = 50816, -- Enchant Gloves - Angler
	[62257] = 44946, -- Scroll of Enchant Weapon - Titanguard
	[44612] = 38985, -- Scroll of Enchant Gloves - Greater Blasting
}

--
-- Table used to target Enchanting Vellum
--
Skillet.vellumData = {
	[7418] = 38682, -- Enchant Bracer - Minor Health
	[7420] = 38682, -- Enchant Chest - Minor Health
	[7426] = 38682, -- Enchant Chest - Minor Absorption
	[7428] = 38682, -- Enchant Bracer - Minor Deflection
	[7443] = 38682, -- Enchant Chest - Minor Mana
	[7454] = 38682, -- Enchant Cloak - Minor Resistance
	[7457] = 38682, -- Enchant Bracer - Minor Stamina
	[7745] = 39349, -- Enchant 2H Weapon - Minor Impact
	[7748] = 38682, -- Enchant Chest - Lesser Health
	[7766] = 38682, -- Enchant Bracer - Minor Spirit
	[7771] = 38682, -- Enchant Cloak - Minor Protection
	[7776] = 38682, -- Enchant Chest - Lesser Mana
	[7779] = 38682, -- Enchant Bracer - Minor Agility
	[7782] = 38682, -- Enchant Bracer - Minor Strength
	[7786] = 39349, -- Enchant Weapon - Minor Beastslayer
	[7788] = 39349, -- Enchant Weapon - Minor Striking
	[7793] = 39349, -- Enchant 2H Weapon - Lesser Intellect
	[7857] = 38682, -- Enchant Chest - Health
	[7859] = 38682, -- Enchant Bracer - Lesser Spirit
	[7861] = 38682, -- Enchant Cloak - Lesser Fire Resistance
	[7863] = 38682, -- Enchant Boots - Minor Stamina
	[7867] = 38682, -- Enchant Boots - Minor Agility
	[13378] = 38682, -- Enchant Shield - Minor Stamina
	[13380] = 39349, -- Enchant 2H Weapon - Lesser Spirit
	[13419] = 38682, -- Enchant Cloak - Minor Agility
	[13421] = 38682, -- Enchant Cloak - Lesser Protection
	[13464] = 38682, -- Enchant Shield - Lesser Protection
	[13485] = 38682, -- Enchant Shield - Lesser Spirit
	[13501] = 38682, -- Enchant Bracer - Lesser Stamina
	[13503] = 39349, -- Enchant Weapon - Lesser Striking
	[13522] = 38682, -- Enchant Cloak - Lesser Shadow Resistance
	[13529] = 39349, -- Enchant 2H Weapon - Lesser Impact
	[13536] = 38682, -- Enchant Bracer - Lesser Strength
	[13538] = 38682, -- Enchant Chest - Lesser Absorption
	[13607] = 38682, -- Enchant Chest - Mana
	[13612] = 38682, -- Enchant Gloves - Mining
	[13617] = 38682, -- Enchant Gloves - Herbalism
	[13620] = 38682, -- Enchant Gloves - Fishing
	[13622] = 38682, -- Enchant Bracer - Lesser Intellect
	[13626] = 38682, -- Enchant Chest - Minor Stats
	[13631] = 38682, -- Enchant Shield - Lesser Stamina
	[13635] = 38682, -- Enchant Cloak - Defense
	[13637] = 38682, -- Enchant Boots - Lesser Agility
	[13640] = 38682, -- Enchant Chest - Greater Health
	[13642] = 38682, -- Enchant Bracer - Spirit
	[13644] = 38682, -- Enchant Boots - Lesser Stamina
	[13646] = 38682, -- Enchant Bracer - Lesser Deflection
	[13648] = 38682, -- Enchant Bracer - Stamina
	[13653] = 39349, -- Enchant Weapon - Lesser Beastslayer
	[13655] = 39349, -- Enchant Weapon - Lesser Elemental Slayer
	[13657] = 38682, -- Enchant Cloak - Fire Resistance
	[13659] = 38682, -- Enchant Shield - Spirit
	[13661] = 38682, -- Enchant Bracer - Strength
	[13663] = 38682, -- Enchant Chest - Greater Mana
	[13687] = 38682, -- Enchant Boots - Lesser Spirit
	[13689] = 38682, -- Enchant Shield - Lesser Block
	[13693] = 39349, -- Enchant Weapon - Striking
	[13695] = 39349, -- Enchant 2H Weapon - Impact
	[13698] = 38682, -- Enchant Gloves - Skinning
	[13700] = 38682, -- Enchant Chest - Lesser Stats
	[13746] = 38682, -- Enchant Cloak - Greater Defense
	[13794] = 38682, -- Enchant Cloak - Resistance
	[13815] = 38682, -- Enchant Gloves - Agility
	[13817] = 38682, -- Enchant Shield - Stamina
	[13822] = 38682, -- Enchant Bracer - Intellect
	[13836] = 38682, -- Enchant Boots - Stamina
	[13841] = 38682, -- Enchant Gloves - Advanced Mining
	[13846] = 38682, -- Enchant Bracer - Greater Spirit
	[13858] = 38682, -- Enchant Chest - Superior Health
	[13868] = 38682, -- Enchant Gloves - Advanced Herbalism
	[13882] = 38682, -- Enchant Cloak - Lesser Agility
	[13887] = 38682, -- Enchant Gloves - Strength
	[13890] = 38682, -- Enchant Boots - Minor Speed
	[13898] = 39349, -- Enchant Weapon - Fiery Weapon
	[13905] = 38682, -- Enchant Shield - Greater Spirit
	[13915] = 39349, -- Enchant Weapon - Demonslaying
	[13917] = 38682, -- Enchant Chest - Superior Mana
	[13931] = 38682, -- Enchant Bracer - Deflection
	[13933] = 38682, -- Enchant Shield - Frost Resistance
	[13935] = 38682, -- Enchant Boots - Agility
	[13937] = 39349, -- Enchant 2H Weapon - Greater Impact
	[13939] = 38682, -- Enchant Bracer - Greater Strength
	[13941] = 38682, -- Enchant Chest - Stats
	[13943] = 39349, -- Enchant Weapon - Greater Striking
	[13945] = 38682, -- Enchant Bracer - Greater Stamina
	[13947] = 38682, -- Enchant Gloves - Riding Skill
	[13948] = 38682, -- Enchant Gloves - Minor Haste
	[20008] = 38682, -- Enchant Bracer - Greater Intellect
	[20009] = 38682, -- Enchant Bracer - Superior Spirit
	[20010] = 38682, -- Enchant Bracer - Superior Strength
	[20011] = 38682, -- Enchant Bracer - Superior Stamina
	[20012] = 38682, -- Enchant Gloves - Greater Agility
	[20013] = 38682, -- Enchant Gloves - Greater Strength
	[20014] = 38682, -- Enchant Cloak - Greater Resistance
	[20015] = 38682, -- Enchant Cloak - Superior Defense
	[20016] = 38682, -- Enchant Shield - Vitality
	[20017] = 38682, -- Enchant Shield - Greater Stamina
	[20020] = 38682, -- Enchant Boots - Greater Stamina
	[20023] = 38682, -- Enchant Boots - Greater Agility
	[20024] = 38682, -- Enchant Boots - Spirit
	[20025] = 38682, -- Enchant Chest - Greater Stats
	[20026] = 38682, -- Enchant Chest - Major Health
	[20028] = 38682, -- Enchant Chest - Major Mana
	[20029] = 39349, -- Enchant Weapon - Icy Chill
	[20030] = 39349, -- Enchant 2H Weapon - Superior Impact
	[20031] = 39349, -- Enchant Weapon - Superior Striking
	[20032] = 39349, -- Enchant Weapon - Lifestealing
	[20033] = 39349, -- Enchant Weapon - Unholy Weapon
	[20034] = 39349, -- Enchant Weapon - Crusader
	[20035] = 39349, -- Enchant 2H Weapon - Major Spirit
	[20036] = 39349, -- Enchant 2H Weapon - Major Intellect
	[21931] = 39349, -- Enchant Weapon - Winter's Might
	[22749] = 39349, -- Enchant Weapon - Spellpower
	[22750] = 39349, -- Enchant Weapon - Healing Power
	[23799] = 39349, -- Enchant Weapon - Strength
	[23800] = 39349, -- Enchant Weapon - Agility
	[23801] = 38682, -- Enchant Bracer - Mana Regeneration
	[23802] = 38682, -- Enchant Bracer - Healing Power
	[23803] = 39349, -- Enchant Weapon - Mighty Spirit
	[23804] = 39349, -- Enchant Weapon - Mighty Intellect
	[25072] = 38682, -- Enchant Gloves - Threat
	[25073] = 38682, -- Enchant Gloves - Shadow Power
	[25074] = 38682, -- Enchant Gloves - Frost Power
	[25078] = 38682, -- Enchant Gloves - Fire Power
	[25079] = 38682, -- Enchant Gloves - Healing Power
	[25080] = 38682, -- Enchant Gloves - Superior Agility
	[25081] = 38682, -- Enchant Cloak - Greater Fire Resistance
	[25082] = 38682, -- Enchant Cloak - Greater Nature Resistance
	[25083] = 38682, -- Enchant Cloak - Stealth
	[25084] = 38682, -- Enchant Cloak - Subtlety
	[25086] = 37602, -- Enchant Cloak - Dodge
	[27837] = 39349, -- Enchant 2H Weapon - Agility
	[27899] = 37602, -- Enchant Bracer - Brawn
	[27905] = 37602, -- Enchant Bracer - Stats
	[27906] = 37602, -- Enchant Bracer - Major Defense
	[27911] = 37602, -- Enchant Bracer - Superior Healing
	[27913] = 37602, -- Enchant Bracer - Restore Mana Prime
	[27914] = 37602, -- Enchant Bracer - Fortitude
	[27917] = 37602, -- Enchant Bracer - Spellpower
	[27944] = 37602, -- Enchant Shield - Tough Shield
	[27945] = 37602, -- Enchant Shield - Intellect
	[27946] = 37602, -- Enchant Shield - Shield Block
	[27947] = 37602, -- Enchant Shield - Resistance
	[27948] = 37602, -- Enchant Boots - Vitality
	[27950] = 37602, -- Enchant Boots - Fortitude
	[27951] = 37602, -- Enchant Boots - Dexterity
	[27954] = 37602, -- Enchant Boots - Surefooted
	[27957] = 37602, -- Enchant Chest - Exceptional Health
	[27958] = 43145, -- Enchant Chest - Exceptional Mana
	[27960] = 37602, -- Enchant Chest - Exceptional Stats
	[27961] = 37602, -- Enchant Cloak - Major Armor
	[27962] = 37602, -- Enchant Cloak - Major Resistance
	[27967] = 39350, -- Enchant Weapon - Major Striking
	[27968] = 39350, -- Enchant Weapon - Major Intellect
	[27971] = 39350, -- Enchant 2H Weapon - Savagery
	[27972] = 39350, -- Enchant Weapon - Potency
	[27975] = 39350, -- Enchant Weapon - Major Spellpower
	[27977] = 39350, -- Enchant 2H Weapon - Major Agility
	[27981] = 39350, -- Enchant Weapon - Sunfire
	[27982] = 39350, -- Enchant Weapon - Soulfrost
	[27984] = 39350, -- Enchant Weapon - Mongoose
	[28003] = 39350, -- Enchant Weapon - Spellsurge
	[28004] = 39350, -- Enchant Weapon - Battlemaster
	[33990] = 37602, -- Enchant Chest - Major Spirit
	[33991] = 37602, -- Enchant Chest - Restore Mana Prime
	[33992] = 37602, -- Enchant Chest - Major Resilience
	[33993] = 37602, -- Enchant Gloves - Blasting
	[33994] = 37602, -- Enchant Gloves - Precise Strikes
	[33995] = 37602, -- Enchant Gloves - Major Strength
	[33996] = 37602, -- Enchant Gloves - Assault
	[33997] = 37602, -- Enchant Gloves - Major Spellpower
	[33999] = 37602, -- Enchant Gloves - Major Healing
	[34001] = 37602, -- Enchant Bracer - Major Intellect
	[34002] = 37602, -- Enchant Bracer - Assault
	[34003] = 37602, -- Enchant Cloak - Spell Penetration
	[34004] = 37602, -- Enchant Cloak - Greater Agility
	[34005] = 37602, -- Enchant Cloak - Greater Arcane Resistance
	[34006] = 37602, -- Enchant Cloak - Greater Shadow Resistance
	[34007] = 37602, -- Enchant Boots - Cat's Swiftness
	[34008] = 37602, -- Enchant Boots - Boar's Speed
	[34009] = 37602, -- Enchant Shield - Major Stamina
	[34010] = 39350, -- Enchant Weapon - Major Healing
	[42620] = 39350, -- Enchant Weapon - Greater Agility
	[42974] = 43146, -- Enchant Weapon - Executioner
	[44383] = 37602, -- Enchant Shield - Resilience
	[44483] = 43145, -- Enchant Cloak - Superior Frost Resistance
	[44484] = 43145, -- Enchant Gloves - Expertise
	[44488] = 43145, -- Enchant Gloves - Precision
	[44489] = 43145, -- Enchant Shield - Defense
	[44492] = 43145, -- Enchant Chest - Mighty Health
	[44494] = 43145, -- Enchant Cloak - Superior Nature Resistance
	[44500] = 43145, -- Enchant Cloak - Superior Agility
	[44506] = 43145, -- Enchant Gloves - Gatherer
	[44508] = 43145, -- Enchant Boots - Greater Spirit
	[44509] = 43145, -- Enchant Chest - Greater Mana Restoration
	[44510] = 43146, -- Enchant Weapon - Exceptional Spirit
	[44513] = 43145, -- Enchant Gloves - Greater Assault
	[44524] = 43146, -- Enchant Weapon - Icebreaker
	[44528] = 43145, -- Enchant Boots - Greater Fortitude
	[44529] = 43145, -- Enchant Gloves - Major Agility
	[44555] = 43145, -- Enchant Bracers - Exceptional Intellect
	[44556] = 43145, -- Enchant Cloak - Superior Fire Resistance
	[44575] = 43145, -- Enchant Bracers - Greater Assault
	[44576] = 43146, -- Enchant Weapon - Lifeward
	[44582] = 43145, -- Enchant Cloak - Spell Piercing
	[44584] = 43145, -- Enchant Boots - Greater Vitality
	[44588] = 43145, -- Enchant Chest - Exceptional Resilience
	[44589] = 43145, -- Enchant Boots - Superior Agility
	[44590] = 43145, -- Enchant Cloak - Superior Shadow Resistance
	[44591] = 43145, -- Enchant Cloak - Titanweave
	[44592] = 43145, -- Enchant Gloves - Exceptional Spellpower
	[44593] = 43145, -- Enchant Bracers - Major Spirit
	[44595] = 39350, -- Enchant 2H Weapon - Scourgebane
	[44596] = 43145, -- Enchant Cloak - Superior Arcane Resistance
	[44598] = 43145, -- Enchant Bracer - Expertise
	[44616] = 43145, -- Enchant Bracers - Greater Stats
	[44621] = 43146, -- Enchant Weapon - Giant Slayer
	[44623] = 43145, -- Enchant Chest - Super Stats
	[44625] = 43145, -- Enchant Gloves - Armsman
	[44629] = 43146, -- Enchant Weapon - Exceptional Spellpower
	[44630] = 43146, -- Enchant 2H Weapon - Greater Savagery
	[44631] = 43145, -- Enchant Cloak - Shadow Armor
	[44633] = 43146, -- Enchant Weapon - Exceptional Agility
	[44635] = 43145, -- Enchant Bracers - Greater Spellpower
	[46578] = 43146, -- Enchant Weapon - Deathfrost
	[46594] = 37602, -- Enchant Chest - Defense
	[47051] = 37602, -- Enchant Cloak - Steelweave
	[47672] = 43145, -- Enchant Cloak - Mighty Armor
	[47766] = 43145, -- Enchant Chest - Greater Defense
	[47898] = 43145, -- Enchant Cloak - Greater Speed
	[47899] = 43145, -- Enchant Cloak - Wisdom
	[47900] = 43145, -- Enchant Chest - Super Health
	[47901] = 43145, -- Enchant Boots - Tuskarr's Vitality
	[59619] = 43146, -- Enchant Weapon - Accuracy
	[59621] = 43146, -- Enchant Weapon - Berserking
	[59625] = 43146, -- Enchant Weapon - Black Magic
	[60606] = 43145, -- Enchant Boots - Assault
	[60609] = 43145, -- Enchant Cloak - Speed
	[60616] = 43145, -- Enchant Bracers - Striking
	[60621] = 43146, -- Enchant Weapon - Greater Potency
	[60623] = 43145, -- Enchant Boots - Icewalker
	[60653] = 43145, -- Enchant Shield - Greater Intellect
	[60663] = 43145, -- Enchant Cloak - Major Agility
	[60668] = 43145, -- Enchant Gloves - Crusher
	[60691] = 43146, -- Enchant 2H Weapon - Massacre
	[60692] = 43145, -- Enchant Chest - Powerful Stats
	[60707] = 43146, -- Enchant Weapon - Superior Potency
	[60714] = 43146, -- Enchant Weapon - Mighty Spellpower
	[60763] = 43145, -- Enchant Boots - Greater Assault
	[60767] = 43145, -- Enchant Bracer - Superior Spellpower
	[62256] = 43145, -- Enchant Bracer - Major Stamina
	[62948] = 43146, -- Enchant Staff - Greater Spellpower
	[62959] = 43146, -- Enchant Staff - Spellpower
	[63746] = 38682, -- Enchant Boots - Lesser Accuracy
	[64441] = 43146, -- Enchant Weapon - Blade Ward
	[64579] = 43146, -- Enchant Weapon - Blood Draining
	[71692] = 38682, -- Enchant Gloves - Angler
	[62257] = 43146, -- Enchant Weapon - Titanguard
	[44612] = 43145, -- Enchant Gloves - Greater Blasting
}
