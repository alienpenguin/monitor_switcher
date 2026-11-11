import SwiftUI
import AppKit

@main
struct MonitorSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Monitor Switcher", id: "mainWindow") {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 920, height: 600)
        .commands {
            // Remove "New Window" (Cmd+N) so app remains strictly a single window
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize tray icon and global hotkey
        _ = AppWindowManager.shared
    }

    /// Do not terminate when window is closed - keep running in the tray!
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// When user clicks Dock icon or relaunches, restore single window
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppWindowManager.shared.showWindow()
        // Return false to prevent SwiftUI from instantiating an additional window!
        return false
    }

    /// Intercept Cmd-Q or Quit to show a confirmation dialog
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let wasVisible = AppWindowManager.shared.isWindowVisible

        // Temporarily bring app to front so confirmation alert is focused
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Quit Monitor Switcher?"
        alert.informativeText = "Are you sure you want to quit? The menu bar tray icon and global shortcut will no longer be available."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return .terminateNow
        } else {
            // If user cancelled and window was hidden, restore accessory policy so dock icon disappears again
            if !wasVisible {
                NSApp.setActivationPolicy(.accessory)
            }
            return .terminateCancel
        }
    }
}
