#!/bin/bash
# Usage: ./build.sh [run]   (set SIGN_ID to sign with your own certificate)
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/Pane.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Pane "$APP/Contents/MacOS/Pane"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign "${SIGN_ID:--}" "$APP"
echo "Built $APP"

if [[ "${1:-}" == "run" ]]; then
    pkill -x Pane || true
    # open only reactivates the old instance if it hasn't exited yet
    while pgrep -x Pane >/dev/null; do sleep 0.1; done
    open "$APP"
fi
