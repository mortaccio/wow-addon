local _, GT = ...

--[[
PvP cooldown dataset sync
Source: OmniCD Retail Spells_Mainline.lua
Snapshot date: 2026-02-25
Normalization:
- OmniCD types are mapped into Gladtools buckets and categories.
- Enemy cooldown timers are still event-driven estimates (Blizzard API does not expose enemy cooldowns directly).
- TODO: Apply talent/spec modifier tables from Modifiers_Mainline.lua when talent certainty is available.
]]

GT.CooldownData = {
    DEATHKNIGHT = {
        interrupts = {
            { spellID = 47482, defaultCD = 30, category = "interrupt", priority = 100, icon = 237569, name = "Leap", sourceType = "interrupt", specs = { 252 } },
            { spellID = 47528, defaultCD = 15, category = "interrupt", priority = 100, icon = 237527, name = "Mind Freeze", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 51052, defaultCD = 240, category = "defensive", priority = 93, icon = 237510, name = "Anti-Magic Zone", sourceType = "raidDefensive" },
            { spellID = 48707, defaultCD = 60, category = "defensive", priority = 92, icon = 136120, name = "Anti-Magic Shell", sourceType = "defensive" },
            { spellID = 48743, defaultCD = 120, category = "defensive", priority = 92, icon = 136146, name = "Death Pact", sourceType = "defensive" },
            { spellID = 48792, defaultCD = 120, category = "defensive", priority = 92, icon = 237525, name = "Icebound Fortitude", sourceType = "defensive" },
            { spellID = 49028, defaultCD = 120, category = "defensive", priority = 88, icon = 135277, name = "Dancing Rune Weapon", sourceType = "tankDefensive" },
            { spellID = 55233, defaultCD = 90, category = "defensive", priority = 88, icon = 136168, name = "Vampiric Blood", sourceType = "tankDefensive" },
            { spellID = 114556, defaultCD = 240, category = "defensive", priority = 88, icon = 134430, name = "Purgatory", sourceType = "tankDefensive" },
            { spellID = 194679, defaultCD = 25, category = "defensive", priority = 88, icon = 237529, name = "Rune Tap", sourceType = "tankDefensive", maxCharges = 2 },
            { spellID = 219809, defaultCD = 60, category = "defensive", priority = 88, icon = 132151, name = "Tombstone", sourceType = "tankDefensive" },
            { spellID = 274156, defaultCD = 30, category = "defensive", priority = 88, icon = 1121487, name = "Consumption", sourceType = "tankDefensive" },
            { spellID = 327574, defaultCD = 120, category = "defensive", priority = 88, icon = 136133, name = "Sacrificial Pact", sourceType = "tankDefensive" },
            { spellID = 49039, defaultCD = 120, category = "defensive", priority = 86, icon = 136187, name = "Lichborne", sourceType = "counterCC" },
            { spellID = 206931, defaultCD = 30, category = "defensive", priority = 84, icon = 838812, name = "Blooddrinker", sourceType = "heal" },
        },
        offensives = {
            { spellID = 42650, defaultCD = 180, category = "offensive", priority = 82, icon = 237511, name = "Army of the Dead", sourceType = "offensive" },
            { spellID = 46585, defaultCD = 120, category = "offensive", priority = 82, icon = 1100170, name = "Raise Dead", sourceType = "offensive" },
            { spellID = 47568, defaultCD = 30, category = "offensive", priority = 82, icon = 135372, name = "Empower Rune Weapon", sourceType = "offensive", maxCharges = 2 },
            { spellID = 49206, defaultCD = 180, category = "offensive", priority = 82, icon = 458967, name = "Summon Gargoyle", sourceType = "offensive" },
            { spellID = 51271, defaultCD = 45, category = "offensive", priority = 82, icon = 458718, name = "Pillar of Frost", sourceType = "offensive" },
            { spellID = 63560, defaultCD = 45, category = "offensive", priority = 82, icon = 342913, name = "Dark Transformation", sourceType = "offensive" },
            { spellID = 194844, defaultCD = 60, category = "offensive", priority = 82, icon = 342917, name = "Bonestorm", sourceType = "offensive" },
            { spellID = 196770, defaultCD = 20, category = "offensive", priority = 82, icon = 538770, name = "Remorseless Winter", sourceType = "offensive", specs = { 251 } },
            { spellID = 203173, defaultCD = 30, category = "offensive", priority = 82, icon = 1390941, name = "Death Chain", sourceType = "offensive" },
            { spellID = 207018, defaultCD = 20, category = "offensive", priority = 82, icon = 136088, name = "Murderous Intent", sourceType = "offensive" },
            { spellID = 207289, defaultCD = 90, category = "offensive", priority = 82, icon = 136224, name = "Unholy Assault", sourceType = "offensive" },
            { spellID = 275699, defaultCD = 45, category = "offensive", priority = 82, icon = 1392565, name = "Apocalypse", sourceType = "offensive" },
            { spellID = 383269, defaultCD = 90, category = "offensive", priority = 82, icon = 3578196, name = "Legion of Souls", sourceType = "offensive" },
            { spellID = 439843, defaultCD = 45, category = "offensive", priority = 82, icon = 5927621, name = "Reaper's Mark", sourceType = "offensive" },
            { spellID = 455395, defaultCD = 90, category = "offensive", priority = 82, icon = 298667, name = "Raise Abomination", sourceType = "offensive" },
            { spellID = 1249658, defaultCD = 90, category = "offensive", priority = 82, icon = 1029007, name = "Breath of Sindragosa", sourceType = "offensive" },
        },
        utility = {
            { spellID = 108199, defaultCD = 120, category = "utility", priority = 74, icon = 538767, name = "Gorefiend's Grasp", sourceType = "aoeCC" },
            { spellID = 207167, defaultCD = 60, category = "utility", priority = 74, icon = 135836, name = "Blinding Sleet", sourceType = "aoeCC" },
            { spellID = 279302, defaultCD = 90, category = "utility", priority = 74, icon = 341980, name = "Frostwyrm's Fury", sourceType = "aoeCC" },
            { spellID = 47481, defaultCD = 90, category = "utility", priority = 73, icon = 237524, name = "Gnaw", sourceType = "cc", specs = { 252 } },
            { spellID = 221562, defaultCD = 45, category = "utility", priority = 73, icon = 538558, name = "Asphyxiate", sourceType = "cc" },
            { spellID = 47476, defaultCD = 45, category = "utility", priority = 71, icon = 136214, name = "Strangulate", sourceType = "disarm" },
            { spellID = 49576, defaultCD = 15, category = "utility", priority = 71, icon = 237532, name = "Death Grip", sourceType = "disarm" },
            { spellID = 212552, defaultCD = 60, category = "utility", priority = 69, icon = 1100041, name = "Wraith Walk", sourceType = "freedom" },
            { spellID = 444347, defaultCD = 45, category = "utility", priority = 69, icon = 852890, name = "Death Charge", sourceType = "freedom" },
            { spellID = 48265, defaultCD = 45, category = "utility", priority = 62, icon = 237561, name = "Death's Advance", sourceType = "movement" },
            { spellID = 77606, defaultCD = 20, category = "utility", priority = 60, icon = 135888, name = "Dark Simulacrum", sourceType = "other" },
            { spellID = 221699, defaultCD = 60, category = "utility", priority = 60, icon = 237515, name = "Blood Tap", sourceType = "other", maxCharges = 2 },
            { spellID = 56222, defaultCD = 8, category = "utility", priority = 42, icon = 136088, name = "Dark Command", sourceType = "taunt" },
        },
        trinkets = {
        },
    },
    DEMONHUNTER = {
        interrupts = {
            { spellID = 183752, defaultCD = 15, category = "interrupt", priority = 100, icon = 1305153, name = "Disrupt", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 196555, defaultCD = 180, category = "defensive", priority = 96, icon = 463284, name = "Netherwalk", sourceType = "immunity" },
            { spellID = 196718, defaultCD = 300, category = "defensive", priority = 93, icon = 1305154, name = "Darkness", sourceType = "raidDefensive" },
            { spellID = 198589, defaultCD = 60, category = "defensive", priority = 92, icon = 1305150, name = "Blur", sourceType = "defensive", specs = { 577 } },
            { spellID = 206803, defaultCD = 90, category = "defensive", priority = 92, icon = 1380371, name = "Rain from Above", sourceType = "defensive" },
            { spellID = 187827, defaultCD = 180, category = "defensive", priority = 88, icon = 1247262, name = "Metamorphosis", sourceType = "tankDefensive", specs = { 581 } },
            { spellID = 203720, defaultCD = 20, category = "defensive", priority = 88, icon = 1344645, name = "Demon Spikes", sourceType = "tankDefensive", specs = { 581 }, maxCharges = 2 },
            { spellID = 204021, defaultCD = 60, category = "defensive", priority = 88, icon = 1344647, name = "Fiery Brand", sourceType = "tankDefensive" },
            { spellID = 209258, defaultCD = 480, category = "defensive", priority = 88, icon = 1348655, name = "Last Resort", sourceType = "tankDefensive" },
            { spellID = 263648, defaultCD = 30, category = "defensive", priority = 88, icon = 2065625, name = "Soul Barrier", sourceType = "tankDefensive" },
            { spellID = 205604, defaultCD = 60, category = "defensive", priority = 86, icon = 1380372, name = "Reverse Magic", sourceType = "counterCC" },
        },
        offensives = {
            { spellID = 191427, defaultCD = 180, category = "offensive", priority = 82, icon = 1247262, name = "Metamorphosis", sourceType = "offensive", specs = { 577 } },
            { spellID = 198013, defaultCD = 40, category = "offensive", priority = 82, icon = 1305156, name = "Eye Beam", sourceType = "offensive" },
            { spellID = 204596, defaultCD = 30, category = "offensive", priority = 82, icon = 1344652, name = "Sigil of Flame", sourceType = "offensive" },
            { spellID = 207029, defaultCD = 20, category = "offensive", priority = 82, icon = 1344654, name = "Tormentor", sourceType = "offensive" },
            { spellID = 207407, defaultCD = 60, category = "offensive", priority = 82, icon = 1309072, name = "Soul Carver", sourceType = "offensive" },
            { spellID = 212084, defaultCD = 40, category = "offensive", priority = 82, icon = 1450143, name = "Fel Devastation", sourceType = "offensive" },
            { spellID = 258860, defaultCD = 40, category = "offensive", priority = 82, icon = 136189, name = "Essence Break", sourceType = "offensive" },
            { spellID = 258920, defaultCD = 30, category = "offensive", priority = 82, icon = 1344649, name = "Immolation Aura", sourceType = "offensive", cooldownBySpec = { [581] = 15 } },
            { spellID = 258925, defaultCD = 90, category = "offensive", priority = 82, icon = 2065580, name = "Fel Barrage", sourceType = "offensive" },
            { spellID = 320341, defaultCD = 60, category = "offensive", priority = 82, icon = 136194, name = "Bulk Extraction", sourceType = "offensive" },
            { spellID = 342817, defaultCD = 25, category = "offensive", priority = 82, icon = 1455916, name = "Glaive Tempest", sourceType = "offensive" },
            { spellID = 370965, defaultCD = 90, category = "offensive", priority = 82, icon = 6035307, name = "The Hunt", sourceType = "offensive" },
            { spellID = 390163, defaultCD = 60, category = "offensive", priority = 82, icon = 6035306, name = "Sigil of Spite", sourceType = "offensive" },
        },
        utility = {
            { spellID = 179057, defaultCD = 45, category = "utility", priority = 74, icon = 135795, name = "Chaos Nova", sourceType = "aoeCC" },
            { spellID = 202137, defaultCD = 90, category = "utility", priority = 74, icon = 1418288, name = "Sigil of Silence", sourceType = "aoeCC" },
            { spellID = 202138, defaultCD = 60, category = "utility", priority = 74, icon = 1418286, name = "Sigil of Chains", sourceType = "aoeCC" },
            { spellID = 207684, defaultCD = 120, category = "utility", priority = 74, icon = 1418287, name = "Sigil of Misery", sourceType = "aoeCC" },
            { spellID = 205630, defaultCD = 60, category = "utility", priority = 73, icon = 1380367, name = "Illidan's Grasp", sourceType = "cc" },
            { spellID = 211881, defaultCD = 30, category = "utility", priority = 73, icon = 1118739, name = "Fel Eruption", sourceType = "cc", specs = { 577 } },
            { spellID = 217832, defaultCD = 45, category = "utility", priority = 73, icon = 1380368, name = "Imprison", sourceType = "cc" },
            { spellID = 205625, defaultCD = 30, category = "utility", priority = 70, icon = 1344649, name = "Cleansed by Flame", sourceType = "dispel", cooldownBySpec = { [581] = 15 } },
            { spellID = 278326, defaultCD = 10, category = "utility", priority = 70, icon = 828455, name = "Consume Magic", sourceType = "dispel" },
            { spellID = 189110, defaultCD = 20, category = "utility", priority = 62, icon = 1344650, name = "Infernal Strike", sourceType = "movement", specs = { 581 } },
            { spellID = 195072, defaultCD = 10, category = "utility", priority = 62, icon = 1247261, name = "Fel Rush", sourceType = "movement", specs = { 577 } },
            { spellID = 198793, defaultCD = 25, category = "utility", priority = 62, icon = 1348401, name = "Vengeful Retreat", sourceType = "movement" },
            { spellID = 205629, defaultCD = 20, category = "utility", priority = 62, icon = 134294, name = "Demonic Trample", sourceType = "movement" },
            { spellID = 232893, defaultCD = 15, category = "utility", priority = 62, icon = 1344646, name = "Felblade", sourceType = "movement" },
            { spellID = 188501, defaultCD = 30, category = "utility", priority = 60, icon = 1247266, name = "Spectral Sight", sourceType = "other" },
            { spellID = 185245, defaultCD = 8, category = "utility", priority = 42, icon = 1344654, name = "Torment", sourceType = "taunt" },
        },
        trinkets = {
        },
    },
    DRUID = {
        interrupts = {
            { spellID = 78675, defaultCD = 60, category = "interrupt", priority = 100, icon = 252188, name = "Solar Beam", sourceType = "interrupt" },
            { spellID = 106839, defaultCD = 15, category = "interrupt", priority = 100, icon = 236946, name = "Skull Bash", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 102342, defaultCD = 90, category = "defensive", priority = 95, icon = 572025, name = "Ironbark", sourceType = "externalDefensive" },
            { spellID = 740, defaultCD = 180, category = "defensive", priority = 93, icon = 136107, name = "Tranquility", sourceType = "raidDefensive" },
            { spellID = 124974, defaultCD = 90, category = "defensive", priority = 93, icon = 236764, name = "Nature's Vigil", sourceType = "raidDefensive" },
            { spellID = 22812, defaultCD = 60, category = "defensive", priority = 92, icon = 136097, name = "Barkskin", sourceType = "defensive", cooldownBySpec = { [104] = 45 } },
            { spellID = 61336, defaultCD = 180, category = "defensive", priority = 92, icon = 236169, name = "Survival Instincts", sourceType = "defensive" },
            { spellID = 377847, defaultCD = 120, category = "defensive", priority = 92, icon = 236169, name = "Well-Honed Instincts", sourceType = "defensive" },
            { spellID = 80313, defaultCD = 45, category = "defensive", priority = 88, icon = 1033490, name = "Pulverize", sourceType = "tankDefensive" },
            { spellID = 200851, defaultCD = 60, category = "defensive", priority = 88, icon = 1129695, name = "Rage of the Sleeper", sourceType = "tankDefensive" },
            { spellID = 201664, defaultCD = 30, category = "defensive", priority = 88, icon = 132117, name = "Demoralizing Roar", sourceType = "tankDefensive" },
            { spellID = 354654, defaultCD = 60, category = "defensive", priority = 88, icon = 4067364, name = "Grove Protection", sourceType = "tankDefensive" },
            { spellID = 22842, defaultCD = 36, category = "defensive", priority = 84, icon = 132091, name = "Frenzied Regeneration", sourceType = "heal" },
            { spellID = 33891, defaultCD = 180, category = "defensive", priority = 84, icon = 236157, name = "Incarnation: Tree of Life", sourceType = "heal" },
            { spellID = 102351, defaultCD = 30, category = "defensive", priority = 84, icon = 132137, name = "Cenarion Ward", sourceType = "heal" },
            { spellID = 102693, defaultCD = 20, category = "defensive", priority = 84, icon = 132129, name = "Grove Guardians", sourceType = "heal", maxCharges = 3 },
            { spellID = 108238, defaultCD = 90, category = "defensive", priority = 84, icon = 136059, name = "Renewal", sourceType = "heal" },
            { spellID = 197721, defaultCD = 60, category = "defensive", priority = 84, icon = 538743, name = "Flourish", sourceType = "heal" },
            { spellID = 203651, defaultCD = 60, category = "defensive", priority = 84, icon = 1408836, name = "Overgrowth", sourceType = "heal" },
            { spellID = 204066, defaultCD = 60, category = "defensive", priority = 84, icon = 136057, name = "Lunar Beam", sourceType = "heal" },
            { spellID = 391888, defaultCD = 25, category = "defensive", priority = 84, icon = 6035308, name = "Adaptive Swarm", sourceType = "heal" },
            { spellID = 392160, defaultCD = 20, category = "defensive", priority = 84, icon = 136073, name = "Invigorate", sourceType = "heal" },
            { spellID = 473909, defaultCD = 90, category = "defensive", priority = 84, icon = 874857, name = "Ancient of Lore", sourceType = "heal" },
        },
        offensives = {
            { spellID = 5217, defaultCD = 30, category = "offensive", priority = 82, icon = 132242, name = "Tiger's Fury", sourceType = "offensive" },
            { spellID = 50334, defaultCD = 180, category = "offensive", priority = 82, icon = 236149, name = "Berserk", sourceType = "offensive" },
            { spellID = 88747, defaultCD = 30, category = "offensive", priority = 82, icon = 464341, name = "Wild Mushroom", sourceType = "offensive", maxCharges = 3 },
            { spellID = 102543, defaultCD = 180, category = "offensive", priority = 82, icon = 571586, name = "Incarnation: Avatar of Ashamane", sourceType = "offensive" },
            { spellID = 102558, defaultCD = 180, category = "offensive", priority = 82, icon = 571586, name = "Incarnation: Guardian of Ursoc", sourceType = "offensive" },
            { spellID = 102560, defaultCD = 180, category = "offensive", priority = 82, icon = 571586, name = "Incarnation: Chosen of Elune", sourceType = "offensive" },
            { spellID = 106951, defaultCD = 180, category = "offensive", priority = 82, icon = 236149, name = "Berserk", sourceType = "offensive" },
            { spellID = 194223, defaultCD = 180, category = "offensive", priority = 82, icon = 136060, name = "Celestial Alignment", sourceType = "offensive" },
            { spellID = 202425, defaultCD = 45, category = "offensive", priority = 82, icon = 135900, name = "Warrior of Elune", sourceType = "offensive" },
            { spellID = 202770, defaultCD = 60, category = "offensive", priority = 82, icon = 132123, name = "Fury of Elune", sourceType = "offensive" },
            { spellID = 207017, defaultCD = 20, category = "offensive", priority = 82, icon = 132270, name = "Alpha Challenge", sourceType = "offensive" },
            { spellID = 274281, defaultCD = 20, category = "offensive", priority = 82, icon = 1392545, name = "New Moon", sourceType = "offensive", maxCharges = 3 },
            { spellID = 274837, defaultCD = 45, category = "offensive", priority = 82, icon = 132140, name = "Feral Frenzy", sourceType = "offensive" },
            { spellID = 319454, defaultCD = 300, category = "offensive", priority = 82, icon = 135879, name = "Heart of the Wild", sourceType = "offensive" },
            { spellID = 391528, defaultCD = 120, category = "offensive", priority = 82, icon = 6035309, name = "Convoke the Spirits", sourceType = "offensive" },
        },
        utility = {
            { spellID = 99, defaultCD = 30, category = "utility", priority = 74, icon = 132121, name = "Incapacitating Roar", sourceType = "aoeCC" },
            { spellID = 132469, defaultCD = 30, category = "utility", priority = 74, icon = 236170, name = "Typhoon", sourceType = "aoeCC" },
            { spellID = 5211, defaultCD = 60, category = "utility", priority = 73, icon = 132114, name = "Mighty Bash", sourceType = "cc" },
            { spellID = 22570, defaultCD = 30, category = "utility", priority = 73, icon = 132134, name = "Maim", sourceType = "cc" },
            { spellID = 202246, defaultCD = 25, category = "utility", priority = 73, icon = 1408833, name = "Overrun", sourceType = "cc" },
            { spellID = 102359, defaultCD = 30, category = "utility", priority = 71, icon = 538515, name = "Mass Entanglement", sourceType = "disarm" },
            { spellID = 102793, defaultCD = 60, category = "utility", priority = 71, icon = 571588, name = "Ursol's Vortex", sourceType = "disarm" },
            { spellID = 209749, defaultCD = 30, category = "utility", priority = 71, icon = 538516, name = "Faerie Swarm", sourceType = "disarm" },
            { spellID = 2782, defaultCD = 8, category = "utility", priority = 70, icon = 135952, name = "Remove Corruption", sourceType = "dispel" },
            { spellID = 2908, defaultCD = 10, category = "utility", priority = 70, icon = 132163, name = "Soothe", sourceType = "dispel" },
            { spellID = 88423, defaultCD = 8, category = "utility", priority = 70, icon = 236288, name = "Nature's Cure", sourceType = "dispel", specs = { 105 } },
            { spellID = 106898, defaultCD = 120, category = "utility", priority = 64, icon = 464343, name = "Stampeding Roar", sourceType = "raidMovement" },
            { spellID = 1850, defaultCD = 120, category = "utility", priority = 62, icon = 132120, name = "Dash", sourceType = "movement" },
            { spellID = 102401, defaultCD = 15, category = "utility", priority = 62, icon = 538771, name = "Wild Charge", sourceType = "movement" },
            { spellID = 252216, defaultCD = 45, category = "utility", priority = 62, icon = 1817485, name = "Tiger Dash", sourceType = "movement" },
            { spellID = 5215, defaultCD = 6, category = "utility", priority = 60, icon = 514640, name = "Prowl", sourceType = "other" },
            { spellID = 29166, defaultCD = 180, category = "utility", priority = 60, icon = 136048, name = "Innervate", sourceType = "other" },
            { spellID = 132158, defaultCD = 60, category = "utility", priority = 60, icon = 136076, name = "Nature's Swiftness", sourceType = "other" },
            { spellID = 155835, defaultCD = 40, category = "utility", priority = 60, icon = 1033476, name = "Bristling Fur", sourceType = "other" },
            { spellID = 202359, defaultCD = 60, category = "utility", priority = 60, icon = 611423, name = "Astral Communion", sourceType = "other" },
            { spellID = 329042, defaultCD = 120, category = "utility", priority = 60, icon = 1394953, name = "Emerald Slumber", sourceType = "other" },
            { spellID = 6795, defaultCD = 8, category = "utility", priority = 42, icon = 132270, name = "Growl", sourceType = "taunt" },
            { spellID = 205636, defaultCD = 60, category = "utility", priority = 42, icon = 132129, name = "Force of Nature", sourceType = "taunt" },
        },
        trinkets = {
        },
    },
    EVOKER = {
        interrupts = {
            { spellID = 351338, defaultCD = 40, category = "interrupt", priority = 100, icon = 4622469, name = "Quell", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 378441, defaultCD = 45, category = "defensive", priority = 96, icon = 4631367, name = "Time Stop", sourceType = "immunity" },
            { spellID = 357170, defaultCD = 60, category = "defensive", priority = 95, icon = 4622478, name = "Time Dilation", sourceType = "externalDefensive" },
            { spellID = 360827, defaultCD = 30, category = "defensive", priority = 95, icon = 5199621, name = "Blistering Scales", sourceType = "externalDefensive" },
            { spellID = 368412, defaultCD = 60, category = "defensive", priority = 95, icon = 4630462, name = "Time of Need", sourceType = "externalDefensive" },
            { spellID = 363534, defaultCD = 240, category = "defensive", priority = 93, icon = 4622474, name = "Rewind", sourceType = "raidDefensive" },
            { spellID = 374227, defaultCD = 120, category = "defensive", priority = 93, icon = 4630449, name = "Zephyr", sourceType = "raidDefensive" },
            { spellID = 363916, defaultCD = 90, category = "defensive", priority = 92, icon = 1394891, name = "Obsidian Scales", sourceType = "defensive" },
            { spellID = 374348, defaultCD = 90, category = "defensive", priority = 92, icon = 4630463, name = "Renewing Blaze", sourceType = "defensive" },
            { spellID = 404381, defaultCD = 360, category = "defensive", priority = 92, icon = 5199625, name = "Defy Fate", sourceType = "defensive" },
            { spellID = 355913, defaultCD = 30, category = "defensive", priority = 84, icon = 4622457, name = "Emerald Blossom", sourceType = "heal" },
            { spellID = 355936, defaultCD = 30, category = "defensive", priority = 84, icon = 4622454, name = "Dream Breath", sourceType = "heal" },
            { spellID = 359816, defaultCD = 120, category = "defensive", priority = 84, icon = 4622455, name = "Dream Flight", sourceType = "heal" },
            { spellID = 360995, defaultCD = 24, category = "defensive", priority = 84, icon = 4622471, name = "Verdant Embrace", sourceType = "heal", cooldownBySpec = { [1468] = 18 } },
            { spellID = 367226, defaultCD = 30, category = "defensive", priority = 84, icon = 4622476, name = "Spiritbloom", sourceType = "heal" },
            { spellID = 370960, defaultCD = 180, category = "defensive", priority = 84, icon = 4630447, name = "Emerald Communion", sourceType = "heal" },
        },
        offensives = {
            { spellID = 357208, defaultCD = 30, category = "offensive", priority = 82, icon = 4622458, name = "Fire Breath", sourceType = "offensive" },
            { spellID = 357210, defaultCD = 120, category = "offensive", priority = 82, icon = 4622450, name = "Deep Breath", sourceType = "offensive" },
            { spellID = 359073, defaultCD = 30, category = "offensive", priority = 82, icon = 4630444, name = "Eternity Surge", sourceType = "offensive" },
            { spellID = 368847, defaultCD = 20, category = "offensive", priority = 82, icon = 4622459, name = "Firestorm", sourceType = "offensive" },
            { spellID = 370452, defaultCD = 20, category = "offensive", priority = 82, icon = 4622449, name = "Shattering Star", sourceType = "offensive" },
            { spellID = 375087, defaultCD = 120, category = "offensive", priority = 82, icon = 4622452, name = "Dragonrage", sourceType = "offensive" },
            { spellID = 390386, defaultCD = 300, category = "offensive", priority = 82, icon = 4723908, name = "Fury of the Aspects", sourceType = "offensive" },
            { spellID = 395152, defaultCD = 30, category = "offensive", priority = 82, icon = 5061347, name = "Ebon Might", sourceType = "offensive" },
            { spellID = 403631, defaultCD = 120, category = "offensive", priority = 82, icon = 5199622, name = "Breath of Eons", sourceType = "offensive" },
            { spellID = 443328, defaultCD = 27, category = "offensive", priority = 82, icon = 5927629, name = "Engulf", sourceType = "offensive" },
        },
        utility = {
            { spellID = 368970, defaultCD = 180, category = "utility", priority = 74, icon = 4622486, name = "Tail Swipe", sourceType = "aoeCC" },
            { spellID = 371032, defaultCD = 120, category = "utility", priority = 74, icon = 4622477, name = "Terror of the Skies", sourceType = "aoeCC" },
            { spellID = 396286, defaultCD = 40, category = "utility", priority = 74, icon = 5199647, name = "Upheaval", sourceType = "aoeCC" },
            { spellID = 372048, defaultCD = 120, category = "utility", priority = 73, icon = 4622466, name = "Oppressing Roar", sourceType = "cc" },
            { spellID = 358385, defaultCD = 90, category = "utility", priority = 71, icon = 1016245, name = "Landslide", sourceType = "disarm" },
            { spellID = 370388, defaultCD = 90, category = "utility", priority = 71, icon = 4622446, name = "Swoop Up", sourceType = "disarm" },
            { spellID = 383005, defaultCD = 45, category = "utility", priority = 71, icon = 4630470, name = "Chrono Loop", sourceType = "disarm" },
            { spellID = 360823, defaultCD = 8, category = "utility", priority = 70, icon = 4630445, name = "Naturalize", sourceType = "dispel", specs = { 1468 } },
            { spellID = 365585, defaultCD = 8, category = "utility", priority = 70, icon = 4630445, name = "Expunge", sourceType = "dispel" },
            { spellID = 374251, defaultCD = 60, category = "utility", priority = 70, icon = 4630446, name = "Cauterizing Flame", sourceType = "dispel" },
            { spellID = 377509, defaultCD = 60, category = "utility", priority = 70, icon = 4622475, name = "Dream Projection", sourceType = "dispel" },
            { spellID = 358267, defaultCD = 35, category = "utility", priority = 62, icon = 4622463, name = "Hover", sourceType = "movement" },
            { spellID = 370665, defaultCD = 60, category = "utility", priority = 62, icon = 4622460, name = "Rescue", sourceType = "movement" },
            { spellID = 370537, defaultCD = 90, category = "utility", priority = 60, icon = 4630476, name = "Stasis", sourceType = "other" },
            { spellID = 370553, defaultCD = 120, category = "utility", priority = 60, icon = 4622480, name = "Tip the Scales", sourceType = "other" },
            { spellID = 374968, defaultCD = 120, category = "utility", priority = 60, icon = 4622479, name = "Time Spiral", sourceType = "other" },
            { spellID = 404977, defaultCD = 177, category = "utility", priority = 60, icon = 5201905, name = "Time Skip", sourceType = "other" },
            { spellID = 406732, defaultCD = 180, category = "utility", priority = 60, icon = 5199645, name = "Spatial Paradox", sourceType = "other" },
        },
        trinkets = {
        },
    },
    HUNTER = {
        interrupts = {
            { spellID = 147362, defaultCD = 24, category = "interrupt", priority = 100, icon = 249170, name = "Counter Shot", sourceType = "interrupt" },
            { spellID = 187707, defaultCD = 15, category = "interrupt", priority = 100, icon = 1376045, name = "Muzzle", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 186265, defaultCD = 180, category = "defensive", priority = 96, icon = 132199, name = "Aspect of the Turtle", sourceType = "immunity" },
            { spellID = 53480, defaultCD = 60, category = "defensive", priority = 95, icon = 464604, name = "Roar of Sacrifice", sourceType = "externalDefensive" },
            { spellID = 264735, defaultCD = 120, category = "defensive", priority = 92, icon = 136094, name = "Survival of the Fittest", sourceType = "defensive" },
            { spellID = 472707, defaultCD = 90, category = "defensive", priority = 92, icon = 1738657, name = "Shell Cover", sourceType = "defensive" },
            { spellID = 109304, defaultCD = 120, category = "defensive", priority = 84, icon = 461117, name = "Exhilaration", sourceType = "heal" },
        },
        offensives = {
            { spellID = 19574, defaultCD = 90, category = "offensive", priority = 82, icon = 132127, name = "Bestial Wrath", sourceType = "offensive" },
            { spellID = 203415, defaultCD = 45, category = "offensive", priority = 82, icon = 1239829, name = "Fury of the Eagle", sourceType = "offensive" },
            { spellID = 208652, defaultCD = 30, category = "offensive", priority = 82, icon = 612363, name = "Dire Beast: Hawk", sourceType = "offensive" },
            { spellID = 212431, defaultCD = 30, category = "offensive", priority = 82, icon = 236178, name = "Explosive Shot", sourceType = "offensive" },
            { spellID = 257044, defaultCD = 20, category = "offensive", priority = 82, icon = 461115, name = "Rapid Fire", sourceType = "offensive" },
            { spellID = 260243, defaultCD = 45, category = "offensive", priority = 82, icon = 132205, name = "Volley", sourceType = "offensive" },
            { spellID = 269751, defaultCD = 30, category = "offensive", priority = 82, icon = 236184, name = "Flanking Strike", sourceType = "offensive" },
            { spellID = 288613, defaultCD = 120, category = "offensive", priority = 82, icon = 132329, name = "Trueshot", sourceType = "offensive" },
            { spellID = 321530, defaultCD = 60, category = "offensive", priority = 82, icon = 132139, name = "Bloodshed", sourceType = "offensive" },
            { spellID = 356707, defaultCD = 60, category = "offensive", priority = 82, icon = 236159, name = "Wild Kingdom", sourceType = "offensive" },
            { spellID = 359844, defaultCD = 120, category = "offensive", priority = 82, icon = 4667415, name = "Call of the Wild", sourceType = "offensive" },
            { spellID = 360952, defaultCD = 120, category = "offensive", priority = 82, icon = 2032587, name = "Coordinated Assault", sourceType = "offensive" },
            { spellID = 360966, defaultCD = 90, category = "offensive", priority = 82, icon = 4667416, name = "Spearhead", sourceType = "offensive" },
            { spellID = 466904, defaultCD = 300, category = "offensive", priority = 82, icon = 6352455, name = "Harrier's Cry", sourceType = "offensive" },
        },
        utility = {
            { spellID = 109248, defaultCD = 45, category = "utility", priority = 74, icon = 462650, name = "Binding Shot", sourceType = "aoeCC" },
            { spellID = 186387, defaultCD = 30, category = "utility", priority = 74, icon = 1376038, name = "Bursting Shot", sourceType = "aoeCC" },
            { spellID = 236776, defaultCD = 40, category = "utility", priority = 74, icon = 135826, name = "High Explosive Trap", sourceType = "aoeCC" },
            { spellID = 462031, defaultCD = 60, category = "utility", priority = 74, icon = 1044088, name = "Implosive Trap", sourceType = "aoeCC" },
            { spellID = 19577, defaultCD = 60, category = "utility", priority = 73, icon = 132111, name = "Intimidation", sourceType = "cc" },
            { spellID = 187650, defaultCD = 30, category = "utility", priority = 73, icon = 135834, name = "Freezing Trap", sourceType = "cc" },
            { spellID = 213691, defaultCD = 30, category = "utility", priority = 73, icon = 132153, name = "Scatter Shot", sourceType = "cc" },
            { spellID = 474421, defaultCD = 60, category = "utility", priority = 73, icon = 1392564, name = "Intimidation", sourceType = "cc" },
            { spellID = 212638, defaultCD = 25, category = "utility", priority = 71, icon = 1412207, name = "Tracker's Net", sourceType = "disarm" },
            { spellID = 356719, defaultCD = 60, category = "utility", priority = 71, icon = 132211, name = "Chimaeral Sting", sourceType = "disarm" },
            { spellID = 407028, defaultCD = 45, category = "utility", priority = 71, icon = 5094557, name = "Sticky Tar Bomb", sourceType = "disarm" },
            { spellID = 19801, defaultCD = 10, category = "utility", priority = 70, icon = 136020, name = "Tranquilizing Shot", sourceType = "dispel" },
            { spellID = 212640, defaultCD = 25, category = "utility", priority = 70, icon = 1014022, name = "Mending Bandage", sourceType = "dispel" },
            { spellID = 781, defaultCD = 20, category = "utility", priority = 62, icon = 132294, name = "Disengage", sourceType = "movement" },
            { spellID = 186257, defaultCD = 180, category = "utility", priority = 62, icon = 132242, name = "Aspect of the Cheetah", sourceType = "movement" },
            { spellID = 190925, defaultCD = 30, category = "utility", priority = 62, icon = 1376040, name = "Harpoon", sourceType = "movement", specs = { 255 } },
            { spellID = 272651, defaultCD = 45, category = "utility", priority = 62, icon = 457329, name = "Command Pet", sourceType = "movement" },
            { spellID = 1543, defaultCD = 20, category = "utility", priority = 60, icon = 135815, name = "Flare", sourceType = "other" },
            { spellID = 5384, defaultCD = 30, category = "utility", priority = 60, icon = 132293, name = "Feign Death", sourceType = "other" },
            { spellID = 34477, defaultCD = 30, category = "utility", priority = 60, icon = 132180, name = "Misdirection", sourceType = "other" },
            { spellID = 186289, defaultCD = 90, category = "utility", priority = 60, icon = 612363, name = "Aspect of the Eagle", sourceType = "other", specs = { 255 } },
            { spellID = 187698, defaultCD = 30, category = "utility", priority = 60, icon = 576309, name = "Tar Trap", sourceType = "other" },
            { spellID = 199483, defaultCD = 60, category = "utility", priority = 60, icon = 461113, name = "Camouflage", sourceType = "other" },
        },
        trinkets = {
        },
    },
    MAGE = {
        interrupts = {
            { spellID = 2139, defaultCD = 24, category = "interrupt", priority = 100, icon = 135856, name = "Counterspell", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 45438, defaultCD = 240, category = "defensive", priority = 96, icon = 135841, name = "Ice Block", sourceType = "immunity" },
            { spellID = 414660, defaultCD = 180, category = "defensive", priority = 93, icon = 1723997, name = "Mass Barrier", sourceType = "raidDefensive" },
            { spellID = 11426, defaultCD = 25, category = "defensive", priority = 92, icon = 135988, name = "Ice Barrier", sourceType = "defensive" },
            { spellID = 55342, defaultCD = 120, category = "defensive", priority = 92, icon = 135994, name = "Mirror Image", sourceType = "defensive" },
            { spellID = 86949, defaultCD = 300, category = "defensive", priority = 92, icon = 252268, name = "Cauterize", sourceType = "defensive", specs = { 63 } },
            { spellID = 110959, defaultCD = 120, category = "defensive", priority = 92, icon = 575584, name = "Greater Invisibility", sourceType = "defensive" },
            { spellID = 235219, defaultCD = 300, category = "defensive", priority = 92, icon = 135865, name = "Cold Snap", sourceType = "defensive", specs = { 64 }, resetCD = { 45438, 122, 120, 11426 } },
            { spellID = 235313, defaultCD = 25, category = "defensive", priority = 92, icon = 132221, name = "Blazing Barrier", sourceType = "defensive" },
            { spellID = 235450, defaultCD = 25, category = "defensive", priority = 92, icon = 135991, name = "Prismatic Barrier", sourceType = "defensive" },
            { spellID = 342245, defaultCD = 60, category = "defensive", priority = 92, icon = 609811, name = "Alter Time", sourceType = "defensive" },
            { spellID = 414658, defaultCD = 240, category = "defensive", priority = 92, icon = 135777, name = "Ice Cold", sourceType = "defensive" },
        },
        offensives = {
            { spellID = 12472, defaultCD = 120, category = "offensive", priority = 82, icon = 135838, name = "Icy Veins", sourceType = "offensive" },
            { spellID = 44614, defaultCD = 30, category = "offensive", priority = 82, icon = 1506795, name = "Flurry", sourceType = "offensive" },
            { spellID = 80353, defaultCD = 300, category = "offensive", priority = 82, icon = 458224, name = "Time Warp", sourceType = "offensive" },
            { spellID = 84714, defaultCD = 60, category = "offensive", priority = 82, icon = 629077, name = "Frozen Orb", sourceType = "offensive" },
            { spellID = 116011, defaultCD = 45, category = "offensive", priority = 82, icon = 609815, name = "Rune of Power", sourceType = "offensive" },
            { spellID = 153561, defaultCD = 45, category = "offensive", priority = 82, icon = 1033911, name = "Meteor", sourceType = "offensive" },
            { spellID = 153595, defaultCD = 30, category = "offensive", priority = 82, icon = 2126034, name = "Comet Storm", sourceType = "offensive" },
            { spellID = 153626, defaultCD = 20, category = "offensive", priority = 82, icon = 1033906, name = "Arcane Orb", sourceType = "offensive", specs = { 62 } },
            { spellID = 190319, defaultCD = 120, category = "offensive", priority = 82, icon = 135824, name = "Combustion", sourceType = "offensive" },
            { spellID = 190356, defaultCD = 15, category = "offensive", priority = 82, icon = 135857, name = "Blizzard", sourceType = "offensive", specs = { 64 } },
            { spellID = 198144, defaultCD = 60, category = "offensive", priority = 82, icon = 1387355, name = "Ice Form", sourceType = "offensive" },
            { spellID = 205021, defaultCD = 60, category = "offensive", priority = 82, icon = 1698700, name = "Ray of Frost", sourceType = "offensive" },
            { spellID = 205025, defaultCD = 45, category = "offensive", priority = 82, icon = 136031, name = "Presence of Mind", sourceType = "offensive" },
            { spellID = 321507, defaultCD = 45, category = "offensive", priority = 82, icon = 236222, name = "Touch of the Magi", sourceType = "offensive" },
            { spellID = 353082, defaultCD = 45, category = "offensive", priority = 82, icon = 4067368, name = "Ring of Fire", sourceType = "offensive" },
            { spellID = 353128, defaultCD = 45, category = "offensive", priority = 82, icon = 4226155, name = "Arcanosphere", sourceType = "offensive" },
            { spellID = 365350, defaultCD = 90, category = "offensive", priority = 82, icon = 4667417, name = "Arcane Surge", sourceType = "offensive" },
            { spellID = 382440, defaultCD = 60, category = "offensive", priority = 82, icon = 6035312, name = "Shifting Power", sourceType = "offensive" },
        },
        utility = {
            { spellID = 31661, defaultCD = 45, category = "utility", priority = 74, icon = 134153, name = "Dragon's Breath", sourceType = "aoeCC" },
            { spellID = 113724, defaultCD = 45, category = "utility", priority = 74, icon = 464484, name = "Ring of Frost", sourceType = "aoeCC" },
            { spellID = 157980, defaultCD = 45, category = "utility", priority = 74, icon = 1033912, name = "Supernova", sourceType = "aoeCC" },
            { spellID = 157981, defaultCD = 30, category = "utility", priority = 74, icon = 135903, name = "Blast Wave", sourceType = "aoeCC" },
            { spellID = 383121, defaultCD = 60, category = "utility", priority = 74, icon = 575585, name = "Mass Polymorph", sourceType = "aoeCC" },
            { spellID = 449700, defaultCD = 40, category = "utility", priority = 74, icon = 4914671, name = "Gravity Lapse", sourceType = "aoeCC" },
            { spellID = 389794, defaultCD = 45, category = "utility", priority = 73, icon = 135783, name = "Snowdrift", sourceType = "cc" },
            { spellID = 120, defaultCD = 45, category = "utility", priority = 71, icon = 135852, name = "Cone of Cold", sourceType = "disarm" },
            { spellID = 122, defaultCD = 30, category = "utility", priority = 71, icon = 135848, name = "Frost Nova", sourceType = "disarm" },
            { spellID = 157997, defaultCD = 25, category = "utility", priority = 71, icon = 1033909, name = "Ice Nova", sourceType = "disarm" },
            { spellID = 352278, defaultCD = 90, category = "utility", priority = 71, icon = 4226156, name = "Ice Wall", sourceType = "disarm" },
            { spellID = 475, defaultCD = 8, category = "utility", priority = 70, icon = 136082, name = "Remove Curse", sourceType = "dispel" },
            { spellID = 198100, defaultCD = 30, category = "utility", priority = 70, icon = 135729, name = "Kleptomania", sourceType = "dispel" },
            { spellID = 1953, defaultCD = 15, category = "utility", priority = 62, icon = 135736, name = "Blink", sourceType = "movement" },
            { spellID = 212653, defaultCD = 25, category = "utility", priority = 62, icon = 135739, name = "Shimmer", sourceType = "movement", maxCharges = 2 },
            { spellID = 389713, defaultCD = 45, category = "utility", priority = 62, icon = 132171, name = "Displacement", sourceType = "movement" },
            { spellID = 66, defaultCD = 300, category = "utility", priority = 60, icon = 132220, name = "Invisibility", sourceType = "other" },
            { spellID = 12051, defaultCD = 90, category = "utility", priority = 60, icon = 136075, name = "Evocation", sourceType = "other" },
            { spellID = 31687, defaultCD = 30, category = "utility", priority = 60, icon = 135862, name = "Summon Water Elemental", sourceType = "other" },
            { spellID = 108839, defaultCD = 20, category = "utility", priority = 60, icon = 610877, name = "Ice Floes", sourceType = "other", maxCharges = 3 },
            { spellID = 414664, defaultCD = 300, category = "utility", priority = 60, icon = 1387356, name = "Mass Invisibility", sourceType = "other" },
        },
        trinkets = {
        },
    },
    MONK = {
        interrupts = {
            { spellID = 116705, defaultCD = 15, category = "interrupt", priority = 100, icon = 608940, name = "Spear Hand Strike", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 116849, defaultCD = 120, category = "defensive", priority = 95, icon = 627485, name = "Life Cocoon", sourceType = "externalDefensive" },
            { spellID = 115310, defaultCD = 180, category = "defensive", priority = 93, icon = 1020466, name = "Revival", sourceType = "raidDefensive" },
            { spellID = 202162, defaultCD = 45, category = "defensive", priority = 93, icon = 620829, name = "Avert Harm", sourceType = "raidDefensive" },
            { spellID = 388615, defaultCD = 180, category = "defensive", priority = 93, icon = 1381300, name = "Restoral", sourceType = "raidDefensive" },
            { spellID = 115176, defaultCD = 300, category = "defensive", priority = 92, icon = 642417, name = "Zen Meditation", sourceType = "defensive" },
            { spellID = 115203, defaultCD = 120, category = "defensive", priority = 92, icon = 615341, name = "Fortifying Brew", sourceType = "defensive", cooldownBySpec = { [268] = 360 } },
            { spellID = 122278, defaultCD = 120, category = "defensive", priority = 92, icon = 620827, name = "Dampen Harm", sourceType = "defensive" },
            { spellID = 122470, defaultCD = 90, category = "defensive", priority = 92, icon = 651728, name = "Touch of Karma", sourceType = "defensive", specs = { 269 } },
            { spellID = 122783, defaultCD = 90, category = "defensive", priority = 92, icon = 775460, name = "Diffuse Magic", sourceType = "defensive" },
            { spellID = 119582, defaultCD = 20, category = "defensive", priority = 88, icon = 133701, name = "Purifying Brew", sourceType = "tankDefensive", maxCharges = 2 },
            { spellID = 132578, defaultCD = 180, category = "defensive", priority = 88, icon = 608951, name = "Invoke Niuzao, the Black Ox", sourceType = "tankDefensive" },
            { spellID = 322507, defaultCD = 45, category = "defensive", priority = 88, icon = 1360979, name = "Celestial Brew", sourceType = "tankDefensive" },
            { spellID = 1241059, defaultCD = 45, category = "defensive", priority = 88, icon = 613399, name = "Celestial Infusion", sourceType = "tankDefensive" },
            { spellID = 209584, defaultCD = 30, category = "defensive", priority = 86, icon = 651940, name = "Zen Focus Tea", sourceType = "counterCC" },
            { spellID = 354540, defaultCD = 90, category = "defensive", priority = 86, icon = 839394, name = "Nimble Brew", sourceType = "counterCC" },
            { spellID = 322118, defaultCD = 120, category = "defensive", priority = 84, icon = 574571, name = "Invoke Yu'lon, the Jade Serpent", sourceType = "heal" },
            { spellID = 325197, defaultCD = 120, category = "defensive", priority = 84, icon = 877514, name = "Invoke Chi-Ji, the Red Crane", sourceType = "heal" },
            { spellID = 443028, defaultCD = 90, category = "defensive", priority = 84, icon = 5927619, name = "Celestial Conduit", sourceType = "heal" },
        },
        offensives = {
            { spellID = 113656, defaultCD = 24, category = "offensive", priority = 82, icon = 627606, name = "Fists of Fury", sourceType = "offensive" },
            { spellID = 123904, defaultCD = 120, category = "offensive", priority = 82, icon = 620832, name = "Invoke Xuen, the White Tiger", sourceType = "offensive" },
            { spellID = 123986, defaultCD = 30, category = "offensive", priority = 82, icon = 135734, name = "Chi Burst", sourceType = "offensive" },
            { spellID = 124081, defaultCD = 30, category = "offensive", priority = 82, icon = 613397, name = "Zen Pulse", sourceType = "offensive" },
            { spellID = 137639, defaultCD = 90, category = "offensive", priority = 82, icon = 136038, name = "Storm, Earth, and Fire", sourceType = "offensive", maxCharges = 2 },
            { spellID = 152175, defaultCD = 24, category = "offensive", priority = 82, icon = 988194, name = "Whirling Dragon Punch", sourceType = "offensive" },
            { spellID = 207025, defaultCD = 20, category = "offensive", priority = 82, icon = 620830, name = "Admonishment", sourceType = "offensive" },
            { spellID = 322109, defaultCD = 180, category = "offensive", priority = 82, icon = 606552, name = "Touch of Death", sourceType = "offensive" },
            { spellID = 325153, defaultCD = 60, category = "offensive", priority = 82, icon = 644378, name = "Exploding Keg", sourceType = "offensive" },
            { spellID = 387184, defaultCD = 120, category = "offensive", priority = 82, icon = 6035314, name = "Weapons of Order", sourceType = "offensive" },
            { spellID = 388193, defaultCD = 15, category = "offensive", priority = 82, icon = 6035313, name = "Jadefire Stomp", sourceType = "offensive" },
            { spellID = 388686, defaultCD = 120, category = "offensive", priority = 82, icon = 4667418, name = "Summon White Tiger Statue", sourceType = "offensive" },
            { spellID = 392983, defaultCD = 40, category = "offensive", priority = 82, icon = 1282595, name = "Strike of the Windlord", sourceType = "offensive" },
        },
        utility = {
            { spellID = 116844, defaultCD = 45, category = "utility", priority = 74, icon = 839107, name = "Ring of Peace", sourceType = "aoeCC" },
            { spellID = 119381, defaultCD = 60, category = "utility", priority = 74, icon = 642414, name = "Leg Sweep", sourceType = "aoeCC" },
            { spellID = 115078, defaultCD = 45, category = "utility", priority = 73, icon = 629534, name = "Paralysis", sourceType = "cc" },
            { spellID = 198898, defaultCD = 30, category = "utility", priority = 73, icon = 332402, name = "Song of Chi-Ji", sourceType = "cc" },
            { spellID = 202335, defaultCD = 45, category = "utility", priority = 73, icon = 644378, name = "Double Barrel", sourceType = "cc" },
            { spellID = 202370, defaultCD = 30, category = "utility", priority = 71, icon = 1381297, name = "Mighty Ox Kick", sourceType = "disarm" },
            { spellID = 233759, defaultCD = 45, category = "utility", priority = 71, icon = 132343, name = "Grapple Weapon", sourceType = "disarm" },
            { spellID = 324312, defaultCD = 60, category = "utility", priority = 71, icon = 628134, name = "Clash", sourceType = "disarm" },
            { spellID = 115450, defaultCD = 8, category = "utility", priority = 70, icon = 460692, name = "Detox", sourceType = "dispel", specs = { 270 } },
            { spellID = 218164, defaultCD = 8, category = "utility", priority = 70, icon = 460692, name = "Detox", sourceType = "dispel" },
            { spellID = 116841, defaultCD = 30, category = "utility", priority = 69, icon = 651727, name = "Tiger's Lust", sourceType = "freedom" },
            { spellID = 101545, defaultCD = 30, category = "utility", priority = 62, icon = 606545, name = "Flying Serpent Kick", sourceType = "movement", specs = { 269 } },
            { spellID = 109132, defaultCD = 20, category = "utility", priority = 62, icon = 574574, name = "Roll", sourceType = "movement", maxCharges = 2 },
            { spellID = 115008, defaultCD = 20, category = "utility", priority = 62, icon = 607849, name = "Chi Torpedo", sourceType = "movement", maxCharges = 2 },
            { spellID = 119996, defaultCD = 45, category = "utility", priority = 62, icon = 237585, name = "Transcendence: Transfer", sourceType = "movement" },
            { spellID = 1217413, defaultCD = 30, category = "utility", priority = 62, icon = 1029596, name = "Slicing Winds", sourceType = "movement" },
            { spellID = 115399, defaultCD = 120, category = "utility", priority = 60, icon = 629483, name = "Black Ox Brew", sourceType = "other" },
            { spellID = 116680, defaultCD = 30, category = "utility", priority = 60, icon = 611418, name = "Thunder Focus Tea", sourceType = "other" },
            { spellID = 115315, defaultCD = 10, category = "utility", priority = 42, icon = 627607, name = "Summon Black Ox Statue", sourceType = "taunt" },
            { spellID = 115546, defaultCD = 8, category = "utility", priority = 42, icon = 620830, name = "Provoke", sourceType = "taunt" },
        },
        trinkets = {
        },
    },
    PALADIN = {
        interrupts = {
            { spellID = 31935, defaultCD = 15, category = "interrupt", priority = 100, icon = 135874, name = "Avenger's Shield", sourceType = "interrupt" },
            { spellID = 96231, defaultCD = 15, category = "interrupt", priority = 100, icon = 523893, name = "Rebuke", sourceType = "interrupt" },
            { spellID = 215652, defaultCD = 45, category = "interrupt", priority = 100, icon = 237452, name = "Shield of Virtue", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 642, defaultCD = 300, category = "defensive", priority = 96, icon = 524354, name = "Divine Shield", sourceType = "immunity" },
            { spellID = 228049, defaultCD = 300, category = "defensive", priority = 96, icon = 135919, name = "Guardian of the Forgotten Queen", sourceType = "immunity" },
            { spellID = 1022, defaultCD = 300, category = "defensive", priority = 95, icon = 135964, name = "Blessing of Protection", sourceType = "externalDefensive" },
            { spellID = 6940, defaultCD = 120, category = "defensive", priority = 95, icon = 135966, name = "Blessing of Sacrifice", sourceType = "externalDefensive" },
            { spellID = 148039, defaultCD = 30, category = "defensive", priority = 95, icon = 4067370, name = "Barrier of Faith", sourceType = "externalDefensive" },
            { spellID = 199448, defaultCD = 120, category = "defensive", priority = 95, icon = 135966, name = "Ultimate Sacrifice", sourceType = "externalDefensive" },
            { spellID = 204018, defaultCD = 300, category = "defensive", priority = 95, icon = 135880, name = "Blessing of Spellwarding", sourceType = "externalDefensive" },
            { spellID = 432472, defaultCD = 60, category = "defensive", priority = 95, icon = 5927636, name = "Holy Bulwark", sourceType = "externalDefensive", maxCharges = 2 },
            { spellID = 31821, defaultCD = 180, category = "defensive", priority = 93, icon = 135872, name = "Aura Mastery", sourceType = "raidDefensive" },
            { spellID = 498, defaultCD = 60, category = "defensive", priority = 92, icon = 524353, name = "Divine Protection", sourceType = "defensive", specs = { 65 } },
            { spellID = 184662, defaultCD = 90, category = "defensive", priority = 92, icon = 236264, name = "Shield of Vengeance", sourceType = "defensive" },
            { spellID = 403876, defaultCD = 90, category = "defensive", priority = 92, icon = 524353, name = "Divine Protection", sourceType = "defensive", specs = { 70 } },
            { spellID = 31850, defaultCD = 120, category = "defensive", priority = 88, icon = 135870, name = "Ardent Defender", sourceType = "tankDefensive" },
            { spellID = 86659, defaultCD = 300, category = "defensive", priority = 88, icon = 135919, name = "Guardian of Ancient Kings", sourceType = "tankDefensive" },
            { spellID = 327193, defaultCD = 90, category = "defensive", priority = 88, icon = 237537, name = "Moment of Glory", sourceType = "tankDefensive" },
            { spellID = 378279, defaultCD = 45, category = "defensive", priority = 88, icon = 1349535, name = "Gift of the Golden Val'kyr", sourceType = "tankDefensive" },
            { spellID = 387174, defaultCD = 60, category = "defensive", priority = 88, icon = 1272527, name = "Eye of Tyr", sourceType = "tankDefensive" },
            { spellID = 210256, defaultCD = 60, category = "defensive", priority = 86, icon = 135911, name = "Blessing of Sanctuary", sourceType = "counterCC" },
            { spellID = 633, defaultCD = 600, category = "defensive", priority = 84, icon = 135928, name = "Lay on Hands", sourceType = "heal" },
            { spellID = 114165, defaultCD = 30, category = "defensive", priority = 84, icon = 613408, name = "Holy Prism", sourceType = "heal" },
            { spellID = 200652, defaultCD = 90, category = "defensive", priority = 84, icon = 1122562, name = "Tyr's Deliverance", sourceType = "heal" },
            { spellID = 216331, defaultCD = 60, category = "defensive", priority = 84, icon = 589117, name = "Avenging Crusader", sourceType = "heal" },
            { spellID = 384376, defaultCD = 120, category = "defensive", priority = 84, icon = 135875, name = "Avenging Wrath", sourceType = "heal" },
            { spellID = 414273, defaultCD = 90, category = "defensive", priority = 84, icon = 135985, name = "Hand of Divinity", sourceType = "heal" },
        },
        offensives = {
            { spellID = 31884, defaultCD = 120, category = "offensive", priority = 82, icon = 135875, name = "Avenging Wrath", sourceType = "offensive", cooldownBySpec = { [70] = 60 } },
            { spellID = 198034, defaultCD = 120, category = "offensive", priority = 82, icon = 626003, name = "Divine Hammer", sourceType = "offensive" },
            { spellID = 207028, defaultCD = 20, category = "offensive", priority = 82, icon = 135984, name = "Inquisition", sourceType = "offensive" },
            { spellID = 231895, defaultCD = 120, category = "offensive", priority = 82, icon = 236262, name = "Crusade", sourceType = "offensive" },
            { spellID = 255937, defaultCD = 30, category = "offensive", priority = 82, icon = 1112939, name = "Wake of Ashes", sourceType = "offensive" },
            { spellID = 343527, defaultCD = 30, category = "offensive", priority = 82, icon = 613954, name = "Execution Sentence", sourceType = "offensive" },
            { spellID = 343721, defaultCD = 60, category = "offensive", priority = 82, icon = 135878, name = "Final Reckoning", sourceType = "offensive" },
            { spellID = 375576, defaultCD = 60, category = "offensive", priority = 82, icon = 6035315, name = "Divine Toll", sourceType = "offensive" },
            { spellID = 388007, defaultCD = 45, category = "offensive", priority = 82, icon = 3636845, name = "Blessing of Summer", sourceType = "offensive" },
            { spellID = 389539, defaultCD = 120, category = "offensive", priority = 82, icon = 135922, name = "Sentinel", sourceType = "offensive" },
        },
        utility = {
            { spellID = 115750, defaultCD = 90, category = "utility", priority = 74, icon = 571553, name = "Blinding Light", sourceType = "aoeCC" },
            { spellID = 469317, defaultCD = 15, category = "utility", priority = 74, icon = 135902, name = "Stand Against Evil", sourceType = "aoeCC" },
            { spellID = 853, defaultCD = 45, category = "utility", priority = 73, icon = 135963, name = "Hammer of Justice", sourceType = "cc" },
            { spellID = 10326, defaultCD = 15, category = "utility", priority = 73, icon = 571559, name = "Turn Evil", sourceType = "cc" },
            { spellID = 20066, defaultCD = 15, category = "utility", priority = 73, icon = 135942, name = "Repentance", sourceType = "cc" },
            { spellID = 410126, defaultCD = 45, category = "utility", priority = 71, icon = 5260436, name = "Searing Glare", sourceType = "disarm" },
            { spellID = 4987, defaultCD = 8, category = "utility", priority = 70, icon = 135949, name = "Cleanse", sourceType = "dispel", specs = { 65 } },
            { spellID = 213644, defaultCD = 8, category = "utility", priority = 70, icon = 135953, name = "Cleanse Toxins", sourceType = "dispel" },
            { spellID = 1044, defaultCD = 25, category = "utility", priority = 69, icon = 135968, name = "Blessing of Freedom", sourceType = "freedom" },
            { spellID = 190784, defaultCD = 45, category = "utility", priority = 62, icon = 1360759, name = "Divine Steed", sourceType = "movement" },
            { spellID = 378974, defaultCD = 120, category = "utility", priority = 60, icon = 535594, name = "Bastion of Light", sourceType = "other" },
            { spellID = 414170, defaultCD = 60, category = "utility", priority = 60, icon = 237537, name = "Daybreak", sourceType = "other" },
            { spellID = 62124, defaultCD = 8, category = "utility", priority = 42, icon = 135984, name = "Hand of Reckoning", sourceType = "taunt" },
        },
        trinkets = {
        },
    },
    PRIEST = {
        interrupts = {
            { spellID = 15487, defaultCD = 45, category = "interrupt", priority = 100, icon = 458230, name = "Silence", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 33206, defaultCD = 180, category = "defensive", priority = 95, icon = 135936, name = "Pain Suppression", sourceType = "externalDefensive" },
            { spellID = 47788, defaultCD = 180, category = "defensive", priority = 95, icon = 237542, name = "Guardian Spirit", sourceType = "externalDefensive" },
            { spellID = 108968, defaultCD = 300, category = "defensive", priority = 95, icon = 537079, name = "Void Shift", sourceType = "externalDefensive" },
            { spellID = 197268, defaultCD = 90, category = "defensive", priority = 95, icon = 1445239, name = "Ray of Hope", sourceType = "externalDefensive" },
            { spellID = 15286, defaultCD = 120, category = "defensive", priority = 93, icon = 136230, name = "Vampiric Embrace", sourceType = "raidDefensive" },
            { spellID = 62618, defaultCD = 180, category = "defensive", priority = 93, icon = 253400, name = "Power Word: Barrier", sourceType = "raidDefensive" },
            { spellID = 64843, defaultCD = 180, category = "defensive", priority = 93, icon = 237540, name = "Divine Hymn", sourceType = "raidDefensive" },
            { spellID = 271466, defaultCD = 180, category = "defensive", priority = 93, icon = 537078, name = "Luminous Barrier", sourceType = "raidDefensive" },
            { spellID = 47585, defaultCD = 120, category = "defensive", priority = 92, icon = 237563, name = "Dispersion", sourceType = "defensive" },
            { spellID = 215982, defaultCD = 120, category = "defensive", priority = 92, icon = 132864, name = "Spirit of the Redeemer", sourceType = "defensive" },
            { spellID = 328530, defaultCD = 60, category = "defensive", priority = 92, icon = 1345176, name = "Divine Ascension", sourceType = "defensive" },
            { spellID = 391124, defaultCD = 600, category = "defensive", priority = 92, icon = 1295528, name = "Restitution", sourceType = "defensive" },
            { spellID = 32379, defaultCD = 10, category = "defensive", priority = 86, icon = 136149, name = "Shadow Word: Death", sourceType = "counterCC" },
            { spellID = 213610, defaultCD = 45, category = "defensive", priority = 86, icon = 458722, name = "Holy Ward", sourceType = "counterCC" },
            { spellID = 2050, defaultCD = 60, category = "defensive", priority = 84, icon = 135937, name = "Holy Word: Serenity", sourceType = "heal" },
            { spellID = 19236, defaultCD = 90, category = "defensive", priority = 84, icon = 237550, name = "Desperate Prayer", sourceType = "heal" },
            { spellID = 34861, defaultCD = 60, category = "defensive", priority = 84, icon = 237541, name = "Holy Word: Sanctify", sourceType = "heal" },
            { spellID = 120517, defaultCD = 60, category = "defensive", priority = 84, icon = 632352, name = "Halo", sourceType = "heal" },
            { spellID = 120644, defaultCD = 60, category = "defensive", priority = 84, icon = 632353, name = "Halo", sourceType = "heal" },
            { spellID = 200183, defaultCD = 120, category = "defensive", priority = 84, icon = 1060983, name = "Apotheosis", sourceType = "heal" },
            { spellID = 372760, defaultCD = 60, category = "defensive", priority = 84, icon = 521584, name = "Divine Word", sourceType = "heal" },
            { spellID = 372835, defaultCD = 120, category = "defensive", priority = 84, icon = 135980, name = "Lightwell", sourceType = "heal" },
            { spellID = 373481, defaultCD = 15, category = "defensive", priority = 84, icon = 4667420, name = "Power Word: Life", sourceType = "heal" },
            { spellID = 421453, defaultCD = 240, category = "defensive", priority = 84, icon = 1060982, name = "Ultimate Penitence", sourceType = "heal" },
            { spellID = 472433, defaultCD = 90, category = "defensive", priority = 84, icon = 135895, name = "Evangelism", sourceType = "heal" },
        },
        offensives = {
            { spellID = 8092, defaultCD = 24, category = "offensive", priority = 82, icon = 136224, name = "Mind Blast", sourceType = "offensive", cooldownBySpec = { [256] = 24, [258] = 9 } },
            { spellID = 10060, defaultCD = 120, category = "offensive", priority = 82, icon = 135939, name = "Power Infusion", sourceType = "offensive" },
            { spellID = 34433, defaultCD = 180, category = "offensive", priority = 82, icon = 136199, name = "Shadowfiend", sourceType = "offensive" },
            { spellID = 123040, defaultCD = 60, category = "offensive", priority = 82, icon = 136214, name = "Mindbender", sourceType = "offensive" },
            { spellID = 200174, defaultCD = 60, category = "offensive", priority = 82, icon = 136214, name = "Mindbender", sourceType = "offensive" },
            { spellID = 205385, defaultCD = 15, category = "offensive", priority = 82, icon = 136201, name = "Shadow Crash", sourceType = "offensive", maxCharges = 2 },
            { spellID = 211522, defaultCD = 45, category = "offensive", priority = 82, icon = 537021, name = "Psyfiend", sourceType = "offensive" },
            { spellID = 228260, defaultCD = 120, category = "offensive", priority = 82, icon = 1386548, name = "Void Eruption", sourceType = "offensive" },
            { spellID = 263165, defaultCD = 30, category = "offensive", priority = 82, icon = 1386551, name = "Void Torrent", sourceType = "offensive" },
            { spellID = 316262, defaultCD = 90, category = "offensive", priority = 82, icon = 3718862, name = "Thoughtsteal", sourceType = "offensive" },
            { spellID = 372616, defaultCD = 60, category = "offensive", priority = 82, icon = 4667419, name = "Empyreal Blaze", sourceType = "offensive" },
            { spellID = 375901, defaultCD = 45, category = "offensive", priority = 82, icon = 6035316, name = "Mindgames", sourceType = "offensive" },
            { spellID = 391109, defaultCD = 60, category = "offensive", priority = 82, icon = 1445237, name = "Dark Ascension", sourceType = "offensive" },
            { spellID = 451235, defaultCD = 120, category = "offensive", priority = 82, icon = 615099, name = "Voidwraith", sourceType = "offensive" },
        },
        utility = {
            { spellID = 8122, defaultCD = 45, category = "utility", priority = 74, icon = 136184, name = "Psychic Scream", sourceType = "aoeCC" },
            { spellID = 64044, defaultCD = 45, category = "utility", priority = 73, icon = 237568, name = "Psychic Horror", sourceType = "cc" },
            { spellID = 88625, defaultCD = 60, category = "utility", priority = 73, icon = 135886, name = "Holy Word: Chastise", sourceType = "cc" },
            { spellID = 205364, defaultCD = 30, category = "utility", priority = 73, icon = 1386549, name = "Dominate Mind", sourceType = "cc" },
            { spellID = 108920, defaultCD = 60, category = "utility", priority = 71, icon = 537022, name = "Void Tendrils", sourceType = "disarm" },
            { spellID = 527, defaultCD = 8, category = "utility", priority = 70, icon = 135894, name = "Purify", sourceType = "dispel" },
            { spellID = 32375, defaultCD = 120, category = "utility", priority = 70, icon = 135739, name = "Mass Dispel", sourceType = "dispel" },
            { spellID = 213634, defaultCD = 8, category = "utility", priority = 70, icon = 135935, name = "Purify Disease", sourceType = "dispel" },
            { spellID = 73325, defaultCD = 90, category = "utility", priority = 62, icon = 463835, name = "Leap of Faith", sourceType = "movement" },
            { spellID = 121536, defaultCD = 20, category = "utility", priority = 62, icon = 642580, name = "Angelic Feather", sourceType = "movement", maxCharges = 3 },
            { spellID = 586, defaultCD = 30, category = "utility", priority = 60, icon = 135994, name = "Fade", sourceType = "other" },
            { spellID = 64901, defaultCD = 180, category = "utility", priority = 60, icon = 135982, name = "Symbol of Hope", sourceType = "other" },
            { spellID = 428933, defaultCD = 60, category = "utility", priority = 60, icon = 5927640, name = "Premonition", sourceType = "other", maxCharges = 2 },
        },
        trinkets = {
        },
    },
    ROGUE = {
        interrupts = {
            { spellID = 1766, defaultCD = 15, category = "interrupt", priority = 100, icon = 132219, name = "Kick", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 1856, defaultCD = 120, category = "defensive", priority = 92, icon = 132331, name = "Vanish", sourceType = "defensive" },
            { spellID = 1966, defaultCD = 15, category = "defensive", priority = 92, icon = 132294, name = "Feint", sourceType = "defensive" },
            { spellID = 5277, defaultCD = 120, category = "defensive", priority = 92, icon = 136205, name = "Evasion", sourceType = "defensive" },
            { spellID = 31224, defaultCD = 120, category = "defensive", priority = 92, icon = 136177, name = "Cloak of Shadows", sourceType = "defensive" },
            { spellID = 31230, defaultCD = 360, category = "defensive", priority = 92, icon = 132285, name = "Cheat Death", sourceType = "defensive" },
            { spellID = 185311, defaultCD = 30, category = "defensive", priority = 84, icon = 1373904, name = "Crimson Vial", sourceType = "heal" },
        },
        offensives = {
            { spellID = 5938, defaultCD = 30, category = "offensive", priority = 82, icon = 135428, name = "Shiv", sourceType = "offensive" },
            { spellID = 13750, defaultCD = 180, category = "offensive", priority = 82, icon = 136206, name = "Adrenaline Rush", sourceType = "offensive" },
            { spellID = 13877, defaultCD = 30, category = "offensive", priority = 82, icon = 132350, name = "Blade Flurry", sourceType = "offensive", specs = { 260 } },
            { spellID = 51690, defaultCD = 180, category = "offensive", priority = 82, icon = 6735718, name = "Killing Spree", sourceType = "offensive" },
            { spellID = 121471, defaultCD = 90, category = "offensive", priority = 82, icon = 376022, name = "Shadow Blades", sourceType = "offensive" },
            { spellID = 185313, defaultCD = 60, category = "offensive", priority = 82, icon = 236279, name = "Shadow Dance", sourceType = "offensive" },
            { spellID = 196937, defaultCD = 90, category = "offensive", priority = 82, icon = 132094, name = "Ghostly Strike", sourceType = "offensive" },
            { spellID = 212283, defaultCD = 30, category = "offensive", priority = 82, icon = 252272, name = "Symbols of Death", sourceType = "offensive", specs = { 261 } },
            { spellID = 221622, defaultCD = 30, category = "offensive", priority = 82, icon = 236283, name = "Thick as Thieves", sourceType = "offensive" },
            { spellID = 269513, defaultCD = 30, category = "offensive", priority = 82, icon = 1043573, name = "Death from Above", sourceType = "offensive" },
            { spellID = 271877, defaultCD = 45, category = "offensive", priority = 82, icon = 1016243, name = "Blade Rush", sourceType = "offensive" },
            { spellID = 277925, defaultCD = 60, category = "offensive", priority = 82, icon = 236282, name = "Shuriken Tornado", sourceType = "offensive" },
            { spellID = 280719, defaultCD = 60, category = "offensive", priority = 82, icon = 132305, name = "Secret Technique", sourceType = "offensive" },
            { spellID = 315341, defaultCD = 45, category = "offensive", priority = 82, icon = 135610, name = "Between the Eyes", sourceType = "offensive", specs = { 260 } },
            { spellID = 315508, defaultCD = 45, category = "offensive", priority = 82, icon = 1373910, name = "Roll the Bones", sourceType = "offensive", specs = { 260 } },
            { spellID = 360194, defaultCD = 120, category = "offensive", priority = 82, icon = 4667421, name = "Deathmark", sourceType = "offensive" },
            { spellID = 381989, defaultCD = 360, category = "offensive", priority = 82, icon = 4667423, name = "Keep It Rolling", sourceType = "offensive" },
            { spellID = 382245, defaultCD = 45, category = "offensive", priority = 82, icon = 135988, name = "Cold Blood", sourceType = "offensive" },
            { spellID = 384631, defaultCD = 90, category = "offensive", priority = 82, icon = 6035318, name = "Flagellation", sourceType = "offensive" },
            { spellID = 385627, defaultCD = 60, category = "offensive", priority = 82, icon = 1259291, name = "Kingsbane", sourceType = "offensive" },
            { spellID = 426591, defaultCD = 45, category = "offensive", priority = 82, icon = 1120132, name = "Goremaw's Bite", sourceType = "offensive" },
        },
        utility = {
            { spellID = 200733, defaultCD = 60, category = "utility", priority = 74, icon = 136175, name = "Airborne Irritant", sourceType = "aoeCC", cooldownBySpec = { [260] = 63.6 } },
            { spellID = 408, defaultCD = 30, category = "utility", priority = 73, icon = 132298, name = "Kidney Shot", sourceType = "cc" },
            { spellID = 1776, defaultCD = 25, category = "utility", priority = 73, icon = 132155, name = "Gouge", sourceType = "cc" },
            { spellID = 2094, defaultCD = 120, category = "utility", priority = 73, icon = 136175, name = "Blind", sourceType = "cc" },
            { spellID = 212182, defaultCD = 180, category = "utility", priority = 73, icon = 458733, name = "Smoke Bomb", sourceType = "cc" },
            { spellID = 359053, defaultCD = 120, category = "utility", priority = 73, icon = 458733, name = "Smoke Bomb", sourceType = "cc" },
            { spellID = 207777, defaultCD = 45, category = "utility", priority = 71, icon = 236272, name = "Dismantle", sourceType = "disarm" },
            { spellID = 2983, defaultCD = 120, category = "utility", priority = 62, icon = 132307, name = "Sprint", sourceType = "movement" },
            { spellID = 36554, defaultCD = 30, category = "utility", priority = 62, icon = 132303, name = "Shadowstep", sourceType = "movement" },
            { spellID = 195457, defaultCD = 45, category = "utility", priority = 62, icon = 1373906, name = "Grappling Hook", sourceType = "movement", specs = { 260 } },
            { spellID = 1725, defaultCD = 30, category = "utility", priority = 60, icon = 132289, name = "Distract", sourceType = "other" },
            { spellID = 57934, defaultCD = 30, category = "utility", priority = 60, icon = 236283, name = "Tricks of the Trade", sourceType = "other" },
            { spellID = 114018, defaultCD = 360, category = "utility", priority = 60, icon = 635350, name = "Shroud of Concealment", sourceType = "other" },
        },
        trinkets = {
        },
    },
    SHAMAN = {
        interrupts = {
            { spellID = 57994, defaultCD = 12, category = "interrupt", priority = 100, icon = 136018, name = "Wind Shear", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 409293, defaultCD = 120, category = "defensive", priority = 96, icon = 5260435, name = "Burrow", sourceType = "immunity" },
            { spellID = 98008, defaultCD = 180, category = "defensive", priority = 93, icon = 237586, name = "Spirit Link Totem", sourceType = "raidDefensive" },
            { spellID = 108280, defaultCD = 180, category = "defensive", priority = 93, icon = 538569, name = "Healing Tide Totem", sourceType = "raidDefensive" },
            { spellID = 198838, defaultCD = 60, category = "defensive", priority = 93, icon = 136098, name = "Earthen Wall Totem", sourceType = "raidDefensive" },
            { spellID = 207399, defaultCD = 300, category = "defensive", priority = 93, icon = 136080, name = "Ancestral Protection Totem", sourceType = "raidDefensive" },
            { spellID = 30884, defaultCD = 45, category = "defensive", priority = 92, icon = 136060, name = "Nature's Guardian", sourceType = "defensive" },
            { spellID = 108270, defaultCD = 180, category = "defensive", priority = 92, icon = 538572, name = "Stone Bulwark Totem", sourceType = "defensive" },
            { spellID = 108271, defaultCD = 120, category = "defensive", priority = 92, icon = 538565, name = "Astral Shift", sourceType = "defensive" },
            { spellID = 198103, defaultCD = 300, category = "defensive", priority = 92, icon = 136024, name = "Earth Elemental", sourceType = "defensive" },
            { spellID = 204331, defaultCD = 45, category = "defensive", priority = 92, icon = 511726, name = "Counterstrike Totem", sourceType = "defensive" },
            { spellID = 8143, defaultCD = 60, category = "defensive", priority = 86, icon = 136108, name = "Tremor Totem", sourceType = "counterCC" },
            { spellID = 204336, defaultCD = 30, category = "defensive", priority = 86, icon = 136039, name = "Grounding Totem", sourceType = "counterCC" },
            { spellID = 383019, defaultCD = 60, category = "defensive", priority = 86, icon = 538575, name = "Tranquil Air Totem", sourceType = "counterCC" },
            { spellID = 5394, defaultCD = 30, category = "defensive", priority = 84, icon = 135127, name = "Healing Stream Totem", sourceType = "heal" },
            { spellID = 114052, defaultCD = 180, category = "defensive", priority = 84, icon = 135791, name = "Ascendance", sourceType = "heal" },
            { spellID = 157153, defaultCD = 45, category = "defensive", priority = 84, icon = 971076, name = "Cloudburst Totem", sourceType = "heal" },
            { spellID = 197995, defaultCD = 20, category = "defensive", priority = 84, icon = 893778, name = "Wellspring", sourceType = "heal" },
        },
        offensives = {
            { spellID = 2825, defaultCD = 300, category = "offensive", priority = 82, icon = 136012, name = "Bloodlust", sourceType = "offensive" },
            { spellID = 51533, defaultCD = 90, category = "offensive", priority = 82, icon = 237577, name = "Feral Spirit", sourceType = "offensive" },
            { spellID = 114050, defaultCD = 180, category = "offensive", priority = 82, icon = 135791, name = "Ascendance", sourceType = "offensive" },
            { spellID = 114051, defaultCD = 180, category = "offensive", priority = 82, icon = 135791, name = "Ascendance", sourceType = "offensive" },
            { spellID = 191634, defaultCD = 60, category = "offensive", priority = 82, icon = 839977, name = "Stormkeeper", sourceType = "offensive" },
            { spellID = 192222, defaultCD = 30, category = "offensive", priority = 82, icon = 971079, name = "Liquid Magma Totem", sourceType = "offensive" },
            { spellID = 192249, defaultCD = 150, category = "offensive", priority = 82, icon = 2065626, name = "Storm Elemental", sourceType = "offensive" },
            { spellID = 193876, defaultCD = 60, category = "offensive", priority = 82, icon = 136012, name = "Shamanism", sourceType = "offensive" },
            { spellID = 198067, defaultCD = 150, category = "offensive", priority = 82, icon = 135790, name = "Fire Elemental", sourceType = "offensive" },
            { spellID = 375982, defaultCD = 30, category = "offensive", priority = 82, icon = 6035320, name = "Primordial Wave", sourceType = "offensive" },
            { spellID = 384352, defaultCD = 60, category = "offensive", priority = 82, icon = 1035054, name = "Doom Winds", sourceType = "offensive" },
            { spellID = 444995, defaultCD = 30, category = "offensive", priority = 82, icon = 5927655, name = "Surging Totem", sourceType = "offensive" },
        },
        utility = {
            { spellID = 51490, defaultCD = 30, category = "utility", priority = 74, icon = 237589, name = "Thunderstorm", sourceType = "aoeCC" },
            { spellID = 192058, defaultCD = 60, category = "utility", priority = 74, icon = 136013, name = "Capacitor Totem", sourceType = "aoeCC" },
            { spellID = 204406, defaultCD = 30, category = "utility", priority = 74, icon = 237589, name = "Traveling Storm", sourceType = "aoeCC" },
            { spellID = 378779, defaultCD = 25, category = "utility", priority = 74, icon = 237589, name = "Thundershock", sourceType = "aoeCC" },
            { spellID = 51514, defaultCD = 30, category = "utility", priority = 73, icon = 237579, name = "Hex", sourceType = "cc" },
            { spellID = 197214, defaultCD = 40, category = "utility", priority = 73, icon = 524794, name = "Sundering", sourceType = "cc" },
            { spellID = 305483, defaultCD = 45, category = "utility", priority = 73, icon = 1385911, name = "Lightning Lasso", sourceType = "cc" },
            { spellID = 51485, defaultCD = 30, category = "utility", priority = 71, icon = 136100, name = "Earthgrab Totem", sourceType = "disarm" },
            { spellID = 355580, defaultCD = 90, category = "utility", priority = 71, icon = 1020304, name = "Static Field Totem", sourceType = "disarm" },
            { spellID = 356736, defaultCD = 30, category = "utility", priority = 71, icon = 538567, name = "Unleashed Shield", sourceType = "disarm" },
            { spellID = 51886, defaultCD = 8, category = "utility", priority = 70, icon = 236288, name = "Cleanse Spirit", sourceType = "dispel" },
            { spellID = 77130, defaultCD = 8, category = "utility", priority = 70, icon = 236288, name = "Purify Spirit", sourceType = "dispel", specs = { 264 } },
            { spellID = 378773, defaultCD = 12, category = "utility", priority = 70, icon = 451166, name = "Greater Purge", sourceType = "dispel" },
            { spellID = 383013, defaultCD = 120, category = "utility", priority = 70, icon = 136070, name = "Poison Cleansing Totem", sourceType = "dispel" },
            { spellID = 58875, defaultCD = 60, category = "utility", priority = 69, icon = 132328, name = "Spirit Walk", sourceType = "freedom" },
            { spellID = 192077, defaultCD = 120, category = "utility", priority = 64, icon = 538576, name = "Wind Rush Totem", sourceType = "raidMovement" },
            { spellID = 192063, defaultCD = 20, category = "utility", priority = 62, icon = 463565, name = "Gust of Wind", sourceType = "movement" },
            { spellID = 196884, defaultCD = 30, category = "utility", priority = 62, icon = 1027879, name = "Feral Lunge", sourceType = "movement" },
            { spellID = 2484, defaultCD = 30, category = "utility", priority = 60, icon = 136102, name = "Earthbind Totem", sourceType = "other" },
            { spellID = 20608, defaultCD = 1800, category = "utility", priority = 60, icon = 451167, name = "Reincarnation", sourceType = "other" },
            { spellID = 79206, defaultCD = 120, category = "utility", priority = 60, icon = 451170, name = "Spiritwalker's Grace", sourceType = "other" },
            { spellID = 108285, defaultCD = 180, category = "utility", priority = 60, icon = 538570, name = "Totemic Recall", sourceType = "other" },
            { spellID = 378081, defaultCD = 60, category = "utility", priority = 60, icon = 136076, name = "Nature's Swiftness", sourceType = "other" },
            { spellID = 443454, defaultCD = 30, category = "utility", priority = 60, icon = 5927625, name = "Ancestral Swiftness", sourceType = "other" },
        },
        trinkets = {
        },
    },
    WARLOCK = {
        interrupts = {
            { spellID = 119898, defaultCD = 24, category = "interrupt", priority = 100, icon = 236292, name = "Command Demon", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 104773, defaultCD = 180, category = "defensive", priority = 92, icon = 136150, name = "Unending Resolve", sourceType = "defensive" },
            { spellID = 108416, defaultCD = 60, category = "defensive", priority = 92, icon = 136146, name = "Dark Pact", sourceType = "defensive" },
            { spellID = 212295, defaultCD = 45, category = "defensive", priority = 86, icon = 135796, name = "Nether Ward", sourceType = "counterCC" },
            { spellID = 452930, defaultCD = 60, category = "defensive", priority = 84, icon = 538744, name = "Demonic Healthstone", sourceType = "heal" },
        },
        offensives = {
            { spellID = 1122, defaultCD = 120, category = "offensive", priority = 82, icon = 136219, name = "Summon Infernal", sourceType = "offensive" },
            { spellID = 6353, defaultCD = 45, category = "offensive", priority = 82, icon = 135809, name = "Soul Fire", sourceType = "offensive" },
            { spellID = 89751, defaultCD = 30, category = "offensive", priority = 82, icon = 236303, name = "Felstorm", sourceType = "offensive", specs = { 266 } },
            { spellID = 104316, defaultCD = 20, category = "offensive", priority = 82, icon = 1378282, name = "Call Dreadstalkers", sourceType = "offensive" },
            { spellID = 111898, defaultCD = 120, category = "offensive", priority = 82, icon = 237562, name = "Grimoire: Felguard", sourceType = "offensive" },
            { spellID = 152108, defaultCD = 30, category = "offensive", priority = 82, icon = 409545, name = "Cataclysm", sourceType = "offensive" },
            { spellID = 196447, defaultCD = 25, category = "offensive", priority = 82, icon = 840407, name = "Channel Demonfire", sourceType = "offensive" },
            { spellID = 205179, defaultCD = 45, category = "offensive", priority = 82, icon = 132886, name = "Phantom Singularity", sourceType = "offensive" },
            { spellID = 205180, defaultCD = 120, category = "offensive", priority = 82, icon = 1416161, name = "Summon Darkglare", sourceType = "offensive" },
            { spellID = 212459, defaultCD = 120, category = "offensive", priority = 82, icon = 1113433, name = "Call Fel Lord", sourceType = "offensive" },
            { spellID = 264119, defaultCD = 25, category = "offensive", priority = 82, icon = 1616211, name = "Summon Vilefiend", sourceType = "offensive" },
            { spellID = 264130, defaultCD = 30, category = "offensive", priority = 82, icon = 236290, name = "Power Siphon", sourceType = "offensive" },
            { spellID = 265187, defaultCD = 60, category = "offensive", priority = 82, icon = 2065628, name = "Summon Demonic Tyrant", sourceType = "offensive" },
            { spellID = 267171, defaultCD = 60, category = "offensive", priority = 82, icon = 236292, name = "Demonic Strength", sourceType = "offensive" },
            { spellID = 267211, defaultCD = 30, category = "offensive", priority = 82, icon = 132182, name = "Bilescourge Bombers", sourceType = "offensive" },
            { spellID = 278350, defaultCD = 30, category = "offensive", priority = 82, icon = 1391774, name = "Vile Taint", sourceType = "offensive" },
            { spellID = 328774, defaultCD = 60, category = "offensive", priority = 82, icon = 136132, name = "Amplify Curse", sourceType = "offensive" },
            { spellID = 353753, defaultCD = 30, category = "offensive", priority = 82, icon = 1117883, name = "Bonds of Fel", sourceType = "offensive" },
            { spellID = 386951, defaultCD = 30, category = "offensive", priority = 82, icon = 460857, name = "Soul Swap", sourceType = "offensive" },
            { spellID = 386997, defaultCD = 60, category = "offensive", priority = 82, icon = 6035321, name = "Soul Rot", sourceType = "offensive" },
            { spellID = 387976, defaultCD = 45, category = "offensive", priority = 82, icon = 607513, name = "Dimensional Rift", sourceType = "offensive", maxCharges = 3 },
            { spellID = 410598, defaultCD = 60, category = "offensive", priority = 82, icon = 5260437, name = "Soul Rip", sourceType = "offensive" },
            { spellID = 417537, defaultCD = 45, category = "offensive", priority = 82, icon = 828455, name = "Oblivion", sourceType = "offensive" },
            { spellID = 442726, defaultCD = 60, category = "offensive", priority = 82, icon = 5927631, name = "Malevolence", sourceType = "offensive" },
            { spellID = 455465, defaultCD = 25, category = "offensive", priority = 82, icon = 1709932, name = "Summon Gloomhound", sourceType = "offensive" },
            { spellID = 455476, defaultCD = 25, category = "offensive", priority = 82, icon = 1709931, name = "Summon Charhound", sourceType = "offensive" },
            { spellID = 1218128, defaultCD = 60, category = "offensive", priority = 82, icon = 538744, name = "Bloodstone", sourceType = "offensive" },
        },
        utility = {
            { spellID = 5484, defaultCD = 40, category = "utility", priority = 74, icon = 607852, name = "Howl of Terror", sourceType = "aoeCC" },
            { spellID = 30283, defaultCD = 60, category = "utility", priority = 74, icon = 607865, name = "Shadowfury", sourceType = "aoeCC" },
            { spellID = 6789, defaultCD = 45, category = "utility", priority = 73, icon = 607853, name = "Mortal Coil", sourceType = "cc" },
            { spellID = 353294, defaultCD = 60, category = "utility", priority = 71, icon = 4067372, name = "Shadow Rift", sourceType = "disarm" },
            { spellID = 48020, defaultCD = 30, category = "utility", priority = 62, icon = 237560, name = "Demonic Circle: Teleport", sourceType = "movement" },
            { spellID = 80240, defaultCD = 30, category = "utility", priority = 60, icon = 460695, name = "Havoc", sourceType = "other" },
            { spellID = 108503, defaultCD = 30, category = "utility", priority = 60, icon = 538443, name = "Grimoire of Sacrifice", sourceType = "other" },
            { spellID = 200546, defaultCD = 45, category = "utility", priority = 60, icon = 1380866, name = "Bane of Havoc", sourceType = "other" },
            { spellID = 333889, defaultCD = 180, category = "utility", priority = 60, icon = 237564, name = "Fel Domination", sourceType = "other" },
        },
        trinkets = {
        },
    },
    WARRIOR = {
        interrupts = {
            { spellID = 6552, defaultCD = 15, category = "interrupt", priority = 100, icon = 132938, name = "Pummel", sourceType = "interrupt" },
            { spellID = 386071, defaultCD = 90, category = "interrupt", priority = 100, icon = 132091, name = "Disrupting Shout", sourceType = "interrupt" },
        },
        defensives = {
            { spellID = 213871, defaultCD = 15, category = "defensive", priority = 95, icon = 132359, name = "Bodyguard", sourceType = "externalDefensive" },
            { spellID = 236273, defaultCD = 60, category = "defensive", priority = 95, icon = 1455893, name = "Duel", sourceType = "externalDefensive" },
            { spellID = 97462, defaultCD = 180, category = "defensive", priority = 93, icon = 132351, name = "Rallying Cry", sourceType = "raidDefensive" },
            { spellID = 118038, defaultCD = 120, category = "defensive", priority = 92, icon = 132336, name = "Die by the Sword", sourceType = "defensive" },
            { spellID = 184364, defaultCD = 120, category = "defensive", priority = 92, icon = 132345, name = "Enraged Regeneration", sourceType = "defensive" },
            { spellID = 871, defaultCD = 180, category = "defensive", priority = 88, icon = 132362, name = "Shield Wall", sourceType = "tankDefensive" },
            { spellID = 1160, defaultCD = 45, category = "defensive", priority = 88, icon = 132366, name = "Demoralizing Shout", sourceType = "tankDefensive" },
            { spellID = 2565, defaultCD = 16, category = "defensive", priority = 88, icon = 132110, name = "Shield Block", sourceType = "tankDefensive" },
            { spellID = 12975, defaultCD = 180, category = "defensive", priority = 88, icon = 135871, name = "Last Stand", sourceType = "tankDefensive" },
            { spellID = 386394, defaultCD = 180, category = "defensive", priority = 88, icon = 132344, name = "Battle-Scarred Veteran", sourceType = "tankDefensive" },
            { spellID = 3411, defaultCD = 30, category = "defensive", priority = 86, icon = 132365, name = "Intervene", sourceType = "counterCC" },
            { spellID = 18499, defaultCD = 60, category = "defensive", priority = 86, icon = 136009, name = "Berserker Rage", sourceType = "counterCC" },
            { spellID = 23920, defaultCD = 25, category = "defensive", priority = 86, icon = 132361, name = "Spell Reflection", sourceType = "counterCC", cooldownBySpec = { [73] = 20 } },
            { spellID = 384100, defaultCD = 60, category = "defensive", priority = 86, icon = 136009, name = "Berserker Shout", sourceType = "counterCC" },
            { spellID = 1219201, defaultCD = 60, category = "defensive", priority = 86, icon = 136009, name = "Berserker Roar", sourceType = "counterCC" },
            { spellID = 202168, defaultCD = 25, category = "defensive", priority = 84, icon = 589768, name = "Impending Victory", sourceType = "heal" },
        },
        offensives = {
            { spellID = 1719, defaultCD = 90, category = "offensive", priority = 82, icon = 458972, name = "Recklessness", sourceType = "offensive" },
            { spellID = 107574, defaultCD = 90, category = "offensive", priority = 82, icon = 613534, name = "Avatar", sourceType = "offensive" },
            { spellID = 167105, defaultCD = 45, category = "offensive", priority = 82, icon = 464973, name = "Colossus Smash", sourceType = "offensive" },
            { spellID = 205800, defaultCD = 20, category = "offensive", priority = 82, icon = 136080, name = "Oppressor", sourceType = "offensive" },
            { spellID = 227847, defaultCD = 90, category = "offensive", priority = 82, icon = 236303, name = "Bladestorm", sourceType = "offensive" },
            { spellID = 228920, defaultCD = 90, category = "offensive", priority = 82, icon = 970854, name = "Ravager", sourceType = "offensive" },
            { spellID = 260643, defaultCD = 21, category = "offensive", priority = 82, icon = 2065621, name = "Skullsplitter", sourceType = "offensive" },
            { spellID = 260708, defaultCD = 30, category = "offensive", priority = 82, icon = 132306, name = "Sweeping Strikes", sourceType = "offensive", specs = { 71 } },
            { spellID = 262161, defaultCD = 45, category = "offensive", priority = 82, icon = 2065633, name = "Warbreaker", sourceType = "offensive" },
            { spellID = 376079, defaultCD = 90, category = "offensive", priority = 82, icon = 6035322, name = "Champion's Spear", sourceType = "offensive" },
            { spellID = 384110, defaultCD = 45, category = "offensive", priority = 82, icon = 460959, name = "Wrecking Throw", sourceType = "offensive" },
            { spellID = 384318, defaultCD = 90, category = "offensive", priority = 82, icon = 642418, name = "Thunderous Roar", sourceType = "offensive" },
            { spellID = 385059, defaultCD = 45, category = "offensive", priority = 82, icon = 1278409, name = "Odyn's Fury", sourceType = "offensive" },
            { spellID = 436358, defaultCD = 45, category = "offensive", priority = 82, icon = 5927618, name = "Demolish", sourceType = "offensive" },
        },
        utility = {
            { spellID = 5246, defaultCD = 90, category = "utility", priority = 74, icon = 132154, name = "Intimidating Shout", sourceType = "aoeCC" },
            { spellID = 46968, defaultCD = 40, category = "utility", priority = 74, icon = 236312, name = "Shockwave", sourceType = "aoeCC" },
            { spellID = 107570, defaultCD = 30, category = "utility", priority = 73, icon = 613535, name = "Storm Bolt", sourceType = "cc" },
            { spellID = 385952, defaultCD = 45, category = "utility", priority = 73, icon = 4667427, name = "Shield Charge", sourceType = "cc" },
            { spellID = 236077, defaultCD = 45, category = "utility", priority = 71, icon = 132343, name = "Disarm", sourceType = "disarm" },
            { spellID = 383762, defaultCD = 180, category = "utility", priority = 70, icon = 136088, name = "Bitter Immunity", sourceType = "dispel" },
            { spellID = 329038, defaultCD = 20, category = "utility", priority = 69, icon = 132277, name = "Bloodrage", sourceType = "freedom" },
            { spellID = 100, defaultCD = 20, category = "utility", priority = 62, icon = 132337, name = "Charge", sourceType = "movement" },
            { spellID = 6544, defaultCD = 45, category = "utility", priority = 62, icon = 236171, name = "Heroic Leap", sourceType = "movement" },
            { spellID = 206572, defaultCD = 45, category = "utility", priority = 62, icon = 1380676, name = "Dragon Charge", sourceType = "movement" },
            { spellID = 12323, defaultCD = 30, category = "utility", priority = 60, icon = 136147, name = "Piercing Howl", sourceType = "other" },
            { spellID = 64382, defaultCD = 180, category = "utility", priority = 60, icon = 311430, name = "Shattering Throw", sourceType = "other" },
            { spellID = 355, defaultCD = 8, category = "utility", priority = 42, icon = 136080, name = "Taunt", sourceType = "taunt" },
            { spellID = 1161, defaultCD = 120, category = "utility", priority = 42, icon = 132091, name = "Challenging Shout", sourceType = "taunt", specs = { 73 } },
        },
        trinkets = {
        },
    },
    GENERIC = {
        interrupts = {
        },
        defensives = {
        },
        offensives = {
        },
        utility = {
            { spellID = 7744, defaultCD = 120, category = "racial", priority = 66, icon = 136187, name = "Will of the Forsaken", sourceType = "racial" },
            { spellID = 20549, defaultCD = 90, category = "racial", priority = 66, icon = 132368, name = "War Stomp", sourceType = "racial" },
            { spellID = 20572, defaultCD = 120, category = "racial", priority = 66, icon = 135726, name = "Blood Fury", sourceType = "racial" },
            { spellID = 20589, defaultCD = 60, category = "racial", priority = 66, icon = 132309, name = "Escape Artist", sourceType = "racial" },
            { spellID = 20594, defaultCD = 120, category = "racial", priority = 66, icon = 136225, name = "Stoneform", sourceType = "racial" },
            { spellID = 26297, defaultCD = 180, category = "racial", priority = 66, icon = 135727, name = "Berserking", sourceType = "racial" },
            { spellID = 58984, defaultCD = 120, category = "racial", priority = 66, icon = 132089, name = "Shadowmeld", sourceType = "racial" },
            { spellID = 59542, defaultCD = 120, category = "racial", priority = 66, icon = 135923, name = "Gift of the Naaru", sourceType = "racial" },
            { spellID = 59752, defaultCD = 180, category = "racial", priority = 66, icon = 136129, name = "Will to Survive", sourceType = "racial" },
            { spellID = 68992, defaultCD = 90, category = "racial", priority = 66, icon = 366937, name = "Darkflight", sourceType = "racial" },
            { spellID = 69070, defaultCD = 90, category = "racial", priority = 66, icon = 370769, name = "Rocket Jump", sourceType = "racial" },
            { spellID = 107079, defaultCD = 120, category = "racial", priority = 66, icon = 572035, name = "Quaking Palm", sourceType = "racial" },
            { spellID = 129597, defaultCD = 120, category = "racial", priority = 66, icon = 136222, name = "Arcane Torrent", sourceType = "racial" },
            { spellID = 255647, defaultCD = 150, category = "racial", priority = 66, icon = 1724000, name = "Light's Judgment", sourceType = "racial" },
            { spellID = 255654, defaultCD = 120, category = "racial", priority = 66, icon = 1723987, name = "Bull Rush", sourceType = "racial" },
            { spellID = 256948, defaultCD = 180, category = "racial", priority = 66, icon = 1724004, name = "Spatial Rift", sourceType = "racial" },
            { spellID = 260364, defaultCD = 180, category = "racial", priority = 66, icon = 1851463, name = "Arcane Pulse", sourceType = "racial" },
            { spellID = 265221, defaultCD = 120, category = "racial", priority = 66, icon = 1786406, name = "Fireblood", sourceType = "racial" },
            { spellID = 274738, defaultCD = 120, category = "racial", priority = 66, icon = 2021574, name = "Ancestral Call", sourceType = "racial" },
            { spellID = 287712, defaultCD = 150, category = "racial", priority = 66, icon = 2447782, name = "Haymaker", sourceType = "racial" },
            { spellID = 291944, defaultCD = 180, category = "racial", priority = 66, icon = 1850550, name = "Regeneratin'", sourceType = "racial" },
            { spellID = 312411, defaultCD = 90, category = "racial", priority = 66, icon = 3193416, name = "Bag of Tricks", sourceType = "racial" },
            { spellID = 312916, defaultCD = 150, category = "racial", priority = 66, icon = 3192688, name = "Emergency Failsafe", sourceType = "racial" },
            { spellID = 312924, defaultCD = 180, category = "racial", priority = 66, icon = 3192686, name = "Hyper Organic Light Originator", sourceType = "racial" },
            { spellID = 357214, defaultCD = 180, category = "racial", priority = 66, icon = 4622488, name = "Wing Buffet", sourceType = "racial" },
            { spellID = 436344, defaultCD = 120, category = "racial", priority = 66, icon = 5788297, name = "Azerite Surge", sourceType = "racial" },
            { spellID = 6262, defaultCD = 60, category = "utility", priority = 36, icon = 538745, name = "Healthstone", sourceType = "consumable" },
            { spellID = 113942, defaultCD = 90, category = "utility", priority = 36, icon = 607512, name = "Demonic Gateway", sourceType = "consumable" },
            { spellID = 408234, defaultCD = 120, category = "utility", priority = 36, icon = 5199618, name = "Activate Weyrnstone", sourceType = "consumable" },
            { spellID = 431416, defaultCD = 300, category = "utility", priority = 36, icon = 5931169, name = "Algari Healing Potion", sourceType = "consumable" },
        },
        trinkets = {
            { spellID = 336126, defaultCD = 120, category = "trinket", priority = 99, icon = 1322720, name = "Gladiator's Medallion", sourceType = "pvptrinket", cooldownBySpec = { [65] = 90, [105] = 90, [256] = 90, [257] = 90, [264] = 90, [270] = 90, [1468] = 90 }, sharedCD = { 336126, 336135 } },
            { spellID = 336135, defaultCD = 60, category = "trinket", priority = 99, icon = 895886, name = "Adaptation", sourceType = "pvptrinket", sharedCD = { 336126, 336135 } },
            { spellID = 271374, defaultCD = 120, category = "trinket", priority = 97, icon = 237290, name = "Razdunk's Big Red Button", sourceType = "trinket" },
            { spellID = 300142, defaultCD = 120, category = "trinket", priority = 97, icon = 1981725, name = "Hyperthread Wristwraps", sourceType = "trinket" },
            { spellID = 345228, defaultCD = 60, category = "trinket", priority = 97, icon = 135884, name = "Gladiator's Badge", sourceType = "trinket" },
            { spellID = 345231, defaultCD = 120, category = "trinket", priority = 97, icon = 132344, name = "Gladiator's Emblem", sourceType = "trinket" },
            { spellID = 345739, defaultCD = 90, category = "trinket", priority = 97, icon = 133733, name = "Grim Codex", sourceType = "trinket" },
            { spellID = 443337, defaultCD = 90, category = "trinket", priority = 97, icon = 5899332, name = "Charged Stormrook Plume", sourceType = "trinket" },
            { spellID = 443529, defaultCD = 90, category = "trinket", priority = 97, icon = 1379201, name = "Burin of the Candle King", sourceType = "trinket" },
            { spellID = 443536, defaultCD = 120, category = "trinket", priority = 97, icon = 5948040, name = "Bursting Lightshard", sourceType = "trinket" },
            { spellID = 448904, defaultCD = 90, category = "trinket", priority = 97, icon = 4548852, name = "Ravenous Honey Buzzer", sourceType = "trinket" },
            { spellID = 455486, defaultCD = 60, category = "trinket", priority = 97, icon = 4626288, name = "Goldenglow Censer", sourceType = "trinket" },
            { spellID = 466652, defaultCD = 90, category = "trinket", priority = 97, icon = 6383539, name = "Vexie's Pit Whistle", sourceType = "trinket" },
            { spellID = 466810, defaultCD = 90, category = "trinket", priority = 97, icon = 6383449, name = "Chromebustible Bomb Suit", sourceType = "trinket" },
            { spellID = 470286, defaultCD = 120, category = "trinket", priority = 97, icon = 6383523, name = "Torq's Big Red Button", sourceType = "trinket" },
            { spellID = 471059, defaultCD = 120, category = "trinket", priority = 97, icon = 6383486, name = "Geargrinder's Spare Keys", sourceType = "trinket" },
            { spellID = 471142, defaultCD = 120, category = "trinket", priority = 97, icon = 6383461, name = "Flarendo's Pilot Light", sourceType = "trinket" },
            { spellID = 1213437, defaultCD = 90, category = "trinket", priority = 97, icon = 1719207, name = "Goo-blin Grenade", sourceType = "trinket" },
            { spellID = 1216605, defaultCD = 90, category = "trinket", priority = 97, icon = 136067, name = "Ratfang Toxin", sourceType = "trinket" },
            { spellID = 1219102, defaultCD = 120, category = "trinket", priority = 97, icon = 1500928, name = "Ringing Ritual Mud", sourceType = "trinket" },
            { spellID = 1219294, defaultCD = 120, category = "trinket", priority = 97, icon = 517112, name = "Garbagemancer's Last Resort", sourceType = "trinket" },
            { spellID = 1223611, defaultCD = 360, category = "trinket", priority = 97, icon = 7110834, name = "Ethereal Exhaustion", sourceType = "trinket", cooldownBySpec = { [66] = 360, [73] = 360, [104] = 360, [250] = 360, [268] = 360, [581] = 360 } },
            { spellID = 1232721, defaultCD = 90, category = "trinket", priority = 97, icon = 7137503, name = "Loom'ithar's Living Silk", sourceType = "trinket" },
            { spellID = 1232802, defaultCD = 120, category = "trinket", priority = 97, icon = 7137585, name = "Araz's Ritual Forge", sourceType = "trinket" },
            { spellID = 1235425, defaultCD = 60, category = "trinket", priority = 97, icon = 7137533, name = "Soulbinder's Embrace", sourceType = "trinket" },
            { spellID = 1236691, defaultCD = 480, category = "trinket", priority = 97, icon = 7137561, name = "All-Devouring Nucleus", sourceType = "trinket" },
        },
    },
}

