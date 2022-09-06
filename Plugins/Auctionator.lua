local addonName,addonTable = ...
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = Skillet.build == "Wrath"
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

--
-- Includes changes from GuardsmanBogo
-- Includes changes from Dranni21312
--

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
			desc = "Show vendor prices for buyable reagents",
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
		useVendorCalc = {
			type = "toggle",
			name = "useVendorCalc",
			desc = "Show calculated cost from vendor sell price for buyable reagents",
			get = function()
				return Skillet.db.profile.plugins.ATR.useVendorCalc
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useVendorCalc = value
				if value then
					Skillet.db.profile.plugins.ATR.useVendorCalc = value
				end
			end,
			order = 6
		},
		useSearchExact = {
			type = "toggle",
			name = "useSearchExact",
			desc = "Use MultiSearchExact instead of MultSearch in Auction House shopping list",
			get = function()
				return Skillet.db.profile.plugins.ATR.useSearchExact
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.useSearchExact = value
				if value then
					Skillet.db.profile.plugins.ATR.useSearchExact = value
				end
			end,
			order = 7
		},
		exceptEnchanting = {
			type = "toggle",
			name = "exceptEnchanting",
			desc = "Ignore useSearchExact for Enchanting",
			get = function()
				return Skillet.db.profile.plugins.ATR.exceptEnchanting
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.exceptEnchanting = value
				if value then
					Skillet.db.profile.plugins.ATR.exceptEnchanting = value
				end
			end,
			order = 8
		},
		showProfitValue = {
			type = "toggle",
			name = "showProfitValue",
			desc = "Show profit as value",
			get = function()
				return Skillet.db.profile.plugins.ATR.showProfitValue
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.showProfitValue = value
				if value then
					Skillet.db.profile.plugins.ATR.showProfitValue = value
				end
			end,
			order = 9
		},
		showProfitPercentage = {
			type = "toggle",
			name = "showProfitPercentage",
			desc = "Show profit as percentage",
			get = function()
				return Skillet.db.profile.plugins.ATR.showProfitPercentage
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.showProfitPercentage = value
				if value then
					Skillet.db.profile.plugins.ATR.showProfitPercentage = value
				end
			end,
			order = 10
		},
		colorCode = {
			type = "toggle",
			name = "colorCode",
			desc = "Add color to the results",
			get = function()
				return Skillet.db.profile.plugins.ATR.colorCode
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.colorCode = value
				if value then
					Skillet.db.profile.plugins.ATR.colorCode = value
				end
			end,
			order = 11
		},
		alwaysEnchanting = {
			type = "toggle",
			name = "alwaysEnchanting",
			desc = "Always show Enchanting profit (loss)",
			get = function()
				return Skillet.db.profile.plugins.ATR.alwaysEnchanting
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.alwaysEnchanting = value
				if value then
					Skillet.db.profile.plugins.ATR.alwaysEnchanting = value
				end
			end,
			order = 12
		},
		buyFactor = {
			type = "range",
			name = "buyFactor",
			desc = "Multiply vendor sell price by this to get calculated buy price",
			min = 1, max = 10, step = 1, isPercent = false,
			get = function()
				return Skillet.db.profile.plugins.ATR.buyFactor
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.buyFactor = value
				Skillet:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 20
		},
		markup = {
			type = "range",
			name = "Markup %",
			min = 0, max = 2, step = 0.01, isPercent = true,
			get = function()
				return Skillet.db.profile.plugins.ATR.markup
			end,
			set = function(self,value)
				Skillet.db.profile.plugins.ATR.markup = value
			end,
			width = "double",
			order = 21,
		},
	},
}

--
-- Until we can figure out how to get defaults into the "range" variables above
--
local buyFactorDef = 4
local markupDef = 1.05

function plugin.OnInitialize()
	if not Skillet.db.profile.plugins.ATR then
		Skillet.db.profile.plugins.ATR = {}
		Skillet.db.profile.plugins.ATR.enabled = true
		Skillet.db.profile.plugins.ATR.buyFactor = buyFactorDef
		Skillet.db.profile.plugins.ATR.markup = markupDef
	end
	if Skillet.db.profile.plugins.ATR.showProfitValue == nil then
		Skillet.db.profile.plugins.ATR.showProfitValue = true
	end
	Skillet:AddPluginOptions(plugin.options)
