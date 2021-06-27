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

--
-- Iterates through a list of reagentIDs and recalculates craftability
--
function Skillet:AdjustInventory()
	DA.DEBUG(0,"AdjustInventory()")
--
-- Update queue for faster response time
--
	Skillet:ScanQueuedReagents()
	Skillet:InventoryScan()
	self:CalculateCraftableCounts()
	self:UpdateTradeSkillWindow()
end

--
-- This is the simplest command:  iterate recipeID x count
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
-- Reserve reagents
--
local function queueAppendReagent(command, reagentID, need, queueCraftables)
	local reagentName
	if reagentID then
		reagentName = GetItemInfo(reagentID)
	end
	DA.DEBUG(0,"queueAppendReagent("..tostring(reagentID)..", "..tostring(need)..", "..tostring(queueCraftables).."), name= "..tostring(reagentName)..", level= "..tostring(command.level))
	local reagentsInQueue = Skillet.db.realm.reagentsInQueue[Skillet.currentPlayer]
	local skillIndexLookup = Skillet.data.skillIndexLookup[Skillet.currentPlayer]
	local numInBoth = GetItemCount(reagentID,true)
	local numInBags = GetItemCount(reagentID)
	local numInBank =  numInBoth - numInBags
	local numInQueue = reagentsInQueue[reagentID] or 0
	DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank)..", numInQueue="..tostring(numInQueue))
	local have
	if Skillet.db.profile.ignore_banked_reagents then
		have = numInBags + numInQueue
	else
		have = numInBoth + numInQueue
	end
	DA.DEBUG(1,"queueCraftables= "..tostring(queueCraftables)..", need= "..tostring(need)..", have= "..tostring(have))
	if queueCraftables and need > have then
		local recipeSource = Skillet.db.global.itemRecipeSource[reagentID]
		DA.DEBUG(2,"recipeSource= "..DA.DUMP1(recipeSource))
		if recipeSource then
			for recipeSourceID in pairs(recipeSource) do
				local skillIndex = skillIndexLookup[recipeSourceID]
				DA.DEBUG(3,"recipeSourceID= "..tostring(recipeSourceID)..", skillIndex= "..tostring(skillIndex))
				if skillIndex then
--
-- Identify that this queue has craftable reagent requirements
--
					command.complex = true
					local recipeSource = Skillet:GetRecipe(recipeSourceID)
					local newCount = math.ceil((need - have)/recipeSource.numMade)
					local newCommand = Skillet:QueueCommandIterate(recipeSourceID, newCount)
					newCommand.level = (command.level or 0) + 1
--
-- Do not add IgnoredMats as it would cause loops
--
					if not Skillet.TradeSkillIgnoredMats[recipeSourceID] and
					  not Skillet.db.realm.userIgnoredMats[Skillet.currentPlayer][recipeSourceID] then
						Skillet:QueueAppendCommand(newCommand, queueCraftables)
						break
					else
						DA.DEBUG(3,"Did Not Queue "..tostring(recipeSourceID).." ("..tostring(recipeSource.name)..")")
					end
				end
			end -- for
		end
	end
	DA.DEBUG(0,"queueAppendReagent: level= "..tostring(command.level))
end

--
-- command.complex means the queue entry requires additional crafting to take place prior to entering the queue.
-- we can't just increase the # of the first command if it happens to be the same recipe without making sure
-- the additional queue entry doesn't require some additional craftable reagents
--
local function AddToQueue(command)
	DA.DEBUG(0,"AddToQueue("..DA.DUMP1(command)..")")
	local queue = Skillet.db.realm.queueData[self.currentPlayer]
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
--
--check last item in queue - add current if they are the same
--
		if queue[i].op == "iterate" and queue[i].recipeID == command.recipeID then
			queue[i].count = queue[i].count + command.count
		else
			table.insert(queue, command)
		end
	else
		table.insert(queue, command)
	end
end

