#!/bin/bash
# Usage: ./build.sh [run|zip]   (SIGN_ID signs with your own certificate, VERSION stamps a release)
set -euo pipefail
cd "$(dirname "$0")"

# One binary for Apple silicon and Intel; each architecture gets its own build folder so SwiftPM never mixes them
BINARIES=()
for arch in arm64 x86_64; do
    swift build -c release --arch "$arch" --scratch-path ".build/$arch"
    BINARIES+=("$(swift build -c release --arch "$arch" --scratch-path ".build/$arch" --show-bin-path)/Pane")
done

APP=build/Pane.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create -output "$APP/Contents/MacOS/Pane" "${BINARIES[@]}"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
if [[ -n "${VERSION:-}" ]]; then
    plutil -replace CFBundleShortVersionString -string "${VERSION#v}" "$APP/Contents/Info.plist"
fi
# Finder and iCloud attributes on the bundle make codesign refuse it
xattr -cr "$APP"
codesign --force --sign "${SIGN_ID:--}" "$APP"
echo "Built $APP"

if [[ "${1:-}" == "zip" ]]; then
    ZIP="build/Pane-$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist").zip"
    ditto -c -k --norsrc --noextattr --keepParent "$APP" "$ZIP"
    echo "Packed $ZIP"
fi

if [[ "${1:-}" == "run" ]]; then
    pkill -x Pane || true
    # open only reactivates the old instance if it hasn't exited yet
    while pgrep -x Pane >/dev/null; do sleep 0.1; done
    open "$APP"
fi
