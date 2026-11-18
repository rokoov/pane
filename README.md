# Pane

**Window snapping for your trackpad.** Swipe on any title bar to snap, tile and move windows. Free and open source.

A free, open-source alternative to Swish, written natively in Swift.

## Gestures

Two-finger swipe on the title bar of the active window:

| Swipe | Result |
| --- | --- |
| ← / → | Left / right half |
| ↑ | Fill the screen |
| ↓ | Minimize |
| ↖ ↗ ↙ ↘ | Quarters |
| ← / → again on a snapped window | Move to the next monitor |

Hold **⌥** to swipe anywhere on screen. The active window moves wherever the cursor is.

A live preview shows where the window will land. Swipe back to cancel.

## Install

Requires macOS 13 or later, on Apple silicon or Intel.

1. Download **Pane.zip** from the [latest release](https://github.com/rokoov/pane/releases/latest), unzip it and move **Pane** to Applications.
2. Open Pane. It isn't notarized by Apple, so macOS blocks the first launch: open System Settings → Privacy & Security and click **Open Anyway**.
3. Grant **Accessibility** access when asked (System Settings → Privacy & Security → Accessibility). Pane needs it to read and move windows.

After an update, macOS may ask for Accessibility access again: remove Pane from the list (or run `tccutil reset Accessibility com.rokoov.pane`) and grant it again.

Releases are built by GitHub Actions straight from the tagged source.

## Build from source

```bash
git clone https://github.com/rokoov/pane.git
cd pane
./build.sh run
```

`./build.sh zip` packs `build/Pane.zip`. Every build is signed ad-hoc and gets a new signature, so grant Accessibility again after rebuilding, or sign with your own certificate: `SIGN_ID="Apple Development: Your Name" ./build.sh`.

Run the tests with `swift test` (needs Xcode) and check formatting with `swift format lint --strict --recursive Sources Tests Package.swift`.

## Privacy

No network access, no analytics, no accounts. Pane only listens to scroll gestures and moves windows.

## License

MIT
