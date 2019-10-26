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
--
-- filter this recipe based on the values selected in the filter dropdown
--
-- most of the work has already been done and is stored in:
--   subClass = Skillet.db.realm.subClass[player][tradeID]
--   invSlot = Skillet.db.realm.invSlot[player][tradeID]
-- indexed by itemID with the choices stored in a table:
--   Skillet.db.realm.subClass[player][tradeID].name
--   Skillet.db.realm.invSlot[player][tradeID].name
--
-- the filter dropdown will offer the choices in the name table
-- and will set two global variables:
--   Skillet.db.realm.subClass[player][tradeID].selected
--   Skillet.db.realm.invSlot[player][tradeID].selected
--
--[[
	["invSlot"] = {
		["player"] = {
			[2550] = {
				[4343] = "INVTYPE_LEGS",
				["name"] = {
					[""] = 13,
					["INVTYPE_BODY"] = 4,
					["INVTYPE_FEET"] = 2,
					["INVTYPE_LEGS"] = 2,
					["INVTYPE_CLOAK"] = 2,
					["INVTYPE_BAG"] = 1,
				},
	["subClass"] = {
		["player"] = {
			[2550] = {
				[4343] = "Cloth",
				["name"] = {
					["Bag"] = 1,
					["Cloth"] = 12,
				},
]]--

function Skillet:RecipeFilter(skillIndex)
	--DA.DEBUG(1,"RecipeFilter("..tostring(skillIndex)..")")
	local skill = Skillet:GetSkill(Skillet.currentPlayer, Skillet.currentTrade, skillIndex)
	--DA.DEBUG(1,"skill= "..DA.DUMP1(skill,1))
	local recipe = Skillet:GetRecipe(skill.id)
	--DA.DEBUG(1,"recipe= "..DA.DUMP1(recipe,1))
	local subClass = Skillet.db.realm.subClass[Skillet.currentPlayer][Skillet.currentTrade]
	local invSlot = Skillet.db.realm.invSlot[Skillet.currentPlayer][Skillet.currentTrade]
	local itemID = recipe.itemID
	--DA.DEBUG(1,"RecipeFilter: itemID= "..tostring(itemID)..", subClass= "..tostring(subClass[itemID])..", invSlot= "..tostring(invSlot[itemID]))
	--DA.DEBUG(1,"RecipeFilter: subClass.selected= "..tostring(subClass.selected)..", invSlot.selected= "..tostring(invSlot.selected))
	if not ItemID and not subClass.selected and not invSlot.selected then
--
-- not initialized yet
--
		--DA.DEBUG(1,"RecipeFilter: not initialized yet")
		return false
	end
	if subClass.selected == "None" and invSlot.selected == "None" then
--
-- not filtering anything
--
		--DA.DEBUG(1,"RecipeFilter: not filtering anything")
		return false
	end
	if subClass[itemID] == subClass.selected or invSlot[itemID] == invSlot.selected then
--
-- filtering active, return only items that meet the criteria
--
		--DA.DEBUG(1,"RecipeFilter: filtering active, item met the criteria")
		return false
	end
--
-- filtering active, item did not meet the criteria
--
	--DA.DEBUG(1,"RecipeFilter: filtering active, item did not meet the criteria")
	return true
end

--
-- Called when the new filter drop down is displayed
--
function Skillet:FilterDropDown_OnShow()
	--DA.DEBUG(0,"FilterDropDown_OnShow()")
	UIDropDownMenu_Initialize(SkilletFilterDropdown, Skillet.FilterDropDown_Initialize)
	SkilletFilterDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 1)
end

--
-- called when the new filter drop down is first loaded
--
function Skillet:FilterDropDown_OnLoad()
	--DA.DEBUG(0,"FilterDropDown_OnLoad()")
	UIDropDownMenu_Initialize(SkilletFilterDropdown, Skillet.FilterDropDown_Initialize)
	SkilletFilterDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, 1)
end

--
-- The method we use the initialize the new filter drop down.
--
function Skillet.FilterDropDown_Initialize(menuFrame,level)
	--DA.DEBUG(0,"FilterDropDown_Initialize()")
	local player, tradeID = Skillet.currentPlayer, Skillet.currentTrade
	if not player or not tradeID then return end
	local subClass = Skillet.db.realm.subClass[player][tradeID]
	local invSlot = Skillet.db.realm.invSlot[player][tradeID]
	local index = 1
	local info
	info = UIDropDownMenu_CreateInfo()
	info.text = L["None"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = index
	info.arg1 = "None"
	info.arg2 = "None"
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	index = index + 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["SubClass"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = index
	info.isTitle = true
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	index = index + 1

	if subClass.name then
		for n,c in pairs(subClass.name) do
			info = UIDropDownMenu_CreateInfo()
			info.text = "    "..(n or "")
			info.func = Skillet.FilterDropDown_OnClick
			info.value = index
			info.arg1 = n
			info.arg2 = "None"
			if self then
				info.owner = self:GetParent()
			end
			UIDropDownMenu_AddButton(info)
			index = index + 1
		end
	end

	info = UIDropDownMenu_CreateInfo()
	info.text = L["InvSlot"]
	info.func = Skillet.FilterDropDown_OnClick
	info.value = index
	info.isTitle = true
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	index = index + 1

	if invSlot.name then
		for n,c in pairs(invSlot.name) do
			info = UIDropDownMenu_CreateInfo()
			info.text = "    "..(_G[n] or "")
			info.func = Skillet.FilterDropDown_OnClick
			info.value = index
			info.arg1 = "None"
			info.arg2 = n
			if self then
				info.owner = self:GetParent()
			end
			UIDropDownMenu_AddButton(info)
			index = index + 1
		end
	end
end

--
-- Called when the user selects an item in the new filter drop down
--
function Skillet:FilterDropDown_OnClick(arg1,arg2)
	--DA.DEBUG(0,"FilterDropDown_OnClick("..tostring(arg1)..", "..tostring(arg2)..")")
	UIDropDownMenu_SetSelectedID(SkilletFilterDropdown, self:GetID())
	Skillet.db.realm.subClass[Skillet.currentPlayer][Skillet.currentTrade].selected = arg1
	Skillet.db.realm.invSlot[Skillet.currentPlayer][Skillet.currentTrade].selected = arg2
	Skillet.dataScanned = false
	Skillet:UpdateTradeSkillWindow()
end
