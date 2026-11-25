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
/spells dice                the Dice view: the 31 corsair dice, the roll each one teaches, and where it is sold
/spells dice off            back to the spell list
/spells dice known          in the Dice view, also list the rolls you already know
/spells dice now            in the Dice view, only the dice your COR level can use
/spells here                what this job still needs in the zone you are standing in, with where to get each one
/spells alerts on|off       the zone-in notice on or off (one toast and one chat line, never twice for one zone)
/spells alerts shop|drop|bcnm on|off   silence one of the three kinds of place
/spells rescan              read your bags again now (they are re-read every 4 seconds anyway)
/spells sync                ask the server for the scroll ledger again (Gramateus / the box)
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

Two different questions, answered two different ways, and a row can wear both marks at once.

**In a bag: read.** The tracker walks all eighteen containers the client has - Inventory, Mog Safe, Storage,
Temporary items, Mog Locker, Satchel, Sack, Case, Mog Wardrobe 1 to 8, Mog Safe 2, Recycle Bin
(`docs/addons/04-game-data.md`) - and marks a spell whose scroll or plate is in one of them. Green bag icon, the
count when there is more than one, a tooltip naming the bag. Bags are re-read every four seconds and on
`/spells rescan`.

**Stored at Gramateus or in the box: asked.** Those are not containers the client holds - VanaCore's `Container` enum
ends at 17 - so this is a question for the server, and it is asked **once for the whole store**, not once per scroll.
The addon sends CatsEyeXI's `0x1A4` tab-summary request (source 2, the scroll ledger: the same protocol Trove uses) and
the answer is a bitmask per page: 19 uint32s, 512 scrolls, one bit each. A stored row gets a cyan vault icon with the
tooltip `stored (Gramateus / the box)` - no count, because the ledger carries none.

The page table that says which bit is which spell, `scroll_ledger.lua`, is Trove's generated file copied byte-identical
(its own header: *"Order MUST match the server's page layout"*), so a resync cannot mark the wrong spells. The request
goes out when the window opens and on `/spells sync`, at most once a minute. The answer is Crystal Warrior only: a
non-CW character is told so once and the addon stops asking.

`Usable now`, `In storage` and `Show learnt` are independent filters, so "castable, already bought, not learnt" is
three clicks.

## Corsair dice

Corsair rolls are **not** learnt with level. Each roll is taught by a die item, bought or found - the client's own
item table says so outright (`items_1.lua`, item 5477: `COR Lv.49`, *Teaches the Phantom Roll ability*, *Warrior's
Roll*). The Dice view lists all **31** of them, by the level that lets you use them, with the vendor and the price:
13 at Chayaya in Al Zahbi, 18 at Jajaroon and Chichiroon in Nashmau.

Two things are read, and they are different reads:

- **Do you know the roll?** The ability the die teaches, from `vana.game.abilities()` - job abilities start at bit
  `0x200`, so ability `n` is bit `0x200 + n` (`docs/addons/04-game-data.md:489`). A missing bitfield means *unknown*,
  drawn as a question mark, never as "you don't have it".
- **Do you own the die?** The bag scan, by item id, exactly as a scroll is marked.

Three honesty notes, since the whole point is that nothing here is invented:

- Every one of the 31 dice is a **vendor** sale in the tables as read; the badge set has drop, battlefield and quest
  kinds for dice too, but no die page named one, so those paths are drawn only when data appears.
- **Samurai Die is the one disagreement in the client's own data**: the item prints `COR Lv.37`, the ability table says
  Samurai Roll is level 34. The row shows 37, because that is what the game tells a player who examines the die.
- Dice alerts obey the shop switch and are skipped when the ability bitfield is missing - silence rather than telling a
  player they lack a roll they may already know.

## Install

