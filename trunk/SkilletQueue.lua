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

Skillet.reagentsChanged = {}

-- iterates through a list of reagentIDs and recalculates craftability
function Skillet:AdjustInventory()
	DA.DEBUG(0,"AdjustInventory()")
	-- update queue for faster response time
	if self.reagentsChanged then
		for id,v in pairs(self.reagentsChanged) do
			self:InventoryReagentCraftability(id)
		end
	end
	self.reagentsChanged = {}
	self.dataScanned = false
	Skillet:ScanQueuedReagents()
	Skillet:InventoryScan()
	self:CalculateCraftableCounts()
	self:UpdateQueueWindow()
	self:UpdateTradeSkillWindow()
end

--
-- this is the simplest command:  iterate recipeID x count
-- this is the only currently implemented queue command
-- Given the tradeID and the recipeID (currently the recipe name)
-- the skillIndex can be calculated so it doesn't need to be saved.
--
function Skillet:QueueCommandIterate(recipeID, count)
	DA.DEBUG(0,"QueueCommandIterate("..tostring(recipeID)..", "..tostring(count)..") currentTrade= "..tostring(self.currentTrade))
	local newCommand = {}
	local recipe = self:GetRecipe(recipeID)
	local tradeName = self:GetTradeName(recipe.tradeID)
	local recipeIndex = self.data.skillIndexLookup[self.currentPlayer][recipeID]
	newCommand.op = "iterate"
	newCommand.recipeID = recipeID or 0
	newCommand.tradeID = recipe.tradeID or 0
	newCommand.tradeName = tradeName or ""
	newCommand.recipeIndex = recipeIndex or 0
	newCommand.count = count or 0
	return newCommand
end

--
-- command to craft "recipeID" until inventory has "count" "itemID"
-- not currently implemented
--
function Skillet:QueueCommandInventory(recipeID, itemID, count)
	DA.DEBUG(0,"QueueCommandInventory("..tostring(recipeID)..", "..tostring(itemID)..", "..tostring(count)..")")
	local newCommand = {}
	local tradeID = self.currentTrade or "0"	-- Use 0 for unknown to make sure the entry exists
	newCommand.op = "inventory"
	newCommand.recipeID = recipeID or 0
	newCommand.tradeID = recipe.tradeID or 0
	newCommand.tradeName = tradeName or ""
	newCommand.recipeIndex = recipeIndex or 0
	newCommand.count = count or 0
	newCommand.itemID = itemID or 0
	return newCommand
end

--
-- command to craft "recipeID" until a certain crafting level has been reached
-- not currently implemented
--
function Skillet:QueueCommandSkillLevel(recipeID, untilSkill)
	DA.DEBUG(0,"QueueCommandSkillLevel("..tostring(recipeID)..", "..tostring(untilSkill)..")")
	local newCommand = {}
	newCommand.op = "skillLevel"
	newCommand.recipeID = recipeID or 0
	newCommand.tradeID = recipe.tradeID or 0
	newCommand.tradeName = tradeName or ""
	newCommand.recipeIndex = recipeIndex or 0
	newCommand.count = count or 0
	newCommand.untilSkill = untilSkill or 0
	return newCommand
end

