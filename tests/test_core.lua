-- Headless tests for spells_core.lua. No framework, no fixture files: the module is pure, so the whole suite is a
-- handful of tables plus a counter. Run with `luajit test_core.lua`; the last line is the verdict and a non-zero exit
-- means it failed.
--
-- The fixtures are spelled out here on purpose: spells_data.lua is frozen but spell_sources.lua is generated, and a
-- test that leans on the generator would change shape every time the generator does. These are the smallest tables
-- that exercise every rule in the contract - two modes that hide different things, one spell with no source at all,
-- one spell that no job can learn at the cap.
local here = (arg and arg[0] or ''):match('^(.*)[/\\][^/\\]*$') or '.'
local CORE = here .. '/../spells_core.lua'
local C = assert(loadfile(CORE))()

local checks, failures = 0, 0

local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        print(string.format('FAIL %s', label))
        print(string.format('     got:  %s', tostring(got)))
        print(string.format('     want: %s', tostring(want)))
    end
end

local function names(rows)
    local t = {}
    for i = 1, #rows do t[i] = rows[i].name end
    return table.concat(t, ' | ')
end

-- data: mirrors spells_data.lua's shape and its three modes closely enough that a mode rule broken here is broken
-- there. Every tag carries a note, because badge() reads notes, never labels.
local DATA = {
    level_cap = 75,
    skip_types = { trust = true },
    tags = {
        wizardoll = { label = 'Wizardoll', icon = 'hat-wizard', note = 'ACE: learnt from the Wizardoll NPC' },
        shop = { label = 'Shop', icon = 'store', note = 'sold by an NPC vendor' },
        ah = { label = 'AH', icon = 'coins', note = 'listed on the Auction House' },
        drop = { label = 'Drop', icon = 'box-open', note = 'dropped by a monster' },
        quest = { label = 'Quest', icon = 'scroll', note = 'a quest reward' },
        bcnm = { label = 'BCNM', icon = 'dice', note = 'a battlefield reward' },
        sots = { label = 'Summit', icon = 'star', note = 'Summit of the Stars reward' },
        learn = { label = 'Learn', icon = 'flask', note = 'learnt by fighting the monster that casts it' },
        self = { label = 'Self-found', icon = 'compass', note = 'no AH or Wizardoll path in this mode' },
        none = { label = 'Not at 75', icon = 'ban', note = 'no job learns this at the level 75 cap' },
        unknown = { label = 'No source', icon = 'question', note = 'no acquisition source is recorded' },
    },
    modes = {
        { id = 'ace', label = 'ACE', tags = { 'wizardoll', 'shop', 'ah', 'drop', 'quest', 'bcnm' },
          hide = {}, fallback = 'unknown', src = 'bg-wiki CatsEyeXI_Content/Accelerated' },
        { id = 'cw', label = 'CW', tags = { 'shop', 'drop', 'quest', 'bcnm' },
          hide = { 'wizardoll', 'ah' }, fallback = 'self', src = 'bg-wiki CatsEyeXI_Content/Crystal_Warrior' },
        { id = 'wew', label = 'WEW', tags = { 'shop', 'ah', 'drop', 'quest', 'bcnm' },
          hide = { 'wizardoll' }, fallback = 'unknown', src = 'bg-wiki CatsEyeXI_Content/Wings_Era_Warrior' },
    },
    skills = {
        { id = 'white', label = 'White', types = { 'white' } },
        { id = 'black', label = 'Black', types = { 'black' } },
        { id = 'ninjutsu', label = 'Ninjutsu', types = { 'ninjutsu' } },
    },
}

local SPELLS = {
    { id = 1,  name = 'Cure',            type = 'white',    skill_name = 'healing_magic',   mp = 8,   element = 'light', jobs = { [3] = 1, [5] = 3, [7] = 5 } },
    { id = 2,  name = 'Cure II',         type = 'white',    skill_name = 'healing_magic',   mp = 24,  element = 'light', jobs = { [3] = 11, [5] = 17 } },
    { id = 3,  name = 'Cure III',        type = 'white',    skill_name = 'healing_magic',   mp = 46,  element = 'light', jobs = { [3] = 21, [5] = 33 } },
    { id = 4,  name = 'Cure IV',         type = 'white',    skill_name = 'healing_magic',   mp = 88,  element = 'light', jobs = { [3] = 41, [7] = 51 } },
    { id = 5,  name = 'Haste',           type = 'white',    skill_name = 'enhancing_magic', mp = 40,  element = 'wind',  jobs = { [3] = 40, [5] = 48 } },
    { id = 6,  name = 'Fire',            type = 'black',    skill_name = 'elemental_magic', mp = 5,   element = 'fire',  jobs = { [4] = 1, [5] = 4 } },
    { id = 7,  name = 'Fire II',         type = 'black',    skill_name = 'elemental_magic', mp = 24,  element = 'fire',  jobs = { [4] = 17, [5] = 21 } },
    { id = 8,  name = 'Utsusemi: Ichi',  type = 'ninjutsu', skill_name = 'ninjutsu',        mp = 12,  element = 'none',  jobs = { [13] = 12, [5] = 37 } },
    { id = 9,  name = 'Meteor',          type = 'black',    skill_name = 'elemental_magic', mp = 300, element = 'fire',  jobs = { [4] = 90 } },
    { id = 10, name = 'Tornado',         type = 'black',    skill_name = 'elemental_magic', mp = 200, element = 'wind',  jobs = { [4] = 75 } },
    { id = 11, name = 'Cure V',          type = 'white',    skill_name = 'healing_magic',   mp = 120, element = 'light', jobs = { [3] = 86, [7] = 90 } },
    { id = 12, name = 'Kupipi',          type = 'trust',    skill_name = 'summoning',       mp = 0,   element = 'light', jobs = { [3] = 1 } },
}

-- sources: only two spells have a scroll page, one with two paths, one AH-only. The rest are the "no source recorded"
-- case the badge has to handle without inventing anything.
local SOURCES = {
    [1] = { tag = 'shop', tags = { 'shop', 'ah' }, note = 'sold by the curing NPC in Windurst', src = 'bg-wiki Scroll_of_Cure' },
    [4] = { tag = 'ah',   tags = { 'ah' },         note = 'Auction House only',                src = 'bg-wiki Scroll_of_Cure_IV' },
    -- a page that was read but whose tables gave no usable path: the one case where the ACE Sparks route is the only
    -- badge left
    [2] = { tag = nil,    tags = {},               note = '',                                  src = 'bg-wiki Scroll_of_Cure_II' },
}

