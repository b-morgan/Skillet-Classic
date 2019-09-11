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

-- This file contains all the code I use to access recipe/tradeskill information

-- If an item requires a specific level before it can be used, then
-- the level is returned, otherwise 0 is returned
--
-- item can be: itemID or "itemString" or "itemName" or "itemLink"
function Skillet:GetLevelRequiredToUse(item)
	if not item then return end
		local level = select(5, GetItemInfo(item))
	if not level then level = 0 end
	return level
end

function Skillet:GetItemIDFromLink(link)	-- works with items or enchants
	if (link) then
		local linktype, id = string.match(link, "|H([^:]+):(%d+)")
		if id then
			return tonumber(id);
		else
			return nil
		end
	end
end

-- return GetItemInfo and automatically query server if not cached
function Skillet:GetItemInfo(id)
	if id then
		local name = GetItemInfo(id)
		if not name then
			GameTooltip:SetHyperlink("item:"..id)
			GameTooltip:SetHyperlink("enchant:"..id)
		end
		return GetItemInfo(id)
	end
end

-- Wrapper that calls the correct Get*Info for crafts and trades as appropriate
function Skillet:GetTradeSkillInfo(skillIndex)
	local tradeID = self.currentTrade
	local skill = self:GetSkill(self.currentPlayer, tradeID, skillIndex)
	if skill then
		local id = skill.id
		local skillName = self:GetRecipeName(id)
		local difficulty = skill.difficulty
		if id and id ~= 0 then
			local recipe = self:GetRecipe(id)
			local numAvailable = (skill.numCraftable or 0) / (recipe.numMade or 1)
			return skillName, difficulty, numAvailable, 0	
		else
			return skillName, "header", 0, 1
		end
	else
		return nil, nil, nil, nil
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
	-- no match
end

-- Returns the name of the current trade skill
function Skillet:GetTradeName(tradeID)
	return (GetSpellInfo(tradeID))
end

-- Returns a link for the currently selected tradeskill item.
-- The input is an index into the currently selected tradeskill
-- or craft.
function Skillet:GetTradeSkillItemLink(index)
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, index)
		if recipe then
		local _, link = GetItemInfo(recipe.itemID)
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

-- Returns a link for the reagent required to create the specified
-- item, the index'th reagent required for the item is returned
function Skillet:GetTradeSkillReagentItemLink(skillIndex, index)
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and recipe.reagentData[index] then
			local _, link = GetItemInfo(recipe.reagentData[index].id)
			return link;
		end
	end
		return nil
end

-- Gets a link to the recipe (not the item creafted by the recipe)
-- for the current tradeskill
function Skillet:GetTradeSkillRecipeLink(skillIndex)
	local recipe, id = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe and id then
--	DA.DEBUG(0,"get tradeskill recipe link: "..(id or "nil"))
		local link = GetSpellLink(id)		
		return link
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

-- Gets the trade skill line, and knows how to do the right
-- thing depending on whether or not this is a craft.
function Skillet:GetTradeSkillLine()
	local tradeName = GetSpellInfo(self.currentTrade)
	local ranks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
		local rank, maxRank
	if ranks then
		rank, maxRank = ranks.rank, ranks.maxRank
	else
		rank, maxRank = 0, 0
	end
	DA.DEBUG(0,"GetTradeSkillLine "..(tradeName or "nil").." "..(rank or "nil").." "..(maxRank or "nil"))	
	return tradeName, rank, maxRank
end

-- Returns the number of trade or craft skills
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

function Skillet:internal_GetCraftersForItem(itemId)
	return nil
end