--
-- queue up the command and reserve reagents
--
function Skillet:QueueAppendCommand(command, queueCraftables)
	DA.DEBUG(0,"QueueAppendCommand("..DA.DUMP1(command)..", "..tostring(queueCraftables)..")")
	local recipe = Skillet:GetRecipe(command.recipeID)
	DA.DEBUG(0,"recipe= "..DA.DUMP1(recipe)..", visited= "..tostring(self.visited[command.recipeID]))
	if recipe and not self.visited[command.recipeID] then
		self.visited[command.recipeID] = true
		local count = command.count
		local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
		local reagentsChanged = self.reagentsChanged
		local skillIndexLookup = self.data.skillIndexLookup[Skillet.currentPlayer]
		for i=1,#recipe.reagentData,1 do
			local reagent = recipe.reagentData[i]
			DA.DEBUG(1,"reagent= "..DA.DUMP1(reagent))
			local need = count * reagent.numNeeded
			local numInBoth = GetItemCount(reagent.id, true)
			local numInBags = GetItemCount(reagent.id, false)
			local numInBank =  numInBoth - numInBags
			DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
			local have = numInBags + (reagentsInQueue[reagent.id] or 0);	-- In Classic just bags
			reagentsInQueue[reagent.id] = (reagentsInQueue[reagent.id] or 0) - need;
			reagentsChanged[reagent.id] = true
			DA.DEBUG(1,"queueCraftables= "..tostring(queueCraftables)..", need= "..tostring(need)..", have= "..tostring(have))
			if queueCraftables and need > have and (Skillet.db.profile.queue_glyph_reagents or not recipe.name:match(Skillet.L["Glyph "])) then
				local recipeSource = self.db.global.itemRecipeSource[reagent.id]
				DA.DEBUG(1,"recipeSource= "..DA.DUMP1(recipeSource))
				if recipeSource then
					for recipeSourceID in pairs(recipeSource) do
						local skillIndex = skillIndexLookup[recipeSourceID]
						DA.DEBUG(1,"skillIndex= "..tostring(skillIndex))
						if skillIndex then
							command.complex = true						-- identify that this queue has craftable reagent requirements
							local recipeSource = Skillet:GetRecipe(recipeSourceID)
							local newCount = math.ceil((need - have)/recipeSource.numMade)
							local newCommand = self:QueueCommandIterate(recipeSourceID, newCount)
							newCommand.level = (command.level or 0) + 1
							-- do not add items from transmutation - this can create weird loops
							if not Skillet.TradeSkillIgnoredMats[recipeSourceID] and 
							  not Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeSourceID] then
								self:QueueAppendCommand(newCommand, queueCraftables, true)
							end
						end
					end
				end
			end
		end
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) + command.count * (recipe.numMade or 0)
		reagentsChanged[recipe.itemID] = true
		Skillet:AddToQueue(command)
		self.visited[command.recipeID] = nil
	end
end

-- command.complex means the queue entry requires additional crafting to take place prior to entering the queue.
-- we can't just increase the # of the first command if it happens to be the same recipe without making sure
-- the additional queue entry doesn't require some additional craftable reagents
function Skillet:AddToQueue(command)
	DA.DEBUG(0,"AddToQueue("..DA.DUMP1(command)..")")
	local queue = self.db.realm.queueData[self.currentPlayer]
	-- if self.linkedSkill then return end
	if (not command.complex) then		-- we can add this queue entry to any of the other entries
		local added
		for i=1,#queue,1 do
			if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID then
				queue[i].count = queue[i].count + command.count
				added = true
				break
			end
		end
		if not added then
			table.insert(queue, command)
		end
	elseif queue and #queue>0 then
		local i=#queue
		--check last item in queue - add current if they are the same
		if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID then
			queue[i].count = queue[i].count + command.count
		else
			table.insert(queue, command)
		end
	else
		table.insert(queue, command)
	end
	self:AdjustInventory()
end

function Skillet:RemoveFromQueue(index)
	DA.DEBUG(0,"RemoveFromQueue("..tostring(index)..")")
	local queue = self.db.realm.queueData[self.currentPlayer]
	local command = queue[index]
	local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
	local reagentsChanged = self.reagentsChanged
	if command.op == "iterate" then
		local recipe = self:GetRecipe(command.recipeID)
		if not command.count then
			command.count = 1
		end
		reagentsInQueue[recipe.itemID] = (reagentsInQueue[recipe.itemID] or 0) - (recipe.numMade or 0) * command.count
		reagentsChanged[recipe.itemID] = true
		for i=1,#recipe.reagentData,1 do
			local reagent = recipe.reagentData[i]
			reagentsInQueue[reagent.id] = (reagentsInQueue[reagent.id] or 0) + (reagent.numNeeded or 0) * command.count
			reagentsChanged[reagent.id] = true
		end
	end
	table.remove(queue, index)
	self:AdjustInventory()
end

function Skillet:ClearQueue()
	DA.DEBUG(0,"ClearQueue()")
	if #self.db.realm.queueData[self.currentPlayer]>0 then
		self.db.realm.queueData[self.currentPlayer] = {}
		self.db.realm.reagentsInQueue[self.currentPlayer] = {}
		self.dataScanned = false
		self:UpdateTradeSkillWindow()
	end
	--DA.DEBUG(0,"ClearQueue Complete")
end

--
-- Prints a list of saved queues
--
function Skillet:PrintSaved()
	DA.DEBUG(0,"PrintSaved()");
	local saved = self.db.profile.SavedQueues
	if saved then
		for name,queue in pairs(saved) do
			local size = 0
			for qpos,command in pairs(queue) do
				size = size + 1
			end
			print("name= "..tostring(name)..", size= "..tostring(size))
		end
	else
		print("No SavedQueues")
	end
