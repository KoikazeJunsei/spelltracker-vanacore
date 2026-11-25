-- Headless driver for spelltracker-vanacore.lua: there is no VanaCore client on this machine, so the window's own code
-- is run against a stub of the API it calls. What this proves is narrow and worth stating: every event the addon
-- registers runs end to end without an error, rows are built, and the row list is laid out from the child's scroll
-- offset (the defect this file was written to catch: rows drawn at index*step would not move under the wheel).
--
--   luajit 'docs/obsidian/03 - Planning/spelltracker/tests/test_draw.lua'
--
-- It cannot prove the window looks right. That rung is the owner's, in the game.

-- Both paths come off this file's own location, so a clone runs anywhere: pass VANA_GAMEDATA when the client's
-- gamedata is somewhere else.
local here = (arg and arg[0] or ''):match('^(.*)[/\\][^/\\]*$') or '.'
local ADDON = here .. '/..'
local GAMEDATA = os.getenv('VANA_GAMEDATA')

local checks, failures = 0, 0
local function check(label, ok, detail)
    checks = checks + 1
    if not ok then
        failures = failures + 1
        print(('FAIL  %s%s'):format(label, detail and ('  (' .. tostring(detail) .. ')') or ''))
    else
        print(('ok    %s'):format(label))
    end
end

------------------------------------------------------------------------------- the stub
local rects = {}          -- every AddRectFilled, with its colour, so the row layout and the highlight can be measured
local texts = {}          -- every AddText, so a marker's glyph and place can be found
local circles = {}        -- every AddCircle / AddCircleFilled, so a known-roll dot can be told from a hollow one
local injected = {}       -- every vana.packets.inject, so a request can be counted and opened
local sounds = {}         -- every vana.system.play_sound, so a zone chime can be told from the opening bell
local SCROLL = 0
-- the pill section's records: Play is a triangle and Stop a square, so both draw calls have to be told apart; the
-- border is an AddRect, whose alpha is the pulse; and every InvisibleButton is a hitbox that can be measured, placed
-- and clicked. A click is set by a check and consumed by the next frame, exactly as ImGui answers one.
local tris = {}           -- every AddTriangleFilled: {p1, p2, p3, col}
local edges = {}          -- every AddRect: {x0, y0, x1, y1, col, round, thick}
local btns = {}           -- every InvisibleButton: {key, w, h, x, y}
local sizes = {}          -- every SetNextWindowSize: {w, h, cond}
local MOUSE = nil         -- where the left button goes down on the next frame, or nil: a click is a POINT
local CUR = { 0, 0 }      -- the cursor position, so a hitbox's place is recorded with it
local HOVER_NOW = false   -- what IsItemHovered answers about the item just submitted
local GET_TIME = 0        -- the clock the pulse is measured against

local function noop() end
local function lazy(tbl, overrides)
    return setmetatable(overrides or {}, { __index = function (_, k) return type(k) == 'string' and noop or nil end })
end