**As a package (recommended).** `spelltracker-vanacore-<version>.vcaddon` from the [releases page](https://github.com/KoikazeJunsei/cexi-addons/releases)
installs itself: double-click it, drop it in `Vanacore\addons\install\`, or use `/vana` > Addons > **Install from file**.
VanaCore shows what is in it and where it came from before writing anything, installs it to
`addons\vanacore\spelltracker-vanacore\`, moves any previous copy to `backups\addons\`, and offers to load it at every
start. A web page can hand it over in one click:
`vanacore://install/https://github.com/KoikazeJunsei/cexi-addons/releases/download/v0.1.0/spelltracker-vanacore-0.1.0.vcaddon`

**By hand.** Copy this folder to `Vanacore\addons\vanacore\` and `/addon load spelltracker-vanacore`. Note that a
hand-copied folder is never updated by a package later (the package installer refuses a folder that carries no
`.vcaddon.json`), so prefer the package if you want updates.

**Building the package** (from a VanaCore checkout): `python3 tools/vcaddon/pack.py <this folder> -o <out dir>`.
The same files always produce the same bytes, so a rebuild of an unchanged addon is a no-op.

## Policy position (CatsEyeXI addon tiers)

CatsEyeXI classifies by what an addon *achieves in gameplay*, not how it works inside (`catseyexi.com/addon-policy`).
By that measure this is **T2, Information Display**, and the precedent is on the approved list: **trove is approved
T2** and sends the same `0x1A4` tab-summary request to the same server module for the same purpose - showing the
player what is in their storage.

What it does, exhaustively:

* **reads** - job and level (`vana.game.self`), the spell bitfield (`vana.game.spells`), item ids in the eighteen
  containers (`vana.game.container`), the shipped spell and item tables (`vana.gamedata`).
* **sends exactly one kind of packet** - the ledger summary (`vana.packets.inject(false, 0x1A4, ...)`, action 13,
  source 2), when the window opens or on `/spells sync`, never more than once a minute. It is a query: no withdraw
  (action 2), no deposit, no trade, no item movement.
* **opens a browser** on a badge or Wiki click, with `vana.system.open_url`, on the player's click.

What it does not do, checked by grep over its own files: no `vana.chat.run`, `vana.command`, `QueueCommand`, no `/ma`
`/ja` `/ws` `/equip` `/item` string anywhere, no synthetic input, no target selection, no movement, no memory write,
no packet rewrite or blocking, no visibility or collision change, no `os.execute` / `io.popen` / `ffi.load` / socket,
no timer loop. Nothing it does can fire without the player opening the window.

The policy scanner reports `sends_packets=1 packet_handlers=1` for those two Ledger lines and leans **T1?**, because
its tree counts any packet send as "acts for the player". That is triage, not a verdict (the scanner says so in its
own docstring): the addon takes no game action, so T1 - "takes real actions for the player... gear-swap helpers,
attended healing" - does not describe it. Its `dynamic_code`/`native_code` hits are the frozen `ui.lua`/`pad.lua` kit,
and its 592 `urls` are the cited acquisition rows.

**Unlisted addons require review before use** on CatsEyeXI, so the ticket is worth opening: link this folder and the
`trove` precedent above. Nothing here is T3 (no unattended loop) or T4 (no server rule broken, no rate limit defeated,
nothing the client hides is revealed).

## Where the data comes from

- **Levels:** `vana.gamedata.spells`, VanaCore's table generated from CatsEyeXI's own `sql/spell_list.sql`. The three
  rows where CatsEyeXI differs from LandSandBoat's table are shipped with their citation in `spells_data.lua`
  (`Cure IV` PLD 51, `Indi-Int` GEO 34, `Geo-Haste` GEO 93). No level is scaled or invented: a spell a job only
  reaches above the level cap is shown at its real level and marked out of reach.
- **Learnt or not:** `vana.game.spells()`, the game's own 128-byte bitfield. Nothing asks the server and nothing is
  remembered locally, so the list matches the spell menu.
- **Dice and their rolls:** `dice_data.lua`, generated by `tools/make_dice_sources.py` from the 31 BG-Wiki die pages
  with the same parsers, the same cache and the same pacing as the scroll crawl (`tools/make_spell_sources.py`); each
  row keeps the page it was read from. Known-status is the ability bit, bag markers are the bag scan.
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