GT.CooldownIndexBySpell = {}
GT.TrinketIndexBySpell = {}

local INDEX_CLASS_ORDER = { "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR", "GENERIC" }
local INDEX_BUCKET_ORDER = { "interrupts", "defensives", "offensives", "utility", "trinkets" }

local function normalizeSpecData(entry)
    local specs = entry.specs
    if type(specs) ~= "table" or #specs == 0 then
        entry.specLookup = nil
        entry.specID = nil
        return
    end

    local lookup = {}
    local uniqueCount = 0
    local onlySpecID = nil
    for _, specID in ipairs(specs) do
        if type(specID) == "number" and specID > 0 and not lookup[specID] then
            lookup[specID] = true
            uniqueCount = uniqueCount + 1
            onlySpecID = specID
        end
    end

    entry.specLookup = next(lookup) and lookup or nil
    if uniqueCount == 1 then
        entry.specID = onlySpecID
    else
        entry.specID = nil
    end
end

local function addIndexedEntry(indexTable, spellID, entry)
    if not spellID then
        return
    end

    local list = indexTable[spellID]
    if not list then
        list = {}
        indexTable[spellID] = list
    end

    list[#list + 1] = entry
end

for _, classFile in ipairs(INDEX_CLASS_ORDER) do
    local buckets = GT.CooldownData[classFile]
    if buckets then
        for _, bucketName in ipairs(INDEX_BUCKET_ORDER) do
            local entries = buckets[bucketName]
            if entries then
                for _, entry in ipairs(entries) do
                    entry.classFile = classFile
                    entry.bucket = bucketName
                    normalizeSpecData(entry)

                    addIndexedEntry(GT.CooldownIndexBySpell, entry.spellID, entry)
                    if bucketName == "trinkets" or entry.category == "trinket" then
                        addIndexedEntry(GT.TrinketIndexBySpell, entry.spellID, entry)
                    end
                end
            end
        end
    end
end

local function selectEntry(entries, classFile, specID)
    if type(entries) ~= "table" then
        return nil
    end

    local classFallback = nil
    local genericFallback = nil

    for _, entry in ipairs(entries) do
        if classFile and entry.classFile == classFile then
            if specID and entry.specLookup then
                if entry.specLookup[specID] then
                    return entry
                end
            elseif not entry.specLookup then
                classFallback = classFallback or entry
            elseif not specID then
                classFallback = classFallback or entry
            end
        elseif entry.classFile == "GENERIC" then
            genericFallback = genericFallback or entry
        end
    end

    if classFallback then
        return classFallback
    end

    return genericFallback or entries[1]
end

function GT:GetCooldownEntryForSpell(spellID, classFile, specID)
    local entries = self.CooldownIndexBySpell[spellID]
    return selectEntry(entries, classFile, specID)
end

function GT:GetTrinketEntryForSpell(spellID, classFile, specID)
    local entries = self.TrinketIndexBySpell[spellID]
    return selectEntry(entries, classFile, specID)
end