end

local function profitPctText(profit,cost,limit)
	local profitPct, proPctTxt
	if cost and cost ~= 0 then
		profitPct = profit * 100 / cost
		if profitPct > limit then
			proPctTxt = ">"..tostring(limit)
		else
			proPctTxt = string.format("%.0d", profitPct)
		end
	else
		profitPct = 0.0
		proPctTxt = "0"
	end
	--DA.DEBUG(0,"profitPctText: profit= "..tostring(profit)..", cost= "..tostring(cost)..", limit= "..tostring(limit)..", proPctTxt= "..tostring(proPctTxt))
	return proPctTxt
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	if not recipe then return end
	local itemID = recipe.itemID
--
-- Check for Enchanting. 
--   In Classic Era, Most recipes don't produce an item but we still should get reagent prices.
--   In Wrath, Enchants can be applied to vellum to produce scrolls so use the scroll price instead.
--
	if recipe.tradeID == 7411 then
		--DA.DEBUG(0,"GetExtraText: itemID= "..tostring(itemID)..", type= "..type(itemID))
		if itemID then
			itemID = Skillet.EnchantSpellToItem[itemID] or 0
		end
		if itemID == 0 then
			--DA.DEBUG(0,"GetExtraText: recipe.name= "..tostring(recipe.name)..", recipe.spellID= "..tostring(recipe.spellID)..", recipe.scrollID= "..tostring(recipe.scrollID))
			itemID = recipe.scrollID
		end
	end
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
--
-- buyout is Auctionator's price (for one) times the number this recipe makes
--
		local buyout
		if Atr_GetAuctionBuyout then
			buyout = (Atr_GetAuctionBuyout(itemID) or 0) * recipe.numMade
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			buyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
		else
			return
		end
		if buyout then
			label = "|r".."ATR "..L["Buyout"]..":"
			extra_text = Skillet:FormatMoneyFull(buyout, true)
		end
--
-- Collect the price of reagents
--
		local toConcatLabel = {}
		local toConcatExtra = {}
		local cost = 0
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if not reagent then
				break
			end
			local needed = reagent.numNeeded or 0
			local id
			if isRetail then
				id = reagent.reagentID
			else
				id = reagent.id
			end
			local itemName = ""
			if id then
				itemName = GetItemInfo(id)
				if not itemName then
					itemName = ""
				end
			end
--
-- Default value for a reagent is the Auctionator price
--
			local value
			if Atr_GetAuctionBuyout then
				value = (Atr_GetAuctionBuyout(id) or 0) * needed
			elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
				value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0) * needed
			else
				value = 0
			end
			if not Skillet:VendorSellsReagent(id) then
--
-- Not sold by a vendor so use the default
--
				toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s", needed, itemName)
				toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
			else
				toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, itemName, L["buyable"])
				if Skillet.db.profile.plugins.ATR.buyablePrices then