end

--
-- Prints the contents of the queue name or the current queue
--
function Skillet:PrintQueue(name)
	DA.DEBUG(0,"PrintQueue("..tostring(name)..")");
	local queue
	if name then
		print("name= "..tostring(name))
		queue = self.db.profile.SavedQueues[name].queue
	else
		queue = self.db.realm.queueData[self.currentPlayer]
	end
	if queue then
		for qpos,command in pairs(queue) do
			print("qpos= "..tostring(qpos)..", command= "..DA.DUMP1(command))
		end
	else
		print("Queue is empty")
	end
end

function Skillet:ProcessQueue(altMode)
	DA.DEBUG(0,"ProcessQueue("..tostring(altMode)..")");
	local queue = self.db.realm.queueData[self.currentPlayer]
	local qpos = 1
	local skillIndexLookup = self.data.skillIndexLookup[self.currentPlayer]
	self.processingPosition = nil
	self.processingCommand = nil
	local command
--
-- find the first queue entry that is craftable
--
	repeat
		command = queue[qpos]
		DA.DEBUG(1,"command= "..DA.DUMP1(command))
		if command and command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			local craftable = true
			local skillIndex = skillIndexLookup[command.recipeID]
			local cooldown
			if skillIndex then
				cooldown = GetTradeSkillCooldown(skillIndex)
			end
			if cooldown then
				Skillet:Print(L["Skipping"],recipe.name,"-",L["has cooldown of"],SecondsToTime(cooldown))
				craftable = false
			else
				for i=1,#recipe.reagentData,1 do
					local reagent = recipe.reagentData[i]
					local reagentName = GetItemInfo(reagent.id) or reagent.id
					DA.DEBUG(1,"id= "..tostring(reagent.id)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(reagent.numNeeded))
					local numInBoth = GetItemCount(reagent.id, true)
					local numInBags = GetItemCount(reagent.id, false)
					local numInBank =  numInBoth - numInBags
					DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
					if numInBags < reagent.numNeeded then
						Skillet:Print(L["Skipping"],recipe.name,"-",L["need"],reagent.numNeeded,"x",reagentName,"("..L["have"],numInBags..")")
						craftable = false
						break
					end
				end -- for
			end -- cooldown
			if craftable then break end		-- exit the repeat loop, this command is craftable
		end -- iterate
		qpos = qpos + 1
	until qpos > #queue
--
-- either queue[qpos] is craftable or nothing is craftable
--
	if qpos > #queue then
		qpos = 1				-- nothing is craftable
		command = queue[qpos]
	end
--
-- Process this item in the queue:
-- Change professions if necessary (and come back later).
-- If we got here with nothing craftable in the queue,
-- let DoTradeSkill or DoCraft generate the error.
--
	if command then
		if command.op == "iterate" then
			self.queuecasting = true
			DA.DEBUG(1,"command= "..DA.DUMP1(command)..", currentTrade= "..tostring(currentTrade))
			local recipeID = command.recipeID
			local tradeID = command.tradeID
			local tradeName = command.tradeName
			local recipeIndex = command.recipeIndex
			local count = command.count
			if self.currentTrade ~= tradeID and tradeName then
				local Mining = self:GetTradeName(MINING)
				local Smelting = self:GetTradeName(SMELTING)
				if tradeName == Mining then tradeName = Smelting end
				Skillet:Print(L["Changing profession to"],tradeName,L["Press Process to continue"])
				DA.DEBUG(1,"executing CastSpellByName("..tostring(tradeName)..")")
				self.queuecasting = false
				self.changingTrade = tradeID
				CastSpellByName(tradeName)					-- switch professions
				self:QueueMoveToTop(qpos)		-- will this fix the changing profession loop?
				return
			end
			self.processingSpell = self:GetRecipeName(recipeID)		-- In Classic, the recipeID is the recipeName
			self.processingPosition = qpos
			self.processingCommand = command
			DA.DEBUG(0,"processingSpell= "..tostring(self.processingSpell)..", processingPosition= "..tostring(qpos)..", processingCommand= "..DA.DUMP1(command))
			if self.isCraft then
				DA.DEBUG(0,"DoCraft(spell= "..tostring(recipeIndex)..", count= "..tostring(count)..") altMode= "..tostring(altMode))
				DoCraft(recipeIndex, count)
			else
				DA.DEBUG(0,"DoTradeSkill(spell= "..tostring(recipeIndex)..", count= "..tostring(count)..") altMode= "..tostring(altMode))
				DoTradeSkill(recipeIndex, count)
			end
