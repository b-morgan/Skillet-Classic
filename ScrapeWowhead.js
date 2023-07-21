/*
======== Instructions ========
1) Go to a profession recipe page. Example: https://wotlk.wowhead.com/alchemy#recipes
2) Open inspector
3) Go to console tab
4) Paste the following code
*/

// [Paste]
recipes = {}; // spellID => skill_levels
counter = {}; // just keep track of keys

is_enchanting = (document.location.pathname == '/enchanting');
is_alchemy    = (document.location.pathname == '/alchemy');

function get_skill_levels() {
    $('#tab-recipes .listview-row').each(function(i, row){
        // Is always the item link except for enchants where it is also the spell
        var $first_link  = $(row).find('td:first-child a');
        // Is always the spell link for all professions
        var $second_link = $(row).find('td:nth-child(2) a');

        var spellID = $second_link[0].href.match(/spell=[0-9]*/)[0].split('=')[1];
        var itemID  = 0; // placeholder for enchanting

        // Skip basic campfire, not a real recipe
        if (spellID == 818) { return; }
        
        if (!is_enchanting) {
            itemID = $first_link[0].href.match(/item=[0-9]*/)[0].split('=')[1];
        }
        // Make the ids integers
        spellID = +spellID;
        itemID  = +itemID;

        var $td_div = $(row).find('td:last-child div');
        // if it doesn't have skill level information, skip it, its an invalid recipe
        if ($td_div.length == 1) {
            console.log('skipping spellID: ' + spellID + ' - ' + $second_link.text());
            return; // next in loop
        }
        var arr = [];
        $td_div.last().find('span').each(function(j, span){
            arr.push($(span).text());
        });

        // ---- recipe manual fixes ----
        if (is_alchemy && arr.length == 3) {
          // These alchemy recipes are discoveries from other outland recipes
          // all outland recipes are 300 minimum skill, so these must ALSO be 300 minimum.
          // NOTE: also Gurubashi Mojo Madness also requires 300 to learn in ZG
          var level = 300;
          // cauldrons are 360 minimum to match the protection pots
          if ($first_link[0].href.indexOf('cauldron') != -1) { level = 360; }
          arr.unshift(level);
        }
        /*
        Manual fixes for some starter recipes that Wowhead does not have complete data for.
        These can be removed if wowhead ever uploads corrected data.
        Affected recipes:
          Charred Wolf Meat (2538)
          Roasted Boar Meat (2657)
          Smelt Copper (2540)
          Crafted Light Shot (3920)
          Delicate Copper Wire (25255)
          Rough Stone Statue (32259)
          Braided Copper Ring (25493)
          Woven Copper Ring (26925)
          Enchant Bracer Minor Health (7418)
          Enchant Bracer Minor Deflection (7428)
        */
        if (arr.length == 3 && [2538, 2657, 2540, 3920, 25255, 32259, 25493, 26925, 7418, 7428].includes(spellID)) {
            arr.unshift(1);
        }
        // ---- ----

        if (arr.length < 4) {
          // prefill the array with duplicates of the first value
          // TODO: debug printout that we're padding this spell?
          arr = Array(4 - arr.length).fill(arr[0]).concat(arr);
        }

        recipes[itemID] = recipes[itemID] || {}; // Maybe init
        recipes[itemID][spellID] = arr;
        // REM: all enchanting will be shoved under itemID(0)

        counter[spellID] = 1; // Keep track of how many valid recipes we've found
    });
    console.log('number recipes: ' + Object.keys(counter).length);
}
function print_skill_levels() {
    var arr = [];

    if (is_enchanting) {
        recipes = recipes[0]; // bust out of the placeholder itemID
        $.each(recipes, function(spellID, val){
            // [-spellID] = "A/B/C/D",  (enchanting only)
            arr.push('[-' + spellID + '] = "' + val.join('/') + '"');
        });
    } else {
        $.each(recipes, function(itemID, spells){
            if (Object.keys(spells).length == 1) { // 99% of cases
                var val = Object.values(spells)[0];
                // Don't use a nested table when only one spell per item
                // [itemID] = "A/B/C/D",
                arr.push('[' + itemID + '] = "' + val.join('/') + '"');
                return;
            }
            // [itemID] = { [spellID] = "A/B/C/D", [spellID] = "A/B/C/D" },
            var inner = [];
            $.each(spells, function(spellID, val){
                inner.push('[' + spellID + '] = "' + val.join('/') + '"');
            });
            arr.push('[' + itemID + '] = {' + inner.join(', ') + '}');
        });
    }
    arr.push(''); // Pad the end so we have a comma on every line
    console.log(arr.join(',\n'));
}

function main_loop() {
    get_skill_levels();

    var $next = $('#tab-recipes .listview-band-top .listview-nav > a').eq(3);
    // REM: .data() does not necessarily update correctly
    //      always use attr()
    if ($next.attr('data-active') == 'no') {
        print_skill_levels();
        return;
    }
    $next.click();
    setTimeout(main_loop, 250); // Wait a moment to give it plenty of time to load
}

// [/paste]

/*
5) Run function: "main_loop()"
6) Copy paste output into lua file SkillLevelData.lua replacing relevant tradeskill section
7) Startover from step 1 on the next profession page (excluding herbalism, skinning, fishing obviously)
*/
