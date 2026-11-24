-- Where each spell's scroll comes from, read off BG-Wiki's scroll item pages (their "Purchased From",
-- "Dropped from" and "Obtained From" tables) by tools/make_spell_sources.py on 2026-11-24.
-- Keyed by spell id, the same ids as vana.gamedata.spells. Each row keeps the page it was read from in
-- `src`, so every badge can be checked. Blue magic is tagged from the rule that it is learnt in battle.
-- A spell with no row has no recorded source: the addon draws a "?" badge rather than a guess.
-- 519 spells with a source, 67 without a scroll page. Don't edit: rerun the generator.
local M = {}

M.spells = {
[1]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 62 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cure"}, -- Cure
[2]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 598 Gil San d'Oria at least 2nd place in Conquest (+3)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cure_II"}, -- Cure II
[3]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 3,334 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cure_III"}, -- Cure III
[4]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 23,400 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cure_IV"}, -- Cure IV
[5]={tag="drop",tags={"ah","drop","bcnm"},note="Foreseer Oramix / Ifrit's Cauldron (+12)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cure_V"}, -- Cure V
[7]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,393 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Curaga"}, -- Curaga
[8]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 11,200 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Curaga_II"}, -- Curaga II
[9]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 19,932 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Curaga_III"}, -- Curaga III
[10]={tag="drop",tags={"ah","drop","bcnm"},note="Novv the Whitehearted / Sea Serpent Grotto (+12)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Curaga_IV"}, -- Curaga IV
[12]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 5,293 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raise"}, -- Raise
[13]={tag="drop",tags={"ah","drop","bcnm"},note="Coral Sahagin / Sea Serpent Grotto (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raise_II"}, -- Raise II
[14]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 184 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Poisona"}, -- Poisona
[15]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 331 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Paralyna"}, -- Paralyna
[16]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,012 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blindna"}, -- Blindna
[17]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 2,330 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Silena"}, -- Silena
[18]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 19,200 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stona"}, -- Stona
[19]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 13,300 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Viruna"}, -- Viruna
[20]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 8,586 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cursna"}, -- Cursna
[21]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 35,000 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Holy"}, -- Holy
[23]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 84 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dia"}, -- Dia
[24]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 10,304 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dia_II"}, -- Dia II
[25]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 139,125 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dia_III"}, -- Dia III
[28]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 143 Gil San d'Oria at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Banish"}, -- Banish
[29]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 8,280 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Banish_II"}, -- Banish II
[30]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Nilerouche / Tavnazian Safehold - (F-7) / 66,000 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Banish_III"}, -- Banish III
[33]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,191 Gil San d'Oria must be 1st place in Conquest AND Must be San d'Oria Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Diaga"}, -- Diaga
[38]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,191 Gil San d'Oria at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Banishga"}, -- Banishga
[39]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 20,000 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Banishga_II"}, -- Banishga II
[43]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 224 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protect"}, -- Protect
[44]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 6,508 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protect_II"}, -- Protect II
[45]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 32,000 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protect_III"}, -- Protect III
[46]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 92,000 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protect_IV"}, -- Protect IV
[48]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,619 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shell"}, -- Shell
[49]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 16,192 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shell_II"}, -- Shell II
[50]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 26,244 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shell_III"}, -- Shell III
[51]={tag="drop",tags={"ah","drop","bcnm"},note="Ruby Quadav / Qulun Dome (+7)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shell_IV"}, -- Shell IV
[53]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 2,143 Gil San d'Oria at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blink"}, -- Blink
[54]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 7,181 Gil San d'Oria must be 1st place in Conquest AND Must be San d'Oria Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stoneskin"}, -- Stoneskin
[55]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 368 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aquaveil"}, -- Aquaveil
[56]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 855 Gil San d'Oria must be 1st place in Conquest AND Must be San d'Oria Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Slow"}, -- Slow
[57]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 18,400 Gil Windurst must be in 1st place in Conquest AND Must be Windurst Citizen (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Haste"}, -- Haste
[58]={tag="drop",tags={"ah","drop","bcnm"},note="Goblin Leecher / King Ranperre's Tomb (+28)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Paralyze"}, -- Paralyze
[59]={tag="drop",tags={"ah","drop","bcnm"},note="Garnet Quadav / Rolanberry Fields (+20)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Silence"}, -- Silence
[60]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 1,760 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barfire"}, -- Barfire
[61]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 3,624 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barblizzard"}, -- Barblizzard
[62]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 930 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Baraero"}, -- Baraero
[63]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 156 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barstone"}, -- Barstone
[64]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 5,754 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barthunder"}, -- Barthunder
[65]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 360 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barwater"}, -- Barwater
[66]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 1,760 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barfira"}, -- Barfira
[67]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 3,624 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barblizzara"}, -- Barblizzara
[68]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 930 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Baraera"}, -- Baraera
[69]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 156 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barstonra"}, -- Barstonra
[70]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 5,754 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barthundra"}, -- Barthundra
[71]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 360 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barwatera"}, -- Barwatera
[72]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 244 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barsleep"}, -- Barsleep
[73]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 400 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barpoison"}, -- Barpoison
[74]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 780 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barparalyze"}, -- Barparalyze
[75]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 2,030 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barblind"}, -- Barblind
[76]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 4,608 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barsilence"}, -- Barsilence
[77]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 15,120 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barpetrify"}, -- Barpetrify
[78]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 9,600 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barvirus"}, -- Barvirus
[79]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 139,125 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Slow_II"}, -- Slow II
[80]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 139,125 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Paralyze_II"}, -- Paralyze II
[81]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 60,750 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Recall-Jugner"}, -- Recall-Jugner
[82]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 60,750 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Recall-Pashh"}, -- Recall-Pashh
[83]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 60,750 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Recall-Meriph"}, -- Recall-Meriph
[86]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 244 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barsleepra"}, -- Barsleepra
[87]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 400 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barpoisonra"}, -- Barpoisonra
[88]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 780 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barparalyzra"}, -- Barparalyzra
[89]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 2,030 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barblindra"}, -- Barblindra
[90]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 4,608 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barsilencera"}, -- Barsilencera
[91]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 15,120 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barpetra"}, -- Barpetra
[92]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 9,600 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Barvira"}, -- Barvira
[93]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Brave Ox / Rabao - (F-7) / 20,092 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Cura"}, -- Cura
[94]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Brave Ox / Rabao - (F-7) / 62,192 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sacrifice"}, -- Sacrifice
[95]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Brave Ox / Rabao - (F-7) / 64,584 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Esuna"}, -- Esuna
[96]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Brave Ox / Rabao - (F-7) / 30,967 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Auspice"}, -- Auspice
[97]={tag="shop",tags={"shop","ah","bcnm"},note="Zafif / Al Zahbi - (J-8) / 28,500 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Reprisal"}, -- Reprisal
[98]={tag="shop",tags={"shop","ah","bcnm"},note="Sororo / Bastok Markets - (H-5) / 30,360 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Repose"}, -- Repose
[100]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 4,747 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enfire"}, -- Enfire
[101]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 3,770 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enblizzard"}, -- Enblizzard
[102]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 2,300 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enaero"}, -- Enaero
[103]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 1,867 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enstone"}, -- Enstone
[104]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 1,393 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enthunder"}, -- Enthunder
[105]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 6,508 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enwater"}, -- Enwater
[106]={tag="drop",tags={"ah","drop","bcnm"},note="Kutkha / Balga's Dais (+25)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Phalanx"}, -- Phalanx
[107]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 139,125 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Phalanx_II"}, -- Phalanx II
[108]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 3,974 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Regen"}, -- Regen
[109]={tag="drop",tags={"ah","drop","bcnm"},note="Taisaijin / Ranguemont Pass",src="https://www.bg-wiki.com/ffxi/Scroll_of_Refresh"}, -- Refresh
[110]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 7,203 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Regen_II"}, -- Regen II
[111]={tag="drop",tags={"ah","drop","bcnm"},note="Foreseer Oramix / Ifrit's Cauldron (+12)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Regen_III"}, -- Regen III
[112]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Zafif / Al Zahbi - (J-8) / 27,600 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Flash"}, -- Flash
[120]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 34,656 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Teleport-Yhoat"}, -- Teleport-Yhoat
[121]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 34,656 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Teleport-Altep"}, -- Teleport-Altep
[122]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 32,176 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Teleport-Holla"}, -- Teleport-Holla
[123]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 32,176 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Teleport-Dem"}, -- Teleport-Dem
[124]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 32,176 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Teleport-Mea"}, -- Teleport-Mea
[125]={tag="drop",tags={"ah","drop","bcnm"},note="Goblin Leecher / Maze of Shakhrami (+30)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protectra"}, -- Protectra
[126]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 7,047 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protectra_II"}, -- Protectra II
[127]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 19,200 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protectra_III"}, -- Protectra III
[128]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 87,400 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protectra_IV"}, -- Protectra IV
[129]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 119,240 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Protectra_V"}, -- Protectra V
[130]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 1,760 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shellra"}, -- Shellra
[131]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 14,080 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shellra_II"}, -- Shellra II
[132]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 26,244 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shellra_III"}, -- Shellra III
[133]={tag="drop",tags={"ah","drop","bcnm"},note="Foreseer Oramix / Ifrit's Cauldron (+12)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shellra_IV"}, -- Shellra IV
[134]={tag="shop",tags={"shop","ah","bcnm"},note="Hasim / Lower Jeuno - (H-9) / 124,540 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shellra_V"}, -- Shellra V
[135]={tag="drop",tags={"ah","drop","bcnm"},note="Topaz Quadav / Castle Zvahl Keep (+4)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Reraise"}, -- Reraise
[136]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 5,293 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Invisible"}, -- Invisible
[137]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 2,300 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sneak"}, -- Sneak
[138]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 1,191 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Deodorize"}, -- Deodorize
[139]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 34,656 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Teleport-Vahzl"}, -- Teleport-Vahzl
[140]={tag="drop",tags={"ah","drop","bcnm"},note="Za'Dha Adamantking / Qulun Dome (+27)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raise_III"}, -- Raise III
[141]={tag="drop",tags={"ah","drop","bcnm"},note="Hellish Weapon / Fei'Yin",src="https://www.bg-wiki.com/ffxi/Scroll_of_Reraise_II"}, -- Reraise II
[142]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Dabih Jajalioh / Ru'Lude Gardens - (F-9) / 500,000 Gil / Tier 4 shop only (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Reraise_III"}, -- Reraise III
[143]={tag="bcnm",tags={"ah","bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Erase"}, -- Erase
[144]={tag="bcnm",tags={"bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fire"}, -- Fire
[145]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 16,928 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fire_II"}, -- Fire II
[146]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 33,306 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fire_III"}, -- Fire III
[147]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 148,500 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fire_IV"}, -- Fire IV
[149]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,619 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzard"}, -- Blizzard
[150]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 22,356 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzard_II"}, -- Blizzard II
[151]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 39,368 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzard_III"}, -- Blizzard III
[152]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 166,250 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzard_IV"}, -- Blizzard IV
[154]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 331 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aero"}, -- Aero
[155]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 12,236 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aero_II"}, -- Aero II
[156]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 27,744 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aero_III"}, -- Aero III
[157]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 131,750 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aero_IV"}, -- Aero IV
[159]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 62 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stone"}, -- Stone
[160]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 5,878 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stone_II"}, -- Stone II
[161]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 19,932 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stone_III"}, -- Stone III
[162]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 108,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stone_IV"}, -- Stone IV
[164]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 3,334 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thunder"}, -- Thunder
[165]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 28,520 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thunder_II"}, -- Thunder II
[166]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 45,930 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thunder_III"}, -- Thunder III
[167]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 185,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thunder_IV"}, -- Thunder IV
[169]={tag="bcnm",tags={"bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Water"}, -- Water
[170]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 8,280 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Water_II"}, -- Water II
[171]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 22,682 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Water_III"}, -- Water III
[172]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 116,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Water_IV"}, -- Water IV
[174]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 7,181 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Firaga"}, -- Firaga
[175]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 21,307 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Firaga_II"}, -- Firaga II
[176]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 112,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Firaga_III"}, -- Firaga III
[179]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 10,948 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzaga"}, -- Blizzaga
[180]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 26,244 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzaga_II"}, -- Blizzaga II
[181]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 127,500 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzaga_III"}, -- Blizzaga III
[184]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 4,239 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aeroga"}, -- Aeroga
[185]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 19,800 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aeroga_II"}, -- Aeroga II
[186]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 95,625 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aeroga_III"}, -- Aeroga III
[189]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 1,191 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stonega"}, -- Stonega
[190]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 12,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stonega_II"}, -- Stonega II
[191]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 69,875 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stonega_III"}, -- Stonega III
[194]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 15,456 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thundaga"}, -- Thundaga
[195]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 31,681 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thundaga_II"}, -- Thundaga II
[196]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 144,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thundaga_III"}, -- Thundaga III
[199]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 2,134 Gil Windurst at least 2nd place in Conquest (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Waterga"}, -- Waterga
[200]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 13,050 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Waterga_II"}, -- Waterga II
[201]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 82,250 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Waterga_III"}, -- Waterga III
[204]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 71,250 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Flare"}, -- Flare
[205]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 129,180 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Flare_II"}, -- Flare II
[206]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 52,500 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Freeze"}, -- Freeze
[207]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 129,180 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Freeze_II"}, -- Freeze II
[208]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 56,250 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Tornado"}, -- Tornado
[209]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 129,180 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Tornado_II"}, -- Tornado II
[210]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 60,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Quake"}, -- Quake
[211]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 129,180 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Quake_II"}, -- Quake II
[212]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 63,750 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Burst"}, -- Burst
[213]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 129,180 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Burst_II"}, -- Burst II
[214]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Susu / Lower Jeuno - (H-9) / 67,500 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Flood"}, -- Flood
[215]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 129,180 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Flood_II"}, -- Flood II
[216]={tag="drop",tags={"ah","drop","bcnm"},note="Wendigo / Maze of Shakhrami (+4)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Gravity"}, -- Gravity
[220]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 84 Gil San d'Oria at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Poison"}, -- Poison
[221]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 23,184 Gil Windurst must be in 1st place in Conquest AND Must be Windurst Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Poison_II"}, -- Poison II
[225]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 4,747 Gil Windurst must be in 1st place in Conquest AND Must be Windurst Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Poisonga"}, -- Poisonga
[226]={tag="bcnm",tags={"ah","bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Poisonga_II"}, -- Poisonga II
[230]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 368 Gil San d'Oria at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Bio"}, -- Bio
[231]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 12,880 Gil Windurst must be in 1st place in Conquest AND Must be Windurst Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Bio_II"}, -- Bio II
[232]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 139,125 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Bio_III"}, -- Bio III
[235]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 4,747 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Burn"}, -- Burn
[236]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 3,770 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Frost"}, -- Frost
[237]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 2,300 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Choke"}, -- Choke
[238]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,867 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Rasp"}, -- Rasp
[239]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 1,393 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shock"}, -- Shock
[240]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 6,508 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Drown"}, -- Drown
[241]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 32,320 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Retrace"}, -- Retrace
[242]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Mazween / Aht Urhgan Whitegate - (G-7) / 44,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-ACC"}, -- Absorb-ACC
[245]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 10,428 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Drain"}, -- Drain
[246]={tag="shop",tags={"shop","ah","bcnm"},note="Mazween / Aht Urhgan Whitegate - (G-7) / 30,780 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Drain_II"}, -- Drain II
[247]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 12,850 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Aspir"}, -- Aspir
[249]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 10,428 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blaze_Spikes"}, -- Blaze Spikes
[250]={tag="drop",tags={"ah","drop","quest","bcnm"},note="Phantom / Ship Bound For Selbina (+3)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Ice_Spikes"}, -- Ice Spikes
[251]={tag="shop",tags={"shop","ah","bcnm"},note="Hilkomu-Makimu / Windurst Waters South - (G-7) / 8,280 Gil Windurst at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shock_Spikes"}, -- Shock Spikes
[252]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Mamaroon / Nashmau - (H-7) / 27,000 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stun"}, -- Stun
[253]={tag="shop",tags={"shop","ah","bcnm"},note="Regine / Port San d'Oria - (J-8) / 2,300 Gil San d'Oria at least 2nd place in Conquest (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sleep"}, -- Sleep
[254]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Regine / Port San d'Oria - (J-8) / 114 Gil San d'Oria must be 1st place in Conquest AND Must be San d'Oria Citizen (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blind"}, -- Blind
[258]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Scribe / Giddeus (+20)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Bind"}, -- Bind
[259]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 18,720 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sleep_II"}, -- Sleep II
[260]={tag="shop",tags={"shop","ah","bcnm"},note="Shohrun-Tuhrun / Windurst Waters South - (G-7) / 79,928 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dispel"}, -- Dispel
[261]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 11,953 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Warp"}, -- Warp
[262]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 37,200 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Warp_II"}, -- Warp II
[263]={tag="drop",tags={"ah","drop","bcnm"},note="Banshee / Gusgen Mines (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Escape"}, -- Escape
[264]={tag="drop",tags={"ah","drop","bcnm"},note="Wight / Sauromugue Champaign / Batallia Downs / Qufim Island / Gusgen Mines / Maze of Shakhrami",src="https://www.bg-wiki.com/ffxi/Scroll_of_Tractor"}, -- Tractor
[266]={tag="bcnm",tags={"ah","bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-STR"}, -- Absorb-STR
[267]={tag="drop",tags={"ah","drop","bcnm"},note="Duke Haborym / Castle Zvahl Baileys (+4)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-DEX"}, -- Absorb-DEX
[268]={tag="drop",tags={"ah","drop","bcnm"},note="Orcish Zerker / Castle Zvahl Keep (+43)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-VIT"}, -- Absorb-VIT
[269]={tag="drop",tags={"ah","drop","bcnm"},note="Orcish Zerker / Monastic Cavern (+44)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-AGI"}, -- Absorb-AGI
[270]={tag="drop",tags={"ah","drop","bcnm"},note="Orcish Zerker / Monastic Cavern (+44)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-INT"}, -- Absorb-INT
[271]={tag="shop",tags={"shop","ah","bcnm"},note="Jabbar / Port Bastok - (F-6) / 14,070 Gil / Tenshodo Guild Merchant / Open from 1:00 - 23:00 daily (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-MND"}, -- Absorb-MND
[272]={tag="shop",tags={"shop","ah","bcnm"},note="Jabbar / Port Bastok - (F-6) / 14,070 Gil / Tenshodo Guild Merchant / Open from 1:00 - 23:00 daily (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-CHR"}, -- Absorb-CHR
[273]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 11,200 Gil (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sleepga"}, -- Sleepga
[274]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 67,818 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sleepga_II"}, -- Sleepga II
[275]={tag="shop",tags={"shop","ah","bcnm"},note="Mazween / Aht Urhgan Whitegate - (G-7) / 27,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Absorb-TP"}, -- Absorb-TP
[276]={tag="shop",tags={"shop","ah","bcnm"},note="Susu / Lower Jeuno - (H-9) / 139,125 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blind_II"}, -- Blind II
[277]={tag="shop",tags={"shop","ah","bcnm"},note="Mazween / Aht Urhgan Whitegate - (G-7) / 70,560 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dread_Spikes"}, -- Dread Spikes
[312]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Macchi Gazlitah / Ru'Lude Gardens - (H-9) / 31,878 Gil / Tier 3 shop only",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enfire_II"}, -- Enfire II
[313]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Macchi Gazlitah / Ru'Lude Gardens - (H-9) / 30,492 Gil / Tier 3 shop only",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enblizzard_II"}, -- Enblizzard II
[314]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Macchi Gazlitah / Ru'Lude Gardens - (H-9) / 27,968 Gil / Tier 3 shop only",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enaero_II"}, -- Enaero II
[315]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Macchi Gazlitah / Ru'Lude Gardens - (H-9) / 26,112 Gil / Tier 3 shop only",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enstone_II"}, -- Enstone II
[316]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Macchi Gazlitah / Ru'Lude Gardens - (H-9) / 25,600 Gil / Tier 3 shop only",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enthunder_II"}, -- Enthunder II
[317]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Macchi Gazlitah / Ru'Lude Gardens - (H-9) / 33,000 Gil / Tier 3 shop only",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enwater_II"}, -- Enwater II
[318]={tag="shop",tags={"shop","ah","bcnm"},note="Amalasanda / Lower Jeuno - (J-9) / 9,590 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Monomi:_Ichi"}, -- Monomi: Ichi
[320]={tag="shop",tags={"shop","ah","bcnm"},note="Jabbar / Port Bastok - (F-6) / 1,561 Gil / Tenshodo Guild Merchant / Open from 1:00 - 23:00 daily (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Katon:_Ichi"}, -- Katon: Ichi
[321]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conquistador / Castle Zvahl Keep (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Katon:_Ni"}, -- Katon: Ni
[322]={tag="shop",tags={"shop","ah","bcnm"},note="Solby-Maholby / Norg - (H-9) / 107,325 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Katon:_San"}, -- Katon: San
[323]={tag="shop",tags={"shop","ah","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,331 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Hyoton:_Ichi"}, -- Hyoton: Ichi
[324]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conquistador / Castle Zvahl Keep (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Hyoton:_Ni"}, -- Hyoton: Ni
[325]={tag="shop",tags={"shop","ah","bcnm"},note="Solby-Maholby / Norg - (H-9) / 107,325 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Hyoton:_San"}, -- Hyoton: San
[326]={tag="shop",tags={"shop","ah","bcnm"},note="Jabbar / Port Bastok - (F-6) / 1,561 Gil / Tenshodo Guild Merchant / Open from 1:00 - 23:00 daily (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Huton:_Ichi"}, -- Huton: Ichi
[327]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Yagudo Conquistador / Castle Oztroja (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Huton:_Ni"}, -- Huton: Ni
[328]={tag="shop",tags={"shop","ah","bcnm"},note="Solby-Maholby / Norg - (H-9) / 107,325 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Huton:_San"}, -- Huton: San
[329]={tag="shop",tags={"shop","ah","bcnm"},note="Jabbar / Port Bastok - (F-6) / 1,561 Gil / Tenshodo Guild Merchant / Open from 1:00 - 23:00 daily (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Doton:_Ichi"}, -- Doton: Ichi
[330]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conquistador / Castle Zvahl Keep (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Doton:_Ni"}, -- Doton: Ni
[331]={tag="shop",tags={"shop","ah","bcnm"},note="Solby-Maholby / Norg - (H-9) / 107,325 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Doton:_San"}, -- Doton: San
[332]={tag="shop",tags={"shop","ah","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,331 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raiton:_Ichi"}, -- Raiton: Ichi
[333]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conquistador / Castle Zvahl Keep (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raiton:_Ni"}, -- Raiton: Ni
[334]={tag="shop",tags={"shop","ah","bcnm"},note="Solby-Maholby / Norg - (H-9) / 107,325 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raiton:_San"}, -- Raiton: San
[335]={tag="shop",tags={"shop","ah","bcnm"},note="Jabbar / Port Bastok - (F-6) / 1,561 Gil / Tenshodo Guild Merchant / Open from 1:00 - 23:00 daily (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Suiton:_Ichi"}, -- Suiton: Ichi
[336]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conquistador / Castle Zvahl Keep (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Suiton:_Ni"}, -- Suiton: Ni
[337]={tag="shop",tags={"shop","ah","bcnm"},note="Solby-Maholby / Norg - (H-9) / 107,325 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Suiton:_San"}, -- Suiton: San
[338]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 13,133 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Utsusemi:_Ichi"}, -- Utsusemi: Ichi
[339]={tag="bcnm",tags={"ah","bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Utsusemi:_Ni"}, -- Utsusemi: Ni
[341]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,849 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Jubaku:_Ichi"}, -- Jubaku: Ichi
[344]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,849 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Hojo:_Ichi"}, -- Hojo: Ichi
[345]={tag="drop",tags={"ah","drop","bcnm"},note="Tonberry Decapitator / Den of Rancor (+6)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Hojo:_Ni"}, -- Hojo: Ni
[347]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,849 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Kurayami:_Ichi"}, -- Kurayami: Ichi
[348]={tag="drop",tags={"ah","drop","bcnm"},note="Tonberry Decapitator / Den of Rancor (+6)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Kurayami:_Ni"}, -- Kurayami: Ni
[350]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,849 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dokumori:_Ichi"}, -- Dokumori: Ichi
[353]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 2,849 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Tonko:_Ichi"}, -- Tonko: Ichi
[354]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Assassin / Castle Oztroja / U (+6)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Tonko:_Ni"}, -- Tonko: Ni
[368]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 66 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Requiem"}, -- Foe Requiem
[369]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 450 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Requiem_II"}, -- Foe Requiem II
[370]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 4,048 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Requiem_III"}, -- Foe Requiem III
[371]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 7,065 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Requiem_IV"}, -- Foe Requiem IV
[372]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Chanter / Castle Oztroja (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Requiem_V"}, -- Foe Requiem V
[373]={tag="drop",tags={"ah","drop","bcnm"},note="Abyss Sahagin / Sea Serpent Grotto (+3)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Requiem_VI"}, -- Foe Requiem VI
[376]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Drummer / Castle Oztroja",src="https://www.bg-wiki.com/ffxi/Scroll_of_Horde_Lullaby"}, -- Horde Lullaby
[378]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 38 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Army%27s_Paeon"}, -- Army's Paeon
[379]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 328 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Army%27s_Paeon_II"}, -- Army's Paeon II
[380]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 3,312 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Army%27s_Paeon_III"}, -- Army's Paeon III
[381]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 6,072 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Army%27s_Paeon_IV"}, -- Army's Paeon IV
[382]={tag="drop",tags={"ah","drop","bcnm"},note="Coastal Sahagin / Sea Serpent Grotto",src="https://www.bg-wiki.com/ffxi/Scroll_of_Army%27s_Paeon_V"}, -- Army's Paeon V
[386]={tag="shop",tags={"shop","ah","drop","quest","bcnm"},note="Amalasanda / Lower Jeuno - (J-8) / 11,833 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Mage%27s_Ballad"}, -- Mage's Ballad
[387]={tag="bcnm",tags={"ah","bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Mage%27s_Ballad_II"}, -- Mage's Ballad II
[389]={tag="shop",tags={"shop","ah","bcnm"},note="Ferdoulemiont / Southern San d'Oria - (I-11) / 16 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Knight%27s_Minne"}, -- Knight's Minne
[390]={tag="shop",tags={"shop","ah","bcnm"},note="Ferdoulemiont / Southern San d'Oria - (I-11) / 883 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Knight%27s_Minne_II"}, -- Knight's Minne II
[391]={tag="shop",tags={"shop","ah","bcnm"},note="Ferdoulemiont / Southern San d'Oria - (I-11) / 5,626 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Knight%27s_Minne_III"}, -- Knight's Minne III
[392]={tag="drop",tags={"ah","drop","bcnm"},note="Abyss Sahagin / Sea Serpent Grotto (+3)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Knight%27s_Minne_IV"}, -- Knight's Minne IV
[394]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 22 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Valor_Minuet"}, -- Valor Minuet
[395]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 1,126 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Valor_Minuet_II"}, -- Valor Minuet II
[396]={tag="shop",tags={"shop","ah","bcnm"},note="Hortense / Bastok Markets - (K-10) / 5,667 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Valor_Minuet_III"}, -- Valor Minuet III
[397]={tag="drop",tags={"ah","drop","bcnm"},note="Coastal Sahagin / Sea Serpent Grotto / 0.66% (+3)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Valor_Minuet_IV"}, -- Valor Minuet IV
[399]={tag="shop",tags={"shop","ah","bcnm"},note="Boncort / Northern San d'Oria - (F-8) / 167 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sword_Madrigal"}, -- Sword Madrigal
[400]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Lutenist / Castle Zvahl Baileys (+4)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blade_Madrigal"}, -- Blade Madrigal
[401]={tag="shop",tags={"shop","ah","bcnm"},note="Mono Nchaa / Windurst Woods - (H-13) / 2,649 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Hunter%27s_Prelude"}, -- Hunter's Prelude
[402]={tag="drop",tags={"ah","drop","bcnm"},note="Orcish Farkiller / Monastic Cavern (+3)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Archer%27s_Prelude"}, -- Archer's Prelude
[403]={tag="shop",tags={"shop","ah","bcnm"},note="Dohdjuma / Selbina - (G-10) / 238 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sheepfoe_Mambo"}, -- Sheepfoe Mambo
[404]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Lutenist / Castle Zvahl Baileys (+4)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dragonfoe_Mambo"}, -- Dragonfoe Mambo
[405]={tag="shop",tags={"shop","ah","bcnm"},note="Valeriano / Port Bastok - (K-8) / 2,980 Gil First Place nation in Conquest only (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fowl_Aubade"}, -- Fowl Aubade
[406]={tag="shop",tags={"shop","ah","bcnm"},note="Wije Tiren / Windurst Woods - (I-8) / 99 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Herb_Pastoral"}, -- Herb Pastoral
[408]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conductor / Castle Oztroja",src="https://www.bg-wiki.com/ffxi/Scroll_of_Shining_Fantasia"}, -- Shining Fantasia
[409]={tag="shop",tags={"shop","ah","bcnm"},note="Valeriano / Port Bastok - (K-8) / 598 Gil First Place nation in Conquest only (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Scop%27s_Operetta"}, -- Scop's Operetta
[410]={tag="shop",tags={"shop","ah","bcnm"},note="Valeriano / Port Bastok - (K-8) / 17,296 Gil First Place nation in Conquest only (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Puppet%27s_Operetta"}, -- Puppet's Operetta
[412]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Chanter / Castle Zvahl Keep (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Gold_Capriccio"}, -- Gold Capriccio
[414]={tag="bcnm",tags={"ah","bcnm"},note="Prime Weapons • Ultimate Weapons • Ultimate Augments • Abjurations iL119 • JSE Necks • Divergence Augments • Escutcheons (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Warding_Round"}, -- Warding Round
[415]={tag="shop",tags={"shop","ah","bcnm"},note="Creepstix / Lower Jeuno - (H-9) / 8,160 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Goblin_Gavotte"}, -- Goblin Gavotte
[419]={tag="shop",tags={"shop","ah","bcnm"},note="Valeriano / Port Bastok - (K-8) / 2,104 Gil First Place nation in Conquest only (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Advancing_March"}, -- Advancing March
[420]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Conductor / Castle Oztroja (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Victory_March"}, -- Victory March
[421]={tag="shop",tags={"shop","ah","bcnm"},note="Thadiene / Southern San d'Oria - (K-7) / 4,416 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Battlefield_Elegy"}, -- Battlefield Elegy
[422]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Chanter / Castle Oztroja (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Carnage_Elegy"}, -- Carnage Elegy
[424]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 3,146 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sinewy_Etude"}, -- Sinewy Etude
[425]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 2,815 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dextrous_Etude"}, -- Dextrous Etude
[426]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 2,208 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Vivacious_Etude"}, -- Vivacious Etude
[427]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 1,913 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Quick_Etude"}, -- Quick Etude
[428]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 1,567 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Learned_Etude"}, -- Learned Etude
[429]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 1,265 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Spirited_Etude"}, -- Spirited Etude
[430]={tag="shop",tags={"shop","ah","bcnm"},note="Manyny / Windurst Woods - (H-13) / 1,000 Gil (+1)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Enchanting_Etude"}, -- Enchanting Etude
[431]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 81,328 Gil Bastok at least 2nd place in Conquest",src="https://www.bg-wiki.com/ffxi/Scroll_of_Herculean_Etude"}, -- Herculean Etude
[432]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 78,200 Gil Bastok at least 2nd place in Conquest",src="https://www.bg-wiki.com/ffxi/Scroll_of_Uncanny_Etude"}, -- Uncanny Etude
[433]={tag="shop",tags={"shop","ah","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 70,656 Gil Bastok at least 2nd place in Conquest",src="https://www.bg-wiki.com/ffxi/Scroll_of_Vital_Etude"}, -- Vital Etude
[434]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 67,712 Gil Bastok at least 2nd place in Conquest",src="https://www.bg-wiki.com/ffxi/Scroll_of_Swift_Etude"}, -- Swift Etude
[435]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 64,768 Gil Bastok at least 2nd place in Conquest",src="https://www.bg-wiki.com/ffxi/Scroll_of_Sage_Etude"}, -- Sage Etude
[436]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 57,960 Gil Bastok at least 2nd place in Conquest",src="https://www.bg-wiki.com/ffxi/Scroll_of_Logical_Etude"}, -- Logical Etude
[437]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 55,200 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Bewitching_Etude"}, -- Bewitching Etude
[438]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 6,380 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fire_Carol"}, -- Fire Carol
[439]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 7,440 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Ice_Carol"}, -- Ice Carol
[440]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 5,940 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Wind_Carol"}, -- Wind Carol
[441]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 4,600 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Earth_Carol"}, -- Earth Carol
[442]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 7,920 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Lightning_Carol"}, -- Lightning Carol
[443]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 5,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Water_Carol"}, -- Water Carol
[444]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 4,200 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Light_Carol"}, -- Light Carol
[445]={tag="shop",tags={"shop","ah","bcnm"},note="Yoskolo / Lower Jeuno - (I-8) / 8,400 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dark_Carol"}, -- Dark Carol
[454]={tag="shop",tags={"shop","ah","bcnm"},note="Ensasa / Windurst Waters North - (H-9) / 644 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fire_Threnody"}, -- Fire Threnody
[455]={tag="shop",tags={"shop","ah","bcnm"},note="Mjoll / Bastok Markets - (E-11) / 1,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Ice_Threnody"}, -- Ice Threnody
[456]={tag="shop",tags={"shop","ah","bcnm"},note="Champalpieu / Upper Jeuno - (H-6) / 567 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Wind_Threnody"}, -- Wind Threnody
[457]={tag="shop",tags={"shop","ah","bcnm"},note="Ensasa / Windurst Waters North - (H-9) / 283 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Earth_Threnody"}, -- Earth Threnody
[459]={tag="shop",tags={"shop","ah","bcnm"},note="Champalpieu / Upper Jeuno - (H-6) / 420 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Water_Threnody"}, -- Water Threnody
[460]={tag="shop",tags={"shop","ah","bcnm"},note="Lusiane / Southern San d'Oria - (F-8) / 110 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Light_Threnody"}, -- Light Threnody
[461]={tag="shop",tags={"shop","ah","bcnm"},note="Mjoll / Bastok Markets - (E-11) / 199 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Dark_Threnody"}, -- Dark Threnody
[462]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Drummer / Castle Oztroja",src="https://www.bg-wiki.com/ffxi/Scroll_of_Magic_Finale"}, -- Magic Finale
[463]={tag="drop",tags={"ah","drop","bcnm"},note="Yagudo Piper / Giddeus (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Lullaby"}, -- Foe Lullaby
[464]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Valeriano / Port Bastok - (K-8) / 92,000 Gil First Place nation in Conquest only (+2)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Goddess%27s_Hymnus"}, -- Goddess's Hymnus
[465]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Ferdoulemiont / Southern San d'Oria - (I-11) / 50,784 Gil (+4)",src="https://www.bg-wiki.com/ffxi/Scroll_of_Chocobo_Mazurka"}, -- Chocobo Mazurka
[466]={tag="drop",tags={"ah","drop","bcnm"},note="Abyss Sahagin / Sea Serpent Grotto",src="https://www.bg-wiki.com/ffxi/Scroll_of_Maiden%27s_Virelai"}, -- Maiden's Virelai
[467]={tag="shop",tags={"shop","ah","bcnm"},note="Khaf Jhifanm / Aht Urhgan Whitegate - (H-11) / 4,400 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Raptor_Mazurka"}, -- Raptor Mazurka
[468]={tag="shop",tags={"shop","ah","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 91,425 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foe_Sirvente"}, -- Foe Sirvente
[469]={tag="shop",tags={"shop","ah","bcnm"},note="Harmodios / Bastok Markets - (K-10) / 91,425 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Adventurer%27s_Dirge"}, -- Adventurer's Dirge
[513]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Venom Shell
[515]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Maelstrom
[517]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Metallic Body
[519]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Screwdriver
[521]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- MP Drainkiss
[522]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Death Ray
[524]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sandspin
[527]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Smite of Rage
[529]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Bludgeon
[530]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Refueling
[531]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Ice Break
[532]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Blitzstrahl
[533]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Self-Destruct
[534]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Mysterious Light
[535]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Cold Wave
[536]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Poison Breath
[537]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Stinking Gas
[538]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Memento Mori
[539]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Terror Touch
[540]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Spinal Cleave
[541]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Blood Saber
[542]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Digest
[543]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Mandibular Bite
[544]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Cursed Sphere
[545]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sickle Slash
[547]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Cocoon
[548]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Filamented Hold
[549]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Pollen
[551]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Power Attack
[554]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Death Scissors
[555]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Magnetite Cloud
[557]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Eyes On Me
[560]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Frenetic Rip
[561]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Frightful Roar
[563]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Hecatomb Wave
[564]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Body Slam
[565]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Radiant Breath
[567]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Helldive
[569]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Jet Stream
[570]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Blood Drain
[572]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sound Blast
[573]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Feather Tickle
[574]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Feather Barrier
[575]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Jettatura
[576]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Yawn
[577]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Foot Kick
[578]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Wild Carrot
[579]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Voracious Trunk
[581]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Healing Breeze
[582]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Chaotic Eye
[584]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sheep Song
[585]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Ram Charge
[587]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Claw Cyclone
[588]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Lowing
[589]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Dimensional Death
[591]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Heat Breath
[592]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Blank Gaze
[593]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Magic Fruit
[594]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Uppercut
[595]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- 1000 Needles
[596]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Pinecone Bomb
[597]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sprout Smack
[598]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Soporific
[599]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Queasyshroom
[603]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Wild Oats
[604]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Bad Breath
[605]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Geist Wall
[606]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Awful Eye
[608]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Frost Breath
[610]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Infrasonics
[611]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Disseverment
[612]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Actinic Burst
[613]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Reactor Cool
[614]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Saline Coat
[615]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Plasma Charge
[616]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Temporal Shift
[617]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Vertical Cleave
[618]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Blastbomb
[620]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Battle Dance
[621]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sandspray
[622]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Grand Slam
[623]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Head Butt
[626]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Bomb Toss
[628]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Frypan
[629]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Flying Hip Press
[631]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Hydro Shot
[632]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Diamondhide
[633]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Enervation
[634]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Light of Penance
[636]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Warm-Up
[637]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Firespit
[638]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Feather Storm
[640]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Tail Slap
[641]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Hysteric Barrage
[642]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Amplification
[643]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Cannonball
[644]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Mind Blast
[645]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Exuviation
[646]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Magic Hammer
[647]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Zephyr Mantle
[648]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Regurgitation
[650]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Seedspray
[651]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Corrosive Ooze
[652]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Spiral Spin
[653]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Asuran Claws
[654]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sub-zero Smash
[655]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Triumphant Roar
[656]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Acrid Stream
[657]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Blazing Bound
[658]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Plenilune Embrace
[659]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Demoralizing Roar
[660]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Cimicine Discharge
[661]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Animating Wail
[662]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Battery Charge
[663]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Leafstorm
[664]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Regeneration
[665]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Final Sting
[666]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Goblin Rush
[667]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Vanity Dive
[668]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Magic Barrier
[669]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Whirl of Rage
[670]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Benthic Typhoon
[671]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Auroral Drape
[672]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Osmosis
[673]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Quad. Continuum
[674]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Fantod
[675]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Thermal Pulse
[677]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Empty Thrash
[678]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Dream Flower
[679]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Occultation
[680]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Charged Whisker
[681]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Winds of Promy.
[682]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Delta Thrust
[683]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Evryone. Grudge
[684]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Reaving Wind
[685]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Barrier Tusk
[686]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Mortal Ray
[687]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Water Bomb
[688]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Heavy Strike
[689]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Dark Orb
[690]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- White Wind
[692]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Sudden Lunge
[693]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Quadrastrike
[694]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Vapor Spray
[695]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Thunder Breath
[696]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- O. Counterstance
[697]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Amorphic Spikes
[698]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Wind Breath
[699]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Barbed Crescent
[736]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Thunderbolt
[737]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Harden Shell
[738]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Absolute Terror
[739]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Gates of Hades
[740]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Tourbillion
[741]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Pyric Bulwark
[742]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Bilgestorm
[743]={tag="learn",tags={"learn"},note="learnt by fighting the monster that casts it",src="https://www.bg-wiki.com/ffxi/Blue_Magic"}, -- Bloodrake
[768]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 2,335 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Regen"}, -- Indi-Regen
[769]={tag="shop",tags={"shop","ah","quest","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 100 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Poison"}, -- Indi-Poison
[770]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 21,000 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Refresh"}, -- Indi-Refresh
[772]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 53,460 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-STR"}, -- Indi-STR
[773]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 46,440 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-DEX"}, -- Indi-DEX
[774]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 43,740 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-VIT"}, -- Indi-VIT
[775]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 32,640 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-AGI"}, -- Indi-AGI
[776]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 30,912 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-INT"}, -- Indi-INT
[777]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 23,940 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-MND"}, -- Indi-MND
[778]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 21,000 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-CHR"}, -- Indi-CHR
[779]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 25,270 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Fury"}, -- Indi-Fury
[780]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 10,926 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Barrier"}, -- Indi-Barrier
[781]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 52,080 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Acumen"}, -- Indi-Acumen
[782]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 34,000 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Fend"}, -- Indi-Fend
[783]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 1,400 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Precision"}, -- Indi-Precision
[784]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 372 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Voidance"}, -- Indi-Voidance
[785]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 6,692 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Focus"}, -- Indi-Focus
[786]={tag="shop",tags={"shop","ah","bcnm"},note="Ishvad / Western Adoulin - (I-5) / 2,425 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Attunement"}, -- Indi-Attunement
[791]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 83,160 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Slip"}, -- Indi-Slip
[792]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 61,875 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Torpor"}, -- Indi-Torpor
[793]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 504,000 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Vex"}, -- Indi-Vex
[794]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 94,185 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Languor"}, -- Indi-Languor
[795]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 53,460 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Slow"}, -- Indi-Slow
[796]={tag="shop",tags={"shop","ah","bcnm"},note="Eukalline / Western Adoulin - (I-5) / 103,040 Gil",src="https://www.bg-wiki.com/ffxi/Plate_of_Indi-Paralysis"}, -- Indi-Paralysis
[828]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 34,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Fira"}, -- Fira
[830]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 46,440 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Blizzara"}, -- Blizzara
[834]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 7,476 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stonera"}, -- Stonera
[835]={tag="shop",tags={"shop","ah","drop","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 504,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Stonera_II"}, -- Stonera II
[836]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 54,600 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Thundara"}, -- Thundara
[838]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 21,000 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Watera"}, -- Watera
[839]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 530,265 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Watera_II"}, -- Watera II
[840]={tag="shop",tags={"shop","ah","bcnm"},note="Ledericus / Western Adoulin - (H-5) / 83,160 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Foil"}, -- Foil
[841]={tag="shop",tags={"shop","ah","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 18,032~20,384 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Distract"}, -- Distract
[843]={tag="shop",tags={"shop","ah","bcnm"},note="Tya Padolih / Mhaura - (G-9) / 25,038~28,304 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Frazzle"}, -- Frazzle
[845]={tag="shop",tags={"shop","ah","bcnm"},note="Falgima / Selbina - (H-9) / 30,360 Gil",src="https://www.bg-wiki.com/ffxi/Scroll_of_Flurry"}, -- Flurry
}

return M
