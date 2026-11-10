# Dvsk technical decisions

Newest first. Each entry: date, decision, why, alternatives. Product decisions are in `docs/product/decisions.md`.

## 2026-10-17 Keyboard backlight uses the private `KeyboardBrightnessClient` (CoreBrightness)

- **Decision:** the menu's keyboard backlight slider and "Adjust keyboard in low light" item call `KeyboardBrightnessClient` from `/System/Library/PrivateFrameworks/CoreBrightness.framework`, loaded with `dlopen` and the Objective-C runtime (`KeyboardBacklight.swift`). Selectors: `copyKeyboardBacklightIDs`, `brightnessForKeyboard:` (float 0 to 1), `setBrightness:forKeyboard:` (BOOL), `isAutoBrightnessEnabledForKeyboard:` and `enableAutoBrightness:forKeyboard:` (BOOL). Type encodings read with `method_getTypeEncoding` on a Mac16,1, macOS 27.0.1, 2026-10-17; a write of 0.4 then 0 read back correctly.
- **Why:** macOS has no public API for the keyboard backlight.
- **Risk:** a future macOS can rename or remove it. Every selector is checked with `responds(to:)`, and the menu hides the keyboard section when the class or a backlight ID is missing (desktop Macs, external keyboards).
- **Menu alignment:** custom menu item views use a 27 pt leading and 13 pt trailing inset, measured from where macOS 27 draws standard item titles and the end of the key-equivalent column. They are fixed numbers, so recheck them after a major macOS update.

## 2026-10-13 Launch at login uses `SMAppService.mainApp` (DVSK-001)

- **Decision:** register the main app as a login item with `SMAppService.mainApp` (ServiceManagement, macOS 13 and later; Dvsk needs macOS 15). `register()` adds Dvsk to the Login Items list in System Settings (General → Login Items & Extensions; that name is the `alt_name` in the `Info.plist` of the system's `LoginItems.appex`, read on 2026-10-13), `unregister()` removes it, and `status` is `notRegistered`, `enabled`, `requiresApproval` or `notFound`.
- **Why:** it is Apple's current API for this. It needs no helper app and no file outside the app bundle, the entry shows in the Login Items list where the user can switch it off, and `status` tells us when they did.
- **Alternatives:** `SMLoginItemSetEnabled` with a helper app (Apple's page says `register()` and `unregister()` replace it, macOS 13 and later); a LaunchAgent plist in `~/Library/LaunchAgents` written by hand (the same page says `SMAppService` replaces that too, and it is a file outside the app to own and clean up).
- **Sources:**
  - Apple Developer Documentation, `SMAppService`, read on 2026-10-13 as JSON at `https://developer.apple.com/tutorials/data/documentation/servicemanagement/smappservice.json`. The HTML page (`https://developer.apple.com/documentation/servicemanagement/smappservice`) came back with no body text. From it: `mainApp` is "An app service object that corresponds to the main application as a login item."; `register()` "Registers the service so it can begin launching subject to user approval."; for LoginItems, `register()` and `unregister()` replace `SMLoginItemSetEnabled`; macOS 13.0 and later.
  - The status meanings and the error rules are not on that page. They come from the SDK header `SMAppService.h` (Xcode, `MacOSX27.0.sdk`), read on 2026-10-13. `requiresApproval`: registered, but the user must act in System Settings, "returned if the user revokes consent". `notFound`: "An error occurred and no such service could be found". `register()` on the main app means it launches on later logins; an already registered service returns `kSMErrorAlreadyRegistered`, a refusal returns `kSMErrorLaunchDeniedByUser`, a bad signature returns `kSMErrorInvalidSignature`; "Apps that use SMAppService APIs must be code signed". `unregister()` on the main app keeps it running but stops future launches at login.

## 2026-10-13 The state is read from macOS every time and never stored

- **Decision:** no `Preferences` property, no UserDefaults key, no cached value. `LoginItem.state` reads the status on every call. The menu reads it when it opens.
- **Why:** the Login Items list can change at any time (the user switches Dvsk off there). A stored copy would drift. It also makes the option off after an update from 0.1.x, because nothing was ever registered.
- **Alternatives:** a UserDefaults flag checked at launch (can disagree with System Settings, and needs re-sync code).

## 2026-10-13 The rules live in DvskCore behind a protocol; `SMAppService` sits in a thin adapter

- **Decision:** `LoginItem`, `LoginItemState`, `LoginItemStatus` and the `LoginItemService` protocol are in `DvskCore`. `SystemLoginItemService` in the app target is the only code that touches `SMAppService`. Tests use a fake `LoginItemService`.
- **Why:** `swift test` must not add or remove a login item on the machine that runs it, and `DvskCore` is the only tested module.
- **Alternatives:** a test target for the `Dvsk` executable (a new target, with AppKit linked into the tests); calling `SMAppService` straight from `MenuController` (not testable).
- **Known gap:** the adapter's name-for-name status mapping and its bundle check (including the refusal in `register()` and `unregister()`) have no test. They are only checked in the bundled app.

## 2026-10-13 `register()` is tried from `notRegistered` and `notFound`, never from `requiresApproval`

- **Decision:** a click calls `register()` from `notRegistered` and from `notFound`. From `requiresApproval` it does not: it shows how to approve in System Settings (the header says `register()` would return `kSMErrorAlreadyRegistered`). Whether a click worked is decided by re-reading the status, not by whether the call threw. If the status is still `notFound` afterwards, the "not available" reason is shown.
- **Why:** the first version did not try from `notFound`, because the SDK header calls it an error state ("no such service could be found"). The DVSK-001 review pointed out that some macOS versions report `notFound` for an app that was simply never registered, and then the option could never turn on (criterion 2). I could not observe that here. Trying costs one failed call at worst, and a call that macOS accepts turns the option on. This resolves the earlier risk in `LoginItem`.
- **`swift run`:** nothing reaches `SMAppService` without an app bundle. `SystemLoginItemService` reports `notFound` for `status`, and its `register()` and `unregister()` throw their own error when `Bundle.main` is not an `.app`. So a click ends as "not available" with its reason, and no login item can be created.
- **Open:** the real status transitions (for example after the user switches Dvsk off in System Settings) have not been run on a Mac. They follow the header text. If the installed app still shows the "not available" alert on its first click, `register()` itself failed (look at the signing and where the app sits), not the not-found handling.

## 2026-10-13 The option is a menu item, not a Settings row

- **Decision:** a "Launch at login" item in the menu bar menu, above Settings.
- **Why:** `menuNeedsUpdate` runs each time the menu opens, so it re-reads the state for free. `SettingsWindowController` creates the window once and keeps it alive, so a row there would show stale state when reopened unless extra refresh code was added. The menu already holds the other on/off options (Enabled, Darkroom).
- **Alternatives:** a toggle in `SettingsView`.

## 2026-10-13 A blocked or failed click shows an alert; no "Open System Settings" button

- **Decision:** `NSAlert` after `NSApp.activate()`, with the short reason from `LoginItem`.
- **Why:** the criteria need a short message saying why, and a menu bar app has no other window to show it in.
- **Alternatives:** an extra button calling `SMAppService.openSystemSettingsLoginItems()` (left out to keep the change small; easy to add); a permanent disabled line in the menu.

## 2026-10-13 No version bump in DVSK-001

- **Decision:** `AppInfo.plist` stays at 0.1.1. Choosing the next version and publishing it is a separate release step.
