-- The tracker's whole brain: which spells a job can still learn, what a row means, what badge it wears, and the two
-- links the window opens. Nothing here touches vana.*, ui.lua, the file system or a global: the module takes plain
-- tables (a spell exactly as vana.gamedata.spells hands one over, the 128-byte string from vana.game.spells(), the
-- tables out of spells_data.lua) and returns new ones. That is what lets the identical code run inside the client and
-- under a plain `luajit` test - and the headless run is the only proof available on this machine, which has no
-- VanaCore install to click through.
local C = {}

-- Job ids 1..22, index = id. The client has no table of short job names (images/jobs.png is a picture, not text) and
-- a row wants 'WHM' the same way the header does, so the 22 names live here instead of costing a lookup per frame.
local JOB_SHORT = {
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG',
    'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
}

function C.job_short(job)
    if type(job) ~= 'number' then return nil end
    return JOB_SHORT[math.floor(job)]
end

-- The game's own learned-spell bitfield: byte floor(id/8)+1, bit id%8, least significant bit first. nil means the
-- client would not give it to us (or we are before the first frame) and reads as "knows nothing", which is the safe
-- direction: a wrong nil shows the player more spells than they have, never fewer.
function C.has_bit(bits, id)
    if bits == nil or type(id) ~= 'number' then return false end
    local byte = bits:byte(math.floor(id / 8) + 1)
    if byte == nil then return false end
    return math.floor(byte / 2 ^ (id % 8)) % 2 == 1
end

-- A spell's required level on one job. nil is load-bearing all over this module: it is not "no idea", it is "this job
-- never learns the spell at all", which is the difference between "too low level, come back later" and "not on your
-- list, ever". Level 0 and below never appears, so no falsy-number trap.
function C.level_for(spell, job)
    if spell == nil or spell.jobs == nil or job == nil then return nil end
    return spell.jobs[job]
end

-- The subjob rule as the game applies it: the subjob counts for half its level, rounded down, so a level 34 RDM sub is
-- a level 17 caster for spell purposes. A spell qualifies through either path - main job at its own level, or the
-- subjob at half - and rows() reports which one in via, because "you can cast this" is only useful if the player can
-- tell whether the answer changes when they swap jobs.
function C.castable(spell, me)
    if spell == nil or me == nil then return false end
    local main = C.level_for(spell, me.job)
    if main ~= nil and (me.level or 0) >= main then return true end
    local sub = C.level_for(spell, me.sub_job)
    if sub ~= nil and math.floor((me.sub_level or 0) / 2) >= sub then return true end
    return false
end

-- The badge order, fixed in code rather than read from spells_data.tags: the table is keyed, so its declaration order
-- is not something a caller can rely on, and a badge that silently reorders when someone adds a tag is a regression
-- nobody would notice. wizardoll leads because in ACE it is the path a player actually takes; sots last because it is
-- the rarest. learn sits near the end too: a blue spell is learnt, not bought.
-- wizardoll sits LAST, not first. It used to lead, which made every scrolled spell in ACE read 'Wizardoll' and threw
-- away the vendor, zone and price the generator had just read for it; the window appends the Wizardoll line to the
-- tooltip instead, so the pill keeps the concrete, citable source and ACE players still see the Sparks route.
local TAG_ORDER = { 'shop', 'ah', 'drop', 'quest', 'bcnm', 'learn', 'sots', 'wizardoll' }

local function has(list, want)
    if list == nil then return false end
    for i = 1, #list do
        if list[i] == want then return true end
    end
    return false
end

