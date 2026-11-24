-- What the tracker knows that the game's own tables do not: the three mode policies, the acquisition badges and their
-- icons, the skill filter pills, and the handful of numbers where CatsEyeXI's spell table differs from retail's.
--
-- Everything here is cited. A claim without a `src` is a bug, not a shortcut: this file is where an addon usually starts
-- inventing vendor notes, and the point of the citations is that it does not. Nothing in this file is a per-spell guess
-- either: where each scroll comes from lives in spell_sources.lua, generated from BG-Wiki's own acquisition tables by
-- tools/make_spell_sources.py.
local M = {}

-- Three rows where CatsEyeXI's sql/spell_list.sql differs from LandSandBoat's, read by diffing the two tables. Kept
-- here as well as in the game data because they are the only places the server's own numbers were hand-changed: a
-- tracker that shows retail's level for Cure IV on PLD is wrong by four levels.
M.level_overrides = {
    { spell = 'Cure IV', job = 'PLD', catsEyeXI = 51, retail = 55 },
    { spell = 'Indi-Int', job = 'GEO', catsEyeXI = 34, retail = 36 },
    { spell = 'Geo-Haste', job = 'GEO', catsEyeXI = 93, retail = 97 },
}
M.level_overrides_src = 'catseyexi@stable sql/spell_list.sql vs LandSandBoat/server@base (3 differing rows of 926)'

-- The three modes, as CatsEyeXI describes them. `tags` is what the mode can offer, `hide` is what it takes away, and
-- `fallback` is the badge a spell gets when everything it has is hidden (a CW spell with only an AH source is still
-- self-found: through a vendor, a drop or a battlefield).
M.modes = {
    {
        id = 'ace', label = 'ACE', name = 'Accelerated CatsEye',
        blurb = 'Every CatsEye system: Wizardoll learns spells for Sparks, plus the Auction House, Ventures and Summit.',
        tags = { 'wizardoll', 'shop', 'ah', 'drop', 'quest', 'bcnm' },
        hide = {},
        fallback = 'unknown',
        src = 'bg-wiki CatsEyeXI_Content/Accelerated (Wizardoll NPC: ACE players learn spells using Sparks of Eminence)',
    },
    {
        id = 'cw', label = 'CW', name = 'Crystal Warrior',
        blurb = 'Self-found: no Auction House and no Wizardoll. Vendors, drops, quests and battlefields only.',
        tags = { 'shop', 'drop', 'quest', 'bcnm' },
        hide = { 'wizardoll', 'ah' },
        fallback = 'self',
        -- the AH half is an INFERENCE, and says so: the only public statement about it is the Wings page's "unlike the
        -- Crystal Warrior game mode, [WEW] ... may trade with ACE and use the same Auction House", which implies CW is
        -- outside that arrangement. The CW page itself never mentions the Auction House. If a CW player reports the AH
        -- working, this row is what to change.
        src = 'bg-wiki CatsEyeXI_Content/Crystal_Warrior (own capped progression); AH/Wizardoll exclusion inferred from CatsEyeXI_Content/Wings_Era_Warrior, which says only ACE and WEW share the AH',
    },
    {
        id = 'wew', label = 'WEW', name = 'Wings Era Warrior',
        blurb = 'Era character: Records of Eminence are off, so no Sparks for Wizardoll. The Auction House stays.',
        tags = { 'shop', 'ah', 'drop', 'quest', 'bcnm' },
        hide = { 'wizardoll' },
        fallback = 'unknown',
        src = 'bg-wiki CatsEyeXI_Content/Wings_Era_Warrior (Records of Eminence disabled; same Auction House as ACE)',
    },
}

-- The badges, in the order a player can usually act on them. `icon` is a name in ui.lua's FA table (the check in
-- tests/spelltracker verifies that every one of these exists there: a missing glyph draws a question mark instead).
M.tags = {
    wizardoll = { label = 'Wizardoll', icon = 'hat-wizard', color = '#FFD166',
                  note = 'ACE: learnt from the Wizardoll NPC for Sparks of Eminence' },
    shop      = { label = 'Shop',      icon = 'store',      color = '#7FC97F',
                  note = 'sold by an NPC vendor' },
    ah        = { label = 'AH',        icon = 'coins',      color = '#F0C96A',
                  note = 'listed on the Auction House (Scrolls)' },
    drop      = { label = 'Drop',      icon = 'box-open',   color = '#6FA7FF',
                  note = 'dropped by a monster' },
    quest     = { label = 'Quest',     icon = 'scroll',     color = '#D9A6FF',
                  note = 'a quest or mission reward' },
    bcnm      = { label = 'BCNM',      icon = 'dice',       color = '#FF8A5B',
                  note = 'a battlefield reward (BCNM, ENM or an instance)' },
    sots      = { label = 'Summit',    icon = 'star',       color = '#FFE08A',
                  note = 'Summit of the Stars reward' },
    self      = { label = 'Self-found', icon = 'compass',   color = '#5CC8B0',
                  note = 'no AH or Wizardoll path in this mode: vendor, drop or battlefield' },
    learn     = { label = 'Learn',     icon = 'flask',      color = '#5BB7FF',
                  note = 'blue magic is learnt by fighting the monster that casts it' },
    none      = { label = 'Not at 75', icon = 'ban',        color = '#FF6B6B',
                  note = 'no job learns this at the level 75 cap' },
    unknown   = { label = 'No source', icon = 'question',   color = '#8F97AD',
                  note = 'no acquisition source is recorded for this spell' },
}

-- The skill pills, and the spell `type` each one selects in vana.gamedata.spells.
M.skills = {
    { id = 'white',     label = 'White',     types = { 'white' } },
    { id = 'black',     label = 'Black',     types = { 'black' } },
    { id = 'song',      label = 'Song',      types = { 'song' } },
    { id = 'ninjutsu',  label = 'Ninjutsu',  types = { 'ninjutsu' } },
    { id = 'summoning', label = 'Summoning', types = { 'summoning' } },
    { id = 'blue',      label = 'Blue',      types = { 'blue' } },
    { id = 'geomancy',  label = 'Geomancy',  types = { 'geomancy' } },
}

-- Spell types the tracker ignores outright: a trust is not a spell the player learns.
M.skip_types = { trust = true }

-- The level cap this server runs (see the modes above). A spell no job reaches by this level cannot be learnt at all,
-- which is the honest version of "the post-75 spells are scaled down": they are not, they are out of reach.
M.level_cap = 75

return M
