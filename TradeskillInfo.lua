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

-- This file contains code used to access recipe/tradeskill information

--[[
--
-- GetItemInfo(item)
-- item can be: itemID or "itemString" or "itemName" or "itemLink"
--
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
--
-- If an item requires a specific level before it can be used, then
-- the level is returned, otherwise 0 is returned
--
function Skillet:GetLevelRequiredToUse(item)
	if not item then return end
--  local level = select(5, GetItemInfo(item))
--	if not level then level = 0 end
--	return level
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
	  itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, 
	  isCraftingReagent = GetItemInfo(item)
--
-- is the return value OK?
--
	if not itemMinLevel then itemMinLevel = 0 end
	return itemMinLevel
end

--
-- If an item has an item level, then it
-- is returned, otherwise 0 is returned
--
function Skillet:GetItemLevel(item)
	if not item then return end
--  local level = select(4, GetItemInfo(item))
--	if not level then level = 0 end
--	return level
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
	  itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, 
	  isCraftingReagent = GetItemInfo(item)
--
-- is the return value OK?
--
	if not itemLevel then itemLevel = 0 end
	if type(itemLevel) ~= "number" then
		DA.DEBUG(0,"GetItemLevel("..tostring(item)..")= "..tostring(itemLevel))
		itemLevel = 0
	end
	return itemLevel
end

function Skillet:GetItemIDFromLink(link)	-- works with items or enchants
	--DA.DEBUG(3,"GetItemIDFromLink("..tostring(DA.PLINK(link))..")")
	if (link) then
		local linktype, id = string.match(link, "|H([^:]+):(%d+)")
		--DA.DEBUG(3,"linktype= "..tostring(linktype)..", id= "..tostring(id))
		if id then
			return tonumber(id), tostring(linktype)
		end
	end
end

--
-- Checks a link and returns the level of the that item's quality. If the link is
-- invalid, or not item quality could be found, nil is returned.
--
-- Handy info: _G["ITEM_QUALITY" .. level .. "_DESC"] returns "Epic", etc (localized)
--
-- @return
--     level: from 0 (Poor) to 6 (Artifact).
--     r, g, b: color code for the items color
--     hex: hexidecimal representation of the string, as well as "|c" in the beginning.
--
function Skillet:GetQualityFromLink(link)
	if (not link) then return end
	local color = link:match("(|c%x+)|Hitem:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+|h%[.-%]|h|r")
	if (color) then
		for i = 0, 6 do
			local r, g, b, hex = GetItemQualityColor(i)
			if color == hex then
				-- found it
				return i, r, g, b, hex
			end
		end
	end
--
-- no match
--
end

--
-- Returns the name of the current trade skill
--
function Skillet:GetTradeName(tradeID)
	--DA.DEBUG(2,"GetTradeName("..tostring(tradeID)..")")
	local tradeNameT,tradeNameS
	tradeNameT = Skillet.tradeSkillNamesByID[tradeID]
	tradeNameS = GetSpellInfo(tradeID)
	--DA.DEBUG(2,"tradeNameT= "..tostring(tradeNameT)..", tradeNameS= "..tostring(tradeNameS))
	if not tradeNameT then
		return tradeNameS
	end
	return tradeNameT
end

--
-- Returns a link for the currently selected tradeskill item.
-- The input is an index into the currently selected tradeskill
-- or craft.
--
function Skillet:GetTradeSkillItemLink(index)
	--DA.DEBUG(2,"GetTradeSkillItemLink("..tostring(index)..") currentTrade= "..tostring(self.currentTrade))
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, index)
	local _, link
	if recipe then
		if self.isCraft then
			link = GetCraftItemLink(index)
		else
			_, link = GetItemInfo(recipe.itemID)
		end
		return link
	end
	return nil
end

function Skillet:GetNumTradeSkills(tradeOverride, playerOverride)
	local tradeID = tradeOverride or self.currentTrade
	local player = playerOverride or self.currentPlayer
		local numSkills = #self.db.realm.skillDB[playerOverride][tradeID]
		return numSkills
end

function Skillet:GetTradeSkillCooldown(skillIndex)
	local skill = self.GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
		if skill then
		local coolDown = skill.cooldown
		local now = GetTime()
		if coolDown then
			return math.max(0,coolDown - now)
		end
	end
end

function Skillet:GetTradeSkillNumReagents(skillIndex)
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		return #recipe.reagentData
	end
end

function Skillet:GetTradeSkillReagentInfo(skillIndex, reagentIndex)
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		local reagentID = recipe.reagentData[reagentIndex].id
		local reagentName = GetItemInfo(reagentID)
		local reagentTexture = GetItemIcon(reagentID)
		local reagentCount = recipe.reagentData[reagentIndex].numNeeded
		local playerReagentCount = self:GetInventory(reagentID)
		return reagentName, reagentTexture, reagentCount, playerReagentCount
	end
end

--
-- Returns a link for the reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function Skillet:GetTradeSkillReagentItemLink(skillIndex, index)
	--DA.DEBUG(2,"GetTradeSkillReagentItemLink("..tostring(skillIndex)..", "..tostring(index)..") currentTrade= "..tostring(self.currentTrade))
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and recipe.reagentData[index] then
			local _, link = GetItemInfo(recipe.reagentData[index].id)
			return link
		end
	end
		return nil
end

function Skillet:GetTradeSkillTools(skillIndex)
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
		if skill then
		local recipe = self:GetRecipe(skill.id)
		local toolList = {}
		for i=1,#recipe.tools do
			toolList[i*2-1] = recipe.tools[i]
			toolList[i*2  ] = skill.tools[i] or 1
		end
		return unpack(toolList)
	end
end

function Skillet:ExpandTradeSkillSubClass(skillIndex)
end

--
-- Gets the trade skill line, and knows how to do the right
-- thing depending on whether or not this is a craft.
--
function Skillet:GetTradeSkillLine()
	DA.DEBUG(0,"GetTradeSkillLine(), currentTrade= "..tostring(self.currentTrade))
	if self.currentTrade then
		local tradeName = GetSpellInfo(self.currentTrade)
		local ranks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
		local rank, maxRank
		if ranks then
			rank, maxRank = ranks.rank, ranks.maxRank
		else
			rank, maxRank = 0, 0
		end
		DA.DEBUG(0,"GetTradeSkillLine= "..tostring(tradeName)..", "..tostring(rank)..", "..tostring(maxRank))
		return tradeName, rank, maxRank
	else
		return nil, nil, nil
	end
end

--
-- Returns the number of trade or craft skills
--
function Skillet:GetNumTradeSkills()
	return self:GetNumSkills(self.currentPlayer, self.currentTrade)
end

function Skillet:GetTradeSkillCooldown(index)
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, index)
		if skill and skill.cooldown then
		local cooldown = skill.cooldown - GetTime()
		if cooldown > 0 then
			return cooldown
		end
	end
end

function Skillet:GetTradeSkillIcon(skillIndex)
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	local texture
	if recipe then
		if recipe.numMade > 0 then
			texture = GetItemIcon(recipe.itemID)						-- get the item texture
		else
			texture = "Interface\\Icons\\Spell_Holy_GreaterHeal"		-- standard enchant icon
		end
	end
	return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function Skillet:GetTradeSkillNumMade(skillIndex)
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		return recipe.numMade, recipe.numMade
	end
	return 1,1
end
