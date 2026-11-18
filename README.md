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

Requires macOS 13 or later.

```bash
git clone https://github.com/rokoov/pane.git
cd pane
./build.sh run
```

Pane asks for **Accessibility** access on first launch (System Settings → Privacy & Security → Accessibility). It needs this to read and move windows.

> Builds signed ad-hoc get a new signature each time, so macOS may ask for Accessibility access again after rebuilding. Remove Pane from the list (or run `tccutil reset Accessibility com.rokoov.pane`) and grant it again, or build with your own certificate: `SIGN_ID="Apple Development: Your Name" ./build.sh`.

## Privacy

No network access, no analytics, no accounts. Pane only listens to scroll gestures and moves windows.

## License

MIT
