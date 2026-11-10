# Dvsk architecture

Last updated 2026-10-13 (DVSK-001, launch at login).

## Stack

- Swift Package (`Package.swift`, tools version 6.0, Swift 5 language mode), no third-party dependencies. macOS 15 or later, Apple Silicon and Intel.
- AppKit for the menu bar item, SwiftUI for the Settings window, CoreGraphics for the gamma tables, ServiceManagement (`SMAppService`) for launch at login.
- Tests: XCTest. CI: GitHub Actions on `macos-15`.

## Structure

| Path | What it is |
|---|---|
| `Sources/DvskCore` | Plain Swift (Foundation only), fully unit tested: colour temperature to RGB (`ColorTemperature`), the fixed-time schedule with fade (`Schedule`), the priority of disabled, paused, darkroom and scheduled (`DvskState`), and the launch-at-login rules (`LoginItem`). |
| `Sources/Dvsk` | The app, with no tests. `main.swift` (the `--reset` recovery path, then the accessory-mode app), `AppDelegate` (signal handlers, start and stop), `Engine` (once-a-second tick, easing, re-apply after sleep or display changes), `GammaController` (`CGSetDisplayTransferByTable`; original tables captured once and restored through ColorSync), `MenuController` (menu bar item and menu), `Preferences` (UserDefaults), `SettingsView` (Settings window), `SystemLoginItemService` (the `SMAppService` adapter). |
| `Tests/DvskCoreTests` | XCTest for `DvskCore` only. |
| `scripts/` | `bundle.sh` (app bundle and DMG), `render-cask.sh` (Homebrew cask), `make-icon.swift` (one-off icon generator). |
| `.github/workflows/` | `ci.yml` (build and test; a DMG artifact on pull requests), `homebrew.yml` (updates the cask when a release is published). |
| `AppInfo.plist`, `Resources/AppIcon.icns` | Bundle metadata (`LSUIElement` is true: no Dock icon) and the icon. The app version lives in `AppInfo.plist`. |

## Launch at login

- The option is the "Launch at login" item in the menu bar menu (`MenuController`). It is off on a fresh install and after an update, because nothing registers at launch: only a click on the item calls `register()` or `unregister()`.
- The state is never stored. `LoginItem.state` asks the system on every read: when the menu opens (`menuNeedsUpdate`) and when the item is clicked. So it cannot disagree with the Login Items list in System Settings (General → Login Items & Extensions).
- `LoginItem` (DvskCore) holds the rules behind a `LoginItemService` protocol. Only the status `.enabled` shows as on. `.requiresApproval` and `.notFound` show as off. A click on `.requiresApproval` explains how to approve instead of calling `register()`; a click on `.notFound` still tries `register()` (some macOS versions report it for an app that was never registered) and explains why only if that did not work. The result of a click is judged by re-reading the status, not by whether the call threw.
- `SystemLoginItemService` (the app) maps `SMAppService.mainApp` one to one. When `Bundle.main` is not an `.app` bundle (as under `swift run`) it reports `.notFound`, and its `register()` and `unregister()` throw, all without asking `SMAppService`.
- Tests use a fake service, so no test registers anything on the machine that runs them.
- Quitting does not unregister: the quit and signal paths (`Engine.shutdown`) never touch the login item. A login start is a normal start: same `main.swift`, same `Preferences`, same `LSUIElement` (no Dock icon, no window).

## Build, run, test, deploy

```sh
swift build             # debug build of both modules
swift test              # unit tests (DvskCore); touches no display API and no login item
swift run Dvsk          # run from source; do not start a second copy while an installed Dvsk runs
swift run Dvsk --reset  # restore normal colours after a crash
./scripts/bundle.sh     # universal build -> build/Dvsk.app and build/Dvsk-<version>.dmg
```

- `bundle.sh` ad-hoc signs by default. With `DEVELOPER_ID` (and `NOTARY_PROFILE`) it signs with a Developer ID, then notarizes and staples the app and the DMG.
- CI has no release job. The DMG comes from `bundle.sh` and is attached to a GitHub release; publishing the release runs `homebrew.yml`, which renders the cask with `render-cask.sh` into `fabianwgl/homebrew-tap`.