-- The badge a spell wears in one mode. Returned as four values rather than a table so rows() can drop them straight
-- onto the row, which is the shape the window and the tests both read.
--
-- unreachable wins over everything: a spell no job can learn at the cap has no acquisition path worth advertising,
-- and saying 'AH' for Cure V would be a lie about a spell the player can never own.
function C.badge(row, data, sources, mode)
    local tags = (data and data.tags) or {}
    local unknown = tags.unknown
    if row.unreachable then
        local entry = tags.none or unknown or { label = 'none', note = '' }
        return 'none', entry.note, (mode and mode.src) or nil, entry
    end

    local source = nil
    if sources ~= nil and row.id ~= nil then source = sources[row.id] end

    local hide = {}
    if mode ~= nil and mode.hide ~= nil then
        for i = 1, #mode.hide do hide[mode.hide[i]] = true end
    end

    local have = {}
    if source ~= nil and source.tags ~= nil then
        for i = 1, #source.tags do have[source.tags[i]] = true end
    end

    -- wizardoll is prepended, not inherited from the scroll page: the generator records where the *scroll* comes from,
    -- and the NPC teaches the spell itself. It only applies when a scroll page exists at all - with no recorded scroll
    -- there is nothing to confirm the spell is even sold, so claiming the NPC stocks it would be invention.
    local wizardoll = (not hide.wizardoll) and source ~= nil and mode ~= nil and has(mode.tags, 'wizardoll')

    -- the source row carries the KIND its own note describes (the generator picks both together), and that pairing is
    -- what keeps a pill from reading 'AH' over a sentence naming a monster: a spell that is both auctioned and dropped
    -- shows the path its note actually cites. The mode still gets its veto - a hidden kind falls through.
    local tag = nil
    if source ~= nil and source.tag ~= nil and not hide[source.tag] and source.tag ~= 'wizardoll' then
        tag = source.tag
    end
    if tag == nil then
        for i = 1, #TAG_ORDER do
            local id = TAG_ORDER[i]
            if id == 'wizardoll' then
                if wizardoll then tag = id break end
            elseif have[id] and not hide[id] then
                tag = id break
            end
        end
    end
    if tag == nil then tag = (mode and mode.fallback) or 'unknown' end

    local entry = tags[tag] or unknown
    if entry == nil then entry = { label = tag, note = '' } end

    local note
    if tag == 'wizardoll' then
        note = (tags.wizardoll or entry).note
    elseif source ~= nil then
        -- the generator's per-spell sentence beats the badge's generic one whenever there is one: it is the only
        -- citation the row has, and it names the actual vendor/drop instead of the category
        note = source.note or entry.note
    else
        note = entry.note
    end

    local src = (source and source.src) or (mode and mode.src) or nil
    return tag, note, src, entry
end

local function pill_for(data, id)
    if id == nil or id == 'all' then return nil end
    local pills = (data and data.skills) or {}
    for i = 1, #pills do
        if pills[i].id == id then return pills[i] end
    end
    return nil
end

local function mode_for(data, id)
    local modes = (data and data.modes) or {}
    if id ~= nil then
        for i = 1, #modes do
            if modes[i].id == id then return modes[i] end
        end
    end
    -- an unknown or absent mode is the first one, not an error: a settings row saved by a newer build must not blank
    -- the window, and ACE is the mode the addon opens in
    return modes[1]
end

local function type_ok(pill, t)
    if pill == nil then return true end
    return has(pill.types, t)
end

