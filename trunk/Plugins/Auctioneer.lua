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

Skillet.AUCPlugin = {}

local plugin = Skillet.AUCPlugin
local L = Skillet.L

plugin.options =
{
	type = 'group',
	name = "Auctioneer",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return Skillet.db.profile.plugins.AUC.enabled
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.enabled = value
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
				return Skillet.db.profile.plugins.AUC.useShort
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.useShort = value
				if value then
					Skillet.db.profile.plugins.AUC.useShort = value
				end
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = "Only show positive values",
			get = function()
				return Skillet.db.profile.plugins.AUC.onlyPositive
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.onlyPositive = value
				if value then
					Skillet.db.profile.plugins.AUC.onlyPositive = value
				end
			end,
			order = 3
		},
		reagentPrices = {
			type = "toggle",
			name = "reagentPrices",
			desc = "Show prices for reagents",
			get = function()
				return Skillet.db.profile.plugins.AUC.reagentPrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.reagentPrices = value
				if value then
					Skillet.db.profile.plugins.AUC.reagentPrices = value
				end
			end,
			order = 4
		},
		buyablePrices = {
			type = "toggle",
			name = "buyablePrices",
			desc = "Show AH prices for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.AUC.buyablePrices
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.buyablePrices = value
				if value then
					Skillet.db.profile.plugins.AUC.buyablePrices = value
				end
			end,
			order = 5
		},
		useVendorCalc = {
			type = "toggle",
			name = "useVendorCalc",
			desc = "Show calculated cost from vendor sell price for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.AUC.useVendorCalc
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.useVendorCalc = value
				if value then
					Skillet.db.profile.plugins.AUC.useVendorCalc = value
				end
			end,
			order = 6
		},
		buyFactor = {
			type = "range",
			name = "buyFactor",
			desc = "Multiply vendor sell price by this to get calculated buy price",
			min = 1, max = 10, step = 1, isPercent = false,
			get = function()
				return Skillet.db.profile.plugins.AUC.buyFactor
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.buyFactor = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 10
		},
		markup = {
			type = "range",
			name = "Markup %",
			min = 0, max = 2, step = 0.01, isPercent = true,
			get = function()
				return Skillet.db.profile.plugins.AUC.markup
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.AUC.markup = value
			end,
			width = "double",
			order = 11,
		},
	},
}

--
-- Until we can figure out how to get defaults into the "range" variables above
--
local buyFactorDef = 4
local markupDef = 1.05

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.AUC then
		Skillet.db.profile.plugins.AUC = {}
		Skillet.db.profile.plugins.AUC.enabled = true
		Skillet.db.profile.plugins.AUC.buyFactor = buyFactorDef
		Skillet.db.profile.plugins.AUC.markup = markupDef
	end
	Skillet:AddPluginOptions(plugin.options)
end

local function GetMarketValue(itemLink)
	if AucAdvanced.API.GetMarketValue then
		return AucAdvanced.API.GetMarketValue(itemLink) or nil
	end
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	if not recipe then return end
	local itemID = recipe.itemID
	if Skillet.db.profile.plugins.AUC.enabled and itemID and IsAddOnLoaded("Auc-Advanced") and AucAdvanced then
		local itemName, itemLink = GetItemInfo(itemID)
		local market = ( GetMarketValue(itemLink) or 0 ) * recipe.numMade
		if market then
			extra_text = Skillet:FormatMoneyFull(market, true)
			label = "|r".."AUC "..L["Market"]..":"
		end
		if Skillet.db.profile.plugins.AUC.reagentPrices then
			local toConcatLabel = {}
			local toConcatExtra = {}
			local cost = 0
			for i=1, #recipe.reagentData, 1 do
				local reagent = recipe.reagentData[i]
				if not reagent then
					break
				end
				local needed = reagent.numNeeded or 0
				local id = reagent.id
				local reagentName, reagentLink
				if id then
					reagentName, reagentLink = GetItemInfo(id)
				else
					reagentName = tostring(id)
				end
				local text
				local value = ( GetMarketValue(reagentLink) or 0 ) * needed
				local buyFactor = Skillet.db.profile.plugins.AUC.buyFactor or buyFactorDef
				if Skillet:VendorSellsReagent(id) then
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, reagentName, L["buyable"])
					if Skillet.db.profile.plugins.AUC.buyablePrices then
						if Skillet.db.profile.plugins.AUC.useVendorCalc then
							local sellValue = select(11, GetItemInfo(id))
							value = ( sellValue or 0 ) * needed * buyFactor
						end
						toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
					else
						value = 0
						toConcatExtra[#toConcatExtra+1] = ""
					end
				else
					toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s", needed, reagentName)
				end
				cost = cost + value
			end
			if Skillet.db.profile.plugins.AUC.useVendorCalc then
				local markup = Skillet.db.profile.plugins.AUC.markup or markupDef
				label = label .. "\n\n" .. table.concat(toConcatLabel,"\n") .. "\n   " .. L["Reagents"] .." * ".. (markup * 100) .."%:\n"
				extra_text =  extra_text .. "\n\n" .. table.concat(toConcatExtra,"\n") .. "\n" .. Skillet:FormatMoneyFull(cost * markup, true) .. "\n"
			else
				label = label .. "\n\n" .. table.concat(toConcatLabel,"\n") .. "\n   " .. L["Reagents"] .. ":\n"
				extra_text =  extra_text .. "\n\n" .. table.concat(toConcatExtra,"\n") .. "\n" .. Skillet:FormatMoneyFull(cost, true) .. "\n"
			end
		end
	end
	return label, extra_text
end

function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if not recipe then return end
	local itemID = recipe.itemID
	if Skillet.db.profile.plugins.AUC.enabled and itemID and IsAddOnLoaded("Auc-Advanced") and AucAdvanced then
		local buyout = ( GetMarketValue(itemLink) or 0 ) * recipe.numMade
		if Skillet.db.profile.plugins.AUC.reagentPrices then
			local cost = 0
			for i=1, #recipe.reagentData, 1 do
				local needed = recipe.reagentData[i].numNeeded or 0
				local id = recipe.reagentData[i].id
				local value = ( GetMarketValue(itemLink) or 0 ) * needed
				local buyFactor = Skillet.db.profile.plugins.AUC.buyFactor or buyFactorDef
				if Skillet:VendorSellsReagent(id) then
					if Skillet.db.profile.plugins.AUC.buyablePrices then
						if Skillet.db.profile.plugins.AUC.useVendorCalc then
							local sellValue = select(11, GetItemInfo(id))
							value = ( sellValue or 0 ) * needed * buyFactor
						end
					else
						value = 0
					end
				end
				cost = cost + value
			end
			if Skillet.db.profile.plugins.AUC.useVendorCalc then
				local markup = Skillet.db.profile.plugins.AUC.markup or markupDef
				cost = cost * markup
			end
			local profit = buyout - cost
			if Skillet.db.profile.plugins.AUC.useShort then
				text = Skillet:FormatMoneyShort(profit, true)
			else
				text = Skillet:FormatMoneyFull(profit, true)
			end
			if Skillet.db.profile.plugins.AUC.onlyPositive and profit <= 0 then
				text = nil
			end
		end
	end
	return text
end

Skillet:RegisterRecipeNamePlugin("AUCPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("AUCPlugin")	-- we have a GetExtraText function
