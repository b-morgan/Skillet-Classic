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

Skillet.ATRPlugin = {}

local plugin = Skillet.ATRPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "Auctionator",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.ATR.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.enabled = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
		useShort = {
			type = "toggle",
			name = "useShort",
			desc = "Use Short money format",
			get = function()
				return Skillet.db.profile.plugins.ATR.useShort
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useShort = value
				if value then
					Skillet.db.profile.plugins.ATR.useShort = value
				end
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = "Only show positive values",
			get = function()
				return Skillet.db.profile.plugins.ATR.onlyPositive
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.onlyPositive = value
				if value then
					Skillet.db.profile.plugins.ATR.onlyPositive = value
				end
			end,
			order = 3
		},
		reagentPrices = {
			type = "toggle",
			name = "reagentPrices",
			desc = "Show prices for reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.reagentPrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.reagentPrices = value
				if value then
					Skillet.db.profile.plugins.ATR.reagentPrices = value
				end
			end,
			order = 4
		},
		buyablePrices = {
			type = "toggle",
			name = "buyablePrices",
			desc = "Show AH prices for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.buyablePrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.buyablePrices = value
				if value then
					Skillet.db.profile.plugins.ATR.buyablePrices = value
				end
			end,
			order = 5
		},
	},
}

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.ATR then
		Skillet.db.profile.plugins.ATR = {}
		Skillet.db.profile.plugins.ATR.enabled = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if not skill or not recipe then return end
	local itemID = recipe.itemID
	if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.ATR.enabled and itemID then
		local value = ( Atr_GetAuctionBuyout(itemID) or 0 ) * recipe.numMade
		if value then
			extra_text = Skillet:FormatMoneyFull(value, true)
			label = "|r".. L["Buyout"]..":"
		end
		if Skillet.db.profile.plugins.ATR.reagentPrices then
			local toConcatLabel = {}
			local toConcatExtra = {}
			local total = 0
			for i=1, #recipe.reagentData, 1 do
				local reagent = recipe.reagentData[i]
				if not reagent then
					break
				end
				local needed = reagent.numNeeded or 0
				local id = reagent.id
				local itemName
				if id then
					itemName = GetItemInfo(id)
				else
					itemName = tostring(id)
				end
				local text
				local value = ( Atr_GetAuctionBuyout(id) or 0 ) * needed
				if Skillet:VendorSellsReagent(id) then
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, itemName, L["buyable"])
					if Skillet.db.profile.plugins.ATR.buyablePrices then
						toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
					else
						toConcatExtra[#toConcatExtra+1] = ""
						value = 0
					end
				else
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s", needed, itemName)
					toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
				end
				total = total + value
			end
			label = label .. "\n\n" .. table.concat(toConcatLabel,"\n") .. "\n   " .. L["Reagents"] .. ":\n"
			extra_text =  extra_text .. "\n\n" .. table.concat(toConcatExtra,"\n") .. "\n" .. Skillet:FormatMoneyFull(total, true) .. "\n"
		end
	end
	return label, extra_text
end

function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if recipe then
		local itemID = recipe.itemID
		if Atr_GetAuctionBuyout and Skillet.db.profile.plugins.ATR.enabled and itemID then
			local value = Atr_GetAuctionBuyout(itemID)
			if value then
				value = value * recipe.numMade
				local matsum = 0
				for k,v in pairs(recipe.reagentData) do
					local iprice = Atr_GetAuctionBuyout(v.id)
					if iprice then
						matsum = matsum + v.numNeeded * iprice
					end
				end
				value = value - matsum
				if Skillet.db.profile.plugins.ATR.useShort then
					text = Skillet:FormatMoneyShort(value, true)
				else
					text = Skillet:FormatMoneyFull(value, true)
				end
				if Skillet.db.profile.plugins.ATR.onlyPositive and value <= 0 then
					text = nil
				end
			end
		end
	end
	return text
end

Skillet:RegisterRecipeNamePlugin("ATRPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("ATRPlugin")	-- we have a GetExtraText function

--
-- Auctionator support (moved here from MainFrame.lua)
-- needs to be debugged on Classic
--
function Skillet:AuctionatorSearch()
	if not AuctionatorLoaded or not AuctionFrame then
		return
	end
	if not AuctionFrame:IsShown() then
		Atr_Error_Display ("When the Auction House is open\nclicking this button tells Auctionator\nto scan for the item and all its reagents.")
		return
	end
	local recipe, recipeId = Skillet:GetRecipeDataByTradeIndex(Skillet.currentTrade, Skillet.selectedSkill)
	if not recipe then
		return
	end
	local BUY_TAB = 3;
	Atr_SelectPane(BUY_TAB);
	local numReagents = #recipe.reagentData
	local shoppingListName = GetItemInfo(recipe.itemID)
	if (shoppingListName == nil) then
		shoppingListName = Skillet:GetRecipeName(recipeId)
	end
	local reagentIndex
	local items = {}
	if (shoppingListName) then
		table.insert (items, shoppingListName)
	end
	for reagentIndex = 1, numReagents do
		local reagentId = recipe.reagentData[reagentIndex].id
		if (reagentId and (reagentId ~= 3371)) then
			local reagentName = GetItemInfo(reagentId)
			if (reagentName) then
				table.insert (items, reagentName)
				-- DA.DEBUG(0, "Reagent num "..reagentIndex.." ("..reagentId..") "..reagentName.." added")
			end
		end
	end
	Atr_SearchAH(shoppingListName, items)
end
