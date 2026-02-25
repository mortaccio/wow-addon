local _, GT = ...

local function E(spellID, defaultCD, category, priority, icon)
    return {
        spellID = spellID,
        defaultCD = defaultCD,
        category = category,
        priority = priority or 50,
        icon = icon,
    }
end

-- TODO: Expand entries with spec/talent/PvP-talent overrides and patch-version metadata.
GT.CooldownData = {
    DEATHKNIGHT = {
        interrupts = {
            E(47528, 15, "interrupt", 100), -- Mind Freeze
        },
        defensives = {
            E(48707, 60, "defensive", 90), -- Anti-Magic Shell
            E(48792, 120, "defensive", 90), -- Icebound Fortitude
            E(55233, 90, "defensive", 85), -- Vampiric Blood
            E(51052, 120, "defensive", 80), -- Anti-Magic Zone
        },
        offensives = {
            E(49028, 120, "offensive", 85), -- Dancing Rune Weapon
            E(47568, 120, "offensive", 80), -- Empower Rune Weapon
            E(152279, 120, "offensive", 75), -- Breath of Sindragosa
        },
        utility = {
            E(108199, 120, "utility", 65), -- Gorefiend's Grasp
        },
        trinkets = {},
    },
    DEMONHUNTER = {
        interrupts = {
            E(183752, 15, "interrupt", 100), -- Disrupt
        },
        defensives = {
            E(198589, 60, "defensive", 90), -- Blur
            E(196718, 180, "defensive", 85), -- Darkness
            E(191427, 180, "defensive", 85), -- Metamorphosis (Havoc)
        },
        offensives = {
            E(198013, 30, "offensive", 75), -- Eye Beam
            E(188499, 120, "offensive", 70), -- Blade Dance (The Hunt windows are spec/talent TODO)
        },
        utility = {
            E(179057, 45, "utility", 70), -- Chaos Nova
            E(207684, 90, "utility", 65), -- Sigil of Misery
        },
        trinkets = {},
    },
    DRUID = {
        interrupts = {
            E(106839, 15, "interrupt", 100), -- Skull Bash
        },
        defensives = {
            E(22812, 60, "defensive", 90), -- Barkskin
            E(61336, 180, "defensive", 90), -- Survival Instincts
            E(102342, 90, "defensive", 85), -- Ironbark
        },
        offensives = {
            E(194223, 180, "offensive", 85), -- Celestial Alignment
            E(102560, 180, "offensive", 80), -- Incarnation: Chosen of Elune
            E(106951, 180, "offensive", 80), -- Berserk
        },
        utility = {
            E(740, 180, "utility", 80), -- Tranquility
            E(78675, 60, "utility", 75), -- Solar Beam
            E(102793, 60, "utility", 65), -- Ursol's Vortex
        },
        trinkets = {},
    },
    EVOKER = {
        interrupts = {
            E(351338, 40, "interrupt", 100), -- Quell
        },
        defensives = {
            E(363916, 90, "defensive", 90), -- Obsidian Scales
            E(374348, 90, "defensive", 85), -- Renewing Blaze
        },
        offensives = {
            E(375087, 120, "offensive", 85), -- Dragonrage
            E(403631, 120, "offensive", 80), -- Breath of Eons
        },
        utility = {
            E(363534, 240, "utility", 80), -- Rewind
            E(370665, 120, "utility", 70), -- Rescue
        },
        trinkets = {},
    },
    HUNTER = {
        interrupts = {
            E(147362, 24, "interrupt", 100), -- Counter Shot
            E(187707, 15, "interrupt", 95), -- Muzzle
        },
        defensives = {
            E(186265, 180, "defensive", 90), -- Aspect of the Turtle
            E(109304, 120, "defensive", 85), -- Exhilaration
            E(53480, 60, "defensive", 75), -- Roar of Sacrifice
        },
        offensives = {
            E(19574, 90, "offensive", 85), -- Bestial Wrath
            E(288613, 120, "offensive", 80), -- Trueshot
            E(359844, 120, "offensive", 75), -- Call of the Wild
        },
        utility = {
            E(187650, 30, "utility", 70), -- Freezing Trap
            E(781, 20, "utility", 60), -- Disengage
        },
        trinkets = {},
    },
    MAGE = {
        interrupts = {
            E(2139, 24, "interrupt", 100), -- Counterspell
        },
        defensives = {
            E(45438, 240, "defensive", 95), -- Ice Block
            E(55342, 120, "defensive", 85), -- Mirror Image
            E(235219, 300, "defensive", 75), -- Cold Snap
        },
        offensives = {
            E(190319, 120, "offensive", 90), -- Combustion
            E(12472, 180, "offensive", 85), -- Icy Veins
            E(12042, 90, "offensive", 80), -- Arcane Power
        },
        utility = {
            E(66, 300, "utility", 65), -- Invisibility
            E(122, 30, "utility", 60), -- Frost Nova
        },
        trinkets = {},
    },
    MONK = {
        interrupts = {
            E(116705, 15, "interrupt", 100), -- Spear Hand Strike
        },
        defensives = {
            E(122783, 90, "defensive", 85), -- Diffuse Magic
            E(122470, 90, "defensive", 90), -- Touch of Karma
            E(115203, 300, "defensive", 85), -- Fortifying Brew
        },
        offensives = {
            E(137639, 90, "offensive", 85), -- Storm, Earth, and Fire
            E(152173, 90, "offensive", 80), -- Serenity
            E(123904, 120, "offensive", 75), -- Invoke Xuen
        },
        utility = {
            E(115078, 45, "utility", 70), -- Paralysis
            E(119381, 60, "utility", 70), -- Leg Sweep
        },
        trinkets = {},
    },
    PALADIN = {
        interrupts = {
            E(96231, 15, "interrupt", 100), -- Rebuke
        },
        defensives = {
            E(642, 300, "defensive", 95), -- Divine Shield
            E(1022, 300, "defensive", 90), -- Blessing of Protection
            E(6940, 120, "defensive", 85), -- Blessing of Sacrifice
            E(31821, 180, "defensive", 80), -- Aura Mastery
        },
        offensives = {
            E(31884, 120, "offensive", 90), -- Avenging Wrath
            E(231895, 120, "offensive", 85), -- Crusade
        },
        utility = {
            E(633, 600, "utility", 75), -- Lay on Hands
            E(210256, 45, "utility", 65), -- Blessing of Sanctuary
        },
        trinkets = {},
    },
    PRIEST = {
        interrupts = {
            E(15487, 45, "interrupt", 100), -- Silence
        },
        defensives = {
            E(33206, 180, "defensive", 95), -- Pain Suppression
            E(47788, 180, "defensive", 95), -- Guardian Spirit
            E(62618, 180, "defensive", 90), -- Power Word: Barrier
            E(47585, 120, "defensive", 85), -- Dispersion
        },
        offensives = {
            E(10060, 120, "offensive", 90), -- Power Infusion
            E(47536, 90, "offensive", 80), -- Rapture
        },
        utility = {
            E(8122, 60, "utility", 75), -- Psychic Scream
            E(108968, 300, "utility", 65), -- Void Shift
            E(64901, 300, "utility", 60), -- Symbol of Hope
        },
        trinkets = {},
    },
    ROGUE = {
        interrupts = {
            E(1766, 15, "interrupt", 100), -- Kick
        },
        defensives = {
            E(5277, 120, "defensive", 90), -- Evasion
            E(31224, 120, "defensive", 90), -- Cloak of Shadows
            E(1966, 15, "defensive", 60), -- Feint
        },
        offensives = {
            E(13750, 180, "offensive", 85), -- Adrenaline Rush
            E(121471, 180, "offensive", 80), -- Shadow Blades
            E(360194, 120, "offensive", 75), -- Deathmark
        },
        utility = {
            E(1856, 120, "utility", 85), -- Vanish
            E(2094, 120, "utility", 80), -- Blind
            E(408, 20, "utility", 70), -- Kidney Shot
        },
        trinkets = {},
    },
    SHAMAN = {
        interrupts = {
            E(57994, 12, "interrupt", 100), -- Wind Shear
        },
        defensives = {
            E(108271, 90, "defensive", 90), -- Astral Shift
            E(98008, 180, "defensive", 90), -- Spirit Link Totem
            E(108280, 180, "defensive", 85), -- Healing Tide Totem
        },
        offensives = {
            E(114051, 180, "offensive", 85), -- Ascendance
            E(191634, 60, "offensive", 75), -- Stormkeeper
            E(51533, 120, "offensive", 70), -- Feral Spirit
        },
        utility = {
            E(8143, 60, "utility", 75), -- Tremor Totem
            E(192058, 60, "utility", 70), -- Capacitor Totem
            E(204336, 24, "utility", 70), -- Grounding Totem
        },
        trinkets = {},
    },
    WARLOCK = {
        interrupts = {
            E(19647, 24, "interrupt", 100), -- Spell Lock
            E(119910, 24, "interrupt", 95), -- Spell Lock (alternate spellID)
        },
        defensives = {
            E(104773, 180, "defensive", 90), -- Unending Resolve
            E(108416, 60, "defensive", 75), -- Dark Pact
        },
        offensives = {
            E(1122, 180, "offensive", 85), -- Summon Infernal
            E(205180, 120, "offensive", 80), -- Summon Darkglare
            E(267217, 180, "offensive", 75), -- Nether Portal
        },
        utility = {
            E(6789, 45, "utility", 75), -- Mortal Coil
            E(5484, 40, "utility", 70), -- Howl of Terror
            E(212295, 45, "utility", 70), -- Nether Ward
        },
        trinkets = {},
    },
    WARRIOR = {
        interrupts = {
            E(6552, 15, "interrupt", 100), -- Pummel
        },
        defensives = {
            E(871, 240, "defensive", 90), -- Shield Wall
            E(118038, 120, "defensive", 90), -- Die by the Sword
            E(97462, 180, "defensive", 85), -- Rallying Cry
            E(12975, 180, "defensive", 80), -- Last Stand
        },
        offensives = {
            E(1719, 90, "offensive", 90), -- Recklessness
            E(107574, 90, "offensive", 85), -- Avatar
            E(167105, 45, "offensive", 70), -- Colossus Smash
        },
        utility = {
            E(5246, 90, "utility", 70), -- Intimidating Shout
            E(107570, 30, "utility", 65), -- Storm Bolt
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
            E(42292, 120, "trinket", 100), -- PvP Trinket (legacy spell)
            E(195710, 120, "trinket", 95), -- Honorable Medallion
            E(214027, 90, "trinket", 90), -- Adaptation
            E(59752, 180, "trinket", 85), -- Every Man for Himself
            E(7744, 120, "trinket", 80), -- Will of the Forsaken
            E(20589, 60, "trinket", 80), -- Escape Artist
            E(20594, 120, "trinket", 80), -- Stoneform
        },
    },
}

