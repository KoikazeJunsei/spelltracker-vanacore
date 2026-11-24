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

    for i = 1, #list do
        local sp = list[i]
        if sp ~= nil and sp.jobs ~= nil and not skip[sp.type] then
            local main = C.level_for(sp, opts.job)
            local sub = C.level_for(sp, opts.sub_job)
            -- a spell neither job learns is not this player's list at all; a trust is not a spell anyone learns
            if (main ~= nil or sub ~= nil) and type_ok(pill, sp.type) and name_has(words, sp.name) then
                local learned = C.has_bit(opts.bits, sp.id)
                -- learned rows are hidden by default: the tracker's question is "what is left", and the toggle in the
                -- window is the way back to the full list
                if show_learned or not learned then
                    local row = {
                        id = sp.id,
                        name = sp.name or '',
                        type = sp.type,
                        skill_name = sp.skill_name,
                        mp = sp.mp,
                        element = sp.element,
                        learned = learned,
                        castable = C.castable(sp, {
                            job = opts.job, level = opts.level,
                            sub_job = opts.sub_job, sub_level = opts.sub_level,
                        }),
                        unreachable = not reachable(sp.jobs, cap),
                        -- the level shown is the one the player's own path asks for: the main job's when it learns the
                        -- spell at all, otherwise the subjob's own requirement (not sub_level/2, which is the level the
                        -- player is treated as - showing that would print 17 next to a spell the subjob learns at 34)
                        level = main or sub,
                        via = main ~= nil and 'main' or 'sub',
                    }
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
    local c = { total = 0, learned = 0, missing = 0, unreachable = 0 }
    local list = rows or {}
    for i = 1, #list do
        local r = list[i]
        c.total = c.total + 1
        if r.learned then c.learned = c.learned + 1 else c.missing = c.missing + 1 end
        if r.unreachable then c.unreachable = c.unreachable + 1 end
    end
    return c
end

return C
