# SpellTracker for VanaCore

What your job can still learn, and where each scroll comes from.

`/spells` opens one glass card: your job and level, how many things are still to learn, the mode's acquisition
badges, a search box, skill pills, and one scrolling list of everything this character can still learn - spells and,
on a corsair, the dice. Each spell row shows whether it is already learnt, its level, whether it comes from the main
job or the subjob, its skill and MP cost, and one badge for where a scroll comes from. A die row reads `Bard Die -
Choral Roll`, with its COR level, its badge and its note. Click the badge to search the CatsEyeXI item database, click
the Wiki button for BG-Wiki, or double-click the row for the database.

The tracker's scope is one rule: **anything a player learns by using an item is in the list.** A bard song is learnt
from a scroll; a corsair roll is learnt from a die; both are rows in the same list, under the same toggles. A third
kind of item-taught thing would be a row in the addon's kind table, not a second screen.

The window is drawn with the same `ui.lua` kit as the other VanaCore addons (Auction House, Party Finder, VanaMaps,
Clawmark, VanaStore), so it follows the theme, the window scale, the opacity and the controller.

## Commands

```
/spells                     the window on or off
/spells show                open it
/spells hide                close it
/spells minimize            fold the window down to a pill (see below)
/spells minimize off        unfold it again
/spells reset               position, size, the three scales and opacity back to their defaults
/spells mode ace|cw|wew     which acquisition systems the badges allow
/spells theme <id>          one of the kit's themes; no id lists them
/spells scale <50-300>      the window's geometry: borders, row heights, every measurement in percent
/spells text <50-300>       the letters only - the same number the footer slider sets
/spells pill <50-300>       the minimized capsule only
/spells learned on|off      show the spells and dice already learnt, too
/spells now on|off          only what this job and level can use right now
/spells held on|off         only what already sits in one of your bags (a scroll or a die)
/spells here                what this job still needs in the zone you are standing in, with where to get each one
/spells alerts on|off       the zone-in chime and row highlight on or off (never twice for one zone)
/spells alerts shop|drop|bcnm on|off   silence one of the three kinds of place
/spells alerts sound on|off the soft zone-in chime by itself, with the highlight left on
/spells rescan              read your bags again now (they are re-read every 4 seconds anyway)
/spells sync                ask the server for the scroll ledger again (Gramateus / the box)
/spells sound on|off        the bell as the window opens
/spells debug               the row counts, the bags it read, the window's size, and the last error, in chat
```

An unknown argument prints the same list in one chat line.

### Reading it on a small screen

Three scales, deliberately separate, because they answer three different complaints:

| Knob | What it moves | What it leaves alone |
|---|---|---|
| `/spells scale <50-300>` | the geometry: row heights, paddings, borders, the kit's own `S()` | the window you dragged |
| `/spells text <50-300>` | the font sizes, everywhere | every rect, row and border |
| `/spells pill <50-300>` | the minimized capsule and its word | the window, the list and the letters |

**Both scales have a slider**, on the footer strip at the bottom-right of the window: `Text` above, `Pill` below,
each with the kit's own track and its value in a label beside it. Drag one and the setting follows - the letters grow
in place for `Text` (no window resize needed), and `Pill` sets the size the window folds to, which the full window
cannot show, so its label is the feedback while you drag, and its word and tooltip say which surface it is. Both are
the same settings `/spells text` and `/spells pill` write, so a command and a slider can never disagree. Each value is
saved once, when you let go of the mouse, and `/spells reset` puts both back to 100 %.

Two rows rather than one on purpose: at the window's own 320 px floor a row of two tracks, two labels and two words
would need about 540 px and the card has 266 to give, so shrinking the tracks to fit would have made them unusable.
The strip has its own band at the bottom of the card (two rows, so no row of the list hides behind a control), and it
stops short of the corner: that corner is the window's resize grip now.

**The window resizes like an app.** Drag any edge or corner. Its size is remembered per character and comes
back next session, the list and its scrollbar follow it, and a window floor of 320 x 260 stops a drag that
would hide the header. `/spells reset` returns it to 880 x 560 (at 100 % geometry) and re-centres it. The
pill keeps its fixed size: a drag grip on a 230 x 34 capsule is a trap.

### Minimize: the pill

The `-` button in the header (left of the close button) folds the window down to a pill about 230 x 34 - the word
**Spelltracker**, a Play/Stop button and a Mute button, on the same card the window is drawn on. The capsule has its
own scale (`/spells pill <50-300>`), so a Deck can have a pill it can actually hit without making the window bigger.
The fold is saved per character, so a window you left as a pill comes back as a pill next session. `/spells minimize`
and `/spells minimize off` do the same thing from the keyboard.