GT.CooldownIndexBySpell = {}
GT.TrinketIndexBySpell = {}

for classFile, buckets in pairs(GT.CooldownData) do
    for bucketName, entries in pairs(buckets) do
        for _, entry in ipairs(entries) do
            entry.classFile = classFile
            entry.bucket = bucketName

            local spellID = entry.spellID
            if spellID then
                local list = GT.CooldownIndexBySpell[spellID]
                if not list then
                    list = {}
                    GT.CooldownIndexBySpell[spellID] = list
                end
                list[#list + 1] = entry

                if bucketName == "trinkets" or entry.category == "trinket" then
                    local trinketList = GT.TrinketIndexBySpell[spellID]
                    if not trinketList then
                        trinketList = {}
                        GT.TrinketIndexBySpell[spellID] = trinketList
                    end
                    trinketList[#trinketList + 1] = entry
                end
            end
        end
    end
end

function GT:GetCooldownEntryForSpell(spellID, classFile)
    local entries = self.CooldownIndexBySpell[spellID]
    if not entries then
        return nil
    end

    local genericEntry = nil
    for _, entry in ipairs(entries) do
        if entry.classFile == classFile then
            return entry
        end
        if entry.classFile == "GENERIC" then
            genericEntry = entry
        end
    end

    return genericEntry or entries[1]
end

function GT:GetTrinketEntryForSpell(spellID, classFile)
    local entries = self.TrinketIndexBySpell[spellID]
    if not entries then
        return nil
    end

    local genericEntry = nil
    for _, entry in ipairs(entries) do
        if entry.classFile == classFile then
            return entry
        end
        if entry.classFile == "GENERIC" then
            genericEntry = entry
        end
    end

    return genericEntry or entries[1]
end
