# Monitor Switcher for macOS 🖥️ ➔ 🖥️

A native, lightweight macOS application built with SwiftUI and Swift that lists all open application windows, displays which monitor each window is currently positioned on, and allows you to move any window to another display with a single click.

---

## ✨ Features

- **Multi-Monitor Awareness**:
  - Automatically discovers all attached displays and maps their physical desk arrangement.
  - Displays each monitor's name, resolution, scale factor (Retina / Standard), and Main Display status.
  - Interactive **Mini Monitor Map** previewing display topology.
- **Responsive Layout & Window Scaling**:
  - Monitors adapt and scale proportionally with window resizing (e.g. 50/50 split on dual monitors).
  - Explicit vertical scrollbars inside each monitor column when window height decreases.
  - Horizontal scrolling automatically activates if the window is narrowed below the minimum column width.
  - Window title truncation and tooltips so action buttons never get clipped.
- **Menu Bar Tray Icon & Background Running**:
  - A persistent status item (`rectangle.2.swap`) in the macOS Menu Bar.
  - Left-click tray icon: Instantly toggles the window (Show / Hide).
  - Right-click tray icon: Opens a context menu with active display summaries, shortcut info, and quick actions.
  - Closing the window (red close button `X` or `Cmd+W`) keeps the app running in the background tray instead of quitting!
- **Global Hotkey (Key Combination)**:
  - Summon or dismiss the app from anywhere in macOS using a system-wide hotkey.
  - **Default**: `⌥⇧M` (Option + Shift + M).
  - Customizable presets available via the toolbar keyboard button or tray menu:
    - `⌥⇧M` (Option + Shift + M)
    - `⌃⌥M` (Control + Option + M)
    - `⌥⌘M` (Command + Option + M)
    - `⌃⇧M` (Control + Shift + M)
    - `⌥Space` (Option + Space)
- **Window Movement Engine**:
  - **1-Click Window Moving**: Immediate buttons to send any window to another connected monitor.
  - **Move Strategies**:
    - 🎯 **Smart Center** (default): Fits window safely within the target display's usable area (excluding Menu Bar & Dock) and centers it.
    - 📐 **Proportional**: Retains the exact relative coordinates percentage on the target screen.
    - ⛶ **Maximize / Fill**: Snaps the window to fill the entire usable area of the destination display.
    - ◧ **Left Half / ◨ Right Half**: Instantly snaps to the left or right half of the target display.
  - **Focus on Move**: Optionally activates and brings the moved window to the front.
  - **Bulk Move**: Migrate all windows from one monitor to another with a single click.
- **Built-in Accessibility Helper**:
  - Informs you if macOS Accessibility permission is needed and provides a 1-click button to open System Settings.
  - Dynamically updates the instant permission is toggled.

---

## 🚀 Quick Start

### 1. Build and Run the App

From the project root:

```bash
# Build the release .app bundle
make build

# Launch the app
open dist/MonitorSwitcher.app
```

Or simply:
```bash
make run
```

### 2. (Optional) Install to `/Applications`

```bash
make install
```
This copies `MonitorSwitcher.app` into `/Applications/MonitorSwitcher.app` so you can launch it via Spotlight, Raycast, or Launchpad.

---

## ⌨️ Shortcuts & Hotkeys

| Shortcut | Scope | Action |
|---|---|---|
| `⌥⇧M` *(or chosen preset)* | **Global (System-wide)** | Toggle Monitor Switcher (Show / Hide) |
| `Cmd + R` | In-App | Refresh monitors and window positions |
| `Cmd + W` | In-App | Hide window to tray (keeps app running) |
| `Cmd + Q` | In-App | Quit application |

---

## 🔐 macOS Permissions

macOS requires **Accessibility** permissions for apps to inspect other applications' window titles and reposition windows:

1. When you first launch `MonitorSwitcher.app`, the app will display a **Permission Needed** banner.
2. Click **Grant Permission** or **Open Settings**.
3. In macOS **System Settings** ➔ **Privacy & Security** ➔ **Accessibility**, toggle **Monitor Switcher** to **ON**.
4. The app will immediately detect the permission and unlock full window movement capabilities!
