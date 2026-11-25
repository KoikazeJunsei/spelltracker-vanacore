# spelltracker suites

The evidence for `addons/vanacore/spelltracker-vanacore`: 241 core checks and 326 draw checks, no framework, no
dependencies. Run them from the repo root.

```
luajit tests/spelltracker/test_core.lua
VANA_GAMEDATA=/path/to/vanacore-src/addons/vanacore/libs/gamedata luajit tests/spelltracker/test_draw.lua
```

`test_core.lua` tests the pure modules (`spells_core.lua`, `dice_core.lua`, `scroll_ledger.lua`) against spelled-out
fixtures. `test_draw.lua` runs the whole addon against a stub of the VanaCore API: there is no client on this machine,
so it proves the events, the row list, the geometry and the settings round-trip, and nothing about how it looks - that
rung is played, not tested.

Neither file is packaged: the launcher packs the addon folder only.
