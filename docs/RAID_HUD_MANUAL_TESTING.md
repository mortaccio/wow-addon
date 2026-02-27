# Raid HUD integration notes and manual test plan

## What changed

- Added Blizzard Compact/Raid frame HUD module: `Gladtools/Modules/RaidHUD.lua`.
- Added module load entry in `.toc`: `Gladtools/Gladtools.toc`.
- Added SavedVariables defaults and spell lists for defensive/CD + CC tracking in `Gladtools/Config.lua`.
- Added runtime event registration for RaidHUD in `Gladtools/Main.lua`.
- Added settings controls for RaidHUD toggles and size sliders in `Gladtools/Modules/SettingsUI.lua`.
- Added smoke coverage for RaidHUD defaults/helpers in `tests/smoke.lua`.

## Taint and combat-lockdown risk review

Potential taint points:

1. Hooking Blizzard CompactUnitFrame update functions.
2. Creating child widgets on protected Compact frames.
3. Updating frame points/sizes while combat lockdown is active.

Mitigations implemented:

- Uses `hooksecurefunc` for `CompactUnitFrame_UpdateAll`, `CompactUnitFrame_SetUnit`, `CompactUnitFrame_UpdateHealth`, `CompactUnitFrame_UpdateAuras`.
- No secure function replacement and no protected attribute writes.
- HUD creation is deferred when `InCombatLockdown()` is true; pending attachments are processed on `PLAYER_REGEN_ENABLED`.
- Runtime updates operate on non-secure child textures/frames only.

## Compatibility notes

- Retail + modern clients: uses `C_UnitAuras.GetAuraDataByIndex` when present.
- Classic fallback: uses `UnitAura` scanning when `C_UnitAuras` is unavailable.
- Frame discovery supports Blizzard compact containers (`CompactRaidFrameContainer`, `CompactPartyFrame`, `CompactArenaFrame`) plus known compact member globals.
- Default behavior is `attachOnlyBlizzard = true` to reduce collisions with external frame addons.

## Manual test checklist

### 1) Base enablement

1. Login and run `/gladtools`.
2. Run `/gladtools uicheck` to verify display module health before testing.
3. Enable:
   - `Attach HUD to Blizzard raid frames`
   - `Raid HUD: defensive cooldown icons`
   - `Raid HUD: class-color pointer`
   - `Raid HUD: CC debuff icons`
4. Join party/raid and show Blizzard raid/party frames.

Expected:

- HUD appears on compact unit frames.
- Pointer is visible above health bar.
- Cooldown and CC icon anchors are attached near health bar.

### 2) Defensive cooldown icons

1. Trigger tracked defensive spells on friendly and enemy units (arena/skirmish/RBG).
2. Observe icon strip on compact frame.

Expected:

- Defensive spell icon appears with cooldown spiral.
- Timer text counts down and hides when ready.
- Behavior is identical for friendly/enemy sides when both are enabled.

### 3) Pointer class color

1. Target/inspect units of different classes.
2. Verify pointer color changes to class color.
3. Check non-player/NPC fallback case.

Expected:

- Pointer color follows `RAID_CLASS_COLORS[classToken]`.
- Unknown class uses configured fallback color.

### 4) CC icons

1. Apply stun/incap/fear/silence/root/disarm effects.
2. Observe CC icons near health bar.
3. Hover icon for tooltip.

Expected:

- Active CC aura icon appears with timer spiral.
- Tooltip shows spell info and remaining time.
- Priority sorting favors stronger CC categories first.

### 5) Combat lockdown safety

1. Enter combat with HUD enabled.
2. Force roster/frame updates during combat.
3. Exit combat.

Expected:

- No blocked action/protected taint errors.
- New compact frames attach after `PLAYER_REGEN_ENABLED` if created during combat.

### 6) Persistence

1. Change RaidHUD toggles and size sliders.
2. Run `/reload`.
3. Re-open settings.

Expected:

- Values are preserved in `GladToolsDB` and applied after reload.

### 7) Addon conflict checks

1. Enable Grid/VuhDo-style raid frame replacement.
2. Keep `attachOnlyBlizzard = true`.

Expected:

- RaidHUD only attaches to Blizzard compact frames and avoids third-party frames.

Optional fallback:

- Set `raidHUD.attachOnlyBlizzard = false` in SavedVariables to allow broader attachment attempts when needed.

## Advanced position tuning (SavedVariables)

`GladToolsDB.settings.raidHUD` includes offset controls:

- `cooldowns.offsetX`, `cooldowns.offsetY`
- `pointer.offsetX`, `pointer.offsetY`
- `cc.offsetX`, `cc.offsetY`

Example:

```lua
GladToolsDB.settings.raidHUD.cooldowns.offsetX = 10
GladToolsDB.settings.raidHUD.pointer.offsetY = 4
GladToolsDB.settings.raidHUD.cc.anchorSide = "right"
```

## Screenshot capture guidance

Capture three screenshots for verification:

1. Friendly compact frame with pointer + cooldown icon.
2. Enemy compact frame with defensive cooldown icon active.
3. Compact frame with active CC icon and tooltip.

Use built-in command:

```
/run Screenshot()
```
