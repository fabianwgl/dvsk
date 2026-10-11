#!/bin/bash
# Builds a universal release binary, wraps it in build/Dvsk.app (ad-hoc codesigned)
# and packs build/Dvsk-<version>.dmg with an Applications symlink for drag-install.
set -euo pipefail

cd "$(dirname "$0")/.."

APP="build/Dvsk.app"
STAGING="build/dmg"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" AppInfo.plist)
DMG="build/Dvsk-$VERSION.dmg"

# Prefer a universal (arm64 + x86_64) build; fall back to the native arch.
ARCHS=(--arch arm64 --arch x86_64)
if ! swift build -c release "${ARCHS[@]}"; then
    echo "Universal build failed; falling back to native arch ($(uname -m))." >&2
    ARCHS=()
    swift build -c release
fi
# The output path differs between build systems, so ask SwiftPM for it.
BIN="$(swift build -c release ${ARCHS[@]+"${ARCHS[@]}"} --show-bin-path)/Dvsk"
echo "Binary archs: $(lipo -archs "$BIN")"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Dvsk"
cp AppInfo.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Dvsk" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

echo "Built $APP"
echo "Built $DMG"
