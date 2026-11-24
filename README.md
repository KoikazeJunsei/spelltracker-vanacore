# SpellTracker for VanaCore

What your job can still learn, and where each scroll comes from.

`/spells` opens one glass card: your job and level, how many spells are still to learn, the mode's acquisition badges,
a search box, skill pills, and a scrolling list of every spell your job (or subjob) can use at this level cap. Each row
shows whether the spell is already learnt, its level, whether it comes from the main job or the subjob, its skill and
MP cost, and one badge for where a scroll comes from. Click the badge to search the CatsEyeXI item database, click the
Wiki button for BG-Wiki, or double-click the row for the database.

The window is drawn with the same `ui.lua` kit as the other VanaCore addons (Auction House, Party Finder, VanaMaps,
Clawmark, VanaStore), so it follows the theme, the window scale, the opacity and the controller.

## Commands

```
/spells                     the window on or off
/spells show                open it
/spells hide                close it
/spells reset               position, scale and opacity back to their defaults
/spells mode ace|cw|wew     which acquisition systems the badges allow
/spells theme <id>          one of the kit's themes; no id lists them
/spells scale <50-300>      the window's size in percent
/spells learned on|off      show the spells already learnt, too
/spells now on|off          only the spells you could cast at your level right now
/spells held on|off         only the spells whose scroll is already in one of your bags
/spells rescan              read your bags again now (they are re-read every 4 seconds anyway)
/spells sound on|off        the bell as the window opens
/spells debug               the row counts, the bags it read, and the last error, in chat
```

An unknown argument prints the same list in one chat line.

## The three modes

CatsEyeXI runs three rulesets for learning spells, and the mode only changes which acquisition badges a spell may
show; it never changes a level or a spell's existence.

- **ACE - Accelerated CatsEye.** Every CatsEye system: Wizardoll learns spells for Sparks of Eminence, plus the
  Auction House, Ventures and Summit of the Stars.
  Source: `bg-wiki CatsEyeXI_Content/Accelerated`.
- **CW - Crystal Warrior.** Self-found: no Auction House and no Wizardoll; vendors, drops, quests and battlefields
  only. Source: `bg-wiki CatsEyeXI_Content/Crystal_Warrior`. The Auction House and Wizardoll exclusion is an
  inference: the Wings page says only ACE and WEW share the Auction House. If a CW player reports the AH working,
  that is the row to change.
- **WEW - Wings Era Warrior.** Records of Eminence are off, so no Sparks for Wizardoll; the Auction House stays.
  Source: `bg-wiki CatsEyeXI_Content/Wings_Era_Warrior`.

A spell whose only sources the mode hides falls back to the mode's own badge (`Self-found`, or `No source`).

### What the pill means, and what the tooltip adds

The pill names the **one** source the acquisition table's own sentence cites - "Shop" over `Hasim / Lower Jeuno /
23,400 Gil`, "Drop" over `Goblin Leecher / King Ranperre's Tomb (+28)` - so the label and the note always agree. The
other paths the page recorded ride in the tooltip: the Auction House listing when the scroll has one, and, in ACE, the
Wizardoll NPC that sells scrolled spells for Sparks of Eminence. Wizardoll is a tooltip line rather than a pill on
purpose: as a pill it replaced every vendor, zone and price the table had just been read for.

## "Do I already have this scroll?"

The tracker reads every bag the client exposes and marks a spell whose scroll or plate is sitting in one of them: a bag
icon with the count, a tooltip naming the bag, and a `N scrolls already in your bags` line in the header. `Usable now`
and `In storage` are independent filters, so "castable and already bought" is two clicks.

The bags are the eighteen the client has - Inventory, Mog Safe, Storage, Temporary, Mog Locker, Satchel, Sack, Case,
Mog Wardrobe 1 to 8, Mog Safe 2, Recycle Bin (`docs/addons/04-game-data.md`). Bags are re-read every four seconds and on
`/spells rescan`.

