--[[
spelltracker (SpellTracker): what this job can still learn, and where each scroll comes from.

The list is built from the game's own data: the levels are vana.gamedata.spells (VanaCore's table, generated from
CatsEyeXI's sql/spell_list.sql) and whether a spell is known is vana.game.spells(), the game's own 128-byte bitfield.
Nothing here guesses a level, and no vendor note is invented: a spell whose scroll page could not be read shows a
neutral '?' badge that says so.

In game:

  /spells                  the window on or off
  /spells show | hide      the same, said outright
  /spells reset            position, scale and opacity back to their defaults
  /spells mode ace|cw|wew  which acquisition systems the badges allow (ACE, Crystal Warrior, Wings Era Warrior)
  /spells theme <id>       one of the UI kit's themes; no id lists them
  /spells scale <50-300>   the window's size
  /spells learned on|off   show the spells already learnt, too
  /spells now on|off       only the spells you could cast this minute
  /spells held on|off      only the spells whose scroll is already in one of your bags
  /spells here             what this job still needs in the zone you are in, with where to get each one
  /spells alerts on|off    the zone-in notice on or off (one toast and one chat line, never twice for one zone)
  /spells alerts shop|drop|bcnm on|off   silence one of the three kinds of place
  /spells sync             ask the server for the scroll ledger now (Crystal Warrior: Gramateus / the box)
  /spells rescan           read the bags again now instead of waiting for the cache
  /spells sound on|off     the bell as the window opens
  /spells debug            the row counts, the bags, the ledger and the zone it could read, and the last error, in chat

Click a spell's badge to search the CatsEyeXI database, its Wiki button for BG-Wiki, or double-click the row for the
database. The window is drawn with the family's ui.lua kit, so it looks like the other VanaCore addons and follows the
theme, the scale and the controller.
--]]

addon.name    = 'spelltracker-vanacore'
addon.author  = 'koikaze'
addon.version = '0.1.1'
addon.desc    = 'SpellTracker: the spells this job can still learn, with where each one comes from.'

local imgui = vana.imgui
if imgui == nil then
    print('spelltracker-vanacore needs a newer VanaCore.Core.dll (vana.imgui)')
    return
end

local U = require('ui')
local P, F, T = U.P, U.fonts(), U.sizes()
local S = U.S

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

-------------------------------------------------------------------------------
-- Settings and state
-------------------------------------------------------------------------------

