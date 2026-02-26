# Gladtools - Retail & Midnight Compatibility Improvements

## Summary of Enhancements
This document outlines robustness improvements made to keep Gladtools stable across current Retail builds and Midnight prepatch/launch behavior changes.

---

## 0. **Midnight Compatibility Hardening** ✅

### Motivation
Midnight prepatch/launch introduces combat-addon restrictions in PvP contexts, where spell-level combat event data can be unavailable.

### Changes Made
- **Main.lua**
  - Added runtime probe for spell-level `COMBAT_LOG_EVENT_UNFILTERED` payload quality.
  - Added automatic restricted-mode detection and one-time user warning when spell IDs are consistently unavailable.
  - Restricted mode now pauses cooldown/trinket/DR tracking and refreshes runtime event registrations safely.
- **Utils.lua**
  - Added shared `GT:GetSpellNameAndIcon()` and `GT:GetSpellName()` helpers for safer, centralized spell lookup behavior.
- **CooldownTracker.lua / TrinketTracker.lua / DRTracker.lua**
  - Added restricted-mode gating in `IsEnabled()` so these trackers fail soft instead of reporting misleading empty/ready states.
- **UnitFrames.lua**
  - Cooldown row now shows `CD unavailable` in restricted mode.
  - Trinket icon is hidden when restricted mode is active.
- **NameplateOverlays.lua / Notifications.lua**
  - Added restricted-mode guards for combat-log handling paths.
  - Replaced raw spell lookups with centralized safe helpers.
- **tests/smoke.lua**
  - Added coverage for restricted-mode detection and tracker pause/resume behavior.

---

## 1. **UIParent Availability Checks** ✅

### Motivation
`UIParent` is a critical WoW global that may not be available during very early addon load phases. If modules try to create frames before `UIParent` exists, the addon crashes.

### Changes Made
Added defensive checks to all frame-creating module `Init` functions:
- **Notifications.lua** - Added UIParent check before CreateBanner() and driver setup
- **CastBars.lua** - Added UIParent check before creating status bars  
- **UnitFrames.lua** - Added UIParent check before creating unit group frames
- **PointerSystem.lua** - Added UIParent check before creating pointer markers
- **NameplateOverlays.lua** - Added UIParent check before overlay frame creation
- **SettingsUI.lua** - Added UIParent check before panel creation

All modules now gracefully abort initialization if `UIParent` is unavailable, logging a message instead of crashing.

---

## 2. **Enhanced Spell API Fallbacks** ✅

### Motivation
Spell lookup APIs (`C_Spell.GetSpellInfo`, `GetSpellInfo`) can fail for various reasons:
- Missing/invalid spell IDs
- API exceptions in newer WoW builds
- Deprecated function signatures

### Changes Made
Wrapped all spell name/icon lookups in pcall (protected calls) with type validation:

**Files Updated:**
- **CooldownTracker.lua** - `getSpellNameAndIcon()` now has type checking and pcall protection
- **TrinketTracker.lua** - Same spell lookup safety improvements
- **Notifications.lua** - `getSpellName()` now handles nil spell IDs and API failures gracefully

**Details:**
```lua
local function getSpellNameAndIcon(spellID)
    if not spellID or type(spellID) ~= "number" then
        return nil, nil
    end
    
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(function() return C_Spell.GetSpellInfo(spellID) end)
        if ok and info then
            return info.name, info.iconID
        end
    end
    -- Fallback to GetSpellInfo with same protection...
    return nil, nil
end
```

**Benefit:** If a spell lookup fails, the addon logs it and continues instead of crashing.

---

## 3. **Improved Database Initialization Safety** ✅

### Motivation
SavedVariables can become corrupted if WoW crashes during save, breaking settings access patterns.

### Changes Made
- **Config.lua** - Enhanced `GT:GetSetting()` to validate that `db.settings` is a table before accessing it
  - If corrupted, resets the settings table to empty `{}`
  - Prevents cascading nil errors from corrupted data

---

## 4. **SafeCall Utility Function** ✅

### Motivation
Provide a standardized way for modules to call potentially-unsafe APIs without crashing the entire addon.

### Changes Made
- **Utils.lua** - Added `GT:SafeCall(callback, ...)` function
  - Wraps any function call in pcall
  - Returns nil on failure instead of propagating errors
  - Can be used across all modules for risky API calls

---