--
-- Queue up the command and reserve reagents
--
function Skillet:QueueAppendCommand(command, queueCraftables)
	DA.DEBUG(0,"QueueAppendCommand("..DA.DUMP1(command)..", "..tostring(queueCraftables).."), level= "..tostring(command.level))
	local recipe = self:GetRecipe(command.recipeID)
	--DA.DEBUG(1,"recipe= "..DA.DUMP1(recipe))
	if recipe then
		if not command.level then
			self.newInQueue = {}
		end
		local level = command.level or 0
		if not self.newInQueue[level] then
			self.newInQueue[level] = {}
		end
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			--DA.DEBUG(3,"reagent= "..DA.DUMP1(reagent))
			queueAppendReagent(command, reagent.id, command.count * reagent.numNeeded, queueCraftables)
		end -- for
		self.newInQueue[level][recipe.itemID] = (self.newInQueue[level][recipe.itemID] or 0) + command.count * recipe.numMade
		--DA.DEBUG(2,"newInQueue["..tostring(level).."]["..tostring(recipe.itemID).."]= "..tostring(self.newInQueue[level][recipe.itemID]).." ("..tostring(recipe.name)..")")
		AddToQueue(command)
	end
	DA.DEBUG(0,"QueueAppendCommand: level= "..tostring(command.level))
	if not command.level then
		local reagentsInQueue = self.db.realm.reagentsInQueue[Skillet.currentPlayer]
		--DA.DEBUG(0,"QueueAppendCommand: newInQueue= "..DA.DUMP1(self.newInQueue))
		for level in pairs(self.newInQueue) do
			for itemID in pairs(self.newInQueue[level]) do
				reagentsInQueue[itemID] = (reagentsInQueue[itemID] or 0) + self.newInQueue[level][itemID]
			end
		end
		--DA.DEBUG(0,"QueueAppendCommand: reagentsInQueue= "..DA.DUMP1(reagentsInQueue))
		self:AdjustInventory()
	end
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
		self:UpdateTradeSkillWindow()
	end
	self:AdjustInventory()
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
		--DA.DEBUG(1,"command= "..DA.DUMP1(command))
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
					--DA.DEBUG(1,"id= "..tostring(reagent.id)..", reagentName="..tostring(reagentName)..", numNeeded="..tostring(reagent.numNeeded))
					local numInBoth = GetItemCount(reagent.id, true)
					local numInBags = GetItemCount(reagent.id, false)
					local numInBank =  numInBoth - numInBags
					--DA.DEBUG(1,"numInBoth= "..tostring(numInBoth)..", numInBags="..tostring(numInBags)..", numInBank="..tostring(numInBank))
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
			self.queueCasting = true
			--DA.DEBUG(1,"command= "..DA.DUMP1(command)..", currentTrade= "..tostring(currentTrade))
			local recipeID = command.recipeID
			local tradeID = command.tradeID
			local tradeName = command.tradeName
			local recipeIndex = command.recipeIndex
			local verifyIndex = self.data.skillIndexLookup[self.currentPlayer][recipeID]
			if recipeIndex ~= verifyIndex then
				DA.WARN("recipeIndex= "..tostring(recipeIndex).." and verifyIndex= "..tostring(verifyIndex).." do not match")
				self.queueCasting = false
				self:RemoveFromQueue(qpos)
				return
			end
			local count = command.count
			if self.currentTrade ~= tradeID and tradeName then
				--DA.DEBUG(1,"queue_crafts= "..tostring(self.db.profile.queue_crafts)..", skillIsCraft= "..tostring(self.skillIsCraft[tradeID]))
				if self.db.profile.queue_crafts and self.skillIsCraft[tradeID] then
--
-- Blizzard has restricted DoCraft(index) to anything but their own UI.
-- The queue_crafts option allows crafts to be queued so that
-- the reagents can be placed in the shopping list. 
-- This also queues the craft itself but we can't process that so remove it.
--
					self.queueCasting = false
					self:RemoveFromQueue(qpos)
					return
				else
					self.queueCasting = false
					self:ChangeTrade(tradeID)
					self:QueueMoveToTop(qpos)
					return
				end
			end
			self.processingSpell = self:GetRecipeName(recipeID)		-- In Classic, the recipeID is the recipeName
			self.processingPosition = qpos
			self.processingCommand = command
			--DA.DEBUG(1,"processingSpell= "..tostring(self.processingSpell)..", processingPosition= "..tostring(qpos)..", processingCommand= "..DA.DUMP1(command))
			if self.isCraft then
				--DA.DEBUG(1,"DoCraft(spell= "..tostring(recipeIndex)..", count= "..tostring(count)..") altMode= "..tostring(altMode))
				if self.DoCraft then 
					DoCraft(recipeIndex, count)
				else
					DA.WARN("processingSpell= "..tostring(self.processingSpell)..", processingPosition= "..tostring(qpos)..", processingCommand= "..DA.DUMP1(command))
					DA.WARN("DoCraft(spell= "..tostring(recipeIndex)..", count= "..tostring(count)..") altMode= "..tostring(altMode))
				end
			else
				--DA.DEBUG(1,"DoTradeSkill(spell= "..tostring(recipeIndex)..", count= "..tostring(count)..") altMode= "..tostring(altMode))
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
					self.queueCasting = false
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
	--DA.DEBUG(1,"currentPlayer= "..tostring(self.currentPlayer)..", currentTrade= "..tostring(self.currentTrade)..", selectedSkill= "..tostring(self.selectedSkill))
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

