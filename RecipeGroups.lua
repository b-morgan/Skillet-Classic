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
--	--DA.DEBUG(3,			-- is used to track function calls
--	--DA.DEBUG(4,		-- is used to expand function call tables
--	--DA.DEBUG(5,			-- is used to display data within a function
--
--	comment all three for production
--	uncomment 0 and 2 for debugging
--	uncomment 1 for serious debugging
--
--	Note:
--	  comments on DA.DEBUG statements are directly in front of the DA
--	..comments on code that should not be executed are at the beginning of the line
--
--	The code that currently doesn't work is enabled / disabled in MainFrame.lua line 258:
--	257:	SkilletGroupLabel:SetText(L["Grouping"])
--	258:	SkilletRecipeGroupOperations:Disable()
--
--

local OVERALL_PARENT_GROUP_NAME = "*ALL*"

local skillLevel = {
	["optimal"]	        = 4,
	["medium"]          = 3,
	["easy"]            = 2,
	["trivial"]	        = 1,
}

function Skillet:RecipeGroupRename(oldName, newName)
	--DA.DEBUG(3,"RecipeGroupRename("..tostring(oldName)..", "..tostring(newName)..")")
	if self.data.groupList[self.currentPlayer][self.currentTrade][oldName] then
		self.data.groupList[self.currentPlayer][self.currentTrade][newName] = self.data.groupList[self.currentPlayer][self.currentTrade][oldName]
		self.data.groupList[self.currentPlayer][self.currentTrade][oldName] = nil
		local list = self.data.groupList[self.currentPlayer][self.currentTrade][newName]
		local oldKey = self.currentTrade..":"..oldName
		local newKey = self.currentTrade..":"..newName
		local key = self.currentPlayer..":"..self.currentTrade..":"..newName
		self.db.profile.groupDB[newKey] = self.db.profile.groupDB[oldKey]
		self.db.profile.groupDB[oldKey] = nil
		for groupName, groupData in pairs(list) do
			groupData.key = key
		end
	end
end

function Skillet:RecipeGroupFind(player, tradeID, label, name)
	--DA.DEBUG(3,"RecipeGroupFind("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(name)..")")
	if player and tradeID and label then
		local groupList = self.data.groupList
		if groupList and groupList[player] and groupList[player][tradeID] and groupList[player][tradeID][label] then
			return self.data.groupList[player][tradeID][label][name or OVERALL_PARENT_GROUP_NAME]
		end
	end
end

function Skillet:RecipeGroupFindRecipe(group, recipeID)
	--DA.DEBUG(3,"RecipeGroupFindRecipe("..tostring(group.name)..", "..tostring(recipeID)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if group then
		local entries = group.entries
		if entries then
			for i=1,#entries do
				if entries[i].recipeID then
					return entries[i]
				end
			end
		end
	end
end

--
-- creates a new recipe group
-- player = for whom the group is being created
-- tradeID = tradeID of the group
-- label = meta-group of groups.  for example, "Blizzard" is defined for the standard blizzard groups.  this allows multiple group settings
-- name = new group name (optional -- not specified means the overall parent group)
--
-- returns the newly created group record
--
local serial = 0
function Skillet:RecipeGroupNew(player, tradeID, label, name)
	--DA.DEBUG(3,"RecipeGroupNew("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(name)..")")
	local existingGroup = self:RecipeGroupFind(player, tradeID, label, name)
	if existingGroup then
		--DA.DEBUG(5,"RecipeGroupNew: group "..existingGroup.key.."/"..existingGroup.name.." exists")
		return existingGroup
	else
		--DA.DEBUG(5,"RecipeGroupNew: new group "..(name or OVERALL_PARENT_GROUP_NAME)..", "..tostring(label))
		local newGroup = {}
		local key = player..":"..tradeID..":"..label
		newGroup.expanded = true
		newGroup.key = key
		newGroup.name = name or OVERALL_PARENT_GROUP_NAME
		newGroup.entries = {}
		newGroup.locked = nil
		newGroup.groupIndex = serial
		serial = serial + 1
		self:InitGroupList(player, tradeID, label)
		self.data.groupList[player][tradeID][label][newGroup.name] = newGroup
		return newGroup
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupClearEntries(group, level)
	--DA.DEBUG(3,"RecipeGroupClearEntries("..tostring(group.name)..", "..tostring(level)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if not level then level = 1 end
	level = level + 1
	if group then
		--DA.DEBUG(5,"#group.entries= "..tostring(#group.entries))
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self:RecipeGroupClearEntries(group.entries[i].subGroup, level)
			end
		end
		group.entries = {}
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupCopy(s, d, noDB, level)
	--DA.DEBUG(3,"RecipeGroupCopy("..tostring(s.name)..", "..tostring(d.name)..", "..tostring(noDB)..", "..tostring(level)..")")
	--DA.DEBUG(4,"s= "..DA.DUMP1(s,1))
	--DA.DEBUG(4,"d= "..DA.DUMP1(d,1))
	if not level then level = 1 end
	level = level + 1
	if s and d then
		local player, tradeID, label = string.split(":", d.key)
		d.groupIndex = s.groupIndex
		d.expanded = s.expanded
		d.entries = {}
			for i=1,#s.entries do
			if s.entries[i].subGroup then
				local newGroup = self:RecipeGroupNew(player, tradeID, label, s.entries[i].name)
				self:RecipeGroupCopy(s.entries[i].subGroup, newGroup, noDB, level)
				self:RecipeGroupAddSubGroup(d, newGroup, s.entries[i].groupIndex, noDB)
			else
				self:RecipeGroupAddRecipe(d, s.entries[i].recipeID, s.entries[i].skillIndex, noDB)
			end
		end
	end
end

function Skillet:RecipeGroupAddRecipe(group, recipeID, skillIndex, noDB)
	--DA.DEBUG(3,"RecipeGroupAddRecipe("..tostring(group.name)..", "..tostring(recipeID)..", "..tostring(skillIndex)..", "..tostring(noDB)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if group and recipeID then
		local currentEntry
		for i=1,#group.entries do
			if group.entries[i].recipeID == recipeID then
				currentEntry = group.entries[i]
				break
			end
		end
		if not currentEntry then
			local newEntry = {}
			newEntry.recipeID = recipeID
			newEntry.name, newEntry.spellID = self:GetRecipeName(recipeID)
			newEntry.skillIndex = skillIndex
--			if newEntry ~= group then newEntry.parent = group end -- newEntry.parent = group
			newEntry.parent = group
			table.insert(group.entries, newEntry)
			currentEntry = newEntry
		else
			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name, currentEntry.spellID = self:GetRecipeName(recipeID)
--			if currentEntry ~= group then currentEntry.parent = group end -- currentEntry.parent
			currentEntry.parent = group
		end
		if not noDB then
			self:ConstructDBString(group)
		end
		return currentEntry
	end
end

function Skillet:RecipeGroupAddSubGroup(group, subGroup, groupID, noDB)
	--DA.DEBUG(3,"RecipeGroupAddSubGroup("..tostring(group.name)..", "..tostring(subGroup.name)..", "..tostring(groupID)..", "..tostring(noDB)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	--DA.DEBUG(4,"subGroup= "..DA.DUMP1(subGroup,1))
	if group and subGroup then
		local currentEntry
		for i=1,#group.entries do
			if group.entries[i].subGroup == subGroup then
				currentEntry = group.entries[i]
				break
			end
		end
		if not currentEntry then
			local newEntry = {}
--			if subGroup ~= group then subGroup.parent = group end -- subGroup.parent = group
			subGroup.parent = group
			subGroup.groupIndex = groupID
			newEntry.subGroup = subGroup
			newEntry.groupIndex = groupID
			newEntry.name = subGroup.name
--			if newEntry ~= group then newEntry.parent = group end -- newEntry.parent = group
			newEntry.parent = group
			table.insert(group.entries, newEntry)
		else
--			if subGroup ~= group then subGroup.parent = group end -- subGroup.parent = group
			subGroup.parent = group
			subGroup.groupIndex = groupID
			currentEntry.subGroup = subGroup
			currentEntry.groupIndex = groupID
			currentEntry.name = subGroup.name
--			if currentEntry ~= group then currentEntry.parent = group end -- currentEntry.parent = group
			currentEntry.parent = group
		end
		if not noDB then
			self:ConstructDBString(group)
		end
		return currentEntry
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupPasteEntry(entry, group, level)
	--DA.DEBUG(3,"RecipeGroupPasteEntry("..tostring(entry.name)..", "..tostring(group.name)..", "..tostring(level)..")")
	--DA.DEBUG(4,"entry= "..DA.DUMP1(entry,1))
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if not level then level = 1 end
	level = level + 1
	if entry and group and entry.parent ~= group then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		--DA.DEBUG(5,"RecipeGroupPasteEntry: paste "..entry.name.." into "..group.name)
		local parentGroup = group
		if entry.subGroup then
			if entry.subGroup == group then
				--DA.DEBUG(5,"RecipeGroupPasteEntry: entry.subGroup is equal to group= "..tostring(group.name))
				return
			end
			local newName, newIndex = self:RecipeGroupNewName(group.key, entry.name)
			local newGroup = self:RecipeGroupNew(player, tradeID, label, newName)
			self:RecipeGroupAddSubGroup(parentGroup, newGroup, newIndex)
			if entry.subGroup.entries then
				--DA.DEBUG(5,"RecipeGroupPasteEntry: "..tostring(entry.subGroup.name) .. " " .. #entry.subGroup.entries)
				for i=1,#entry.subGroup.entries do
					--DA.DEBUG(5,"RecipeGroupPasteEntry: "..tostring(entry.subGroup.entries[i].name) .. ", " .. newGroup.name)
					self:RecipeGroupPasteEntry(entry.subGroup.entries[i], newGroup, level)
				end
			end
		else
--
-- hope we never get here
--
			local newIndex = self.data.skillIndexLookup[player][entry.recipeID]
			if not newIndex then
				--DA.DEBUG(3,"RecipeGroupPasteEntry: add new skillDB entry= "..tostring(entry.recipeID))
				newIndex = #self.db.realm.skillDB[player][tradeID] + 1
				self.db.realm.skillDB[player][tradeID][newIndex] = "x:"..entry.recipeID
			end
			self:RecipeGroupAddRecipe(parentGroup, entry.recipeID, newIndex)
		end
	else
		--DA.DEBUG(5,"RecipeGroupPasteEntry: failed entry and group and entry.parent ~= group ")
	end
end

function Skillet:RecipeGroupMoveEntry(entry, group)
	--DA.DEBUG(3,"RecipeGroupMoveEntry("..tostring(entry.name)..", "..tostring(group.name)..")")
	--DA.DEBUG(4,"entry= "..DA.DUMP1(entry,1))
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if entry and group and entry.parent ~= group then
		if entry.subGroup then
			if entry.subGroup == group then
				return
			end
		end
		local entryGroup = entry.parent
		if entryGroup then
			local loc
			for i=1,#entryGroup.entries do
				if entryGroup.entries[i] == entry then
					loc = i
					break
				end
			end
			table.remove(entryGroup.entries, loc)
			table.insert(group.entries, entry)
--			if entry ~= group then entry.parent = group end -- entry.parent = group
			entry.parent = group
			Skillet:ConstructDBString(group)
			Skillet:ConstructDBString(entryGroup)
		end
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupDeleteGroup(group, level)
	--DA.DEBUG(3,"RecipeGroupDeleteGroup("..tostring(group.name)..", "..tostring(level)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if not level then level = 1 end
	level = level + 1
	if group then
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self.RecipeGroupDeleteGroup(group.entries[i].subGroup, level)
			end
		end
		group.entries = nil
		local player, tradeID, label = string.split(":",group.key)
		local gkey = tradeID..":"..label
		self.db.profile.groupDB[gkey][group.name] = nil
	end
end

function Skillet:RecipeGroupDeleteEntry(entry)
	--DA.DEBUG(3,"RecipeGroupDeleteEntry("..tostring(entry.name)..")")
	--DA.DEBUG(4,"entry= "..DA.DUMP1(entry,1))
	if entry then
		local entryGroup = entry.parent
		local loc
		if not entryGroup.entries then return end
		for i=1,#entryGroup.entries do
			if entryGroup.entries[i] == entry then
				loc = i
				break
			end
		end
		table.remove(entryGroup.entries, loc)
		if entry.subGroup then
			self:RecipeGroupDeleteGroup(entry.subGroup)
		end
		Skillet:ConstructDBString(entryGroup)
	end
end

function Skillet:RecipeGroupNewName(key, name)
	--DA.DEBUG(3,"RecipeGroupNewName("..tostring(key)..", "..tostring(name)..")")
	local index = 1
	if key and name then
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)
		local groupList = self.data.groupList[player][tradeID][label]
		for v in pairs(groupList) do
			index = index + 1
		end
		if groupList[name] then
			local tempName = name..":"
			local suffix = 2
			while groupList[tempName..suffix] do
				suffix = suffix + 1
			end
			name = tempName..suffix
		end
	end
	--DA.DEBUG(3,"RecipeGroupNewName: name= "..tostring(name)..", index= "..tostring(index))
	return name, index
end

function Skillet:RecipeGroupRenameEntry(entry, name)
	--DA.DEBUG(3,"RecipeGroupRenameEntry("..tostring(entry.name)..", "..tostring(name)..")")
	--DA.DEBUG(4,"entry= "..DA.DUMP1(entry,1))
	if entry and name then
		local key = entry.parent.key
		local player, tradeID, label = string.split(":", key)
		tradeID = tonumber(tradeID)
		if entry.subGroup then
			local oldName = entry.subGroup.name
			local groupList = self.data.groupList[player][tradeID][label]
			if oldName ~= name then
				name = self:RecipeGroupNewName(key, name)
				entry.subGroup.name = name
				groupList[name] = groupList[oldName]
				groupList[oldName] = nil
				entry.name = name
			end
		end
		self:ConstructDBString(entry.parent)
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupSort(group, sortMethod, desc, level)
	--DA.DEBUG(3,"RecipeGroupSort("..tostring(group.name)..", "..tostring(sortMethod)..", "..tostring(desc)..", "..tostring(level)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	if not level then level = 1 end
	level = level + 1
	if group then
		--DA.DEBUG(5,"group.entries= "..DA.DUMP1(group.entries,1))
		for v, entry in pairs(group.entries) do
			if entry.subGroup and entry.subGroup ~= group then
				self:RecipeGroupSort(entry.subGroup, sortMethod, desc, level)
			end
		end
		if group.entries and #group.entries > 1 then
			if desc then
				table.sort(group.entries, function(a,b)
					return sortMethod(Skillet.currentTrade, b, a)
				end)
			else
				table.sort(group.entries, function(a,b)
					return sortMethod(Skillet.currentTrade, a, b)
				end)
			end
		end
	end
end

function Skillet:RecipeGroupInitFlatten(group, list)
	--DA.DEBUG(3,"RecipeGroupInitFlatten("..tostring(group.name)..", "..tostring(list)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	--DA.DEBUG(4,"list= "..DA.DUMP1(list,1))
	if group and list then
		local newSkill = {}
		newSkill.name = group.name
		newSkill.groupIndex = group.groupIndex
		newSkill.subGroup = group
		newSkill.expanded = true
		newSkill.depth = 0
--		if newSkill.parent ~= group.parent then newSkill.parent = group.parent end -- newSkill.parent = group.parent
		--DA.DEBUG(5,"newSkill= "..DA.DUMP1(newSkill,1))
		newSkill.parent = group.parent
		list[1] = newSkill
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupFlatten(group, depth, list, index, level)
	--DA.DEBUG(3,"RecipeGroupFlatten("..tostring(group.name)..", "..tostring(depth)..", "..tostring(list.name)..", "..tostring(index)..", "..tostring(level)..")")
	--DA.DEBUG(4,"group= "..DA.DUMP1(group,1))
	--DA.DEBUG(4,"list= "..DA.DUMP1(list,1))
	if not level then level = 1 end
	level = level + 1
	local num = 0
	if group and list then
		for v, entry in pairs(group.entries) do
			if entry.subGroup then
				--DA.DEBUG(5,"RecipeGroupFlatten: Have a subGroup= "..tostring(entry.subGroup))
				local newSkill = entry
				local inSub = 0
				newSkill.depth = depth
				if (index > 0) then
					newSkill.parentIndex = index
				else
					newSkill.parentIndex = nil
				end
				num = num + 1
				list[num + index] = newSkill
				if entry.subGroup.expanded then
					inSub = self:RecipeGroupFlatten(entry.subGroup, depth+1, list, num+index, level)
				end
				num = num + inSub
			else
				--DA.DEBUG(5,"RecipeGroupFlatten: No subGroup")
				local skillData = self:GetSkill(self.currentPlayer, self.currentTrade, entry.skillIndex)
				local recipe = self:GetRecipe(entry.recipeID)
				if skillData then
					--DA.DEBUG(5,"RecipeGroupFlatten: Have skillData= "..tostring(skillData))
--
-- apply (a subset of) filtering
--
					local filterCraftable = false
--
-- are we hiding anything that is trivial (has no chance of giving a skill point)
-- (will be tested later)
--
					local filterLevel = ((skillLevel[entry.difficulty] or skillLevel[skillData.difficulty] or 0) < (self:GetTradeSkillOption("filterLevel")))
--
-- are we hiding anything that can't be created with the mats on this character?
--
					if Skillet:GetTradeSkillOption("hideuncraftable") then
						--DA.DEBUG(5,"name="..tostring(skillData.name)..", numCraftable="..tostring(skillData.numCraftable)..", numRecursive="..tostring(skillData.numRecursive)..", numCraftableVendor="..tostring(skillData.numCraftableVendor)..", numCraftableAlts="..tostring(skillData.numCraftableAlts))
						if not (skillData.numCraftable and skillData.numCraftable > 0 and Skillet:GetTradeSkillOption("filterInventory-bag")) and
						   not (skillData.numRecursive and skillData.numRecursive > 0 and Skillet:GetTradeSkillOption("filterInventory-crafted")) and
						   not (skillData.numCraftableVendor and skillData.numCraftableVendor > 0 and Skillet:GetTradeSkillOption("filterInventory-vendor")) and
						   not (skillData.numCraftableAlts and skillData.numCraftableAlts > 0 and Skillet:GetTradeSkillOption("filterInventory-alts")) then
							filterCraftable = true
						end
					end
--
--	call our internal recipe filter
--
					if Skillet:RecipeFilter(entry.skillIndex) then
						filterCraftable = true
					end
--
--	call any external recipe filters
--
					if Skillet.recipeFilters then
						for _,f in pairs(Skillet.recipeFilters) do
							if f.filterMethod(f.namespace, entry.skillIndex) then
								filterCraftable = true
							end
						end
					end
--
-- do something with the results
--
					local newSkill = entry
					newSkill.depth = depth
					newSkill.skillData = skillData
					newSkill.spellID = recipe.spellID
					if (index>0) then
						newSkill.parentIndex = index
					else
						newSkill.parentIndex = nil
					end
					if not (filterLevel or filterCraftable) then
						num = num + 1
						list[num + index] = newSkill
					end
				else
					--DA.DEBUG(5,"No skillData")
				end
			end
		end
	end
	return num
end

function Skillet:PruneList(player)
	--DA.DEBUG(3,"PruneList()")
	if self.data.groupList then
		local perPlayerList = self.data.groupList[player]
		for trade, perTradeList in pairs(perPlayerList) do
			for label, perLabelList in pairs(perTradeList) do
				for name, group in pairs(perLabelList) do
					if type(group) == "table" and name ~= OVERALL_PARENT_GROUP_NAME and group.parent == nil then
						--DA.DEBUG(5,"PruneList: Pruning "..tostring(group.name)..", groupIndex= "..tostring(group.groupIndex))
						perLabelList[name] = nil
						if self.db.profile.groupDB and self.db.profile.groupDB[trade..":"..label] then
							self.db.profile.groupDB[trade..":"..label][name] = nil
						end
					end
				end
			end
		end
	end
end

function Skillet:InitGroupList(player, tradeID, label)
	--DA.DEBUG(3,"InitGroupList("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..")")
	if not self.data.groupList then
		self.data.groupList = {}
	end
	if not self.data.groupList[player] then
		self.data.groupList[player] = {}
	end
	if not self.data.groupList[player][tradeID] then
		self.data.groupList[player][tradeID] = {}
	end
	if not self.data.groupList[player][tradeID][label] then
		self.data.groupList[player][tradeID][label] = {}
	end
end

--
-- make a db string for saving groups
--
-- Note: this function is recursive
--
function Skillet:ConstructDBString(group, level)
	--DA.DEBUG(3,"ConstructDBString("..tostring(group.name)..", "..tostring(level)..")")
	--DA.DEBUG(4,"CDBS: group= "..DA.DUMP1(group,1))
	if not level then level = 1 end
	level = level + 1
	if group and not group.autoGroup then
		local key = group.key
		local player, tradeID, label = string.split(":",key)
		local gkey = tradeID..":"..label
		tradeID = tonumber(tradeID)
		if not self.data.groupList[player][tradeID][label].autoGroup then
			local groupString = group.groupIndex
			for v,entry in pairs(group.entries) do
				if not entry.subGroup then
--					groupString = groupString..":'"..entry.recipeID
					local rID
					rID = string.gsub(entry.recipeID, ":", ";")
					rID = string.gsub(rID, "'", "`")
					groupString = groupString..":'"..rID
				else
					groupString = groupString..":g"..entry.groupIndex	-- entry.subGroup.name
					self:ConstructDBString(entry.subGroup, level)
				end
			end
			if not self.db.profile.groupDB[gkey] then
				self.db.profile.groupDB[gkey] = {}
			end
			--DA.DEBUG(5,"CDBS: groupString= "..tostring(groupString))
			self.db.profile.groupDB[gkey][group.name] = groupString
		end
	end
end

function Skillet:DeconstructDBStrings() -- DDBS(1): DDBS(2)
	--DA.DEBUG(3,"DeconstructDBStrings()")
--
-- first pass, find all the defined groups
--
	local groupNames = {}
	local serial = 1
	for gkey, groupList in pairs(self.db.profile.groupDB) do
		local player = self.currentPlayer
		local tradeID, label = string.split(":", gkey)
		local key = player..":"..gkey
		tradeID = tonumber(tradeID)
		if tradeID == self.currentTrade then
			self:InitGroupList(player, tradeID, label)
			for name,list in pairs(groupList) do
				--DA.DEBUG(5,"DDBS(1): name= "..tostring(name)..", list= "..tostring(list))
				local group = self:RecipeGroupNew(player, tradeID, label, name)
				local groupContents = { string.split(":",list) }
				local groupID = tonumber(groupContents[1]) or serial
				serial = serial + 1
				group.groupIndex = groupID
				groupNames[groupID] = name
			end
		end
	end
--
-- second pass, fill all the groups with data
--
	for gkey, groupList in pairs(self.db.profile.groupDB) do
		local player = self.currentPlayer
		local tradeID, label = string.split(":", gkey)
		local key = player..":"..gkey
		tradeID = tonumber(tradeID)
		if tradeID == self.currentTrade and self.data.skillIndexLookup then
			for name,list in pairs(groupList) do
				--DA.DEBUG(5,"DDBS(2): name= "..tostring(name)..", list= "..tostring(list))
				local group = self:RecipeGroupFind(player, tradeID, label, name)
				local groupIndex = group.groupIndex
				if not group.initialized then
					group.initialized = true
					local groupContents = { string.split(":",list) }
					--DA.DEBUG(5,"DDBS(2): groupContents= "..DA.DUMP1(groupContents))
					for j=2,#groupContents do
						local recipeID = groupContents[j]
						if string.sub(recipeID,1,1) == "g" then
							local id = tonumber(string.sub(recipeID,2))
							--DA.DEBUG(5,"DDBS(2): id= "..tostring(id))
							local subGroup = self:RecipeGroupFind(player, tradeID, label, groupNames[id])
							if subGroup then
								--DA.DEBUG(5,"DDBS(2): adding subGroup "..tostring(groupContents[1]))
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.groupIndex, true)
							end
						elseif string.sub(recipeID,1,1) == "'" then
							recipeID = string.sub(recipeID,2)
							recipeID = string.gsub(recipeID, ";", ":")
							recipeID = string.gsub(recipeID, "`", "'")
							--DA.DEBUG(5,"DDBS(2): recipeID= "..tostring(recipeID))
							local skillIndex = self.data.skillIndexLookup[player][recipeID]
							if skillIndex then 
								--DA.DEBUG(5,"DDBS(2): adding recipe "..recipeID.." to "..group.name.."/"..player..":"..skillIndex)
								self:RecipeGroupAddRecipe(group, recipeID, skillIndex, true)
							end
						else
							--DA.DEBUG(3,"DDBS(2): Serious problem with "..tostring(recipeID))
						end
					end
				end
			end
			self:PruneList(player)
		end
	end
end

--
-- Called when the grouping drop down is displayed
--
function Skillet:RecipeGroupDropdown_OnShow()
	--DA.DEBUG(3,"RecipeGroupDropdown_OnShow()")
	UIDropDownMenu_Initialize(SkilletRecipeGroupDropdown, Skillet.RecipeGroupDropdown_Initialize)
	SkilletRecipeGroupDropdown.displayMode = "MENU"
	Skillet:DeconstructDBStrings()
	local groupLabel = self:GetTradeSkillOption("grouping") or self.currentGroupLabel
	UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, groupLabel, true)
	UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, groupLabel)
end

--
-- The method we use the initialize the grouping drop down.
--
function Skillet.RecipeGroupDropdown_Initialize(menuFrame,level)
	--DA.DEBUG(3,"RecipeGroupDropdown_Initialize("..tostring(menuFrame)..", "..tostring(level)..")")
	if level == 1 then  -- group labels
		local entry = {}
		entry.text = L["Flat"]
		entry.value = "Flat"
		entry.func = Skillet.RecipeGroupSelect
		entry.arg1 = Skillet
		entry.arg2 = "Flat"
		entry.icon = "Interface\\Addons\\Skillet-Classic\\Icons\\locked.tga"
		if Skillet.currentGroupLabel == "Flat" then
			entry.checked = true
		else
			entry.checked = false
		end
		UIDropDownMenu_AddButton(entry)
		if Skillet.data.groupList[Skillet.currentPlayer] then
			local numGroupsAdded = 0
			if Skillet.data.groupList[Skillet.currentPlayer][Skillet.currentTrade] then
				for labelName, groupData in pairs(Skillet.data.groupList[Skillet.currentPlayer][Skillet.currentTrade]) do
					if labelName == "Blizzard" then
						entry.text = L["Blizzard"]
					else
						entry.text = labelName
					end
					entry.value = labelName
					entry.func = Skillet.RecipeGroupSelect
					entry.arg1 = Skillet
					entry.arg2 = labelName
					if labelName == "Blizzard" or Skillet:GetTradeSkillOption(labelName.."-locked") then
						entry.icon = "Interface\\Addons\\Skillet-Classic\\Icons\\locked.tga"
					else
						entry.icon = nil -- "Interface\\Addons\\Skillet-Classic\\Icons\\unlocked.tga"
					end
					if Skillet.currentGroupLabel == labelName then
						entry.checked = true
					else
						entry.checked = false
					end
					UIDropDownMenu_AddButton(entry)
					numGroupsAdded = numGroupsAdded + 1
				end
			end
		end
	end
end

--
-- Called when the user selects an item in the sorting drop down
--
function Skillet:RecipeGroupSelect(menuFrame,label)
	--DA.DEBUG(3,"RecipeGroupSelect("..tostring(menuFrame)..", "..tostring(label)..")")
	Skillet:SetTradeSkillOption("grouping", label)
	Skillet.currentGroupLabel = label
	Skillet.currentGroup = nil
	Skillet:RecipeGroupDropdown_OnShow()
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:RecipeGroupIsLocked()
	local answer
	if self.currentGroupLabel == "Flat" or self.currentGroupLabel == "Blizzard" then
		answer = true 
	else
		answer = Skillet:GetTradeSkillOption(self.currentGroupLabel.."-locked")
	end
	--DA.DEBUG(3,"RecipeGroupIsLocked()= "..tostring(answer))
	return answer
end

function Skillet:ToggleTradeSkillOptionDropDown(option)
	--DA.DEBUG(3,"RecipeGroupOperations_OnClick("..tostring(option)..")")
	self:ToggleTradeSkillOption(option)
	self:RecipeGroupDropdown_OnShow()
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

--
-- Called when the grouping operators drop down is displayed
--
function Skillet:RecipeGroupOperations_OnClick(this)
	--DA.DEBUG(3,"RecipeGroupOperations_OnClick("..tostring(this)..")")
	if not RecipeGroupOpsMenu then
		RecipeGroupOpsMenu = CreateFrame("Frame", "RecipeGroupOpsMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(RecipeGroupOpsMenu, SkilletRecipeGroupOpsMenu_Init, "MENU")
	ToggleDropDownMenu(1, nil, RecipeGroupOpsMenu, this, this:GetWidth(), 0)
end

--
-- The method we use the initialize the group ops drop down.
--
function SkilletRecipeGroupOpsMenu_Init(menuFrame,level)
	--DA.DEBUG(3,"SkilletRecipeGroupOpsMenu_Init("..tostring(menuFrame)..", "..tostring(label)..")")
	if level == 1 then
		local entry = {}
		local null = {}
		null.text = ""
		null.disabled = true
		entry.text = L["New"]
		entry.value = "New"
		entry.func = Skillet.RecipeGroupOpNew
		UIDropDownMenu_AddButton(entry)
		entry.text = L["Copy"]
		entry.value = "Copy"
		entry.func = Skillet.RecipeGroupOpCopy
		UIDropDownMenu_AddButton(entry)
		entry.text = L["Rename"]
		entry.value = "Rename"
		entry.func = Skillet.RecipeGroupOpRename
		UIDropDownMenu_AddButton(entry)
		entry.text = L["Lock/Unlock"]
		entry.value = "Lock/Unlock"
		entry.func = Skillet.RecipeGroupOpLock
		UIDropDownMenu_AddButton(entry)
		entry.text = L["Delete"]
		entry.value = "Delete"
		entry.func = Skillet.RecipeGroupOpDelete
		UIDropDownMenu_AddButton(entry)
	end
end

function Skillet:RecipeGroupOpNew()
	--DA.DEBUG(3,"RecipeGroupOpNew()")
	local label = "Custom"
	local player = Skillet.currentPlayer
	local tradeID = Skillet.currentTrade
	local groupList = Skillet.data.groupList
	if Skillet.db.profile.groupSN[tradeID] then
		label = "Custom "..Skillet.db.profile.groupSN[tradeID]
		Skillet.db.profile.groupSN[tradeID] = Skillet.db.profile.groupSN[tradeID] + 1
	else
		label = "Custom"
		Skillet.db.profile.groupSN[tradeID] = 1
	end
	local newMain = Skillet:RecipeGroupNew(player, tradeID, label)
	Skillet:ConstructDBString(newMain)
	Skillet:SetTradeSkillOption("grouping", label)
	Skillet.currentGroupLabel = label
	UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, label)
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:RecipeGroupOpCopy()
	--DA.DEBUG(3,"RecipeGroupOpCopy()")
	local label = "Custom"
	local player = Skillet.currentPlayer
	local tradeID = Skillet.currentTrade
	local groupList = Skillet.data.groupList
	if Skillet.db.profile.groupSN[tradeID] then
		label = "Custom "..Skillet.db.profile.groupSN[tradeID]
	end
	local newMain = Skillet:RecipeGroupNew(player, tradeID, label)
	local oldMain = Skillet:RecipeGroupFind(player, tradeID, Skillet.currentGroupLabel)
	Skillet:RecipeGroupCopy(oldMain, newMain, false)
	Skillet:ConstructDBString(newMain)
	Skillet:SetTradeSkillOption("grouping", label)
	Skillet.currentGroupLabel = label
	UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, label)
	Skillet:SortAndFilterRecipes()
	Skillet:UpdateTradeSkillWindow()
end

function Skillet:GroupNameEditSave()
	--DA.DEBUG(3,"GroupNameEditSave()")
	local newName = GroupButtonNameEdit:GetText()
	Skillet:RecipeGroupRename(Skillet.currentGroupLabel, newName)
	GroupButtonNameEdit:Hide()
	SkilletRecipeGroupDropdownText:Show()
	SkilletRecipeGroupDropdownText:SetText(newName)
	Skillet.currentGroupLabel = newName
end

function Skillet:RecipeGroupOpRename()
	--DA.DEBUG(3,"RecipeGroupOpRename()")
	if not Skillet:RecipeGroupIsLocked() then
		GroupButtonNameEdit:SetText(Skillet.currentGroupLabel)
		GroupButtonNameEdit:SetParent(SkilletRecipeGroupDropdownText:GetParent())
		local numPoints = SkilletRecipeGroupDropdownText:GetNumPoints()
		for p=1,numPoints do
			GroupButtonNameEdit:SetPoint(SkilletRecipeGroupDropdownText:GetPoint(p))
		end
		GroupButtonNameEdit:Show()
		SkilletRecipeGroupDropdownText:Hide()
	end
end

function Skillet:RecipeGroupOpLock()
	--DA.DEBUG(3,"RecipeGroupOpLock()")
	local label = Skillet.currentGroupLabel
	if label ~= "Blizzard" and label ~= "Flat" then
		Skillet:ToggleTradeSkillOption(label.."-locked")
	end
end

function Skillet:RecipeGroupOpDelete()
	--DA.DEBUG(3,"RecipeGroupOpDelete()")
	if not Skillet:RecipeGroupIsLocked() then
		local player = Skillet.currentPlayer
		local tradeID = Skillet.currentTrade
		local label = Skillet.currentGroupLabel
		Skillet.data.groupList[player][tradeID][label] = nil
		Skillet.db.profile.groupDB[tradeID..":"..label] = nil
		Skillet.db.profile.groupSN[tradeID..":"..label] = nil
--
-- if the only entry left is "Blizzard", then delete the profession SN
--
		local count = 0
		for group in pairs(Skillet.data.groupList[player][tradeID]) do
			count = count + 1
		end
		if count == 1 then
			Skillet.db.profile.groupSN[tradeID] = nil
		end
--
-- switch back to showing the "Blizzard" group
--
		label = "Blizzard"
		Skillet:SetTradeSkillOption("grouping", label)
		Skillet.currentGroupLabel = label
		UIDropDownMenu_SetSelectedName(SkilletRecipeGroupDropdown, label, true)
		UIDropDownMenu_SetText(SkilletRecipeGroupDropdown, label)
		Skillet:SortAndFilterRecipes()
		Skillet:UpdateTradeSkillWindow()
	end
end

--
-- Note: this function is recursive
--
function Skillet:RecipeGroupDump(group, level)
	--DA.DEBUG(3,"RecipeGroupDump("..tostring(group.name)..", "..tostring(level)..")")
	if not level then level = 1 end
	level = level + 1
	if group then
		local groupString = group.key.."/"..group.name.."="..group.groupIndex
		for v,entry in pairs(group.entries) do
			if not entry.subGroup then
				groupString = groupString..":"..entry.recipeID
			else
				groupString = groupString..":"..entry.subGroup.name
				self:RecipeGroupDump(entry.subGroup, level)
			end
		end
		--DA.DEBUG(5,groupString)
	else
		--DA.DEBUG(5,"no match")
	end
end
