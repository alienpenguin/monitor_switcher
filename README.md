# Monitor Switcher for macOS 🖥️ ➔ 🖥️

A native, lightweight macOS application built with SwiftUI and Swift that lists all open application windows, displays which monitor each window is currently positioned on, and allows you to move any window to another display with a single click.

---

## ✨ Features

- **Multi-Monitor Awareness**:
  - Automatically discovers all attached displays and maps their physical desk arrangement.
  - Displays each monitor's name, resolution, scale factor (Retina / Standard), and Main Display status.
  - Interactive **Mini Monitor Map** previewing display topology.
- **Window Detection & Organization**:
  - Organizes windows into side-by-side columns matching the real-world monitor layout.
  - Shows app icon, application name, window title, and exact dimensions/position coordinates.
  - Real-time search filter by app name or window title.
- **Window Movement Engine**:
  - **1-Click Window Moving**: Immediate buttons to send any window to another connected monitor.
  - **Move Strategies**:
    - 🎯 **Smart Center** (default): Fits window safely within the target display's usable area (excluding Menu Bar & Dock) and centers it.
    - 📐 **Proportional**: Retains the exact relative coordinates percentage on the target screen.
    - ⛶ **Maximize / Fill**: Snaps the window to fill the entire usable area of the destination display.
    - ◧ **Left Half / ◨ Right Half**: Instantly snaps to the left or right half of the target display.
  - **Focus on Move**: Optionally activates and brings the moved window to the front.
  - **Bulk Move**: Migrate all windows from one monitor to another with a single click.
- **Dynamic Updates**:
  - Auto-refreshes when display configuration changes (plugging in or unplugging monitors).
  - Quick refresh shortcut (`Cmd+R`).
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

## 🔐 macOS Permissions

macOS requires **Accessibility** permissions for apps to inspect other applications' window titles and reposition windows:

1. When you first launch `MonitorSwitcher.app`, the app will display a **Permission Needed** banner.
2. Click **Grant Permission** or **Open Settings**.
3. In macOS **System Settings** ➔ **Privacy & Security** ➔ **Accessibility**, toggle **Monitor Switcher** to **ON**.
4. The app will immediately detect the permission and unlock full window movement capabilities!

> *Note: Even before granting Accessibility permissions, the app will use CoreGraphics window inspection to list open windows and monitors in preview mode.*

---

## 🛠️ Architecture

- **`Models/`**
  - `Monitor.swift`: Display model, CoreGraphics display bounds, visible frame conversion (dock/menu bar safe zone), and intersection calculations.
  - `WindowInfo.swift`: Application window metadata, bounds, icon, PID, and live `AXUIElement` reference.
  - `MoveStrategy.swift`: Algorithms for computing target window coordinates (Smart Center, Proportional, Maximize, Half-splits).
- **`Services/`**
  - `DisplayManager.swift`: Screen discovery via `NSScreen` and `CGDirectDisplayID`. Converts macOS bottom-left coordinate space to global CoreGraphics top-left space.
  - `WindowManager.swift`: Accessibility-driven window enumeration and 3-pass repositioning engine (`kAXPositionAttribute` & `kAXSizeAttribute`).
  - `AccessibilityManager.swift`: Accessibility trust verification (`AXIsProcessTrusted`), system prompt launcher, and polling observer.
- **`Views/`**
  - `ContentView.swift`: Main dashboard, search bar, strategy picker, and status bar.
  - `MonitorView.swift`: Column view representing each physical monitor with header badges and window cards.
  - `WindowRowView.swift`: Individual window card with app icon, title, coordinates, and 1-click move button / options menu.
  - `MiniMonitorMap.swift`: Proportional visual mini-map of desk displays.
  - `PermissionBannerView.swift`: Accessibility onboarding banner.

---

## ⌨️ Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd + R` | Refresh monitors and window positions |
| `Cmd + Q` | Quit application |
