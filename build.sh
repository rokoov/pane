#!/bin/bash
# Usage: ./build.sh [run] [zip] [dmg]   (SIGN_ID signs with your own certificate, VERSION stamps a release)
set -euo pipefail
cd "$(dirname "$0")"

# One binary for Apple silicon and Intel; each architecture gets its own build folder so SwiftPM never mixes them
BINARIES=()
for arch in arm64 x86_64; do
    swift build -c release --arch "$arch" --scratch-path ".build/$arch"
    BINARIES+=("$(swift build -c release --arch "$arch" --scratch-path ".build/$arch" --show-bin-path)/Pane")
done

APP=build/Pane.app
BINARY="$APP/Contents/MacOS/Pane"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create -output "$BINARY" "${BINARIES[@]}"
# Swift Build records the deployment target as the SDK version, which keeps AppKit in its old look on macOS 26 and
# later; stamp the SDK the app was really built against
MINOS=$(vtool -show-build "$BINARY" | awk '/minos/ { print $2; exit }')
vtool -set-build-version macos "$MINOS" "$(xcrun --show-sdk-version)" -replace -output "$BINARY.stamped" "$BINARY"
mv "$BINARY.stamped" "$BINARY"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
if [[ -n "${VERSION:-}" ]]; then
    plutil -replace CFBundleShortVersionString -string "${VERSION#v}" "$APP/Contents/Info.plist"
fi
# Finder and iCloud attributes on the bundle make codesign refuse it
xattr -cr "$APP"
codesign --force --sign "${SIGN_ID:--}" "$APP"
NAME="Pane-$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
echo "Built $APP"

for target in "$@"; do
    case "$target" in
    zip)
        ditto -c -k --norsrc --noextattr --keepParent "$APP" "build/$NAME.zip"
        echo "Packed build/$NAME.zip"
        ;;
    dmg)
        # dmgbuild lays the disk image out without scripting Finder, so CI makes the same one
        if [[ ! -x build/dmgbuild/bin/dmgbuild ]]; then
            python3 -m venv build/dmgbuild
            build/dmgbuild/bin/pip install --quiet dmgbuild==2.0.0
        fi
        build/dmgbuild/bin/dmgbuild -s Resources/dmg/settings.py -D app="$APP" \
            -D background=Resources/dmg/background.tiff -D icon=Resources/AppIcon.icns Pane "build/$NAME.dmg"
        echo "Packed build/$NAME.dmg"
        ;;
    run)
        pkill -x Pane || true
        # open only reactivates the old instance if it hasn't exited yet
        while pgrep -x Pane >/dev/null; do sleep 0.1; done
        # Registering the bundle lets macOS show its icon and find it for Accessibility before it first launches
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
            -f "$APP"
        open "$APP"
        ;;
    *)
        echo "Unknown target: $target" >&2
        exit 1
        ;;
    esac
done
