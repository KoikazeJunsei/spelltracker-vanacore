-- Where each corsair die is bought or found, read off BG-Wiki's die item pages (their "Purchased
-- From", "Dropped from" and "Obtained From" tables) by tools/make_dice_sources.py on 2026-11-25.
-- Keyed by die item id, the same ids as vana.gamedata.items. Each row keeps the page it was read from
-- in `src`, so every badge can be checked. `level` is the COR level the die's own description asks
-- for; `ability_id` is the Phantom Roll ability it teaches, which is what known-status is read for
-- out of vana.game.abilities(). A die with tag "none" has a page that names no source: the addon draws
-- its neutral badge rather than a guess. Don't edit: rerun the generator.
-- 31 dice with a row, 31 of them naming a place, 0 without a page. Don't edit: rerun the generator.
local M = {}

M.dice = {
[5477]={id=5477,name="Warrior Die",roll="Fighter's Roll",ability_id=98,level=49,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 68,000 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Warrior_Die"}, -- Warrior Die
[5478]={id=5478,name="Monk Die",roll="Monk's Roll",ability_id=99,level=31,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 22,400 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Monk_Die"}, -- Monk Die
[5479]={id=5479,name="White Mage Die",roll="Healer's Roll",ability_id=100,level=20,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 5,000 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/White_Mage_Die"}, -- White Mage Die
[5480]={id=5480,name="Black Mage Die",roll="Wizard's Roll",ability_id=101,level=58,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 108,000 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Black_Mage_Die"}, -- Black Mage Die
[5481]={id=5481,name="Red Mage Die",roll="Warlock's Roll",ability_id=102,level=46,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 62,000 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Red_Mage_Die"}, -- Red Mage Die
[5482]={id=5482,name="Thief Die",roll="Rogue's Roll",ability_id=103,level=43,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 50,400 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Thief_Die"}, -- Thief Die
[5483]={id=5483,name="Paladin Die",roll="Gallant's Roll",ability_id=104,level=55,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 90,750 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Paladin_Die"}, -- Paladin Die
[5484]={id=5484,name="Dark Knight Die",roll="Chaos Roll",ability_id=105,level=14,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 2,205 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Dark_Knight_Die"}, -- Dark Knight Die
[5485]={id=5485,name="Beastmaster Die",roll="Beast Roll",ability_id=106,level=34,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 26,600 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Beastmaster_Die"}, -- Beastmaster Die
[5486]={id=5486,name="Bard Die",roll="Choral Roll",ability_id=107,level=26,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 12,780 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Bard_Die"}, -- Bard Die
[5487]={id=5487,name="Ranger Die",roll="Hunter's Roll",ability_id=108,level=11,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 1,300 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Ranger_Die"}, -- Ranger Die
[5488]={id=5488,name="Samurai Die",roll="Samurai Roll",ability_id=109,level=37,tag="shop",tags={"shop","ah"},note="Jajaroon / Nashmau - (G-7) / 35,200 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Samurai_Die"}, -- Samurai Die
[5489]={id=5489,name="Ninja Die",roll="Ninja Roll",ability_id=110,level=8,tag="shop",tags={"shop","ah"},note="Jajaroon / Nashmau - (G-7) / 600 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Ninja_Die"}, -- Ninja Die
[5490]={id=5490,name="Dragoon Die",roll="Drachen Roll",ability_id=111,level=23,tag="shop",tags={"shop","ah"},note="Jajaroon / Nashmau - (G-7) / 9,216 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Dragoon_Die"}, -- Dragoon Die
[5491]={id=5491,name="Summoner Die",roll="Evoker's Roll",ability_id=112,level=40,tag="shop",tags={"shop","ah"},note="Jajaroon / Nashmau - (G-7) / 40,000 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Summoner_Die"}, -- Summoner Die
[5492]={id=5492,name="Blue Mage Die",roll="Magus's Roll",ability_id=113,level=17,tag="shop",tags={"shop","ah"},note="Jajaroon / Nashmau - (G-7) / 3,525 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Blue_Mage_Die"}, -- Blue Mage Die
[5493]={id=5493,name="Corsair Die",roll="Corsair's Roll",ability_id=114,level=5,tag="shop",tags={"shop","ah","quest"},note="Jajaroon / Nashmau - (G-7) / 316 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Corsair_Die"}, -- Corsair Die
[5494]={id=5494,name="Puppetmaster Die",roll="Puppet Roll",ability_id=115,level=52,tag="shop",tags={"shop","ah"},note="Jajaroon / Nashmau - (G-7) / 82,500 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Puppetmaster_Die"}, -- Puppetmaster Die
[5495]={id=5495,name="Dancer Die",roll="Dancer's Roll",ability_id=116,level=61,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 63,375 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Dancer_Die"}, -- Dancer Die
[5496]={id=5496,name="Scholar Die",roll="Scholar's Roll",ability_id=117,level=64,tag="shop",tags={"shop","ah"},note="Chayaya / Al Zahbi - (J-8) / 68,250 Gil",zone="Al Zahbi",src="https://www.bg-wiki.com/ffxi/Scholar_Die"}, -- Scholar Die
[5497]={id=5497,name="Bolter's Die",roll="Bolter's Roll",ability_id=118,level=76,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 99,225 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Bolter%27s_Die"}, -- Bolter's Die
[5498]={id=5498,name="Caster's Die",roll="Caster's Roll",ability_id=119,level=79,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 85,500 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Caster%27s_Die"}, -- Caster's Die
[5499]={id=5499,name="Courser's Die",roll="Courser's Roll",ability_id=120,level=81,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 97,350 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Courser%27s_Die"}, -- Courser's Die
[5500]={id=5500,name="Blitzer's Die",roll="Blitzer's Roll",ability_id=121,level=83,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 100,650 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Blitzer%27s_Die"}, -- Blitzer's Die
[5501]={id=5501,name="Tactician's Die",roll="Tactician's Roll",ability_id=122,level=86,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 109,440 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Tactician%27s_Die"}, -- Tactician's Die
[5502]={id=5502,name="Allies' Die",roll="Allies' Roll",ability_id=302,level=89,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 116,568 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Allies%27_Die"}, -- Allies' Die
[5503]={id=5503,name="Miser's Die",roll="Miser's Roll",ability_id=303,level=92,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 96,250 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Miser%27s_Die"}, -- Miser's Die
[5504]={id=5504,name="Companion's Die",roll="Companion's Roll",ability_id=304,level=95,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 95,800 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Companion%27s_Die"}, -- Companion's Die
[5505]={id=5505,name="Avenger's Die",roll="Avenger's Roll",ability_id=305,level=97,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 123,744 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Avenger%27s_Die"}, -- Avenger's Die
[6368]={id=6368,name="Geomancer Die",roll="Naturalist's Roll",ability_id=390,level=67,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 69,288 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Geomancer_Die"}, -- Geomancer Die
[6369]={id=6369,name="Rune Fencer Die",roll="Runeist's Roll",ability_id=391,level=70,tag="shop",tags={"shop","ah"},note="Chichiroon / Nashmau - (G-7) / 73,920 Gil",zone="Nashmau",src="https://www.bg-wiki.com/ffxi/Rune_Fencer_Die"}, -- Rune Fencer Die
}

return M
