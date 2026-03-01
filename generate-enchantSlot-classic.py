#!/usr/bin/python3
# Inspired by:
# https://github.com/Auctionator/Auctionator/blob/master/DB2_Scripts/convert-enchant-spell-to-enchant-classic.py
#
# This script converts the csv output from: 
# https://wago.tools/db2/SkillLineAbility 
# https://wago.tools/db2/SpellName
# https://wago.tools/db2/SpellEquippedItems
#
# to get a mapping of the enchant spell id to the invslot 
#
# One command line argument of the form "5.5.0.62258" is added to the .csv file name(s)
#
import csv
import sys
import os

def get_slot(s):
	start = "Enchant "
	end = " - "
	res = s
	idx1 = s.find(start)
	idx2 = s.find(end, idx1 + len(start))
	if idx1 != -1 and idx2 != -1:
		res = s[idx1 + len(start):idx2]
	return(res)

translateSlot = {
	"Bracer": "WRISTSLOT",	
	"Chest": "CHESTSLOT",	
	"Cloak": "BACKSLOT",
	"Boots": "FEETSLOT",	
	"Gloves": "HANDSSLOT",	
	"2H Weapon": "ENCHSLOT_2HWEAPON",	
	"Weapon": "ENCHSLOT_WEAPON",
	"Shield": "SHIELDSLOT",	
	"Ring": "FINGER0SLOT",
	"Off-Hand": "?",	
}

#
# Initialize the data storage
#
if len(sys.argv) < 2:
	print("Usage:")
	print("    One command line argument of the form '5.5.0.62258'") 
	exit()
else:
	build = sys.argv[1]

enchants_only = {}
with open('SkillLineAbility.'+build+'.csv', newline='') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		if row['SkillLine'] == '333':
			enchants_only[int(row['Spell'])] = True

spell_to_name = {}
with open('SpellName.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		spell_to_name[int(row['ID'])] = row['Name_lang']

spell_to_item_class = {}
spell_to_item_subclass = {}
spell_to_item_invtypes = {}
with open('SpellEquippedItems.'+build+'.csv') as f:
    reader = csv.DictReader(f, delimiter=',')
    for row in reader:
        spell_to_item_class[int(row['SpellID'])] = int(row['EquippedItemClass'])
        spell_to_item_subclass[int(row['SpellID'])] = int(row['EquippedItemSubclass'])
        spell_to_item_invtypes[int(row['SpellID'])] = int(row['EquippedItemInvTypes'])

data_format = """\
    [{}] = {{{}, {}, {}, "{}"}}, -- {}\
"""
unique_format = """\
	[{}] = "{}",\
	"""

o = open('enchantSlot.'+build+'.lua', "w")
o.write("-- \n")
o.write("-- " + build + "\n")
o.write("-- [spell] = {EquippedItemClass, EquippedItemSubclass, EquippedItemInvTypes, Slot}\n")
o.write("-- \n")
o.write("Skillet.enchantSlot = {\n")
unique_invtypes = {}
for spell_id in enchants_only:
	if spell_id in spell_to_name:
		spell_name = spell_to_name[spell_id]
		if spell_id in spell_to_item_class:
			spell_class = spell_to_item_class[spell_id]
			spell_subclass = spell_to_item_subclass[spell_id]
			spell_invtypes = spell_to_item_invtypes[spell_id]
			spell_slot = get_slot(spell_name)
			if spell_class == 4: 
				unique_invtypes[spell_invtypes] = spell_slot
			else:
				unique_invtypes[spell_subclass] = spell_slot
			if spell_slot in translateSlot:
				spell_slot = translateSlot[spell_slot]
			o.write(data_format.format(spell_id, spell_class, spell_subclass, spell_invtypes, spell_slot, spell_name) + "\n")
o.write("}\n")
o.close()

o = open('uniqueSlot.'+build+'.lua', "w")
o.write("-- \n")
o.write("-- " + build + "\n")
o.write("-- \n")
o.write("\nSkillet.uniqueSlot = {\n")
for invtype in unique_invtypes:
	o.write(unique_format.format(invtype,unique_invtypes[invtype]) + "\n")
o.write("}\n")
o.close()
