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
  /spells sound on|off     the bell as the window opens
  /spells debug            the row counts and the last error, in chat

Click a spell's badge to search the CatsEyeXI database, its Wiki button for BG-Wiki, or double-click the row for the
database. The window is drawn with the family's ui.lua kit, so it looks like the other VanaCore addons and follows the
theme, the scale and the controller.
--]]

addon.name    = 'spelltracker-vanacore'
addon.author  = 'Carver'
addon.version = '0.1.0'
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

-------------------------------------------------------------------------------
-- Settings and state
-------------------------------------------------------------------------------

local DEFAULTS = {
    theme = 'aurora', scale = 100, mode = 'ace', show_learned = false, skill = 'all',
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
    rows = {}, counts = { total = 0, learned = 0, missing = 0, unreachable = 0 },
    cache_key = nil, spells = nil,
    last_error = nil, focus_frames = 0,
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
-- The rows
-------------------------------------------------------------------------------

-- rebuilding is keyed on everything that can change a row: the character's jobs, the bitfield, the filters. Typing in
-- the search box thus costs one rebuild per keystroke, not one per frame.
local function rebuild(me, bits)
    local key = table.concat({
        me.job, me.level, me.sub_job, me.sub_level,
        tostring(cfg.mode), tostring(cfg.show_learned), tostring(cfg.skill), st.query[1] or '', bits or '',
    }, '|')
    if key == st.cache_key then return end
    st.cache_key = key
    st.rows = {}
    st.counts = { total = 0, learned = 0, missing = 0, unreachable = 0 }

    local spells = spell_table()
    if spells ~= nil then spells = spell_array(spells) end
    if CORE == nil or type(CORE.rows) ~= 'function' or spells == nil or me.job <= 0 then return end
    local data = DATA or { modes = {}, tags = {}, skills = {}, skip_types = {}, level_cap = 75 }
    -- spells_core reads sources by spell id, so it wants the generated map, not the module around it
    local sources = (SOURCES and type(SOURCES.spells) == 'table') and SOURCES.spells or {}
    local cap = tonumber(data.level_cap) or 75

    -- the counts are the whole job's list, not the filtered view: '12 to learn' should not fall when a search narrows
    local ok_all, all = pcall(CORE.rows, spells, {
        job = me.job, level = me.level, sub_job = me.sub_job, sub_level = me.sub_level,
        bits = bits, show_learned = true, mode = cfg.mode, data = data, sources = sources, cap = cap,
    })
    if ok_all and type(all) == 'table' then
        local ok_c, counts = pcall(CORE.counts, all)
        if ok_c and type(counts) == 'table' then st.counts = counts end
    elseif not ok_all then
        fail('rows', all)
    end

    local skill = nil
    if cfg.skill ~= nil and cfg.skill ~= 'all' then skill = cfg.skill end
    local ok_rows, rows = pcall(CORE.rows, spells, {
        job = me.job, level = me.level, sub_job = me.sub_job, sub_level = me.sub_level,
        bits = bits, query = st.query[1] ~= '' and st.query[1] or nil, skill = skill,
        mode = cfg.mode, show_learned = cfg.show_learned == true, data = data, sources = sources, cap = cap,
    })
    if ok_rows and type(rows) == 'table' then
        st.rows = rows
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
-- What the window does
-------------------------------------------------------------------------------

local function set_open(on)
    on = on == true
    if on == st.open then return end
    st.open = on
    if on then
        st.focus_frames = 2
        if cfg.open_sound ~= false then play_bell() end
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
    local pillx = wx - S(8) - pillw
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
    local w = math.max(S(320), math.floor(S(700)))
    local h = math.max(S(260), math.floor(S(560)))
    w = math.min(w, sw - S(20))
    h = math.min(h, sh - S(20))

    if st.recenter then
        -- /spells reset asks for the centre now, which ImGuiCond_FirstUseEver alone would not do in this session
        imgui.SetNextWindowPos({ math.floor((sw - w) / 2), math.floor((sh - h) / 2) }, U.ALWAYS)
        st.recenter = nil
    elseif cfg.x ~= nil and cfg.y ~= nil then
        imgui.SetNextWindowPos({ math.floor(cfg.x), math.floor(cfg.y) }, U.ALWAYS)
    else
        -- the first use of a session, with no saved place yet: centred
        imgui.SetNextWindowPos({ math.floor((sw - w) / 2), math.floor((sh - h) / 2) }, U.FIRST_USE_EVER)
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
            if U.icon_button(dl, '##st_close', x + w - S(42), y + S(14), S(26), 'xmark', P.dim, 'Close') then
                set_open(false)
            end
            dl:AddLine({ x + S(18), y + S(66) }, { x + w - S(18), y + S(66) }, U.u32(P.line, 0.9), 1)

            -- controls: the mode, the learnt toggle, the search
            local cy = y + S(86)
            local mode_opts = {}
            for _, md in ipairs(modes()) do mode_opts[#mode_opts + 1] = { md.id, md.label or md.id } end
            local _, mw, clicked = U.segments(dl, '##st_mode', x + S(18), cy - S(13), S(26), mode_opts, cfg.mode,
                function (o) return pill_colour(MODE_COLOR, o[1], 'accent') end)
            if clicked then set_mode(clicked) end

            local shown, pressed = U.toggle(dl, '##st_learned', x + S(18) + mw + S(22), cy, 'Show learnt', cfg.show_learned == true)
            if pressed then set_learned(shown) end

            local escaped, search_focused = draw_search(dl, x + w - S(18) - S(210), cy, S(210))

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
    rebuild(me, game_bits())
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

local HELP = '/spells [toggle|show|hide|reset|mode ace|cw|wew|theme <id>|scale <50-300>|learned on|off|sound on|off|debug]'

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
        -- measured now, not whenever the window last drew: the command works with the window shut
        st.cache_key = nil
        rebuild(current_player(), game_bits())
        local c = st.counts or {}
        say(string.format('%d shown, %d in the job, %d learnt, %d to learn, %d out of reach at %d',
            #(st.rows or {}), tonumber(c.total) or 0, tonumber(c.learned) or 0, tonumber(c.missing) or 0,
            tonumber(c.unreachable) or 0, tonumber(DATA and DATA.level_cap) or 75))
        say('last error: ' .. tostring(st.last_error or 'none'))
        if CORE == nil then say('spells_core.lua is missing: no rows can be built') end
    else
        say(HELP)
    end
    return true
end)

SPELLTRACKER = st -- (this addon's own state: for a test's eyes, through VanaCore's MCP)