--
-- Queue the max number of craftable items for the currently selected skill
--
function Skillet:QueueAllItems()
	DA.DEBUG(0,"QueueAllItems()");
	local count = self:QueueItems()						-- no argument means queue em all
	return count
end

--
-- Adds the currently selected number of items to the queue and then starts the queue
--
function Skillet:CreateItems(count)
	local mouse = GetMouseButtonClicked()
	DA.DEBUG(0,"CreateItems("..tostring(count).."), "..tostring(mouse))
	if self:QueueItems(count) > 0 then
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
end

--
-- Adds one item to the queue and then starts the queue
--
function Skillet:EnchantItem()
	DA.DEBUG(0,"EnchantItem()")
	self:CreateItems(1)
end

--
-- Queue and create the max number of craftable items for the currently selected skill
--
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
	DA.TRACE("spellID= "..tostring(spellID)..", spellName= "..tostring(self.castSpellName)..", processingSpell= "..tostring(self.processingSpell))
	if unit == "player" then
		if self.processingSpell and self.processingSpell == self.castSpellName then
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
	DA.TRACE("UI_ERROR_MESSAGE("..tostring(message)..")")
end

function Skillet:UI_INFO_MESSAGE(event, errorType, message)
	DA.TRACE("UI_INFO_MESSAGE("..tostring(message)..")")
end

function Skillet:ContinueCast(spell)
	DA.DEBUG(0,"ContinueCast("..tostring(spell).."): changingTrade= "..tostring(self.changingTrade)..
	  ", processingSpell= "..tostring(self.processingSpell)..", queueCasting= "..tostring(self.queueCasting))
	if self.changingTrade then			-- contains the tradeID we are changing to
		self.currentTrade = self.changingTrade
		Skillet:SkilletShow()			-- seems to let DoTradeSkill know we have changed
		self.processingSpell = nil
		self.changingTrade = nil
	else
		self:AdjustInventory()
	end
end

function Skillet:StopCast(spell, success)
	DA.DEBUG(0,"StopCast("..tostring(spell)..", "..tostring(success).."): changingTrade= "..tostring(self.changingTrade)..
	  ", processingSpell= "..tostring(self.processingSpell)..", queueCasting= "..tostring(self.queueCasting))
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
--
-- empty queue or command not found (removed?)
--
			if not queue[1] or not command then
				DA.DEBUG(0,"StopCast empty queue[1]= "..tostring(queue[1])..", command= "..tostring(command))
				self.queueCasting = false
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
					self.queueCasting = false
					self.processingSpell = nil
					self.processingPosition = nil
					self.processingCommand = nil
					self.reagentsChanged = {}
					self:RemoveFromQueue(qpos)		-- implied queued reagent inventory adjustment in remove routine
					DA.DEBUG(0,"removed queue command")
				end
			end
			DA.DEBUG(0,"StopCast is updating window")
			self:AdjustInventory()
		else
			DA.DEBUG(0,"StopCast without success")
			self.queueCasting = false
			self.processingSpell = nil
			self.processingPosition = nil
			self.processingCommand = nil
		end
	else
		DA.DEBUG(0,"StopCast called with "..tostring(spell).." ~= "..tostring(self.processingSpell))
	end
end

--
-- Removes an item from the queue
--
function Skillet:RemoveQueuedCommand(queueIndex)
	DA.DEBUG(0,"RemoveQueuedCommand("..tostring(queueIndex)..")")
	self.reagentsChanged = {}
	self:RemoveFromQueue(queueIndex)
	self:UpdateQueueWindow()
	self:UpdateTradeSkillWindow()
end

--
-- Rebuilds reagentsInQueue list
--
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
