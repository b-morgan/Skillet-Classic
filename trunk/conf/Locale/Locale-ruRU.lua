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

-- Translated by StingerSoft
local L = LibStub("AceLocale-3.0"):NewLocale("Skillet", "ruRU")
if not L then return end

L["About"] = "О Skillet"
L["ABOUTDESC"] = "Информация о Skillet"
L["alts"] = "альты"
L["Appearance"] = "Внешний вид"
L["APPEARANCEDESC"] = "Настройки внешнего вида."
L["bank"] = "банк"
L["Blizzard"] = "Blizzard"
L["buyable"] = "покупаемые"
L["Buy Reagents"] = "Купить реагенты"
L["By Difficulty"] = "По сложности"
L["By Item Level"] = "По уровню предмета"
L["By Level"] = "По уровню"
L["By Name"] = "По имени"
L["By Quality"] = "По качеству"
L["By Skill Level"] = "По уровню умения"
L["can be created by crafting reagents"] = "can be created by crafting reagents" -- Requires localization
L["can be created from reagents in your inventory"] = "может быть создан из реагентов в вашем инвентаре"
L["can be created from reagents in your inventory and bank"] = "может быть создан из реагентов в вашем инвентаре и банке"
L["can be created from reagents on all characters"] = "может быть создан из реагентов на всех ваших чарах"
L["Clear"] = "Очистить"
L["click here to add a note"] = "Кликни чтобы добавить заметку"
L["Collapse all groups"] = "Свернуть все группы"
L["Config"] = "Настройки"
L["CONFIGDESC"] = "Открыть окно настроек для Skillet"
L["Could not find bag space for"] = "Нет места в сумках для"
L["craftable"] = "создаваемый"
L["Crafted By"] = "Изготовлено"
L["Create"] = "Создать"
L["Create All"] = "Создать Все"
L[" days"] = " дней"
L["Delete"] = "Удалить"
L["DISPLAYREQUIREDLEVELDESC"] = "Если предмет для создания требует определённый уровень умения, то этот уровень будет отображаться вместе с рецептом."
L["DISPLAYREQUIREDLEVELNAME"] = "Показывать требуемый уровень"
L["DISPLAYSGOPPINGLISTATAUCTIONDESC"] = "Показывать список закупок предметов, которых у вас нет, нужных для создания рецептов."
L["DISPLAYSGOPPINGLISTATAUCTIONNAME"] = "Показывать список закупок на аукционе"
L["DISPLAYSHOPPINGLISTATBANKDESC"] = "Показывать список закупок предметов, которых у вас нет, нужных для создания рецептов."
L["DISPLAYSHOPPINGLISTATBANKNAME"] = "Показывать список закупок в банке"
L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"] = "Показывать список закупок предметов, которых у вас нет, нужных для создания рецептов."
L["DISPLAYSHOPPINGLISTATGUILDBANKNAME"] = "Показать список закупок в банке гильдии"
L["Draenor Engineering"] = "Дренорское инженерное дело" -- Needs review
L["Enabled"] = "Включено"
L["Enchant"] = "Зачаровать"
L["ENHANCHEDRECIPEDISPLAYDESC"] = "Если включено, то к названию рецепта будет добавлен один или несколько символов '+', указывая на сложность рецепта."
L["ENHANCHEDRECIPEDISPLAYNAME"] = "Отображать сложность рецепта текстом"
L["Expand all groups"] = "Развернуть все группы"
L["Features"] = "Cвойства"
L["FEATURESDESC"] = "Необязательные свойства которые могут быть включены или выключены"
L["Filter"] = "Фильтр"
L["Flush All Data"] = "Сбросить все данные" -- Needs review
L["FLUSHALLDATADESC"] = "Сбросить все данные Skillet" -- Needs review
L["Flush Recipe Data"] = "Сбросить данные рецептов" -- Needs review
L["FLUSHRECIPEDATADESC"] = "Сбросить данные рецептов Skillet" -- Needs review
L["Glyph "] = "Символ "
L["Gold earned"] = "Получено Золота"
L["Grouping"] = "Группировка"
L["has cooldown of"] = "имеет время восстановления" -- Needs review
L["have"] = "есть"
L["Hide trivial"] = "Скрыть низкоуровневые"
L["Hide uncraftable"] = "Скрыть не создаваемые"
L["IGNORECLEARDESC"] = "Удалить всё из списка игнорируемых материалов." -- Needs review
L["Ignored Materials Clear"] = "Очистить игнорируемые материалы" -- Needs review
L["Ignored Materials List"] = "Список игнорируемых материалов" -- Needs review
L["IGNORELISTDESC"] = "Открыть список игнорируемых материалов." -- Needs review
L["Illusions"] = "Illusions" -- Requires localization
L["Include alts"] = "Включать альтов"
L["Include bank"] = "Включая банк" -- Needs review
L["Include guild"] = "Включая гильдию" -- Needs review
L["Inventory"] = "Инвентарь"
L["INVENTORYDESC"] = "Информация инвентаря"
L["is now disabled"] = " теперь отключен"
L["is now enabled"] = " теперь включен"
L["Library"] = "Библиотека"
L["LINKCRAFTABLEREAGENTSDESC"] = "Если вы можете создать реагент, необходимый для текущего рецепта, кликнув по реагенту вы перейдёте на его рецепт."
L["LINKCRAFTABLEREAGENTSNAME"] = "Сделать реагенты кликабельными"
L["Load"] = "Загруз."
L["Merge items"] = "Объединить предметы" -- Needs review
L["Move Down"] = "Преместить на позицию ниже"
L["Move to Bottom"] = "Переместить в конец очереди"
L["Move to Top"] = "Переместить в начало очереди"
L["Move Up"] = "Преместить на позицию выше"
L["need"] = "нужно"
L["No Data"] = "Нет данных"
L["None"] = "Нет"
L["No such queue saved"] = "Нет такой сохраненной очереди"
L["Notes"] = "Заметки"
L["not yet cached"] = "еще не скеширавано"
L["Number of items to queue/create"] = "Число вещей в очереди/создается"
L["Options"] = "Опции"
L["Order by item"] = "Сортировать по предметам" -- Needs review
L["Pause"] = "Пауза"
L["Process"] = "Продолжить"
L["Purchased"] = "Покупаемые"
L["Queue"] = "В очередь"
L["Queue All"] = "Всё в очередь"
L["QUEUECRAFTABLEREAGENTSDESC"] = "Если вы можете создать реагент, необходимый для создания рецепта, то при его отсутствии, он будет добавлен в очередь"
L["QUEUECRAFTABLEREAGENTSNAME"] = "В очередь реагенты"
L["QUEUEGLYPHREAGENTSDESC"] = "Если вы можете создать реагент, необходимый для создания рецепта, то при его отсутствии, он будет добавлен в очередь (эта опция относится только к Символам)."
L["QUEUEGLYPHREAGENTSNAME"] = "В очередь реагенты для Символов"
L["Queue is empty"] = "Очередь пуста"
L["Queue is not empty. Overwrite?"] = "Очередь не пуста. Переписать?"
L["Queues"] = "Очереди"
L["Queue with this name already exsists. Overwrite?"] = "Очередь с таким именем уже сужествует. Переписать?"
L["Reagents"] = "Реагенты"
L["reagents in inventory"] = "реагенты в инвентаре"
L["Really delete this queue?"] = "Вы действительно хотите удалить эту очередь?"
L["Rescan"] = "Обновить"
L["Reset"] = "Сброс"
L["RESETDESC"] = "Сброс позиции окна Skillet"
L["Retrieve"] = "Отыскивать"
L["Save"] = "Сохр."
L["Scale"] = "Масштаб"
L["SCALEDESC"] = "Масштаб окна профессий (по умолчанию 1.0)"
L["Scan completed"] = "Скан окончен"
L["Scanning tradeskill"] = "Сканирование профессии"
L["Selected Addon"] = "Выбранные модификации"
L["Select skill difficulty threshold"] = "Выберите порог сложности навыка"
L["Sells for "] = "Продается за "
L["Shopping Clear"] = "Очистка покупок" -- Needs review
L["SHOPPINGCLEARDESC"] = "Очистить лист покупок" -- Needs review
L["Shopping List"] = "Список закупок"
L["SHOPPINGLISTDESC"] = "Открыть список закупок"
L["SHOWBANKALTCOUNTSDESC"] = "Когда подсчитывается и отображается число создаваемых предметов, в подсчет предметов включается содержимое банка и инвентаря других ваших персонажей."
L["SHOWBANKALTCOUNTSNAME"] = "Включая содержимое банка и инвентаря альтов"
L["SHOWCRAFTCOUNTSDESC"] = "Показывать сколько раз вы можете создать вещь, а не общее число производимых предметов"
L["SHOWCRAFTCOUNTSNAME"] = "Отображать число создаваемого"
L["SHOWCRAFTERSTOOLTIPDESC"] = "Показывать в подсказке предмета, альта который может его создать"
L["SHOWCRAFTERSTOOLTIPNAME"] = "Умеющий персонаж в подсказке"
L["SHOWDETAILEDRECIPETOOLTIPDESC"] = "Отображать детальную подсказку при наведении курсора мыши на рецепт в левой части окна"
L["SHOWDETAILEDRECIPETOOLTIPNAME"] = "Показывать детальную подсказку для рецептов"
L["SHOWFULLTOOLTIPDESC"] = "Показать всю информацию о создаваемом предмете. Если вы отключите это, то вы будете видеть только сжатую подсказку (чтобы просмотреть полную подсказку, удерживайте Ctrl)"
L["SHOWFULLTOOLTIPNAME"] = "Исп. стандартную подсказку"
L["SHOWITEMNOTESTOOLTIPDESC"] = "Добавляет заметки которые вы написали в подсказку данного предмета"
L["SHOWITEMNOTESTOOLTIPNAME"] = "Добавить заметки в подсказку"
L["SHOWITEMTOOLTIPDESC"] = "Отображать подсказку создаваемого предмета, вместо подсказки рецепта."
L["SHOWITEMTOOLTIPNAME"] = "При возможности показывать подсказку предмета"
L["Skillet Trade Skills"] = "Skillet Trade Skills"
L["Skipping"] = "пропускаю"
L["Sold amount"] = "Число продаж"
L["SORTASC"] = "Сортировать список рецептов по порядку"
L["SORTDESC"] = "Сортировать список рецептов в обратном порядке"
L["Sorting"] = "Сортировать"
L["Source:"] = "Источник:"
L["STANDBYDESC"] = "Включить/отключить режим ожидания"
L["STANDBYNAME"] = "ожидание"
L["Start"] = "Начать"
L["Supported Addons"] = "Поддерживаемые модификации"
L["SUPPORTEDADDONSDESC"] = "Поддерживаемые модификации которые могут/уже используются для отслеживания инвентаря"
L["This merchant sells reagents you need!"] = "Этот торговец продает нужные реагенты!"
L["Total Cost:"] = "Общая цена:"
L["Total spent"] = "Всего затрат"
L["Trained"] = "Изучено"
L["TRANSPARAENCYDESC"] = "Прозрачность главного окна профессий"
L["Transparency"] = "Прозрачность"
L["Unknown"] = "Неизвестен"
L["USEBLIZZARDFORFOLLOWERSDESC"] = "Use the Blizzard UI for garrison follower tradeskills" -- Requires localization
L["USEBLIZZARDFORFOLLOWERSNAME"] = "Использовать для соратников интерфейс Blizzard" -- Needs review
L["Using Bank for"] = "Используя банк" -- Needs review
L["Using Reagent Bank for"] = "Используя банк реагентов" -- Needs review
L["VENDORAUTOBUYDESC"] = "Если у вас в очереди есть рецепт/вещи, то во время разговора с торговцем, который продаёт что-нибудь нужное для вашего рецепта, оно будет куплено автоматически." -- Needs review
L["VENDORAUTOBUYNAME"] = "Автоматически купить реагенты"
L["VENDORBUYBUTTONDESC"] = "Отображать кнопку при разговоре с торговцем, это позволит вам осмотреть все нужные реагенты для всех ваших рецептах в очереди."
L["VENDORBUYBUTTONNAME"] = "Кнопка покупок реагентов у торговца"
L["View Crafters"] = "Посмотреть мастеров"

