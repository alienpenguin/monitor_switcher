import AppKit
import SwiftUI

@MainActor
public final class AppWindowManager: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared = AppWindowManager()

    @Published public private(set) var isWindowVisible: Bool = true
    private weak var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var displayManager: DisplayManager?
    private var windowManager: WindowManager?

    private override init() {
        super.init()
        setupStatusItem()
        setupHotKey()
    }

    public func configure(displayManager: DisplayManager, windowManager: WindowManager) {
        self.displayManager = displayManager
        self.windowManager = windowManager
    }

    /// Attaches the main application window
    public func attachWindow(_ window: NSWindow) {
        if self.mainWindow === window { return }
        self.mainWindow = window
        window.delegate = self
        // Ensure standard window collection behavior
        window.collectionBehavior = [.managed, .participatesInCycle]
        self.isWindowVisible = window.isVisible

        if window.isVisible {
            NSApp.setActivationPolicy(.regular)
        }
    }

    /// Toggle show / hide for the main window
    public func toggleWindow() {
        resolveMainWindow()
        guard let window = mainWindow else {
            showWindow()
            return
        }

        if window.isVisible && NSApp.isActive {
            hideWindow()
        } else {
            showWindow()
        }
    }

    public func showWindow() {
        resolveMainWindow()
        // Restore dock icon
        NSApp.setActivationPolicy(.regular)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        isWindowVisible = true
        windowManager?.refreshWindows()
    }

    public func hideWindow() {
        resolveMainWindow()
        mainWindow?.orderOut(nil)
        isWindowVisible = false
        // Remove icon from Dock, leaving only the Menu Bar tray icon
        NSApp.setActivationPolicy(.accessory)
    }

    private func resolveMainWindow() {
        if mainWindow == nil {
            for win in NSApp.windows {
                if win.canBecomeKey && !win.className.contains("StatusBar") && !win.className.contains("Menu") {
                    attachWindow(win)
                    break
                }
            }
        }
    }

    // MARK: - NSWindowDelegate

    /// Intercept red close button to hide to tray and remove from Dock
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideWindow()
        return false
    }

    public func windowDidBecomeKey(_ notification: Notification) {
        isWindowVisible = true
        NSApp.setActivationPolicy(.regular)
    }

    public func windowDidResignKey(_ notification: Notification) {
        // Window lost key focus
    }

    // MARK: - Status Bar / Tray Icon

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            if let image = NSImage(systemSymbolName: "rectangle.2.swap", accessibilityDescription: "Monitor Switcher")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.statusItem = item
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            toggleWindow()
            return
        }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu()
        } else {
            toggleWindow()
        }
    }

    public func showContextMenu() {
        let menu = NSMenu()

        // Toggle window item
        let hotKeyString = HotKeyManager.shared.currentCombination.displayString
        let toggleItem = NSMenuItem(
            title: isWindowVisible ? "Hide Monitor Switcher" : "Show Monitor Switcher",
            action: #selector(menuToggleClicked),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        // Shortcut hint item
        let shortcutItem = NSMenuItem(title: "Shortcut: \(hotKeyString)", action: nil, keyEquivalent: "")
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

        menu.addItem(NSMenuItem.separator())

        // Refresh windows item
        let refreshItem = NSMenuItem(
            title: "Refresh Windows",
            action: #selector(menuRefreshClicked),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Connected Displays summary
        if let displays = displayManager?.monitors, !displays.isEmpty {
            let header = NSMenuItem(title: "Displays:", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for d in displays {
                let count = windowManager?.windows.filter { $0.monitorId == d.id }.count ?? 0
                let item = NSMenuItem(
                    title: "  \(d.name) (\(count) window\(count == 1 ? "" : "s"))",
                    action: nil,
                    keyEquivalent: ""
                )
                item.isEnabled = false
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Quit item (triggers confirmation prompt)
        let quitItem = NSMenuItem(
            title: "Quit Monitor Switcher",
            action: #selector(menuQuitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Reset menu so left-click continues triggering toggleWindow directly
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    @objc private func menuToggleClicked() {
        toggleWindow()
    }

    @objc private func menuRefreshClicked() {
        windowManager?.refreshWindows()
        if !isWindowVisible {
            showWindow()
        }
    }

    @objc private func menuQuitClicked() {
        NSApp.terminate(nil)
    }

    // MARK: - HotKey Setup

    private func setupHotKey() {
        HotKeyManager.shared.onHotKeyTriggered = { [weak self] in
            self?.toggleWindow()
        }
    }
}
