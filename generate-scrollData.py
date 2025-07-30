#!/usr/bin/python3
# This script converts the csv output from: 
# https://wago.tools/db2/item 
# https://wago.tools/db2/itemeffect
# https://wago.tools/db2/spelllevels 
# https://wago.tools/db2/spellequippeditems
# https://wago.tools/db2/SpellName 
# to get a mapping of the enchant spell id to the enchant item 
# (for searching the AH for the enchant or
# calculation crafting profit), and spell level/equipped slot (for the vellum
# needed for crafting cost/profit)
#
# One command line argument of the form "5.5.0.62258" is added to the .csv file name(s)
#
# The output should be redirected to a file with a ">filename" on the command line.
#
import csv
import sys
import os

enchants_only = {}

#
# Initialize the data storage
#
if len(sys.argv) < 2:
	print("Usage:")
	exit()

if len(sys.argv) >= 2:
	build = sys.argv[1]

with open('item.'+build+'.csv', newline='') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		if row['ClassID'] == '0' and row['SubclassID'] == '6':
			enchants_only[int(row['ID'])] = True

item_to_spell = {}
with open('itemeffect.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		item_to_spell[int(row['ParentItemID'])] = int(row['SpellID'])

spell_to_level = {}
with open('spelllevels.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		spell_to_level[int(row['SpellID'])] = int(row['BaseLevel'])

spell_to_item_class = {}
with open('spellequippeditems.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		spell_to_item_class[int(row['SpellID'])] = int(row['EquippedItemClass'])

spell_to_name = {}
with open('spellname.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		spell_to_name[int(row['ID'])] = row['Name_lang']

data_format = """\
    [{}] = {}, -- {}\
"""

print("Skillet.scrollData = {")
for item_id in enchants_only:
	if item_id in item_to_spell:
		spell_id = item_to_spell[item_id]
		spell_level = 0
		if spell_id in spell_to_level:
			spell_level = spell_to_level[spell_id]
		if spell_id in spell_to_name:
			spell_name = spell_to_name[spell_id]
		if spell_id in spell_to_item_class:
			spell_class = spell_to_item_class[spell_id]
			print(data_format.format(spell_id, item_id, spell_name))
print("}")
