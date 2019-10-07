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

local L = LibStub("AceLocale-3.0"):GetLocale("Skillet")

--
-- internal recipe filter
-- filter this recipe based on the filters selected in the Filter dropdown
--
function Skillet:RecipeFilter(skillIndex)
	DA.DEBUG(1,"RecipeFilter("..tostring(skillIndex)..")")
	local skill = Skillet:GetSkill(Skillet.currentPlayer, Skillet.currentTrade, skillIndex)
	--DA.DEBUG(1,"skill= "..DA.DUMP1(skill,1))
	local recipe = Skillet:GetRecipe(skill.id)
	--DA.DEBUG(1,"recipe= "..DA.DUMP1(recipe,1))
--
-- this test should not be needed 
--
	local recipeID = recipe.spellID or 0
	if recipeID == 0 then
		DA.DEBUG(1,"Detected header")
		return false
	end
--
-- no filters detected
--
return false
end

--
-- called when the new filter drop down is first loaded
--
function Skillet:FilterDropDown_OnLoad()
	DA.DEBUG(0,"FilterDropDown_OnLoad()")
	UIDropDownMenu_Initialize(SkilletFilterDropdown, Skillet.FilterDropDown_Initialize)
	SkilletFilterDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
end

--
-- Called when the new filter drop down is displayed
--
function Skillet:FilterDropDown_OnShow()
	DA.DEBUG(0,"FilterDropDown_OnShow()")
	UIDropDownMenu_Initialize(SkilletFilterDropdown, Skillet.FilterDropDown_Initialize)
	SkilletFilterDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	if Skillet.unlearnedRecipes then
		UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 2)
	else
		UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 1)
	end
end

--
-- The method we use the initialize the new filter drop down.
--
function Skillet:FilterDropDown_Initialize()
	DA.DEBUG(0,"FilterDropDown_Initialize()")
	local info
	local i = 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["None"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1

--[[
	info = UIDropDownMenu_CreateInfo()
	info.text = L["SubClass"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Slot"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1
]]--
end

--
-- Called when the user selects an item in the new filter drop down
--
function Skillet:FilterDropDown_OnClick()
	DA.DEBUG(0,"FilterDropDown_OnClick()")
	UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, self:GetID())
	local index = self:GetID()
	if index == 1 then
--		Skillet:SetTradeSkillLearned()
	elseif index == 2 then
--		Skillet:SetTradeSkillUnlearned()
	end
	Skillet.dataScanned = false
	Skillet:RescanTrade()
	Skillet:UpdateTradeSkillWindow()
end