local DEFAULTS = {
    theme = 'aurora', scale = 100, mode = 'ace', show_learned = false, skill = 'all',
    -- the two Phase-2 filters: 'usable now' and 'in storage'. Per character like the rest, because a mule and a
    -- main want different answers out of the same window.
    only_now = false, held_only = false,
    -- the zone alerts (Phase 4). One master switch and one per kind of place, so a player who never wants to hear
    -- about a battlefield can keep the vendor notices. Per character with everything else.
    zone_alerts = true, alert_shop = true, alert_drop = true, alert_bcnm = true,
    x = nil, y = nil, opacity = 100, open_sound = true,
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
    -- the zone alerts: the zone index built once from spell_sources, the last zone key that was announced (a Mog House
    -- in-and-out re-raises zone_change with the same zone), the last zone id any event carried (the fallback for
    -- /spells here), and the plain row list the alerts read - a second list, so the window's own filters cannot
    -- change what is announced
    zone_idx = nil, last_zone_key = nil, last_zone_id = nil,
    plain_rows = {}, plain_key = nil,
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

-- palette KEYS, not colours: P is filled by U.apply_theme and refilled by /spells theme, so a colour captured here
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
local function scale_pct()
    local n = tonumber(cfg.scale) or 100
    return math.max(50, math.min(300, math.floor(n)))
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

local function play_bell()
    local dir = addon_dir()
    if dir == nil then return end
    local path = dir .. '\\sounds\\small_bell.wav'
    local ok, here = pcall(vana.fs.exists, path)
    if ok and here then pcall(vana.system.play_sound, path) end
end

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
                                scan.slots[#scan.slots + 1] = {
                                    name = name, bag = BAG_NAME[id] or ('bag ' .. tostring(id)),
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

-- rebuilding is keyed on everything that can change a row: the character's jobs, the bitfield, the filters. Typing in
-- the search box thus costs one rebuild per keystroke, not one per frame. The scan generation is in the key because a
-- new bag scan changes row.held without changing anything else.
--
-- One builder, two lists. `plain` is the zone alerts' list: the same rows with the view's own filters OFF (nothing
-- learnt, no search, no skill pill, no 'usable now', no 'in storage'), because a search box is a way of looking at
-- the list and never a claim about what the player still needs - announcing 'Lower Jeuno: {the one spell matching
-- your query}' would be a lie about the zone. Each list keeps its own cache key, so one build never blanks the other.
local function rebuild(me, bits, scan, plain)
    local view = plain ~= true
    local held = (scan and scan.held) or nil
    local key = table.concat({
        view and 'view' or 'plain',
        me.job, me.level, me.sub_job, me.sub_level,
        tostring(cfg.mode), tostring(view and cfg.show_learned == true),
        tostring(view and cfg.skill or 'all'), (view and st.query[1]) or '', bits or '',
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

    local spells = spell_table()
    if spells ~= nil then spells = spell_array(spells) end
    if CORE == nil or type(CORE.rows) ~= 'function' or spells == nil or me.job <= 0 then return end
    local data = DATA or { modes = {}, tags = {}, skills = {}, skip_types = {}, level_cap = 75 }
    -- spells_core reads sources by spell id, so it wants the generated map, not the module around it
    local sources = (SOURCES and type(SOURCES.spells) == 'table') and SOURCES.spells or {}
    local cap = tonumber(data.level_cap) or 75
    -- the ledger's answer, folded into a name set. nil (no table, no answer yet) is passed as nil on purpose: an
    -- empty set would be a claim that nothing is stored, and spells_core can tell the two apart
    local stored = nil
    if type(LEDGER) == 'table' and type(st.masks) == 'table' and type(CORE.ledger_stored) == 'function' then
        local ok_l, set = pcall(CORE.ledger_stored, LEDGER, st.masks)
        if ok_l and type(set) == 'table' then stored = set end
    end

    -- the counts are the whole job's list, not the filtered view: '12 to learn' should not fall when a search narrows
    -- the view, and the header's 'N scrolls already in your bags' is counted against the same list for the same
    -- reason (a filter must not look as if the scrolls left the bags)
    if view then
        local ok_all, all = pcall(CORE.rows, spells, {
            job = me.job, level = me.level, sub_job = me.sub_job, sub_level = me.sub_level,
            bits = bits, show_learned = true, mode = cfg.mode, data = data, sources = sources, cap = cap, held = held,
            stored = stored,
        })
        if ok_all and type(all) == 'table' then
            local ok_c, counts = pcall(CORE.counts, all)
            if ok_c and type(counts) == 'table' then st.counts = counts end
        elseif not ok_all then
            fail('rows', all)
        end
    end

    local skill = nil
    if view and cfg.skill ~= nil and cfg.skill ~= 'all' then skill = cfg.skill end
    local ok_rows, rows = pcall(CORE.rows, spells, {
        job = me.job, level = me.level, sub_job = me.sub_job, sub_level = me.sub_level,
        bits = bits, query = view and st.query[1] ~= '' and st.query[1] or nil, skill = skill,
        mode = cfg.mode, show_learned = view and cfg.show_learned == true, data = data, sources = sources, cap = cap,
        held = held, only_now = view and cfg.only_now == true, stored = stored,
    })
    if ok_rows and type(rows) == 'table' then
        -- 'in storage' is the window's own filter, not spells_core's: it is one pass over the rows the core just
        -- built and sorted, so the order the player sees is untouched
        if view and cfg.held_only == true then
            local with_scroll = {}
            for i = 1, #rows do
                if rows[i].held ~= nil then with_scroll[#with_scroll + 1] = rows[i] end
            end
            rows = with_scroll
        end
        if view then st.rows = rows else st.plain_rows = rows end
    else
        fail('rows', rows)
    end
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

-- open_url says whether it started the browser; where it did not, the link still reaches the player on the clipboard
local function open_link(url)
    if type(url) ~= 'string' or url == '' then
        U.toast('warn', 'No link', 'this spell has no address to open', 4, 'circle-info')
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
    local urls = row_urls(row)
    open_link(urls and urls.database or nil)
end

local function open_wiki(row)
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

-- The rows the alerts read: the window's own builder with `plain` set, which is the same list minus the view's
-- filters and minus the learnt spells. The scan is reused (st.scan) because the zone handlers run between frames and
-- a fresh 18-bag walk is not worth it; a nil scan simply means no 'held' markers, which no alert reads.
local function plain_rows()
    local scan = st.scan
    if scan == nil then scan = scan_bags() end
    rebuild(current_player(), game_bits(), scan, true)
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

-- A toast is one line of text wide, so the names are capped there and the chat line carries the citations. Six is
-- enough for the ordinary case (most zones source a handful of what one job needs) and keeps the toast on screen.
local ZONE_TOAST_NAMES = 6
-- Ten entries is a chat line the log can still show above the scroll: kind, spell and the generated note, which is
-- the citation the whole feature exists for ('shop: Cure IV - Hasim / Lower Jeuno - (H-9) / 23,400 Gil').
local ZONE_CHAT_ENTRIES = 10

local function hit_names(hits)
    local names = {}
    for i = 1, #hits do
        if i > ZONE_TOAST_NAMES then break end
        local h = hits[i]
        names[#names + 1] = tostring(h.row and h.row.name or '?')
    end
    local text = table.concat(names, ', ')
    if #hits > ZONE_TOAST_NAMES then
        text = text .. string.format(' and %d more', #hits - ZONE_TOAST_NAMES)
    end
    return text
end

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

local function scroll_note(n)
    return string.format('%d scroll%s', n, n == 1 and '' or 's')
end

-- One toast and one chat line, in the shapes the rest of the file already uses (open_link's toast, say's '[Spells]'
-- prefix). Information only: no packet, no command, no chat input, no movement.
local function zone_report(label, hits)
    say(string.format('%s - %s to find - %s', label, scroll_note(#hits), hit_list(hits)))
end

local function announce_zone(label, hits)
    U.toast('info', label, scroll_note(#hits) .. ' here: ' .. hit_names(hits), 8, 'scroll')
    zone_report(label, hits)
end

-- One zone-in, once. Nothing here writes to the game: no packet, no command, no action.
local function zone_in(e)
    local id = type(e) == 'table' and e.zone or nil
    if tonumber(id) ~= nil and tonumber(id) > 0 then st.last_zone_id = tonumber(id) end
    local name = zone_name(id)
    if name == nil then return false end
    local key = zone_key_of(name)
    if key == '' then return false end
    -- the master switch. Read as == true so a hand-edited settings file with no key stays quiet instead of
    -- announcing something the player never asked for
    if cfg.zone_alerts ~= true then return false end
    -- a Mog House in-and-out re-raises zone_change with the same zone: the player has not moved anywhere new
    if st.last_zone_key == key then return false end
    local hits = zone_hits(key)
    if #hits == 0 then return false end
    -- latched only once something was said. A zone with nothing to announce must not poison the memory, and a login
    -- whose player table had not filled in yet (job 0 builds no rows) has to be able to speak on the next event.
    st.last_zone_key = key
    announce_zone(name, hits)
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

-- /spells here. Always answers: a listing, or the reason there is nothing to list (no zone named yet, or a zone the
-- table sources nothing this job needs). It ignores last_zone_key on purpose - the player asked - and it is not
-- gated by cfg.zone_alerts: the master switch is about the automatic notice, a typed command is not an interruption.
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
    if #hits == 0 then
        say(string.format('%s - nothing here this job still needs (%d spells sourced in this zone)',
            name, zone_sourced(key)))
        return
    end
    zone_report(name, hits)
end

-- the three alert switches, said in one line for /spells alerts with no argument and for /spells debug
local function alert_status()
    return string.format('zone alerts: %s (shop %s, drop %s, bcnm %s)',
        cfg.zone_alerts == true and 'on' or 'off',
        cfg.alert_shop == true and 'on' or 'off',
        cfg.alert_drop == true and 'on' or 'off',
        cfg.alert_bcnm == true and 'on' or 'off')
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
local function draw_search(dl, x, cy, w)
    local h = S(28)
    imgui.SetCursorScreenPos({ x, cy - h / 2 })
    imgui.SetNextItemWidth(w)
    -- ImGuiStyleVar_FramePadding (11): the kit's 12 px padding, pushed out to make room for the icon
    imgui.PushStyleVar(11, { S(30), S(7) })
    local ok, err = pcall(U.with_font, F.text, T.small, function ()
        imgui.InputTextWithHint('##st_search', 'search spells', st.query, 48, 0)
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

local function draw_row(dl, x0, y0, rw, row, i)
    local rowh = S(34)
    local key = '##st_row_' .. tostring(row.id or i)
    local learned = row.learned == true
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
    dl:AddRectFilled({ x0, y0 }, { x0 + rw, y0 + rowh }, U.u32(U.mix(P.card, P.card_hi, 0.85 * hv)), S(8))
    dl:AddRect({ x0, y0 }, { x0 + rw, y0 + rowh }, U.u32(P.line, 0.8), S(8), 15, 1)

    local cy = y0 + rowh / 2
    local dx = x0 + S(14)
    if learned then
        dl:AddCircleFilled({ dx, cy }, S(4), U.u32(P.ok, 0.95), 20)
    else
        dl:AddCircle({ dx, cy }, S(4), U.u32(P.faint, 0.9), 20, 1)
    end

    local name = tostring(row.name or '?')
    local name_col = learned and U.mix(P.text, P.ok, 0.35) or P.text
    if row.unreachable then name_col = U.mix(P.text, P.danger, 0.45) end
    local name_w = rw * 0.42
    U.text_mid(dl, x0 + S(26), cy, U.fit(name, F.text, T.small, name_w), name_col, F.text, T.small)

    local lx = x0 + rw * 0.46
    local lv = tonumber(row.level) or 0
    U.text_mid(dl, lx, cy, 'Lv ' .. lv, row.unreachable and P.danger or P.dim, F.semi, T.tiny)
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

    -- the scroll is already in a bag: the marker names the bag on hover, and says where the rest are when the player
    -- has the same spell in more than one (a copy in the satchel is why 'in your Inventory' alone is not the answer)
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

local function draw_window(me)
    local sw, sh = 1920, 1080
    do
        local ok, w, h = pcall(vana.ui.screen)
        if ok and tonumber(w) and tonumber(h) then sw, sh = w, h end
    end
    local sc = scale_pct() / 100
    -- wider than the list needs, because the controls row has to hold three switches, the mode segments and the
    -- search box side by side: at 700 the third one lands on top of the search field (measured at the kit's 13 px face)
    local w = math.max(S(320), math.floor(S(880)))
    local h = math.max(S(260), math.floor(S(560)))
    w = math.min(w, sw - S(20))
    h = math.min(h, sh - S(20))

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
    imgui.SetNextWindowSize({ w, h }, U.ALWAYS)
    if st.focus_frames > 0 then
        imgui.SetNextWindowFocus()
        st.focus_frames = st.focus_frames - 1
    end

    local fade = U.ease(st.anim)
    U.set_window_alpha(fade * opacity())
    U.push_theme()
    if imgui.Begin('##spelltracker', nil, U.WINDOW_FLAGS) then
        local ok, err = pcall(function ()
            local dl = imgui.GetWindowDrawList()
            local x, y = imgui.GetWindowPos()
            -- keep it on screen, but not while it is being dragged: fighting the mouse makes the drag stutter
            local kx = math.max(0, math.min(x, sw - w))
            local ky = math.max(0, math.min(y, sh - h))
            if (kx ~= x or ky ~= y) and not imgui.IsMouseDown(0) then imgui.SetWindowPos({ kx, ky }) end
            if not imgui.IsMouseDown(0) and (cfg.x ~= kx or cfg.y ~= ky) then
                cfg.x, cfg.y = kx, ky
                save()
            end
            x, y = kx, ky
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
            local line = string.format('%d to learn - %d learnt', tonumber(counts.missing) or 0, tonumber(counts.learned) or 0)
            U.text(dl, x + S(60), y + S(44), line, P.dim, F.text, T.small)
            -- how many of this job's spells already have their scroll in a bag. Counted against the whole job list
            -- (st.counts), and only falls back to the smaller 'showing' number when a filter is on and the rows are
            -- still visible: narrowing the search must not look as if the scrolls left the bags.
            local held_total = tonumber(counts.held) or 0
            -- where the next header line would start. Measured from the kit, never guessed: the header has a hard
            -- right edge (the close button) and the lines share one row at the 700..880 px width.
            local hx = x + S(60) + U.measure(line, F.text, T.small) + S(14)
            if held_total > 0 then
                local held_shown = 0
                local shown_rows = st.rows or {}
                for i = 1, #shown_rows do if shown_rows[i].held ~= nil then held_shown = held_shown + 1 end end
                local n = held_shown > 0 and held_shown or held_total
                local bag_text = string.format('%d scrolls already in your bags', n)
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
                if hx + store_w <= x + w - S(42) - S(12) then
                    U.text(dl, hx, y + S(44), store_text, P.accent, F.semi, T.small)
                end
            end
            if U.icon_button(dl, '##st_close', x + w - S(42), y + S(14), S(26), 'xmark', P.dim, 'Close') then
                set_open(false)
            end
            dl:AddLine({ x + S(18), y + S(66) }, { x + w - S(18), y + S(66) }, U.u32(P.line, 0.9), 1)

            -- controls: the mode, the three filters, the search
            local cy = y + S(86)
            local mode_opts = {}
            for _, md in ipairs(modes()) do mode_opts[#mode_opts + 1] = { md.id, md.label or md.id } end
            local _, mw, clicked = U.segments(dl, '##st_mode', x + S(18), cy - S(13), S(26), mode_opts, cfg.mode,
                function (o) return pill_colour(MODE_COLOR, o[1], 'accent') end)
            if clicked then set_mode(clicked) end

            -- three independent AND filters, each saved on click like the learnt toggle. The switches are laid out
            -- left to right and the search box takes the room that is left, so a label a font wider cannot overlap it.
            local ctl_x = x + S(18) + mw + S(22)
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
            local escaped, search_focused = draw_search(dl, search_x, cy, math.max(S(80), search_w))

            -- the skill pills: All, then the seven the file names
            local py = y + S(116)
            local skill_opts = { { 'all', 'All' } }
            for _, sk in ipairs(skills()) do
                if sk.id then skill_opts[#skill_opts + 1] = { sk.id, sk.label or sk.id } end
            end
            local _, _, sk_clicked = U.segments(dl, '##st_skill', x + S(18), py, S(24), skill_opts, cfg.skill or 'all',
                function (o) return pill_colour(SKILL_COLOR, o[1], 'accent2') end)
            if sk_clicked then set_skill(sk_clicked) end

            -- the list: a child gives the wheel and clips every row to its card, so nothing draws over the header
            local rx = x + S(18)
            local ry = py + S(34)
            local rw = w - S(36)
            local rh = y + h - S(16) - ry
            if rh > S(24) then
                imgui.SetCursorScreenPos({ rx, ry })
                if imgui.BeginChild('##st_rows', { rw, rh }, 256, 0) then
                    -- the CHILD's draw list, not the window's: it clips to the list, so a row can never paint over
                    -- the header or past the card's bottom edge (auctionhouse-vanacore.lua:2242 does the same)
                    local cdl = imgui.GetWindowDrawList()
                    local rows = st.rows or {}
                    local step_y = S(38)
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
                        for i = first, last do
                            local row = rows[i]
                            if type(row) == 'table' then
                                -- laid out from the scroll, not from the row's index: `ry - scroll` is where the
                                -- first row sits on screen, so the list moves under the wheel and a click lands on
                                -- the row the player sees (dropping it drew row 40 over the header)
                                local yy = ry - scroll + (i - 1) * step_y
                                local ok_row, row_err = pcall(draw_row, cdl, rx, yy, row_w, row, i)
                                if not ok_row then fail('row', row_err) end
                            end
                        end
                    end
                    imgui.EndChild()
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
    rebuild(me, game_bits(), scan_bags())
    if st.open or st.anim > 0 then draw_window(me) end
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
        .. (CORE == nil and ' (spells_core.lua is missing: the list stays empty)' or ''))
end)

listen('unload', function ()
    if PAD ~= nil then pcall(PAD.teardown, 'spelltracker') end
    save()
    pcall(U.release_textures)
end)

-------------------------------------------------------------------------------
-- Commands
-------------------------------------------------------------------------------

local HELP = '/spells [toggle|show|hide|reset|mode ace|cw|wew|theme <id>|scale <50-300>|learned on|off|now on|off|held on|off|here|alerts on|off|alerts shop|drop|bcnm on|off|sync|rescan|sound on|off|debug]'

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
    elseif what == 'reset' then
        cfg.x, cfg.y = nil, nil
        cfg.scale = DEFAULTS.scale
        cfg.opacity = DEFAULTS.opacity
        st.recenter, st.cache_key = true, nil
        save()
        say('position, scale and opacity back to their defaults')
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
            say('/spells scale <50-300>')
        else
            cfg.scale = math.max(50, math.min(300, math.floor(n)))
            st.cache_key = nil
            save()
            say('scale: ' .. cfg.scale .. '%')
        end
    elseif what == 'learned' then
        if arg == 'on' or arg == 'off' then
            set_learned(arg == 'on')
            say('showing learnt spells: ' .. arg)
        else
            say('/spells learned on|off')
        end
    elseif what == 'now' then
        if arg == 'on' or arg == 'off' then
            set_only_now(arg == 'on')
            say('only spells you can cast now: ' .. arg)
        else
            say('/spells now on|off')
        end
    elseif what == 'held' then
        if arg == 'on' or arg == 'off' then
            set_held_only(arg == 'on')
            say('only spells with a scroll in your bags: ' .. arg)
        else
            say('/spells held on|off')
        end
    elseif what == 'here' then
        -- the same listing the zone-in makes, on demand: the zone the player is in now, and no last-zone memory
        list_zone()
    elseif what == 'alerts' then
        -- '/spells alerts on|off' is the master switch; '/spells alerts shop|drop|bcnm on|off' silences one kind.
        -- Both save like every other setting, and both say what changed. A bare '/spells alerts' answers with the
        -- three switches, which is the only way to see the per-kind ones without reading the settings file.
        local state = (words[4] or ''):lower()
        if arg == 'on' or arg == 'off' then
            cfg.zone_alerts = arg == 'on'
            save()
            say('zone alerts: ' .. arg)
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
        if st.open then rebuild(current_player(), game_bits(), scan) end
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
        rebuild(current_player(), game_bits(), scan)
        local c = st.counts or {}
        say(string.format('%d shown, %d in the job, %d learnt, %d to learn, %d out of reach at %d',
            #(st.rows or {}), tonumber(c.total) or 0, tonumber(c.learned) or 0, tonumber(c.missing) or 0,
            tonumber(c.unreachable) or 0, tonumber(DATA and DATA.level_cap) or 75))
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
            cfg.zone_alerts == true and 'on' or 'off'))
    else
        say(HELP)
    end
    return true
end)

SPELLTRACKER = st -- (this addon's own state: for a test's eyes, through VanaCore's MCP)
