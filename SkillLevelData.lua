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

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

local PT = LibStub("LibPeriodicTable-3.1")

local skillColors = {
	["unknown"]		= { r = 1.00, g = 0.00, b = 0.00, level = 5, alttext="???", cstring = "|cffff0000"},
	["optimal"]		= { r = 1.00, g = 0.50, b = 0.25, level = 4, alttext="+++", cstring = "|cffff8040"},
	["medium"]		= { r = 1.00, g = 1.00, b = 0.00, level = 3, alttext="++",  cstring = "|cffffff00"},
	["easy"]		= { r = 0.25, g = 0.75, b = 0.25, level = 2, alttext="+",   cstring = "|cff40c000"},
	["trivial"]		= { r = 0.50, g = 0.50, b = 0.50, level = 1, alttext="",    cstring = "|cff808080"},
	["header"]		= { r = 1.00, g = 0.82, b = 0,    level = 0, alttext="",    cstring = "|cffffc800"},
}

--
-- Our own table of skill levels (Skillet.db.global.SkillLevels)
--   1) can be maintained manually
--   2) can be scrapped from an external website like https://classic.wowhead.com/
--   3) can be maintained with an external addon (using AddTradeSkillLevels, DelTradeSkillLevels)
--
-- Each entry is: [itemID] = "orange/yellow/green/gray"
--   itemID is the item made by the recipe or the recipeID of the Enchant
--   orange is the (numeric) skill level below which recipe is orange
--   yellow is the (numeric) skill level below which the recipe is yellow
--   green  is the (numeric) skill level below which the recipe is green
--   gray   is the (numeric) skill level above which the recipe is gray
--
-- A global table, Skillet.db.global.MissingSkillLevels, is added to when
-- no other entry is found. The format of this table is the same as
-- the table Skillet.db.global.SkillLevels to facilitate adding to this table.
--

function Skillet:InitializeSkillLevels()
	self.db.global.SkillLevels = {
		[0] = "orange/yellow/green/gray",
		[7818] = "100/105/107/110",
	}
end

function Skillet:GetTradeSkillLevels(itemID)
	DA.DEBUG(0,"GetTradeSkillLevels("..tostring(itemID)..")")
	local a,b,c,d
	local skillLevels = Skillet.db.global.SkillLevels
	if itemID then 
		if tonumber(itemID) ~= nil and itemID ~= 0 then
			if self.isCraft then
				itemID = -itemID
			end
--
-- If there is an entry in our own table, use it
--
			if skillLevels and skillLevels[itemID] then
				--DA.DEBUG(0,"levels= "..tostring(skillLevels[itemID]))
				a,b,c,d = string.split("/", skillLevels[itemID])
				a = tonumber(a) or 0
				b = tonumber(b) or 0
				c = tonumber(c) or 0
				d = tonumber(d) or 0
				return a, b, c, d
			end
--
-- The TradeskillInfo addon seems to be more accurate than LibPeriodicTable-3.1
--
			if isRetail and TradeskillInfo then
				local recipeSource = Skillet.db.global.itemRecipeSource[itemID]
				if type(recipeSource) == 'table' then
					--DA.DEBUG(0,"recipeSource= "..DA.DUMP1(recipeSource))
					for recipeID in pairs(recipeSource) do
						--DA.DEBUG(1,"recipeID= "..tostring(recipeID))
						local TSILevels = TradeskillInfo:GetCombineDifficulty(recipeID)
						if type(TSILevels) == 'table' then
							--DA.DEBUG(1,"TSILevels="..DA.DUMP1(TSILevels))
							a = tonumber(TSILevels[1]) or 0
							b = tonumber(TSILevels[2]) or 0
							c = tonumber(TSILevels[3]) or 0
							d = tonumber(TSILevels[4]) or 0
							return a, b, c, d
						end
					end
				else
					--DA.DEBUG(0,"recipeSource= "..tostring(recipeSource))
				end
			end
--
-- Check LibPeriodicTable
-- Note: The itemID for Enchants is negative
--
			if PT then
				local levels = PT:ItemInSet(itemID,"TradeskillLevels")
				if levels then
					--DA.DEBUG(0,"levels= "..tostring(levels))
					a,b,c,d = string.split("/",levels)
					a = tonumber(a) or 0
					b = tonumber(b) or 0
					c = tonumber(c) or 0
					d = tonumber(d) or 0
					return a, b, c, d
				end
			end
		end
	end
	if not Skillet.db.global.MissingSkillLevels then
		Skillet.db.global.MissingSkillLevels = {}
	end
	Skillet.db.global.MissingSkillLevels[itemID] = "0/0/0/0"
	return 0, 0, 0, 0 
end

function Skillet:GetTradeSkillLevelColor(itemID, rank)
	--DA.DEBUG(0,"GetTradeSkillLevelColor("..tostring(itemID)..", "..tostring(rank)")")
	if itemID then
		local orange, yellow, green, gray = self:GetTradeSkillLevels(itemID)
		if rank >= gray then return skillColors["trivial"] end
		if rank >= green then return skillColors["easy"] end
		if rank >= yellow then return skillColors["moderate"] end
		if rank >= orange then return skillColors["optimal"] end
	end
	return skillColors["unknown"]
end

function Skillet:AddTradeSkillLevels(itemID, orange, yellow, green, gray)
	--DA.DEBUG(0,"AddTradeSkillLevels("..tostring(itemID)..", "..tostring(orange)..", "..tostring(yellow)..", "..tostring(green)..", "..tostring(gray)..")")
	local skillLevels = Skillet.db.global.SkillLevels
	if itemID then
--
-- should add some sanity checking 
--
		skillLevels[itemID] = tostring(orange).."/"..tostring(yellow).."/"..tostring(green).."/"..tostring(gray)
	end
end

function Skillet:DelTradeSkillLevels(itemID)
	--DA.DEBUG(0,"DelTradeSkillLevels("..tostring(itemID)..")")
	local skillLevels = Skillet.db.global.SkillLevels
	if itemID then
--
-- we could add some additional checking
--
		skillLevels[itemID] = nil
	end
end