- **Click the pill to restore it.** The word is part of the hitbox, not a label beside it: anywhere on the pill that
  is not Play/Stop or Mute brings the window back, with the current zone's rows already highlighted. Clicking either
  of the two buttons does that button's job and never also restores the window.
- **Play/Stop** - drawn as geometry, not as a font glyph: a triangle with a vertical left edge and its apex to the
  right while the zone alerts are listening, a square while they are stopped. It is the same switch as
  `/spells alerts on|off` (its tooltip names what the click will do). Stopping silences the chime, the highlight and
  the pulse together.
- **Mute** - a bell while the zone chime is audible and a bell-slash while it is muted. It is the same switch as
  `/spells alerts sound on|off`, and it is **sound only**: a muted pill still pulses and the restored window still
  highlights the rows.
- **The pulse** - the pill's border breathes (`0.75 + 0.25 * sin(t * 4)` alpha, the kit's own focus-ring shape) while
  the window is minimized, the alerts are listening, **and** the zone you are standing in has at least one row this
  job still needs. Nothing pulses for a zone with nothing to find, for Stop, or once the window is restored. Only the
  alpha moves: the pill never changes size or place, so it cannot shift under the mouse.

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

## Zone alerts: a chime and a highlight, no chat

Walking into a zone where something on your list is sold, dropped or fought for plays the folder's softer bell
(`sounds/tiny_bell.wav`) once and highlights those rows - an accent bar inside the row and a soft wash, in the current
theme's own accent. Nothing is written to chat and no toast appears: an alert must not interrupt a fight. The
highlight stays until the next zone-in, and a zone with nothing on your list clears it.

`/spells alerts on|off` is the master switch; `/spells alerts shop|drop|bcnm on|off` silences one kind of place;
`/spells alerts sound on|off` keeps the highlight and drops the chime. `/spells here` is the on-demand listing and
still answers in chat, because you typed it.

## Corsair dice, in the same list

Corsair rolls are **not** learnt with level. Each roll is taught by a die item, bought or found - the client's own
item table says so outright (`items_1.lua`, item 5477: `COR Lv.49`, *Teaches the Phantom Roll ability*, *Warrior's
Roll*). A die is therefore a row in the same list as a spell: `Bard Die - Choral Roll`, its COR level, its badge,
vendor and price (13 dice at Chayaya in Al Zahbi, 18 at Jajaroon and Chichiroon in Nashmau), and a bag marker when
the die itself is in one of your bags.

Which dice are listed comes from your jobs, never from a setting:

- **COR main** - every die at the level printed on it, usable from that level.
- **COR sub** - the dice at half the sub level, rounded down, each row flagged `needs COR main`: you can use the die
  at that level, but learning the roll needs corsair as the main job.
- **COR neither** - no die rows at all.

The same toggles apply to a die: `Show learnt` shows or hides a roll you already know (a missing ability bitfield is
drawn as `?`, never as "you don't know it"), `Usable now` keeps the dice at your level, `In storage` keeps the ones
whose item is in a bag, and the search box matches the die's name **and** the roll it teaches. The mode toggles
filter a die exactly as they filter a shop scroll, through the same badge rule.

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

* **reads** - job and level (`vana.game.self`), the spell bitfield (`vana.game.spells`), the ability bitfield
  (`vana.game.abilities`, for corsair rolls), item ids in the eighteen containers (`vana.game.container`), the shipped
  spell, die and item tables (`vana.gamedata`).
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
`settings\addons\spelltracker-vanacore\<Character>\settings.json` (theme, the three scales, mode, learned filter,
skill filter, window position and size, opacity, opening sound, zone alerts and their chime).

## Files

| File | What |
|---|---|
| `spelltracker-vanacore.lua` | the window, the events, the commands and the settings |
| `spells_core.lua` | pure logic: rows, counts, badges, URLs (no `vana`, testable headlessly) |
| `spells_data.lua` | the three modes, the badge definitions, the skill pills and the cited level overrides |
| `spell_sources.lua` | the generated per-spell acquisition table |
| `ui.lua` | the family's drawing kit (unmodified) |
| `pad.lua` | controller support shared by the family (unmodified) |
| `fonts/`, `sounds/small_bell.wav`, `sounds/tiny_bell.wav`, `images/jobs.png` | the kit's faces, the bells and the job icons |

`spells_core.lua` and `spell_sources.lua` are required softly: a copy missing one still loads and opens an empty list
(rather than failing at load), and `/spells debug` says which module is missing.

## Controller

With a gamepad enabled in `vanacore.ini` (`[addons] gamepad = 1`), the D-pad moves the focus, Confirm presses the
focused control (a mode, a skill pill, the learnt toggle, a row's badge or Wiki button), and Cancel leaves a text box.
The wheel and the list still answer the mouse.
