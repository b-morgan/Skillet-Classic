/*
======== Instructions ========
1) Go to a profession recipe page. Example: https://tbc.wowhead.com/alchemy#recipes
2) Open inspector
3) Go to console tab
4) Paste the following code
*/
recipes = {};
// Run this loop once on each page of results. Then repeat again for the next profession.
function get_skill_levels() {
    $('#tab-recipes .listview-row').each(function(i, row){
        var $a = $(row).find('td:first-child a');
        // Most are items, but enchants are spells
        var item_id = $a[0].href.match(/(item|spell)=[0-9]*/)[0].split('=')[1];

        var $td_div = $(row).find('td:last-child div');
        // if it doesn't have skill level information, skip it, its an invalid recipe
        if ($td_div.length == 1) {
            console.log('skipping: ' + item_id + ' - ' + $(row).find('td:nth-child(2) a').text());
            return;
        }
        var arr = [];
        $td_div.last().find('span').each(function(j, span){
            arr.push($(span).text());
        });
        //console.log(item_id + ' - ' + $a.text() + ' - ' + arr.toString());
        recipes[item_id] = arr;
    });
    console.log('Recipes.length: ' + Object.keys(recipes).length);
}
function print_skill_levels() {
    var arr = [];
    $.each(recipes, function(id, val){
        if (val.length < 4) {
          // prefill the array with duplicates of the first value
          val = Array(4 - val.length).fill(val[0]).concat(val);
        }
        arr.push('[' + id + '] = "' + val.join('/') + '"');
    });
    arr.push(''); // Pad the end so we have a comma on every line
    console.log(arr.join(',\n'));
}
/*
5) Run function: "get_skill_levels()"
6) Hit next page link to load the next 50 recipes
7) Repeat step 5 and 6 until all recipes have been read
8) Run function: "print_skill_levels()"
9) Copy paste output into lua file SkillLevelData.lua replacing relevant tradeskill section
10) Startover from step 1 on the next profession page (excluding herbalism, skinning, fishing obviously)
*/
