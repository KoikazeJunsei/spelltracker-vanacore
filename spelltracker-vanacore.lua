--[[
spelltracker (SpellTracker): what this job can still learn, and where each scroll comes from.

The list is built from the game's own data: the levels are vana.gamedata.spells (VanaCore's table, generated from
CatsEyeXI's sql/spell_list.sql) and whether a spell is known is vana.game.spells(), the game's own 128-byte bitfield.
Nothing here guesses a level, and no vendor note is invented: a spell whose scroll page could not be read shows a
neutral '?' badge that says so. The same list carries the corsair dice, because a roll is learnt the same way a song
is - by using an item - and their known-status is the ability bitfield (vana.game.abilities()).

The tracker's scope is anything a player learns by USING AN ITEM: a scroll, a plate, a die. The learnable kinds are
one table below (KINDS), so a third kind would be a row there and not a new branch in the draw.

In game:

  /spells                  the window on or off
  /spells show | hide      the same, said outright
  /spells minimize         fold the window to a pill (its Play/Stop, Mute, and click-to-restore)
  /spells minimize off     unfold it again
  /spells reset            position, size, the three scales and opacity back to their defaults
  /spells mode ace|cw|wew  which acquisition systems the badges allow (ACE, Crystal Warrior, Wings Era Warrior)
  /spells theme <id>       one of the UI kit's themes; no id lists them
  /spells scale <50-300>   the window's geometry: borders, row heights, every S() measurement
  /spells text <50-300>    the letters on their own, in the same window and the same rows
  /spells pill <50-300>    the minimized capsule on its own
  /spells learned on|off   show the spells and dice already learnt, too
  /spells now on|off       only what this job and level can use this minute
  /spells held on|off      only what already sits in one of your bags (a scroll or a die)
  /spells here             what this job still needs in the zone you are in, with where to get each one
  /spells alerts on|off    the zone-in chime and row highlight on or off (never twice for one zone)
  /spells alerts shop|drop|bcnm on|off   silence one of the three kinds of place
  /spells alerts sound on|off   the soft chime itself, with the highlight left alone
  /spells sync             ask the server for the scroll ledger now (Crystal Warrior: Gramateus / the box)
  /spells rescan           read the bags again now instead of waiting for the cache
  /spells sound on|off     the bell as the window opens
  /spells debug            the row counts, the bags, the ledger and the zone it could read, and the last error, in chat

Click a spell's badge to search the CatsEyeXI database, its Wiki button for BG-Wiki, or double-click the row for the
database. Drag any edge or corner of the window to resize it - the list and its rows follow the size the player gave
it - and drag the card itself to move it. The two scale sliders live in the strip along the bottom, so the readability
knobs are in the window they make readable. The window is drawn with the family's ui.lua kit, so it looks like the
other VanaCore addons and follows the theme, the scale and the controller.
--]]

addon.name    = 'spelltracker-vanacore'
addon.author  = 'koikaze'
addon.version = '0.6.0'
addon.desc    = 'SpellTracker: the spells this job can still learn, with where each one comes from.'

local imgui = vana.imgui
if imgui == nil then
    print('spelltracker-vanacore needs a newer VanaCore.Core.dll (vana.imgui)')
    return
end

local U = require('ui')
local P, F = U.P, U.fonts()
local S = U.S
-- ImGuiWindowFlags_NoResize: the kit lists its flags in order (ui.lua:155 - NoTitleBar 1, NoResize 2, NoScrollbar 8,
-- NoScrollWithMouse 16, NoCollapse 32, NoBackground 128), and the window drops this one to become draggable.
local NO_RESIZE = 2

-- the controller is optional: a mouse-only window beats an addon that fails to load without pad.lua
local PAD = nil
do
    local ok, mod = pcall(require, 'pad')
    if ok and type(mod) == 'table' then PAD = mod end
end

-- spells_core.lua is the pure logic and spell_sources.lua the generated acquisition table. Both are other lanes'
-- files: required softly, so a checkout missing one still opens a window (an empty list) instead of failing to load.
local CORE, DATA, SOURCES = nil, nil, nil
do
    local ok, mod = pcall(require, 'spells_core')
    if ok and type(mod) == 'table' then CORE = mod end
end
do
    local ok, mod = pcall(require, 'spells_data')
    if ok and type(mod) == 'table' then DATA = mod end
end
do
    local ok, mod = pcall(require, 'spell_sources')
    if ok and type(mod) == 'table' then SOURCES = mod end
end

-- scroll_ledger.lua is Trove's generated page table, copied byte-identical because its order must match the
-- server's page layout (the server sends bitmasks, not names, so a reordered table marks the wrong spells). Soft like
-- the others: without it the window still draws, it just has no way to say what is stored.
local LEDGER = nil
do
    local ok, mod = pcall(require, 'scroll_ledger')
    if ok and type(mod) == 'table' and #mod > 0 then LEDGER = mod end
end

-- The corsair dice: dice_core.lua is the pure logic (which die teaches which roll, is it known, what is left) and
-- dice_data.lua the generated acquisition table read off the die pages. Both required softly for the same reason as
-- the spell files: a checkout missing one still opens a window, just with no die rows in the one list.
local DCORE, DDATA = nil, nil
do
    local ok, mod = pcall(require, 'dice_core')
    if ok and type(mod) == 'table' then DCORE = mod end
end
do
    local ok, mod = pcall(require, 'dice_data')
    if ok and type(mod) == 'table' and type(mod.dice) == 'table' then DDATA = mod end
end

-------------------------------------------------------------------------------
-- Settings and state
-------------------------------------------------------------------------------

local DEFAULTS = {
    theme = 'aurora', scale = 100, mode = 'ace', show_learned = false, skill = 'all',
    -- The two scales READABILITY is set with, both independent of the geometry `scale`: text_scale multiplies the font
    -- sizes only (the row rects, the list and the borders stay exactly where they are), and pill_scale moves the
    -- minimized capsule only. Both clamped 50-300 and both per character like everything else, so a Deck and a desk
    -- can read the same window two different ways.
    text_scale = 100, pill_scale = 100,
    -- the two Phase-2 filters: 'usable now' and 'in storage'. Per character like the rest, because a mule and a
    -- main want different answers out of the same window.
    only_now = false, held_only = false,
    -- the zone alerts. One master switch and one per kind of place, so a player who never wants to hear about a
    -- battlefield can keep the vendor notices. zone_sound is the soft chime by itself, for a player who wants the
    -- highlight and not the noise. Per character with everything else.
    zone_alerts = true, alert_shop = true, alert_drop = true, alert_bcnm = true, zone_sound = true,
    x = nil, y = nil, opacity = 100, open_sound = true,
    -- The size the player dragged the window to, or nil for the computed one. nil rather than 880 x 560 on purpose:
    -- a window nobody has resized by hand keeps following /spells scale, and one that has been dragged keeps the size
    -- it was given (its contents still scale inside it).
    w = nil, h = nil,
    -- folded down to the pill. Per character like the rest, so a window folded away comes back as a pill next session
    -- rather than springing open at full size.
    minimized = false,
}

local config = nil
do
    -- the per-character store is what the family uses: two characters can want different modes and window places
    local ok, store = pcall(vana.settings.register, { scope = 'character', defaults = DEFAULTS })
    if ok and type(store) == 'table' and type(store.data) == 'table' then
        config = store
    else
        config = { data = DEFAULTS, save = function () end }
    end
end
local cfg = config.data

local st = {
    open = false, anim = 0,
    query = { '' },
    rows = {}, counts = { total = 0, learned = 0, missing = 0, unreachable = 0, held = 0, stored = 0 },
    cache_key = nil, spells = nil, items = nil,
    last_error = nil, focus_frames = 0,
    -- the bag scan is a separate, slower thing than the row build: it is cached by the clock and versioned, so a
    -- new scan (a scroll moved into the inventory) rebuilds the rows without a keystroke
    scan = nil, scan_at = nil, scan_gen = 0,
    -- the scroll ledger: the last answer's uint32 per page, a generation so a new answer rebuilds the rows, whether
    -- the server refused (non-Crystal-Warrior) and when we last asked (nil = never, the 60 s gate reads it)
    masks = nil, ledger_gen = 0, ledger_locked = false, ledger_at = nil, ledger_asked = false,
    -- whether the window's position has been placed this session: once it has, ImGui owns it and a drag sticks
    pos_placed = false,
    -- The same rule for the SIZE, and one more state: false = nothing placed yet this session, true = placed and left
    -- alone since, nil = folded since it was placed (the ImGui window is wearing the pill's 230 x 34, so coming back
    -- owes it a size). st.size_of is the size that was last asked for, so a change of scale re-places and a drag does
    -- not. st.win_w/win_h are what GetWindowSize answered, for /spells debug.
    size_placed = false, size_of = nil, win_w = nil, win_h = nil,
    -- the footer sliders' values while they are being dragged, one per slider. Not settings: cfg.text_scale and
    -- cfg.pill_scale are written once, on release, so a two-second drag does not save the settings file sixty times
    text_drag = nil, pill_drag = nil,
    -- the zone alerts: the zone index built once from spell_sources, the last zone key that was announced (a Mog House
    -- in-and-out re-raises zone_change with the same zone), the last zone id any event carried (the fallback for
    -- /spells here), the plain row list the alerts read - a second list, so the window's own filters cannot change
    -- what is announced - and the ids of the rows the zone is about, which the row draw reads for its highlight. The
    -- set is rebuilt on every zone-in and emptied by a zone with nothing this job needs.
    zone_idx = nil, last_zone_key = nil, last_zone_id = nil,
    plain_rows = {}, plain_key = nil, here_ids = {},
    -- the zone index built from dice_data, and the dice counts for /spells debug: the one list merges both kinds, but
    -- the debug line still answers 'how many dice are there' separately.
    dice_idx = nil, dice_counts = { total = 0, usable = 0, known = 0, missing = 0, unknown = 0, held = 0, kinds = {} },
    -- folded to the pill. cfg.minimized is what survives the session; this mirror is what the draw reads, so a nil or
    -- hand-edited setting cannot make the first frame's branch disagree with the saved one.
    minimized = cfg.minimized == true,
}

local function say(text) pcall(vana.chat.write, '[Spells] ' .. text, 106) end
local function fail(where, err)
    st.last_error = tostring(where) .. ': ' .. tostring(err)
    pcall(vana.log, 'spelltracker-vanacore ' .. st.last_error)
end
local function save() pcall(function () config:save() end) end

-- the modes and skills the file carries, with the fallbacks the window needs before the file is there
local FALLBACK_MODES = {
    { id = 'ace', label = 'ACE', blurb = 'Every CatsEye system: Wizardoll for Sparks, the Auction House, Ventures and Summit.' },
    { id = 'cw',  label = 'CW',  blurb = 'Self-found: no Auction House and no Wizardoll. Vendors, drops, quests and battlefields only.' },
    { id = 'wew', label = 'WEW', blurb = 'Era character: no Sparks for Wizardoll. The Auction House stays.' },
}
local FALLBACK_SKILLS = {
    { id = 'white', label = 'White' }, { id = 'black', label = 'Black' }, { id = 'song', label = 'Song' },
    { id = 'ninjutsu', label = 'Ninjutsu' }, { id = 'summoning', label = 'Summoning' }, { id = 'blue', label = 'Blue' },
    { id = 'geomancy', label = 'Geomancy' },
}
local UNKNOWN_TAG = { label = 'No source', icon = 'question', color = '#8F97AD', note = 'no acquisition source is recorded for this spell' }

-- Palette KEYS, not colours: P is filled by U.apply_theme and refilled by /spells theme, so a colour captured here
-- at load time would leave the mode pills in the old theme's accent after a switch
local MODE_COLOR = { ace = 'accent', cw = 'ok', wew = 'cyan' }
local SKILL_COLOR = {
    all = 'accent2', white = '#F2F2F2', black = '#8E6BFF', song = '#F0C96A', ninjutsu = '#6E7BD9',
    summoning = '#5CD6C8', blue = '#5BB7FF', geomancy = '#B5D96E',
}
local function pill_colour(keys, id, fallback)
    local c = keys[id]
    if c == nil then return P[fallback] end
    if c:sub(1, 1) == '#' then return c end
    return P[c] or P[fallback]
end

local function modes()
    if DATA and type(DATA.modes) == 'table' and #DATA.modes > 0 then return DATA.modes end
    return FALLBACK_MODES
end
local function skills()
    if DATA and type(DATA.skills) == 'table' and #DATA.skills > 0 then return DATA.skills end
    return FALLBACK_SKILLS
end
local function mode_by_id(id)
    for _, m in ipairs(modes()) do if m.id == id then return m end end
    return nil
