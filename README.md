# Gladtools

Retail World of Warcraft Arena PvP addon with modular tracking for cooldowns, trinkets, unit frames, cast bars, and pointers.

## What Works Now

- Real event-driven tracking (`COMBAT_LOG_EVENT_UNFILTERED`, arena/unit events, spellcast events)
- Arena enemy frames (`arena1-3`) and friendly frames (`player`, `party1-4`)
- Near frames (`nameplate1-5` hostile players in range)
- Cooldown icons with numeric countdown text on frames
- Trinket/racial timer detection and display
- DR tracking (stun/incap/fear/silence/root) with live reset timers on enemy frames
- Cast bars for arena units (+ optional focus/target)
- Pointer system (off / all friendlies / healers only) with role-aware color + pulse
- Cleaner compact visual style: class accent bars, category-colored cooldown borders, DR badges
- Enhanced frame readability: class icon badge, unit role/tag/status chip, compact HP values, cooldown/trinket summaries
- Cast bars improved with source tag, state flag (`CS`/`CH`/`NI`), and moving progress spark
- Pointer markers now include priority labels (`H`, `!`, party index) for quicker reads
- Live runtime snapshot panel in settings (visible frames, active cooldowns/trinkets/DR/casts/pointers)
- Top-of-screen burst alerts when your healer is in hard CC and enemies press offensive cooldowns
- Enemy "CC on you" cast-start warnings at top of screen
- Enhanced player nameplates: arena labels, healer icon, class-color HP, large CC debuffs (right), your debuffs (top), and plate cast bars
- Cooldown tracking now uses Blizzard APIs where available (`C_Spell` / `GetSpellBaseCooldown`) with normalized spec-aware fallback data
- Nameplate and healer-CC debuff timers now reconcile against live aura durations when unit aura data is available
- Expanded normalized cooldown and DR datasets for stronger live arena coverage
- Presets (`Healer`, `DPS`) with editable overrides and automatic `Custom` state
- Blizzard Settings panel registration (with fallback)

## Folder Layout

```text
Gladtools/
  Gladtools.toc
  Init.lua
  Utils.lua
  Config.lua
  CooldownData.lua
  Main.lua
  Modules/
    UnitMap.lua
    CooldownTracker.lua
    TrinketTracker.lua
    DRTracker.lua
    Notifications.lua
    NameplateOverlays.lua
    UnitFrames.lua
    CastBars.lua
    PointerSystem.lua
    SettingsUI.lua
```

## Installation

1. Close World of Warcraft.
2. Copy the `Gladtools` folder into your Retail addons directory.

Windows path:
`C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Gladtools`

macOS path:
`/Applications/World of Warcraft/_retail_/Interface/AddOns/Gladtools`

3. Make sure the `.toc` file is at:
`.../AddOns/Gladtools/Gladtools.toc`
4. Start WoW Retail and open Character Select.
5. Click `AddOns` and verify `Gladtools` is enabled.
6. Enter the game and run `/gladtools` to open settings.
7. Optional: run `/gladtools snapshot` to confirm trackers are active.

Update steps:
1. Exit WoW.
2. Replace the old `Gladtools` folder with the new one.
3. Keep your existing `GladToolsDB` saved variables unless you want a full reset.

## Presets

- `Healer`
  - Pointers: all friendlies
  - Friendly/enemy/near frames: enabled, fancy
  - Cooldowns: enabled, friendly+enemy shown
  - Cast bars: enabled
  - Trinkets: enabled
- `DPS`
  - Pointers: healers only
  - Friendly/enemy frames: enabled, fancy
  - Near frames: disabled by default
  - Cooldowns: enabled, friendly+enemy shown
  - Cast bars: enabled
  - Trinkets: enabled

Preset behavior:
- Applying preset writes defaults immediately
- You can still change any setting after apply
- Any deviation from preset marks state as `Custom`
- `Reset To Selected` reapplies selected preset

## Commands

- `/gladtools` - open settings
- `/gladtools preset <healer|dps>` - apply preset
- `/gladtools resetpreset` - reset to selected preset
- `/gladtools pointers <off|all|healers>` - pointer mode
- `/gladtools snapshot` - print a live tracker snapshot in chat
- `/gladtools state` - show current preset state
- `/gladtools help` - command list

## Starter Data Model

`CooldownData.lua` is data-driven and keyed by class:

```lua
CooldownData[class] = {
  interrupts = {...},
  defensives = {...},
  offensives = {...},
  utility = {...},
  trinkets = {...},
}
```

Each spell entry includes:
- `spellID`
- `defaultCD`
- `category`
- `icon`
- `priority`

## TODO (Competitive 3v3)

- Continue tuning spec/talent/PvP-talent overrides for edge patches
- Expand special-case DR handling (immunity/hybrid aura variants)
- Optional: integrate LibRangeCheck for more precise near-frame edge cases

## Visual Preview Without WoW

The browser preview is only a static settings mock:

- Open [preview/index.html](/home/asenic/wow-addon/preview/index.html)
- Or run:

```bash
python3 -m http.server 8080
# then open http://localhost:8080/preview/
```
