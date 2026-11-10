# Dvsk overview

## What it is

Dvsk is a small, free, open-source Mac menu bar app that makes your screen warmer in the evening, like f.lux. It is a proof of concept, kept small and easy to read.

## Who it is for

Mac users who look at a screen at night and want less blue light, and developers who want a readable example of how this works.

## Why

Cold blue light late in the evening can make it harder to wind down. Dvsk gives a warmer picture at night with no account and no network.

## How to use it

1. Install with `brew install --cask fabianwgl/tap/dvsk`, or download the DMG from the GitHub Releases page, open it and drag Dvsk to Applications.
2. Opening it the first time depends on the version:
   - Version 0.1.1 and later are signed and "notarized" (Apple has checked the app and vouches for it), so macOS should open them with no warning. This comes from the project README; nobody has checked it on a downloaded copy yet (assumed, confirm).
   - Version 0.1.1 is not published yet. As of 2026-10-13 the download and the Homebrew install still give 0.1.0, which is not notarized. macOS blocks its first launch. Allow it in System Settings, Privacy & Security, "Open Anyway".
3. Click the menu bar icon. By default the screen turns warm from 20:00 to 07:00, fading over 30 minutes.
4. Open Settings to change the start and end times, the fade length and how warm the night colour is.
5. Use Darkroom for an all-red screen, or disable for an hour when you need true colours.
6. Quitting the app brings normal colours back. If the screen stays tinted after a crash, run `Dvsk --reset`.

## Known limits

- Turn off Night Shift and True Tone, they stack on top of Dvsk.
- Some displays (DisplayLink, AirPlay, some Sidecar) ignore the tint. HDR content can partly bypass it.
- No launch at login yet. It is approved, and when it arrives it will be off until you turn it on. Planned for the next release (assumed, confirm).
- No sunrise/sunset schedule yet. It is an idea that is not scheduled. If it is built, you would type your location by hand, and it would be a choice next to the fixed times.