-- the game's 128-byte bitfield, built by hand so the suite does not need vana.game.spells()
local function bits_with(ids)
    local t = {}
    for i = 1, 128 do t[i] = 0 end
    for _, id in ipairs(ids) do
        local byte = math.floor(id / 8)
        t[byte + 1] = t[byte + 1] + 2 ^ (id % 8)
    end
    local out = {}
    for i = 1, 128 do out[i] = string.char(t[i]) end
    return table.concat(out)
end

local function find(rows, name)
    for i = 1, #rows do
        if rows[i].name == name then return rows[i] end
    end
    return nil
end

-- 1. has_bit -------------------------------------------------------------------------------------------------------
local bits = bits_with({ 3, 64 })
eq(C.has_bit(bits, 3), true, 'has_bit: set bit low')
eq(C.has_bit(bits, 4), false, 'has_bit: clear bit next to a set one')
eq(C.has_bit(bits, 64), true, 'has_bit: set bit on a byte boundary')
eq(C.has_bit(nil, 3), false, 'has_bit: nil bits reads false')
eq(C.has_bit(bits, 200), false, 'has_bit: past the end of the string reads false')

-- 2. level_for -----------------------------------------------------------------------------------------------------
eq(C.level_for(SPELLS[2], 3), 11, 'level_for: known job gives its level')
eq(C.level_for(SPELLS[2], 1), nil, 'level_for: unknown job gives nil')

-- 3. castable ------------------------------------------------------------------------------------------------------
eq(C.castable(SPELLS[3], { job = 3, level = 21 }), true, 'castable: main job exactly at level')
eq(C.castable(SPELLS[3], { job = 3, level = 20 }), false, 'castable: main job one below level')
eq(C.castable(SPELLS[2], { job = 13, level = 10, sub_job = 5, sub_level = 34 }), true,
   'castable: subjob at exactly half its level')
eq(C.castable(SPELLS[2], { job = 13, level = 10, sub_job = 5, sub_level = 33 }), false,
   'castable: subjob one below half its level')
eq(C.castable(SPELLS[1], { job = 1, level = 75 }), false, 'castable: job that learns nothing is never castable')

-- 4. rows: a WHM-40 ------------------------------------------------------------------------------------------------
local whm40 = { job = 3, level = 40 }
local three = { SPELLS[1], SPELLS[3], SPELLS[4] }
local known = bits_with({ 1, 3 }) -- Cure and Cure III already learnt
local hidden = C.rows(three, {
    job = whm40.job, level = whm40.level, bits = known, data = DATA, sources = SOURCES,
})
eq(names(hidden), 'Cure IV', 'rows: learned spells excluded by default')
local shown = C.rows(three, {
    job = 3, level = 40, bits = known, data = DATA, sources = SOURCES, show_learned = true,
})
eq(names(shown), 'Cure | Cure III | Cure IV', 'rows: show_learned returns the full list, sorted by level')
eq(find(shown, 'Cure IV').level, 41, 'rows: row level is the main job requirement')
eq(find(shown, 'Cure IV').via, 'main', 'rows: via is main when the main job learns it')
eq(find(shown, 'Cure').short_job, 'WHM', 'rows: short_job names the job whose level is shown')

-- the subjob path: a NIN-10 with a RDM-34 sub can cast Cure II (RDM 17 <= 34/2), and the level shown has to be the
-- subjob's own requirement (17), not the half level the player is treated as
local sub_rows = C.rows({ SPELLS[2] }, {
    job = 13, level = 10, sub_job = 5, sub_level = 34, data = DATA, sources = SOURCES,
})
eq(sub_rows[1].via, 'sub', 'rows: via is sub when only the subjob learns the spell')
eq(sub_rows[1].level, 17, 'rows: subjob rows show the subjob requirement, not sub_level/2')
eq(sub_rows[1].short_job, 'RDM', 'rows: subjob rows name the subjob')
eq(sub_rows[1].castable, true, 'rows: the subjob path marks the row castable')