## 5. **Robust Startup Sequencing** ✅

### Motivation
If UIParent isn't available on first initialization, modules need a chance to retry after it becomes available.

### Changes Made
- **Main.lua** - Enhanced `GT:Startup()` to detect if any module deferred initialization
  - Retries module initialization if UIParent is now available
  - Ensures all features eventually load when the UI is ready

---

## 6. **Error Handling in Event Loop** ✅

### What Was Already Good
The addon's `Init.lua` already wraps all module callbacks in `pcall`:
```lua
function GT:IterateModules(callbackName, ...)
    for _, module in ipairs(self.moduleOrder) do
        local callback = module[callbackName]
        if type(callback) == "function" then
            local ok, err = pcall(callback, module, ...)
            if not ok then
                self:Print(string.format("Module %s failed in %s: %s", ...))
            end
        end
    end
end
```

This ensures that if **any** module's event handler crashes, it's logged and other modules continue processing.

---

## 7. **Frame Creation Guards** ✅

### Changes Made
All modules now check both `CreateFrame` and `UIParent` before attempting frame creation:
```lua
if not UIParent or not CreateFrame then
    GT:Print("UIParent not available, deferring <ModuleName> init")
    return
end
```

And verify frame creation succeeded with optional checks:
```lua
self.driver = CreateFrame("Frame", "GladtoolsDriver", UIParent)
if self.driver and self.driver.SetScript then
    self.driver:SetScript("OnUpdate", function(_, elapsed)
        -- Handler...
    end)
end
```

---

## Summary of Files Modified

| File | Changes |
|------|---------|
| `Gladtools/Main.lua` | Added retry logic in `GT:Startup()` for deferred module initialization |
| `Gladtools/Utils.lua` | Added `GT:SafeCall()` utility function |
| `Gladtools/Config.lua` | Enhanced `GT:GetSetting()` with corruption detection/repair |
| `Gladtools/Modules/Notifications.lua` | UIParent checks, spell lookup pcall protection |
| `Gladtools/Modules/CastBars.lua` | UIParent checks, improved frame creation guards |
| `Gladtools/Modules/UnitFrames.lua` | UIParent checks, frame creation safety |
| `Gladtools/Modules/PointerSystem.lua` | UIParent checks, driver setup safety |
| `Gladtools/Modules/NameplateOverlays.lua` | UIParent checks, overlay initialization safety |
| `Gladtools/Modules/SettingsUI.lua` | Deferred panel creation if UIParent unavailable |
| `Gladtools/Modules/CooldownTracker.lua` | Spell lookup pcall protection, type validation |
| `Gladtools/Modules/TrinketTracker.lua` | Spell lookup pcall protection, type validation |

---

## Testing Recommendations

After installing the updated addon:

1. **Load in Game**
   - Log into a character
   - Verify `/gladtools` opens the settings panel
   - Check that no red errors appear in chat

2. **Enter Arena**
   - Zone into a 3v3 arena
   - Verify enemy/friendly/near frames appear
   - Check cooldown icons update correctly
   - Confirm pointer markers show (press `/gladtools pointers` to cycle modes)
   - Monitor `/gladtools snapshot` output

3. **Apply Presets**
   - Try both healer and DPS presets
   - Modify individual settings
   - Use `/gladtools resetpreset` to verify revert works

4. **Check Chat for Errors**
   - No "Module failed" errors should appear
   - Any deferred initializations will show "UIParent not available" messages (which is fine and rare)

---

## Compatibility Notes

- **API Version**: 120001, 120000, 110200 (covers latest Retail + backwards compatibility)
- **SafeCall Pattern**: Used throughout to tolerate missing/changed APIs
- **Fallback Chain**: All critical lookups have manual fallback lists (CooldownData, DRData)
- **Event Registration**: Dynamically enabled based on settings; missing old events are safely ignored

---

## Additional Robustness Patterns

If you encounter new issues after installation, consider:

1. **Check for chat errors** - Addon will log module initialization failures
2. **Try `/gladtools resetpreset`** - Resets all settings to defaults
3. **Verify data files** - Ensure `CooldownData.lua` and `DRData.lua` load without errors
4. **Check WoW Version** - Use `/run print(GetBuildInfo())` to confirm build

---

**Version**: 0.2.0+improvements  
**Date**: February 26, 2026  
**Target**: WoW Retail 10.2 (Midnight Prepatch)
