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

local L = Skillet.L
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

--
-- All the options that we allow the user to control.
--
Skillet.options =
{
	handler = Skillet,
	type = 'group',
	args = {
		features = {
			type = 'group',
			name = L["Features"],
			desc = L["FEATURESDESC"],
			order = 10,
			args = {
				header = {
					type = "header",
					name = L["Skillet Trade Skills"].." "..Skillet.version,
					order = 11
				},
				vendor_buy_button = {
					type = "toggle",
					name = L["VENDORBUYBUTTONNAME"],
					desc = L["VENDORBUYBUTTONDESC"],
					get = function()
						return Skillet.db.profile.vendor_buy_button
					end,
					set = function(self,value)
						Skillet.db.profile.vendor_buy_button = value
					end,
					width = "full",
					order = 12
				},
				vendor_auto_buy = {
					type = "toggle",
					name = L["VENDORAUTOBUYNAME"],
					desc = L["VENDORAUTOBUYDESC"],
					get = function()
						return Skillet.db.profile.vendor_auto_buy
					end,
					set = function(self,value)
						Skillet.db.profile.vendor_auto_buy = value
					end,
					width = "full",
					order = 13
				},
				show_item_notes_tooltip = {
					type = "toggle",
					name = L["SHOWITEMNOTESTOOLTIPNAME"],
					desc = L["SHOWITEMNOTESTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.show_item_notes_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.show_item_notes_tooltip = value
					end,
					width = "full",
					order = 14
				},
--[[
				show_crafters_tooltip = {
					type = "toggle",
					name = L["SHOWCRAFTERSTOOLTIPNAME"],
					desc = L["SHOWCRAFTERSTOOLTIPDESC"],
					disabled = true, -- because of 5.4 changes to trade links 
					get = function()
						return Skillet.db.profile.show_crafters_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.show_crafters_tooltip = value
					end,
					width = "full",
					order = 15
				},
]]--
				show_detailed_recipe_tooltip = {
					type = "toggle",
					name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
					desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.show_detailed_recipe_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.show_detailed_recipe_tooltip = value
					end,
					width = "full",
					order = 16
				},
				display_full_tooltip = {
					type = "toggle",
					name = L["SHOWFULLTOOLTIPNAME"],
					desc = L["SHOWFULLTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.display_full_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.display_full_tooltip = value
					end,
					width = "full",
					order = 17
				},
				display_item_tooltip = {
					type = "toggle",
					name = L["SHOWITEMTOOLTIPNAME"],
					desc = L["SHOWITEMTOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.display_item_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.display_item_tooltip = value
					end,
					width = "full",
					order = 18
				},
				link_craftable_reagents = {
					type = "toggle",
					name = L["LINKCRAFTABLEREAGENTSNAME"],
					desc = L["LINKCRAFTABLEREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.link_craftable_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.link_craftable_reagents = value
					end,
					width = 1.5,
					order = 19
				},
				queue_craftable_reagents = {
					type = "toggle",
					name = L["QUEUECRAFTABLEREAGENTSNAME"],
					desc = L["QUEUECRAFTABLEREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.queue_craftable_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.queue_craftable_reagents = value
					end,
					width = 1.5,
					order = 20
				},
				queue_tools = {
					type = "toggle",
					name = L["QUEUETOOLSNAME"],
					desc = L["QUEUETOOLSDESC"],
					get = function()
						return Skillet.db.profile.queue_tools
					end,
					set = function(self,value)
						Skillet.db.profile.queue_tools = value
					end,
					width = 1.5,
					order = 21
				},
				ignore_banked_reagents = {
					type = "toggle",
					name = L["IGNOREBANKEDREAGENTSNAME"],
					desc = L["IGNOREBANKEDREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.ignore_banked_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.ignore_banked_reagents = value
					end,
					width = 1.5,
					order = 22
				},
				ignore_queued_reagents = {
					type = "toggle",
					name = L["IGNOREQUEUEDREAGENTSNAME"],
					desc = L["IGNOREQUEUEDREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.ignore_queued_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.ignore_queued_reagents = value
					end,
					width = 1.5,
					order = 22
				},
--[[
				queue_glyph_reagents = {
					type = "toggle",
					name = L["QUEUEGLYPHREAGENTSNAME"],
					desc = L["QUEUEGLYPHREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.queue_glyph_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.queue_glyph_reagents = value
					end,
					width = "full",
					order = 22
				},
]]--
				header = {
					type = "header",
					name = L["DISPLAYSHOPPINGLIST"],
					order = 23
				},
					display_shopping_list_at_bank = {
						type = "toggle",
						name = L["Bank"],
						desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_bank
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_bank = value
						end,
						width = 0.75,
						order = 24
					},
					display_shopping_list_at_auction = {
						type = "toggle",
						name = L["Auction"],
						desc = L["DISPLAYSHOPPINGLISTATAUCTIONDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_auction
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_auction = value
						end,
						width = 0.75,
						order = 25
					},
					display_shopping_list_at_merchant = {
						type = "toggle",
						name = L["Merchant"],
						desc = L["DISPLAYSHOPPINGLISTATMERCHANTDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_merchant
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_merchant = value
						end,
						width = 0.75,
						order = 26
					},
					display_shopping_list_at_guildbank = {
						hidden = isClassic,
						type = "toggle",
						name = L["Guild bank"],
						desc = L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"],
						get = function()
							return Skillet.db.profile.display_shopping_list_at_guildbank
						end,
						set = function(self,value)
							Skillet.db.profile.display_shopping_list_at_guildbank = value
						end,
						width = 0.75,
						order = 27
					},
				show_craft_counts = {
					type = "toggle",
					name = L["SHOWCRAFTCOUNTSNAME"],
					desc = L["SHOWCRAFTCOUNTSDESC"],
					get = function()
						return Skillet.db.profile.show_craft_counts
					end,
					set = function(self,value)
						Skillet.db.profile.show_craft_counts = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 28,
				},
--[[
				use_blizzard_for_followers = {
					type = "toggle",
					name = L["USEBLIZZARDFORFOLLOWERSNAME"],
					desc = L["USEBLIZZARDFORFOLLOWERSDESC"],
					get = function()
						return Skillet.db.profile.use_blizzard_for_followers
					end,
					set = function(self,value)
						Skillet.db.profile.use_blizzard_for_followers = value
					end,
					width = "full",
					order = 29
				},
]]--
				hide_blizzard_frame = {
					type = "toggle",
					name = L["HIDEBLIZZARDFRAMENAME"],
					desc = L["HIDEBLIZZARDFRAMEDESC"],
					get = function()
						return Skillet.db.profile.hide_blizzard_frame
					end,
					set = function(self,value)
						Skillet.db.profile.hide_blizzard_frame = value
					end,
					width = "full",
					order = 30
				},
				support_crafting = {
					type = "toggle",
					name = L["SUPPORTCRAFTINGNAME"],
					desc = L["SUPPORTCRAFTINGDESC"],
					get = function()
						return Skillet.db.profile.support_crafting
					end,
					set = function(self,value)
						Skillet.db.profile.support_crafting = value
					end,
					width = 1.5,
					order = 31
				},
				ignore_change = {
					hidden = isClassic,
					type = "toggle",
					name = L["IGNORECHANGENAME"],
					desc = L["IGNORECHANGEDESC"],
					get = function()
						return Skillet.db.profile.ignore_change
					end,
					set = function(self,value)
						Skillet.db.profile.ignore_change = value
					end,
					width = 1.5,
					order = 32
				},
				include_craftbuttons = {
					type = "toggle",
					name = L["CRAFTBUTTONSNAME"],
					desc = L["CRAFTBUTTONSDESC"],
					get = function()
						return Skillet.db.profile.include_craftbuttons
					end,
					set = function(self,value)
						Skillet.db.profile.include_craftbuttons = value
					end,
					width = "full",
					order = 33
				},
				queue_crafts = {
					type = "toggle",
					name = L["QUEUECRAFTSNAME"],
					desc = L["QUEUECRAFTSDESC"],
					get = function()
						return Skillet.db.profile.queue_crafts
					end,
					set = function(self,value)
						Skillet.db.profile.queue_crafts = value
						Skillet:ConfigureRecipeControls()
					end,
					width = 1.5,
					order = 34
				},
				enchant_scrolls = {
					hidden = isClassic,
					type = "toggle",
					name = L["ENCHANTSCROLLSNAME"],
					desc = L["ENCHANTSCROLLSDESC"],
					get = function()
						return Skillet.db.profile.enchant_scrolls
					end,
					set = function(self,value)
						Skillet.db.profile.enchant_scrolls = value
					end,
					width = 1.0,
					order = 35
				},
--[[
				use_higher_vellum = {
					hidden = isClassic,
					type = "toggle",
					name = L["HIGHERVELLUMNAME"],
					desc = L["HIGHERVELLUMDESC"],
					get = function()
						return Skillet.db.profile.use_higher_vellum
					end,
					set = function(self,value)
						Skillet.db.profile.use_higher_vellum = value
					end,
					width = 1.0,
					order = 36
				},
]]--
				include_tradebuttons = {
					type = "toggle",
					name = L["TRADEBUTTONSNAME"],
					desc = L["TRADEBUTTONSDESC"],
					get = function()
						return Skillet.db.profile.include_tradebuttons
					end,
					set = function(self,value)
						Skillet.db.profile.include_tradebuttons = value
					end,
					width = "full",
					order = 37
				},
				search_includes_reagents = {
					type = "toggle",
					name = L["INCLUDEREAGENTSNAME"],
					desc = L["INCLUDEREAGENTSDESC"],
					get = function()
						return Skillet.db.profile.search_includes_reagents
					end,
					set = function(self,value)
						Skillet.db.profile.search_includes_reagents = value
						Skillet.data.tooltipCache = {}
					end,
					width = "full",
					order = 38
				},
				use_guildbank_as_alt = {
					hidden = isClassic,
					type = "toggle",
					name = L["USEGUILDBANKASALTNAME"],
					desc = L["USEGUILDBANKASALTDESC"],
					get = function()
						return Skillet.db.profile.use_guildbank_as_alt
					end,
					set = function(self,value)
						Skillet.db.profile.use_guildbank_as_alt = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = 1.5,
					order = 39
				},
				use_bank_as_alt = {
					type = "toggle",
					name = L["USEBANKASALTNAME"],
					desc = L["USEBANKASALTDESC"],
					get = function()
						return Skillet.db.profile.use_bank_as_alt
					end,
					set = function(self,value)
						Skillet.db.profile.use_bank_as_alt = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = 1.5,
					order = 40
				},
				use_alt_banks = {
					type = "toggle",
					name = L["USEALTBANKSNAME"],
					desc = L["USEALTBANKSDESC"],
					get = function()
						return Skillet.db.profile.use_alt_banks
					end,
					set = function(self,value)
						Skillet.db.profile.use_alt_banks = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = 1.5,
					order = 41
				},
			}
		},
		appearance = {
			type = 'group',
			name = L["Appearance"],
			desc = L["APPEARANCEDESC"],
			args = {
				display_required_level = {
					type = "toggle",
					name = L["DISPLAYREQUIREDLEVELNAME"],
					desc = L["DISPLAYREQUIREDLEVELDESC"],
					get = function()
						return Skillet.db.profile.display_required_level
					end,
					set = function(self,value)
						Skillet.db.profile.display_item_level = false
						Skillet.db.profile.display_required_level = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 1
				},
				display_item_level = {
					type = "toggle",
					name = L["DISPLAYITEMLEVELNAME"],
					desc = L["DISPLAYITEMLEVELDESC"],
					get = function()
						return Skillet.db.profile.display_item_level
					end,
					set = function(self,value)
						Skillet.db.profile.display_required_level = false
						Skillet.db.profile.display_item_level = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 2
				},
				select_top_recipe = {
					type = "toggle",
					name = L["SELECTTOPRECIPENAME"],
					desc = L["SELECTTOPRECIPEDESC"],
					get = function()
						return Skillet.db.profile.select_top_recipe
					end,
					set = function(self,value)
						Skillet.db.profile.select_top_recipe = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 3,
				},
				enhanced_recipe_display = {
					type = "toggle",
					name = L["ENHANCHEDRECIPEDISPLAYNAME"],
					desc = L["ENHANCHEDRECIPEDISPLAYDESC"],
					get = function()
						return Skillet.db.profile.enhanced_recipe_display
					end,
					set = function(self,value)
						Skillet.db.profile.enhanced_recipe_display = value
						Skillet:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 4,
				},
				interrupt_clears_queue = {
					type = "toggle",
					name = L["INTERRUPTCLEARNAME"],
					desc = L["INTERRUPTCLEARDESC"],
					get = function()
						return Skillet.db.profile.interrupt_clears_queue
					end,
					set = function(self,value)
						Skillet.db.profile.interrupt_clears_queue = value
					end,
					width = "full",
					order = 5,
				},
				sound_on_empty_queue = {
					type = "toggle",
					name = L["SOUNDONEMPTYQUEUENAME"],
					desc = L["SOUNDONEMPTYQUEUEDESC"],
					get = function()
						return Skillet.db.profile.sound_on_empty_queue
					end,
					set = function(self,value)
						Skillet.db.profile.sound_on_empty_queue = value
					end,
					width = "full",
					order = 6,
				},
				clamp_to_screen = {
					type = "toggle",
					name = L["CLAMPTOSCREENNAME"],
					desc = L["CLAMPTOSCREENDESC"],
					get = function()
						return Skillet.db.profile.clamp_to_screen
					end,
					set = function(self,value)
						Skillet.db.profile.clamp_to_screen = value
						if SkilletFrame then SkilletFrame:SetClampedToScreen(value) end
						if SkilletStandaloneQueue then SkilletStandaloneQueue:SetClampedToScreen(value) end
					end,
					width = "full",
					order = 9,
				},
				scale_tooltip = {
					type = "toggle",
					name = L["SCALETOOLTIPNAME"],
					desc = L["SCALETOOLTIPDESC"],
					get = function()
						return Skillet.db.profile.scale_tooltip
					end,
					set = function(self,value)
						Skillet.db.profile.scale_tooltip = value
					end,
					width = "full",
					order = 10,
				},
				transparency = {
					type = "range",
					name = L["Transparency"],
					desc = L["TRANSPARAENCYDESC"],
					min = 0.1, max = 1, step = 0.05, isPercent = true,
					get = function()
						return Skillet.db.profile.transparency
					end,
					set = function(self,t)
						Skillet.db.profile.transparency = t
						Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateShoppingListWindow(false)
						Skillet:UpdateStandaloneQueueWindow()
					end,
					width = "full",
					order = 11,
				},
				scale = {
					type = "range",
					name = L["Scale"],
					desc = L["SCALEDESC"],
					min = 0.1, max = 1.25, step = 0.05, isPercent = true,
					get = function()
						return Skillet.db.profile.scale
					end,
					set = function(self,t)
						Skillet.db.profile.scale = t
						Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateShoppingListWindow(false)
						Skillet:UpdateStandaloneQueueWindow()
					end,
					width = "full",
					order = 12,
				},
				ttscale = {
					type = "range",
					name = L["Tooltip Scale"],
					desc = L["TOOLTIPSCALEDESC"],
					min = 0.1, max = 1.25, step = 0.05, isPercent = true,
					get = function()
						return Skillet.db.profile.ttscale
					end,
					set = function(self,t)
						Skillet.db.profile.ttscale = t
						Skillet:UpdateTradeSkillWindow()
						Skillet:UpdateShoppingListWindow(false)
						Skillet:UpdateStandaloneQueueWindow()
					end,
					width = "full",
					order = 13,
				},
			},
		},
		config = {
			type = 'execute',
			name = L["Config"],
			desc = L["CONFIGDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ShowOptions()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			guiHidden = true,
			order = 51
		},
		shoppinglist = {
			type = 'execute',
			name = L["Shopping List"],
			desc = L["SHOPPINGLISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					if Skillet:IsShoppingListVisible() then
						Skillet:HideShoppingList()
					else
						Skillet:DisplayShoppingList(false, Skillet.db.profile.queue_tools)
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 52
		},
		shoppingclear = {
			type = 'execute',
			name = L["Shopping Clear"],
			desc = L["SHOPPINGCLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 53
		},
		flushalldata = {
			type = 'execute',
			name = L["Flush All Data"],
			desc = L["FLUSHALLDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushAllData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 54
		},
		flushrecipedata = {
			type = 'execute',
			name = L["Flush Recipe Data"],
			desc = L["FLUSHRECIPEDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushRecipeData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 55
		},
		flushplayerdata = {
			type = 'execute',
			name = L["Flush Player Data"],
			desc = L["FLUSHPLAYERDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:InitializeDatabase(UnitName("player"), true)
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 56
		},
		standby = {
			type = 'execute',
			name = L["STANDBYNAME"],
			desc = L["STANDBYDESC"],
			func = function()
				if Skillet:IsEnabled() then
					Skillet:Disable()
					Skillet:Print(RED_FONT_COLOR_CODE..L["is now disabled"]..FONT_COLOR_CODE_CLOSE)
				else
					Skillet:Enable()
					Skillet:Print(GREEN_FONT_COLOR_CODE..L["is now enabled"]..FONT_COLOR_CODE_CLOSE)
				end
			end,
			guiHidden = true,
			order = 57
		},
		ignorelist = {
			type = 'execute',
			name = L["Ignored Materials List"],
			desc = L["IGNORELISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:DisplayIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 58
		},
		ignoreclear = {
			type = 'execute',
			name = L["Ignored Materials Clear"],
			desc = L["IGNORECLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 59
		},
		ignoreadd = {
			type = "input",
			name = "IgnoreAdd",
			desc = "Add to userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return Skillet.db.realm.userIgnoredMats[UnitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				Skillet.db.realm.userIgnoredMats[UnitName("player")][value] = 1
			end,
			order = 60
		},
		ignoredel = {
			type = "input",
			name = "IgnoreDel",
			desc = "Delete from userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return Skillet.db.realm.userIgnoredMats[UnitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				Skillet.db.realm.userIgnoredMats[UnitName("player")][value] = nil
			end,
			order = 61
		},
--[[
		resetrecipefilter = {
			type = 'execute',
			name = L["Reset Recipe Filter"],
			desc = L["RESETRECIPEFILTERDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ResetTradeSkillFilter()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 62
		},
]]--
		printsaved = {
			type = 'execute',
			name = "PrintSaved",
			desc = "Print list of SavedQueues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintSaved()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 63
		},
		printqueue = {
			type = 'execute',
			name = "PrintQueue",
			desc = "Print Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintQueue()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 64
		},
		printsavedqueue = {
			type = 'input',
			name = "PrintSavedQueue",
			desc = "Print Named Saved Queue",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintQueue(value)
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 65
		},
		clearqueue = {
			type = 'execute',
			name = "ClearQueue",
			desc = "Clear Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:ClearQueue()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 66
		},
		printauction = {
			type = 'execute',
			name = "PrintAuctionData",
			desc = "Print Auction Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:PrintAuctionData()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 67
		},
		enchanting = {
			type = "toggle",
			name = "Enchanting",
			desc = "Enable/Disable Enchant button",
			get = function()
				return Skillet.db.profile.support_crafting
			end,
			set = function(self,value)
				Skillet.db.profile.support_crafting = value
				Skillet:ConfigureRecipeControls()
				Skillet:UpdateTradeSkillWindow()
			end,
			order = 68,
		},
--
-- commands to toggle Blizzard's frames (beats using "/run")
--
		btsui = {
			type = "toggle",
			name = "BTSUI",
			desc = "Show/Hide the Blizzard TradeSkill frame",
			get = function()
				return Skillet.data.btsui
			end,
			set = function(self,value)
				Skillet.data.btsui = value
				if value then
					ShowUIPanel(TradeSkillFrame)
					Skillet.BlizzardUIshowing = true
				else
					HideUIPanel(TradeSkillFrame)
					Skillet.BlizzardUIshowing = false
				end
			end,
			order = 69
		},
		bcui = {
			type = "toggle",
			name = "BCUI",
			desc = "Show/Hide the Blizzard Crafting frame",
			get = function()
				return Skillet.data.bcui
			end,
			set = function(self,value)
				Skillet.data.bcui = value
				if value then
					ShowUIPanel(CraftFrame)
				else
					HideUIPanel(CraftFrame)
				end
			end,
			order = 70
		},
--
-- commands to update Skillet's main windows
--
		uslw = {
			type = 'execute',
			name = "UpdateShoppingListWindow",
			desc = "Update (Skillet's) Shopping List Window",
			func = function()
				Skillet:UpdateShoppingListWindow(false)
			end,
			order = 71
		},
		utsw = {
			type = 'execute',
			name = "UpdateTradeSkillWindow",
			desc = "Update (Skillet's) TradeSkill Window",
			func = function()
				Skillet:UpdateTradeSkillWindow()
			end,
			order = 72
		},
--
-- command to turn on/off custom groups 
-- (i.e. panic/debug button if they aren't working)
--
		customgroups = {
			type = "toggle",
			name = "CustomGroups",
			desc = "Enable / Disable Custom Groups button",
			get = function()
				return Skillet.data.customgroups
			end,
			set = function(self,value)
				Skillet.data.customgroups = value
				if value then
					SkilletRecipeGroupOperations:Enable()
				else
					SkilletRecipeGroupOperations:Disable()
				end
			end,
			order = 73
		},
--
-- additional database flush commands
--
		flushcustomdata = {
			type = 'execute',
			name = "Flush Custom Data",
			desc = "Flush Custom Group Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushCustomData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 74
		},
		flushqueuedata = {
			type = 'execute',
			name = "Flush Queue Data",
			desc = "Flush Queue Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:FlushQueueData()
					Skillet:InitializeDatabase(UnitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 75
		},
		nomodkeys = {
			type = "toggle",
			name = "NoModKeys",
			desc = "Disable/Enable Mod Keys to open the Blizzard frames",
			get = function()
				return Skillet.db.profile.nomodkeys
			end,
			set = function(self,value)
				Skillet.db.profile.nomodkeys = value
			end,
			order = 76
		},
		invertshiftkey = {
			type = "toggle",
			name = "InvertShiftKey",
			desc = "Invert sense of shift to open the Blizzard frames",
			get = function()
				return Skillet.db.profile.invertshiftkey
			end,
			set = function(self,value)
				Skillet.db.profile.invertshiftkey = value
			end,
			order = 76
		},
--
-- commands to print and initialize skill data (SkillLevelData.lua)
--
		printskilllevels = {
			type = 'input',
			name = "PrintSkillLevels",
			desc = "Print Skill Levels",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					--DA.DEBUG(0,"value= "..value..", #value= "..strlen(value))
					local itemID = 0
					local spellID = 0
					if strlen(value) > 0 then
						local itemID, spellID = string.split(" ",value)
						--DA.DEBUG(0,"itemID= "..tostring(itemID)..", spellID= "..tostring(spellID))
					end
					Skillet:PrintTradeSkillLevels(itemID, spellID)
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 77
		},
		initskilllevels = {
			type = 'execute',
			name = "Init Skill Levels",
			desc = "Initialize Skill Levels",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet:InitializeSkillLevels()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 78
		},
		altskilllevels = {
			type = "toggle",
			name = "AltSkillLevels",
			desc = "Use Alternate Skill Levels",
			get = function()
				return Skillet.db.profile.altskilllevels
			end,
			set = function(self,value)
				Skillet.db.profile.altskilllevels = value
			end,
			order = 78
		},
		baseskilllevel = {
			type = "toggle",
			name = "BaseSkillLevel",
			desc = "Use Alternate Base Skill Level",
			get = function()
				return Skillet.db.profile.baseskilllevel
			end,
			set = function(self,value)
				Skillet.db.profile.baseskilllevel = value
			end,
			order = 78
		},
		news = {
			type = 'execute',
			name = "Display news",
			desc = "Display the news frame",
			func = function()
				if not (UnitAffectingCombat("player")) then
					Skillet.NewsGUI:Toggle()
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 79
		},
		AJ = {
			type = "input",
			name = "AJ",
			desc = "Display Auctionator (and Journalator) API output for value, an ItemID or itemLink",
			get = function()
				return Skillet.AJID
			end,
			set = function(self,value)
				Skillet.AJID = value
				local name = GetItemInfo(value)
				local itemID = GetItemInfoInstant(value)
				print("value= "..tostring(value)..", itemID= "..tostring(itemID)..", name= "..tostring(name))
				if Auctionator.API and itemID then
					local price = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0)
					print("itemID= "..tostring(itemID)..", price= "..Skillet:FormatMoneyShort(price, true))
					if Journalator.API and name then
						successCount = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, name)
						failedCount = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, name)
						lastSold = Journalator.API.v1.GetRealmLastSoldByItemName(addonName, name)
						lastBought = Journalator.API.v1.GetRealmLastBoughtByItemName(addonName, name)
						print("itemName= "..tostring(name)..", successCount= "..tostring(successCount)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
					end
				end
			end,
			order = 80
		},

--
-- Commands to manipulate the state of debugging code flags
-- (See DebugAids.lua)
--
		WarnShow = {
			type = "toggle",
			name = "WarnShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.WarnShow
			end,
			set = function(self,value)
				Skillet.db.profile.WarnShow = value
				Skillet.WarnShow = value
				if value then
					Skillet.db.profile.WarnLog = value
					Skillet.WarnLog = value
				end
			end,
			order = 81
		},
		WarnLog = {
			type = "toggle",
			name = "WarnLog",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.WarnLog
			end,
			set = function(self,value)
				Skillet.db.profile.WarnLog = value
				Skillet.WarnLog = value
			end,
			order = 82
		},
		DebugShow = {
			type = "toggle",
			name = "DebugShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.DebugShow
			end,
			set = function(self,value)
				Skillet.db.profile.DebugShow = value
				Skillet.DebugShow = value
				if value then
					Skillet.db.profile.DebugLogging = value
					Skillet.DebugLogging = value
				end
			end,
			order = 83
		},
		DebugLogging = {
			type = "toggle",
			name = "DebugLogging",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.DebugLogging
			end,
			set = function(self,value)
				Skillet.db.profile.DebugLogging = value
				Skillet.DebugLogging = value
			end,
			order = 84
		},
		DebugLevel = {
			type = "input",
			name = "DebugLevel",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.DebugLevel
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 1
				elseif value < 1 then value = 1
				elseif value > 9 then value = 10 end
				Skillet.db.profile.DebugLevel = value
				Skillet.DebugLevel = value
			end,
			order = 85
		},
		TableDump = {
			type = "toggle",
			name = "TableDump",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TableDump
			end,
			set = function(self,value)
				Skillet.db.profile.TableDump = value
				Skillet.TableDump = value
			end,
			order = 86
		},
		TraceShow = {
			type = "toggle",
			name = "TraceShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceShow
			end,
			set = function(self,value)
				Skillet.db.profile.TraceShow = value
				Skillet.TraceShow = value
				if value then
					Skillet.db.profile.TraceLog = value
					Skillet.TraceLog = value
				end
			end,
			order = 87
		},
		TraceLog = {
			type = "toggle",
			name = "TraceLog",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceLog
			end,
			set = function(self,value)
				Skillet.db.profile.TraceLog = value
				Skillet.TraceLog = value
			end,
			order = 88
		},
		TraceLog2 = {
			type = "toggle",
			name = "TraceLog2",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.TraceLog2
			end,
			set = function(self,value)
				Skillet.db.profile.TraceLog2 = value
				Skillet.TraceLog2 = value
			end,
			order = 88
		},
		ProfileShow = {
			type = "toggle",
			name = "ProfileShow",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.ProfileShow
			end,
			set = function(self,value)
				Skillet.db.profile.ProfileShow = value
				Skillet.ProfileShow = value
			end,
			order = 89
		},
		ClearDebugLog = {
			type = "execute",
			name = "ClearDebugLog",
			desc = "Option for debugging",
			func = function()
				SkilletDBPC = {}
				DA.DebugLog = SkilletDBPC
			end,
			order = 90
		},
		ClearProfileLog = {
			type = "execute",
			name = "ClearProfileLog",
			desc = "Option for debugging",
			func = function()
				SkilletProfile = {}
				DA.DebugProfile = SkilletProfile
			end,
			order = 91
		},
		DebugStatus = {
			type = 'execute',
			name = "DebugStatus",
			desc = "Print Debug Status",
			func = function()
				DA.DebugAidsStatus()
			end,
			order = 92
		},
		DebugOff = {
			type = 'execute',
			name = "DebugOff",
			desc = "Turn Debug Off",
			func = function()
				if Skillet.db.profile.WarnShow then
					Skillet.db.profile.WarnShow = false
					Skillet.WarnShow = false
				end
				if Skillet.db.profile.WarnLog then
					Skillet.db.profile.WarnLog = false
					Skillet.WarnLog = false
				end
				if Skillet.db.profile.DebugShow then
					Skillet.db.profile.DebugShow= false
					Skillet.DebugShow = false
				end
				if Skillet.db.profile.DebugLogging then
					Skillet.db.profile.DebugLogging = false
					Skillet.DebugLogging = false
				end
--
-- DebugLevel is left alone but
-- LogLevel is left undefined or set to false as
-- the default should be log everything.
--
				if Skillet.db.profile.LogLevel then
					Skillet.db.profile.LogLevel = false
					Skillet.LogLevel = false
				end
				if Skillet.db.profile.TraceShow then
					Skillet.db.profile.TraceShow = false
					Skillet.TraceShow = false
				end
				if Skillet.db.profile.TraceLog then
					Skillet.db.profile.TraceLog = false
					Skillet.TraceLog = false
				end
				if Skillet.db.profile.ProfileShow then
					Skillet.db.profile.ProfileShow = false
					Skillet.ProfileShow = false
				end
			end,
			order = 93
		},
		LogLevel = {
			type = "toggle",
			name = "LogLevel",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.LogLevel
			end,
			set = function(self,value)
				Skillet.db.profile.LogLevel = value
				Skillet.LogLevel = value
			end,
			order = 94
		},
		MaxDebug = {
			type = "input",
			name = "MaxDebug",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.MAXDEBUG
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 4000 end
				Skillet.db.profile.MAXDEBUG = value
				Skillet.MAXDEBUG = value
			end,
			order = 95
		},
		MaxProfile = {
			type = "input",
			name = "MaxProfile",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.MAXPROFILE
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 2000 end
				Skillet.db.profile.MAXPROFILE = value
				Skillet.MAXPROFILE = value
			end,
			order = 96
		},
		FixBugs = {
			type = "toggle",
			name = "FixBugs",
			desc = "Option for debugging",
			get = function()
				return Skillet.db.profile.FixBugs
			end,
			set = function(self,value)
				Skillet.db.profile.FixBugs = value
				Skillet.FixBugs = value
				if value then
					Skillet.db.profile.TraceLog = value
					Skillet.TraceLog = value
				end
			end,
			order = 97
		},
		DebugMark = {
			type = 'input',
			name = "DebugMark",
			desc = "Adds a comment to logs",
			get = function()
			end,
			set = function(self,value)
				DA.MARK(value)
			end,
			order = 98
		},
--
-- Commands to set/show how many TRADE_SKILL_UPDATE / CRAFT_UPDATE events to ignore
--
		TradeWait = {
			type = "input",
			name = "TradeWait",
			desc = "Number of TRADE_SKILL_UPDATE events to ignore",
			get = function()
				return Skillet.db.realm.trade_wait
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 1
				elseif value < 1 then value = 1
				elseif value > 9 then value = 10 end
				Skillet.db.realm.trade_wait = value
			end,
			order = 100
		},
		CraftWait = {
			type = "input",
			name = "CraftWait",
			desc = "Number of CRAFT_UPDATE events to ignore",
			get = function()
				return Skillet.db.realm.craft_wait
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 1
				elseif value < 1 then value = 1
				elseif value > 9 then value = 10 end
				Skillet.db.realm.craft_wait = value
			end,
			order = 101
		},
		ShowWait = {
			type = 'execute',
			name = "ShowWait",
			desc = "Print *_UPDATE Waits",
			func = function()
				print("TradeWait= "..tostring(Skillet.db.realm.trade_wait))
				print("CraftWait= "..tostring(Skillet.db.realm.craft_wait))
			end,
			order = 103
		},
--
-- commands to manage the custom reagent price table
--
		customadd = {
			type = 'input',
			name = "customadd",
			desc = "Add a custom price for a reagent (customadd id|link,price)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local item, id, price, name, link
						local server = Skillet.data.server or 0
						DA.DEBUG(0,"value= "..value)
						item, price = string.split(",",value)
						if string.find(item,"|H") then
							id = Skillet:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = GetItemInfo(id)
						price = tonumber(price)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", price= "..tostring(price)..", link= "..tostring(link))
						Skillet.db.global.customPrice[server][id] = { ["name"] = name, ["value"] = price }
						end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 105
		},
		customdel = {
			type = 'input',
			name = "customdel",
			desc = "Delete a custom reagent (customdel id|link)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local id
						local server = Skillet.data.server or 0
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = Skillet:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						Skillet.db.global.customPrice[server][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 106
		},
		customshow = {
			type = 'execute',
			name = "customshow",
			desc = "Print the custom reagent price table",
			func = function()
				local server = Skillet.data.server or 0
				for id,entry in pairs(Skillet.db.global.customPrice[server]) do
					print(tostring(entry.name)..", "..Skillet:FormatMoneyFull(entry.value,true))
				end
			end,
			order = 107
		},
		customdump = {
			type = 'execute',
			name = "customdump",
			desc = "Print the custom reagent price table",
			func = function()
				local server = Skillet.data.server or 0
				for id,entry in pairs(Skillet.db.global.customPrice[server]) do
					print("id= "..tostring(id)..", name= "..tostring(entry.name)..", value= "..tostring(entry.value))
				end
			end,
			order = 108
		},
		customclear = {
			type = 'execute',
			name = "customclear",
			desc = "Clear the custom reagent price table",
			func = function()
				local server = Skillet.data.server or 0
				Skillet.db.global.customPrice[server] = {}
			end,
			order = 109
		},

--
-- commands to manage the manual toolData list
--
		tooladd = {
			type = 'input',
			name = "tooladd",
			desc = "Add a tool (tooladd id|link,data)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local item, id, data, name, link
						local player = Skillet.currentPlayer
						DA.DEBUG(0,"value= "..value)
						item, data = string.split(",",value)
						if string.find(item,"|H") then
							id = Skillet:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = GetItemInfo(id)
						data = tonumber(data)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", data= "..tostring(data)..", link= "..tostring(link))
						Skillet.db.realm.toolData[player][id] = { ["name"] = name, ["value"] = data }
						end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 110
		},
		tooldel = {
			type = 'input',
			name = "tooldel",
			desc = "Delete a tool (tooldel id|link)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local id
						local player = Skillet.currentPlayer
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = Skillet:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						Skillet.db.realm.toolData[player][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 111
		},
		tooldump = {
			type = 'execute',
			name = "tooldump",
			desc = "Print the toolData table",
			func = function()
				local player = Skillet.currentPlayer
				if next(Skillet.db.realm.toolData[player]) == nil then
					print("toolData is empty")
				end
				for id,entry in pairs(Skillet.db.realm.toolData[player]) do
					print("id= "..tostring(id)..", name= "..tostring(entry.name)..", value= "..tostring(entry.value))
				end
			end,
			order = 112
		},
		toolclear = {
			type = 'execute',
			name = "toolclear",
			desc = "Clear the custom reagent data table",
			func = function()
				local player = Skillet.currentPlayer
				Skillet.db.realm.toolData[player] = {}
			end,
			order = 113
		},

--
-- command to reset the position of the major Skillet frames
--
		reset = {
			type = 'execute',
			name = L["Reset"],
			desc = L["RESETDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					local windowManager = LibStub("LibWindow-1.1")
					if SkilletFrame and SkilletFrame:IsVisible() then
						SkilletFrame:SetWidth(750);
						SkilletFrame:SetHeight(580);
						SkilletFrame:SetPoint("TOPLEFT",200,-100);
						windowManager.SavePosition(SkilletFrame)
					end
					if SkilletStandaloneQueue and SkilletStandaloneQueue:IsVisible() then
						SkilletStandaloneQueue:SetWidth(385);
						SkilletStandaloneQueue:SetHeight(170);
						SkilletStandaloneQueue:SetPoint("TOPLEFT",950,-100);
						windowManager.SavePosition(SkilletStandaloneQueue)
					end
					if SkilletShoppingList and SkilletShoppingList:IsVisible() then
						SkilletShoppingList:SetWidth(385);
						SkilletShoppingList:SetHeight(170);
						SkilletShoppingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(SkilletShoppingList)
					end
				else
					DA.DEBUG(0,"|cff8888ffSkillet|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 130
		},
	}
}

--
-- Configure the options window
--
function Skillet:ConfigureOptions()
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("Skillet", self.options, "Skillet")
	acecfg:RegisterOptionsTable("Skillet Features", self.options.args.features)
	acecfg:RegisterOptionsTable("Skillet Appearance", self.options.args.appearance)
	acecfg:RegisterOptionsTable("Skillet Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	acecfg:RegisterOptionsTable("Skillet Plugins", Skillet.pluginsOptions)
	local acedia = LibStub("AceConfigDialog-3.0")
	Skillet.optionsFrame = acedia:AddToBlizOptions("Skillet Features", "Skillet")
	acedia:AddToBlizOptions("Skillet Appearance", "Appearance", "Skillet")
	acedia:AddToBlizOptions("Skillet Profiles", "Profiles", "Skillet")
	acedia:AddToBlizOptions("Skillet Plugins", "Plugins", "Skillet")
end

--
-- Show the options window
--
function Skillet:ShowOptions()
	Settings.OpenToCategory("Skillet")
end

