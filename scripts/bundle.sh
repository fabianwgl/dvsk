#!/bin/bash
# Builds a release binary and wraps it in build/Dvsk.app (ad-hoc codesigned).
set -euo pipefail

cd "$(dirname "$0")/.."

APP="build/Dvsk.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Dvsk "$APP/Contents/MacOS/Dvsk"
cp AppInfo.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"

echo "Built $APP"
