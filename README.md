# Dvsk

A small, readable, open-source take on f.lux for macOS. Dvsk is a menu bar app that warms your display in the evening by scaling each display's gamma tables, the same mechanism f.lux and Lunar use. It is a proof of concept: macOS only, no Location Services (the schedule uses fixed clock times), no installer.

## Features

- Automatic warm-up on a fixed schedule (default 20:00 to 07:00) with a gradual fade (default 30 minutes, centred on each boundary).
- Night temperature slider (1200K to 6500K) with live preview.
- Darkroom mode: everything red, for preserving night vision.
- "Disable for an hour" and "Resume".
- Settings window for night start/end, fade length, and night temperature.
- Always restores normal colours on quit, Ctrl-C and `kill -TERM`.

Defaults: night 20:00 to 07:00, 30 minute fade, 6500K by day, 2700K at night.

## Build and run

Requires macOS 15+ and a Swift 6 toolchain.

```sh
swift build            # debug build
swift test             # unit tests for the colour maths and schedule (DvskCore)
swift run Dvsk         # run the menu bar app (tints the screen!)
./scripts/bundle.sh    # release build -> build/Dvsk.app (ad-hoc codesigned)
open build/Dvsk.app
```

## Recovery: `--reset`

If Dvsk is killed with `kill -9` or crashes, the screen can stay tinted. Restore normal colours with:

```sh
swift run Dvsk --reset
# or, from the bundle:
build/Dvsk.app/Contents/MacOS/Dvsk --reset
```

`--reset` restores the display colours and exits immediately without starting any UI.

## Layout

- `Sources/DvskCore`: pure Swift (Foundation only), unit tested: Kelvin to RGB, schedule, mode resolution.
- `Sources/Dvsk`: the app: gamma control, engine (1 Hz tick, easing, re-apply after wake and display changes), menu, settings.
- `Tests/DvskCoreTests`: XCTest suite.

## Known limitations

- Turn off Night Shift (System Settings > Displays). It stacks on top of Dvsk, as does True Tone.
- Some displays ignore gamma tables: DisplayLink adapters, AirPlay, and some Sidecar setups.
- HDR/EDR content can partly bypass the tint.
- No launch at login yet. `SMAppService.mainApp` is a possible later step once the app is a properly signed bundle.

## License

MIT, see `LICENSE`.