--
-- If this reagent is sold by a vendor, then use that (calculated) price instead
--
					local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
					value = ( select(11,GetItemInfo(id)) or 0 ) * needed * buyFactor
					toConcatExtra[#toConcatExtra+1] = Skillet:FormatMoneyFull(value, true)
				else
--
-- If this reagent is sold by a vendor, don't use the Auctionator price
--
					value = 0
					toConcatExtra[#toConcatExtra+1] = ""
				end
			end
			cost = cost + value
		end
--
-- Show all the reagent information?
--
		if Skillet.db.profile.plugins.ATR.reagentPrices then
			label = label.."\n\n"..table.concat(toConcatLabel,"\n").."\n"
			extra_text = extra_text.."\n\n"..table.concat(toConcatExtra,"\n").."\n"
		else
			label = label.."\n"
			extra_text = extra_text.."\n"
		end
--
-- If reagents were priced as bought from a vendor, should we markup the price? 
--
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			label = label.."\n   "..L["Cost"].." * "..(markup * 100).."%:\n"
			cost = cost * markup
		else
			label = label.."\n   "..L["Cost"]..":\n"
		end
		extra_text = extra_text.."\n"..Skillet:FormatMoneyFull(cost, true).."\n"
--
-- If we craft this item, will we make a profit?
--
		if buyout then
			local profit = buyout - cost
			if Skillet.db.profile.plugins.ATR.showProfitValue or Skillet.db.profile.plugins.ATR.showProfitPercentage then
				label = label.."\n"
				extra_text = extra_text.."\n"
--
-- Show the profit absolute value and as a percentage of the cost
--
				label = label.."   Profit:\n"
				extra_text = extra_text..Skillet:FormatMoneyFull(profit, true).."\n"
				label = label.."   Profit percentage:\n"
				extra_text = extra_text..profitPctText(profit,cost,9999).."%\n"
			end
		end
	end
	return label, extra_text
end

--
-- Returns a text representation of profit, numerical value of profit (for sorting purposes)
--
function plugin.RecipeNameSuffix(skill, recipe)
	local text
	local profit
	if not recipe then return end
	--DA.DEBUG(0,"RecipeNameSuffix: recipe= "..DA.DUMP1(recipe,1))
	local itemID = recipe.itemID
--
-- Check for Enchanting. Most recipes don't produce an item but
-- we still should get reagent prices.
--
	if recipe.tradeID == 7411 then
		--DA.DEBUG(0,"RecipeNameSuffix: itemID= "..tostring(itemID)..", type= "..type(itemID))
		if itemID then
			itemID = Skillet.EnchantSpellToItem[itemID] or 0
		end
		if itemID == 0 then
			--DA.DEBUG(0,"RecipeNameSuffix: recipe.name= "..tostring(recipe.name)..", recipe.spellID= "..tostring(recipe.spellID)..", recipe.scrollID= "..tostring(recipe.scrollID))
			itemID = recipe.scrollID
		end
	end
	local itemName
	if itemID then itemName = GetItemInfo(itemID) end
	--DA.DEBUG(0,"RecipeNameSuffix: itemName= "..tostring(itemName)..", type= "..type(itemName))
	if Skillet.db.profile.plugins.ATR.enabled and itemID then
		local value
		if Atr_GetAuctionBuyout then
			value = Atr_GetAuctionBuyout(itemID) or 0
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			value = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0
		else
			return
		end
		--DA.DEBUG(0,"RecipeNameSuffix: value= "..tostring(value))
		local buyout = value * recipe.numMade
		local cost = 0
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if not reagent then
				break
			end
			local needed = reagent.numNeeded or 0
			local id
			if isRetail then
				id = reagent.reagentID
			else
				id = reagent.id
			end
			local name = GetItemInfo(id) or id
			local value
			if Atr_GetAuctionBuyout then
				value = (Atr_GetAuctionBuyout(id) or 0) * needed
			elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
				value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0) * needed
			else
				value = 0
			end
			if Skillet:VendorSellsReagent(id) then
				if Skillet.db.profile.plugins.ATR.buyablePrices then
					if Skillet.db.profile.plugins.ATR.useVendorCalc then
						local buyFactor = Skillet.db.profile.plugins.ATR.buyFactor or buyFactorDef
						value = ( select(11,GetItemInfo(id)) or 0 ) * needed * buyFactor
					end
				else
					value = 0
				end
			end
			--DA.DEBUG(1, "RecipeNameSuffix: reagent["..i.."] ("..id..") "..tostring(name)..", value= "..tostring(value))
			cost = cost + value
		end
		if Skillet.db.profile.plugins.ATR.useVendorCalc then
			local markup = Skillet.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		profit = buyout - cost
		if Skillet.db.profile.plugins.ATR.showProfitValue then
			if Skillet.db.profile.plugins.ATR.useShort then
				text = Skillet:FormatMoneyShort(profit, true, Skillet.db.profile.plugins.ATR.colorCode)
			else
				text = Skillet:FormatMoneyFull(profit, true, Skillet.db.profile.plugins.ATR.colorCode)
			end
		end
		if Skillet.db.profile.plugins.ATR.showProfitPercentage then
			if text then
				text = text.." ("..profitPctText(profit,cost,999).."%)"
			else
				text = "("..profitPctText(profit,cost,999).."%)"
			end
		end
--
-- Enchants don't have any profit so if checked, always display the (negative) cost.
--
		if recipe.tradeID == 7411 then
			if not Skillet.db.profile.plugins.ATR.alwaysEnchanting then
				if Skillet.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
					text = nil
				end
			end
		elseif Skillet.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
			text = nil
		end
	end
	--DA.DEBUG(0,"RecipeNameSuffix: text= "..tostring(text)..", profit= "..tostring(profit))
	recipe.suffix = profit
	return text, profit
end

Skillet:RegisterRecipeNamePlugin("ATRPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

Skillet:RegisterDisplayDetailPlugin("ATRPlugin")	-- we have a GetExtraText function

--
-- Auctionator button support
--  whichOne:
--    true will search for the items in the ShoppingList
--    false (or nil) will search for the item and reagents in the MainFrame
--
function Skillet:AuctionatorSearch(whichOne)
	DA.DEBUG(0, "AuctionatorSearch("..tostring(whichOne)..")")
	local shoppingListName
	local items = {}
	local recipe = Skillet:GetRecipeDataByTradeIndex(Skillet.currentTrade, Skillet.selectedSkill)
	DA.DEBUG(1,"AuctionatorSearch: recipe= "..DA.DUMP1(recipe))
	if whichOne then
		shoppingListName = L["Shopping List"]
		local list = Skillet:GetShoppingList(nil, nil, false)
		if not list or #list == 0 then
			DA.DEBUG(0,"AuctionatorSearch: Shopping List is empty")
			return
		end
		for i=1,#list,1 do
			local id  = list[i].id
			local name = GetItemInfo(id)
			if name and not Skillet:VendorSellsReagent(id) then
				table.insert (items, name)
				DA.DEBUG(1, "AuctionatorSearch: Item["..tostring(i).."] "..name.." ("..tostring(id)..") added")
			end
		end
	else
		if not recipe then
			return
		end
		local itemID = recipe.itemID
--
-- Check for Enchanting and add the Enchant name if no item is produced.
--
		if recipe.tradeID == 7411 and itemID then
			itemID = Skillet.EnchantSpellToItem[itemID] or 0
		end
		if itemID ~= 0 then
			shoppingListName = GetItemInfo(itemID)
		else
			shoppingListName = recipe.name
		end
		if (shoppingListName) then
			if recipe.tradeID == 7411 and not Skillet.isCraft then
				if Skillet.db.profile.plugins.ATR.useSearchExact and not Skillet.db.profile.plugins.ATR.exceptEnchanting then
					table.insert (items, L["Scroll of"].." "..shoppingListName)
				else
					table.insert (items, shoppingListName)
				end
			else
				table.insert (items, shoppingListName)
			end
		end
		local i
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if not reagent then
				break
			end
			local needed = reagent.numNeeded or 0
			local id
			if isRetail then
				id = reagent.reagentID
			else
				id = reagent.id
			end
			if id then
				local reagentName = GetItemInfo(id)
				if (reagentName) then
					if not Skillet:VendorSellsReagent(id) then
						table.insert (items, reagentName)
						DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..reagentName)
					else
						DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..reagentName)
					end
				end
			end
		end
	end
	if Atr_SelectPane and Atr_SearchAH then
		DA.DEBUG(0, "AuctionatorSearch: shoppingListName= "..tostring(shoppingListName)..", items= "..DA.DUMP1(items))
		local BUY_TAB = 3;
		Atr_SelectPane(BUY_TAB)
		Atr_SearchAH(shoppingListName, items)
	elseif Skillet.db.profile.plugins.ATR.useSearchExact and Auctionator.API.v1.MultiSearchExact then
		if recipe.tradeID == 7411 and Skillet.db.profile.plugins.ATR.exceptEnchanting then
			DA.DEBUG(0, "AuctionatorSearch: addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
			Auctionator.API.v1.MultiSearch(addonName, items)
		else
			DA.DEBUG(0, "AuctionatorSearch: (exact) addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
			Auctionator.API.v1.MultiSearchExact(addonName, items)
		end
	elseif Auctionator.API.v1.MultiSearch then
		DA.DEBUG(0, "AuctionatorSearch: addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
		Auctionator.API.v1.MultiSearch(addonName, items)
	end
end