-- 5. rows: a job that learns nothing -------------------------------------------------------------------------------
local none = C.rows(SPELLS, { job = 1, level = 75, data = DATA, sources = SOURCES })
eq(type(none), 'table', 'rows: unknown job still returns a table')
eq(#none, 0, 'rows: job that learns nothing yields no rows')
eq(#C.rows(SPELLS, { job = 0, level = 0, data = DATA, sources = SOURCES }), 0,
   'rows: main_job 0 (no job yet) yields no rows instead of erroring')

-- 6. query ---------------------------------------------------------------------------------------------------------
local q = C.rows(SPELLS, { job = 3, level = 60, data = DATA, sources = SOURCES, query = '  IV   cure ', show_learned = true })
eq(names(q), 'Cure IV', 'query: two words in any order and any case')
eq(#C.rows(SPELLS, { job = 3, level = 60, data = DATA, sources = SOURCES, query = 'raise', show_learned = true }), 0,
   'query: no match yields nothing')
eq(#C.rows(SPELLS, { job = 3, level = 60, data = DATA, sources = SOURCES, query = 'cure', show_learned = true }), 5,
   'query: one word matches every name containing it')

-- 7. skill pills ---------------------------------------------------------------------------------------------------
local blm = { job = 4, level = 40, data = DATA, sources = SOURCES }
local black = C.rows(SPELLS, { job = blm.job, level = blm.level, data = DATA, sources = SOURCES, skill = 'black' })
eq(names(black), 'Fire | Fire II | Tornado | Meteor', 'skill: black pill keeps only black spells, in sort order')
local white_on_blm = C.rows(SPELLS, { job = 4, level = 40, data = DATA, sources = SOURCES, skill = 'white' })
eq(#white_on_blm, 0, 'skill: white pill on a BLM yields nothing')
eq(#C.rows(SPELLS, { job = 4, level = 40, data = DATA, sources = SOURCES, skill = 'all' }), #black,
   'skill: all and nil are the same filter')
eq(#C.rows(SPELLS, { job = 4, level = 40, data = DATA, sources = SOURCES, skill = 'song' }), #black,
   'skill: a pill id that does not exist filters nothing')

-- 8. unreachable ---------------------------------------------------------------------------------------------------
local cap_rows = C.rows({ SPELLS[9], SPELLS[10] }, { job = 4, level = 40, data = DATA, sources = SOURCES })
eq(find(cap_rows, 'Meteor').unreachable, true, 'rows: level-90-only spell is flagged unreachable')
eq(find(cap_rows, 'Tornado').unreachable, false, 'rows: level-75 spell is not flagged unreachable')
eq(find(cap_rows, 'Meteor').tag, 'none', 'badge: an unreachable spell is tagged none whatever its source')
eq(find(cap_rows, 'Meteor').level, 90, 'rows: an unreachable spell still reports its real level')

-- 9. badge per mode ------------------------------------------------------------------------------------------------
local function one(spell, mode)
    local rows = C.rows({ spell }, {
        job = 3, level = 60, data = DATA, sources = SOURCES, mode = mode, show_learned = true,
    })
    return rows[1]
end
-- wizardoll is the LAST resort, not the lead: the pill names the vendor or drop the source table cites (that is the
-- only citation the row has), and the window appends the ACE Sparks route to its tooltip. Both halves are pinned.
eq(one(SPELLS[1], 'ace').tag, 'shop', 'badge: ace leads with the concrete source, not wizardoll')
eq(one(SPELLS[1], 'ace').note, SOURCES[1].note, 'badge: the pill note is the vendor the source names')
eq(one(SPELLS[2], 'ace').tag, 'wizardoll', 'badge: a source with no usable tag still offers wizardoll in ace')
eq(one(SPELLS[2], 'ace').note, DATA.tags.wizardoll.note, 'badge: wizardoll note comes from the tag table')
eq(one(SPELLS[1], 'wew').tag, 'shop', 'badge: wew hides wizardoll and keeps the shop path')
eq(one(SPELLS[4], 'cw').tag, 'self', 'badge: cw hides ah and wizardoll and falls back to self')
eq(one(SPELLS[4], 'cw').badge.label, 'Self-found', 'badge: fallback tag still resolves to a tag entry')
eq(one(SPELLS[4], 'wew').tag, 'ah', 'badge: wew keeps the ah path')
eq(one(SPELLS[1], 'wew').src, SOURCES[1].src, 'badge: src is the source row when there is one')

-- 10. badge with no source row -------------------------------------------------------------------------------------
local nosrc = one(SPELLS[5], 'ace')
eq(nosrc.tag, 'unknown', 'badge: a spell with no source row falls back to unknown')
eq(nosrc.badge ~= nil, true, 'badge: badge entry is never nil')
eq(nosrc.badge.label, 'No source', 'badge: unknown resolves to the data tag entry')
eq(nosrc.src, DATA.modes[1].src, 'badge: src falls back to the mode citation')

-- 11. urls ---------------------------------------------------------------------------------------------------------
local utsu = C.urls('Utsusemi: Ichi')
eq(utsu.wiki, 'https://www.bg-wiki.com/ffxi/Utsusemi:_Ichi', 'urls: wiki keeps the colon, spaces become underscores')
eq(utsu.database, 'https://catseyexi.com/database?q=Utsusemi%3A%20Ichi',
   'urls: database percent-encodes the space and the colon')
local scroll = C.urls('Cure IV', 'Scroll of Cure IV')
eq(scroll.database, 'https://catseyexi.com/database?q=Scroll%20of%20Cure%20IV',
   'urls: the scroll name is searched for when there is one')
eq(scroll.wiki, 'https://www.bg-wiki.com/ffxi/Cure_IV', 'urls: wiki uses the spell name, not the scroll')
eq(C.urls('A-B_c.d~e').database, 'https://catseyexi.com/database?q=A-B_c.d~e',
   'urls: RFC 3986 unreserved characters are left alone')

-- 12. counts -------------------------------------------------------------------------------------------------------
local all = C.rows(SPELLS, {
    job = 3, level = 40, bits = bits_with({ 1, 2 }), data = DATA, sources = SOURCES, show_learned = true,
})
local c = C.counts(all)
eq(c.total, 6, 'counts: total counts every visible row')
eq(c.learned, 2, 'counts: learned counts the bits that are set')
eq(c.missing, 4, 'counts: missing is total minus learned')
eq(c.unreachable, 1, 'counts: unreachable counts the rows no job can learn at the cap')
eq(names(all), 'Cure | Cure II | Cure III | Haste | Cure IV | Cure V',
   'rows: castable first, then level ascending, then name')
eq(C.counts({}).total, 0, 'counts: an empty list counts as zero, not an error')

-- 13. scroll_name ----------------------------------------------------------------------------------------------------
-- 'Scroll of Cure IV' is the item the shop and the AH list; 'Cure IV' is the spell the row is about. Geomancy is the
-- one other prefix the game uses ('Plate of Indi-Int'), and a prefix alone holds no spell at all.
eq(C.scroll_name('Scroll of Cure IV'), 'Cure IV', 'scroll_name: a scroll gives the spell it holds')
eq(C.scroll_name('Plate of Indi-Int'), 'Indi-Int', 'scroll_name: a geomancy plate gives the spell too')
eq(C.scroll_name('Scroll of Utsusemi: Ichi'), 'Utsusemi: Ichi', 'scroll_name: a colon in the spell name survives')
eq(C.scroll_name('Cure IV'), nil, 'scroll_name: a bare spell name is not a scroll')
eq(C.scroll_name('Fire Crystal'), nil, 'scroll_name: an item that is not a scroll is nil')
eq(C.scroll_name('  scroll   OF   Cure IV  '), 'Cure IV', 'scroll_name: odd spacing and case around the prefix')
eq(C.scroll_name('Scroll of '), nil, 'scroll_name: a prefix with nothing after it is nil')
eq(C.scroll_name(nil), nil, 'scroll_name: nil is nil, not an error')

-- 14. held -----------------------------------------------------------------------------------------------------------
-- Two of the same scroll in the inventory, once more in the safe: the count is the player's whole stock, the bag is
-- the first one it was found in, and bags names every bag it turned up in so the tooltip can say 'also ...'.
local SLOTS = {
    { name = 'Scroll of Cure IV', bag = 'Inventory', count = 1 },
    { name = 'Plate of Indi-Int', bag = 'Mog Safe',  count = 2 },
    { name = 'Scroll of Cure IV', bag = 'Inventory', count = 2 },
    { name = 'Scroll of Cure IV', bag = 'Mog Safe',  count = 1 },
    { name = 'Fire Crystal',      bag = 'Inventory', count = 12 },
}
local H = C.held(SLOTS)
eq(type(H), 'table', 'held: a slot list yields a map')
eq(H['cure iv'] ~= nil, true, 'held: a scroll is keyed by its lower-cased spell name')
eq(H['cure iv'].count, 4, 'held: the same spell in two bags adds up')
eq(H['cure iv'].bag, 'Inventory', 'held: the first bag that held it stays the bag')
eq(table.concat(H['cure iv'].bags, '|'), 'Inventory|Mog Safe', 'held: every bag it was seen in is listed once')
eq(H['indi-int'].count, 2, 'held: a plate counts the same way a scroll does')
eq(H['indi-int'].bag, 'Mog Safe', 'held: the plate keeps its own bag')
eq(H['fire crystal'], nil, 'held: an item that is not a scroll is not held')
local empty_n = 0
for _ in pairs(C.held({})) do empty_n = empty_n + 1 end
eq(empty_n, 0, 'held: an empty slot list yields an empty map')
local nil_n = 0
for _ in pairs(C.held(nil)) do nil_n = nil_n + 1 end
eq(nil_n, 0, 'held: nil slots yields an empty map, not an error')

-- 15. rows: only_now -------------------------------------------------------------------------------------------------
-- WHM 50 knows Cure I..IV and Haste, and Cure V sits in the list only because it exists; 'usable now' has to drop
-- exactly the row the player cannot cast and leave the rest in the same order.
local whm50 = { job = 3, level = 50, data = DATA, sources = SOURCES, show_learned = true }
local all50 = C.rows(SPELLS, whm50)
local now50 = C.rows(SPELLS, { job = 3, level = 50, data = DATA, sources = SOURCES, show_learned = true, only_now = true })
eq(#all50, 6, "only_now: the unfiltered WHM 50 list is the fixture's six WHM spells")
eq(#now50, 5, 'only_now: the count of rows drops by the one spell above level')
eq(find(now50, 'Cure V'), nil, "only_now: a spell above the player's level is gone")
eq(names(now50), 'Cure | Cure II | Cure III | Haste | Cure IV', 'only_now: the surviving rows keep their order')
local all_castable = true
for i = 1, #now50 do if now50[i].castable ~= true then all_castable = false end end
eq(all_castable, true, 'only_now: every row it keeps is castable')
eq(now50[#now50].castable, true, 'only_now: the last row left is castable too')

-- 16. rows: held ----------------------------------------------------------------------------------------------------
-- the held map rides onto the rows a caller shows; a spell nobody holds must carry nil, not an empty table, because
-- the window draws the marker on `if row.held` alone.
local held_rows = C.rows(three, {
    job = 3, level = 40, bits = known, data = DATA, sources = SOURCES, show_learned = true, held = H,
})
local held_cure4 = find(held_rows, 'Cure IV')
eq(held_cure4.held ~= nil, true, 'held rows: a scroll in the bags marks its row')
eq(held_cure4.held.bag, 'Inventory', 'held rows: the row carries the bag')
eq(held_cure4.held.count, 4, 'held rows: the row carries the count')
eq(find(held_rows, 'Cure').held, nil, 'held rows: a spell nobody holds carries nil')
eq(held_cure4.held ~= H['cure iv'], true, "held rows: row.held is a copy, not the map's own entry")
eq(names(held_rows), names(C.rows(three, { job = 3, level = 40, bits = known, data = DATA, sources = SOURCES, show_learned = true })),
   'held rows: passing held changes no filter and no order')

-- 17. counts: held --------------------------------------------------------------------------------------------------
eq(C.counts(held_rows).held, 1, 'counts: held counts the rows carrying a held scroll')
eq(C.counts(all50).held, 0, 'counts: a list built without a held map counts zero held')
eq(C.counts({}).held, 0, 'counts: an empty list counts zero held, not an error')

-- 18. ledger_stored: the page table and the bit decode ---------------------------------------------------------------
-- The table is the SHIPPED scroll_ledger.lua, not a fixture: its order has to match the server's page layout, so a
-- test that invented a page order would pass while the addon marked the wrong spells. The three anchors below were
-- read out of that file (White page 1 starts at Cure and ends at Protect; the third category is Summoning with one
-- 8-entry page; the seventh is Geomancy with one 30-entry page) and a change to the table's order breaks them.
local LEDGER = assert(loadfile(here .. '/../scroll_ledger.lua'))()

local function count_set(set)
    local n = 0
    for _ in pairs(set or {}) do n = n + 1 end
    return n
end

local pages_total = 0
for i = 1, #LEDGER do pages_total = pages_total + #LEDGER[i].pages end
eq(#LEDGER, 7, 'ledger: the shipped table has seven categories')
eq(pages_total, 19, 'ledger: and nineteen pages, so the answer carries nineteen uint32s')
eq(LEDGER[1].pages[1][1][1], 'Cure', 'ledger: white page 1 entry 1 is Cure')
eq(LEDGER[1].pages[1][32][1], 'Protect', 'ledger: white page 1 is a full 32-entry page')
eq(LEDGER[3].pages[1][8][1], 'Dark Spirit', 'ledger: the third category is Summoning, eight entries')
eq(LEDGER[7].pages[1][30][1], 'Indi-Haste', 'ledger: the seventh category is Geomancy, thirty entries')

-- flattening: page k is (pages before category i) + j. A mask on page 1 of the FIRST category proves nothing about
-- that arithmetic, which is why the anchors cross categories: page 12 is Summoning's only page and page 19 is the
-- last page of the last category. Ignoring the category offset lands both on the white pages instead.
local one_page = C.ledger_stored(LEDGER, { [1] = 1 })
eq(one_page['cure'], true, 'flatten: bit 0 of page 1 marks the first entry of White page 1')
eq(one_page['protect'], nil, 'flatten: and nothing else on that page')
eq(count_set(one_page), 1, 'flatten: one bit means one spell')

local third_cat = C.ledger_stored(LEDGER, { [12] = 128 })
eq(third_cat['dark spirit'], true, 'flatten: page 12 is Summoning page 1, bit 7 is its eighth entry')
eq(third_cat['fire spirit'], nil, 'flatten: and bit 0 of that page is not marked')
eq(count_set(third_cat), 1, 'flatten: a mid-table page does not bleed into its neighbours')

local last_cat = C.ledger_stored(LEDGER, { [19] = 2 ^ 29 })
eq(last_cat['indi-haste'], true, 'flatten: page 19 is Geomancy page 1, bit 29 is its thirtieth entry')
eq(count_set(last_cat), 1, 'flatten: two categories apart still lands on one entry')

-- a full 32-entry page: bit 31 is entry 32, which is exactly where a uint32 runs out
local top_bit = C.ledger_stored(LEDGER, { [1] = 2 ^ 31 })
eq(top_bit['protect'], true, 'bits: bit 31 of a full page marks its 32nd entry')
eq(top_bit['cure'], nil, 'bits: and not the first one')
eq(count_set(top_bit), 1, 'bits: a single high bit marks a single spell')

-- a page shorter than 32: a set bit past its last entry has nothing to name, and must not index past the array
local past_end = C.ledger_stored(LEDGER, { [6] = 2 ^ 31 })
eq(count_set(past_end), 0, 'bits: a bit past the end of a short page marks nothing')

-- the guards. A short answer, a nil answer, a zero mask and a junk mask are all "no information", never an error.
local short_list = C.ledger_stored(LEDGER, { [1] = 1 })
eq(short_list['protect ii'], nil, 'short answer: page 2 is absent, so nothing on it is marked')
local nil_masks = C.ledger_stored(LEDGER, nil)
eq(type(nil_masks), 'table', 'nil masks: an empty set, not nil and not an error')
eq(count_set(nil_masks), 0, 'nil masks: nothing is claimed as stored')

local zero_masks = {}
for i = 1, 19 do zero_masks[i] = 0 end
eq(count_set(C.ledger_stored(LEDGER, zero_masks)), 0, 'mask 0: a page with no bits marks nothing')

eq(count_set(C.ledger_stored(nil, { [1] = 1 })), 0, 'no ledger: a missing page table yields an empty set')
eq(count_set(C.ledger_stored(LEDGER, 'x')), 0, 'junk masks: a string is not an answer')

-- a page longer than 32 entries: a uint32 has 32 bits, so entries 33+ cannot be encoded and are ignored. The
-- first mask below is the ordinary case; the second is a value the wire cannot carry (2^32), which is the only input
-- that can reach the 33rd entry at all - and the answer is still "nothing", because that entry is unreachable.
local LONG_PAGE = {}
for i = 1, 40 do LONG_PAGE[i] = { 'Long Spell ' .. i, 9000 + i } end
local LONG_LEDGER = { { name = 'Long', short = 'LNG', pages = { LONG_PAGE } } }
local long_set = C.ledger_stored(LONG_LEDGER, { [1] = 2 ^ 31 })
eq(long_set['long spell 32'], true, 'long page: bit 31 is still the 32nd entry of a 40-entry page')
eq(long_set['long spell 33'], nil, 'long page: the 33rd entry is unreachable and is not marked')
eq(count_set(long_set), 1, 'long page: one bit, one spell, no indexing past the array')
eq(count_set(C.ledger_stored(LONG_LEDGER, { [1] = 2 ^ 32 })), 0,
   'long page: a page is counted as it is, so no entry past the 32nd is ever marked')

-- the same spell named twice in the table: two entries, one key, no error
local DUP_LEDGER = { { name = 'Dup', short = 'DUP', pages = { { { 'Cure', 4609 }, { 'Cure', 4609 }, { 'Fire', 4752 } } } } }
local dup_set = C.ledger_stored(DUP_LEDGER, { [1] = 1 })
eq(dup_set['cure'], true, 'duplicate name: two entries with one name mark one key')
eq(count_set(dup_set), 1, 'duplicate name: and the key is a single boolean')

-- 19. rows and counts carry the ledger's answer ----------------------------------------------------------------
-- 'Cure IV' is entry 4 of White page 1, so bit 3 of mask 1. Built through ledger_stored rather than hand-written:
-- the name key is the function's own output, so a change to its casing or shape shows up here too.
local STORED = C.ledger_stored(LEDGER, { [1] = 8 })
eq(STORED['cure iv'], true, 'ledger: Cure IV is entry 4 of White page 1, bit 3')
local stored_rows = C.rows(three, {
    job = 3, level = 40, bits = known, data = DATA, sources = SOURCES, show_learned = true,
    held = H, stored = STORED,
})
eq(find(stored_rows, 'Cure IV').stored, true, 'stored rows: the ledger marks its row')
eq(find(stored_rows, 'Cure').stored, nil, 'stored rows: a spell the ledger does not mark carries nil, not false')
eq(names(stored_rows), names(held_rows), 'stored rows: passing the ledger changes no filter and no order')
eq(C.counts(stored_rows).held, 1, 'stored rows: the bag count survives the ledger')
eq(C.counts(stored_rows).stored, 1, 'counts: stored counts the rows the ledger marks')
eq(C.counts(held_rows).stored, 0, 'counts: a list built without the ledger counts zero stored')
eq(C.counts({}).stored, 0, 'counts: an empty list counts zero stored, not an error')

-- 20. zones -----------------------------------------------------------------------------
-- The two tables spell the same zone differently and both spellings are in the shipped data: the game's zone table
-- drops apostrophes ('Port San dOria') because DAT names cannot carry one, and spell_sources.lua keeps the wiki's
-- ('Port San d'Oria'). The join is zone_key, so the first check is that both spellings meet - the plan's own
-- measurement (all 43 zones resolve) needs that, and 'port sandoria' would only come out of 'Port SandOria'.
eq(C.zone_key("Port San d'Oria"), C.zone_key('Port San dOria'),
   'zone_key: the wiki spelling and the game table spelling meet at one key')
eq(C.zone_key("Port San d'Oria"), 'port san doria', 'zone_key: an apostrophe is dropped, not turned into a space')
eq(C.zone_key('The Eldieme Necropolis (S)'), 'the eldieme necropolis (s)',
   'zone_key: a trailing (S) marks the past version, and is kept as a token')
eq(C.zone_key('The Eldieme Necropolis [S]'), 'the eldieme necropolis (s)',
   'zone_key: a trailing [S] means the same and lands on the same key')
eq(C.zone_key('The Eldieme Necropolis (S)') == C.zone_key('The Eldieme Necropolis'), false,
   'zone_key: the past zone and the present one are different zones, not spellings of one')
eq(C.zone_key('The Eldieme Necropolis'), 'the eldieme necropolis',
   'zone_key: the present zone keeps no token, so a past vendor cannot be announced there')
eq(C.zone_key('Windurst Waters South'), 'windurst waters', 'zone_key: a trailing South is dropped')
eq(C.zone_key('Windurst Waters North'), 'windurst waters', 'zone_key: and so is a trailing North')
eq(C.zone_key('  Lower   Jeuno '), 'lower jeuno', 'zone_key: whitespace collapses and is trimmed, and case folds')
eq(C.zone_key('Port San d\u{2019}Oria'), 'port san doria', 'zone_key: the typographic apostrophe is dropped')
eq(C.zone_key('Port San d' .. string.char(96) .. 'Oria'), C.zone_key("Port San d'Oria"),
   'zone_key: a backtick is dropped the same way an apostrophe is')
eq(C.zone_key(nil), '', 'zone_key: nil is the empty key, not an error')
eq(C.zone_key(''), '', 'zone_key: an empty name is the empty key')
eq(C.zone_key(42), '', 'zone_key: a non-string is the empty key')

-- a three-kind fixture plus the two shapes the real table has: an empty zone (160 shipped rows) and a numeric-string
-- key (the generated table is keyed by id, and Lua makes no promise that arrives as a number)
local ZONE_SOURCES = {
    [1]   = { tag = 'shop', tags = { 'shop' }, note = 'A vendor / Lower Jeuno',   zone = 'Lower Jeuno' },
    [2]   = { tag = 'drop', tags = { 'drop' }, note = 'A monster / Lower Jeuno',  zone = 'Lower Jeuno' },
    [3]   = { tag = 'bcnm', tags = { 'bcnm' }, note = 'A battlefield / Lower Jeuno', zone = 'Lower Jeuno' },
    [5]   = { tag = 'shop', tags = { 'shop' }, note = 'A vendor / Port San dOria', zone = "Port San d'Oria" },
    ['9'] = { tag = 'drop', tags = { 'drop' }, note = 'A monster / the past',      zone = 'The Eldieme Necropolis (S)' },
    ['7'] = { tag = 'ah',   tags = { 'ah' },   note = 'Auction House only',        zone = '' },
    [6]   = { tag = 'drop', tags = { 'drop' }, note = 'no place recorded' },
}
local ZIDX = C.zone_index(ZONE_SOURCES)
eq(type(ZIDX), 'table', 'zone_index: a source table yields a table')
eq(#(ZIDX['lower jeuno'] or {}), 3, 'zone_index: the three kinds are grouped under one zone')
eq(ZIDX['lower jeuno'][1].kind, 'shop', 'zone_index: shop rows come first in a zone')
eq(ZIDX['lower jeuno'][2].kind, 'drop', 'zone_index: then drop')
eq(ZIDX['lower jeuno'][3].kind, 'bcnm', 'zone_index: then bcnm')
eq(ZIDX['lower jeuno'][1].note, 'A vendor / Lower Jeuno', 'zone_index: the note travels with the row')
eq(ZIDX['lower jeuno'][1].zone, 'Lower Jeuno', 'zone_index: and so does the zone as the table spells it')
eq(ZIDX['lower jeuno'][1].id, 1, 'zone_index: the id is a number, so the join with a row id works')
eq(#(ZIDX['the eldieme necropolis (s)'] or {}), 1, 'zone_index: a (S) zone lands under its past-version key')
eq(ZIDX['the eldieme necropolis (s)'][1].id, 9, 'zone_index: a numeric-string key becomes a number')
eq(#(ZIDX['the eldieme necropolis'] or {}), 0, 'zone_index: and not under the present zone, which has its own vendors')
eq(#(ZIDX['port san doria'] or {}), 1, 'zone_index: an apostrophe zone lands under the key both tables share')
-- 3 + 1 + 1 + 1: every row that names a place, and neither of the two without one
local idx_total = 0
for _, bucket in pairs(ZIDX) do idx_total = idx_total + #bucket end
eq(idx_total, 5, 'zone_index: rows with no zone (empty or absent) are skipped')
eq(#C.zone_index(nil), 0, 'zone_index: nil yields an empty index, not an error')
local empty_idx_n = 0
for _ in pairs(C.zone_index({})) do empty_idx_n = empty_idx_n + 1 end
eq(empty_idx_n, 0, 'zone_index: an empty source table yields an empty index')

-- the rows the alerts read, built the way the window builds them (job 3 at 60, nothing learnt)
local zone_rows = C.rows(SPELLS, { job = 3, level = 60, data = DATA, sources = SOURCES })
local function hit_names(hits)
    local t = {}
    for i = 1, #hits do t[i] = hits[i].row.name end
    return table.concat(t, ' | ')
end
local hits = C.here(ZIDX, 'lower jeuno', zone_rows)
eq(hit_names(hits), 'Cure III | Cure II | Cure',
   'here: a battlefield first, then a drop, then the vendor, each by name')
eq(hits[1].kind, 'bcnm', 'here: each hit says which kind of place it is')
eq(hits[1].note, 'A battlefield / Lower Jeuno', 'here: and carries the generated note')
eq(hits[1].zone, 'Lower Jeuno', 'here: and the zone as the source table spells it')
eq(hits[3].row.name, 'Cure', 'here: the hit carries the caller row itself')

-- learnt spells are the caller's business: with Cure and Cure II known, only Cure III is left to find
local learnt = C.rows(SPELLS, {
    job = 3, level = 60, bits = bits_with({ 1, 2 }), data = DATA, sources = SOURCES,
})
eq(hit_names(C.here(ZIDX, 'lower jeuno', learnt)), 'Cure III', 'here: only the rows still needed are returned')

-- kinds is a set: one kind off drops those hits and leaves the rest in order
local vendors_only = C.here(ZIDX, 'lower jeuno', zone_rows, { shop = true })
eq(hit_names(vendors_only), 'Cure', 'here: a kind set keeps only the kinds it names')
local no_shop = C.here(ZIDX, 'lower jeuno', zone_rows, { drop = true, bcnm = true })
eq(hit_names(no_shop), 'Cure III | Cure II', 'here: a kind set that excludes one drops exactly that one')
eq(hit_names(C.here(ZIDX, 'lower jeuno', zone_rows, nil)), hit_names(hits),
   'here: nil kinds means all three')
local no_kinds = C.here(ZIDX, 'lower jeuno', zone_rows, {})
eq(#no_kinds, 0, 'here: an empty kind set means the player asked for nothing')

eq(#C.here(ZIDX, 'nowhere', zone_rows), 0, 'here: an unknown zone yields nothing')
eq(#C.here(nil, 'lower jeuno', zone_rows), 0, 'here: a nil index yields nothing, not an error')
eq(#C.here(ZIDX, '', zone_rows), 0, 'here: an empty key matches no zone')
eq(#C.here(ZIDX, 'lower jeuno', nil), 0, 'here: nil rows yield nothing')

-- nothing is written back: not the index, not the bucket's order, not the rows themselves
local bucket = ZIDX['lower jeuno']
local first_before = bucket[1].id
local hits_again = C.here(ZIDX, 'lower jeuno', zone_rows)
eq(#bucket, 3, 'here: the index bucket keeps its length')
eq(bucket[1].id, first_before, 'here: the index bucket keeps its own order')
eq(bucket[1].kind, 'shop', 'here: and its own first entry')
eq(#zone_rows, 6, "here: the caller's row list keeps its length")
eq(hits_again[1].row, hits[1].row, 'here: the hits name the caller rows, not copies')
eq(hits[1].row.zone, nil, 'here: nothing is written onto the caller row')
eq(hits_again[1].row.zone, nil, 'here: not even on a second call')

------------------------------------------------------------------------------- 21. dice_core: known
-- A corsair roll is learnt from a die item, not by levelling, and the game counts it in the OTHER bitfield: the
-- 224-byte ability string, where a job ability's bit is 0x200 + its id (docs/addons/04-game-data.md:490-492). The
-- first checks pin that offset, because reading bit 97 for Phantom Roll would test a weapon skill's bit and mark a
-- player as knowing rolls they were never taught. `nil` is its own answer: the client has not sent the bits yet, and
-- 'not known' would be a claim about the player rather than about the client.
local D = assert(loadfile(here .. '/../dice_core.lua'))()

local function ability_bits(ids)
    local t = {}
    for i = 1, 224 do t[i] = 0 end
    for _, id in ipairs(ids) do
        local bit = 512 + id
        local byte = math.floor(bit / 8)
        t[byte + 1] = t[byte + 1] + 2 ^ (bit % 8)
    end
    local out = {}
    for i = 1, 224 do out[i] = string.char(t[i]) end
    return table.concat(out)
end
local function bit_string(bytes, bit)
    local t = {}
    for i = 1, bytes do t[i] = 0 end
    t[math.floor(bit / 8) + 1] = 2 ^ (bit % 8)
    local out = {}
    for i = 1, bytes do out[i] = string.char(t[i]) end
    return table.concat(out)
end

local abits = ability_bits({ 98, 110 })
eq(D.known(abits, 98), true, 'dice known: a set job ability bit reads true')
eq(D.known(abits, 110), true, 'dice known: and so does another one on another byte')
eq(D.known(abits, 99), false, 'dice known: a clear bit reads false, not nil')
eq(D.known(bit_string(224, 610), 98), true, 'dice known: ability 98 lives at bit 0x200 + 98 = 610')
eq(D.known(bit_string(224, 98), 98), false,
   'dice known: bit 98 alone is a weapon skill, so it does not mark the ability known')
eq(D.known(nil, 98), nil, 'dice known: nil bits is UNKNOWN, not "not known"')
eq(D.known('', 98), nil, 'dice known: an empty string cannot answer')
eq(D.known(string.rep('\0', 50), 98), nil, 'dice known: a string too short for the bit is unknown, not false')
eq(D.known(string.rep('\0', 224), 98), false, 'dice known: a full zeroed string says not known')
eq(D.known(abits, nil), nil, 'dice known: no ability id is unknown')
eq(D.known(abits, 'x'), nil, 'dice known: a non-numeric id is unknown')

------------------------------------------------------------------------------- 22. dice_core: rows
-- The fixture mirrors dice_data.lua's shape field for field. Five dice with the four things a row can be: a shop in
-- Al Zahbi, a shop in Nashmau, a level-97 die above any of the levels tested, a page that named no source at all, and
-- an apostrophe in the name (the case a generated table gets wrong when it takes a slug for a name).
local DICE = {
    [5477] = { id = 5477, name = 'Warrior Die', roll = "Fighter's Roll", ability_id = 98, level = 49,
               tag = 'shop', tags = { 'shop', 'ah' }, note = 'Chayaya / Al Zahbi - (J-8) / 68,000 Gil',
               zone = 'Al Zahbi', src = 'https://www.bg-wiki.com/ffxi/Warrior_Die' },
    [5479] = { id = 5479, name = 'White Mage Die', roll = "Healer's Roll", ability_id = 100, level = 20,
               tag = 'none', tags = {}, note = '', zone = '', src = 'https://www.bg-wiki.com/ffxi/White_Mage_Die' },
    [5487] = { id = 5487, name = 'Ranger Die', roll = "Hunter's Roll", ability_id = 108, level = 11,
               tag = 'shop', tags = { 'shop' }, note = 'Chayaya / Al Zahbi - (J-8) / 1,300 Gil',
               zone = 'Al Zahbi', src = 'https://www.bg-wiki.com/ffxi/Ranger_Die' },
    [5489] = { id = 5489, name = 'Ninja Die', roll = 'Ninja Roll', ability_id = 110, level = 8,
               tag = 'shop', tags = { 'shop' }, note = 'Jajaroon / Nashmau - (G-7) / 600 Gil',
               zone = 'Nashmau', src = 'https://www.bg-wiki.com/ffxi/Ninja_Die' },
    [5505] = { id = 5505, name = "Avenger's Die", roll = "Avenger's Roll", ability_id = 305, level = 97,
               tag = 'shop', tags = { 'shop', 'ah' }, note = 'Chichiroon / Nashmau - (G-7) / 123,744 Gil',
               zone = 'Nashmau', src = 'https://www.bg-wiki.com/ffxi/Avenger%27s_Die' },
}

local function dice_names(rows)
    local t = {}
    for i = 1, #rows do t[i] = rows[i].name end
    return table.concat(t, ' | ')
end

local no_bits = D.rows(DICE, { level = 30 })
eq(#no_bits, 5, 'dice rows: a nil bitfield lists every die (unknown is not "known")')
eq(no_bits[1].known, nil, 'dice rows: and every row says known is nil, not false')
eq(dice_names(no_bits), 'Ninja Die | Ranger Die | White Mage Die | Warrior Die | Avenger\'s Die',
   'dice rows: sorted by level, then by name')
eq(no_bits[1].level, 8, 'dice rows: the level is the COR requirement printed on the die')
eq(no_bits[1].roll, 'Ninja Roll', 'dice rows: the row names the roll the die teaches')
eq(no_bits[1].ability_id, 110, 'dice rows: and the ability id known-status is read for')
eq(no_bits[1].src ~= '', true, 'dice rows: every row keeps the page it came from')

-- usable is the literal level <= opts.level comparison, and the boundary is the interesting value
eq(no_bits[1].usable, true, 'dice rows: a die at or below the level is usable')
eq(D.rows({ DICE[5489] }, { level = 8 })[1].usable, true, 'dice rows: exactly at the level is usable')
eq(D.rows({ DICE[5489] }, { level = 7 })[1].usable, false, 'dice rows: one level short is not')
eq(D.rows({ DICE[5489] }, { level = 0 })[1].usable, false, 'dice rows: not on COR (level 0) makes nothing usable')
eq(D.rows(DICE, {})[1].usable, false, 'dice rows: no opts at all reads as level 0, not as an error')

-- known filtering: a known die is hidden by default and comes back with show_known, like a learnt spell
local with_bits = D.rows(DICE, { level = 30, bits = abits })
eq(#with_bits, 3, 'dice rows: a known die is hidden by default')
eq(dice_names(with_bits), "Ranger Die | White Mage Die | Avenger's Die",
   'dice rows: the known ones go and the rest keep their order')
local all_bits = D.rows(DICE, { level = 30, bits = abits, show_known = true })
eq(#all_bits, 5, 'dice rows: show_known lists the known dice too')
eq(dice_names(all_bits), dice_names(no_bits), 'dice rows: show_known changes no order')
eq(all_bits[4].known, true, 'dice rows: and a known die carries known = true')
eq(all_bits[3].known, false, 'dice rows: an unknown one carries known = false')

-- only_now is the level filter, folded into the same pass
local now30 = D.rows(DICE, { level = 30, bits = abits, only_now = true, show_known = true })
eq(#now30, 3, 'dice rows: only_now keeps the dice at or below the level')
eq(dice_names(now30), 'Ninja Die | Ranger Die | White Mage Die', 'dice rows: and keeps their order')
eq(D.rows(DICE, { level = 0, only_now = true })[1], nil, 'dice rows: only_now off COR yields nothing, not an error')

-- the query reads the die's name AND the roll it teaches, because a player looks for either ('healer' is the roll,
-- 'white mage' the die). The zone is not searched on purpose: 'what is sold in Nashmau' is the Dice view's column,
-- not a search box's job.
eq(dice_names(D.rows(DICE, { level = 30, query = 'healer' })), 'White Mage Die',
   'dice query: a word of the roll name finds the die')
eq(dice_names(D.rows(DICE, { level = 30, query = 'white' })), 'White Mage Die',
   'dice query: a word of the die name finds it too')
eq(dice_names(D.rows(DICE, { level = 30, query = "avenger's" })), "Avenger's Die",
   'dice query: an apostrophe is a plain character, not a pattern')
eq(dice_names(D.rows(DICE, { level = 30, query = 'DIE' })), dice_names(no_bits),
   'dice query: case folds and every die name ends in "die"')
eq(#D.rows(DICE, { level = 30, query = 'nashmau' }), 0, 'dice query: the zone is not part of the search')

-- the three shapes dice_data can arrive in: the module, the keyed table, an array of rows
eq(#D.rows({ dice = DICE }, { level = 30 }), 5, 'dice data: the module table is read as its dice')
eq(#D.rows({ DICE[5477], DICE[5489] }, { level = 30 }), 2, 'dice data: an array of rows is read as it is')
eq(#D.rows(nil), 0, 'dice data: nil yields no rows, not an error')
eq(#D.rows({}, { level = 30 }), 0, 'dice data: an empty table yields no rows')

------------------------------------------------------------------------------- 23. dice_core: held and counts
-- The bag marker is keyed by ITEM id: 'Warrior Die' is an item's name, and the map the window builds comes from the
-- container slots' own ids, so a name that merely looks like a die cannot mark a row.
local HELD = { [5477] = { bag = 'Mog Locker', count = 2 }, [9999] = { bag = 'Inventory', count = 1 } }
local held_rows = D.rows(DICE, { level = 30, held = HELD })
local warrior = nil
for i = 1, #held_rows do if held_rows[i].name == 'Warrior Die' then warrior = held_rows[i] end end
eq(warrior ~= nil and warrior.held ~= nil, true, 'dice held: a die in a bag marks its row')
eq(warrior and warrior.held.bag, 'Mog Locker', 'dice held: the marker names the bag')
eq(warrior and warrior.held.count, 2, 'dice held: and the count')
eq(warrior ~= nil and warrior.held ~= HELD[5477], true, "dice held: the row's marker is a copy, not the map's entry")
eq(held_rows[1].held, nil, 'dice held: a die nobody holds carries nil, not an empty table')
eq(D.rows(DICE, { level = 30, held = HELD })[1].held, nil, 'dice held: and nothing else is marked')
eq(#held_rows, 5, 'dice held: the bag map filters nothing')

local dc = D.counts(no_bits)
eq(dc.total, 5, 'dice counts: total counts every row')
eq(dc.usable, 3, 'dice counts: usable counts the rows at or below the level')
eq(dc.known, 0, 'dice counts: a nil bitfield counts zero known')
eq(dc.missing, 0, 'dice counts: and zero missing, because it is not "not known"')
eq(dc.unknown, 5, 'dice counts: it counts them as unknown instead')
eq(dc.kinds.shop, 4, 'dice counts: the per-kind tally counts the shop dice')
eq(dc.kinds.none, 1, 'dice counts: and the page that named no source')
local dcb = D.counts(all_bits)
eq(dcb.known, 2, 'dice counts: with a bitfield, known counts the set abilities')
eq(dcb.missing, 3, 'dice counts: missing counts the clear ones')
eq(dcb.unknown, 0, 'dice counts: and nothing is unknown once the client has answered')
eq(D.counts(held_rows).held, 1, 'dice counts: held counts the rows carrying a die in a bag')
local empty_counts = D.counts({})
eq(empty_counts.total, 0, 'dice counts: an empty list counts zero, not an error')
local kinds_n = 0
for _ in pairs(empty_counts.kinds) do kinds_n = kinds_n + 1 end
eq(kinds_n, 0, 'dice counts: and its kind tally is empty')

print(string.format('checks %d, failures %d', checks, failures))
os.exit(failures > 0 and 1 or 0)
