local _, GT = ...

GT.SpecIDs = GT.SpecIDs or {
    BLOOD_DK = 250,
    FROST_DK = 251,
    UNHOLY_DK = 252,

    HAVOC_DH = 577,
    VENGEANCE_DH = 581,

    BALANCE_DRUID = 102,
    FERAL_DRUID = 103,
    GUARDIAN_DRUID = 104,
    RESTORATION_DRUID = 105,

    DEVASTATION_EVOKER = 1467,
    PRESERVATION_EVOKER = 1468,
    AUGMENTATION_EVOKER = 1473,

    BEAST_MASTERY_HUNTER = 253,
    MARKSMANSHIP_HUNTER = 254,
    SURVIVAL_HUNTER = 255,

    ARCANE_MAGE = 62,
    FIRE_MAGE = 63,
    FROST_MAGE = 64,

    BREWMASTER_MONK = 268,
    WINDWALKER_MONK = 269,
    MISTWEAVER_MONK = 270,

    HOLY_PALADIN = 65,
    PROTECTION_PALADIN = 66,
    RETRIBUTION_PALADIN = 70,

    DISCIPLINE_PRIEST = 256,
    HOLY_PRIEST = 257,
    SHADOW_PRIEST = 258,

    ASSASSINATION_ROGUE = 259,
    OUTLAW_ROGUE = 260,
    SUBTLETY_ROGUE = 261,

    ELEMENTAL_SHAMAN = 262,
    ENHANCEMENT_SHAMAN = 263,
    RESTORATION_SHAMAN = 264,

    AFFLICTION_WARLOCK = 265,
    DEMONOLOGY_WARLOCK = 266,
    DESTRUCTION_WARLOCK = 267,

    ARMS_WARRIOR = 71,
    FURY_WARRIOR = 72,
    PROTECTION_WARRIOR = 73,
}

local SPEC = GT.SpecIDs