**The ephemeral box and Gramateus are a different question, and a bag scan cannot answer them.** They are not
containers the client holds: VanaCore's own `Container` enum ends at 17 and every id above it is refused, which is why
CatsEyeXI's Trove addon reads its ephemeral-box counts straight out of the synthesis packet (`trove/core/crafting.lua`)
instead of from a bag. Scrolls are also not in the box - once `Decrypting Antiquity II` is done they are auto-transferred
to **Gramateus in Upper Jeuno**, where you can see them but not take them back.

The server will answer that question per scroll: `!scroll <name>` reports whether it is stored in the box or at
Gramateus. A following increment drives that command from the window (a per-row query and an explicit, spaced-out bulk
sync parsed against the server's own reply lines). Until it lands, this window's storage check is the bags only, and it
says so rather than implying it looked at the box.

## Where the data comes from

- **Levels:** `vana.gamedata.spells`, VanaCore's table generated from CatsEyeXI's own `sql/spell_list.sql`. The three
  rows where CatsEyeXI differs from LandSandBoat's table are shipped with their citation in `spells_data.lua`
  (`Cure IV` PLD 51, `Indi-Int` GEO 34, `Geo-Haste` GEO 93). No level is scaled or invented: a spell a job only
  reaches above the level cap is shown at its real level and marked out of reach.
- **Learnt or not:** `vana.game.spells()`, the game's own 128-byte bitfield. Nothing asks the server and nothing is
  remembered locally, so the list matches the spell menu.
- **Scroll sources:** `spell_sources.lua`, generated from BG-Wiki's acquisition tables by
  `tools/make_spell_sources.py` - 585 spells with a source, 428 of them read off a scroll page's `Purchased From` /
  `Dropped from` / `Obtained From` tables and 157 blue spells tagged by the rule that blue magic is learnt in battle
  (a spell with no scroll item page is read off its own spell page: `Scroll of Firestorm` does not exist, `Firestorm`
  does). `Diaga II` has no page at all and keeps the neutral badge.
  (`python tools/make_spell_sources.py <vanacore>/addons/vanacore/libs/gamedata` regenerates it; the pages are cached,
  and the wiki rate-limits a fast reader, so the generator paces itself and retries). A spell whose page could not be read gets a neutral `No source` badge whose tooltip
  says no acquisition source is recorded. It is visibly unknown, never guessed: there is no fabricated vendor note in
  this addon.
- **Links:** the database button opens `https://catseyexi.com/database?q=<scroll name>`, the site's own search route;
  the Wiki button opens `https://www.bg-wiki.com/ffxi/<Spell_Name>`. Geomancy spells search for `Plate of <name>`,
  every other spell for `Scroll of <name>`. Where VanaCore cannot open a browser the link is copied to the clipboard
  and a toast says so.

## Install

Copy the `spelltracker-vanacore` folder into `Vanacore\addons\vanacore\`, then:

```
/addon load spelltracker-vanacore
/spells
```

Settings are per character, in
`settings\addons\spelltracker-vanacore\<Character>\settings.json` (theme, scale, mode, learned filter, skill filter,
window position, opacity, opening sound).

## Files

| File | What |
|---|---|
| `spelltracker-vanacore.lua` | the window, the events, the commands and the settings |
| `spells_core.lua` | pure logic: rows, counts, badges, URLs (no `vana`, testable headlessly) |
| `spells_data.lua` | the three modes, the badge definitions, the skill pills and the cited level overrides |
| `spell_sources.lua` | the generated per-spell acquisition table |
| `ui.lua` | the family's drawing kit (unmodified) |
| `pad.lua` | controller support shared by the family (unmodified) |
| `fonts/`, `sounds/small_bell.wav`, `images/jobs.png` | the kit's faces, the bell and the job icons |

`spells_core.lua` and `spell_sources.lua` are required softly: a copy missing one still loads and opens an empty list
(rather than failing at load), and `/spells debug` says which module is missing.

## Controller

With a gamepad enabled in `vanacore.ini` (`[addons] gamepad = 1`), the D-pad moves the focus, Confirm presses the
focused control (a mode, a skill pill, the learnt toggle, a row's badge or Wiki button), and Cancel leaves a text box.
The wheel and the list still answer the mouse.
