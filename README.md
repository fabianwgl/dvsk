# Dvsk

[![CI](https://github.com/fabianwgl/dvsk/actions/workflows/ci.yml/badge.svg)](https://github.com/fabianwgl/dvsk/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/fabianwgl/dvsk)](https://github.com/fabianwgl/dvsk/releases/latest)
[![License: MIT](https://img.shields.io/github/license/fabianwgl/dvsk)](LICENSE)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-black?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)

An open-source alternative to [f.lux](https://justgetflux.com) for macOS: a small menu bar app that makes your screen warmer in the evening.

Dvsk changes each display's gamma tables, the same way f.lux does. It is a proof of concept, kept small and readable.

## Features

- **Scheduled warm-up:** turns warm at fixed times (default 20:00 to 07:00) with a smooth 30-minute fade.
- **Night temperature slider:** 1200K to 6500K, with a live preview.
- **Darkroom mode:** the whole screen goes red, to protect your night vision.
- **Disable for an hour:** a countdown appears next to the menu bar icon while it's paused.
- **Safe exit:** normal colours come back when you quit, press Ctrl-C or send `kill -TERM`.

## Requirements

- macOS 15 or later (Apple Silicon or Intel)
- To build from source: Xcode 16 or the Swift 6 toolchain

## Install

With [Homebrew](https://brew.sh):

```sh
brew install --cask fabianwgl/tap/dvsk
```

Or download `Dvsk-<version>.dmg` from [Releases](https://github.com/fabianwgl/dvsk/releases), open it and drag Dvsk to Applications.

Release builds are signed with a Developer ID and notarized by Apple, so macOS opens them without the "could not verify" block.

## Build and run

```sh
git clone https://github.com/fabianwgl/dvsk.git && cd dvsk
swift run Dvsk
```

To build the app and a DMG yourself (universal, ad-hoc signed, with no Dock icon):

```sh
./scripts/bundle.sh
open build/Dvsk.app    # or open build/Dvsk-<version>.dmg to install
```

To build a signed and notarized release DMG, set a Developer ID Application identity and a [notarytool keychain profile](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow):

```sh
DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE=dvsk-notary ./scripts/bundle.sh
```

To run the tests:

```sh
swift test
```

## If your screen stays tinted

If Dvsk crashes or is force-killed, your colours may not come back. To restore them, run:

```sh
swift run Dvsk --reset
```

Or, if you installed the app:

```sh
/Applications/Dvsk.app/Contents/MacOS/Dvsk --reset
```

## Known limitations

- Turn off Night Shift (System Settings → Displays) and True Tone, because they stack on top of Dvsk.
- DisplayLink adapters, AirPlay and some Sidecar setups ignore gamma tables.
- HDR content can partly bypass the tint.
- There's no launch at login or sunrise/sunset location support yet.

## How it works

- `Sources/DvskCore` holds the colour and schedule logic: converting colour temperature (Kelvin) to RGB, the fixed-time schedule, and choosing the current mode. It's plain Swift and fully unit tested.
- `Sources/Dvsk` is the app itself. Once a second it works out the target colour, eases toward it, and writes it to every display with `CGSetDisplayTransferByTable`. After sleep or a display change it applies the tint again, and it restores the original colours through ColorSync when you quit.

## Contributing

Issues and pull requests are welcome. Please run `swift test` before opening a pull request.

## License

[MIT](LICENSE)
