-- The dice half of the tracker's brain: which corsair dice a player still needs, what each teaches, and what it costs
-- to be told. Nothing here touches vana.*, ui.lua, the file system or a global: the module takes plain tables (the
-- rows out of dice_data.lua, the 224-byte string from vana.game.abilities()) and returns new ones, so the identical
-- code runs inside the client and under a plain `luajit` test.
--
-- A corsair roll is NOT learnt by levelling: each one is taught by a die item, bought or found, and the item's own
-- description prints the COR level it asks for ("COR Lv.49 / Teaches the Phantom Roll ability / \"Fighter's Roll.\"").
-- That is why a die row carries two numbers that look alike and are not: `level` is the COR requirement printed on the
-- die, and `ability_id` is the Phantom Roll ability it teaches, which is the thing the game's own bitfield counts.
local D = {}

-- Where a job ability's bit lives in vana.game.abilities() (docs/addons/04-game-data.md:490-492): weapon skills from
-- bit 0, JOB ABILITIES FROM BIT 0x200 (512), pet commands from 0x400, traits from 0x600. So Phantom Roll, ability 97,
-- is bit 609 of the 224-byte string - not bit 97. Reading the ability id as the bit index would test a weapon skill's
-- bit and mark a player as knowing rolls they have never been taught, so this offset is the whole correctness of
-- `known()`.
local ABILITY_BIT = 512

-- True when the bitset has this ability, false when it does not, and nil when the answer is not knowable: no string
-- yet (nil is what vana.game.abilities() returns until the server has sent it), a bit past the end of the string, or
-- no id at all. The three answers are deliberately distinct - a die row draws a question mark for nil and never the
-- word 'unknown', because "the client would not tell us" is not the same fact as "you do not know this roll".
function D.known(bits, ability_id)
    if type(bits) ~= 'string' then return nil end
    local id = tonumber(ability_id)
    if id == nil then return nil end
    local bit = ABILITY_BIT + math.floor(id)
    local byte = bits:byte(math.floor(bit / 8) + 1)
    if byte == nil then return nil end
    return math.floor(byte / 2 ^ (bit % 8)) % 2 == 1
end

-- the query is split on whitespace and every word has to appear in the die's name OR the roll it teaches, so 'healer'
-- and 'white' both find the White Mage Die; plain find, so a word with a '-' or an apostrophe is not read as a pattern
local function words_of(query)
    local out = {}
    if type(query) ~= 'string' then return out end
    for w in query:lower():gmatch('%S+') do out[#out + 1] = w end
    return out
end

local function name_has(words, text)
    if #words == 0 then return true end
    local n = (text or ''):lower()
    for i = 1, #words do
        if not n:find(words[i], 1, true) then return false end
    end
    return true
end

-- dice_data.lua is keyed by item id, but a caller (a test, a future generator) may hand over the array of rows or the
-- module itself. All three shapes are read; nothing is copied, because rows() only reads.
local function list_of(data)
    local out = {}
    if type(data) ~= 'table' then return out end
    local map = data
    if type(data.dice) == 'table' then map = data.dice end
    if #map > 0 then
        for i = 1, #map do
            if type(map[i]) == 'table' then out[#out + 1] = map[i] end
        end
        return out
    end
    for key, row in pairs(map) do
        if type(row) == 'table' then
            if row.id == nil and tonumber(key) ~= nil then
                local copy = {}
                for k, v in pairs(row) do copy[k] = v end
                copy.id = tonumber(key)
                row = copy
            end
            out[#out + 1] = row
        end
    end
    return out
end

-- level first, then name: a COR reads the list the way they get the dice, cheapest and earliest first. The id is the
-- last tiebreak so two dice at one level never swap places between frames.
local function before(a, b)
    if a.level ~= b.level then return a.level < b.level end
    if a.name ~= b.name then return a.name < b.name end
    return tostring(a.id) < tostring(b.id)
end

-- The dice list for one player. opts:
--   level        the player's COR level; 0 or nil when they are not on COR, and then every row is simply not usable
--   bits         vana.game.abilities() - nil means known-status is unknown, and the row carries known = nil
--   show_known   keep the dice already known (default false: the question is 'what is left')
--   only_now     keep the dice the player can use at this level
--   query        words to look for in the die's name and the roll it teaches
--   held         a map keyed by item id: { [5477] = { bag = 'Inventory', count = 1 } }
--
-- Every row is a new table: the caller may edit it and the data table is untouched. `usable` is the literal
-- level <= opts.level comparison (a die is usable the moment you reach its COR level), and a nil bitset never turns
-- into 'not known' - see D.known.
function D.rows(data, opts)
    opts = opts or {}
    local out = {}
    local level = tonumber(opts.level) or 0
    local show_known = opts.show_known == true
    local only_now = opts.only_now == true
    local words = words_of(opts.query)
    local held = type(opts.held) == 'table' and opts.held or nil
    local list = list_of(data)

    for i = 1, #list do
        local r = list[i]
        local lv = tonumber(r.level) or 0
        local known = D.known(opts.bits, r.ability_id)
        local usable = lv <= level
        local name = tostring(r.name or '')
        if (show_known or known ~= true) and (not only_now or usable)
            and name_has(words, name .. ' ' .. tostring(r.roll or '')) then
            local tags = {}
            for j = 1, #(r.tags or {}) do tags[j] = r.tags[j] end
            local row = {
                id = tonumber(r.id),
                name = name,
                roll = tostring(r.roll or ''),
                ability_id = tonumber(r.ability_id),
                level = lv,
                tag = r.tag,
                tags = tags,
                note = tostring(r.note or ''),
                zone = tostring(r.zone or ''),
                src = tostring(r.src or ''),
                known = known,
                usable = usable,
            }
            local in_bag = held ~= nil and row.id ~= nil and held[row.id] or nil
            if type(in_bag) == 'table' then
                -- copied onto the row for the same reason spells_core copies its held entry: the window must not be
                -- able to edit the map the next rebuild reads
                row.held = { bag = in_bag.bag, count = tonumber(in_bag.count) or 1 }
            end
            out[#out + 1] = row
        end
    end

    table.sort(out, before)
    return out
end

-- The header's numbers. known/missing are counted only where the bitfield answered: a nil-known row is neither
-- known nor missing but `unknown`, so a header can say '19 dice, 3 known, 12 left' and not silently claim a total it
-- could not read. kinds is the per-badge tally (shop 31, ah 0, ...) for the same header or for /spells debug.
function D.counts(rows)
    local c = { total = 0, usable = 0, known = 0, missing = 0, unknown = 0, held = 0, kinds = {} }
    local list = rows or {}
    for i = 1, #list do
        local r = list[i]
        c.total = c.total + 1
        if r.usable then c.usable = c.usable + 1 end
        if r.known == true then c.known = c.known + 1
        elseif r.known == false then c.missing = c.missing + 1
        else c.unknown = c.unknown + 1 end
        if r.held ~= nil then c.held = c.held + 1 end
        local kind = tostring(r.tag or 'none')
        c.kinds[kind] = (c.kinds[kind] or 0) + 1
    end
    return c
end

return D