--
-- if alt down/right click - auto use items / like vellums (not implemented in Classic)
--
			if altMode then
				local itemID = Skillet:GetAutoTargetItem(tradeID)
				if itemID then
					DA.DEBUG(0,"UseItemByName("..tostring(itemID)..")")
					UseItemByName(itemID)
					self.queuecasting = false
				end
			end
			return
		else
			DA.DEBUG(0,"unsupported queue op: "..(command.op or "nil"))
		end		-- iterate
	else
--
-- Not sure how we got here but clear the queue for currentPlayer
--
		DA.DEBUG(0,"not command, clearing queueData for "..tostring(self.currentPlayer))
		self.db.realm.queueData[self.currentPlayer] = {}
	end		-- command
end

--
-- Adds the currently selected number of items to the queue
--
function Skillet:QueueItems(count)
	DA.DEBUG(0,"QueueItems("..tostring(count)..")")
	DA.DEBUG(1,"currentPlayer= "..tostring(self.currentPlayer)..", currentTrade= "..tostring(self.currentTrade)..", selectedSkill= "..tostring(self.selectedSkill))
	if not self.selectedSkill then return 0 end
	local skill = self:GetSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
	if not skill then return 0 end
	local recipe = self:GetRecipe(skill.id)
	local recipeID = skill.id
	if not count then
		count = skill.numCraftable / (recipe.numMade or 1)
		if count == 0 then
			count = (skill.numCraftableVendor or 0)/ (recipe.numMade or 1)
		end
		if count == 0 then
			count = (skill.numCraftableAlts or 0) / (recipe.numMade or 1)
		end
	end
	count = math.min(count, 9999)
	self.visited = {}
	if count > 0 then
		if self.currentTrade and self.selectedSkill then
			if recipe then
				local queueCommand = self:QueueCommandIterate(recipeID, count)
				self:QueueAppendCommand(queueCommand, Skillet.db.profile.queue_craftable_reagents)
			end
		end
	end
	return count
end

-- Queue the max number of craftable items for the currently selected skill
function Skillet:QueueAllItems()
	DA.DEBUG(0,"QueueAllItems()");
	local count = self:QueueItems()						-- no argument means queue em all
	return count
end

-- Adds the currently selected number of items to the queue and then starts the queue
function Skillet:CreateItems(count)
	local mouse = GetMouseButtonClicked()
	DA.DEBUG(0,"CreateItems("..tostring(count).."), "..tostring(mouse))
	if self:QueueItems(count) > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

-- Adds one item to the queue and then starts the queue
function Skillet:EnchantItem()
	DA.DEBUG(0,"EnchantItem()")
	self:CreateItems(1)
end

-- Queue and create the max number of craftable items for the currently selected skill
function Skillet:CreateAllItems()
	local mouse = GetMouseButtonClicked()
	DA.DEBUG(0,"CreateAllItems(), "..tostring(mouse))
	if self:QueueAllItems() > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

function Skillet:UNIT_SPELLCAST_SENT(event, unit, target, castGUID)
	DA.TRACE("UNIT_SPELLCAST_SENT("..tostring(unit)..", "..tostring(target)..", "..tostring(castGUID)..")")
	DA.TRACE("processingSpell= "..tostring(self.processingSpell))
end