end
local function mode_list()
    local names = {}
    for _, m in ipairs(modes()) do names[#names + 1] = m.id end
    return table.concat(names, ', ')
end
local function theme_list()
    local names = {}
    for _, th in ipairs(U.THEMES or {}) do names[#names + 1] = th.id end
    return table.concat(names, ', ')
end

-- a clamped percentage: a hand-edited settings file should not make the window unreadable
local function clamp_pct(n)
    return math.max(50, math.min(300, math.floor(tonumber(n) or 100)))
end
-- the geometry scale: the kit's S() multiplies every measurement by it, and this addon hands it to U.frame each frame
local function scale_pct()
    return clamp_pct(cfg.scale)
end
-- the two readability scales, read the same way and clamped the same way. text_scale has a second source: the footer
-- slider, which holds its own value while it is being dragged (st.text_drag) so the batch of frames between press and
-- release follow it without the settings file being written on every one of them.
local function text_pct()
    return clamp_pct(st.text_drag or cfg.text_scale)
end
local function pill_pct()
    return clamp_pct(st.pill_drag or cfg.pill_scale)
end
-- two sizes are the same size within a pixel: GetWindowSize answers a float, and a rounding difference is not a drag
local function near_size(a, b)
    return a ~= nil and b ~= nil and math.abs(tonumber(a) - tonumber(b)) < 1
end

-- The kit's font sizes, read through ONE shim: T.body is 15 at text_scale 100 and 30 at 200, and that holds for the
-- kit's own defaults too (U.toggle reads T.small inside ui.lua, so a copy of the table would leave the toggle labels
-- at 13 px while the rows beside them doubled). The metatable therefore goes on the table itself, with the numbers
-- moved out from under it - a metatable's __index is only consulted for a key the table does NOT hold, so scaling in
-- place would never fire. Nothing positional is affected: every measurement is S(n), which this does not touch.
-- Guarded twice (no ui.sizes, a table that refuses a metatable): the window then draws at the kit's own sizes rather
-- than failing to load.
local T_RAW = { title = 30, h1 = 22, h2 = 17, body = 15, small = 13, tiny = 11 }
local T = T_RAW
do
    local ok, sizes = pcall(U.sizes)
    if ok and type(sizes) == 'table' then
        -- a RELOAD lands here again, on a table that already has this metatable and therefore no numbers of its own:
        -- taking the snapshot a second time through pairs() would find nothing and leave every size nil, which is a
        -- frame that cannot measure a word. The numbers are carried ON the metatable, so a second session reuses them.
        local raw = nil
        local have = getmetatable(sizes)
        if type(have) == 'table' and type(have.raw) == 'table' then raw = have.raw end
        if raw == nil then
            raw = {}
            for k, v in pairs(sizes) do raw[k] = v end
            for k in pairs(raw) do sizes[k] = nil end
        end
        local made = pcall(setmetatable, sizes, {
            raw = raw,
            __index = function (_, k)
                local v = raw[k]
                if type(v) == 'number' then return v * text_pct() / 100 end
                return v
            end,
        })
        if made then
            T, T_RAW = sizes, raw
        elseif have == nil then
            for k, v in pairs(raw) do sizes[k] = v end -- put back what we took out: the kit still needs its numbers
        end
    end
end
local function opacity()
    local n = tonumber(cfg.opacity) or 100
    return math.max(30, math.min(100, n)) / 100
end

-- the addon folder, for the bell; vana.paths.addon is a field, so it is read under pcall like every other risky call
local function addon_dir()
    local ok, dir = pcall(function () return vana.paths.addon end)
    return ok and type(dir) == 'string' and dir or nil
end

-- The folder's two sounds: small_bell.wav is the window's opening bell, tiny_bell.wav the softer one the zone-in
-- chime uses. Both go through the same guarded path: no addon folder, no file, no sound, and no error either way.
local BELL_OPEN = '\\sounds\\small_bell.wav'
local BELL_ZONE = '\\sounds\\tiny_bell.wav'

local function play_sound(file)
    local dir = addon_dir()
    if dir == nil then return false end
    local path = dir .. file
    local ok, here = pcall(vana.fs.exists, path)
    if ok and here then
        pcall(vana.system.play_sound, path)
        return true
    end
    return false
end

local function play_bell() play_sound(BELL_OPEN) end
local function play_chime() play_sound(BELL_ZONE) end

-- the game's own name for a job, and the kit's table when the game data isn't there (a client without DATs)
local function job_short(job)
    job = tonumber(job) or 0
    if job > 0 then
        local ok, row = pcall(function () return vana.gamedata.jobs[job] end)
        if ok and type(row) == 'table' and type(row.short) == 'string' and row.short ~= '' then return row.short end
    end
    return U.JOBS[job] or '???'
end

local function current_player()
    local me = { job = 0, level = 0, sub_job = 0, sub_level = 0 }
    local ok, p = pcall(vana.game.player)
    if ok and type(p) == 'table' then
        me.job = tonumber(p.main_job) or 0
        me.level = tonumber(p.main_job_level) or 0
        me.sub_job = tonumber(p.sub_job) or 0
        me.sub_level = tonumber(p.sub_job_level) or 0
    end
    -- before the server's table has filled in, the game's own self read has the same numbers
    if me.job <= 0 then
        local ok2, _, _, job, level, subjob, sublevel = pcall(vana.game.self)
        if ok2 then
            me.job = tonumber(job) or 0
            me.level = tonumber(level) or 0
            me.sub_job = tonumber(subjob) or 0
            me.sub_level = tonumber(sublevel) or 0
        end
    end
    return me
end

local function game_bits()
    local ok, bits = pcall(vana.game.spells)
    if ok and type(bits) == 'string' and #bits > 0 then return bits end
    return nil
end

-- The game's own ABILITY bitfield (224 bytes), which is where a learnt corsair roll is counted: a job ability's bit is
-- 0x200 + its id (docs/addons/04-game-data.md:490-492), while weapons skills start at bit 0. A separate read from
-- game_bits() on purpose - the spell bitfield cannot answer this question at all - and nil until the server has sent
-- it, which dice_core reads as 'unknown' rather than 'not known'.
local function ability_bits()
    local ok, bits = pcall(vana.game.abilities)
    if ok and type(bits) == 'string' and #bits > 0 then return bits end
    return nil
end

local COR_JOB = 17

-- How the player's own jobs reach the dice, or nil when they do not. Dice follow the same rule spells do, read off
-- the same current_player() the spell list uses and never off a setting:
--   COR main -> the die at its printed COR level, usable from that level
--   COR sub  -> usable at half the sub level (floored), and flagged: learning a die needs COR main
--   neither  -> no die rows at all
-- A main job with level 0 (the character-select state) is not a COR the list can speak for, so it is nil too.
local function cor_scope(me)
    if type(me) ~= 'table' then return nil end
    local job = tonumber(me.job) or 0
    local level = tonumber(me.level) or 0
    local sub_job = tonumber(me.sub_job) or 0
    local sub_level = tonumber(me.sub_level) or 0
    if job == COR_JOB and level > 0 then return { level = level, via = 'main' } end
    if sub_job == COR_JOB and sub_level > 0 then
        return { level = math.floor(sub_level / 2), via = 'sub' }
    end
    return nil
end

-- the spell table is large and can be absent on a client with no game data: read it once, and only when the list is
-- about to be built. A nil answer is retried next frame rather than latched: vana.gamedata loads a table on first
-- touch, and a one-shot latch would leave the window empty for the whole session if that first touch came too early.
local function spell_table()
    if st.spells ~= nil then return st.spells end
    local ok, t = pcall(function () return vana.gamedata.spells end)
    if ok and type(t) == 'table' then st.spells = t end
    return st.spells
end

-- spells_core walks its list by index, while the game data is documented as a table keyed by spell id. When the
-- table is already a sequence (the shipped one is: [1] to [n] with an id field each) it is used as it is; a keyed
-- table is turned into one array, in id order, once.
local function spell_array(t)
    if #t > 0 then return t end
    if st.spell_array_of == t then return st.spell_array end
    local list = {}
    for id, sp in pairs(t) do
        if type(sp) == 'table' then
            if sp.id == nil then
                local copy = { id = id }
                for k, v in pairs(sp) do copy[k] = v end
                sp = copy
            end
            list[#list + 1] = sp
        end
    end
    table.sort(list, function (a, b) return (a.id or 0) < (b.id or 0) end)
    st.spell_array_of, st.spell_array = t, list
    return list
end

-- The learnable kinds. The tracker's scope is anything a player learns by USING AN ITEM, which is why a die (learnt
-- by using the die) and a song's scroll (learnt by using the scroll) are both in here. A row is: the generated
-- acquisition table, the client read that answers "do I know it" (the 128-byte spell bitfield, and the ability
-- bitfield at 0x200 + the ability id for a roll), an optional job scope, and the builder that turns the game's own
-- table into rows. The list builder below walks this table, so a third kind (a pet charm, an instrument) is a row
-- here - its table and its bitfield - and not a new branch in the draw.
local KINDS = {
    {
        id = 'spell',
        -- spell_sources.lua's generated map, keyed by spell id
        sources = function () return SOURCES end,
        known = function () return game_bits() end,
        rows = function (opts)
            if CORE == nil or type(CORE.rows) ~= 'function' then return nil end
            local spells = spell_table()
            if spells == nil then return nil end
            return CORE.rows(spell_array(spells), opts)
        end,
    },
    {
        id = 'die',
        -- dice_data.lua's generated table, keyed by the die's item id
        sources = function () return DDATA end,
        -- dice_core.known does the 0x200 offset; nil bits stay UNKNOWN and keep the row visible
        known = function () return ability_bits() end,
        scope = cor_scope,
        rows = function (opts)
            if DCORE == nil or type(DCORE.rows) ~= 'function' or DDATA == nil then return nil end
            if opts.scope == nil then return {} end
            return DCORE.rows(DDATA.dice, opts)
        end,
    },
}
local KIND_ORDER = { 'spell', 'die' }

-------------------------------------------------------------------------------
-- What is in the bags
-------------------------------------------------------------------------------

-- The client's own 18 containers in its own order, copied from docs/addons/04-game-data.md:518-532. It stops at 17
-- on purpose: the client's Container enum ends there and its container_item rejects anything above it, so probing
-- 18 and up would only ever answer nil - a longer loop would read as "there might be more bags", and there are not.
local BAG_NAME = {
    [0] = 'Inventory', 'Mog Safe', 'Storage', 'Temporary items', 'Mog Locker', 'Mog Satchel', 'Mog Sack', 'Mog Case',
    'Mog Wardrobe', 'Mog Safe 2', 'Mog Wardrobe 2', 'Mog Wardrobe 3', 'Mog Wardrobe 4', 'Mog Wardrobe 5',
    'Mog Wardrobe 6', 'Mog Wardrobe 7', 'Mog Wardrobe 8', 'Recycle Bin',
}
local BAG_LAST = 17
-- four seconds: long enough that walking through a zone does not re-read 18 bags every frame, short enough that a
-- scroll picked up in the last fight shows up while the player is still looking at the list
local SCAN_SECONDS = 4
-- the marker a row wears when its scroll is in a bag. 'bag-shopping' is the honest glyph, but ui.lua's FA table is
-- generated and this copy has no bag entry; fa() quietly substitutes the question mark for a name it does not know,
-- so the choice is probed against that fallback rather than assumed.
local BAG_ICON = 'sack-dollar'
do
    local ok_a, a = pcall(U.fa, 'bag-shopping')
    local ok_q, q = pcall(U.fa, 'question')
    if ok_a and ok_q and type(a) == 'string' and a ~= q then BAG_ICON = 'bag-shopping' end
end
-- the marker for a scroll the server's ledger says is stored at Gramateus or in the box. Same probe, one more step
-- down the list ('vault', then 'box-archive', then the plain 'archive'): this copy of the kit's FA table has neither
-- of the first two, and fa() answers an unknown name with the question mark, which is why each name is compared
-- against that answer instead of being assumed to exist.
local VAULT_ICON = 'archive'
do
    local ok_q, q = pcall(U.fa, 'question')
    local names = { 'vault', 'box-archive' }
    if ok_q and type(q) == 'string' then
        for i = 1, #names do
            local ok_n, g = pcall(U.fa, names[i])
            if ok_n and type(g) == 'string' and g ~= q then VAULT_ICON = names[i] break end
        end
    end
end

-- item id -> name, or false where the client had none: a bag holds item ids, and the same scroll sits in the same
-- slot every scan, so the name is looked up once per item per session rather than once per bag slot per scan
local ITEM_NAME = {}

local function item_table()
    if st.items ~= nil then return st.items end
    -- vana.gamedata.items loads in 4,096-id parts on first touch; a nil answer here is "not yet", so it is retried
    -- on the next scan rather than latched for the session
    local ok, t = pcall(function () return vana.gamedata.items end)
    if ok and type(t) == 'table' then st.items = t end
    return st.items
end

local function item_name(items, id)
    local hit = ITEM_NAME[id]
    if hit ~= nil then
        if hit == false then return nil end
        return hit
    end
    local name = nil
    -- log_name, not name: an item's `name` is the bare thing ('Utsusemi: Ichi', 'Holy'), and only `log_name` carries
    -- the 'scroll of' / 'plate of' the scroll test needs (item 4629: name="Holy", log_name="scroll of Holy"). Reading
    -- `name` here made every scroll look like a piece of gear, so no row was ever marked - the fake fixture in the
    -- tests said 'Scroll of Cure IV' and the shipped table says 'scroll of' in lower case on the log name.
    -- The table is paged and generated: one bad id must cost that item, not the whole bag.
    local ok, row = pcall(function () return items[id] end)
    if ok and type(row) == 'table' then
        if type(row.log_name) == 'string' and row.log_name ~= '' then name = row.log_name
        elseif type(row.name) == 'string' and row.name ~= '' then name = row.name end
    end
    ITEM_NAME[id] = name or false
    return name
end

-- The ephemeral box is not in the client's container set, so a memory scan cannot see it however far this loop runs:
-- the Container enum ends at 17 (abi.hpp:1198) and CatsEyeXI's own Trove reads the box out of the synthesis packet
-- rather than a bag (legacy/ashita/addons/trove/core/crafting.lua:780). It can only be ASKED about - this file asks
-- with the scroll ledger's 0x1A4 summary (below), which answers for Gramateus and the box together - so nothing in
-- this bag walk claims anything about either store, and a row marked from the ledger says so in its own tooltip.
-- Do not 'fix' this by adding an id to the loop.
--
-- Reads every bag the character owns and turns the scrolls among them into spells_core.held()'s map. The whole walk
-- is inside one pcall: a client without containers, a bag that errors mid-walk and a character at the select screen
-- all have to leave the window drawing with no held rows, never raising into the frame that asked.
local function scan_bags()
    local now = 0
    do
        local ok, t = pcall(U.clock)
        if ok and tonumber(t) then now = t end
    end
    if st.scan ~= nil and st.scan_at ~= nil and (now - st.scan_at) < SCAN_SECONDS then return st.scan end
    st.scan_at = now

    local scan = { at = now, slots = {}, bags_read = {}, held = {} }
    local items = item_table()
    local walked, walk_err = pcall(function ()
        for id = 0, BAG_LAST do
            local ok_bag, bag = pcall(vana.game.container, id)
            -- nil is the ordinary answer for a bag this character does not own; capacity 1 is a bag holding nothing
            -- but its reserved slot 0
            if ok_bag and type(bag) == 'table' then
                local cap = tonumber(bag.capacity) or 0
                if cap >= 2 then
                    scan.bags_read[#scan.bags_read + 1] = id
                    for slot = 1, cap - 1 do
                        local s = bag[slot]
                        if type(s) == 'table' and s.id ~= nil and s.id ~= 0 then
                            local name = nil
                            if items ~= nil then name = item_name(items, s.id) end
                            if name ~= nil then
                                -- the id rides along for the die rows: a die is matched by its item id, not by its
                                -- name (spells_core.held reads name/bag/count and ignores the extra field)
                                scan.slots[#scan.slots + 1] = {
                                    name = name, id = s.id, bag = BAG_NAME[id] or ('bag ' .. tostring(id)),
                                    count = tonumber(s.count) or 1,
                                }
                            end
                        end
                    end
                end
            end
        end
    end)
    if not walked then fail('scan', walk_err) end

    if CORE ~= nil and type(CORE.held) == 'function' then
        local ok_held, held = pcall(CORE.held, scan.slots)
        if ok_held and type(held) == 'table' then scan.held = held end
    end
    st.scan = scan
    st.scan_gen = (st.scan_gen or 0) + 1
    st.cache_key = nil
    return scan
end

local function held_count(map)
    local n = 0
    if type(map) == 'table' then for _ in pairs(map) do n = n + 1 end end
    return n
end

-- the bags this scan could read, as ids and names, for /spells debug: the answer to "is the bag I put the scroll in
-- even being read", which is the one question a player can act on
local function bag_list(scan)
    local names = {}
    for i = 1, #((scan and scan.bags_read) or {}) do
        local id = scan.bags_read[i]
        names[#names + 1] = tostring(id) .. ' ' .. tostring(BAG_NAME[id] or '?')
    end
    if #names == 0 then return 'none' end
    return table.concat(names, ', ')
end

-------------------------------------------------------------------------------
-- The scroll ledger (Trove's 0x1A4 tab summary)
-------------------------------------------------------------------------------

-- The protocol, read off legacy/ashita/addons/trove/plugins/scrolls.lua:30-46 (request) and :326-348 (answer):
--   request  0x1A4, 64 bytes, byte 5 = 13 (C2S_TAB_SUMMARY), byte 7 = 2 (TAB_SOURCE_SCROLLS), sent once
--   answer   action 12 (S2C_TAB_SUMMARY), byte 6 = page count, byte 7 = source (must be 2),
--            then page-count little-endian uint32s from byte 9; bit b = entry b+1 of that page is stored
--   action 4 (S2C_LOCKED)  the answer to a character that is not a Crystal Warrior: the ledger is CW only
-- That is ONE packet for the whole store, which is why it beats a per-scroll chat query. It costs `sends_packets` in
-- the policy scan (tools/addon_vet/scan.py), the same class of addon Trove is, and docs/addons/10-packets.md:120 is
-- the citation for the rule that matters: the server treats an injected packet as the player's.
local PACKET_LEDGER = 0x1A4
local C2S_TAB_SUMMARY = 13
local S2C_TAB_SUMMARY = 12
local S2C_LOCKED = 4
local TAB_SOURCE_SCROLLS = 2
-- one ask a minute. The answer only changes when the player stores a scroll, and nothing here is worth a packet per
-- frame; /spells sync is the way past the gate when the player knows it has changed.
local LEDGER_SECONDS = 60

-- the client's clock, or nil when it cannot be read: every gate below treats a nil clock as "do not ask", which
-- costs a marker rather than a packet loop
local function clock_now()
    local ok, t = pcall(U.clock)
    if ok and tonumber(t) then return tonumber(t) end
    return nil
end

local function ledger_payload()
    local b = {}
    for i = 1, 64 do b[i] = 0 end
    b[5] = C2S_TAB_SUMMARY
    b[7] = TAB_SOURCE_SCROLLS
    local out = {}
    for i = 1, 64 do out[i] = string.char(b[i]) end
    return table.concat(out)
end

-- Returns true when a request actually went out. Refuses, never raises: no LEDGER (a checkout without the table),
-- a locked ledger, no packets surface, no character in the world, and the 60 s gate unless force is set.
local function request_ledger(force)
    if type(LEDGER) ~= 'table' or #LEDGER < 1 then return false end
    if st.ledger_locked then return false end
    local pk = nil
    do
        local ok, t = pcall(function () return vana.packets end)
        if ok then pk = t end
    end
    if type(pk) ~= 'table' or type(pk.inject) ~= 'function' then return false end
    local me = current_player()
    if me == nil or (tonumber(me.job) or 0) <= 0 then return false end
    local now = clock_now()
    if not force then
        if now == nil then return false end
        if st.ledger_at ~= nil and (now - st.ledger_at) < LEDGER_SECONDS then return false end
    end
    -- The call is written out rather than taken out of pk: tools/addon_vet/scan.py matches the symbol, and an addon
    -- that sends packets has to show up as one in the policy scan instead of slipping past it. The pcall is what
    -- keeps a client without the surface from raising into the frame that opened the window.
    local ok_send, err = pcall(function ()
        vana.packets.inject(false, PACKET_LEDGER, ledger_payload())
    end)
    if not ok_send then
        -- recorded as asked anyway: a failing inject that is retried every frame is a tight loop into the game
        fail('ledger', err)
        if now ~= nil then st.ledger_at = now end
        return false
    end
    st.ledger_at = now
    st.ledger_asked = true
    return true
end

-- The masks out of one answer, or nil where the payload is not a complete answer. nil is not an error and not an
-- empty answer: the caller leaves the last good masks in place, because a half-read packet that blanked them would
-- mark every stored scroll as missing.
local function ledger_masks(data)
    if type(data) ~= 'string' or #data < 9 then return nil end
    if data:byte(5) ~= S2C_TAB_SUMMARY then return nil end
    if data:byte(7) ~= TAB_SOURCE_SCROLLS then return nil end
    local count = data:byte(6)
    if count == nil then return nil end
    local masks = {}
    local pos = 9
    for i = 1, count do
        local b1, b2, b3, b4 = data:byte(pos, pos + 3)
        if b1 == nil or b2 == nil or b3 == nil or b4 == nil then return nil end
        masks[i] = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
        pos = pos + 4
    end
    return masks
end

-- One packet_in handler for 0x1A4, called inside a pcall: a malformed payload has to leave the window drawing.
-- e.data is the packet as a string with its 4-byte header first (docs/addons/10-packets.md:37-50); an id VanaCore
-- has no field table for can arrive with e.data nil, so the last buffer of the same id is parsed instead.
local function ledger_packet(e)
    if type(e) ~= 'table' or e.id ~= PACKET_LEDGER then return end
    local data = e.data
    if type(data) ~= 'string' then
        -- the fallback is inside its own pcall so a client without the packets surface records nothing: this runs in
        -- a packet handler, and a raise here would be the handler's fault, not the packet's
        local got, last = pcall(function () return vana.packets.last(true, PACKET_LEDGER) end)
        if got and type(last) == 'string' then data = last end
    end
    if type(data) ~= 'string' or #data < 7 then return end
    if data:byte(5) == S2C_LOCKED then
        -- said once: the server repeats this answer to every ask, and the addon stops asking after the first
        if not st.ledger_locked then
            st.ledger_locked = true
            say('the scroll ledger is Crystal Warrior only: nothing will be marked as stored')
        end
        return
    end
    local masks = ledger_masks(data)
    if masks == nil then return end
    st.masks = masks
    st.ledger_gen = (st.ledger_gen or 0) + 1
    st.cache_key = nil
end

-------------------------------------------------------------------------------
-- The rows
-------------------------------------------------------------------------------

-- The spell list's own order is the base and never changes: dice are inserted where their printed level belongs,
-- after every spell of the same or a lower level, so a list with no dice is exactly the list spells_core built.
local function merge_rows(spells, dice)
    if dice == nil or #dice == 0 then return spells end
    local out = {}
    local j = 1
    for i = 1, #dice do
        local lv = tonumber(dice[i].level) or 0
        while j <= #spells and (tonumber(spells[j].level) or 0) <= lv do
            out[#out + 1] = spells[j]
            j = j + 1
        end
        out[#out + 1] = dice[i]
    end
    while j <= #spells do
        out[#out + 1] = spells[j]
        j = j + 1
    end
    return out
end

-- One count for the one list. A spell's learned flag and a die's known flag are the same fact under two names, and a
-- die the client has not answered for is neither learned nor missing (its row is still listed, with a question mark).
local function count_rows(rows)
    local c = { total = 0, learned = 0, missing = 0, unreachable = 0, held = 0, stored = 0 }
    for i = 1, #rows do
        local r = rows[i]
        c.total = c.total + 1
        if r.kind == 'die' then
            if r.known == true then c.learned = c.learned + 1
            elseif r.known == false then c.missing = c.missing + 1 end
        else
            if r.learned then c.learned = c.learned + 1 else c.missing = c.missing + 1 end
            if r.unreachable then c.unreachable = c.unreachable + 1 end
        end
        if r.held ~= nil then c.held = c.held + 1 end
        if r.stored then c.stored = c.stored + 1 end
    end
    return c
end

-- item id -> the bag and count, out of the scan's own slots. The bag scan records each slot's name, count, bag and
-- item id, which is the only key a die can be matched on: 'Warrior Die' is an item's name, never a scroll's, and two
-- dice can share a word ('Corsair Die' / 'Corsair's Roll') without sharing an id.
local function dice_held(scan)
    local out = {}
    local slots = (scan and scan.slots) or {}
    for i = 1, #slots do
        local s = slots[i]
        if type(s) == 'table' and s.id ~= nil then
            local e = out[s.id]
            if e == nil then
                out[s.id] = { bag = s.bag, count = tonumber(s.count) or 1 }
            else
                e.count = e.count + (tonumber(s.count) or 1)
            end
        end
    end
    return out
end

-- rebuilding is keyed on everything that can change a row: the character's jobs, both bitfields, the filters. Typing
-- in the search box thus costs one rebuild per keystroke, not one per frame. The scan generation is in the key because
-- a new bag scan changes row.held without changing anything else; the job scope is in it because COR main, COR sub
-- and no COR at all are three different lists.
--
-- One builder, two lists. `plain` is the zone alerts' list: the same rows with the view's own filters OFF (nothing
-- learnt, no search, no skill pill, no 'usable now', no 'in storage'), because a search box is a way of looking at
-- the list and never a claim about what the player still needs - announcing 'Lower Jeuno: {the one spell matching
-- your query}' would be a lie about the zone. Each list keeps its own cache key, so one build never blanks the other.
local function rebuild(me, scan, plain)
    local view = plain ~= true
    local held = (scan and scan.held) or nil
    local scope = cor_scope(me)
    -- every kind reads its own bitfield, so the true answer to "do I know it" travels with the kind rather than
    -- being threaded through each caller
    local bits = {}
    for i = 1, #KIND_ORDER do
        local k = KINDS[i]
        bits[k.id] = k.known()
    end
    local key = table.concat({
        view and 'view' or 'plain',
        me.job, me.level, me.sub_job, me.sub_level,
        tostring(cfg.mode), tostring(view and cfg.show_learned == true),
        tostring(view and cfg.skill or 'all'), (view and st.query[1]) or '',
        bits.spell or '', bits.die or '',
        tostring(scope and scope.level or 'no'),
        tostring(view and cfg.only_now == true), tostring(view and cfg.held_only == true),
        tostring(st.scan_gen or 0),
        -- the generation, not just the page count: a second answer with the same 19 pages is a different answer,
        -- and a same-shaped one (a scroll stored today) would otherwise leave yesterday's markers on the rows
        tostring(st.ledger_gen or 0),
    }, '|')
    if view then
        if key == st.cache_key then return end
        st.cache_key = key
        st.rows = {}
        st.counts = { total = 0, learned = 0, missing = 0, unreachable = 0, held = 0, stored = 0 }
    else
        if key == st.plain_key then return end
        st.plain_key = key
        st.plain_rows = {}
    end

    local data = DATA or { modes = {}, tags = {}, skills = {}, skip_types = {}, level_cap = 75 }
    -- spells_core reads sources by spell id, so it wants the generated map, not the module around it
    local sources = (SOURCES and type(SOURCES.spells) == 'table') and SOURCES.spells or {}
    local cap = tonumber(data.level_cap) or 75
    local mode = mode_by_id(cfg.mode)
    -- the ledger's answer, folded into a name set. nil (no table, no answer yet) is passed as nil on purpose: an
    -- empty set would be a claim that nothing is stored, and spells_core can tell the two apart
    local stored = nil
    if type(LEDGER) == 'table' and type(st.masks) == 'table' and CORE ~= nil and type(CORE.ledger_stored) == 'function' then
        local ok_l, set = pcall(CORE.ledger_stored, LEDGER, st.masks)
        if ok_l and type(set) == 'table' then stored = set end
    end
    local bags_of_dice = dice_held(scan)

    -- One build, every kind, one merged list. `show_learned` is the same toggle for a spell and for a die, because
    -- the question the window asks is the same: what is left to learn. The spell rows keep spells_core's own order
    -- (castable first, then level, then name); only the dice are placed, and merge_rows leaves a spell-only list
    -- exactly as it was.
    local function build(show_learned, query, only_now, skill)
        local spell_opts = {
            job = me.job, level = me.level, sub_job = me.sub_job, sub_level = me.sub_level,
            bits = bits.spell, show_learned = show_learned, query = query, skill = skill,
            mode = cfg.mode, data = data, sources = sources, cap = cap, held = held,
            only_now = only_now, stored = stored,
        }
        local die_opts = {
            level = scope and scope.level or 0, scope = scope, bits = bits.die, held = bags_of_dice,
            show_known = show_learned, only_now = only_now, query = query,
        }
        local spell_rows, dice_rows = {}, {}
        for i = 1, #KIND_ORDER do
            local k = KINDS[i]
            local opts = (k.id == 'die') and die_opts or spell_opts
            local ok_k, rows = pcall(k.rows, opts)
            if not ok_k then
                fail(k.id == 'die' and 'dice' or 'rows', rows)
                rows = {}
            end
            if type(rows) ~= 'table' then rows = {} end
            if k.id == 'die' then dice_rows = rows else spell_rows = rows end
        end
        for i = 1, #spell_rows do spell_rows[i].kind = 'spell' end
        for i = 1, #dice_rows do
            local r = dice_rows[i]
            r.kind = 'die'
            if scope ~= nil then r.via = scope.via end
            -- The badge is spells_core's own: the die's source row is the same shape spell_sources hands over
            -- (tag/tags/note/src), so the mode's hide list filters a die exactly as it filters a shop scroll, and no
            -- second mode rule exists to drift from the first.
            if CORE ~= nil and type(CORE.badge) == 'function' then
                local ok_b, tag, note, src, entry = pcall(CORE.badge, r, data, DDATA and DDATA.dice or {}, mode)
                if ok_b then r.tag, r.note, r.src, r.badge = tag, note, src, entry end
            end
        end
        return merge_rows(spell_rows, dice_rows), dice_rows
    end

    -- the counts are the whole job's list, not the filtered view: '12 to learn' should not fall when a search narrows
    -- the view, and the header's bag count is counted against the same list for the same reason (a filter must not
    -- look as if the scrolls left the bags)
    if view then
        local all, dice_all = build(true, nil, false, nil)
        st.counts = count_rows(all)
        if DCORE ~= nil and type(DCORE.counts) == 'function' then
            local ok_c, counts = pcall(DCORE.counts, dice_all)
            if ok_c and type(counts) == 'table' then st.dice_counts = counts end
        end
    end

    local skill = nil
    if view and cfg.skill ~= nil and cfg.skill ~= 'all' then skill = cfg.skill end
    local rows = build(view and cfg.show_learned == true, (view and st.query[1] ~= '') and st.query[1] or nil,
        view and cfg.only_now == true or false, skill)
    -- 'in storage' is the window's own filter, not a core one: it is one pass over the rows just built and sorted, so
    -- the order the player sees is untouched. A die's held entry is the same shape as a scroll's, so the one rule
    -- covers both kinds.
    if view and cfg.held_only == true then
        local with_item = {}
        for i = 1, #rows do
            if rows[i].held ~= nil then with_item[#with_item + 1] = rows[i] end
        end
        rows = with_item
    end
    if view then st.rows = rows else st.plain_rows = rows end
end

-- Both lists from one scan. Every caller that rebuilt the spells' rows also wants the dice's (a frame, /spells
-- rescan, /spells debug): a list one edit behind the game is exactly the bug the cache key exists to prevent, and
-- two calls in three places is one call forgotten in the fourth.
local function refresh_rows(me, scan)
    rebuild(me, scan)
end

local function scroll_name(row)
    -- geomancy scrolls are plates; every other spell is a scroll
    return ((row.type == 'geomancy') and 'Plate of ' or 'Scroll of ') .. tostring(row.name or '')
end

local function row_urls(row)
    if CORE == nil or type(CORE.urls) ~= 'function' then return nil end
    local ok, urls = pcall(CORE.urls, tostring(row.name or ''), scroll_name(row))
    if ok and type(urls) == 'table' then return urls end
    return nil
end

-- A die's own BG-Wiki page is the citation its row was generated from, so its Wiki button opens that page; its badge
-- searches the database by the die's item name, which is what the site knows it by.
local function die_urls(row)
    if CORE == nil or type(CORE.urls) ~= 'function' then return nil end
    local name = tostring(row.name or '')
    local ok, urls = pcall(CORE.urls, name, name)
    if ok and type(urls) == 'table' then return urls end
    return nil
end

-- open_url says whether it started the browser; where it did not, the link still reaches the player on the clipboard
local function open_link(url)
    if type(url) ~= 'string' or url == '' then
        U.toast('warn', 'No link', 'this row has no address to open', 4, 'circle-info')
        return
    end
    local ok, opened = pcall(vana.system.open_url, url)
    local shown = url:gsub('^https?://', '')
    if ok and opened then
        U.toast('info', 'Opened in your browser', shown, 3, 'arrow-right')
    else
        pcall(vana.system.set_clipboard, url)
        U.toast('info', 'Link copied', shown, 4, 'circle-check')
    end
end

local function open_database(row)
    local urls = row.kind == 'die' and die_urls(row) or row_urls(row)
    open_link(urls and urls.database or nil)
end

local function open_wiki(row)
    if row.kind == 'die' then
        open_link(row.src)
        return
    end
    local urls = row_urls(row)
    open_link(urls and urls.wiki or nil)
end

-------------------------------------------------------------------------------
-- Zone alerts
-------------------------------------------------------------------------------

-- Where the generated source table says each spell's scroll is sold, dropped or fought for, grouped by zone key.
-- Built once (lazily: a session that never zones in costs nothing) and latched, because spell_sources.lua cannot
-- change while the addon is loaded. Every failure - no CORE, no SOURCES, a CORE.zone_index that raises or answers
-- something that is not a table - is 'no zones to announce', never an error the player sees: the window still draws.
local function zone_index()
    if type(st.zone_idx) == 'table' then return st.zone_idx end
    if CORE == nil or type(CORE.zone_index) ~= 'function' then return nil end
    if SOURCES == nil or type(SOURCES.spells) ~= 'table' then return nil end
    local ok, idx = pcall(CORE.zone_index, SOURCES.spells)
    if not ok then
        fail('zones', idx)
        return nil
    end
    if type(idx) ~= 'table' then return nil end
    st.zone_idx = idx
    return idx
end

-- The game's own name for a zone id. nil for everything that is not one: no vana.gamedata (a client without DATs),
-- an id past the table, id 0 ('unknown'), and a zone the table has no name for all cost the alert and nothing else.
local function zone_name(id)
    local zone = tonumber(id)
    if zone == nil or zone <= 0 then return nil end
    local ok, row = pcall(function () return vana.gamedata.zones[zone] end)
    if ok and type(row) == 'table' and type(row.name) == 'string' and row.name ~= '' and row.name ~= 'unknown' then
        return row.name
    end
    return nil
end

-- Both tables spell a zone differently (the game drops apostrophes, the wiki splits Windurst Waters into halves), so
-- the join is on C.zone_key. Guarded like every other call into CORE.
local function zone_key_of(name)
    if CORE == nil or type(CORE.zone_key) ~= 'function' then return '' end
    local ok, key = pcall(CORE.zone_key, name)
    if ok and type(key) == 'string' then return key end
    return ''
end

-- The three kinds the request covers, as C.here() wants them: the per-kind switches this character has set. An
-- empty set is not an error - it is a player who silenced every kind, and C.here answers nothing.
local function alert_kinds()
    local kinds = {}
    if cfg.alert_shop == true then kinds.shop = true end
    if cfg.alert_drop == true then kinds.drop = true end
    if cfg.alert_bcnm == true then kinds.bcnm = true end
    return kinds
end

-- How many spells the source table places in this zone at all, for /spells debug and for the 'nothing here' answer:
-- the number that tells a player whether the zone was looked at or simply has no entry.
local function zone_sourced(key)
    local idx = zone_index()
    if idx == nil or type(key) ~= 'string' or key == '' then return 0 end
    local bucket = idx[key]
    if type(bucket) ~= 'table' then return 0 end
    return #bucket
end

-- Where dice_data says each die is sold or dropped, grouped by zone key. Built with spells_core.zone_index, which is a
-- plain join over any table keyed by id that carries tag/note/zone; a die row is exactly that shape, so a second copy
-- of the join would only be a second thing to keep right. Latched like the spell index: dice_data cannot change while
-- the addon is loaded.
local function dice_zone_index()
    if type(st.dice_idx) == 'table' then return st.dice_idx end
    if CORE == nil or type(CORE.zone_index) ~= 'function' then return nil end
    if DDATA == nil or type(DDATA.dice) ~= 'table' then return nil end
    local ok, idx = pcall(CORE.zone_index, DDATA.dice)
    if not ok then
        fail('dice zones', idx)
        return nil
    end
    if type(idx) ~= 'table' then return nil end
    st.dice_idx = idx
    return idx
end

-- How many dice the table places in this zone at all, for /spells debug: the same number zone_sourced is for spells.
local function dice_zone_sourced(key)
    local idx = dice_zone_index()
    if idx == nil or type(key) ~= 'string' or key == '' then return 0 end
    local bucket = idx[key]
    if type(bucket) ~= 'table' then return 0 end
    return #bucket
end

-- forward declaration: dice_hits reads the plain list, which is built by the same builder the window uses
local plain_rows

-- The dice a player still has to learn that this zone sources. Only rows whose known-status is false: a die the player
-- already knows must never be announced, and a nil-known die (no bitfield yet) is left out too, because the client not
-- answering is not permission to announce something the player may already own. The per-kind switches still apply -
-- every die in the shipped table is a shop's, so alert_shop silences them the way it silences a scroll vendor.
--
-- The rows come from the plain list (the same builder the window uses, filters off), so a search box cannot change
-- what is announced. They are re-sorted by the die's COR level (then name) after the join: spells_core.here orders a
-- zone's sources by kind and then by name, which for a wall of dice puts Beast Roll before Ranger Roll; the list reads
-- lowest level first, and a notice that names the dice in a different order than the list is a second sorting rule to
-- keep right.
local function dice_hits(key)
    local idx = dice_zone_index()
    if idx == nil or CORE == nil or type(CORE.here) ~= 'function' then return {} end
    local unknown = {}
    local all = plain_rows()
    for i = 1, #all do
        local r = all[i]
        if type(r) == 'table' and r.kind == 'die' and r.known == false then unknown[#unknown + 1] = r end
    end
    if #unknown == 0 then return {} end
    local ok, hits = pcall(CORE.here, idx, key, unknown, alert_kinds())
    if not ok then
        fail('dice zones', hits)
        return {}
    end
    if type(hits) ~= 'table' then return {} end
    table.sort(hits, function (a, b)
        local ra, rb = a.row or {}, b.row or {}
        local la, lb = tonumber(ra.level) or 0, tonumber(rb.level) or 0
        if la ~= lb then return la < lb end
        return tostring(ra.name or '') < tostring(rb.name or '')
    end)
    return hits
end

-- The rows the alerts read: the window's own builder with `plain` set, which is the same list minus the view's
-- filters and minus what is already learnt. The scan is reused (st.scan) because the zone handlers run between frames
-- and a fresh 18-bag walk is not worth it; a nil scan simply means no 'held' markers, which no alert reads.
function plain_rows()
    local scan = st.scan
    if scan == nil then scan = scan_bags() end
    rebuild(current_player(), scan, true)
    return st.plain_rows or {}
end

-- What the player still needs that this zone has: [] for a zone with nothing, a zone the table does not name, and a
-- CORE that is missing. Never raises, so no game event handler can be taken down by a bad row.
local function zone_hits(key)
    local idx = zone_index()
    if idx == nil or CORE == nil or type(CORE.here) ~= 'function' then return {} end
    local ok, hits = pcall(CORE.here, idx, key, plain_rows(), alert_kinds())
    if ok and type(hits) == 'table' then return hits end
    if not ok then fail('zones', hits) end
    return {}
end

-- Ten entries is a chat line the log can still show above the scroll: kind, spell and the generated note, which is
-- the citation the whole feature exists for ('shop: Cure IV - Hasim / Lower Jeuno - (H-9) / 23,400 Gil').
local ZONE_CHAT_ENTRIES = 10

local function hit_list(hits)
    local parts = {}
    for i = 1, #hits do
        if i > ZONE_CHAT_ENTRIES then break end
        local h = hits[i]
        local note = tostring(h.note or '')
        -- a source row can carry an empty note (the generator writes '' when the page named no place inside the
        -- zone); the row's own badge note is the better second choice, and '' is better than 'nil'
        if note == '' then note = tostring(h.row and h.row.note or '') end
        parts[#parts + 1] = string.format('%s: %s - %s', tostring(h.kind), tostring(h.row and h.row.name or '?'), note)
    end
    local text = table.concat(parts, '; ')
    if #hits > ZONE_CHAT_ENTRIES then
        text = text .. string.format('; and %d more', #hits - ZONE_CHAT_ENTRIES)
    end
    return text
end

-- The dice half of the chat line, printed after the scrolls. The word 'die' leads every entry rather than the tag the
-- badge wears: a line that reads 'shop: Warrior Die - Chayaya / Al Zahbi' would look like a scroll whose name the
-- player does not recognise, and the level comes next because a die at 76 is a different answer from one at 8.
local function dice_list(hits)
    local parts = {}
    for i = 1, #(hits or {}) do
        if i > ZONE_CHAT_ENTRIES then break end
        local h = hits[i]
        local row = h.row or {}
        local note = tostring(h.note or '')
        if note == '' then note = tostring(row.note or '') end
        parts[#parts + 1] = string.format('die: %s (Lv %d) - %s',
            tostring(row.name or '?'), tonumber(row.level) or 0, note)
    end
    local text = table.concat(parts, '; ')
    local n = #(hits or {})
    if n > ZONE_CHAT_ENTRIES then
        text = text .. string.format('; and %d more', n - ZONE_CHAT_ENTRIES)
    end
    return text
end

local function scroll_note(n)
    return string.format('%d scroll%s', n, n == 1 and '' or 's')
end

local function die_note(n)
    -- 'dice', not 'dies': the plural of the item is the word the wiki and the game both use
    return string.format('%d %s', n, n == 1 and 'die' or 'dice')
end

-- '2 scrolls and 1 die', '1 die', '3 scrolls': what the notice counts, in the same order the list below it reads.
local function need_note(scrolls, dice)
    if dice == 0 then return scroll_note(scrolls) end
    if scrolls == 0 then return die_note(dice) end
    return string.format('%s and %s', scroll_note(scrolls), die_note(dice))
end

-- One toast and one chat line, in the shapes the rest of the file already uses (open_link's toast, say's '[Spells]'
-- prefix). Information only: no packet, no command, no chat input, no movement. The dice are appended after the
-- scrolls and the counts name them as dice, so '1 die here: Warrior Die' is a different sentence from '1 scroll'.
local function zone_report(label, hits, dice)
    local parts = {}
    if #hits > 0 then parts[#parts + 1] = hit_list(hits) end
    if #(dice or {}) > 0 then parts[#parts + 1] = dice_list(dice) end
    say(string.format('%s - %s to find - %s', label, need_note(#hits, #(dice or {})), table.concat(parts, '; ')))
end

-- The zone-in is silent in chat now. What it does is mark the zone live for the row draw - the ids of what this job
-- still needs here - and, unless the chime is off, play the folder's softer bell once. No toast and no chat line: an
-- alert must not interrupt a fight, and the highlighted rows are the notice. Nothing here writes to the game: no
-- packet, no command, no action.
local function announce_zone(hits, dice)
    local ids = {}
    for i = 1, #(hits or {}) do
        local id = hits[i].row and hits[i].row.id
        if id ~= nil then ids[id] = true end
    end
    for i = 1, #(dice or {}) do
        local id = dice[i].row and dice[i].row.id
        if id ~= nil then ids[id] = true end
    end
    st.here_ids = ids
    if cfg.zone_sound ~= false then play_chime() end
end

-- Whether the zone the player is standing in has something this job still needs: the one condition the pill's pulse
-- asks about, so the pulse and the highlighted rows can never disagree about whether the zone is worth a nudge. A nil
-- or emptied set is 'no' rather than an error - the alerts clear it on a zone with nothing, and a checkout missing
-- spells_core never fills it at all.
local function zone_has_need()
    if type(st.here_ids) ~= 'table' then return false end
    return next(st.here_ids) ~= nil
end

-- The zone alerts' master switch, read exactly the way zone_in reads it (== true, so a hand-edited or older settings
-- file with no key is OFF rather than quietly announced). One reading for the whole file: the pill's Play/Stop and its
-- pulse must never claim the alerts are listening while the game stays silent, and /spells alerts and /spells debug
-- print the same answer.
local function alerts_listening() return cfg.zone_alerts == true end

-- One zone-in, once. Nothing here writes to the game: no packet, no command, no action.
local function zone_in(e)
    local id = type(e) == 'table' and e.zone or nil
    if tonumber(id) ~= nil and tonumber(id) > 0 then st.last_zone_id = tonumber(id) end
    local name = zone_name(id)
    if name == nil then return false end
    local key = zone_key_of(name)
    if key == '' then return false end
    -- the master switch, through the one reading of it the whole file shares (alerts_listening above): a hand-edited
    -- settings file with no key stays quiet instead of announcing something the player never asked for. The highlight
    -- is part of the alert, so it goes too.
    if not alerts_listening() then
        st.here_ids = {}
        return false
    end
    -- a Mog House in-and-out re-raises zone_change with the same zone: the player has not moved anywhere new
    if st.last_zone_key == key then return false end
    local hits = zone_hits(key)
    local dice = dice_hits(key)
    if #hits == 0 and #dice == 0 then
        -- nothing here for this job: the last zone's highlight must not linger on the new list
        st.here_ids = {}
        return false
    end
    -- latched only once something was announced. A zone with nothing to announce must not poison the memory, and a
    -- login whose player table had not filled in yet (job 0 builds no rows) has to be able to speak on the next event.
    st.last_zone_key = key
    announce_zone(hits, dice)
    return true
end

-- The zone the player is standing in when a command runs. Three sources, in the docs' order
-- (docs/addons/04-game-data.md:455-470): the server's own zone-in (vana.game.player_zone, right the second the zone
-- loads), then the party list's own member (vana.game.party().members[1].zone, which lags a zone-in by the seconds
-- the new zone takes to load), then the id the last zone_change/login carried. Every read is guarded; nil means the
-- client has not named a zone yet and the command says so rather than guessing.
local function current_zone()
    local ok_p, z = pcall(function () return vana.game.player_zone(nil) end)
    if ok_p and tonumber(z) and tonumber(z) > 0 then return tonumber(z) end
    local ok_party, party = pcall(function () return vana.game.party() end)
    if ok_party and type(party) == 'table' and type(party.members) == 'table' then
        local row = party.members[1]
        if type(row) == 'table' and tonumber(row.zone) and tonumber(row.zone) > 0 then return tonumber(row.zone) end
    end
    if st.last_zone_id ~= nil then return st.last_zone_id end
    return nil
end

-- The zone marks, read on demand and SILENTLY. Folding the window happens while the player stands still, so a pill
-- that waited for the next zone-in would look dead in exactly the zone it was folded for. No chime here: the player
-- asked to fold, not for an alert. It reads what the zone-in reads, so the pill's pulse and the highlighted rows can
-- never disagree. Declared here, after every helper it calls - a local function is only visible to ones declared
-- below it, and a missing upvalue would be a nil global (which pcall would swallow into 'nothing marked').
local function refresh_here()
    if not alerts_listening() then st.here_ids = {} return end
    local name = zone_name(current_zone())
    if name == nil then st.here_ids = {} return end
    local key = zone_key_of(name)
    if key == '' then st.here_ids = {} return end
    local ids = {}
    local hits, dice = zone_hits(key), dice_hits(key)
    for i = 1, #(hits or {}) do
        local id = hits[i].row and hits[i].row.id
        if id ~= nil then ids[id] = true end
    end
    for i = 1, #(dice or {}) do
        local id = dice[i].row and dice[i].row.id
        if id ~= nil then ids[id] = true end
    end
    st.here_ids = ids
end

-- /spells here. Always answers: a listing, or the reason there is nothing to list (no zone named yet, or a zone the
-- table sources nothing this job needs). It ignores last_zone_key on purpose - the player asked - and it is not
-- gated by cfg.zone_alerts: the master switch is about the automatic notice, a typed command is not an interruption.
-- The dice are listed after the scrolls, as the request has it, and a zone that only sells a die still answers.
local function list_zone()
    local name = zone_name(current_zone())
    if name == nil then
        say('no zone to list yet: the client has not named one (it fills in with the first zone-in)')
        return
    end
    local key = zone_key_of(name)
    if key == '' then
        say('no zone to list: spells_core.lua is missing')
        return
    end
    local hits = zone_hits(key)
    local dice = dice_hits(key)
    if #hits == 0 and #dice == 0 then
        say(string.format('%s - nothing here this job still needs (%d spells sourced in this zone)',
            name, zone_sourced(key)))
        return
    end
    zone_report(name, hits, dice)
end

-- the alert switches, said in one line for /spells alerts with no argument and for /spells debug
local function alert_status()
    return string.format('zone alerts: %s (shop %s, drop %s, bcnm %s, sound %s)',
        alerts_listening() and 'on' or 'off',
        cfg.alert_shop == true and 'on' or 'off',
        cfg.alert_drop == true and 'on' or 'off',
        cfg.alert_bcnm == true and 'on' or 'off',
        cfg.zone_sound == true and 'on' or 'off')
end

-------------------------------------------------------------------------------
-- What the window does
-------------------------------------------------------------------------------

local function set_open(on)
    on = on == true
    if on == st.open then return end
    st.open = on
    if on then
        st.focus_frames = 2
        if cfg.open_sound ~= false then play_bell() end
        -- ask for the ledger when the window opens, not every frame: request_ledger's 60 s gate is what keeps a
        -- player who toggles the window ten times from spending ten packets
        st.ledger_asked = true
        request_ledger(false)
    else
        -- a fresh opening asks again (the 60 s gate in request_ledger is what decides whether anything is sent)
        st.ledger_asked = false
    end
end

-- Folded or not. cfg is what survives the session (a per-character settings file) and st is what the frame reads;
-- keeping the two together here means neither the header button, the pill nor /spells can set one without the other.
local function set_minimized(on)
    on = on == true
    st.minimized = on
    -- folding happens where the player stands: read the zone now, without a chime, or the pill would stay quiet until
    -- the next zone-in. Unfolding keeps the marks the window is about to draw.
    if on then pcall(refresh_here) end
    if cfg.minimized ~= on then
        cfg.minimized = on
        save()
    end
    return on
end

local function set_mode(id)
    local m = mode_by_id(id)
    if m == nil then return false end
    if cfg.mode ~= id then
        cfg.mode = id
        st.cache_key = nil
        save()
        play_bell()
        U.toast('info', 'Mode: ' .. tostring(m.label or id), tostring(m.blurb or ''), 5, 'wand')
    end
    return true
end

local function set_skill(id)
    if cfg.skill == id then return end
    cfg.skill = id
    st.cache_key = nil
    save()
end

local function set_learned(on)
    cfg.show_learned = on == true
    st.cache_key = nil
    save()
end

-- 'usable now' and 'in storage' save the same way the learnt toggle does: one click, written to this character's
-- settings, effective on the next rebuild (which the cleared cache key forces)
local function set_only_now(on)
    cfg.only_now = on == true
    st.cache_key = nil
    save()
end

local function set_held_only(on)
    cfg.held_only = on == true
    st.cache_key = nil
    save()
end

-- the search box: the theme's own frame, with the room on the left for the magnifier. Escape clears the query rather
-- than closing the window, which is what a box with text in it should do.
local function draw_search(dl, x, cy, w, hint)
    local h = S(28)
    imgui.SetCursorScreenPos({ x, cy - h / 2 })
    imgui.SetNextItemWidth(w)
    -- ImGuiStyleVar_FramePadding (11): the kit's 12 px padding, pushed out to make room for the icon
    imgui.PushStyleVar(11, { S(30), S(7) })
    local ok, err = pcall(U.with_font, F.text, T.small, function ()
        imgui.InputTextWithHint('##st_search', hint or 'search spells', st.query, 48, 0)
    end)
    imgui.PopStyleVar(1)
    if not ok then fail('search', err) end
    local focused = imgui.IsItemActive() or imgui.IsItemFocused()
    local escaped = false
    if focused and imgui.IsKeyPressed(U.KEY_ESCAPE) then
        st.query[1] = ''
        escaped = true
        st.cache_key = nil
    end
    local x0, y0 = imgui.GetItemRectMin()
    local _, ih = imgui.GetItemRectSize()
    U.icon(dl, x0 + S(13), y0 + ih / 2, 'magnifying-glass', P.faint, T.small)
    return escaped, focused
end

-- A row is 34 px tall at 100 %, but the row's name is drawn at T.small, which the text scale multiplies: past about
-- 250 % that line is taller than the card it sits in and consecutive rows overlap. So the card grows to fit its own
-- line and the list's step follows the card. At 100 % this is exactly S(34) and nothing moves.
local function row_h()
    local h = S(34)
    local fit = S(T.small) + S(14)
    if fit > h then h = fit end
    return h
end

local function draw_row(dl, x0, y0, rw, row, i)
    local rowh = row_h()
    local die = row.kind == 'die'
    local key = '##st_row_' .. tostring(row.id or i)
    -- not `die and row.known or nil`: false would collapse to nil and draw a question mark for a roll the player
    -- definitely does not know
    local known = nil
    if die then known = row.known end
    local learned = (not die) and row.learned == true
    local badge = row.badge
    if type(badge) ~= 'table' then
        badge = (DATA and DATA.tags and DATA.tags[row.tag]) or UNKNOWN_TAG
    end
    local label = tostring(badge.label or '?')
    local color = tostring(badge.color or P.dim)
    local icon_name = tostring(badge.icon or 'question')
    local note = tostring(row.note or badge.note or '')
    local src = tostring(row.src or '')
    -- the other paths ride in the tooltip, never on the pill: the pill names the one source the table's sentence cites
    -- (spells_core keeps that pairing), and these say what else the page recorded. The Auction House is always one of
    -- them when the scroll has an AH listing, since a scrolled spell that is also vendored would otherwise never show
    -- its AH path anywhere.
    local extra = ''
    local seen_tags = row.tags or {}
    local ah = false
    for i = 1, #seen_tags do if seen_tags[i] == 'ah' then ah = true end end
    if ah and cfg.mode ~= 'cw' then extra = extra .. '  -  also listed on the Auction House' end
    local mode_has_wizardoll = false
    do
        local m = mode_by_id(cfg.mode)
        for _, t in ipairs((m and m.tags) or {}) do if t == 'wizardoll' then mode_has_wizardoll = true end end
    end
    if mode_has_wizardoll and #seen_tags > 0 then
        extra = extra .. '  -  this mode: the Wizardoll NPC sells scrolled spells for Sparks of Eminence'
    end
    local tip = note .. extra .. (src ~= '' and ('  (' .. src .. ')') or '')
    if #tip > 320 then tip = tip:sub(1, 317) .. '...' end

    local tw, th = U.measure(label, F.semi, T.tiny)
    local pad = S(8)
    local pillw = tw + th + S(4) + pad * 2
    local pillh = th + S(7)
    local wsize = S(22)
    local wx = x0 + rw - wsize - S(4)
    local wy = y0 + (rowh - wsize) / 2
    -- two markers can share the strip between the pill and the Wiki button: the ledger's stored mark on the left and
    -- the bag mark to its right, because "stored at Gramateus" and "in one of your bags" are different facts and a
    -- row can carry either without the other. The pill yields the room for both (a row without a stored mark gets
    -- exactly the geometry it had before).
    local held = row.held
    local held_n = 0
    local bag_w = 0
    if type(held) == 'table' then
        held_n = tonumber(held.count) or 1
        bag_w = S(18) + (held_n > 1 and S(12) or 0)
    end
    local stored = row.stored == true
    local store_w = stored and S(18) or 0
    local mark_w = bag_w + store_w
    local pillx = wx - S(8) - pillw - mark_w
    local pilly = y0 + (rowh - pillh) / 2

    -- the row's own click area stops before the badge and the Wiki button: overlapping invisible buttons would let
    -- the first one eat the others' clicks
    local hitw = math.max(1, pillx - x0 - S(4))
    imgui.SetCursorScreenPos({ x0, y0 })
    local row_pressed, row_hovered, hv = U.hit(key, hitw, rowh, S(8))
    -- A row the zone the player just walked into is about: a soft accent wash under the normal card plus a short
    -- accent bar just inside the left edge. Both are drawn inside the cell, so nothing moves - not the row height,
    -- the hitbox or the list's scroll maths - and the kit's own palette keys are used, so every theme carries it.
    local live = type(st.here_ids) == 'table' and row.id ~= nil and st.here_ids[row.id] == true
    local fill = live and U.mix(P.card, P.accent, 0.18) or P.card
    dl:AddRectFilled({ x0, y0 }, { x0 + rw, y0 + rowh }, U.u32(U.mix(fill, P.card_hi, 0.85 * hv)), S(8))
    dl:AddRect({ x0, y0 }, { x0 + rw, y0 + rowh },
        U.u32(live and U.mix(P.line, P.accent, 0.55) or P.line, 0.8), S(8), 15, 1)
    if live then
        dl:AddRectFilled({ x0 + S(3), y0 + S(7) }, { x0 + S(6), y0 + rowh - S(7) }, U.u32(P.accent, 0.95), S(2))
    end

    local cy = y0 + rowh / 2
    local dx = x0 + S(14)
    if die then
        -- known is TRUE, FALSE or nil: nil is the client not having answered, and it is drawn as a question mark, never
        -- as 'you do not know this roll'
        if known == true then
            dl:AddCircleFilled({ dx, cy }, S(4), U.u32(P.ok, 0.95), 20)
        elseif known == false then
            dl:AddCircle({ dx, cy }, S(4), U.u32(P.faint, 0.9), 20, 1)
        else
            U.icon(dl, dx, cy, 'question', P.faint, T.tiny)
        end
    elseif learned then
        dl:AddCircleFilled({ dx, cy }, S(4), U.u32(P.ok, 0.95), 20)
    else
        dl:AddCircle({ dx, cy }, S(4), U.u32(P.faint, 0.9), 20, 1)
    end

    local name = tostring(row.name or '?')
    local name_col
    if die then
        name_col = row.usable == true and P.text or U.mix(P.text, P.faint, 0.55)
        if known == true then name_col = U.mix(name_col, P.ok, 0.35) end
    else
        name_col = learned and U.mix(P.text, P.ok, 0.35) or P.text
        if row.unreachable then name_col = U.mix(P.text, P.danger, 0.45) end
    end
    local name_w = die and rw * 0.28 or rw * 0.42
    U.text_mid(dl, x0 + S(26), cy, U.fit(name, F.text, T.small, name_w), name_col, F.text, T.small)

    -- a die row reads left to right as 'what it is, what it teaches, what level it asks for'; a spell row keeps the
    -- columns it always had (level, via sub, skill, MP)
    local lx = x0 + (die and rw * 0.58 or rw * 0.46)
    local lv = tonumber(row.level) or 0
    local lv_col = P.dim
    if die and row.usable ~= true then lv_col = P.faint
    elseif not die and row.unreachable then lv_col = P.danger end
    U.text_mid(dl, lx, cy, 'Lv ' .. lv, lv_col, F.semi, T.tiny)

    if die then
        local roll = tostring(row.roll or '')
        if roll ~= '' then
            U.text_mid(dl, x0 + rw * 0.36, cy, U.fit(roll, F.text, T.tiny, rw * 0.20),
                known == true and P.dim or P.accent2, F.text, T.tiny)
        end
        -- a subbed COR can see the dice at half the sub level, but learning one needs COR main: said on the row, in
        -- the same column a spell uses for 'via SUB'
        if row.via == 'sub' then
            U.text_mid(dl, lx + S(42), cy, 'needs COR main', P.cyan, F.text, T.tiny)
        end
        if row.usable ~= true then
            U.text_mid(dl, lx + S(42) + (row.via == 'sub' and S(92) or 0), cy, 'not yet', P.faint, F.text, T.tiny)
        end
    else
        if row.via == 'sub' then
            U.text_mid(dl, lx + S(42), cy, 'via SUB', P.cyan, F.text, T.tiny)
        end
        if type(row.skill_name) == 'string' and row.skill_name ~= '' then
            U.text_mid(dl, x0 + rw * 0.60, cy, U.fit(row.skill_name, F.text, T.tiny, S(96)), P.dim, F.text, T.tiny)
        end
        local mp = tonumber(row.mp) or 0
        if mp > 0 then
            U.text_mid(dl, x0 + rw * 0.74, cy, 'MP ' .. mp, P.accent2, F.text, T.tiny)
        end
    end

    -- the badge's own hit area, then its colour; a source that is unknown is drawn as unknown, never guessed
    imgui.SetCursorScreenPos({ pillx, pilly })
    local pill_pressed, pill_hovered = U.hit(key .. 'p', pillw, pillh, pillh / 2)
    U.pill(dl, pillx, pilly, label, U.mix(P.card_hi, color, 0.30), color, F.semi, T.tiny, pad, icon_name)
    if pill_hovered and tip ~= '' then
        U.with_font(F.text, T.small, imgui.SetTooltip, tip)
    end

    -- the markers right of the pill: the stored one first, then the bag one, whose geometry is untouched for a row
    -- without a stored mark. Both are hit-tested so the two tooltips never share a pixel.
    local strip_x = pillx + pillw + S(2)
    if stored then
        imgui.SetCursorScreenPos({ strip_x, y0 })
        local _, store_hovered = U.hit(key .. 's', store_w, rowh, S(4))
        U.icon(dl, strip_x + S(8), cy, VAULT_ICON, P.cyan, T.tiny)
        if store_hovered then
            -- named, never counted: the ledger answers one bit per scroll and a number here would be invented
            U.with_font(F.text, T.small, imgui.SetTooltip, 'stored (Gramateus / the box)')
        end
    end

    -- the scroll or the die is already in a bag: the marker names the bag on hover, and says where the rest are when
    -- the player has the same thing in more than one
    if type(held) == 'table' then
        local mx = strip_x + store_w
        local mw_box = math.max(1, wx - S(2) - mx)
        imgui.SetCursorScreenPos({ mx, y0 })
        local _, mark_hovered = U.hit(key .. 'b', mw_box, rowh, S(4))
        local icon_x = mx + S(8)
        U.icon(dl, icon_x, cy, BAG_ICON, P.ok, T.tiny)
        if held_n > 1 then U.text_mid(dl, icon_x + S(7), cy, tostring(held_n), P.ok, F.semi, T.tiny) end
        if mark_hovered then
            local where = 'in your ' .. tostring(held.bag or 'bags')
            local others = {}
            for i = 1, #(held.bags or {}) do
                if held.bags[i] ~= held.bag then others[#others + 1] = tostring(held.bags[i]) end
            end
            if #others > 0 then where = where .. ', also ' .. table.concat(others, ', ') end
            U.with_font(F.text, T.small, imgui.SetTooltip, where)
        end
    end

    local wiki_pressed = U.icon_button(dl, key .. 'w', wx, wy, wsize, 'scroll', P.cyan, 'Open BG-Wiki')

    if wiki_pressed then
        open_wiki(row)
    elseif pill_pressed or (row_hovered and imgui.IsMouseDoubleClicked(0)) then
        open_database(row)
    end
end

-- The pill: the window folded to its notification size, 230 x 34 at 100 % (scaled by S() like everything else, and by
-- pill_scale on top of that). Wide enough for the word at the display face plus a 22 px Play/Stop and a 22 px Mute,
-- each inside its own round hitbox.
local PILL_W, PILL_H, PILL_BTN = 230, 34, 22

-- The pill's own factor: cfg.pill_scale (50-300) as a multiplier, applied to its three constants BEFORE S() - so the
-- capsule is the one surface whose size the player sets on its own. It neither follows the text scale (its word is
-- sized here, not by T) nor the window's geometry beyond the kit's own scale, which still applies on top.
local function pill_k()
    return pill_pct() / 100
end
local function pill_size(n)
    return n * pill_k()
end

-- The pill: one window folded down, not a second window. Left to right the word 'Spelltracker' in the kit's display
-- face, a drawn Play/Stop and a Mute wearing the kit's own bell glyphs. EVERYTHING else - the word included - is the
-- restore hitbox: one invisible button across the whole pill laid down FIRST, then the two real buttons over it.
-- ImGui hands a click to the later item once the earlier one allows overlap, and the restore is guarded on both
-- buttons below, so a press on either can never also restore the window.
local function draw_pill(dl, x, y, w, h, t)
    t = tonumber(t) or 0
    local r = h / 2
    do
        local m = S(16)
        dl:PushClipRect({ x - m, y - m }, { x + w + m, y + h + m }, false)
        U.shadow(dl, x, y, w, h, r, 1)
        dl:PopClipRect()
    end
    -- the kit's own card surface and border, so the pill looks like the family's other surfaces in every theme
    U.panel(dl, x, y, w, h, P.card, 1, r, P.line)

    -- Listening is the zone alerts' own switch (the same reading zone_in uses), so the button and the alerts can never
    -- disagree. A muted pill still pulses and still highlights: mute is the chime only.
    local listening = alerts_listening()

    -- The pulse: the kit's breathing alpha (ui.lua's focus ring is 0.75 + 0.25 * sin(t * 4)) on the border, while
    -- there is something here this job still needs. Alpha only - never a size, a position or a re-layout - so a
    -- pulsing pill cannot shift under the mouse, and nothing pulses for an empty zone, for Stop, or when restored.
    if listening and zone_has_need() then
        dl:AddRect({ x, y }, { x + w, y + h }, U.u32(P.accent, 0.75 + 0.25 * math.sin(t * 4)), r, 15, 1)
    end

    -- the restore hitbox, first and full size. SetNextItemAllowOverlap is what lets the two buttons below be hovered
    -- and clicked at all: without it the first item owns the mouse for as long as it is held, and they would be dead
    -- buttons drawn over a live one.
    imgui.SetCursorScreenPos({ x, y })
    if imgui.SetNextItemAllowOverlap ~= nil then imgui.SetNextItemAllowOverlap() end
    local restore = U.hit('##st_restore', w, h, r)

    local cy = y + h / 2
    -- one button geometry for both states and both buttons, measured from the right edge: neither target moves when
    -- the glyph changes, and the word never pushes them around. The height is what the capsule can hold, so the button
    -- is clamped to it - at pill_scale 300 the button wants 66 px of a 102 px capsule and still fits with its margin,
    -- and a capsule clipped by a small screen keeps a button that fits what is left rather than one that overflows.
    local btn = math.min(S(PILL_BTN * pill_k()), h - S(6))
    local mute_x = x + w - S(10 * pill_k()) - btn
    local play_x = mute_x - S(6 * pill_k()) - btn

    local face = F.disp or F.text
    local text_x = x + S(14 * pill_k())
    local text_w = math.max(S(24 * pill_k()), play_x - text_x - S(8 * pill_k()))
    -- The word is the CAPSULE's text, so it is sized by the capsule and not by text_scale: the capsule's height grows
    -- with pill_scale, and a word that grew with the window's text scale while the capsule ignored it would overflow
    -- its own pill. The tooltips below stay on T, because they are ImGui's own surface, outside the pill.
    local word = (T_RAW.h2 or 17) * pill_k()
    U.text_mid(dl, text_x, cy, U.fit('Spelltracker', face, word, text_w), P.text, face, word)

    -- Play is a triangle with a vertical left edge and its apex to the right; Stop is a square. Both are geometry on
    -- the draw list rather than a glyph: the kit's icon table has no play or stop, and its faces come from the
    -- client's default font (ui.lua:172), so an unknown glyph would draw as an empty box. The hitbox is the kit's own
    -- small round button in both states, so the target is identical whether it reads Play or Stop.
    imgui.SetCursorScreenPos({ play_x, cy - btn / 2 })
    local play_pressed, play_hovered, play_hv = U.hit('##st_play', btn, btn, btn / 2)
    local lit = listening and P.accent or P.dim
    local bcx = play_x + btn / 2
    dl:AddCircleFilled({ bcx, cy }, btn / 2, U.u32(lit, 0.08 + 0.16 * play_hv), 32)
    if play_hv > 0 then dl:AddCircle({ bcx, cy }, btn / 2, U.u32(lit, 0.55 * play_hv), 32, 1) end
    local gh = btn * 0.46
    local gy = cy - gh / 2
    if listening then
        local gw = gh * 0.9
        -- a triangle's visual mass sits left of its bounding box, so it is nudged right to look centred in the circle
        local gx = bcx - gw / 2 + gw / 6
        -- the first two points share x: a vertical left edge, and the apex on the right
        dl:AddTriangleFilled({ gx, gy }, { gx, gy + gh }, { gx + gw, gy + gh / 2 }, U.u32(lit))
    else
        dl:AddRectFilled({ bcx - gh / 2, gy }, { bcx + gh / 2, gy + gh }, U.u32(lit), S(1))
    end
    if play_hovered then
        -- named as what the click will DO, not as the state it is in
        U.with_font(F.text, T.small, imgui.SetTooltip,
            listening and 'Stop the zone alerts (the pill stops pulsing)' or 'Start the zone alerts again')
    end
    if play_pressed then
        cfg.zone_alerts = not listening
        save()
    end

    -- Mute is the chime only, and its tooltip says so: the kit's own bell / bell-slash, both in its icon table
    local audible = cfg.zone_sound ~= false
    local mute_pressed = U.icon_button(dl, '##st_mute', mute_x, cy - btn / 2, btn,
        audible and 'bell' or 'bell-slash', audible and P.dim or P.warn,
        audible and 'Mute the zone chime (the pulse and the highlight stay)' or 'Unmute the zone chime')
    if mute_pressed then
        cfg.zone_sound = not audible
        save()
    end

    -- the whole pill restores, the word included - but never on a frame one of the two buttons was pressed
    if restore and not play_pressed and not mute_pressed then set_minimized(false) end
end

-- The footer's two scales: the text scale and the pill scale, as the kit's own slider each. Both are laid out from the
-- RIGHT edge inwards, so the pair line up on one axis and the bottom-right corner - which is the window's resize grip
-- now that NoResize is off - stays free. ONE ROW PER SLIDER: at the window's 320 px floor, two tracks plus two value
-- labels plus two words need about 540 px and the card has 266 px to give, so they would not fit side by side at any
-- usable track width. Two rows of S(30), a clear S(6) between the two hitboxes, and the list gives up the whole band.
local SCALE_MIN, SCALE_MAX = 50, 300
local FOOTER_ROW, FOOTER_ROWS = 30, 2
local function footer_slider(dl, key, word, x, w, cy, value, tip)
    -- the value label the kit draws to the right of its track is part of this control's width, so the layout starts
    -- from the widest label it can print ('300%') rather than from the track
    local label_w = select(1, U.measure('300%', F.semi, T.small))
    local label_x = x + w - S(18) - label_w -- the value label's left edge, inside the window's own padding
    local track_right = label_x - S(14)     -- the kit draws the label at track x + width + S(14)
    local word_w = select(1, U.measure(word, F.text, T.small))
    local track_w = math.min(S(150), (track_right - (x + S(18))) - S(14) - word_w)
    if track_w < S(40) then return nil end  -- a card too narrow for a track still has /spells text and /spells pill
    local track_x = track_right - track_w
    local word_x = track_x - S(14) - word_w
    if word_x >= x + S(18) then
        U.text_mid(dl, word_x, cy, word, P.dim, F.text, T.small)
    end
    local picked, moved, released = U.slider(dl, key, track_x, cy, track_w, value, SCALE_MIN, SCALE_MAX, '%d%%')
    if tip ~= nil and imgui.IsItemHovered() then
        U.with_font(F.text, T.small, imgui.SetTooltip, tip)
    end
    return picked, moved, released
end

local function draw_window(me, t)
    local sw, sh = 1920, 1080
    do
        local ok, w, h = pcall(vana.ui.screen)
        if ok and tonumber(w) and tonumber(h) then sw, sh = w, h end
    end
    local sc = scale_pct() / 100
    -- read ONCE: the position block below clears it, and the size block needs the same answer
    local recenter = st.recenter == true
    -- The window's DEFAULT size at this scale, plus the floor and the ceiling a drag is allowed: 880 x 560 is where the
    -- controls row fits three switches, the mode segments and the search box side by side (at 700 the third one lands
    -- on the search field, measured at the kit's 13 px face); 320 x 260 is the floor the code has always computed; the
    -- screen is the ceiling.
    local min_w, min_h = math.max(S(320), 1), math.max(S(260), 1)
    local max_w, max_h = math.max(min_w, sw - S(20)), math.max(min_h, sh - S(20))
    local def_w = math.min(math.max(min_w, math.floor(S(880))), max_w)
    local def_h = math.min(math.max(min_h, math.floor(S(560))), max_h)
    -- What the window is going to have: the pill is the same window at a notification size (a size branch, not a
    -- second window - 230 x 34 at 100 %, times pill_scale, and never the window's 880 x 560), and the window is the
    -- player's own dragged size when there is one, the default when there is not.
    local w, h = def_w, def_h
    if st.minimized == true then
        w = math.min(S(pill_size(PILL_W)), sw - S(20))
        h = math.min(S(pill_size(PILL_H)), sh - S(20))
    else
        local cw, ch = tonumber(cfg.w), tonumber(cfg.h)
        if cw ~= nil and ch ~= nil then
            w = math.max(min_w, math.min(max_w, cw))
            h = math.max(min_h, math.min(max_h, ch))
        end
    end

    -- The position is placed ONCE and then left alone. ImGuiCond_Always is applied on every frame, so pinning the
    -- saved place with it (which this did) overrides the window's own position each frame: the player drags, the next
    -- frame puts it back, and the window looks like it cannot be moved. It is forced for exactly two reasons - the
    -- first frame this session, and /spells reset - and both clear the flag that asks for it.
    if st.recenter or not st.pos_placed then
        local px, py
        if st.recenter then
            px, py = (sw - w) / 2, (sh - h) / 2
        elseif cfg.x ~= nil and cfg.y ~= nil then
            px, py = cfg.x, cfg.y
        else
            px, py = (sw - w) / 2, (sh - h) / 2
        end
        imgui.SetNextWindowPos({ math.floor(px), math.floor(py) }, U.ALWAYS)
        st.recenter, st.pos_placed = nil, true
    end
    -- The SIZE follows the place's rule: placed when it has to be, and then ImGui's. ALWAYS on every frame (which this
    -- did until 0.6.0) imposes the computed size before the frame's own resize is read back, so an edge or a corner
    -- snaps back every frame - the same class of defect the position had in 0.1.1. A placement is owed in exactly three
    -- cases: the first frame this session (FIRST_USE_EVER - this is where the window STARTS, not where it stays),
    -- /spells reset, and the frame the window comes back from the pill, which is wearing the capsule's 230 x 34. A
    -- change of /spells scale moves the default, so that re-places too; a drag never does.
    if st.minimized == true then
        imgui.SetNextWindowSize({ w, h }, U.ALWAYS)
        if st.size_placed then st.size_placed = nil end
        st.size_of = nil
    else
        local moved = st.size_of == nil
            or math.abs(st.size_of[1] - w) >= 1 or math.abs(st.size_of[2] - h) >= 1
        local cond = nil
        if recenter or st.size_placed == nil then
            cond = U.ALWAYS -- a reset, or the window is still wearing the capsule's size
        elseif not st.size_placed then
            cond = U.FIRST_USE_EVER -- the first frame this session: where it STARTS, not where it stays
        elseif moved then
            cond = U.ALWAYS -- the default moved under it (a /spells scale change), which is not a drag
        end
        if cond ~= nil then
            imgui.SetNextWindowSize({ w, h }, cond)
            st.size_of = { w, h }
        end
        st.size_placed = true
    end
    -- the drag's floor and ceiling, every frame: ImGui keeps them for one Begin only. The pill is not resizeable at
    -- all, so it gets none.
    if st.minimized ~= true and imgui.SetNextWindowSizeConstraints ~= nil then
        pcall(imgui.SetNextWindowSizeConstraints, { min_w, min_h }, { max_w, max_h })
    end
    if st.focus_frames > 0 then
        imgui.SetNextWindowFocus()
        st.focus_frames = st.focus_frames - 1
    end

    -- NoTitleBar 1, NoResize 2, NoScrollbar 8, NoScrollWithMouse 16, NoCollapse 32, NoBackground 128 - the kit's own
    -- comment on U.WINDOW_FLAGS. The WINDOW drops NoResize (a drag on an edge or a corner is the point of the feature);
    -- the PILL keeps it, because a drag grip on a 230 x 34 capsule is a trap. The bit is TESTED before it is
    -- subtracted and the constant is the kit's, so a kit that ever ships a different flags set cannot make this a
    -- silent subtraction from somebody else's bit.
    local flags = U.WINDOW_FLAGS
    if st.minimized ~= true and type(flags) == 'number' and flags % (2 * NO_RESIZE) >= NO_RESIZE then
        flags = flags - NO_RESIZE
    end

    local fade = U.ease(st.anim)
    U.set_window_alpha(fade * opacity())
    U.push_theme()
    if imgui.Begin('##spelltracker', nil, flags) then
        local ok, err = pcall(function ()
            local dl = imgui.GetWindowDrawList()
            local x, y = imgui.GetWindowPos()
            -- THE SIZE THE WINDOW ACTUALLY HAS. A drag on an edge or a corner changes it without telling this addon, so
            -- the body lays itself out from ImGui's own answer: the list's rect is w - S(36) by h - S(196) below, which
            -- means the rows, the header and the child's scroll all follow a resize with no further bookkeeping.
            -- Guarded: a nil answer, a zero-size window (the frame before its first layout) or a missing function
            -- leaves the size that was asked for, so the frame still draws.
            do
                local ok_sz, gw, gh = pcall(imgui.GetWindowSize)
                if ok_sz and tonumber(gw) and tonumber(gh) and gw >= S(80) and gh >= S(40) then
                    w, h = gw, gh
                end
            end
            st.win_w, st.win_h = w, h
            -- keep it on screen, but not while it is being dragged: fighting the mouse makes the drag stutter
            local kx = math.max(0, math.min(x, sw - w))
            local ky = math.max(0, math.min(y, sh - h))
            if (kx ~= x or ky ~= y) and not imgui.IsMouseDown(0) then imgui.SetWindowPos({ kx, ky }) end
            if not imgui.IsMouseDown(0) and (cfg.x ~= kx or cfg.y ~= ky) then
                cfg.x, cfg.y = kx, ky
                save()
            end
            x, y = kx, ky
            -- The size is the player's too, and it is written the way the place is: while the mouse is up, only when it
            -- changed, and once - the write makes the two agree, so the next frame has nothing to do and a drag is
            -- never fought. A size that IS the default is stored as nil rather than as a number, so a window nobody
            -- has dragged keeps following /spells scale. The pill is skipped: its 230 x 34 is not the window's size.
            if st.minimized ~= true and not imgui.IsMouseDown(0) then
                if near_size(w, def_w) and near_size(h, def_h) then
                    if cfg.w ~= nil or cfg.h ~= nil then
                        cfg.w, cfg.h = nil, nil
                        save()
                    end
                elseif not (near_size(cfg.w, w) and near_size(cfg.h, h)) then
                    cfg.w, cfg.h = math.floor(w), math.floor(h)
                    save()
                end
                -- and the addon now believes the window IS this size, so the next frame's target matches it and no
                -- placement is asked for: a drag is answered with a save, never with a SetNextWindowSize
                st.size_of = { w, h }
            end
            -- folded: the pill, and nothing else of the window (no header, no controls, no list)
            if st.minimized == true then
                draw_pill(dl, x, y, w, h, t)
                return
            end
            local m = S(40)
            dl:PushClipRect({ x - m, y - m }, { x + w + m, y + h + m }, false)
            U.shadow(dl, x, y, w, h, S(16), 1)
            dl:PopClipRect()
            U.panel(dl, x, y, w, h, P.bg, 1, S(16), P.line)

            -- header: the job and its level, the counts, and the close button
            U.job_badge(dl, x + S(36), y + S(38), S(18), me.job, 1)
            local sub_name = (me.sub_job > 0) and job_short(me.sub_job) or '---'
            local sub_level = (me.sub_job > 0) and me.sub_level or 0
            local title = string.format('%s %d  /  %s %d', job_short(me.job), me.level, sub_name, sub_level)
            U.text(dl, x + S(60), y + S(18), title, P.text, F.disp, T.h1)
            local counts = st.counts or {}
            local line = string.format('%d to learn - %d learnt',
                tonumber(counts.missing) or 0, tonumber(counts.learned) or 0)
            U.text(dl, x + S(60), y + S(44), line, P.dim, F.text, T.small)
            -- where the next header line would start. Measured from the kit, never guessed: the header has a hard
            -- right edge (the close button) and the lines share one row at the 700..880 px width.
            local hx = x + S(60) + U.measure(line, F.text, T.small) + S(14)
            -- how many rows already sit in a bag - a scroll or a die, one count. Counted against the whole list
            -- (st.counts), and only falls back to the smaller 'showing' number when a filter is on and the rows are
            -- still visible: narrowing the search must not look as if the items left the bags.
            local held_total = tonumber(counts.held) or 0
            if held_total > 0 then
                local held_shown = 0
                local shown_rows = st.rows or {}
                for i = 1, #shown_rows do if shown_rows[i].held ~= nil then held_shown = held_shown + 1 end end
                local n = held_shown > 0 and held_shown or held_total
                local bag_text = string.format('%d already in your bags', n)
                U.text(dl, hx, y + S(44), bag_text, P.accent, F.semi, T.small)
                hx = hx + U.measure(bag_text, F.semi, T.small) + S(14)
            end
            -- what the server's ledger says is stored at Gramateus / in the box: a second, separate count, because a
            -- scroll can be stored and not held (and the other way round). Dropped, not clipped, if it would run
            -- under the close button: a number half-hidden behind a glyph is worse than no number.
            local stored_total = tonumber(counts.stored) or 0
            if stored_total > 0 then
                local store_text = string.format('%d stored', stored_total)
                local store_w = U.measure(store_text, F.semi, T.small)
                if hx + store_w <= x + w - S(72) - S(12) then
                    U.text(dl, hx, y + S(44), store_text, P.accent, F.semi, T.small)
                end
            end
            -- fold to the pill. Its own key and its own 26 px box, left of the close button (which keeps its place, so
            -- neither target moved): two keys mean a click on one can never fire the other, and the fold is a
            -- different act from shutting the window.
            if U.icon_button(dl, '##st_min', x + w - S(72), y + S(14), S(26), 'window-minimize', P.dim,
                'Minimize to the pill') then
                set_minimized(true)
            end
            if U.icon_button(dl, '##st_close', x + w - S(42), y + S(14), S(26), 'xmark', P.dim, 'Close') then
                set_open(false)
            end
            dl:AddLine({ x + S(18), y + S(66) }, { x + w - S(18), y + S(66) }, U.u32(P.line, 0.9), 1)

            -- controls: the mode, the three filters and the search, on one row for the one list
            local cy = y + S(86)
            local ctl_x = x + S(18)
            local mode_opts = {}
            for _, md in ipairs(modes()) do mode_opts[#mode_opts + 1] = { md.id, md.label or md.id } end
            local _, mw, clicked = U.segments(dl, '##st_mode', x + S(18), cy - S(13), S(26), mode_opts, cfg.mode,
                function (o) return pill_colour(MODE_COLOR, o[1], 'accent') end, F.semi, T.small)
            if clicked then set_mode(clicked) end
            ctl_x = x + S(18) + mw + S(22)

            -- independent AND filters, each saved on click like the learnt toggle. The switches are laid out
            -- left to right and the search box takes the room that is left, so a label a font wider cannot overlap it.
            local function toggle_at(key, label, on)
                local shown, pressed = U.toggle(dl, key, ctl_x, cy, label, on)
                -- the kit's switch is a 40 px track, a 10 px gap and the label; 16 px between switches
                ctl_x = ctl_x + S(40) + S(10) + select(1, U.measure(label, F.text, T.small)) + S(16)
                return shown, pressed
            end
            local learnt_on, learnt_pressed = toggle_at('##st_learned', 'Show learnt', cfg.show_learned == true)
            if learnt_pressed then set_learned(learnt_on) end
            local now_on, now_pressed = toggle_at('##st_now', 'Usable now', cfg.only_now == true)
            if now_pressed then set_only_now(now_on) end
            local held_on, held_pressed = toggle_at('##st_held', 'In storage', cfg.held_only == true)
            if held_pressed then set_held_only(held_on) end

            local search_x = x + w - S(18) - S(210)
            if search_x < ctl_x + S(10) then search_x = ctl_x + S(10) end
            local search_w = math.min(S(210), x + w - S(18) - search_x)
            local escaped, search_focused = draw_search(dl, search_x, cy, math.max(S(80), search_w),
                'search spells and dice')

            -- the second row: the skill pills. They read a spell's type, so dice are not narrowed by them - a die is
            -- not white or black, and hiding it behind a spell-school pill would be a second rule about dice.
            local py = y + S(116)
            local skill_opts = { { 'all', 'All' } }
            for _, sk in ipairs(skills()) do
                if sk.id then skill_opts[#skill_opts + 1] = { sk.id, sk.label or sk.id } end
            end
            local _, _, sk_clicked = U.segments(dl, '##st_skill', x + S(18), py, S(24), skill_opts,
                cfg.skill or 'all', function (o) return pill_colour(SKILL_COLOR, o[1], 'accent2') end, F.semi, T.small)
            if sk_clicked then set_skill(sk_clicked) end

            -- the list: a child gives the wheel and clips every row to its card, so nothing draws over the header
            local rx = x + S(18)
            local ry = py + S(34)
            local rw = w - S(36)
            -- The footer band: the two scale sliders sit on the bottom-right of the card, one above the other, so the
            -- list stops ABOVE both of them. Reserving the whole band here - rather than drawing the sliders over the
            -- last row - is what keeps a row from hiding under a control at any window height or scale.
            local footer_h = S(FOOTER_ROW * FOOTER_ROWS)
            local rh = y + h - S(16) - footer_h - ry
            if rh > S(24) then
                imgui.SetCursorScreenPos({ rx, ry })
                if imgui.BeginChild('##st_rows', { rw, rh }, 256, 0) then
                    -- the CHILD's draw list, not the window's: it clips to the list, so a row can never paint over
                    -- the header or past the card's bottom edge (auctionhouse-vanacore.lua:2242 does the same)
                    local cdl = imgui.GetWindowDrawList()
                    local rows = st.rows or {}
                    local step_y = row_h() + S(4)
                    -- the child's scrollbar takes the right edge: the rows stop before it, so a Wiki button is never
                    -- half under the grab
                    local row_w = rw - S(12)
                    -- the content height, so the wheel has something to scroll even when rows are culled below
                    imgui.Dummy({ 1, math.max(1, #rows * step_y + S(4)) })
                    if #rows == 0 then
                        U.text_center(cdl, rx, ry + S(24), row_w, 'nothing to learn - try Show learnt or All', P.faint, F.text, T.small)
                    else
                        local scroll = 0
                        local ok_sc, sy = pcall(imgui.GetScrollY)
                        if ok_sc and tonumber(sy) then scroll = sy end
                        local first = math.max(1, math.floor(scroll / step_y) + 1)
                        local last = math.min(#rows, first + math.ceil(rh / step_y) + 2)
                        -- one row renderer for both kinds: a die row's roll and COR level are columns the same
                        -- function draws, not a second renderer to keep in step
                        local render = draw_row
                        for i = first, last do
                            local row = rows[i]
                            if type(row) == 'table' then
                                -- laid out from the scroll, not from the row's index: `ry - scroll` is where the
                                -- first row sits on screen, so the list moves under the wheel and a click lands on
                                -- the row the player sees (dropping it drew row 40 over the header)
                                local yy = ry - scroll + (i - 1) * step_y
                                local ok_row, row_err = pcall(render, cdl, rx, yy, row_w, row, i)
                                if not ok_row then fail('row', row_err) end
                            end
                        end
                    end
                    imgui.EndChild()
                end
            end

            -- The footer: the two scales as REAL controls on the bottom-right of the card, because "the letters are
            -- too small" and "I cannot hit the pill" are things a player fixes by dragging rather than by typing a
            -- number. Both are the kit's own slider (ui.lua's track, fill, knob and value label), not hand-rolled
            -- tracks, and each drives the same setting its command drives. One place, both knobs: no settings tab.
            --
            -- Right-aligned with the window's 18 px padding, with the corner left empty - NoResize is off, so the
            -- bottom-right corner is the resize grip, and a slider that reached it would swallow the grip. The value
            -- label's right edge is the control's real right edge, and that is what sits S(18) inside the window.
            local pill_cy = y + h - S(16) - S(FOOTER_ROW / 2)
            local text_cy = pill_cy - S(FOOTER_ROW)
            local picked, moved, released = footer_slider(dl, '##st_text', 'Text', x, w, text_cy,
                st.text_drag or text_pct(), nil)
            -- the frame it is being dragged on draws the value it reports; the setting is written ONCE, when the mouse
            -- lets go, so a drag does not save the settings file on every frame
            if moved and tonumber(picked) then st.text_drag = math.floor(tonumber(picked) + 0.5) end
            if released then
                local n = clamp_pct(st.text_drag or picked)
                local changed = cfg.text_scale ~= n
                st.text_drag = nil
                if changed then
                    cfg.text_scale = n
                    save()
                end
            end
            -- The pill scale. The full window cannot show what it does - the window does not resize with it - so its
            -- value label is the only feedback here, and the word says which surface it is.
            local ppicked, pmoved, preleased = footer_slider(dl, '##st_pill', 'Pill', x, w, pill_cy,
                st.pill_drag or pill_pct(),
                'Pill scale: the size of the window while it is folded to the pill (it does not resize this window)')
            if pmoved and tonumber(ppicked) then st.pill_drag = math.floor(tonumber(ppicked) + 0.5) end
            if preleased then
                local n = clamp_pct(st.pill_drag or ppicked)
                local changed = cfg.pill_scale ~= n
                st.pill_drag = nil
                if changed then
                    cfg.pill_scale = n
                    save()
                end
            end

            -- Escape at the window closes it, unless the search box owns it: clearing text must not shut the card
            if not escaped and not search_focused and imgui.IsWindowFocused(3) and imgui.IsKeyPressed(U.KEY_ESCAPE) then
                set_open(false)
            end
        end)
        if not ok then fail('window', err) end
    end
    imgui.End()
    U.pop_theme()
    U.set_window_alpha(1)
end

-------------------------------------------------------------------------------
-- Present
-------------------------------------------------------------------------------

local function tick()
    local t = imgui.GetTime()
    local dt = 0.016
    do
        local ok, io = pcall(imgui.GetIO)
        if ok and type(io) == 'table' and tonumber(io.DeltaTime) then
            dt = math.max(0.001, math.min(0.1, io.DeltaTime))
        end
    end
    st.anim = U.lerp(st.anim or 0, st.open and 1 or 0, math.min(1, dt * 12))
    if not st.open and st.anim < 0.02 then st.anim = 0 end
    if not (st.open or st.anim > 0 or #U.anim.toasts > 0) then return end
    if not U.frame(dt, scale_pct() / 100, t) then return end
    if PAD ~= nil then
        pcall(PAD.frame, t, { id = 'spelltracker', capture = function () return st.open end })
        local ok_shown, pad_shown = pcall(PAD.shown)
        U.anim.pad_shown = ok_shown and pad_shown == true
    end
    local me = current_player()
    -- the window can be open without set_open having run in this frame (a saved-open restore): the first drawn frame
    -- while open is the other place the ledger is asked for, and st.ledger_asked keeps it to one try an opening
    if st.open and not st.ledger_asked then
        st.ledger_asked = true
        request_ledger(false)
    end
    -- the bags are read before the rows: an empty bag, a nil container and a character at the select screen all have
    -- to end up with unheld rows, never with a frame that raised
    refresh_rows(me, scan_bags())
    if st.open or st.anim > 0 then draw_window(me, t) end
    U.draw_toasts(t)
end

local function listen(name, fn)
    pcall(vana.events.on, name, fn)
end

listen('present', function ()
    local ok, err = pcall(tick)
    if not ok then fail('present', err) end
end)

-- the ledger's answer. Registered unconditionally: a pcall around the parse means one malformed 0x1A4 can never
-- take the frame that reads it down, and the handler checks the id before touching a byte. The registration is
-- written out rather than routed through listen() above for the same reason the request is: the policy scan's
-- packet_handlers signal matches the symbol, and an addon that reads every packet should say so in its scan.
do
    local ok = pcall(function ()
        vana.events.on('packet_in', function (e)
            local parsed, err = pcall(ledger_packet, e)
            if not parsed then fail('ledger', err) end
        end)
    end)
    if not ok then
        -- no packet surface: the window still draws, it just never learns what is stored
        fail('ledger', 'this client has no vana.events.on')
    end
end

-- The zone alerts' two events, registered with the symbol written out for the same reason packet_in is: the policy
-- scan (tools/addon_vet/scan.py) matches the literal vana.events.on('<name>') call, and an addon that reads the
-- game's own state events should say so in its scan rather than hide behind the listen() helper. Both inside ONE
-- pcall: a client with no vana.events.on loses the alerts and never the window, and each handler parses nothing, so
-- a bad zone id costs an announcement rather than the frame the event arrived on.
do
    local ok = pcall(function ()
        vana.events.on('zone_change', function (e)
            local watched, err = pcall(zone_in, e)
            if not watched then fail('zone', err) end
        end)
        -- login carries the zone too (docs/addons/02-events.md:66-76): the zone a session starts in is not a
        -- zone_change, so without this the first zone of a session would never be announced
        vana.events.on('login', function (e)
            local watched, err = pcall(zone_in, e)
            if not watched then fail('zone', err) end
        end)
    end)
    if not ok then
        -- no event surface: the window still draws, it just never says what is in a zone
        fail('zone', 'this client has no vana.events.on')
    end
end

listen('load', function ()
    -- the theme files first: a player's own themes\<id>.lua is not in THEME_BY_ID until load_theme_files runs, so
    -- checking the saved id before it would silently fall back to aurora for a theme that exists (AH does the same,
    -- auctionhouse-vanacore.lua:4040)
    pcall(U.load_theme_files)
    local theme = cfg.theme or 'aurora'
    if U.THEME_BY_ID[theme] == nil then theme = 'aurora' end
    U.apply_theme(theme)
    if PAD ~= nil then pcall(PAD.setup, 'spelltracker', U) end
    pcall(vana.log, 'spelltracker-vanacore ' .. addon.version .. ' loaded'
        .. (CORE == nil and ' (spells_core.lua is missing: the list stays empty)' or '')
        .. (DCORE == nil and ' (dice_core.lua is missing: no die rows in the list)' or ''))
end)

listen('unload', function ()
    if PAD ~= nil then pcall(PAD.teardown, 'spelltracker') end
    save()
    pcall(U.release_textures)
end)

-------------------------------------------------------------------------------
-- Commands
-------------------------------------------------------------------------------

local HELP = '/spells [toggle|show|hide|minimize|minimize off|reset|mode ace|cw|wew|theme <id>|scale <50-300>|text <50-300>|pill <50-300>|learned on|off|now on|off|held on|off|here|alerts on|off|alerts shop|drop|bcnm on|off|alerts sound on|off|sync|rescan|sound on|off|debug]'

listen('command', function (e)
    local words = {}
    for word in tostring(e.command or ''):gmatch('%S+') do words[#words + 1] = word end
    local cmd = (words[1] or ''):lower()
    -- both slashes: a Windower habit that works on every other command, and silently doing nothing is worse than
    -- answering
    if cmd ~= '/spells' and cmd ~= '//spells' then return false end
    local what = (words[2] or 'toggle'):lower()
    local arg = (words[3] or ''):lower()

    if what == '' or what == 'toggle' then
        set_open(not st.open)
    elseif what == 'show' then
        set_open(true)
    elseif what == 'hide' or what == 'close' then
        set_open(false)
    elseif what == 'minimize' then
        -- the keyboard route to the same state the header button sets. Off restores; anything else (or nothing) folds
        -- the window to the pill, opening it first so a closed tracker answers with a pill rather than silently doing
        -- nothing. Both save through set_minimized, so a reload comes back the same way.
        if arg == 'off' or arg == 'no' then
            set_open(true)
            set_minimized(false)
            say('window restored')
        else
            set_open(true)
            set_minimized(true)
            say('minimized to the pill: click it to restore, or /spells minimize off')
        end
    elseif what == 'reset' then
        cfg.x, cfg.y = nil, nil
        cfg.scale = DEFAULTS.scale
        cfg.text_scale = DEFAULTS.text_scale
        cfg.pill_scale = DEFAULTS.pill_scale
        cfg.w, cfg.h = nil, nil
        cfg.opacity = DEFAULTS.opacity
        st.recenter, st.cache_key = true, nil
        -- a reset during a drag drops the drag, so both sliders come back at 100 with the rest
        st.text_drag, st.pill_drag = nil, nil
        save()
        say('position, size, text and pill scale, and opacity back to their defaults')
    elseif what == 'mode' then
        if not set_mode(arg) then say('modes: ' .. mode_list()) end
    elseif what == 'theme' then
        if U.THEME_BY_ID[arg] ~= nil then
            cfg.theme = arg
            U.apply_theme(arg)
            save()
            say('theme: ' .. tostring(U.THEME_BY_ID[arg].name or arg))
        else
            say('themes: ' .. theme_list())
        end
    elseif what == 'scale' then
        local n = tonumber(arg)
        if n == nil then
            say('/spells scale <50-300>, now ' .. scale_pct() .. '%')
        else
            cfg.scale = clamp_pct(n)
            st.cache_key = nil
            save()
            say('scale: ' .. cfg.scale .. '%')
        end
    elseif what == 'text' then
        -- the readability knob: the font sizes only. It is also the slider on the bottom-right of the window, and this
        -- is the keyboard route to the same number.
        local n = tonumber(arg)
        if n == nil then
            say('/spells text <50-300>, now ' .. text_pct() .. '%  (the same as the slider, bottom right)')
        else
            cfg.text_scale = clamp_pct(n)
            st.text_drag = nil
            save()
            say('text scale: ' .. text_pct() .. '%')
        end
    elseif what == 'pill' then
        -- the capsule only: the window, the list and the letters are untouched by it
        local n = tonumber(arg)
        if n == nil then
            say('/spells pill <50-300>, now ' .. pill_pct() .. '%')
        else
            cfg.pill_scale = clamp_pct(n)
            st.pill_drag = nil
            save()
            say('pill scale: ' .. pill_pct() .. '%')
        end
    elseif what == 'learned' then
        if arg == 'on' or arg == 'off' then
            set_learned(arg == 'on')
            say('showing learnt spells and dice: ' .. arg)
        else
            say('/spells learned on|off')
        end
    elseif what == 'now' then
        if arg == 'on' or arg == 'off' then
            set_only_now(arg == 'on')
            say('only what you can use now: ' .. arg)
        else
            say('/spells now on|off')
        end
    elseif what == 'held' then
        if arg == 'on' or arg == 'off' then
            set_held_only(arg == 'on')
            say('only what is in your bags: ' .. arg)
        else
            say('/spells held on|off')
        end
    elseif what == 'here' then
        -- the same listing the zone-in makes, on demand: the zone the player is in now, and no last-zone memory
        list_zone()
    elseif what == 'alerts' then
        -- '/spells alerts on|off' is the master switch; '/spells alerts shop|drop|bcnm on|off' silences one kind;
        -- '/spells alerts sound on|off' keeps the highlight and drops the chime. All save like every other setting,
        -- and all say what changed. A bare '/spells alerts' answers with every switch, which is the only way to see
        -- the per-kind ones without reading the settings file.
        local state = (words[4] or ''):lower()
        if arg == 'on' or arg == 'off' then
            cfg.zone_alerts = arg == 'on'
            save()
            say('zone alerts: ' .. arg)
        elseif arg == 'sound' and (state == 'on' or state == 'off') then
            cfg.zone_sound = state == 'on'
            save()
            say('zone alert chime: ' .. state)
        elseif (arg == 'shop' or arg == 'drop' or arg == 'bcnm') and (state == 'on' or state == 'off') then
            if arg == 'shop' then cfg.alert_shop = state == 'on'
            elseif arg == 'drop' then cfg.alert_drop = state == 'on'
            else cfg.alert_bcnm = state == 'on' end
            save()
            say(string.format('%s zone alerts: %s', arg, state))
        else
            say(alert_status())
        end
    elseif what == 'sync' then
        -- the owner's way past the 60 s gate: they just stored a scroll and want the marker now
        if LEDGER == nil then
            say('scroll_ledger.lua is missing: the server can be asked, but there is no table to decode the answer with')
        elseif st.ledger_locked then
            say('the scroll ledger is Crystal Warrior only: nothing to sync for this character')
        elseif request_ledger(true) then
            say('asked the server for the scroll ledger (one packet, 0x1A4): the markers update when it answers')
        else
            say('no request went out: no character in the world, or the client has no packet surface')
        end
    elseif what == 'rescan' then
        -- the owner's way out of the 4 s cache: they just moved a scroll and want the row marked now
        st.scan_at = nil
        local scan = scan_bags()
        st.cache_key = nil
        if st.open then refresh_rows(current_player(), scan) end
        say(string.format('bags read: %s - %d scrolls held', bag_list(scan), held_count(scan and scan.held)))
    elseif what == 'sound' then
        if arg == 'on' or arg == 'off' then
            cfg.open_sound = arg == 'on'
            save()
            say('opening sound: ' .. arg)
            if cfg.open_sound then play_bell() end
        else
            say('/spells sound on|off')
        end
    elseif what == 'debug' then
        -- measured now, not whenever the window last drew: the command works with the window shut, and it forces a
        -- fresh scan so the two bag lines are this moment's answer rather than the cache's
        st.cache_key = nil
        st.scan_at = nil
        local scan = scan_bags()
        refresh_rows(current_player(), scan)
        local c = st.counts or {}
        say(string.format('%d shown, %d in the job, %d learnt, %d to learn, %d out of reach at %d',
            #(st.rows or {}), tonumber(c.total) or 0, tonumber(c.learned) or 0, tonumber(c.missing) or 0,
            tonumber(c.unreachable) or 0, tonumber(DATA and DATA.level_cap) or 75))
        -- the three scales, because 'the text is too small' and 'the window is too small' are different fixes, and the
        -- size ImGui answered is where a legibility complaint actually starts
        say(string.format('scales: window %d%%, text %d%%, pill %d%%', scale_pct(), text_pct(), pill_pct()))
        local ww, wh = tonumber(st.win_w), tonumber(st.win_h)
        if ww ~= nil and wh ~= nil then
            say(string.format('window: %d x %d (%s)', math.floor(ww), math.floor(wh),
                (tonumber(cfg.w) ~= nil and tonumber(cfg.h) ~= nil) and 'resized by hand' or 'the default for this scale'))
        else
            say('window: not drawn yet this session, so its size is not measured')
        end
        say('bags read: ' .. bag_list(scan))
        say(string.format('held scrolls: %d', held_count(scan and scan.held)))
        -- the ledger, in the three facts that explain a missing or wrong marker: how many pages came back, how many
        -- rows that marks, and whether the server refused. 'asked' is on the client's clock, not a guess.
        local asked = 'never'
        if st.ledger_at ~= nil then
            local now = clock_now()
            if now ~= nil then asked = string.format('%ds ago', math.max(0, math.floor(now - st.ledger_at)))
            else asked = 'yes' end
        end
        say(string.format('ledger: %d pages, %d stored, locked=%s, asked %s',
            #(st.masks or {}), tonumber((st.counts or {}).stored) or 0,
            st.ledger_locked and 'yes' or 'no', asked))
        say('last error: ' .. tostring(st.last_error or 'none'))
        if CORE == nil then say('spells_core.lua is missing: no rows can be built') end
        -- the zone line: which zone the client names, the key both tables meet on, how many spells the shipped table
        -- sources there at all, and whether the alerts are armed. The count is the table's, not this job's, so a
        -- player can tell 'nothing here for me' from 'this zone is not in the table'
        local zid = current_zone()
        local zname = zone_name(zid)
        local zkey = zname ~= nil and zone_key_of(zname) or ''
        say(string.format("zone '%s' (%s), %d sourced spells here, alerts %s",
            tostring(zname or '?'), zkey ~= '' and zkey or 'none', zone_sourced(zkey),
            alerts_listening() and 'on' or 'off'))
        -- the dice line, the same three facts as the row line above it: how many the table has, how many the client
        -- says are learnt, and how many it places in the zone the player is standing in. The third is the table's
        -- count, not this character's, so 'no die here' and 'the wiki has no die here' stay different answers.
        local dc = st.dice_counts or {}
        say(string.format('dice %d rows, %d known, %d with a source in this zone',
            tonumber(dc.total) or 0, tonumber(dc.known) or 0, dice_zone_sourced(zkey)))
        if DCORE == nil then say('dice_core.lua is missing: no dice can be listed') end
        if DDATA == nil then say('dice_data.lua is missing: no die sources can be listed') end
    else
        say(HELP)
    end
    return true
end)

SPELLTRACKER = st -- (this addon's own state: for a test's eyes, through VanaCore's MCP)
