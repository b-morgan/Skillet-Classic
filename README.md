# Skillet-Classic
World of Warcraft addon. Skillet-Classic is a replacement for the default TradeSkill (and Crafting/Enchanting) UI.
<p>To report bugs and request new features check:&nbsp;<a href="https://www.curseforge.com/wow/addons/skillet-classic/issues">https://www.curseforge.com/wow/addons/skillet-classic/issues</a><br/>
To help with Localization see:&nbsp;<a href="https://www.curseforge.com/wow/addons/skillet-classic/localization">https://www.curseforge.com/wow/addons/skillet-classic/localization</a></p>
<p><strong>Other than "Please open an issue" I won't be responding to bug reports in comments.</strong></p>
<h3><strong>Features:</strong></h3>
<ul>
<li>Larger the the standard tradeskill window</li>
<li>Built-in queue for creating multiple, different items</li>
<li>Queued items are saved when you log out and are restored on log in</li>
<li>Automatically buy reagents for queued recipes when visiting a vendor</li>
<li>If you can craft a reagent needed by a recipe, then clicking on that reagent will take you to its recipe (same features as <em>Reverse Engineering</em>)</li>
<li>If the item to be crafted requires a minimum level to use, that level can be displayed along with the recipe (disabled by default)</li>
<li>The shopping list of items needed for all queued recipes for all alts can be displayed at banks, auction houses, or from the command line</li>
<li>Items needed for crafting queued items can be automatically retrieved from your bank or guild bank (by using the shopping list)</li>
<li>User editable list of notes attached to reagents and crafted items</li>
<li>Queued counts added to (optional) notes display</li>
<li>Crafted counts can be adjusted with Right-click and Shift-right-click on the item icon in the detail frame</li>
<li>Recipes can be filtered by name, whether or not you could level when creating the item, and whether or not you have the mats available</li>
<li>Sorting of recipes (name, difficulty, level, and quality of crafted item)</li>
<li>Tracking inventory on alternate characters</li>
<li>Plugin support for (limited) modification of the Skillet frame by other addons</li>
<li>Custom grouping</li>
<li>User managed Ignored Materials List</li>
<li>Complete or mostly complete localizations for deDE, esES, frFR, ruRU, koKR, zhCN, zhTW</li>
</ul>
<h3><strong>Compatibility:</strong></h3>
<ul>
<li><strong>TradeSkillMaster</strong></li>
<ul>
<li>Skillet-Classic can be used with TSM for all professions except Enchanting</li>
<li>If the TSM Crafting UI is set to native ('TSM4') mode</li>
<li>Note: Skillet frames have strata and background changes in this mode</li>
<li>For Enchanting, use the TSM Crafting UI or disable TSM </li>
</ul>
</ul>
<h3><strong>FAQ:</strong></h3>
<ul>
<li><strong>What are the numbers in the middle and how to hide them?</strong> - Right-click on the bag icon above the numbers.</li>
<ul>
<li>Blue = How many you have</li>
<li>Green = How many you can make from materials you have</li>
<li>Yellow = How many you can make by crafting the reagents</li>
<li>Orange = How many you can make if you purchase materials from a vendor</li>
<li>Purple = How many you can make using materials on your alts</li>
</ul>
<li><strong>How to search in the item name only?</strong> - Start your search phrase with exclamation mark: !ink</li>
<li><strong>How to search in Auction House?</strong> - Alt+Click on shopping list</li>
<li><strong>How to retrieve items from bank?</strong> - Turn on "Display shopping list at banks"</li>
<li><strong>How to turn off Skillet temporarily?</strong> - Shift+Click your profession button/link</li>
<li><strong>How to paste a recipe in the chat?</strong> - double click on the recipe list</li>
</ul>
<h3><strong>Changes:</strong></h3>
<ul>
<li><strong>1.20</strong></li>
<ul>
<li>BigWigsMod packager version of 1.19 (with potentially newer libraries)</li>
</ul>
<li><strong>1.19</strong></li>
<ul>
<li>Fix SkilletQueue lua error</li>
<li>Update .toc for addon managers</li>
</ul>
<li><strong>1.18</strong></li>
<ul>
<li>Add option to queue Enchant reagents</li>
<li>Change TradeSkillMaster global</li>
<li>Update TradeSkillMaster compatibility</li>
</ul>
<li><strong>1.17</strong></li>
<ul>
<li>Add linking of reagents</li>
</ul>
<li><strong>1.16</strong></li>
<ul>
<li>Add "/skillet flushplayerdata" command</li>
</ul>
<li><strong>1.15</strong></li>
<ul>
<li>Fix various issues</li>
<li>Update Localization</li>
</ul>
<li><strong>1.14</strong></li>
<ul>
<li>Fix various issues</li>
<li>Add options for profession buttons</li>
<li>Add AuctionLite plugin</li>
</ul>
<li><strong>1.13</strong></li>
<ul>
<li>Fix Enchanting reagent mouseover</li>
<li>Fix Auctionator plugin references(when there is no Auctionator addon)</li>
</ul>
<li><strong>1.12</strong></li>
<ul>
<li>Update .toc</li>
<li>Update Auctionator plugin (common source with Skillet)</li>
<li>Add additional Tooltip scaling</li>
</ul>
<li><strong>1.11</strong></li>
<ul>
<li>Fix normal bag detection</li>
<li>Add Auction House debugging</li>
</ul>
<li><strong>1.10</strong></li>
<ul>
<li>Fix notes</li>
</ul>
<li><strong>1.09</strong></li>
<ul>
<li>Fix Enchant button</li>
<li>Fix Trade Barker</li>
</ul>
<li><strong>1.08</strong></li>
<ul>
<li>Update TOC</li>
<li>Add new plugins (AuctionDB, Auctioneer)</li>
<li>Add plugin identifier to plugin output</li>
<li>Fix required tools display</li>
</ul>
<li><strong>1.07</strong></li>
<ul>
<li>Fix MissingTradeSkillsList button moving</li>
<li>Fix Auctionator buttons</li>
<li>Move all CastSpellByName calls into Skillet.lua</li>
<li>Fix Beast Training interference</li>
</ul>
<li><strong>1.06</strong></li>
<ul>
<li>Fix Filter dropdown not initialized</li>
</ul>
<li><strong>1.05</strong></li>
<ul>
<li>Fix multiple issues</li>
</ul>
<li><strong>1.04</strong></li>
<ul>
<li>Minor bug fixes</li>
</ul>
<li><strong>1.03</strong></li>
<ul>
<li>Add Auctionator button to Shopping List</li>
<li>Close Shopping List when Merchant window is closed</li>
</ul>
<li><strong>1.02</strong></li>
<ul>
<li>Fix multiple issues</li>
</ul>
<li><strong>1.01</strong></li>
<ul>
<li>Fix to prevent queuing Enchanting items</li>
<li>Open Blizzard UI when in combat (Skillet-Classic would open with errors or fail to open)</li>
</ul>
<li><strong>1.00</strong></li>
<ul>
<li>Initial Release</li>
</ul>
</ul>
</ul>