function Skillet:UNIT_SPELLCAST_START(event, unit, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_START("..tostring(unit)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
end

function Skillet:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_SUCCEEDED("..tostring(unit)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
	if unit == "player" then
		if self.processingSpell and self.processingSpell == self.castSpellName or self.changingTrade then
			Skillet:ContinueCast(self.castSpellName)
		end
	end
end

function Skillet:UNIT_SPELLCAST_FAILED(event, unit, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_FAILED("..tostring(unit)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
	if unit == "player" and self.processingSpell and self.processingSpell == self.castSpellName then
		Skillet:StopCast(Skillet.castSpellName,false)
	end
end

function Skillet:UNIT_SPELLCAST_FAILED_QUIET(event, unit, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_FAILED_QUIET("..tostring(unit)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
	if unit == "player" and self.processingSpell and self.processingSpell == self.castSpellName then
		Skillet:StopCast(self.castSpellName,false)
	end
end

function Skillet:UNIT_SPELLCAST_INTERRUPTED(event, unit, castGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_INTERRUPTED("..tostring(unit)..", "..tostring(castGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
	if unit == "player" and self.processingSpell and self.processingSpell == self.castSpellName then
		Skillet:StopCast(self.castSpellName,false)
	end
end

function Skillet:UNIT_SPELLCAST_DELAYED(event, unit, sGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_DELAYED("..tostring(unit)..", "..tostring(sGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
end

function Skillet:UNIT_SPELLCAST_STOP(event, unit, sGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_STOP("..tostring(unit)..", "..tostring(sGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
	if unit == "player" and self.processingSpell and self.processingSpell == self.castSpellName then
		Skillet:StopCast(self.castSpellName,true)
	end
end

function Skillet:UNIT_SPELLCAST_CHANNEL_START(event, unit, sGUID, spellID)
	DA.TRACE("UNIT_SPELLCAST_CHANNEL_START("..tostring(unit)..", "..tostring(sGUID)..", "..tostring(spellID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
end

function Skillet:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, sGUID, sGUID)
	DA.TRACE("UNIT_SPELLCAST_CHANNEL_STOP("..tostring(unit)..", "..tostring(sGUID)..", "..tostring(sGUID)..")")
	self.castSpellID = spellID
	self.castSpellName = GetSpellInfo(spellID)
	DA.TRACE("spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
end

function Skillet:UI_ERROR_MESSAGE(event, errorType, message)
	DA.DEBUG(0,"UI_ERROR_MESSAGE("..tostring(message)..")")
end

function Skillet:UI_INFO_MESSAGE(event, errorType, message)
	DA.DEBUG(0,"UI_INFO_MESSAGE("..tostring(message)..")")
end

function Skillet:ContinueCast(spell)
	DA.DEBUG(0,"ContinueCast("..tostring(spell)..")")
	if self.changingTrade then			-- contains the tradeID we are changing to
		self.changingTrade = nil
		Skillet:SkilletShow()			-- seems to let DoTradeSkill know we have changed
	else
		self:AdjustInventory()
	end
end

function Skillet:StopCast(spell, success)
	DA.DEBUG(0,"StopCast("..tostring(spell)..", "..tostring(success)..")")
	if not self.db.realm.queueData then
		self.db.realm.queueData = {}
	end
	local queue = self.db.realm.queueData[self.currentPlayer]
	if spell == self.processingSpell then
		if success then
			local qpos = self.processingPosition or 1
			local command = nil
			if not queue[qpos] or queue[qpos] ~= self.processingCommand then
				for i=1,#queue,1 do
					if queue[i] == self.processingCommand then
						command = queue[i]
						qpos = i
						break
					end
				end
			else
				command = queue[qpos]
			end
			-- empty queue or command not found (removed?)
			if not queue[1] or not command then
				DA.DEBUG(0,"StopCast empty queue[1]= "..tostring(queue[1])..", command= "..tostring(command))
				self.queuecasting = false
				self.processingSpell = nil
				self.processingPosition = nil
				self.processingCommand = nil
				self:UpdateTradeSkillWindow()
				return
			end
			if command.op == "iterate" then
				command.count = command.count - 1
				if command.count < 1 then
					DA.DEBUG(0,"StopCast "..tostring(command.count).." < 1")
					self.queuecasting = false
					self.processingSpell = nil
					self.processingPosition = nil
					self.processingCommand = nil
					self.reagentsChanged = {}
					self:RemoveFromQueue(qpos)		-- implied queued reagent inventory adjustment in remove routine
					self:RescanTrade()
					DA.DEBUG(0,"removed queue command")
				end
			end
		else
			DA.DEBUG(0,"StopCast without success")
			self.processingSpell = nil
			self.processingPosition = nil
			self.processingCommand = nil
			self.queuecasting = false
		end
		DA.DEBUG(0,"StopCast is updating window")
		self:AdjustInventory()
	else
		DA.DEBUG(0,"StopCast called with "..tostring(spell).." ~= "..tostring(self.processingSpell))
	end
end

-- Stop a trade skill currently in prograess. We cannot cancel the current
-- item as that requires a "SpellStopCasting" call which can only be
-- made from secure code. All this does is stop repeating after the current item
function Skillet:CancelCast()
	DA.DEBUG(0,"CancelCast()")
--	StopTradeSkillRepeat()
end

-- Removes an item from the queue
function Skillet:RemoveQueuedCommand(queueIndex)
	DA.DEBUG(0,"RemoveQueuedCommand("..tostring(queueIndex)..")")
	if queueIndex == 1 then
		self:CancelCast()
	end
	self.reagentsChanged = {}
	self:RemoveFromQueue(queueIndex)
	self:UpdateQueueWindow()
	self:UpdateTradeSkillWindow()
end

-- Rebuilds reagentsInQueue list
function Skillet:ScanQueuedReagents()
	DA.DEBUG(0,"ScanQueuedReagents()")
	if self.linkedSkill or self.isGuild then
		return
	end
	local reagentsInQueue = {}
	for i,command in pairs(self.db.realm.queueData[self.currentPlayer]) do
		if command.op == "iterate" then
			local recipe = self:GetRecipe(command.recipeID)
			if not command.count then
				command.count = 1
			end
			if recipe.numMade > 0 then
				reagentsInQueue[recipe.itemID] = command.count * recipe.numMade + (reagentsInQueue[recipe.itemID] or 0)
			end
			for i=1,#recipe.reagentData,1 do
				local reagent = recipe.reagentData[i]
				reagentsInQueue[reagent.id] = (reagentsInQueue[reagent.id] or 0) - reagent.numNeeded * command.count
			end
		end
	end
	self.db.realm.reagentsInQueue[self.currentPlayer] = reagentsInQueue
end

function Skillet:QueueMoveToTop(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>1 and index<=#queue then
		table.insert(queue, 1, queue[index])
		table.remove(queue, index+1)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveUp(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>1 and index<=#queue then
		table.insert(queue, index-1, queue[index])
		table.remove(queue, index+1)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveDown(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>0 and index<#queue then
		table.insert(queue, index+2, queue[index])
		table.remove(queue, index)
	end
	self:UpdateTradeSkillWindow()
end

function Skillet:QueueMoveToBottom(index)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if index>0 and index<#queue then
		table.insert(queue, queue[index])
		table.remove(queue, index)
	end
	self:UpdateTradeSkillWindow()
end

local function tcopy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

function Skillet:SaveQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	local reagents = self.db.realm.reagentsInQueue[self.currentPlayer]
	if not name or name == "" then return end
	if not queue or #queue == 0 then
		Skillet:MessageBox(L["Queue is empty"])
		return
	end
	if self.db.profile.SavedQueues[name] and not overwrite then
		Skillet:AskFor(L["Queue with this name already exsists. Overwrite?"],
			function() Skillet:SaveQueue(name, true)  end
			)
		return
	end
	self.db.profile.SavedQueues[name] = {}
	self.db.profile.SavedQueues[name].queue = tcopy(queue)
	self.db.profile.SavedQueues[name].reagents = tcopy(reagents)
	Skillet.selectedQueueName = name
	Skillet:QueueLoadDropdown_OnShow()
	SkilletQueueSaveEditBox:SetText("")
end

function Skillet:LoadQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if not name or name == "" then return end
	if not self.db.profile.SavedQueues[name] then
		Skillet:MessageBox(L["No such queue saved"])
		return
	end
	if queue and #queue > 0 and not overwrite then
		Skillet:AskFor(L["Queue is not empty. Overwrite?"],
			function() Skillet:LoadQueue(name, true)  end
			)
		return
	end
	self.db.realm.queueData[self.currentPlayer] = tcopy(self.db.profile.SavedQueues[name].queue)
	self.db.realm.reagentsInQueue[self.currentPlayer] = tcopy(self.db.profile.SavedQueues[name].reagents)
	self:UpdateTradeSkillWindow()
end

function Skillet:DeleteQueue(name, overwrite)
	local queue = self.db.realm.queueData[self.currentPlayer]
	if not name or name == "" then return end
	if not self.db.profile.SavedQueues[name] then
		Skillet:MessageBox(L["No such queue saved"])
		return
	end
	if not overwrite then
		Skillet:AskFor(L["Really delete this queue?"],
			function() Skillet:DeleteQueue(name, true)  end
			)
		return
	end
	self.db.profile.SavedQueues[name] = nil
	Skillet.selectedQueueName = ""
	Skillet:QueueLoadDropdown_OnShow()
	self:UpdateTradeSkillWindow()
end