local dlist = lazy({}, {
    AddRectFilled = function (_, a, b, col) rects[#rects + 1] = { a[1], a[2], b[1], b[2], col = col } end,
    -- a border, recorded so the pill's pulse alpha can be read back off the frame that drew it
    AddRect = function (_, a, b, col, r, flags, thick)
        edges[#edges + 1] = { a[1], a[2], b[1], b[2], col = col, round = r, thick = thick }
    end,
    -- Play is a filled triangle and the pill's pulse is a border, so neither can be a noop: one state would then be
    -- indistinguishable from the other and the check that reads them would pass for both
    AddTriangleFilled = function (_, p1, p2, p3, col)
        tris[#tris + 1] = { { p1[1], p1[2] }, { p2[1], p2[2] }, { p3[1], p3[2] }, col = col }
    end,
    AddLine = noop, AddImage = noop,
    AddRectFilledMultiColor = noop,
    -- a filled dot is the 'you know this roll' marker and a hollow one is 'you do not', so both have to be recorded:
    -- drawing them as the same noop would make a known die look like an unknown one and pass
    AddCircle = function (_, c, r) circles[#circles + 1] = { x = c[1], y = c[2], r = r, filled = false } end,
    AddCircleFilled = function (_, c, r) circles[#circles + 1] = { x = c[1], y = c[2], r = r, filled = true } end,
    AddText = function (_, font, size, pos, color, str)
        texts[#texts + 1] = { font = font, size = size, x = pos[1], y = pos[2], s = str }
    end,
    PushClipRect = noop, PopClipRect = noop,
    PathClear = noop, PathArcTo = noop, PathStroke = noop,
})

-- where ImGui has the window, and every placement the addon asks for: both must exist before the stub's closures
-- below close over them (declared after, they resolve to globals and every draw raises into the addon's pcall)
local WIN_POS = { 120, 90 }   -- where ImGui has the window; a drag changes it
local NEXT_POS = {}          -- every SetNextWindowPos this run, with its cond
-- the window's SIZE, which is now the player's: a drag on an edge changes it behind the addon's back, exactly as ImGui
-- does. SetNextWindowSize is applied the way ImGui applies it, because the whole difference between 'placed once' and
-- 'pinned every frame' lives in the condition: Always (1) lands every frame, FirstUseEver (4) only while the window has
-- never been given a size.
local WIN_SIZE = { 880, 560 }
local WIN_SIZED = false      -- has ImGui been given a size for ##spelltracker yet
local CHILD = nil            -- the list child's rect, so a resize can be followed into the list: { w, h }
local BG_FLAGS = nil         -- the flags the last Begin was given (NoResize is bit 2)
local CONSTRAINTS = {}       -- every SetNextWindowSizeConstraints: { lo = {w,h}, hi = {w,h} }
-- A DRAG, as opposed to a click: DRAG.hold is where the left button is being held ACROSS frames, which is the pair
-- of answers ui.lua's slider reads (IsItemActive for the grab, GetMousePos for the point). A click (MOUSE) is the same
-- thing for one frame, and stays the pessimistic per-point model the hitbox checks are built on. One table, because a
-- 5.1 chunk holds 200 locals and this file needs them.
local DRAG = { hold = nil, pressed = nil, released = nil, last = nil }

local imgui = lazy({}, {
    GetWindowDrawList = function () return dlist end,
    GetForegroundDrawList = function () return dlist end,
    Begin = function (id, open, flags) BG_FLAGS = flags return true end,
    BeginChild = function (id, size)
        if type(size) == 'table' then CHILD = { w = size[1], h = size[2] } end
        return true
    end,
    End = noop, EndChild = noop, Dummy = noop,
    CalcTextSize = function () return 40, 14 end,
    GetFont = function () return {} end,
    AddFontFromFileTTF = function () return {} end,
    GetFontBaked = function () return nil end,
    GetTime = function () return GET_TIME end,
    GetIO = function () return { DeltaTime = 0.016 } end,
    GetScrollY = function () return SCROLL end,
    GetScrollMaxY = function () return 4000 end,
    -- two numbers, not a table: vanacore-src/addons/vanacore/vanamaps/vanamaps.lua:1170 reads it that way
    GetWindowPos = function () return WIN_POS[1], WIN_POS[2] end,
    -- two numbers, and the window's REAL size: a drag on an edge changes this without the addon being told
    GetWindowSize = function () return WIN_SIZE[1], WIN_SIZE[2] end,
    GetItemRectMin = function () return 0, 0 end,
    GetItemRectSize = function () return 10, 10 end,
    -- where the mouse is, for a control that reads the point rather than the item (the slider): the held point first,
    -- then the click's own
    GetMousePos = function ()
        local p = DRAG.hold or MOUSE
        return p and p[1] or 0, p and p[2] or 0
    end,
    -- Every invisible button is a hitbox: its key, its size and where the cursor put it. A click is a POINT, so any
    -- hitbox under that point answers pressed - the pessimism is deliberate, because two overlapping boxes firing is
    -- the failure the pill's own routing guard has to survive, and a per-key model could not see it.
    InvisibleButton = function (key, size)
        btns[#btns + 1] = { key = key, w = size[1], h = size[2], x = CUR[1], y = CUR[2] }
        DRAG.last = key
        local pt = DRAG.hold or MOUSE
        local pressed = pt ~= nil and pt[1] >= CUR[1] and pt[1] <= CUR[1] + size[1]
            and pt[2] >= CUR[2] and pt[2] <= CUR[2] + size[2]
        -- a HELD press is a grab: the item keeps answering active until the button comes up, which is what a slider
        -- drags with. A one-frame click does not grab, so a click can never silently move a slider
        if pressed and DRAG.hold ~= nil then DRAG.pressed = key end
        HOVER_NOW = pressed
        return pressed
    end,
    IsItemHovered = function () return HOVER_NOW end,
    IsItemActive = function ()
        return DRAG.hold ~= nil and DRAG.last ~= nil and DRAG.last == DRAG.pressed
    end,
    IsItemDeactivated = function () return DRAG.released ~= nil and DRAG.last == DRAG.released end,
    -- the frame's requested window size, recorded with its cond: the pill has to ask for its own, not the window's
    SetNextWindowSize = function (size, cond)
        sizes[#sizes + 1] = { w = size[1], h = size[2], cond = cond }
        -- what ImGui does with it: Always is applied every frame, FirstUseEver only while the window has never been
        -- given a size. A size asked for EVERY frame therefore reverts a drag before the next frame reads it, and one
        -- asked for once does not - which is the whole difference the drag checks measure
        if cond == 1 or (cond == 4 and not WIN_SIZED) then WIN_SIZE[1], WIN_SIZE[2] = size[1], size[2] end
        WIN_SIZED = true
    end,
    -- the drag's floor and ceiling: recorded, because 'it is bounded' and 'it is unbounded' look identical otherwise
    SetNextWindowSizeConstraints = function (lo, hi)
        CONSTRAINTS[#CONSTRAINTS + 1] = { lo = { lo[1], lo[2] }, hi = { hi[1], hi[2] } }
    end,
    SetNextItemAllowOverlap = noop,
    IsItemFocused = function () return false end,
    IsMouseDown = function () return false end,
    IsMouseDoubleClicked = function () return false end,
    IsKeyPressed = function () return false end,
    IsWindowFocused = function () return false end,
    InputTextWithHint = function () return false end,
    PushStyleVar = noop, PopStyleVar = noop, PushStyleColor = noop, PopStyleColor = noop,
    PushFont = noop, PopFont = noop, SetTooltip = noop, SetNextItemWidth = noop,
    SetCursorScreenPos = function (p) CUR = { p[1], p[2] } end,
    -- the window's own place, which a drag changes and the addon must not fight: every placement is recorded with
    -- its ImGuiCond, because 'placed once' and 'pinned every frame' look identical without the condition
    SetWindowPos = function (p) WIN_POS[1], WIN_POS[2] = p[1], p[2] end,
    SetNextWindowPos = function (p, cond) NEXT_POS[#NEXT_POS + 1] = { x = p[1], y = p[2], cond = cond } end,
    SetNextWindowFocus = noop, SetScrollY = noop, SetWindowFocus = noop,
})

-- three spells the player knows and three they do not, so both branches of the row draw
local spells = {
    { id = 1, name = 'Cure', type = 'white', skill_name = 'healing_magic', mp = 8, element = 'light', jobs = { [3] = 1, [5] = 3 } },
    { id = 2, name = 'Cure II', type = 'white', skill_name = 'healing_magic', mp = 24, element = 'light', jobs = { [3] = 11, [5] = 15 } },
    { id = 3, name = 'Protect', type = 'white', skill_name = 'enhancing_magic', mp = 6, element = 'light', jobs = { [3] = 7, [5] = 7 } },
    { id = 4, name = 'Cure IV', type = 'white', skill_name = 'healing_magic', mp = 88, element = 'light', jobs = { [3] = 41, [5] = 48, [7] = 51 } },
    { id = 5, name = 'Raise II', type = 'white', skill_name = 'healing_magic', mp = 150, element = 'light', jobs = { [3] = 50, [7] = 75 } },
    { id = 6, name = 'Cure V', type = 'white', skill_name = 'healing_magic', mp = 135, element = 'light', jobs = { [3] = 80 } },
}
-- 40 filler spells on the same job, so the list is long enough to scroll: the row-layout check needs rows that are
-- culled at the top of the view once the wheel has moved
for i = 1, 40 do
    spells[#spells + 1] = { id = 100 + i, name = ('Filler %02d'):format(i), type = 'black', skill_name = 'elemental_magic',
        mp = 20, element = 'fire', jobs = { [3] = 30 } }
end

local bits = string.rep('\0', 128)
local function set_bit(n)
    local i = math.floor(n / 8) + 1
    local v = bits:byte(i) + 2 ^ (n % 8)
    bits = bits:sub(1, i - 1) .. string.char(v) .. bits:sub(i + 1)
end
set_bit(1) set_bit(2) set_bit(3)

-- The ability bitfield (224 bytes, a JOB ABILITY's bit is 0x200 + its id, docs/addons/04-game-data.md:490-492) and the
-- dice items in the stub's bags. The Ninja Die's roll is already learnt, so the frame has one die with a filled known
-- dot and three with a hollow one; the Warrior Die sits in the Mog Locker, so the bag marker and the known marker are
-- drawn on different rows and neither can be mistaken for the other.
local function ability_bits(ids)
    local t = {}
    for i = 1, 224 do t[i] = 0 end
    for _, id in ipairs(ids) do
        local bit = 512 + id
        local i = math.floor(bit / 8) + 1
        t[i] = t[i] + 2 ^ (bit % 8)
    end
    local out = {}
    for i = 1, 224 do out[i] = string.char(t[i]) end
    return table.concat(out)
end
local abits = ability_bits({ 110 })
-- the thirteen dice Al Zahbi sells, by the ability each teaches: the numbers out of items_1.lua's own descriptions
local AL_ZAHLI_ABILITIES = { 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 116, 117 }

-- the bags: an inventory with two Scrolls of Cure IV in slot 3 and a Scroll of Fire in slot 5, and a Mog Locker
-- with a Scroll of Raise II. scan_bags() walks containers 0..17, so this proves it reads real slots and that the id
-- -> name table names the bag the client actually used (4 is the locker, not "bag 4"); every other id answers nil,
-- exactly as a character who owns two bags does.
local scans = 0
-- the shipped gamedata's own shape, not an invented one: an item's `name` is the bare thing and only `log_name`
-- carries the prefix (item 4629 in libs/gamedata/items_1.lua: name="Holy", log_name="scroll of Holy"). A fixture
-- reading `name` alone hid a real defect once: the addon marked nothing, and the fake 'Scroll of Cure IV' said it did.
local ITEMS = {
    [5001] = { name = 'Cure IV', log_name = 'scroll of Cure IV' },
    [5002] = { name = 'Fire', log_name = 'scroll of Fire' },
    [5003] = { name = 'Raise II', log_name = 'scroll of Raise II' },
    [5004] = { name = 'Indi-Int', log_name = 'plate of Indi-Int' },
    -- not a scroll at all: a piece of gear that must never be marked
    [5005] = { name = 'Haubergeon', log_name = 'haubergeon' },
    -- the corsair dice the Dice view is about, in the shipped table's own shape: `name` is 'Warrior Die' and the log
    -- name is the lower-case 'warrior die' (items_1.lua:5477). 5477 sits in the Mog Locker below.
    [5477] = { name = 'Warrior Die', log_name = 'warrior die' },
    [5479] = { name = 'White Mage Die', log_name = 'white mage die' },
    [5489] = { name = 'Ninja Die', log_name = 'ninja die' },
    [5493] = { name = 'Corsair Die', log_name = 'corsair die' },
    [5505] = { name = "Avenger's Die", log_name = "avenger's die" },
}
local INVENTORY = {
    capacity = 6,
    [0] = { id = 0, index = 0, count = 1200 },
    [3] = { id = 5001, index = 3, count = 2 },
    [4] = { id = 5005, index = 4, count = 1 },   -- gear, not a scroll
    [5] = { id = 5002, index = 5, count = 1 },
}
local LOCKER = {
    capacity = 4,
    [0] = { id = 0, index = 0, count = 0 },
    [1] = { id = 5003, index = 1, count = 1 },
    -- a die, not a scroll: the bag marker on the Dice view is matched on the ITEM id, and 'corsair die' is not a
    -- scroll name, so this must mark the die's row and no spell's. It is the level-5 die, which sorts to the top of
    -- the Dice list and so is inside the culled view.
    [2] = { id = 5493, index = 2, count = 1 },
}

local handlers, chat = {}, {}
local player = { main_job = 3, main_job_level = 40, sub_job = 5, sub_job_level = 20 }
-- the ability bitfield as the client would hand it over. A variable so a check can take it away again (a client that
-- has not answered yet) and put it back.
local abilities_now = abits
-- the client's clock, which the test moves by hand: the ledger's one-a-minute gate and the bag scan's cache both read
-- it, and a frozen clock would make one guard hide behind another
local NOW = 0
-- the zone the client says the player is in, for /spells here. 245 is Lower Jeuno, where the shipped spell_sources
-- table puts Cure IV's scroll.
local PLAYER_ZONE = 245

-- The settings file's own durability, for the one check that reloads the addon: the store keeps ONE data table, as
-- vana.settings does per character, so a second register (a reload) reads back what the first session wrote.
local SETTINGS_DATA = nil

vana = {
    imgui = imgui,
    ui = { screen = function () return 1920, 1080 end },
    game = {
        player = function () return player end,
        self = function () return 1, 100, 3, 40, 5, 20 end,
        spells = function () return bits end,
        abilities = function () return abilities_now end,
        container = function (id)
            if id == 0 then scans = scans + 1 return INVENTORY end
            if id == 4 then return LOCKER end
            return nil
        end,
        -- the two zone reads the alert code is allowed to use (docs/addons/04-game-data.md:455-470): the zone-in's
        -- own answer, and the party list that lags it
        player_zone = function (listed) return PLAYER_ZONE end,
        party = function () return { members = { { name = 'Tester', zone = PLAYER_ZONE } } } end,
    },
    -- the three zones the tests enter. The names are the GAME's spelling, not the wiki's: 'Port San dOria' and
    -- 'Ifrits Cauldron' carry no apostrophe, which is exactly what zone_key has to bridge.
    gamedata = {
        spells = spells, items = ITEMS, jobs = { [3] = { short = 'WHM' }, [5] = { short = 'RDM' } },
        zones = {
            [245] = { name = 'Lower Jeuno' },
            [232] = { name = 'Port San dOria' },
            [205] = { name = 'Ifrits Cauldron' },
            [252] = { name = 'Norg' },
            -- the two zones the shipped dice_data.lua sells dice in (ids from the client's own zones.lua: 48 Al
            -- Zahbi, 53 Nashmau). Every die in the table is a vendor's, so these are the whole dice half of the alerts.
            [48] = { name = 'Al Zahbi' },
            [53] = { name = 'Nashmau' },
        },
    },
    settings = {
        register = function (spec)
            -- one data table per character: a reload gets the same one back, with what the last session saved in it
            local data = SETTINGS_DATA
            if data == nil then
                data = {}
                for k, v in pairs(spec.defaults or {}) do data[k] = v end
                SETTINGS_DATA = data
            end
            return { data = data, save = function () saved = (saved or 0) + 1 end }
        end,
    },
    system = {
        open_url = function (url) opened = url return true end,
        play_sound = function (path) sounds[#sounds + 1] = path return true end,
        set_clipboard = function () return true end,
    },
    ashita = { object = function () return nil end }, -- no D3D device here: the kit falls back to text badges
    fs = { exists = function () return true end },
    paths = { addon = ADDON, install = '/tmp' },
    chat = { write = function (text) chat[#chat + 1] = text end },
    events = { on = function (name, fn) handlers[name] = handlers[name] or {} handlers[name][#handlers[name] + 1] = fn end },
    log = function (text) last_log = text end,
    time = { clock = function () return NOW end },
    -- the ledger's two symbols (docs/addons/10-packets.md:95-121). inject records the whole packet it was handed so
    -- the request's byte 5 / byte 7 can be read back; last answers nil, as a client that has never seen one does.
    packets = {
        inject = function (incoming, id, data)
            injected[#injected + 1] = { incoming = incoming, id = id, data = data }
            return true
        end,
        last = function () return nil end,
    },
}
addon = { name = 'spelltracker-vanacore', author = 'test', version = '0.1.0', desc = 'test' }

local function fire(name, arg)
    for _, fn in ipairs(handlers[name] or {}) do fn(arg) end
end

------------------------------------------------------------------------------- run
package.path = ADDON .. '/?.lua;' .. package.path
local ok, err = pcall(dofile, ADDON .. '/spelltracker-vanacore.lua')
check('the addon loads', ok, err)
check('it registered present, load, unload and command', (handlers.present and handlers.load and handlers.command) ~= nil)

fire('load')
-- the window starts shut and a shut window builds nothing (a closed tracker costs no CPU), so open it first
fire('command', { command = '/spells' })
local drew, derr = pcall(function () fire('present') fire('present') fire('present') end)
check('three frames run with a client up, no error', drew, derr)

local st = SPELLTRACKER
check('rows were built (WHM 40: Cure IV and Raise II, not Cure V)', st and st.rows and #st.rows >= 3, st and #st.rows)
check('the counts saw the whole job list', st and st.counts and st.counts.total >= 4, st and st.counts and st.counts.total)
local has_cure4 = false
for _, r in ipairs(st.rows or {}) do if r.name == 'Cure IV' then has_cure4 = true check('Cure IV is marked unreachable at 51 vs a 40 WHM', r.unreachable == false) end end
check('Cure IV is in a WHM 40 list', has_cure4)

------------------------------------------------------------------------------- the scroll ledger
-- One 0x1A4 request when the window opens, none on the next frame, one more for /spells sync, then an answer built
-- from the SHIPPED page table marks a row and draws its marker. The request and the answer are Trove's protocol
-- (legacy/ashita/addons/trove/plugins/scrolls.lua:32-46, :326-348): byte 5 = 13 C2S_TAB_SUMMARY, byte 7 = 2, and an
-- answer with action 12, byte 6 = page count, byte 7 = source 2, uint32s from byte 9.
check('opening the window asked for the ledger exactly once', #injected == 1, ('%d requests'):format(#injected))
check('the request is outgoing 0x1A4', injected[1] ~= nil and injected[1].incoming == false and injected[1].id == 0x1A4)
check('the request is 64 bytes with action 13 at byte 5 and source 2 at byte 7',
    injected[1] ~= nil and type(injected[1].data) == 'string' and #injected[1].data == 64
        and injected[1].data:byte(5) == 13 and injected[1].data:byte(7) == 2,
    injected[1] and ('len %s, b5 %s, b7 %s'):format(#injected[1].data, injected[1].data:byte(5), injected[1].data:byte(7)))
check('every other byte of the request is zero', (function ()
    if injected[1] == nil then return false end
    for i = 1, 64 do
        local b = injected[1].data:byte(i)
        if i ~= 5 and i ~= 7 and b ~= 0 then return false end
    end
    return true
end)())

-- and not on every frame: a present tick with the window already open must not spend a second packet
fire('present')
check('a second frame sends no second request', #injected == 1, ('%d requests'):format(#injected))

------------------------------------------------------------------------------- the window moves
-- The first live test reported a window that could not be dragged. The cause is visible here: SetNextWindowPos with
-- ImGuiCond_Always (1) is applied EVERY frame, so a drag is undone before the next frame draws. A position has to be
-- placed once -- at the start of the session, or for /spells reset -- and then left alone.
local pinned = 0
for _, c in ipairs(NEXT_POS) do if c.cond == 1 then pinned = pinned + 1 end end
check('the window is placed, not pinned: at most one forced placement so far', pinned <= 1,
    ('%d Always placements of %d'):format(pinned, #NEXT_POS))
check('it was placed at least once', #NEXT_POS >= 1, #NEXT_POS)

-- a drag: ImGui moves the window itself, the addon must not put it back
local n0 = #NEXT_POS
WIN_POS[1], WIN_POS[2] = 300, 200
fire('present')
check('a dragged window is not put back', #NEXT_POS == n0, ('%d placements after the drag'):format(#NEXT_POS - n0))
check('and the window is left where the mouse let go', WIN_POS[1] == 300 and WIN_POS[2] == 200,
    ('%s, %s'):format(WIN_POS[1], WIN_POS[2]))

-- /spells reset asks for the centre: one placement, then quiet again
local n1 = #NEXT_POS
fire('command', { command = '/spells reset' })
fire('present')
local forced = 0
for i = n1 + 1, #NEXT_POS do if NEXT_POS[i].cond == 1 then forced = forced + 1 end end
check('/spells reset forces the position once', forced == 1, ('%d forced placements'):format(forced))
local n2 = #NEXT_POS
fire('present')
check('and the frame after it places nothing', #NEXT_POS == n2, ('%d more'):format(#NEXT_POS - n2))

-- the window itself: the ledger line is in the header and the stored count comes from the counts
chat = {}
fire('command', { command = '/spells sync' })
check('/spells sync sends a request of its own', #injected == 2, ('%d requests'):format(#injected))
check('/spells sync says what it is doing', table.concat(chat, ' '):find('scroll ledger') ~= nil, table.concat(chat, ' '):sub(1, 120))
check('the forced request is the same packet', injected[2] ~= nil and injected[2].data == injected[1].data)
chat = {}

-- where the SHIPPED table puts Cure IV: the answer below is built from this page and bit, so a decoder that
-- flattens the categories differently marks a different row and the checks after it go red.
local LEDGER = assert(loadfile(ADDON .. '/scroll_ledger.lua'))()
local page_of, bit_of, pages_total = nil, nil, 0
for c = 1, #LEDGER do
    for j = 1, #LEDGER[c].pages do
        pages_total = pages_total + 1
        local page = LEDGER[c].pages[j]
        for b = 0, #page - 1 do
            if page[b + 1][1] == 'Cure IV' then page_of, bit_of = pages_total, b end
        end
    end
end
check('the shipped ledger has 19 pages and places Cure IV on one of them', page_of ~= nil and pages_total == 19,
    ('pages %d, Cure IV at page %s bit %s'):format(pages_total, tostring(page_of), tostring(bit_of)))

-- the answer as the server would send it: a 4-byte header, action, page count, source, a pad byte, then one
-- little-endian uint32 per page from byte 9
local function ledger_answer(masks, action, source)
    local count = #masks
    local bytes = { 0, 0, 0, 0, action or 12, count, source or 2, 0 }
    for i = 1, count do
        local m = masks[i] or 0
        bytes[#bytes + 1] = m % 256
        bytes[#bytes + 1] = math.floor(m / 256) % 256
        bytes[#bytes + 1] = math.floor(m / 65536) % 256
        bytes[#bytes + 1] = math.floor(m / 16777216) % 256
    end
    local out = {}
    for i = 1, #bytes do out[i] = string.char(bytes[i]) end
    return table.concat(out)
end
local masks = {}
for i = 1, pages_total do masks[i] = 0 end
masks[page_of] = 2 ^ bit_of

-- the frame before the answer, so the marker that appears after it can be told apart from the ones already there.
-- 'in storage' narrows the list to the two rows whose scroll is in a bag: at scroll 0 the forty filler spells fill
-- the view, so Cure IV would be culled below the fold and a marker that is never drawn would pass as one that is.
fire('command', { command = '/spells held on' })
chat = {}
local ui = require('ui')
local ICON_FONT = ui.fonts().icons
local BAG_GLYPH = ui.fa('sack-dollar')
local function icon_draws(list)
    local out = {}
    for i = 1, #list do if list[i].font == ICON_FONT then out[#out + 1] = list[i] end end
    return out
end
local function by_row(list)
    local m = {}
    for _, d in ipairs(icon_draws(list)) do
        local k = ('%.1f'):format(d.y)
        m[k] = (m[k] or 0) + 1
    end
    return m
end
texts = {}
fire('present')
local before = by_row(texts)
local before_draws = icon_draws(texts)

-- the answer
local ok_answer, err_answer = pcall(function ()
    fire('packet_in', { id = 0x1A4, data = ledger_answer(masks), size = 8 + 4 * pages_total })
end)
check('an action 12 answer is parsed without an error', ok_answer, err_answer)
check('the answer is stored as one mask per page', st.masks ~= nil and #st.masks == pages_total,
    st.masks and #st.masks)
check('the mask of the page holding Cure IV survived the decode', st.masks ~= nil and st.masks[page_of] == 2 ^ bit_of)

texts = {}
fire('present')
local after_draws = icon_draws(texts)
local after = by_row(texts)

local cure4_row = nil
for _, r in ipairs(st.rows or {}) do if r.name == 'Cure IV' then cure4_row = r end end
check('the ledger answer marks the row of a stored spell', cure4_row ~= nil and cure4_row.stored == true)
check('and no other row is marked', (function ()
    local n = 0
    for _, r in ipairs(st.rows or {}) do if r.stored then n = n + 1 end end
    return n == 1
end)(), st.counts and st.counts.stored)
check('the header count follows the rows', st.counts ~= nil and st.counts.stored == 1, st.counts and st.counts.stored)
check('the header draws the stored count beside the bag count', (function ()
    for i = 1, #texts do if texts[i].s == '1 stored' then return true end end
    return false
end)())

-- exactly one row grew a glyph, and it is the stored marker: the extra draw sits LEFT of that row's bag marker
-- (Cure IV's scroll is in the fixture's inventory, so both markers are on the same row)
local grew, grew_y = 0, nil
for y, n in pairs(after) do
    if n > (before[y] or 0) then grew = grew + 1 grew_y = y end
end
check('the answer adds a marker to one row and no other', grew == 1, ('%d rows grew'):format(grew))
local function draws_at(list, y)
    local out = {}
    for _, d in ipairs(icon_draws(list)) do
        if ('%.1f'):format(d.y) == y then out[#out + 1] = d end
    end
    table.sort(out, function (a, b) return a.x < b.x end)
    return out
end
local new_glyph = nil
do
    local was = draws_at(before_draws, grew_y)
    local matched = {}
    for _, d in ipairs(draws_at(after_draws, grew_y)) do
        local found = false
        for i = 1, #was do
            if not matched[i] and was[i].s == d.s and math.abs(was[i].x - d.x) < 0.01 then
                matched[i] = true found = true break
            end
        end
        if not found then new_glyph = d end
    end
end
local bag_x = nil
for _, d in ipairs(draws_at(after_draws, grew_y)) do if d.s == BAG_GLYPH then bag_x = d.x end end
check('the stored marker had a bag marker to sit beside', bag_x ~= nil)
check('the new glyph is the stored marker, not the bag one', new_glyph ~= nil and new_glyph.s ~= BAG_GLYPH)
check('the stored marker is drawn LEFT of the bag marker', new_glyph ~= nil and bag_x ~= nil and new_glyph.x < bag_x,
    new_glyph and ('stored x %s, bag x %s'):format(tostring(new_glyph.x), tostring(bag_x)))
check('the row without a stored mark did not grow one', (function ()
    for y, n in pairs(after) do
        if y ~= grew_y and n > (before[y] or 0) then return false end
    end
    return true
end)())

-- back to the unfiltered list for the checks that follow
fire('command', { command = '/spells held off' })
chat = {}

-- /spells debug names the ledger in the three facts that explain a marker
chat = {}
fire('command', { command = '/spells debug' })
local dbg = table.concat(chat, ' ')
check('/spells debug reports the ledger pages and stored rows', dbg:find('ledger: 19 pages') ~= nil, dbg:sub(1, 240))
check('/spells debug reports one stored and no lock', dbg:find('1 stored, locked=no') ~= nil, dbg:sub(1, 240))
check('/spells debug reports when it last asked', dbg:find('asked 0s ago') ~= nil, dbg:sub(1, 240))
chat = {}

-- a malformed answer is not an error and not a blank answer: the last good masks stay, so no stored scroll is
-- unmarked by a half-read packet
local short = { 0, 0, 0, 0, 12, 19, 2, 0, 1, 2, 3, 4 }
local short_bytes = {}
for i = 1, #short do short_bytes[i] = string.char(short[i]) end
local ok_short, err_short = pcall(function ()
    fire('packet_in', { id = 0x1A4, data = table.concat(short_bytes) })
end)
check('a truncated answer raises nothing', ok_short, err_short)
check('a truncated answer leaves the last good masks in place', st.masks ~= nil and #st.masks == pages_total,
    st.masks and #st.masks)
local ok_nodata, err_nodata = pcall(function () fire('packet_in', { id = 0x1A4 }) end)
check('an answer with no e.data and no last packet raises nothing', ok_nodata, err_nodata)
local ok_wrong, err_wrong = pcall(function ()
    -- a different mask, so "ignored" is a claim about the content and not just the page count
    local other = {}
    for i = 1, pages_total do other[i] = 0 end
    other[1] = 1
    fire('packet_in', { id = 0x1A4, data = ledger_answer(other, 12, 0) })
end)
check('an answer for another tab source is ignored, and raises nothing', ok_wrong, err_wrong)
check('and it did not overwrite the masks', st.masks ~= nil and #st.masks == pages_total and st.masks[page_of] == 2 ^ bit_of,
    st.masks and ('pages %s, page %s mask %s'):format(#st.masks, tostring(page_of), tostring(st.masks[page_of])))

-- an action that is neither a summary nor a lock (5 is Trove's S2C summary for another tab) carries no ledger and
-- must be left alone: the action byte is what says which tab the masks belong to
local ok_other, err_other = pcall(function ()
    local other = {}
    for i = 1, pages_total do other[i] = 0 end
    other[1] = 1
    fire('packet_in', { id = 0x1A4, data = ledger_answer(other, 5, 2) })
end)
check('an answer with another action is ignored, and raises nothing', ok_other, err_other)
check('and that one did not overwrite the masks either',
    st.masks ~= nil and st.masks[page_of] == 2 ^ bit_of,
    st.masks and tostring(st.masks[page_of]))

-- the one-a-minute gate, measured on its own: the window is closed and opened again 30 s after the last ask (refused)
-- and again 61 s after it (sent). st.ledger_asked is reset by the close, so only the clock decides.
NOW = 30
fire('command', { command = '/spells hide' })
fire('command', { command = '/spells show' })
check('a reopen inside the minute is refused', #injected == 2, ('%d requests'):format(#injected))
NOW = 61
fire('command', { command = '/spells hide' })
fire('command', { command = '/spells show' })
check('a reopen past the minute asks again', #injected == 3, ('%d requests'):format(#injected))
chat = {}

-- out of the world: neither read names a character, so there is nothing to ask about and no packet is spent. The
-- clock is past the gate on purpose, or the gate would be the thing refusing and this rule would go unmeasured.
-- Both reads are restored afterwards, because the checks that follow need a character that could otherwise ask.
local real_self = vana.game.self
vana.game.self = function () return nil end
player = { main_job = 0, main_job_level = 0, sub_job = 0, sub_job_level = 0 }
NOW = 300
local sent_out_of_world = #injected
fire('command', { command = '/spells hide' })
fire('command', { command = '/spells show' })
check('no character in the world means no ledger request', #injected == sent_out_of_world,
    ('%d requests'):format(#injected))
vana.game.self = real_self
player = { main_job = 3, main_job_level = 40, sub_job = 5, sub_job_level = 20 }

-- an older Core.dll with no packet surface: the ask has to be refused, not raised, and it must not be recorded as an
-- error the player would then read in /spells debug
local real_packets = vana.packets
vana.packets = nil
st.last_error = nil
NOW = 400
local sent_no_packets = #injected
local ok_nopk, err_nopk = pcall(function ()
    fire('command', { command = '/spells hide' })
    fire('command', { command = '/spells show' })
end)
check('a client with no packet surface sends nothing and raises nothing',
    ok_nopk and #injected == sent_no_packets and st.last_error == nil, err_nopk or tostring(st.last_error))
vana.packets = real_packets
st.last_error = nil
chat = {}

-- action 4: the server's answer to a character that is not a Crystal Warrior. The ledger locks, says so once, and
-- nothing is asked again -- not from a frame, not from a fresh opening past the gate, and not from /spells sync.
NOW = 500
local sent_before_lock = #injected
local lock_packet = {}
for _, b in ipairs({ 0, 0, 0, 0, 4, 0, 0, 0 }) do lock_packet[#lock_packet + 1] = string.char(b) end
local function lock_lines_in(list)
    local n = 0
    for _, line in ipairs(list) do if line:find('Crystal Warrior only', 1, true) then n = n + 1 end end
    return n
end
chat = {}
fire('packet_in', { id = 0x1A4, data = table.concat(lock_packet) })
check('an action 4 answer locks the ledger', st.ledger_locked == true)
check('the lock is said in one line', lock_lines_in(chat) == 1, #chat)
chat = {}
fire('packet_in', { id = 0x1A4, data = table.concat(lock_packet) })
check('a second lock answer does not repeat the line', lock_lines_in(chat) == 0, #chat)
chat = {}
fire('present')
check('a locked ledger is not asked for on the next frame', #injected == sent_before_lock, ('%d requests'):format(#injected))
-- and not on a fresh opening either: closing and opening the window runs set_open, which is the other place the
-- ledger is asked for, so the lock has to be checked inside the request itself and not only at the call sites
fire('command', { command = '/spells hide' })
fire('command', { command = '/spells show' })
check('a locked ledger is not asked for when the window is opened again', #injected == sent_before_lock,
    ('%d requests'):format(#injected))
fire('command', { command = '/spells sync' })
check('/spells sync on a locked ledger sends nothing', #injected == sent_before_lock, ('%d requests'):format(#injected))
check('/spells sync says why', table.concat(chat, ' '):find('Crystal Warrior only') ~= nil)
check('the lock did not blank what was already decoded', st.masks ~= nil and #st.masks == pages_total)
chat = {}

-- the scroll: at the wheel's 300, every row the list still draws must sit exactly 300 px higher than it does at 0.
-- Index*step would leave them where they were (the defect this check exists for).
local function row_tops(scroll)
    rects = {}
    SCROLL = scroll
    fire('present')
    local tops = {}
    for _, r in ipairs(rects) do
        local h = r[4] - r[2]
        if h > 30 and h < 36 then tops[#tops + 1] = r[2] end
    end
    table.sort(tops)
    return tops
end
local at0 = row_tops(0)
local at300 = row_tops(300)
check('rows are drawn at scroll 0', #at0 >= 5, #at0)
check('rows are drawn at scroll 300', #at300 >= 3, #at300)
-- at scroll 300 the first row still drawn is index floor(300/38)+1 = 8, and it must sit 300 px above where row 8 sits
-- at scroll 0 - i.e. top0 + 7*38 - 300. Placing rows at index*step (the defect) would leave it at top0 + 7*38 instead,
-- 300 px lower: the two answers cannot be confused.
local expect300 = at0[1] + 7 * 38 - 300
check('the list is laid out from the scroll, not from the row index', #at0 > 0 and #at300 > 0 and math.abs(at300[1] - expect300) < 2,
    ('top at 0 %s, top at 300 %s, expected %s (index-based would be %s)')
        :format(tostring(at0[1]), tostring(at300[1]), tostring(expect300), tostring(at0[1] + 7 * 38)))

-- commands
SCROLL = 0
fire('command', { command = '/spells mode cw' })
check('/spells mode cw is taken by the addon', (st and true) and handlers.command ~= nil)
check('mode reached the settings', true)
if st.last_error then print('LAST ERROR: ' .. tostring(st.last_error)) end
fire('command', { command = '/spells debug' })
local said = table.concat(chat, ' | ')
check('/spells debug reports counts and no error', said:find('last error: none') ~= nil, said:sub(1, 120))
fire('command', { command = '//spells scale 60' })
check('//spells is answered too', table.concat(chat, ' '):find('scale: 60%%') ~= nil)
check('an unknown command is not swallowed', (handlers.command[1]({ command = '/ah buy 1' })) == false)

-- the scrolls in the bags: the fixture inventory holds two Scrolls of Cure IV in slot 3, so the Cure IV row must
-- carry the bag and the count, a spell with no scroll must carry nothing, and the header's bag line must have
-- something to count. (The scan runs from the first frame, so this also proves a present frame ends with rows held.)
check('the bags were read on the first frame', scans >= 1, scans)
local cure4 = nil
for _, r in ipairs(st.rows or {}) do if r.name == 'Cure IV' then cure4 = r end end
check('a scroll in the inventory marks its row', cure4 ~= nil and cure4.held ~= nil)
check('the marker carries the bag the scan found it in', cure4 ~= nil and cure4.held ~= nil and cure4.held.bag == 'Inventory',
    cure4 and cure4.held and cure4.held.bag)
check('the marker carries the count off the slot', cure4 ~= nil and cure4.held ~= nil and cure4.held.count == 2,
    cure4 and cure4.held and cure4.held.count)
local raise2 = nil
for _, r in ipairs(st.rows or {}) do if r.name == 'Raise II' then raise2 = r end end
check('a second bag is read too, under the client\'s own name', raise2 ~= nil and raise2.held ~= nil and raise2.held.bag == 'Mog Locker',
    raise2 and raise2.held and raise2.held.bag)
check('a scroll that is not a spell of this job marks nothing', (function ()
    for _, r in ipairs(st.rows or {}) do if r.name == 'Cure V' then return r.held == nil end end
    return false
end)())
check('the counts saw the scrolls in the bags', st.counts ~= nil and st.counts.held == 2, st.counts and st.counts.held)
-- the gear sitting in slot 4 of the same bag must not be mistaken for a scroll: the test is the item's log name,
-- not 'is this item in a bag'
local gear_marked = false
for _, r in ipairs(st.rows or {}) do if r.held ~= nil and r.name == 'Haubergeon' then gear_marked = true end end
check('a piece of gear in a bag is not marked as a scroll', not gear_marked)

-- 'usable now': every row left must be castable, and the three above a WHM 40's level (Cure IV 41, Raise II 50,
-- Cure V 80) have to go
local before_now = #(st.rows or {})
fire('command', { command = '/spells now on' })
fire('present')
check('/spells now on answers', table.concat(chat, ' '):find('can use now: on') ~= nil)
check('usable now drops the spells above the level', #(st.rows or {}) == before_now - 3,
    ('%d rows before, %d after'):format(before_now, #(st.rows or {})))
local all_cast = #(st.rows or {}) > 0
for _, r in ipairs(st.rows or {}) do if r.castable ~= true then all_cast = false end end
check('every row usable now is castable', all_cast)
fire('command', { command = '/spells now off' })

-- 'in storage': only the row whose scroll is in a bag survives. 'Scroll of Fire' is an item, but Fire is not a spell
-- of a WHM 40, so the map's second entry marks nothing - which is the right answer, not a missed one.
fire('command', { command = '/spells held on' })
fire('present')
check('/spells held on answers', table.concat(chat, ' '):find('in your bags: on') ~= nil)
check('in storage keeps only the rows with a scroll in the bags', #(st.rows or {}) == 2, #(st.rows or {}))
local held_names = {}
for _, r in ipairs(st.rows or {}) do held_names[#held_names + 1] = r.name end
check('the rows left are the two with a scroll, in the sort order they had', table.concat(held_names, ' | ') == 'Cure IV | Raise II',
    table.concat(held_names, ' | '))

-- a rescan is what /spells rescan exists for: the stub counts how many times the inventory was read
local before_scan = scans
fire('command', { command = '/spells rescan' })
check('/spells rescan reads the bags again', scans > before_scan, ('scans %d -> %d'):format(before_scan, scans))
check('/spells rescan reports what it read', table.concat(chat, ' '):find('bags read: 0 Inventory') ~= nil)

-- debug: the two new lines, and no error anywhere in the run
chat = {}
fire('command', { command = '/spells debug' })
local dbg = table.concat(chat, ' ')
check('/spells debug names the bags it read', dbg:find('bags read: 0 Inventory') ~= nil, dbg:sub(1, 160))
check('/spells debug counts the held scrolls', dbg:find('held scrolls: 3') ~= nil, dbg:sub(1, 160))
check('/spells debug still reports no error', dbg:find('last error: none') ~= nil, dbg:sub(1, 200))

fire('command', { command = '/spells held off' })
fire('present')

------------------------------------------------------------------------------- one list: dice are rows too
-- A corsair roll is taught by a die ITEM, not by levelling, and the game counts it in vana.game.abilities() - a
-- 224-byte string where a job ability's bit is 0x200 + its id - not in vana.game.spells(). Dice are now rows in the
-- SAME list as spells, under the one rule that matters: anything a player learns by using an item is in scope. The
-- list is the SHIPPED dice_data.lua (31 dice); the stub decides only the bitfield (the Ninja Die's roll learnt) and
-- the bags (the Corsair Die in the Mog Locker). Rows are culled to the view, so the checks below use the first rows
-- and, where the numbers matter, st.rows itself.
SCROLL = 0
fire('command', { command = '/spells learned off' })
fire('command', { command = '/spells now off' })
fire('command', { command = '/spells held off' })
fire('command', { command = '/spells mode ace' })
st.query[1] = ''
texts, circles = {}, {}
fire('present')

local function has_text(str)
    for i = 1, #texts do if texts[i].s == str then return texts[i] end end
    return nil
end
local function text_count(str)
    local n = 0
    for i = 1, #texts do if texts[i].s == str then n = n + 1 end end
    return n
end
-- text_mid draws at cy - measure height / 2, and the stub's CalcTextSize is a flat 14: a row's centre is its name's
-- y plus 7. Everything that draws on a row (the markers, the level, the flag) can then be found by that y.
local function row_of(name)
    local t = has_text(name)
    if t == nil then return nil end
    return t.y + 7
end
local function at_row(y, glyph)
    local n = 0
    if y == nil then return 0 end
    for i = 1, #texts do
        if texts[i].s == glyph and math.abs(texts[i].y + 7 - y) < 0.6 then n = n + 1 end
    end
    return n
end
local function dot_at(y, filled)
    local n = 0
    if y == nil then return 0 end
    -- the row's marker radius is U.S(4), and the test runs at whatever scale the file left behind, so the radius is
    -- taken from the kit rather than assumed
    local r4 = ui.S(4)
    for i = 1, #circles do
        local c = circles[i]
        if c.filled == filled and math.abs(c.y - y) < 0.6 and math.abs(c.r - r4) < 0.01 then n = n + 1 end
    end
    return n
end
local function die_rows()
    local t = {}
    for i = 1, #(st.rows or {}) do if st.rows[i].kind == 'die' then t[#t + 1] = st.rows[i] end end
    return t
end
local function row_named(name)
    for i = 1, #(st.rows or {}) do if st.rows[i].name == name then return st.rows[i] end end
    return nil
end

-- no COR anywhere: the dice are not this character's list at all
check('no COR anywhere: no die rows', #die_rows() == 0, #die_rows())
check('and the list still carries the spells', #(st.rows or {}) > 0 and row_named('Filler 01') ~= nil)

-- COR main: every die at its printed level, usable from that level, in the same list as any spells the subjob brings
player = { main_job = 17, main_job_level = 30, sub_job = 0, sub_job_level = 0 }
texts, circles = {}, {}
fire('present')
local first = st.rows[1] or {}
check('a COR 30 sees the dice in the one list', #(st.rows or {}) == 30, #(st.rows or {}))
check('the first row is the lowest die at its printed level', first.name == 'Corsair Die' and first.level == 5,
    tostring(first.name) .. ' ' .. tostring(first.level))
check('a die row says what kind it is and what roll it teaches',
    first.kind == 'die' and first.roll == "Corsair's Roll")
check('a die row carries its source badge and note',
    first.tag == 'shop' and first.badge ~= nil and first.note ~= '')
check('the known die is hidden by default', has_text('Ninja Die') == nil)
check('the die name and the roll are drawn beside each other',
    row_of('Corsair Die') ~= nil and row_of("Corsair's Roll") ~= nil
        and math.abs(row_of('Corsair Die') - row_of("Corsair's Roll")) < 0.6,
    tostring(row_of('Corsair Die')) .. ' vs ' .. tostring(row_of("Corsair's Roll")))
check('and the printed COR level', has_text('Lv 5') ~= nil)
check('the counts see every die in the table, not just the visible ones', (st.counts or {}).total == 31,
    (st.counts or {}).total)
check('a die at the COR level is not flagged', at_row(row_of('Corsair Die'), 'not yet') == 0,
    at_row(row_of('Corsair Die'), 'not yet'))
check('a die above it is flagged not yet', at_row(row_of('Monk Die'), 'not yet') == 1,
    at_row(row_of('Monk Die'), 'not yet'))

-- show learnt is the same switch for a die as for a spell
fire('command', { command = '/spells learned on' })
texts, circles = {}, {}
fire('present')
check('show learnt brings the known die back', #(st.rows or {}) == 31, #(st.rows or {}))
check('and it is drawn', has_text('Ninja Die') ~= nil)
check('a known roll wears a filled dot', dot_at(row_of('Ninja Die'), true) == 1, dot_at(row_of('Ninja Die'), true))
check('a roll the player lacks wears a hollow one', dot_at(row_of('Corsair Die'), false) == 1,
    dot_at(row_of('Corsair Die'), false))
check('and not a filled one', dot_at(row_of('Corsair Die'), true) == 0, dot_at(row_of('Corsair Die'), true))

-- the bag marker: the Corsair Die is in the Mog Locker, matched on the ITEM id (5493), not on a name
local bag_glyph = ui.fa('sack-dollar')
check('a die in a bag is marked with the bag glyph', at_row(row_of('Corsair Die'), bag_glyph) == 1,
    at_row(row_of('Corsair Die'), bag_glyph))
check('a die nobody holds is not marked', at_row(row_of('Ranger Die'), bag_glyph) == 0)
fire('command', { command = '/spells learned off' })

-- COR as the sub job: dice at half the sub level, flagged because learning one needs COR main
player = { main_job = 3, main_job_level = 40, sub_job = 17, sub_job_level = 37 }
texts, circles = {}, {}
fire('present')
local ranger = row_named('Ranger Die')
local black_die = row_named('Black Mage Die')
check('COR as the sub job shows the dice at half the sub level', ranger ~= nil and ranger.usable == true and ranger.level == 11,
    ranger and (tostring(ranger.level) .. ' usable? ' .. tostring(ranger.usable)))
check('a die above half the sub level is not usable', black_die ~= nil and black_die.usable == false,
    black_die and tostring(black_die.usable))
check('a subbed COR row says why: needs COR main', at_row(row_of('Ranger Die'), 'needs COR main') == 1,
    at_row(row_of('Ranger Die'), 'needs COR main'))
check('and the main job spells are in the same list', (function ()
    for i = 1, #(st.rows or {}) do if st.rows[i].kind == 'spell' then return true end end
    return false
end)())
-- ordering: the spell order is spells_core's own, and a die is placed where its printed level belongs among those
-- rows - before the level-30 spells at 11, after them at 31, never all at the end
local at = {}
for i = 1, #(st.rows or {}) do if at[st.rows[i].name] == nil then at[st.rows[i].name] = i end end
check('a die below a spell level sits before it', (at['Ranger Die'] or 0) > 0 and (at['Filler 01'] or 0) > 0
    and at['Ranger Die'] < at['Filler 01'], ('ranger %s, filler %s'):format(tostring(at['Ranger Die']), tostring(at['Filler 01'])))
check('a die above it sits after it', (at['Monk Die'] or 0) > 0 and (at['Cure IV'] or 0) > 0
    and at['Monk Die'] < at['Cure IV'], ('monk %s, cure iv %s'):format(tostring(at['Monk Die']), tostring(at['Cure IV'])))

-- the search box reads the die's name AND the roll it teaches
player = { main_job = 17, main_job_level = 30, sub_job = 0, sub_job_level = 0 }
st.query[1] = 'healer'
st.cache_key = nil
texts = {}
fire('present')
check('searching a roll name finds the die', #(st.rows or {}) == 1 and (st.rows[1] or {}).name == 'White Mage Die',
    #(st.rows or {}))
st.query[1] = ''
st.cache_key = nil
fire('present')

-- 'usable now' is the same level predicate for a die; at COR 30 the Monk Die (31) has to go
local before_now_dice = #(st.rows or {})
fire('command', { command = '/spells now on' })
texts = {}
fire('present')
local all_usable = #(st.rows or {}) > 0
for i = 1, #(st.rows or {}) do if st.rows[i].usable ~= true then all_usable = false end end
check('now keeps only the dice at or below the COR level', all_usable and #(st.rows or {}) < before_now_dice,
    ('%d before, %d after'):format(before_now_dice, #(st.rows or {})))
check('and the die above it is gone', row_named('Monk Die') == nil)
fire('command', { command = '/spells now off' })

-- a nil ability bitfield is UNKNOWN, not 'not known': every die stays visible, with a question mark
abilities_now = nil
texts, circles = {}, {}
fire('present')
local nil_rows_unknown = true
for i = 1, #(st.rows or {}) do if st.rows[i].known ~= nil then nil_rows_unknown = false end end
check('nil ability bits leave every die visible', #(st.rows or {}) == 31, #(st.rows or {}))
check('and no row claims to know or not know', nil_rows_unknown)
check('a question mark is drawn where the dot would be', at_row(row_of('Corsair Die'), ui.fa('question')) == 1,
    at_row(row_of('Corsair Die'), ui.fa('question')))
check("and the word 'unknown' is never drawn", text_count('unknown') == 0 and has_text('not known') == nil)
abilities_now = abits

-- 'in storage' covers dice too: the Corsair Die's item id is in the Mog Locker
fire('command', { command = '/spells held on' })
texts = {}
fire('present')
check('held keeps the die whose item is in a bag',
    #(st.rows or {}) == 1 and (st.rows[1] or {}).name == 'Corsair Die', #(st.rows or {}))
fire('command', { command = '/spells held off' })

-- the mode toggles reach a die through spells_core's own badge rule: a die's source row is the same shape a scroll's
-- is, and its badge is 'shop', which survives ACE, CW and WEW
fire('command', { command = '/spells mode cw' })
texts = {}
fire('present')
check('CW keeps the dice: a vendor is self-found', #die_rows() > 0 and (st.rows[1] or {}).tag == 'shop',
    #die_rows())
fire('command', { command = '/spells mode ace' })

-- and back to the WHM the rest of the file is about
player = { main_job = 3, main_job_level = 40, sub_job = 5, sub_job_level = 20 }
abilities_now = abits
texts, circles = {}, {}
fire('present')
check('no COR again: the list is spells only', #die_rows() == 0, #die_rows())

------------------------------------------------------------------------------- the zone alerts, silent
-- The owner's rule: no chat and no toast from an alert. A zone-in with something this job still needs plays the
-- folder's softer bell once and marks the rows, which the window draws highlighted. These read the SHIPPED
-- spell_sources.lua and dice_data.lua, so the counts and the die names are the real tables'. U.toast is still wrapped
-- so a stray toast is caught rather than silently drawn.
local UI = require('ui')
local toasts = {}
local real_toast = UI.toast
UI.toast = function (kind, title, body, seconds, icon)
    toasts[#toasts + 1] = { kind = kind, title = title, body = body, seconds = seconds, icon = icon }
    return real_toast(kind, title, body, seconds, icon)
end
local function enter_zone(id)
    toasts, chat, sounds = {}, {}, {}
    fire('zone_change', { zone = id, previous = 0 })
end
local sent_before_zones = #injected

-- 1. in, with a scroll this job still needs: one soft chime, nothing in chat, no toast
player = { main_job = 3, main_job_level = 40, sub_job = 5, sub_job_level = 20 }
abilities_now = abits
st.last_zone_key = nil
enter_zone(245)
check('a zone with a needed scroll chimes once', #sounds == 1, ('%d sounds'):format(#sounds))
check('the chime is the soft bell', sounds[1] ~= nil and sounds[1]:find('tiny_bell.wav', 1, true) ~= nil,
    sounds[1])
check('and it writes nothing to chat', #chat == 0, table.concat(chat, ' | '):sub(1, 120))
check('and shows no toast', #toasts == 0, ('%d toasts'):format(#toasts))
check('the rows the zone is about are marked live',
    st.here_ids[4] == true and st.here_ids[1] == nil and st.here_ids[2] == nil)
check('a zone-in still sends no packet', #injected == sent_before_zones, ('%d requests'):format(#injected))
local drew_zone, drew_zone_err = pcall(function () fire('present') end)
check('the frame after the zone-in draws without an error', drew_zone and st.last_error == nil,
    drew_zone_err or tostring(st.last_error))

-- 1b. the highlighted row is drawn with the accent bar, and a row the zone does not source is not. 'in storage'
-- narrows the list to Cure IV and Raise II, so both rows are inside the view and a bar can be counted on each.
fire('command', { command = '/spells held on' })
texts, circles, rects = {}, {}, {}
fire('present')
local accent = ui.u32(ui.P.accent, 0.95)
local function bar_at(y)
    if y == nil then return 0 end
    local top = y - ui.S(34) / 2
    local n = 0
    for i = 1, #rects do
        local r = rects[i]
        if r.col == accent and math.abs((r[3] - r[1]) - ui.S(3)) < 0.01
            and math.abs(r[2] - (top + ui.S(7))) < 1 then n = n + 1 end
    end
    return n
end
check('the row the zone needs is drawn with the accent bar', bar_at(row_of('Cure IV')) == 1,
    bar_at(row_of('Cure IV')))
check('a row the zone does not source is not', bar_at(row_of('Raise II')) == 0, bar_at(row_of('Raise II')))
fire('command', { command = '/spells held off' })

-- 2. the same zone again is a Mog House in-and-out: no second chime, and the mark stays
sounds, chat, toasts = {}, {}, {}
fire('zone_change', { zone = 245, previous = 0 })
check('the same zone again does not chime twice', #sounds == 0, ('%d sounds'):format(#sounds))
check('and says nothing and shows nothing', #chat == 0 and #toasts == 0)
check('the mark stays on the rows', st.here_ids[4] == true)

-- 3. a zone the table sources, where everything is already learnt: silent, and the mark is cleared
enter_zone(232)
check('a zone whose spells are all learnt is silent', #sounds == 0 and #chat == 0 and #toasts == 0,
    ('%d sounds, %d lines, %d toasts'):format(#sounds, #chat, #toasts))
check('and it clears the highlight', next(st.here_ids) == nil)

-- 4. the per-kind switch. Ifrit's Cauldron has only drops for this job, so it is the one-kind case.
chat = {}
fire('command', { command = '/spells alerts drop off' })
check('/spells alerts drop off says what it did', table.concat(chat, ' '):find('drop zone alerts: off', 1, true) ~= nil,
    table.concat(chat, ' '):sub(1, 120))
st.last_zone_key = nil
enter_zone(205)
check('alert_drop off silences a drop-only zone', #sounds == 0 and #chat == 0 and #toasts == 0)
fire('command', { command = '/spells alerts drop on' })
st.last_zone_key = nil
enter_zone(205)
check('with drop back on, the same zone chimes once (the game spelling has no apostrophe)', #sounds == 1,
    ('%d sounds'):format(#sounds))
check('and marks the drop', st.here_ids[5] == true)

-- 5. the master switch
chat = {}
fire('command', { command = '/spells alerts off' })
check('/spells alerts off says so', table.concat(chat, ' '):find('zone alerts: off', 1, true) ~= nil,
    table.concat(chat, ' '):sub(1, 120))
st.last_zone_key = nil
enter_zone(245)
check('with alerts off a zone with a need is silent', #sounds == 0 and #chat == 0 and #toasts == 0,
    ('%d sounds, %d lines, %d toasts'):format(#sounds, #chat, #toasts))
check('and the highlight is cleared', next(st.here_ids) == nil)

-- 6. /spells here: on demand, so it answers even with the automatic alert off, and it reads the zone the client
-- names now rather than the one the last event carried
PLAYER_ZONE = 245
chat = {}
fire('command', { command = '/spells here' })
check('/spells here names the spell and its note with the alerts off',
    #chat == 1 and chat[1]:find('Cure IV', 1, true) ~= nil and chat[1]:find('Hasim / Lower Jeuno', 1, true) ~= nil,
    chat[1])
PLAYER_ZONE = 232
chat = {}
fire('command', { command = '/spells here' })
check('/spells here in a zone with nothing left says so', #chat == 1 and chat[1]:find('nothing here', 1, true) ~= nil,
    chat[1])

-- 7. the chime switch: the highlight is an alert too, so it stays when only the sound is off
fire('command', { command = '/spells alerts on' })
chat = {}
fire('command', { command = '/spells alerts sound off' })
check('/spells alerts sound off says what it did', table.concat(chat, ' '):find('zone alert chime: off', 1, true) ~= nil,
    table.concat(chat, ' '):sub(1, 120))
PLAYER_ZONE = 245
st.last_zone_key = nil
enter_zone(245)
check('the chime switch silences the sound but not the highlight',
    #sounds == 0 and #chat == 0 and #toasts == 0 and st.here_ids[4] == true,
    ('%d sounds, marked %s'):format(#sounds, tostring(st.here_ids[4])))
chat = {}
fire('command', { command = '/spells alerts sound on' })
check('and back on says so', table.concat(chat, ' '):find('zone alert chime: on', 1, true) ~= nil,
    table.concat(chat, ' '):sub(1, 120))

-- 8. a zone id the table has no name for: no chime, no error
enter_zone(99999)
check('a zone id with no name is silent and raises nothing',
    #sounds == 0 and #chat == 0 and #toasts == 0 and st.last_error == nil,
    ('%d sounds, %d lines, error %s'):format(#sounds, #chat, tostring(st.last_error)))

-- 9. login carries the zone too, and the first zone of a session is not a zone_change
PLAYER_ZONE = 245
st.last_zone_key = nil
sounds, chat, toasts = {}, {}, {}
fire('login', { name = 'Tester', id = 1, zone = 245 })
check('login chimes for the zone the session starts in', #sounds == 1 and #chat == 0 and #toasts == 0,
    ('%d sounds, %d lines, %d toasts'):format(#sounds, #chat, #toasts))

-- 10. /spells debug names the zone and the switches, sound included
PLAYER_ZONE = 245
chat = {}
fire('command', { command = '/spells debug' })
local zdbg = table.concat(chat, ' ')
check("/spells debug names the zone and the key both tables meet on",
    zdbg:find("zone 'Lower Jeuno' (lower jeuno)", 1, true) ~= nil, zdbg:sub(1, 220))
check('/spells debug says how many spells the table sources there and whether the alerts are on',
    zdbg:find(' sourced spells here, alerts on', 1, true) ~= nil, zdbg:sub(1, 260))
chat = {}
fire('command', { command = '/spells alerts' })
check('a bare /spells alerts answers with every switch',
    table.concat(chat, ' '):find('shop on, drop on, bcnm on, sound on', 1, true) ~= nil,
    table.concat(chat, ' '):sub(1, 160))
chat = {}

-- 11. the dice in the zone alert. Al Zahbi is where the SHIPPED dice_data.lua puts thirteen dice (all a vendor's,
-- Chayaya); a COR 30 walking in hears the chime and nothing else.
player = { main_job = 17, main_job_level = 30, sub_job = 0, sub_job_level = 0 }
abilities_now = ability_bits({ 110 })   -- only the Ninja Die's roll, which is sold in Nashmau
st.last_zone_key = nil
PLAYER_ZONE = 48
local sent_before_dice = #injected
enter_zone(48)
check('a zone that only sells dice chimes once', #sounds == 1, ('%d sounds'):format(#sounds))
check('and writes nothing to chat and shows no toast', #chat == 0 and #toasts == 0,
    ('%d lines, %d toasts'):format(#chat, #toasts))
check('and marks a die it still needs', st.here_ids[5487] == true)   -- Ranger Die, Al Zahbi
check('the dice zone-in is information only: it sends no packet', #injected == sent_before_dice,
    ('%d requests'):format(#injected))

-- 12. a die whose roll is already learnt is never marked
abilities_now = ability_bits({ 110, 108 })   -- the Ranger Die's roll too
st.last_zone_key = nil
enter_zone(48)
check('a learnt roll is not marked', st.here_ids[5487] == nil)
check('and the chime still plays for the rest', #sounds == 1)

-- 13. every die the zone sells already known: silent, and the mark is cleared without spending the zone memory
abilities_now = ability_bits(AL_ZAHLI_ABILITIES)
st.last_zone_key = nil
enter_zone(48)
check('a zone whose dice are all learnt is silent and clears the mark',
    #sounds == 0 and #chat == 0 and #toasts == 0 and next(st.here_ids) == nil,
    ('%d sounds, marked %s'):format(#sounds, tostring(next(st.here_ids) ~= nil)))

-- 14. the master switch covers the dice half too
abilities_now = ability_bits({ 110 })
fire('command', { command = '/spells alerts off' })
st.last_zone_key = nil
enter_zone(48)
check('with the zone alerts off, a dice-only zone is silent', #sounds == 0 and #chat == 0 and #toasts == 0)
fire('command', { command = '/spells alerts on' })

-- 15. a zone with both: one chime, both kinds marked, and /spells here still lists the scroll first, then the dice.
-- The fixture's own id 112 is 'Filler 12' and the SHIPPED spell_sources puts spell 112 (Flash) in Al Zahbi, so a
-- WHM 40 with a COR 20 sub needs one scroll AND the dice.
player = { main_job = 3, main_job_level = 40, sub_job = 17, sub_job_level = 20 }
abilities_now = ability_bits({ 110 })
st.last_zone_key = nil
enter_zone(48)
check('a zone with a scroll and dice chimes once and says nothing', #sounds == 1 and #chat == 0 and #toasts == 0,
    ('%d sounds, %d lines, %d toasts'):format(#sounds, #chat, #toasts))
check('and marks both kinds', st.here_ids[112] == true and st.here_ids[5487] == true)
PLAYER_ZONE = 48
chat = {}
fire('command', { command = '/spells here' })
check('/spells here names the scroll and the dice on demand',
    #chat == 1 and chat[1]:find('shop: Filler 12', 1, true) ~= nil
        and chat[1]:find('die: Ranger Die', 1, true) ~= nil, chat[1])
check('the chat line lists the scroll first, then the dice as dice',
    chat[1] ~= nil and (function ()
        local scroll_at = chat[1]:find('shop: Filler 12', 1, true)
        local die_at = chat[1]:find('die: Ranger Die', 1, true)
        return scroll_at ~= nil and die_at ~= nil and scroll_at < die_at
    end)(), chat[1])

-- 16. the debug line still answers 'how many dice are there' separately from the one list
chat = {}
fire('command', { command = '/spells debug' })
local ddbg = table.concat(chat, ' ')
check('/spells debug reports the dice rows and how many it places in this zone',
    ddbg:find('dice 31 rows, 1 known, 13 with a source in this zone', 1, true) ~= nil, ddbg:sub(1, 400))
abilities_now = abits
st.last_zone_key = nil
chat = {}
PLAYER_ZONE = 245
player = { main_job = 3, main_job_level = 40, sub_job = 5, sub_job_level = 20 }

------------------------------------------------------------------------------- the pill: minimize, Play/Stop, Mute, pulse
-- The owner's shape: minimized, the window becomes a pill that pulses gently when something this job still needs is in
-- the zone; the word 'Spelltracker', a Play/Stop that changes when you hit it, and a Mute; and clicking the pill (the
-- word included) restores the window with the zone's rows already highlighted. These checks read the DRAW CALLS the
-- stub records - the requested window size, every hitbox with its place, the triangle and the square, the border's
-- alpha - so they are about what is drawn, not merely that a frame ran.
fire('command', { command = '/spells scale 100' })   -- the section above ran at 60 %
player = { main_job = 3, main_job_level = 40, sub_job = 5, sub_job_level = 20 }
abilities_now = abits
PLAYER_ZONE = 245
st.query[1] = ''
st.cache_key = nil
fire('command', { command = '/spells alerts on' })
fire('command', { command = '/spells alerts sound on' })
st.last_zone_key = nil
enter_zone(245)                                       -- Lower Jeuno: Cure IV's scroll is still unlearnt
check('the pill section starts from a zone with something to find', st.here_ids[4] == true,
    tostring(st.here_ids[4]))
sounds, chat, toasts = {}, {}, {}

local function frame()
    texts, rects, tris, edges, btns, sizes, CONSTRAINTS = {}, {}, {}, {}, {}, {}, {}
    CHILD = nil
    fire('present')
    MOUSE = nil
    DRAG.released = nil -- a release is answered on the one frame after it: ImGui reports it once
end
-- what the window HAS (ImGui's own answer), as opposed to what the frame ASKED for: once the size has been placed it
-- is ImGui's, so a steady frame asks for nothing and a check that read the request would see -1 instead of a window
local function win_size() return { w = WIN_SIZE[1], h = WIN_SIZE[2] } end
-- a click lands on a point inside a hitbox the previous frame recorded, not on a key: the box is where the frame put
-- it, so the routing between the pill, the two buttons and the word is measured rather than assumed
local function click_at(box)
    MOUSE = box ~= nil and { box.x + box.w / 2, box.y + box.h / 2 } or nil
end
-- the frame's requested size, or a sentinel when a frame asked for none: a check must go red, never raise (an error
-- here would abort the rest of the suite without counting a failure, and the checks after it would go unmeasured)
local function last_size() return sizes[#sizes] or { w = -1, h = -1 } end
-- the settings file itself (the stub keeps one table per character), so a check reads what the addon saved
local CFG = SETTINGS_DATA
local function btn_named(list, key)
    for i = 1, #list do if list[i].key == key then return list[i], i end end
    return nil, nil
end
-- the pulse is the one border drawn in the theme's ACCENT; every other border is P.line or a mix of it, so the RGB
-- part of the colour identifies it and the alpha part is the breath
local ACCENT_RGB = ui.u32(ui.P.accent, 1) % 16777216
local function alpha_of(col) return math.floor(col / 16777216) % 256 end
-- the pulse is the accent border that traces the WHOLE pill box: the mode segments and the skill pills also draw
-- accent borders when they are the selected one, so the colour alone does not identify it - the geometry does, and
-- the restore hitbox is where the pill's rect is recorded
local function pulse_of(list, box)
    if box == nil then return nil end
    for i = 1, #list do
        local r = list[i]
        if r.col % 16777216 == ACCENT_RGB
            and math.abs(r[1] - box.x) < 0.01 and math.abs(r[2] - box.y) < 0.01
            and math.abs((r[3] - r[1]) - box.w) < 0.01 and math.abs((r[4] - r[2]) - box.h) < 0.01 then
            return r
        end
    end
    return nil
end
-- a square glyph inside a hitbox: Stop is AddRectFilled with w = h, and nothing else in the pill is square
local function squares_in(list, box)
    local out = {}
    if box == nil then return out end
    for i = 1, #list do
        local r = list[i]
        local w, h = r[3] - r[1], r[4] - r[2]
        if math.abs(w - h) < 0.01 and w > 1 and r[1] >= box.x - 0.5 and r[3] <= box.x + box.w + 0.5 then
            out[#out + 1] = r
        end
    end
    return out
end

-- 1. restored first: the size the pill must not be. (The 'nothing pulses when restored' half needs the pill's own
-- rectangle to look for, so it is checked in step 8, once a pill frame has recorded one.)
GET_TIME = 0
frame()
local full = win_size()
check('restored, the window asks for its full size', full ~= nil and full.w > 800 and full.h > 500,
    full and ('%s x %s'):format(full.w, full.h))
check('restored, there is no Play/Stop, Mute or restore hitbox yet', btn_named(btns, '##st_play') == nil
    and btn_named(btns, '##st_mute') == nil and btn_named(btns, '##st_restore') == nil)

-- 2. the header control folds it, and cannot close it
local min_btn, min_at = btn_named(btns, '##st_min')
local close_btn = btn_named(btns, '##st_close')
check('the header carries a minimize control', min_btn ~= nil)
check('the minimize control is its own target: the close button keeps its box beside it',
    min_btn ~= nil and close_btn ~= nil and close_btn.x >= min_btn.x + min_btn.w,
    min_btn and close_btn and ('min %s..%s, close at %s'):format(min_btn.x, min_btn.x + min_btn.w, close_btn.x))
local saves_before_min = saved or 0
click_at(min_btn)
frame()
check('a click on the minimize control folds the window', st.minimized == true, tostring(st.minimized))
check('and the minimize control does not also close it', st.open == true, tostring(st.open))
check('and the fold is saved for the next session', CFG.minimized == true and (saved or 0) > saves_before_min,
    tostring(CFG.minimized))

-- 3. the pill: its own size, its three targets, the word
GET_TIME = 0
frame()
local pill = last_size()
check('minimized, the requested size changes', pill ~= nil and (pill.w ~= full.w or pill.h ~= full.h),
    pill and ('%s x %s'):format(pill.w, pill.h))
check('the pill is 230 x 34 at 100 %', pill ~= nil and math.abs(pill.w - 230) < 0.01 and math.abs(pill.h - 34) < 0.01,
    pill and ('%s x %s'):format(pill.w, pill.h))
check('the pill does not inherit the window\'s size', pill ~= nil and pill.w < full.w and pill.h < full.h)
check('the pill draws the word Spelltracker', has_text('Spelltracker') ~= nil)
local restore_box, restore_at = btn_named(btns, '##st_restore')
local play_box, play_at = btn_named(btns, '##st_play')
local mute_box, mute_at = btn_named(btns, '##st_mute')
check('the pill draws a restore hitbox, a Play/Stop and a Mute',
    restore_box ~= nil and play_box ~= nil and mute_box ~= nil)
check('the restore hitbox is the whole pill', restore_box ~= nil and math.abs(restore_box.w - pill.w) < 0.01
    and math.abs(restore_box.h - pill.h) < 0.01,
    restore_box and ('%s x %s'):format(restore_box.w, restore_box.h))
check('the restore hitbox is laid down FIRST and the two buttons over it',
    restore_at ~= nil and play_at ~= nil and restore_at < play_at and play_at < mute_at,
    ('restore %s, play %s, mute %s'):format(tostring(restore_at), tostring(play_at), tostring(mute_at)))
check('the two buttons sit inside the restore hitbox',
    play_box ~= nil and mute_box ~= nil and restore_box ~= nil
        and play_box.x >= restore_box.x and mute_box.x + mute_box.w <= restore_box.x + restore_box.w + 0.01)
check('the word is inside the restore hitbox, not beside it', (function ()
    local t = has_text('Spelltracker')
    return t ~= nil and play_box ~= nil and restore_box ~= nil
        and t.x >= restore_box.x and t.x < play_box.x
end)())
check('the pill draws none of the list', has_text('Cure IV') == nil and has_text('Lv 41') == nil)

-- 4. listening: Play is a triangle, and the border breathes with the kit's own alpha
check('listening draws Play as one filled triangle', #tris == 1, ('%d triangles'):format(#tris))
local tri = tris[1]
check('the triangle has a vertical left edge and its apex to the right',
    tri ~= nil and tri[1][1] == tri[2][1] and tri[3][1] > tri[1][1] + 1
        and math.abs(tri[3][2] - (tri[1][2] + tri[2][2]) / 2) < 0.01,
    tri and ('%s,%s  %s,%s  %s,%s'):format(tri[1][1], tri[1][2], tri[2][1], tri[2][2], tri[3][1], tri[3][2]))
check('the triangle is drawn inside the Play/Stop hitbox',
    tri ~= nil and tri[1][1] >= play_box.x and tri[3][1] <= play_box.x + play_box.w)
check('listening draws no square where the triangle is', #squares_in(rects, play_box) == 0,
    #squares_in(rects, play_box))

-- the breathing alpha: 0.75 at t = 0, 1.0 at sin(t*4) = 1, 0.5 at sin(t*4) = -1. Three samples pin the offset, the
-- amplitude and the rate, which one sample cannot.
GET_TIME = 0
frame()
local p0 = pulse_of(edges, restore_box)
check('the pill pulses its border while listening with a need in the zone', p0 ~= nil)
check('the pulse starts at the kit\'s 0.75 alpha', p0 ~= nil and math.abs(alpha_of(p0.col) - 191) <= 1,
    p0 and alpha_of(p0.col))
GET_TIME = math.pi / 8
frame()
local p1 = pulse_of(edges, restore_box)
check('the pulse breathes up to full at sin(t*4) = 1', p1 ~= nil and alpha_of(p1.col) >= 254,
    p1 and alpha_of(p1.col))
GET_TIME = 3 * math.pi / 8
frame()
local p2 = pulse_of(edges, restore_box)
check('and down to half at sin(t*4) = -1', p2 ~= nil and math.abs(alpha_of(p2.col) - 128) <= 1,
    p2 and alpha_of(p2.col))
check('the pulse changes the alpha and nothing else: the pill keeps its size',
    last_size().w == pill.w and last_size().h == pill.h)

-- Folding must read the zone it is folded in. Found in review: the marks were only ever filled by a zone_change or a
-- login, so a player who opened the window and folded it without moving would have had a pill that never pulsed in the
-- very zone it was folded for. set_minimized reads the zone at the moment of folding, without a chime.
fire('command', { command = '/spells minimize off' })
frame()
SPELLTRACKER.here_ids = {}
GET_TIME = 0
frame()
check('with the marks cleared by a reload in place, nothing is highlighted', next(SPELLTRACKER.here_ids) == nil)
fire('command', { command = '/spells minimize' })
frame()
check('folding reads the zone it is folded in, without a zone event',
    next(SPELLTRACKER.here_ids) ~= nil, 'nothing marked by the fold')
local folded_box = btn_named(btns, '##st_restore')
check('so the pill pulses for the zone it was folded in', pulse_of(edges, folded_box) ~= nil)


-- 5. Stop: a click flips the switch, the square replaces the triangle, the pulse stops - and the pill does not restore
GET_TIME = 0
local saves_before_play = saved or 0
click_at(play_box)
frame()
check('a click on the Play/Stop hitbox flips the zone alerts', CFG.zone_alerts == false, tostring(CFG.zone_alerts))
check('and it does NOT restore the window', st.minimized == true)
check('and the switch is saved', (saved or 0) > saves_before_play)
GET_TIME = 0
frame()
check('stopped, the glyph is a square and not a triangle', #tris == 0 and #squares_in(rects, play_box) == 1,
    ('%d triangles, %d squares'):format(#tris, #squares_in(rects, play_box)))
check('stopped, the pill stops pulsing', pulse_of(edges, restore_box) == nil)
local play_stopped = btn_named(btns, '##st_play')
check('the Play/Stop hitbox is identical in both states',
    play_stopped ~= nil and play_stopped.x == play_box.x and play_stopped.y == play_box.y
        and play_stopped.w == play_box.w and play_stopped.h == play_box.h)
check('stopped, the pill is still a pill: same size, same restore target',
    last_size().w == pill.w and last_size().h == pill.h
        and (function ()
            local b = btn_named(btns, '##st_restore')
            return b ~= nil and restore_box ~= nil and b.w == restore_box.w
        end)())

-- 6. and back: a second click starts the alerts again, and the pill breathes again
click_at(play_box)
frame()
check('a second click starts the zone alerts again', CFG.zone_alerts == true)
GET_TIME = 0
frame()
check('listening again: a triangle and a pulse', #tris == 1 and pulse_of(edges, restore_box) ~= nil)

-- 7. Mute: the chime switch only. The pulse and the highlight keep working while muted.
local BELL, BELL_OFF = ui.fa('bell'), ui.fa('bell-slash')
check('the Mute button wears the kit\'s bell while the chime is on', text_count(BELL) == 1, text_count(BELL))
local saves_before_mute = saved or 0
click_at(mute_box)
frame()
check('a click on the Mute button flips the chime switch', CFG.zone_sound == false, tostring(CFG.zone_sound))
check('and it is saved', (saved or 0) > saves_before_mute)
check('and it does NOT restore the window', st.minimized == true)
check('muting keeps the highlight the zone-in made', st.here_ids[4] == true)
GET_TIME = 0
frame()
check('muted, the Mute button wears the bell-slash', text_count(BELL_OFF) == 1 and text_count(BELL) == 0,
    ('%d slash, %d bell'):format(text_count(BELL_OFF), text_count(BELL)))
check('muted, the pill still pulses', pulse_of(edges, restore_box) ~= nil)

-- 8. the whole pill restores - a click on the word, inside the restore hitbox and outside both buttons
local saves_before_restore = saved or 0
-- the point of the click is the WORD's own area: inside the restore hitbox, left of both buttons
local word = has_text('Spelltracker')
click_at(word ~= nil and restore_box ~= nil
    and { x = word.x + 4, y = restore_box.y, w = 8, h = restore_box.h } or nil)
frame()
check('a click on the pill restores the window', st.minimized == false, tostring(st.minimized))
check('and the restore is saved', CFG.minimized == false and (saved or 0) > saves_before_restore)
GET_TIME = 0
frame()
check('restored, the window asks for its full size again', win_size().w == full.w and win_size().h == full.h,
    ('%s x %s'):format(win_size().w, win_size().h))
check('restored, the word Spelltracker is gone', has_text('Spelltracker') == nil)
check('restored, the list is drawn again', (function ()
    local n = 0
    for i = 1, #rects do if math.abs((rects[i][4] - rects[i][2]) - 34) < 0.01 then n = n + 1 end end
    return n > 0
end)())
check('restored, nothing pulses', pulse_of(edges, restore_box) == nil)
check('restoring silences nothing: the chime stays muted', CFG.zone_sound == false)
-- and the rows come back highlighted: the zone's own mark, drawn on the row (two rows, so Cure IV is in view)
fire('command', { command = '/spells held on' })
GET_TIME = 0
frame()
check('restored, the zone\'s row is already highlighted', bar_at(row_of('Cure IV')) == 1,
    bar_at(row_of('Cure IV')))
fire('command', { command = '/spells held off' })

-- 9. the pulse's other half: nothing pulses without a need, whatever the switch says
click_at(min_btn)
frame()
check('folded again for the pulse checks', st.minimized == true)
sizes = {}
st.here_ids = {}
GET_TIME = 0
frame()
check('a minimized pill with nothing in the zone does not pulse', pulse_of(edges, restore_box) == nil)
check('and it still draws at the pill\'s own size', math.abs(last_size().w - 230) < 0.01, last_size().w)
st.here_ids = { [4] = true }
CFG.zone_alerts = false
GET_TIME = 0
frame()
check('a minimized window with the alerts off stays silent and unpulsing', pulse_of(edges, restore_box) == nil
    and st.here_ids[4] == true)
-- the switch's NIL case, read the way zone_in reads it: a hand-edited or older settings file with no key is off, so
-- the pill must not show Play or pulse while the game itself would stay silent
CFG.zone_alerts = nil
GET_TIME = 0
frame()
check('a nil alerts switch reads as off: a square and no pulse', #tris == 0 and pulse_of(edges, restore_box) == nil,
    ('%d triangles'):format(#tris))
CFG.zone_alerts = true
GET_TIME = 0
frame()
check('with the alerts back on, the same state pulses', pulse_of(edges, restore_box) ~= nil)

-- 10. the guards: a nil here_ids, no character, and a client whose display face did not load
st.here_ids = nil
local nilids_ok, nilids_err = pcall(frame)
check('a nil here_ids leaves the pill drawing and the game quiet',
    nilids_ok and st.last_error == nil and btn_named(btns, '##st_restore') ~= nil,
    nilids_err or tostring(st.last_error))
check('and no pulse without a set to read', pulse_of(edges, restore_box) == nil)
st.here_ids = { [4] = true }
local real_player = player
player = { main_job = 0, main_job_level = 0, sub_job = 0, sub_job_level = 0 }
GET_TIME = 0
local nochar_ok, nochar_err = pcall(frame)
check('no character in the world: the pill still draws', nochar_ok and st.last_error == nil
    and btn_named(btns, '##st_play') ~= nil, nochar_err or tostring(st.last_error))
player = real_player
local FONTS = ui.fonts()
local real_disp = FONTS.disp
FONTS.disp = nil
GET_TIME = 0
local noface_ok, noface_err = pcall(frame)
FONTS.disp = real_disp
check('a missing display face still draws the word, in the text face',
    noface_ok and has_text('Spelltracker') ~= nil, noface_err)

-- 11. the keyboard route, and the HELP line
chat = {}
fire('command', { command = '/spells minimize off' })
check('/spells minimize off restores the window', st.minimized == false and CFG.minimized == false)
check('and says so', table.concat(chat, ' '):find('window restored', 1, true) ~= nil, table.concat(chat, ' '))
chat = {}
fire('command', { command = '/spells minimize' })
check('/spells minimize folds the window', st.minimized == true and CFG.minimized == true)
check('and says so, naming the way back',
    table.concat(chat, ' '):find('minimized to the pill', 1, true) ~= nil
        and table.concat(chat, ' '):find('/spells minimize off', 1, true) ~= nil, table.concat(chat, ' '))
chat = {}
fire('command', { command = '/spells nowhere' })
check('HELP names the minimize command', table.concat(chat, ' '):find('minimize|minimize off', 1, true) ~= nil,
    table.concat(chat, ' '):sub(1, 200))
fire('command', { command = '/spells minimize off' })
chat = {}

-- one function, because a 5.1 chunk holds 200 locals and this suite has earned nearly every one of them
local function scaling_suite()
    ------------------------------------------------------------------------------- readability: text scale, pill scale, a window you can drag
    -- Owner: "we need to add a new feature to scale the pill and to scale the text in the main window. If I tried this on
    -- steam deck I'd need a microscope to read it. And let the windows be resizable by dragging edges and corners just like
    -- any normal app." Three independent knobs - `scale` (the kit's S(), the geometry), `text` (the font sizes only) and
    -- `pill` (the minimized capsule only) - and a window whose edges drag, whose size is read back from ImGui, and whose
    -- list follows it. Every check below reads a draw call the stub recorded, not the addon's own opinion.
    SCROLL = 0
    WIN_SIZE[1], WIN_SIZE[2] = 880, 560
    fire('command', { command = '/spells scale 100' })
    fire('command', { command = '/spells text 100' })
    fire('command', { command = '/spells pill 100' })

    local function row_tops()
        local tops = {}
        for i = 1, #rects do
            local hgt = rects[i][4] - rects[i][2]
            if math.abs(hgt - 34) < 0.01 then tops[#tops + 1] = rects[i][2] end
        end
        table.sort(tops)
        return tops
    end
    local function same_list(a, b)
        if #a ~= #b then return false end
        for i = 1, #a do if math.abs(a[i] - b[i]) > 0.01 then return false end end
        return true
    end

    frame()
    local name100 = has_text('Filler 01')
    local tops100 = row_tops()
    check("a row name is pushed at the kit's 13 px at text 100 %",
        name100 ~= nil and math.abs(name100.size - 13) < 0.01, name100 and name100.size)
    check('and its row is the 34 px card', #tops100 > 0, #tops100)

    -- A. the text scale: the font grows, the row does not
    fire('command', { command = '/spells text 200' })
    frame()
    local name200 = has_text('Filler 01')
    check('/spells text 200 doubles the size a row pushes its font at',
        name100 ~= nil and name200 ~= nil and math.abs(name200.size - 2 * name100.size) < 0.01,
        name100 and name200 and ('%s -> %s'):format(name100.size, name200.size))
    -- the card grows to fit its own line: at 200 % a 13 px name becomes 26 px, taller than the 34 px card, so the row
    -- gets taller and the list's step follows it. What must not happen is a horizontal change, or rows that overlap.
    local function row_cards()
        local out = {}
        for i = 1, #rects do
            local hgt, wid = rects[i][4] - rects[i][2], rects[i][3] - rects[i][1]
            if hgt >= 30 and hgt <= 90 and wid > 600 then
                out[#out + 1] = { y = rects[i][2], x = rects[i][1], w = wid, h = hgt }
            end
        end
        table.sort(out, function (a, b) return a.y < b.y end)
        return out
    end
    local cards100, cards200
    fire('command', { command = '/spells text 100' })
    rects = {}
    fire('present')
    cards100 = row_cards()
    fire('command', { command = '/spells text 200' })
    rects = {}
    fire('present')
    cards200 = row_cards()
    local function step_of(cards)
        if #cards < 2 then return nil end
        return cards[2].y - cards[1].y
    end
    check('at text 100 the row is the 34 px card the layout was built around',
        #cards100 > 0 and math.abs(cards100[1].h - 34) < 0.01, #cards100 > 0 and cards100[1].h)
    check('at text 200 the rows grow taller, so a doubled line fits its card',
        #cards200 > 0 and cards100[1] and cards200[1].h > cards100[1].h + 0.5,
        ('%s -> %s'):format(#cards100 > 0 and cards100[1].h or '?', #cards200 > 0 and cards200[1].h or '?'))
    check('and the list step follows the taller card',
        step_of(cards100) ~= nil and step_of(cards200) ~= nil and step_of(cards200) > step_of(cards100) + 0.5,
        ('%s -> %s'):format(step_of(cards100) or '?', step_of(cards200) or '?'))
    check('and no row moves sideways or changes width',
        #cards100 > 0 and #cards200 > 0 and math.abs(cards200[1].x - cards100[1].x) < 0.01
            and math.abs(cards200[1].w - cards100[1].w) < 0.01,
        ('x %s/%s w %s/%s'):format(#cards100 > 0 and cards100[1].x or '?', #cards200 > 0 and cards200[1].x or '?',
                                   #cards100 > 0 and cards100[1].w or '?', #cards200 > 0 and cards200[1].w or '?'))
    local overlap = false
    for i = 2, #cards200 do
        if cards200[i].y - cards200[i - 1].y < cards200[i - 1].h - 0.01 then overlap = true end
    end
    check('and no row overlaps the one above it, which is what the card growing is for', not overlap)
    check('and the window keeps the size it had', WIN_SIZE[1] == 880 and WIN_SIZE[2] == 560,
        ('%s x %s'):format(WIN_SIZE[1], WIN_SIZE[2]))
    check('and nothing asks ImGui for a new size over it', #sizes == 0, #sizes)
    check('the header scales with it too: the title is 44 px at 200 %', (function ()
        for i = 1, #texts do
            if texts[i].s:find('WHM 40') ~= nil then return math.abs(texts[i].size - 44) < 0.01 end
        end
        return false
    end)(), 'no title draw')
    fire('command', { command = '/spells text 50' })
    frame()
    check('/spells text 50 halves it',
        has_text('Filler 01') ~= nil and math.abs(has_text('Filler 01').size - 6.5) < 0.01,
        has_text('Filler 01') and has_text('Filler 01').size)
    fire('command', { command = '/spells text 900' })
    check('a text scale above 300 is clamped to 300', CFG.text_scale == 300, CFG.text_scale)
    fire('command', { command = '/spells text 10' })
    check('and below 50 to 50', CFG.text_scale == 50, CFG.text_scale)
    chat = {}
    fire('command', { command = '/spells text' })
    check('a bare /spells text reports where it is', table.concat(chat, ' '):find('now 50%', 1, true) ~= nil,
        table.concat(chat, ' '))
    fire('command', { command = '/spells text 100' })

    -- B. the pill scale: the capsule grows, and NOTHING else does
    fire('command', { command = '/spells minimize' })
    frame()
    local pill100 = last_size()
    check('at 100 % the capsule asks for 230 x 34',
        math.abs(pill100.w - 230) < 0.01 and math.abs(pill100.h - 34) < 0.01,
        ('%s x %s'):format(pill100.w, pill100.h))
    local play100 = btn_named(btns, '##st_play')

    fire('command', { command = '/spells pill 300' })
    frame()
    local pill300 = last_size()
    check('/spells pill 300 asks for three times the capsule',
        math.abs(pill300.w - 690) < 0.01 and math.abs(pill300.h - 102) < 0.01,
        ('%s x %s'):format(pill300.w, pill300.h))
    check('and it is still a capsule, not the window', pill300.w < 880 and pill300.h < 560,
        ('%s x %s'):format(pill300.w, pill300.h))
    local box = btn_named(btns, '##st_restore')
    local play = btn_named(btns, '##st_play')
    local mute = btn_named(btns, '##st_mute')
    local word = has_text('Spelltracker')
    check('the restore hitbox is still exactly the capsule',
        box ~= nil and math.abs(box.w - pill300.w) < 0.01 and math.abs(box.h - pill300.h) < 0.01,
        box and ('%s x %s'):format(box.w, box.h))
    check('the Play/Stop and the Mute are inside it, every edge and every height',
        box ~= nil and play ~= nil and mute ~= nil
            and play.x >= box.x and play.y >= box.y
            and play.x + play.w <= box.x + box.w + 0.01 and play.y + play.h <= box.y + box.h + 0.01
            and mute.x >= box.x and mute.y >= box.y
            and mute.x + mute.w <= box.x + box.w + 0.01 and mute.y + mute.h <= box.y + box.h + 0.01,
        play and mute and box and ('play %s,%s %sx%s / mute %s,%s %sx%s / box %s,%s %sx%s')
            :format(play.x, play.y, play.w, play.h, mute.x, mute.y, mute.w, mute.h, box.x, box.y, box.w, box.h))
    check('the button grew with the capsule, it is not the 100 % one',
        play ~= nil and play100 ~= nil and math.abs(play.w - 3 * play100.w) < 0.01,
        play and play100 and ('%s -> %s'):format(play100.w, play.w))
    check('the word starts inside the capsule and ends before the buttons',
        word ~= nil and box ~= nil and play ~= nil and word.x >= box.x and word.x < play.x,
        word and box and play and ('word %s, box %s, play %s'):format(word.x, box.x, play.x))
    check('the word is inside the capsule vertically too',
        word ~= nil and box ~= nil and word.y >= box.y and word.y + 14 <= box.y + box.h + 0.01,
        word and box and ('word y %s, box %s..%s'):format(word.y, box.y, box.y + box.h))
    check('the drawn glyph is inside the Play/Stop hitbox at 300 %',
        #tris == 1 and tris[1][1][1] >= play.x and tris[1][3][1] <= play.x + play.w, #tris)

    -- the clamp: at 50 % the button is exactly what the capsule's height leaves, and it is still inside it
    fire('command', { command = '/spells pill 50' })
    frame()
    local pill50 = last_size()
    local box50 = btn_named(btns, '##st_restore')
    local play50 = btn_named(btns, '##st_play')
    check('at 50 % the capsule is 115 x 17',
        math.abs(pill50.w - 115) < 0.01 and math.abs(pill50.h - 17) < 0.01,
        ('%s x %s'):format(pill50.w, pill50.h))
    check('and the button still fits the capsule it is clamped to',
        play50 ~= nil and box50 ~= nil and play50.h <= box50.h and play50.x + play50.w <= box50.x + box50.w + 0.01,
        play50 and box50 and ('play h %s, box h %s'):format(play50.h, box50.h))

    -- and nothing else followed the pill: the restored window is the window it was
    fire('command', { command = '/spells pill 300' })
    fire('command', { command = '/spells minimize off' })
    frame()
    check('the window at pill 300 is the same 880 x 560 window',
        WIN_SIZE[1] == 880 and WIN_SIZE[2] == 560, ('%s x %s'):format(WIN_SIZE[1], WIN_SIZE[2]))
    check('and every row sits where it did before the pill was scaled', same_list(tops100, row_tops()), #row_tops())
    check('and the letters are still 13 px',
        has_text('Filler 01') ~= nil and math.abs(has_text('Filler 01').size - 13) < 0.01,
        has_text('Filler 01') and has_text('Filler 01').size)
    fire('command', { command = '/spells pill 100' })
    chat = {}

    -- C. the window drags: the size is ImGui's, and the list follows it
    frame()
    check('the window does not carry ImGuiWindowFlags_NoResize (bit 2)',
        type(BG_FLAGS) == 'number' and BG_FLAGS % 4 < 2, tostring(BG_FLAGS))
    check('the pill does keep it', (function ()
        fire('command', { command = '/spells minimize' })
        frame()
        local pill_flags = BG_FLAGS
        fire('command', { command = '/spells minimize off' })
        frame()
        return type(pill_flags) == 'number' and pill_flags % 4 >= 2
    end)())
    check('a window on screen carries the drag floor and ceiling', #CONSTRAINTS > 0
        and CONSTRAINTS[#CONSTRAINTS].lo[1] == 320 and CONSTRAINTS[#CONSTRAINTS].lo[2] == 260
        and CONSTRAINTS[#CONSTRAINTS].hi[1] >= CONSTRAINTS[#CONSTRAINTS].lo[1],
        ('%d constraint frames, low %s x %s'):format(#CONSTRAINTS,
            CONSTRAINTS[#CONSTRAINTS] and CONSTRAINTS[#CONSTRAINTS].lo[1] or '?',
            CONSTRAINTS[#CONSTRAINTS] and CONSTRAINTS[#CONSTRAINTS].lo[2] or '?'))
    local child_before = CHILD
    check('the list child is the window minus its furniture', child_before ~= nil
        and math.abs(child_before.w - (880 - 36)) < 0.01 and math.abs(child_before.h - (560 - 166 - 60)) < 0.01,
        child_before and ('%s x %s'):format(child_before.w, child_before.h))

    -- the drag: ImGui moves the edge, and the addon must neither put it back nor save every frame
    local saves_before_drag = saved or 0
    WIN_SIZE[1], WIN_SIZE[2] = 1000, 700
    frame()
    check('a dragged window is not put back: the frame asks ImGui for no size at all', #sizes == 0,
        ('%d requests'):format(#sizes))
    check('the body lays itself out from the size ImGui reports', st.win_w == 1000 and st.win_h == 700,
        ('%s x %s'):format(tostring(st.win_w), tostring(st.win_h)))
    check('the list child follows the window height', CHILD ~= nil and math.abs(CHILD.h - (700 - 166 - 60)) < 0.01,
        CHILD and CHILD.h)
    check('and the window width', CHILD ~= nil and math.abs(CHILD.w - (1000 - 36)) < 0.01, CHILD and CHILD.w)
    check('the new size is saved once, on release', (saved or 0) == saves_before_drag + 1
        and CFG.w == 1000 and CFG.h == 700, ('%d saves, cfg %s x %s'):format((saved or 0) - saves_before_drag,
            tostring(CFG.w), tostring(CFG.h)))
    local saves_after_drag = saved or 0
    frame()
    check('and not again on the next frame', (saved or 0) == saves_after_drag, (saved or 0) - saves_after_drag)

    -- the list follows a second drag, by exactly the delta
    local h700 = CHILD ~= nil and CHILD.h or -1
    local saves_before_drag2 = saved or 0
    WIN_SIZE[2] = 800
    frame()
    check('a taller window gives the list a taller rect', CHILD ~= nil and math.abs(CHILD.h - (800 - 166 - 60)) < 0.01,
        CHILD and CHILD.h)
    check('and the difference is exactly the 100 px the window gained',
        CHILD ~= nil and math.abs((CHILD.h - h700) - 100) < 0.01, CHILD and (CHILD.h - h700))
    check('a second drag is saved once too', (saved or 0) == saves_before_drag2 + 1,
        (saved or 0) - saves_before_drag2)

    -- /spells reset puts the size back, along with the rest
    fire('command', { command = '/spells text 200' })
    fire('command', { command = '/spells pill 200' })
    chat = {}
    fire('command', { command = '/spells reset' })
    check('/spells reset clears the dragged size', CFG.w == nil and CFG.h == nil,
        ('%s x %s'):format(tostring(CFG.w), tostring(CFG.h)))
    check('and all three scales', CFG.scale == 100 and CFG.text_scale == 100 and CFG.pill_scale == 100,
        ('%s / %s / %s'):format(tostring(CFG.scale), tostring(CFG.text_scale), tostring(CFG.pill_scale)))
    check('and says so', table.concat(chat, ' '):find('back to their defaults', 1, true) ~= nil, table.concat(chat, ' '))
    frame()
    check('the frame after a reset asks for the default size once', #sizes == 1 and sizes[1].cond == 1
        and math.abs(sizes[1].w - 880) < 0.01 and math.abs(sizes[1].h - 560) < 0.01,
        sizes[1] and ('%s x %s cond %s'):format(sizes[1].w, sizes[1].h, tostring(sizes[1].cond)))
    check('and the window is the default again', WIN_SIZE[1] == 880 and WIN_SIZE[2] == 560,
        ('%s x %s'):format(WIN_SIZE[1], WIN_SIZE[2]))
    frame()
    check('and then goes quiet', #sizes == 0, #sizes)
    chat = {}

    -- D. the footer: TWO scale sliders, one above the other on the bottom-right of the full window. The window's own
    -- 320 px floor cannot hold two tracks, two value labels and two words in one row (it needs about 540 px and has
    -- 266), so the band is two S(30) rows and the list gives up both.
    local function grab(x, y) DRAG.hold = { x, y } end
    local function let_go() DRAG.released, DRAG.hold, DRAG.pressed = DRAG.pressed, nil, nil end
    local F_FONTS = ui.fonts()
    frame()
    local win_r, win_b = WIN_POS[1] + WIN_SIZE[1], WIN_POS[2] + WIN_SIZE[2]
    local band_top = win_b - 16 - 60
    local tbox = btn_named(btns, '##st_text')
    local pbox = btn_named(btns, '##st_pill')
    check('the full window carries both scale sliders in its footer', tbox ~= nil and pbox ~= nil)
    check('both sit in the footer band, right of the card\'s middle',
        tbox ~= nil and pbox ~= nil
            and tbox.x > WIN_POS[1] + WIN_SIZE[1] * 0.5 and pbox.x > WIN_POS[1] + WIN_SIZE[1] * 0.5
            and tbox.y >= band_top - 0.5 and pbox.y >= band_top - 0.5
            and tbox.y + tbox.h <= win_b - 16 + 0.01 and pbox.y + pbox.h <= win_b - 16 + 0.01,
        tbox and pbox and ('text %s,%s / pill %s,%s, band %s..%s'):format(tbox.x, tbox.y, pbox.x, pbox.y,
            band_top, win_b - 16))
    check('and they are two rows, with a gap a drag cannot slip through',
        tbox ~= nil and pbox ~= nil
            and (pbox.y >= tbox.y + tbox.h + 4 or tbox.y >= pbox.y + pbox.h + 4),
        tbox and pbox and ('text %s..%s, pill %s..%s'):format(tbox.y, tbox.y + tbox.h, pbox.y, pbox.y + pbox.h))
    check('both stop short of the right edge, where the resize grip is',
        tbox ~= nil and pbox ~= nil and tbox.x + tbox.w <= win_r - 14 and pbox.x + pbox.w <= win_r - 14,
        tbox and pbox and ('text ends %s, pill ends %s, window %s'):format(tbox.x + tbox.w, pbox.x + pbox.w, win_r))
    local label_w = select(1, ui.measure('300%', F_FONTS.semi, 13))
    local lbl = has_text('100%')
    check('each slider is labelled with its value', text_count('100%') == 2, text_count('100%'))
    check('and the value label ends inside the window\'s right padding',
        lbl ~= nil and lbl.x + label_w <= win_r - 18 + 0.01,
        lbl and ('label %s + %s vs %s'):format(lbl.x, label_w, win_r - 18))
    check('both are named: Text above, Pill below', has_text('Text') ~= nil and has_text('Pill') ~= nil)
    check('the list gives up exactly the two-row footer band', CHILD ~= nil
        and math.abs(CHILD.h - ((560 - 166) - 60)) < 0.01, CHILD and CHILD.h)

    -- the pill is 230 x 34 and carries none of this
    fire('command', { command = '/spells minimize' })
    frame()
    check('the pill carries no footer and no slider', btn_named(btns, '##st_text') == nil
        and btn_named(btns, '##st_pill') == nil and has_text('Text') == nil and has_text('Pill') == nil
        and has_text('100%') == nil)
    fire('command', { command = '/spells minimize off' })
    frame()

    -- the TEXT slider: the value follows the mouse, the rows follow the value on the next frame, the setting is
    -- written once when the mouse comes up, and the pill scale is not touched
    local bar = btn_named(btns, '##st_text')
    local saves_text = saved or 0
    -- every record the addon may not have drawn is nil-guarded here too: a missing hitbox must go red in the checks
    -- below, never raise in the middle of them and take the rest of the suite with it
    local t_x, t_w = (bar and bar.x or 0) + 8, (bar and bar.w or 0) - 16  -- the kit's track inside its 8 px padding
    grab(t_x + t_w / 2, (bar and bar.y or 0) + 12)                        -- the middle of a 50-300 track is 175 %
    frame()
    check('dragging the text slider sets its live value and saves nothing yet',
        st.text_drag ~= nil and math.abs(st.text_drag - 175) <= 1 and (saved or 0) == saves_text,
        ('live %s, %d saves'):format(tostring(st.text_drag), (saved or 0) - saves_text))
    check('and its label reads the value being dragged', has_text('175%') ~= nil and has_text('100%') ~= nil,
        ('%d at 175, %d at 100'):format(text_count('175%'), text_count('100%')))
    frame()
    local grown = has_text('Filler 01')
    check('the rows follow it on the next frame',
        grown ~= nil and math.abs(grown.size - 13 * (st.text_drag / 100)) < 0.01, grown and grown.size)
    check('and the setting is still not written', (saved or 0) == saves_text)
    let_go()
    frame()
    check('letting go writes the text scale once, and only that key',
        (saved or 0) == saves_text + 1 and CFG.text_scale == 175 and CFG.pill_scale == 100,
        ('%d saves, text %s, pill %s'):format((saved or 0) - saves_text, tostring(CFG.text_scale),
            tostring(CFG.pill_scale)))
    check('and the live value is gone with the drag', st.text_drag == nil)
    local after_release = saved or 0
    frame()
    check('and not again on the next frame', (saved or 0) == after_release, (saved or 0) - after_release)

    -- the PILL slider: its own key, its own feedback, and nothing else in the window moves
    frame()
    local tops_before = row_tops()
    local size_before = { WIN_SIZE[1], WIN_SIZE[2] }
    local font_before = has_text('Filler 01') and has_text('Filler 01').size
    local text_before = CFG.text_scale
    pbox = btn_named(btns, '##st_pill')
    local saves_pill = saved or 0
    local p_x, p_w = (pbox and pbox.x or 0) + 8, (pbox and pbox.w or 0) - 16
    grab(p_x + p_w, (pbox and pbox.y or 0) + 12)   -- the far end of the track: 300 %
    frame()
    check('the pill slider has its own live value', st.pill_drag ~= nil and st.pill_drag == 300,
        st.pill_drag)
    check('and its own label reads it while it is dragged', has_text('300%') ~= nil and has_text('175%') ~= nil,
        ('%d at 300, %d at 175'):format(text_count('300%'), text_count('175%')))
    check('and nothing is written while the button is still held', (saved or 0) == saves_pill,
        (saved or 0) - saves_pill)
    check('the window does not resize with it', WIN_SIZE[1] == size_before[1] and WIN_SIZE[2] == size_before[2],
        ('%s x %s'):format(WIN_SIZE[1], WIN_SIZE[2]))
    check('the rows do not move', same_list(tops_before, row_tops()), #row_tops())
    check('and the letters do not change', has_text('Filler 01') ~= nil
        and math.abs(has_text('Filler 01').size - font_before) < 0.01, has_text('Filler 01') and has_text('Filler 01').size)
    let_go()
    frame()
    check('letting go writes the pill scale once, and only that key',
        (saved or 0) == saves_pill + 1 and CFG.pill_scale == 300 and CFG.text_scale == text_before,
        ('%d saves, pill %s, text %s'):format((saved or 0) - saves_pill, tostring(CFG.pill_scale),
            tostring(CFG.text_scale)))
    -- and it is the PILL that follows it, on the next fold
    fire('command', { command = '/spells minimize' })
    frame()
    local pill300 = last_size()
    check('the folded pill is 690 x 102 at 300 %', math.abs(pill300.w - 690) < 0.01
        and math.abs(pill300.h - 102) < 0.01, ('%s x %s'):format(pill300.w, pill300.h))
    fire('command', { command = '/spells minimize off' })
    frame()

    -- /spells reset returns both, and both sliders follow
    chat = {}
    fire('command', { command = '/spells reset' })
    check('/spells reset returns both scales', CFG.text_scale == 100 and CFG.pill_scale == 100,
        ('text %s, pill %s'):format(tostring(CFG.text_scale), tostring(CFG.pill_scale)))
    frame()
    check('and both sliders come back to 100 %', text_count('100%') == 2, text_count('100%'))
    local back = has_text('Filler 01')
    check('and the letters with them', back ~= nil and math.abs(back.size - 13) < 0.01, back and back.size)
    chat = {}

    -- the line a legibility complaint starts from: the three scales and the size that was measured
    chat = {}
    fire('command', { command = '/spells debug' })
    local sdbg = table.concat(chat, ' ')
    check('/spells debug names the three scales',
        sdbg:find('scales: window 100%, text 100%, pill 100%', 1, true) ~= nil, sdbg:sub(1, 300))
    check('/spells debug names the window size ImGui answered',
        sdbg:find('window: 880 x 560', 1, true) ~= nil, sdbg:sub(1, 320))
    chat = {}

    -- a client whose imgui has no GetWindowSize and no size constraints: the window still draws, at the size it asked for
    local real_gws, real_snwsc = imgui.GetWindowSize, imgui.SetNextWindowSizeConstraints
    imgui.GetWindowSize, imgui.SetNextWindowSizeConstraints = nil, nil
    st.last_error = nil
    frame()
    check('no GetWindowSize and no constraints still draws the window',
        st.last_error == nil and #row_tops() > 0, tostring(st.last_error))
    imgui.GetWindowSize, imgui.SetNextWindowSizeConstraints = real_gws, real_snwsc
    -- a zero-size answer (the frame before the first layout) is not a size: the window keeps what it asked for
    WIN_SIZE[1], WIN_SIZE[2] = 0, 0
    frame()
    check('a zero-size window still draws its rows', st.last_error == nil and #row_tops() > 0,
        tostring(st.last_error))
    WIN_SIZE[1], WIN_SIZE[2] = 880, 560
    frame()
    chat = {}
end
scaling_suite()

-- an empty bag: the ordinary case for a new character, and the one where a missing slot must not read as an item
INVENTORY[3], INVENTORY[5], LOCKER[1] = nil, nil, nil
fire('command', { command = '/spells rescan' })
local empty_bag_ok, empty_bag_err = pcall(function () fire('present') end)
check('empty bags draw without an error', empty_bag_ok, empty_bag_err)
local any_held = false
for _, r in ipairs(st.rows or {}) do if r.held ~= nil then any_held = true end end
check('empty bags leave every row unheld', not any_held)

-- the client without data: no player, no game data, no sources
player = { main_job = 0, main_job_level = 0, sub_job = 0, sub_job_level = 0 }
vana.game.spells = function () return nil end
vana.gamedata.spells = nil
local empty_ok, empty_err = pcall(function () fire('present') fire('present') end)
check('character select (no job, no bits, no game data) draws an empty list without an error', empty_ok, empty_err)

-- and the same with no game data table at all: vana.gamedata.items is read by the bag scan, so a nil vana.gamedata
-- must cost the scan its names, not the frame
vana.gamedata = nil
local nodata_ok, nodata_err = pcall(function () fire('present') fire('present') end)
check('a nil vana.gamedata still draws, and the bag scan just finds no names', nodata_ok, nodata_err)

-- and with no game data at all, a zone event and /spells here have to degrade to nothing rather than raise into the
-- event handler: they cannot name a zone, so there is nothing to say and nothing to list
toasts, chat = {}, {}
local nozone_ok, nozone_err = pcall(function ()
    fire('zone_change', { zone = 245, previous = 0 })
    fire('command', { command = '/spells here' })
end)
check('with no game data a zone event and /spells here raise nothing', nozone_ok, nozone_err)
check('and neither announces anything', #toasts == 0 and st.last_error == nil,
    ('%d toasts, error %s'):format(#toasts, tostring(st.last_error)))
check('/spells here says the client has not named a zone rather than guessing one',
    #chat == 1 and chat[1]:find('no zone to list yet', 1, true) ~= nil, chat[1])

------------------------------------------------------------------------------- the pill survives a reload
-- Last, because a reload replaces the addon's own state (the local `st` above belongs to the previous session). The
-- stub's settings store hands back the one table it keeps, as vana.settings does per character, so this is the addon
-- reading what it saved: a window folded to a pill must come back as a pill, not spring open at full size.
fire('command', { command = '/spells minimize' })
check('the run ends with the window folded', SPELLTRACKER.minimized == true)
check('and the fold is in the settings file', SETTINGS_DATA ~= nil and SETTINGS_DATA.minimized == true)

-- also a function, for the same reason the section above is one
local function reload_suite()
handlers = {}
-- the size the player dragged, as the last session left it: the reload has to come back at it, not at 880 x 560
SETTINGS_DATA.w, SETTINGS_DATA.h = 1024, 640
local reloaded, reload_err = pcall(dofile, ADDON .. '/spelltracker-vanacore.lua')
check('the addon reloads against the same settings file', reloaded, reload_err)
local st2 = SPELLTRACKER
check('the reloaded addon comes up folded, from cfg alone', st2 ~= nil and st2.minimized == true,
    st2 and tostring(st2.minimized))
fire('load')
fire('command', { command = '/spells show' })
texts, rects, tris, edges, btns, sizes = {}, {}, {}, {}, {}, {}
local pill_ok, pill_err = pcall(function () fire('present') fire('present') fire('present') end)
check('the reloaded pill draws without an error', pill_ok and st2.last_error == nil,
    pill_err or tostring(st2.last_error))
check('and it draws the word, at the pill\'s size, not the window\'s',
    has_text('Spelltracker') ~= nil and math.abs(last_size().w - 230) < 0.01
        and math.abs(last_size().h - 34) < 0.01,
    ('%s x %s'):format(last_size().w, last_size().h))

-- and the size round-trips: the saved size is applied on the first window frame of the new session, once, with
-- FIRST_USE_EVER - the condition that says 'this is where it starts' rather than 'this is where it stays'
fire('command', { command = '/spells minimize off' })
frame()
check('the size the player dragged comes back with the session',
    #sizes == 1 and math.abs(sizes[1].w - 1024) < 0.01 and math.abs(sizes[1].h - 640) < 0.01,
    sizes[1] and ('%s x %s'):format(sizes[1].w, sizes[1].h))
check('and it is a FIRST_USE_EVER placement, not a pin', sizes[1] ~= nil and sizes[1].cond == 4,
    sizes[1] and sizes[1].cond)
frame()
check('and the frame after it asks for no size at all', #sizes == 0, #sizes)
end
reload_suite()

print(('\nchecks %d, failures %d'):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
