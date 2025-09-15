#!/usr/bin/python3
# Inspired by:
# https://github.com/Auctionator/Auctionator/blob/master/DB2_Scripts/convert-enchant-spell-to-enchant-classic.py
#
# This script converts the csv output from: 
# https://wago.tools/db2/Item 
# https://wago.tools/db2/ItemEffect (Classic, row['ParentItemID'])
# https://wago.tools/db2/ItemXItemEffect (Retail only)
# https://wago.tools/db2/SpellName
#
# to get a mapping of the enchant spell id to the enchant item 
# (for searching the AH for the enchant or
# calculation crafting profit), and spell level/equipped slot (for the vellum
# needed for crafting cost/profit)
#
# One command line argument of the form "5.5.0.62258" is added to the .csv file name(s)
#
import csv
import sys
import os

#
# Initialize the data storage
#
if len(sys.argv) < 2:
	print("Usage:")
	exit()
else:
	build = sys.argv[1]

enchants_only = {}
with open('Item.'+build+'.csv', newline='') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		if row['ClassID'] == '0' and row['SubclassID'] == '6':
			enchants_only[int(row['ID'])] = True

item_to_spell = {}
with open('ItemEffect.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		item_to_spell[int(row['ParentItemID'])] = int(row['SpellID'])

spell_to_name = {}
with open('SpellName.'+build+'.csv') as f:
	reader = csv.DictReader(f, delimiter=',')
	for row in reader:
		spell_to_name[int(row['ID'])] = row['Name_lang']

data_format = """\
    [{}] = {}, -- {}\
"""

o = open('scrollData.'+build+'.lua', "w")
o.write("-- " + build + "\n")
o.write("Skillet.scrollData = {\n")
for item_id in enchants_only:
	if item_id in item_to_spell:
		spell_id = item_to_spell[item_id]
		if spell_id in spell_to_name:
			spell_name = spell_to_name[spell_id]
			o.write(data_format.format(spell_id, item_id, spell_name) + "\n")
o.write("}\n")
o.close()
