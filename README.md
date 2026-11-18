# Pane

<img src="Resources/AppIcon-preview.png" width="96" align="right" alt="">

**Window snapping for your trackpad.** Swipe on a window's title bar to snap, tile and move it. Free and open source.

A free, open-source alternative to Swish, written natively in Swift.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/snap-dark.png">
  <img src="docs/snap-light.png" width="720" alt="Two fingers swipe left on a window's title bar while a blurred preview fills the left half of the screen">
</picture>

## Gestures

Two-finger swipe on the title bar of the active window:

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/gestures-dark.png">
  <img src="docs/gestures-light.png" width="720" alt="Where each swipe sends the window: left and right halves, fill, minimize and the four quarters">
</picture>

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

1. Download `Pane-<version>.zip` from the [latest release](https://github.com/rokoov/pane/releases/latest), unzip it and move **Pane** to Applications.
2. Open Pane. It isn't notarized by Apple, so macOS blocks the first launch: open System Settings → Privacy & Security and click **Open Anyway**. If you prefer the terminal: `xattr -dr com.apple.quarantine /Applications/Pane.app`
3. Grant **Accessibility** access when asked (System Settings → Privacy & Security → Accessibility). Pane needs it to read and move windows.

After an update, macOS may ask for Accessibility access again: remove Pane from the list (or run `tccutil reset Accessibility com.rokoov.pane`) and grant it again.

Releases are built by GitHub Actions straight from the tagged source.

## Build from source

```bash
git clone https://github.com/rokoov/pane.git
cd pane
./build.sh run
```

`./build.sh zip` packs `build/Pane-<version>.zip`. Every build is signed ad-hoc and gets a new signature, so grant Accessibility again after rebuilding, or sign with your own certificate: `SIGN_ID="Apple Development: Your Name" ./build.sh`.

Run the tests with `swift test` (needs Xcode) and check formatting with `swift format lint --strict --recursive Sources Tests Package.swift`.

## Privacy

No network access, no analytics, no accounts. Pane only listens to scroll gestures and moves windows.

## License

MIT
