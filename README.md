# Gladtools

Retail World of Warcraft Arena PvP addon with modular tracking for cooldowns, trinkets, unit frames, cast bars, and pointers.

## What Works Now

- Real event-driven tracking (`COMBAT_LOG_EVENT_UNFILTERED`, arena/unit events, spellcast events)
- Arena enemy frames (`arena1-3`) and friendly frames (`player`, `party1-4`)
- Near frames (`party1-4` in range)
- Cooldown icons with numeric countdown text on frames
- Trinket/racial timer detection and display
- DR tracking (stun/incap/fear/silence/root) with live reset timers on enemy frames
- Cast bars for arena units (+ optional focus/target)
- Pointer system (off / all friendlies / healers only)
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
    UnitFrames.lua
    CastBars.lua
    PointerSystem.lua
    SettingsUI.lua
```

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

- Expand dataset with spec/talent/PvP-talent overrides and patch-aware values
- Expand DR spell coverage and edge-case handling (class talents/variants/immunity nuances)
- Add stronger near-frame range engine (e.g., LibRangeCheck integration)

## Visual Preview Without WoW

The browser preview is only a static settings mock:

- Open [preview/index.html](/home/asenic/wow-addon/preview/index.html)
- Or run:

```bash
python3 -m http.server 8080
# then open http://localhost:8080/preview/
```