local function specList(...)
    local list = {}
    for index = 1, select("#", ...) do
        local specID = select(index, ...)
        if type(specID) == "number" and specID > 0 then
            list[#list + 1] = specID
        end
    end
    return list
end

local function E(spellID, defaultCD, category, priority, icon, options)
    local entry = {
        spellID = spellID,
        defaultCD = defaultCD,
        category = category,
        priority = priority or 50,
        icon = icon,
    }

    if type(options) == "table" then
        if type(options.specs) == "table" and #options.specs > 0 then
            entry.specs = options.specs
        end
        if type(options.cooldownBySpec) == "table" then
            entry.cooldownBySpec = options.cooldownBySpec
        end
        if type(options.maxCharges) == "number" and options.maxCharges > 1 then
            entry.maxCharges = options.maxCharges
        end
    end

    return entry
end

GT.CooldownData = {
    DEATHKNIGHT = {
        interrupts = {
            E(47528, 15, "interrupt", 100), -- Mind Freeze
        },
        defensives = {
            E(48707, 60, "defensive", 95), -- Anti-Magic Shell
            E(48792, 120, "defensive", 95), -- Icebound Fortitude
            E(55233, 90, "defensive", 90, nil, { specs = specList(SPEC.BLOOD_DK) }), -- Vampiric Blood
            E(51052, 120, "defensive", 88), -- Anti-Magic Zone
            E(49039, 120, "defensive", 82), -- Lichborne
        },
        offensives = {
            E(49028, 120, "offensive", 90, nil, { specs = specList(SPEC.BLOOD_DK) }), -- Dancing Rune Weapon
            E(47568, 120, "offensive", 86), -- Empower Rune Weapon
            E(152279, 120, "offensive", 82, nil, { specs = specList(SPEC.FROST_DK) }), -- Breath of Sindragosa
            E(383269, 120, "offensive", 80), -- Abomination Limb
            E(42650, 180, "offensive", 74), -- Army of the Dead
        },
        utility = {
            E(108199, 120, "utility", 70), -- Gorefiend's Grasp
            E(49576, 25, "utility", 66), -- Death Grip
            E(221562, 45, "utility", 64), -- Asphyxiate
        },
        trinkets = {},
    },
    DEMONHUNTER = {
        interrupts = {
            E(183752, 15, "interrupt", 100), -- Disrupt
        },
        defensives = {
            E(198589, 60, "defensive", 92, nil, { specs = specList(SPEC.HAVOC_DH) }), -- Blur
            E(196718, 180, "defensive", 90), -- Darkness
            E(187827, 180, "defensive", 86, nil, { specs = specList(SPEC.VENGEANCE_DH) }), -- Metamorphosis (Vengeance)
            E(196555, 180, "defensive", 84, nil, { specs = specList(SPEC.HAVOC_DH) }), -- Netherwalk
        },
        offensives = {
            E(198013, 40, "offensive", 80, nil, { specs = specList(SPEC.HAVOC_DH) }), -- Eye Beam
            E(191427, 180, "offensive", 84, nil, { specs = specList(SPEC.HAVOC_DH) }), -- Metamorphosis (Havoc)
            E(370965, 90, "offensive", 82), -- The Hunt
            E(188499, 120, "offensive", 74), -- Blade Dance windows
        },
        utility = {
            E(179057, 45, "utility", 74), -- Chaos Nova
            E(207684, 90, "utility", 70), -- Sigil of Misery
            E(204490, 60, "utility", 68), -- Sigil of Silence
            E(217832, 45, "utility", 66), -- Imprison
        },
        trinkets = {},
    },
    DRUID = {
        interrupts = {
            E(106839, 15, "interrupt", 100), -- Skull Bash
        },
        defensives = {
            E(22812, 60, "defensive", 92), -- Barkskin
            E(61336, 180, "defensive", 90, nil, { specs = specList(SPEC.FERAL_DRUID, SPEC.GUARDIAN_DRUID), maxCharges = 2 }), -- Survival Instincts
            E(102342, 90, "defensive", 88, nil, { specs = specList(SPEC.RESTORATION_DRUID) }), -- Ironbark
            E(22842, 36, "defensive", 84, nil, { specs = specList(SPEC.GUARDIAN_DRUID), maxCharges = 2 }), -- Frenzied Regeneration
        },
        offensives = {
            E(194223, 180, "offensive", 88, nil, { specs = specList(SPEC.BALANCE_DRUID) }), -- Celestial Alignment
            E(102560, 180, "offensive", 84, nil, { specs = specList(SPEC.BALANCE_DRUID) }), -- Incarnation: Chosen of Elune
            E(106951, 180, "offensive", 84, nil, { specs = specList(SPEC.FERAL_DRUID) }), -- Berserk
            E(323764, 60, "offensive", 78), -- Convoke the Spirits
        },
        utility = {
            E(740, 180, "utility", 80, nil, { specs = specList(SPEC.RESTORATION_DRUID) }), -- Tranquility
            E(78675, 60, "utility", 76, nil, { specs = specList(SPEC.BALANCE_DRUID) }), -- Solar Beam
            E(102793, 60, "utility", 72), -- Ursol's Vortex
            E(132469, 30, "utility", 68), -- Typhoon
            E(99, 30, "utility", 66), -- Incapacitating Roar
        },
        trinkets = {},
    },
    EVOKER = {
        interrupts = {
            E(351338, 40, "interrupt", 100), -- Quell
        },
        defensives = {
            E(363916, 90, "defensive", 92), -- Obsidian Scales
            E(374348, 90, "defensive", 88), -- Renewing Blaze
            E(357170, 60, "defensive", 84), -- Time Dilation
        },
        offensives = {
            E(375087, 120, "offensive", 88, nil, { specs = specList(SPEC.DEVASTATION_EVOKER) }), -- Dragonrage
            E(403631, 120, "offensive", 84, nil, { specs = specList(SPEC.AUGMENTATION_EVOKER) }), -- Breath of Eons
            E(390386, 90, "offensive", 78), -- Fury of the Aspects (group lust)
        },
        utility = {
            E(363534, 240, "utility", 82, nil, { specs = specList(SPEC.PRESERVATION_EVOKER) }), -- Rewind
            E(370665, 60, "utility", 74), -- Rescue
            E(377509, 90, "utility", 72), -- Time Stop
            E(359816, 90, "utility", 68), -- Dream Flight
        },
        trinkets = {},
    },
    HUNTER = {
        interrupts = {
            E(147362, 24, "interrupt", 100, nil, { specs = specList(SPEC.BEAST_MASTERY_HUNTER, SPEC.MARKSMANSHIP_HUNTER) }), -- Counter Shot
            E(187707, 15, "interrupt", 98, nil, { specs = specList(SPEC.SURVIVAL_HUNTER) }), -- Muzzle
        },
        defensives = {
            E(186265, 180, "defensive", 92), -- Aspect of the Turtle
            E(109304, 120, "defensive", 88), -- Exhilaration
            E(53480, 60, "defensive", 78), -- Roar of Sacrifice
            E(264735, 120, "defensive", 74), -- Survival of the Fittest
        },
        offensives = {
            E(19574, 90, "offensive", 88, nil, { specs = specList(SPEC.BEAST_MASTERY_HUNTER) }), -- Bestial Wrath
            E(288613, 120, "offensive", 84, nil, { specs = specList(SPEC.MARKSMANSHIP_HUNTER) }), -- Trueshot
            E(360952, 120, "offensive", 82, nil, { specs = specList(SPEC.SURVIVAL_HUNTER) }), -- Coordinated Assault
            E(359844, 120, "offensive", 80, nil, { specs = specList(SPEC.BEAST_MASTERY_HUNTER) }), -- Call of the Wild
        },
        utility = {
            E(187650, 30, "utility", 72), -- Freezing Trap
            E(781, 20, "utility", 68), -- Disengage
            E(19577, 60, "utility", 66), -- Intimidation
            E(109248, 45, "utility", 64), -- Binding Shot
        },
        trinkets = {},
    },
    MAGE = {
        interrupts = {
            E(2139, 24, "interrupt", 100), -- Counterspell
        },
        defensives = {
            E(45438, 240, "defensive", 96), -- Ice Block
            E(342245, 60, "defensive", 90), -- Alter Time
            E(55342, 120, "defensive", 86), -- Mirror Image
            E(235219, 300, "defensive", 80), -- Cold Snap
        },
        offensives = {
            E(190319, 120, "offensive", 90, nil, { specs = specList(SPEC.FIRE_MAGE) }), -- Combustion
            E(12472, 180, "offensive", 86, nil, { specs = specList(SPEC.FROST_MAGE) }), -- Icy Veins
            E(12042, 90, "offensive", 84, nil, { specs = specList(SPEC.ARCANE_MAGE) }), -- Arcane Power
            E(80353, 300, "offensive", 70), -- Time Warp
        },
        utility = {
            E(66, 300, "utility", 68), -- Invisibility
            E(122, 30, "utility", 66), -- Frost Nova
            E(31661, 45, "utility", 64, nil, { specs = specList(SPEC.FIRE_MAGE) }), -- Dragon's Breath
            E(113724, 45, "utility", 62), -- Ring of Frost
        },
        trinkets = {},
    },
    MONK = {
        interrupts = {
            E(116705, 15, "interrupt", 100), -- Spear Hand Strike
        },
        defensives = {
            E(122783, 90, "defensive", 90), -- Diffuse Magic
            E(122470, 90, "defensive", 88, nil, { specs = specList(SPEC.WINDWALKER_MONK) }), -- Touch of Karma
            E(115203, 300, "defensive", 86), -- Fortifying Brew
            E(122278, 120, "defensive", 82), -- Dampen Harm
        },
        offensives = {
            E(137639, 90, "offensive", 86, nil, { specs = specList(SPEC.WINDWALKER_MONK) }), -- Storm, Earth, and Fire
            E(152173, 90, "offensive", 84, nil, { specs = specList(SPEC.WINDWALKER_MONK) }), -- Serenity
            E(123904, 120, "offensive", 80, nil, { specs = specList(SPEC.WINDWALKER_MONK) }), -- Invoke Xuen
        },
        utility = {
            E(115078, 45, "utility", 72), -- Paralysis
            E(119381, 60, "utility", 70), -- Leg Sweep
            E(116844, 45, "utility", 68), -- Ring of Peace
            E(115310, 180, "utility", 66, nil, { specs = specList(SPEC.MISTWEAVER_MONK) }), -- Revival
        },
        trinkets = {},
    },
    PALADIN = {
        interrupts = {
            E(96231, 15, "interrupt", 100), -- Rebuke
        },
        defensives = {
            E(642, 300, "defensive", 96), -- Divine Shield
            E(1022, 300, "defensive", 90), -- Blessing of Protection
            E(6940, 120, "defensive", 88), -- Blessing of Sacrifice
            E(31821, 180, "defensive", 86, nil, { specs = specList(SPEC.HOLY_PALADIN) }), -- Aura Mastery
            E(498, 60, "defensive", 82), -- Divine Protection
        },
        offensives = {
            E(31884, 120, "offensive", 90), -- Avenging Wrath
            E(231895, 120, "offensive", 88, nil, { specs = specList(SPEC.RETRIBUTION_PALADIN) }), -- Crusade
            E(375576, 60, "offensive", 78, nil, { specs = specList(SPEC.RETRIBUTION_PALADIN) }), -- Divine Toll windows
        },
        utility = {
            E(633, 600, "utility", 76), -- Lay on Hands
            E(210256, 45, "utility", 70), -- Blessing of Sanctuary
            E(1044, 25, "utility", 68), -- Blessing of Freedom
            E(853, 60, "utility", 66), -- Hammer of Justice
        },
        trinkets = {},
    },
    PRIEST = {
        interrupts = {
            E(15487, 45, "interrupt", 100, nil, { specs = specList(SPEC.SHADOW_PRIEST) }), -- Silence
        },
        defensives = {
            E(33206, 180, "defensive", 96, nil, { specs = specList(SPEC.DISCIPLINE_PRIEST) }), -- Pain Suppression
            E(47788, 180, "defensive", 96, nil, { specs = specList(SPEC.HOLY_PRIEST) }), -- Guardian Spirit
            E(62618, 180, "defensive", 90, nil, { specs = specList(SPEC.DISCIPLINE_PRIEST) }), -- Power Word: Barrier
            E(47585, 120, "defensive", 86, nil, { specs = specList(SPEC.SHADOW_PRIEST) }), -- Dispersion
            E(19236, 90, "defensive", 80), -- Desperate Prayer
        },
        offensives = {
            E(10060, 120, "offensive", 88), -- Power Infusion
            E(47536, 90, "offensive", 82, nil, { specs = specList(SPEC.DISCIPLINE_PRIEST) }), -- Rapture
            E(228260, 90, "offensive", 80, nil, { specs = specList(SPEC.SHADOW_PRIEST) }), -- Voidform
        },
        utility = {
            E(8122, 60, "utility", 74), -- Psychic Scream
            E(108968, 300, "utility", 66), -- Void Shift
            E(64901, 300, "utility", 64), -- Symbol of Hope
            E(32379, 15, "utility", 62), -- Shadow Word: Death utility windows
        },
        trinkets = {},
    },
    ROGUE = {
        interrupts = {
            E(1766, 15, "interrupt", 100), -- Kick
        },
        defensives = {
            E(5277, 120, "defensive", 92), -- Evasion
            E(31224, 120, "defensive", 92), -- Cloak of Shadows
            E(1966, 15, "defensive", 70), -- Feint
        },
        offensives = {
            E(13750, 180, "offensive", 88, nil, { specs = specList(SPEC.OUTLAW_ROGUE) }), -- Adrenaline Rush
            E(121471, 180, "offensive", 84, nil, { specs = specList(SPEC.SUBTLETY_ROGUE) }), -- Shadow Blades
            E(360194, 120, "offensive", 82, nil, { specs = specList(SPEC.ASSASSINATION_ROGUE) }), -- Deathmark
            E(185313, 60, "offensive", 78, nil, { specs = specList(SPEC.SUBTLETY_ROGUE) }), -- Shadow Dance
        },
        utility = {
            E(1856, 120, "utility", 84), -- Vanish
            E(2094, 120, "utility", 80), -- Blind
            E(408, 20, "utility", 72), -- Kidney Shot
            E(212182, 180, "utility", 70), -- Smoke Bomb
        },
        trinkets = {},
    },
    SHAMAN = {
        interrupts = {
            E(57994, 12, "interrupt", 100), -- Wind Shear
        },
        defensives = {
            E(108271, 90, "defensive", 92), -- Astral Shift
            E(98008, 180, "defensive", 90, nil, { specs = specList(SPEC.RESTORATION_SHAMAN) }), -- Spirit Link Totem
            E(108280, 180, "defensive", 88, nil, { specs = specList(SPEC.RESTORATION_SHAMAN) }), -- Healing Tide Totem
            E(198103, 300, "defensive", 80), -- Earth Elemental
        },
        offensives = {
            E(114051, 180, "offensive", 86), -- Ascendance
            E(191634, 60, "offensive", 80, nil, { specs = specList(SPEC.ELEMENTAL_SHAMAN) }), -- Stormkeeper
            E(51533, 120, "offensive", 78, nil, { specs = specList(SPEC.ENHANCEMENT_SHAMAN) }), -- Feral Spirit
            E(375982, 45, "offensive", 74), -- Primordial Wave
        },
        utility = {
            E(8143, 60, "utility", 76), -- Tremor Totem
            E(192058, 60, "utility", 72), -- Capacitor Totem
            E(204336, 24, "utility", 72), -- Grounding Totem
            E(79206, 120, "utility", 66), -- Spiritwalker's Grace
        },
        trinkets = {},
    },
    WARLOCK = {
        interrupts = {
            E(19647, 24, "interrupt", 100), -- Spell Lock
            E(119910, 24, "interrupt", 98), -- Spell Lock (alternate spellID)
        },
        defensives = {
            E(104773, 180, "defensive", 92), -- Unending Resolve
            E(108416, 60, "defensive", 84), -- Dark Pact
        },
        offensives = {
            E(1122, 180, "offensive", 88, nil, { specs = specList(SPEC.DESTRUCTION_WARLOCK) }), -- Summon Infernal
            E(205180, 120, "offensive", 84, nil, { specs = specList(SPEC.AFFLICTION_WARLOCK) }), -- Summon Darkglare
            E(267217, 180, "offensive", 80, nil, { specs = specList(SPEC.DEMONOLOGY_WARLOCK) }), -- Nether Portal
            E(113858, 120, "offensive", 78), -- Dark Soul
        },
        utility = {
            E(6789, 45, "utility", 76), -- Mortal Coil
            E(5484, 40, "utility", 72), -- Howl of Terror
            E(212295, 45, "utility", 70), -- Nether Ward
            E(710, 30, "utility", 66), -- Banish
        },
        trinkets = {},
    },
    WARRIOR = {
        interrupts = {
            E(6552, 15, "interrupt", 100), -- Pummel
        },
        defensives = {
            E(871, 240, "defensive", 92, nil, { specs = specList(SPEC.PROTECTION_WARRIOR) }), -- Shield Wall
            E(118038, 120, "defensive", 92, nil, { specs = specList(SPEC.ARMS_WARRIOR) }), -- Die by the Sword
            E(97462, 180, "defensive", 88), -- Rallying Cry
            E(12975, 180, "defensive", 84), -- Last Stand
            E(23920, 25, "defensive", 82), -- Spell Reflection
        },
        offensives = {
            E(1719, 90, "offensive", 90, nil, { specs = specList(SPEC.FURY_WARRIOR) }), -- Recklessness
            E(107574, 90, "offensive", 86), -- Avatar
            E(167105, 45, "offensive", 78, nil, { specs = specList(SPEC.ARMS_WARRIOR) }), -- Colossus Smash
            E(227847, 90, "offensive", 76, nil, { specs = specList(SPEC.FURY_WARRIOR) }), -- Bladestorm (Fury)
        },
        utility = {
            E(5246, 90, "utility", 74), -- Intimidating Shout
            E(107570, 30, "utility", 70), -- Storm Bolt
            E(46968, 40, "utility", 68), -- Shockwave
            E(236077, 45, "utility", 66), -- Disarm
        },
        trinkets = {},
    },
    GENERIC = {
        interrupts = {},
        defensives = {},
        offensives = {},
        utility = {},
        trinkets = {
            E(336126, 120, "trinket", 100), -- Gladiator's Medallion
            E(42292, 120, "trinket", 98), -- PvP Trinket (legacy)
            E(195710, 120, "trinket", 95), -- Honorable Medallion
            E(214027, 90, "trinket", 92), -- Adaptation
            E(59752, 180, "trinket", 88), -- Every Man for Himself / Will to Survive
            E(7744, 120, "trinket", 86), -- Will of the Forsaken
            E(20589, 60, "trinket", 84), -- Escape Artist
            E(20594, 120, "trinket", 84), -- Stoneform
        },
    },
}

GT.CooldownIndexBySpell = {}
GT.TrinketIndexBySpell = {}

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

for classFile, buckets in pairs(GT.CooldownData) do
    for bucketName, entries in pairs(buckets) do
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
