# Dvsk technical decisions

Newest first. Each entry: date, decision, why, alternatives. Product decisions are in `docs/product/decisions.md`.

## 2026-10-17 Keyboard backlight uses the private `KeyboardBrightnessClient` (CoreBrightness)

- **Decision:** the menu's keyboard backlight slider and "Adjust keyboard in low light" item call `KeyboardBrightnessClient` from `/System/Library/PrivateFrameworks/CoreBrightness.framework`, loaded with `dlopen` and the Objective-C runtime (`KeyboardBacklight.swift`). Selectors: `copyKeyboardBacklightIDs`, `brightnessForKeyboard:` (float 0 to 1), `setBrightness:forKeyboard:` (BOOL), `isAutoBrightnessEnabledForKeyboard:` and `enableAutoBrightness:forKeyboard:` (BOOL). Type encodings read with `method_getTypeEncoding` on a Mac16,1, macOS 27.0.1, 2026-10-17; a write of 0.4 then 0 read back correctly.
- **Why:** macOS has no public API for the keyboard backlight.
- **Risk:** a future macOS can rename or remove it. Every selector is checked with `responds(to:)`, and the menu hides the keyboard section when the class or a backlight ID is missing (desktop Macs, external keyboards).
- **Menu alignment:** custom menu item views use a 27 pt leading and 13 pt trailing inset, measured from where macOS 27 draws standard item titles and the end of the key-equivalent column. They are fixed numbers, so recheck them after a major macOS update.