-- query is split on whitespace and every word has to appear somewhere in the name, in any order, because players type
-- "cure iv" and "iv cure" interchangeably and neither is a substring of the other.
local function words_of(query)
    local out = {}
    if type(query) ~= 'string' then return out end
    for w in query:lower():gmatch('%S+') do out[#out + 1] = w end
    return out
end

-- The spell an item holds. Two prefixes, because the game's own item names use two: every magic scroll is
-- 'Scroll of <spell>' and every geomancy plate is 'Plate of <spell>'. Matched case-insensitively and with any
-- spacing ('Scroll  of') because the name comes out of vana.gamedata.items, which is generated, while a test or a
-- hand-built slot list can say anything. Anything else - a crystal, a piece of gear, a bare spell name - is nil:
-- returning the name unchanged would make every item in the bags look like a scroll nobody can learn.
local function strip_scroll_prefix(s, word)
    local _, e = s:lower():find('^%s*' .. word .. '%s+of%s+')
    if e == nil then return nil end
    return s:sub(e + 1):match('^%s*(.-)%s*$')
end

function C.scroll_name(item_name)
    if type(item_name) ~= 'string' then return nil end
    local rest = strip_scroll_prefix(item_name, 'scroll')
    if rest == nil then rest = strip_scroll_prefix(item_name, 'plate') end
    if rest == nil or rest == '' then return nil end
    return rest
end

-- What the player's bags already hold, keyed by lower-cased spell name so a row can look itself up in one step.
-- A spell found in two bags is ONE entry: the count is the player's whole stock (four Scrolls of Cure IV are four),
-- the bag is the first one it was found in, and bags keeps every bag it turned up in so the tooltip can say where
-- the rest are. The first bag is kept rather than the last because the scan walks the bags in the client's own order
-- (Inventory first), so 'in your Inventory' is the answer a player expects.
function C.held(slots)
    local out = {}
    local list = slots or {}
    for i = 1, #list do
        local slot = list[i]
        if type(slot) == 'table' then
            local spell = C.scroll_name(slot.name)
            if spell ~= nil then
                local key = spell:lower()
                local n = tonumber(slot.count) or 1
                if n < 1 then n = 1 end
                local bag = slot.bag or ''
                local entry = out[key]
                if entry == nil then
                    out[key] = { bag = bag, count = n, bags = { bag } }
                else
                    entry.count = entry.count + n
                    local seen = false
                    for j = 1, #entry.bags do if entry.bags[j] == bag then seen = true break end end
                    if not seen then entry.bags[#entry.bags + 1] = bag end
                end
            end
        end
    end
    return out
end

-- What the scroll ledger says is stored, keyed by lower-cased spell name exactly like C.held()'s map, so a row can
-- look itself up with the same one step. The server does not send quantities - one bit per scroll - so this is a set
-- of names, never a count.
--
-- The flattening is Trove's (legacy/ashita/addons/trove/plugins/scrolls.lua:116-118): page k of the answer is
-- (pages in every category before i) + j for category i, page j. Getting it wrong shifts every category after the
-- first and marks the wrong spells, so it is arithmetic on the table's own shape, not an index the answer carries.
-- Bit b of a page's uint32 is entry b+1 of that page, decoded without a bit library because the client's LuaJIT
-- has one but this module must run under a plain interpreter too: floor(mask / 2^b) % 2. Masks arrive as Lua
-- numbers up to 2^32-1, which a double holds exactly.
--
-- Every guard here is a shape the server can actually send, and none of them is an error: a nil or absent mask list
-- is "no answer yet" (an empty set, not a claim that nothing is stored), a page index past the end of the answer is
-- skipped, a page longer than 32 entries can only encode its first 32 (a uint32 has 32 bits, so the rest are
-- silently unreachable and are ignored rather than indexed), and a ledger that names the same spell twice sets the
-- same key twice.
function C.ledger_stored(ledger, masks)
    local out = {}
    if type(ledger) ~= 'table' or type(masks) ~= 'table' then return out end
    local offset = 0
    for c = 1, #ledger do
        local cat = ledger[c]
        local pages = (type(cat) == 'table' and type(cat.pages) == 'table') and cat.pages or {}
        for j = 1, #pages do
            local mask = tonumber(masks[offset + j])
            local page = pages[j]
            if mask ~= nil and mask > 0 and type(page) == 'table' then
                local n = #page
                if n > 32 then n = 32 end
                for b = 0, n - 1 do
                    if math.floor(mask / 2 ^ b) % 2 == 1 then
                        local entry = page[b + 1]
                        if type(entry) == 'table' and type(entry[1]) == 'string' and entry[1] ~= '' then
                            out[entry[1]:lower()] = true
                        end
                    end
                end
            end
        end
        offset = offset + #pages
    end
    return out
end

local function name_has(words, name)
    if #words == 0 then return true end
    local n = (name or ''):lower()
    for i = 1, #words do
        -- plain find: a word like ':' or 'i-ii' must not be read as a Lua pattern
        if not n:find(words[i], 1, true) then return false end
    end
    return true
end

-- Unreachable is a fact about the spell, not about the player: no job in the whole table learns it at or below the
-- cap, so no amount of levelling gets it. That is why Cure V and Comet are listed rather than hidden - the row is the
-- explanation of why they are missing from every other list.
local function reachable(jobs, cap)
    if cap == nil then return true end
    for _, lvl in pairs(jobs) do
        -- a 0 in the table means "this job never learns it", the same reading the generator uses (tools/
        -- make_spell_sources.py learnable_at_cap): counting it as reachable would flag a spell nobody can get as
        -- available
        if type(lvl) == 'number' and lvl > 0 and lvl <= cap then return true end
    end
    return false
end

-- castable rows first, then reachable before unreachable, then the lowest level first, then alphabetical. Alphabetical
-- last because it is the only stable tiebreak that does not depend on the order the game data happens to arrive in.
local function before(a, b)
    if a.castable ~= b.castable then return a.castable end
    if a.unreachable ~= b.unreachable then return not a.unreachable end
    if a.level ~= b.level then return a.level < b.level end
    return a.name < b.name
end

function C.rows(spells, opts)
    opts = opts or {}
    local data = opts.data or {}
    local out = {}
    local list = spells or {}
    local skip = data.skip_types or {}
    local mode = mode_for(data, opts.mode)
    local pill = pill_for(data, opts.skill)
    local words = words_of(opts.query)
    local cap = opts.cap or data.level_cap
    local show_learned = opts.show_learned
    if show_learned == nil then show_learned = false end
    -- two filters that only ever narrow: 'usable now' (the player can cast it this minute) and a held map from
    -- spells_core.held(). Neither touches the skill/query/learned filters, the sort or the counts - a caller that
    -- wants the whole list simply does not pass them.
    local only_now = opts.only_now == true
    local held = opts.held
    -- the ledger's answer, a set of lower-cased names (C.ledger_stored). Like held it only decorates: it never
    -- narrows, never reorders and never touches the skill/query/learned filters.
    local stored = opts.stored

    for i = 1, #list do
        local sp = list[i]
        if sp ~= nil and sp.jobs ~= nil and not skip[sp.type] then
            local main = C.level_for(sp, opts.job)
            local sub = C.level_for(sp, opts.sub_job)
            -- a spell neither job learns is not this player's list at all; a trust is not a spell anyone learns
            if (main ~= nil or sub ~= nil) and type_ok(pill, sp.type) and name_has(words, sp.name) then
                local learned = C.has_bit(opts.bits, sp.id)
                local castable = C.castable(sp, {
                    job = opts.job, level = opts.level,
                    sub_job = opts.sub_job, sub_level = opts.sub_level,
                })
                -- learned rows are hidden by default: the tracker's question is "what is left", and the toggle in the
                -- window is the way back to the full list. 'usable now' is the same predicate the row reports, read
                -- one row earlier, so the list is built once and sorted once rather than filtered twice.
                if (show_learned or not learned) and (castable or not only_now) then
                    local row = {
                        id = sp.id,
                        name = sp.name or '',
                        type = sp.type,
                        skill_name = sp.skill_name,
                        mp = sp.mp,
                        element = sp.element,
                        learned = learned,
                        castable = castable,
                        unreachable = not reachable(sp.jobs, cap),
                        -- the level shown is the one the player's own path asks for: the main job's when it learns the
                        -- spell at all, otherwise the subjob's own requirement (not sub_level/2, which is the level the
                        -- player is treated as - showing that would print 17 next to a spell the subjob learns at 34)
                        level = main or sub,
                        via = main ~= nil and 'main' or 'sub',
                    }
                    -- the bag entry is COPIED onto the row, bags list included: the window and any caller get a value
                    -- of their own, so a row cannot be edited into (or out of) the map the next rebuild reads
                    local in_bag = held ~= nil and held[(sp.name or ''):lower()] or nil
                    if in_bag ~= nil then
                        local bags = {}
                        for j = 1, #(in_bag.bags or {}) do bags[j] = in_bag.bags[j] end
                        row.held = { bag = in_bag.bag, count = in_bag.count, bags = bags }
                    end
                    -- the ledger marks a spell whose scroll sits at Gramateus or in the box. A bare boolean on
                    -- purpose: the answer carries one bit per scroll and no quantity, so row.stored must not grow a
                    -- count the window could print.
                    if stored ~= nil and stored[(sp.name or ''):lower()] then row.stored = true end
                    row.short_job = C.job_short(main ~= nil and opts.job or opts.sub_job)
                    -- the raw tag list stays on the row for a tooltip that wants to list every path; the single
                    -- resolved tag is what the pill draws
                    local src_row = opts.sources ~= nil and opts.sources[sp.id] or nil
                    row.tags = (src_row and src_row.tags) or {}
                    row.tag, row.note, row.src, row.badge = C.badge(row, data, opts.sources, mode)
                    out[#out + 1] = row
                end
            end
        end
    end

    table.sort(out, before)
    return out
end

-- RFC 3986 unreserved characters survive; every other byte becomes %XX. Hand-rolled on purpose: Lua 5.1 ships no
-- encoder, and one more dependency in a module whose selling point is "auditable in one sitting" is a bad trade.
-- Works on bytes, so a non-ASCII spell name is escaped rather than mangled.
local function pct_encode(s)
    return (tostring(s):gsub('[^%w%-_%.~]', function (c)
        return string.format('%%%02X', string.byte(c))
    end))
end

-- catseyexi.com's own opensearch template is /database?q={searchTerms}, so the scroll name goes in the query string;
-- bg-wiki keeps the colon and only turns spaces into underscores ('Utsusemi:_Ichi' is a real page). A scroll name is
-- searched for when we have one because "Scroll of Cure IV" is what the shop and the AH list.
function C.urls(name, scroll)
    local wiki = tostring(name or ''):gsub(' ', '_')
    return {
        database = 'https://catseyexi.com/database?q=' .. pct_encode(scroll or name or ''),
        wiki = 'https://www.bg-wiki.com/ffxi/' .. wiki,
    }
end

function C.counts(rows)
    local c = { total = 0, learned = 0, missing = 0, unreachable = 0, held = 0, stored = 0 }
    local list = rows or {}
    for i = 1, #list do
        local r = list[i]
        c.total = c.total + 1
        if r.learned then c.learned = c.learned + 1 else c.missing = c.missing + 1 end
        if r.unreachable then c.unreachable = c.unreachable + 1 end
        -- how many of these rows have the scroll already: the window's header line counts against the whole job
        -- list, so it must not fall when a search or a pill narrows the view
        if r.held ~= nil then c.held = c.held + 1 end
        -- and how many the server's ledger says are stored. Two facts, two counts: a scroll in a bag is read from
        -- memory, a stored one was asked about, and a player can have either without the other.
        if r.stored then c.stored = c.stored + 1 end
    end
    return c
end

-------------------------------------------------------------------------------
-- Zones: which of a job's missing spells are sourced where the player is standing
-------------------------------------------------------------------------------

-- The two tables spell a zone differently and neither is wrong. The game's own zone table drops every apostrophe
-- ('Port San dOria', 'RuLude Gardens', 'Ifrits Cauldron') because DAT names cannot carry one; spell_sources.lua keeps
-- the wiki's spelling ('Port San d'Oria'); the wiki splits Windurst Waters into 'South' and 'North' halves the game
-- has as one zone; and a past-version page says '(S)'/'[S]'. Every one of the 43 zones the generated table names is
-- one of those four differences, so normalising both sides to a key is the whole join - no zone-id table and no
-- hand-written alias list that would go stale the next time the generator adds a zone.
--
-- Order matters: the apostrophes go first ('Port San d'Oria' has to become one word, not two), then the past-version
-- marker, then Windurst's compass suffix, then whitespace and case. A non-string (nil, a number) is the empty key,
-- which every caller here reads as 'no zone'.
local TYPO_APOSTROPHE = '\226\128\153' -- U+2019, written as bytes so this file stays ASCII

function C.zone_key(name)
    if type(name) ~= 'string' then return '' end
    -- straight apostrophe, typographic apostrophe, backtick
    local s = name:gsub("'", ''):gsub('`', ''):gsub(TYPO_APOSTROPHE, '')
    -- '(S)' and '[S]', case-insensitive, with any spacing inside the brackets or around them, mean the PAST version of
    -- a zone - a different zone from its present-day twin, not a spelling of it. It is kept as a token rather than
    -- dropped: the shipped table has a vendor in The Eldieme Necropolis (S), and dropping the suffix would announce
    -- him to a player standing in the present one. Both spellings of the past marker meet on the same token.
    s = s:gsub('%s*[%(%[]%s*[Ss]%s*[%)%]]%s*$', ' (s)')
    -- 'Windurst Waters South' is 'Windurst Waters' in the game
    s = s:gsub('%s+[Nn][Oo][Rr][Tt][Hh]%s*$', ''):gsub('%s+[Ss][Oo][Uu][Tt][Hh]%s*$', '')
    s = s:gsub('%s+', ' '):match('^%s*(.-)%s*$')
    return s:lower()
end

-- Spell ids arrive as numbers from the game and as strings from a table keyed by id, and one table can hold both.
-- Indexing by number is what makes the two sides of the join in here() meet.
local function id_key(id)
    local n = tonumber(id)
    if n ~= nil then return n end
    return tostring(id)
end

-- The order a zone's own list reads in, and the order the tags are worth: a vendor that always has the scroll first,
-- then the monster that drops it, then the battlefield. Same order the plan fixed, and it is a fact about the table,
-- not about the player, so it belongs here rather than in the window.
local KIND_ORDER = { shop = 1, drop = 2, bcnm = 3 }

-- Where each spell is sourced, grouped by zone. sources is spell_sources.lua's M.spells: keyed by spell id, one row
-- per spell carrying tag/tags/note/zone/src. A row with no zone (160 of the 544 in the shipped table, all AH-only or
-- vendor-less ones) is skipped - it has no place to be announced in, and inventing one is exactly what this table
-- exists to avoid. The result is fresh tables throughout and the argument is only read.
function C.zone_index(sources)
    local out = {}
    if type(sources) ~= 'table' then return out end
    for id, row in pairs(sources) do
        if type(row) == 'table' and type(row.zone) == 'string' and row.zone ~= '' then
            local key = C.zone_key(row.zone)
            if key ~= '' then
                local bucket = out[key]
                if bucket == nil then bucket = {} out[key] = bucket end
                bucket[#bucket + 1] = { id = id_key(id), kind = row.tag, note = row.note, zone = row.zone }
            end
        end
    end
    for _, bucket in pairs(out) do
        table.sort(bucket, function (a, b)
            local ka, kb = KIND_ORDER[a.kind] or 9, KIND_ORDER[b.kind] or 9
            if ka ~= kb then return ka < kb end
            local na, nb = tostring(a.note or ''), tostring(b.note or '')
            if na ~= nb then return na < nb end
            return tostring(a.id) < tostring(b.id)
        end)
    end
    return out
end

-- Only the three ways the request is about can be announced: the AH and quest paths have no zone on their row (the
-- vendor IS the AH), so a kind outside this set is never a place to walk to.
local HERE_KINDS = { shop = true, drop = true, bcnm = true }
-- Rarest find first: a battlefield's scroll is the one you cannot buy, then a monster's drop, then the vendor.
local HERE_ORDER = { bcnm = 1, drop = 2, shop = 3 }

-- The rows a player still needs that this zone sources. rows is a list already built by C.rows, so learnt spells and
-- every filter are the caller's business - this function only joins on spell id, and a zone whose spells are not in
-- rows (already learnt, other jobs, filtered out) yields nothing. kinds is a set ('shop'/'drop'/'bcnm' -> true) so a
-- player can silence one kind; nil means all three. Each hit carries the caller's own row table plus that row's kind,
-- note and zone from the source table, so the window can print the citation without looking anything up again.
-- Nothing is written to index, bucket or rows: the hits are new tables and only the hits are sorted.
function C.here(index, key, rows, kinds)
    local out = {}
    if type(index) ~= 'table' or type(key) ~= 'string' or key == '' then return out end
    local bucket = index[key]
    if type(bucket) ~= 'table' then return out end
    local want = type(kinds) == 'table' and kinds or nil
    local by_id = {}
    if type(rows) == 'table' then
        for i = 1, #rows do
            local row = rows[i]
            if type(row) == 'table' and row.id ~= nil then by_id[id_key(row.id)] = row end
        end
    end
    for i = 1, #bucket do
        local entry = bucket[i]
        if type(entry) == 'table' and HERE_KINDS[entry.kind] and (want == nil or want[entry.kind] == true) then
            local row = by_id[id_key(entry.id)]
            if row ~= nil then
                out[#out + 1] = { row = row, kind = entry.kind, note = entry.note, zone = entry.zone }
            end
        end
    end
    table.sort(out, function (a, b)
        local ka, kb = HERE_ORDER[a.kind] or 9, HERE_ORDER[b.kind] or 9
        if ka ~= kb then return ka < kb end
        return tostring(a.row.name or '') < tostring(b.row.name or '')
    end)
    return out
end

return C
