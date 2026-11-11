import Foundation
import AppKit
import ApplicationServices
import Combine

@MainActor
public final class WindowManager: ObservableObject {
    @Published public private(set) var windows: [WindowInfo] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var lastErrorMessage: String? = nil

    private let displayManager: DisplayManager
    private let accessibilityManager: AccessibilityManager

    public init(displayManager: DisplayManager, accessibilityManager: AccessibilityManager) {
        self.displayManager = displayManager
        self.accessibilityManager = accessibilityManager
        refreshWindows()
    }

    /// Refresh all window positions and statuses
    public func refreshWindows() {
        isLoading = true
        lastErrorMessage = nil

        defer { isLoading = false }

        displayManager.refreshMonitors()

        if accessibilityManager.isTrusted {
            windows = fetchWindowsViaAccessibility()
        } else {
            windows = fetchWindowsViaCoreGraphics()
        }
    }

    /// Move a specific window to a target monitor
    public func move(
        window: WindowInfo,
        to targetMonitor: Monitor,
        strategy: MoveStrategy = .smartCenter,
        bringToFront: Bool = true
    ) async -> Bool {
        guard accessibilityManager.isTrusted else {
            accessibilityManager.promptForPermission()
            lastErrorMessage = "Accessibility permission is required to move windows."
            return false
        }

        // Locate or reuse AXUIElement for this window
        guard let axWindow = resolveAXWindow(for: window) else {
            lastErrorMessage = "Unable to access window for \(window.appName)."
            return false
        }

        let sourceMonitor = displayManager.monitor(for: window.bounds)
        let targetRect = strategy.targetFrame(
            windowFrame: window.bounds,
            sourceMonitor: sourceMonitor,
            targetMonitor: targetMonitor
        )

        let success = applyFrame(axWindow: axWindow, targetRect: targetRect)

        if success {
            if bringToFront {
                AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                if let app = NSRunningApplication(processIdentifier: window.pid) {
                    app.activate(options: .activateIgnoringOtherApps)
                }
            }

            // Brief pause to allow OS window manager to apply geometry, then refresh
            try? await Task.sleep(nanoseconds: 150_000_000)
            refreshWindows()
            return true
        } else {
            lastErrorMessage = "Failed to reposition window. The app may restrict window manipulation."
            return false
        }
    }

    /// Move all windows currently on sourceMonitor to targetMonitor
    public func moveAll(
        from sourceMonitor: Monitor,
        to targetMonitor: Monitor,
        strategy: MoveStrategy = .smartCenter
    ) async {
        let windowsOnSource = windows.filter { $0.monitorId == sourceMonitor.id }
        for win in windowsOnSource {
            _ = await move(window: win, to: targetMonitor, strategy: strategy, bringToFront: false)
        }
        refreshWindows()
    }

    // MARK: - Internal Helpers

    /// Resolve AXUIElement: either from cache or query live from PID
    private func resolveAXWindow(for window: WindowInfo) -> AXUIElement? {
        if let ax = window.axElement {
            return ax
        }

        let axApp = AXUIElementCreateApplication(window.pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindows = windowsRef as? [AXUIElement] else {
            return nil
        }

        // Attempt to find closest matching window by bounds or title
        for candidate in axWindows {
            if let frame = getFrame(for: candidate) {
                if abs(frame.origin.x - window.bounds.origin.x) < 20 &&
                   abs(frame.origin.y - window.bounds.origin.y) < 20 {
                    return candidate
                }
            }
        }

        return axWindows.first
    }

    /// Apply target position and size using standard 3-pass sequence
    private func applyFrame(axWindow: AXUIElement, targetRect: CGRect) -> Bool {
        var newOrigin = targetRect.origin
        var newSize = targetRect.size

        // Pass 1: Set position
        if let posVal = AXValueCreate(.cgPoint, &newOrigin) {
            _ = AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posVal)
        }

        // Pass 2: Set size
        if let sizeVal = AXValueCreate(.cgSize, &newSize) {
            _ = AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeVal)
        }

        // Pass 3: Re-set position in case window size change shifted the origin
        var finalSuccess = false
        if let posVal = AXValueCreate(.cgPoint, &newOrigin) {
            let res = AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posVal)
            finalSuccess = (res == .success)
        }

        return finalSuccess
    }

    /// Fetch windows directly using macOS Accessibility API
    private func fetchWindowsViaAccessibility() -> [WindowInfo] {
        var result: [WindowInfo] = []
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }

        for app in apps {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let axWindows = windowsRef as? [AXUIElement] else {
                continue
            }

            for axWin in axWindows {
                // Verify window role
                var roleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWin, kAXRoleAttribute as CFString, &roleRef) == .success,
                   let role = roleRef as? String, role != (kAXWindowRole as String) {
                    continue
                }

                // Subrole filter (ignore tooltips, floating helper panels if they are not windows)
                var subroleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWin, kAXSubroleAttribute as CFString, &subroleRef) == .success,
                   let subrole = subroleRef as? String {
                    if subrole == "AXUnknown" { continue }
                }

                // Check minimized state
                var isMinimized = false
                var minRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWin, kAXMinimizedAttribute as CFString, &minRef) == .success,
                   let b = minRef as? Bool {
                    isMinimized = b
                }

                guard let frame = getFrame(for: axWin) else { continue }
                // Ignore tiny invisible 0-sized utility windows
                guard frame.width >= 50 && frame.height >= 50 else { continue }

                // Get title
                var title = ""
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let t = titleRef as? String {
                    title = t
                }

                let appName = app.localizedName ?? "App"
                let assignedMonitor = displayManager.monitor(for: frame)

                let item = WindowInfo(
                    id: "ax-\(app.processIdentifier)-\(Int(frame.origin.x))-\(Int(frame.origin.y))-\(Int(frame.width))",
                    pid: app.processIdentifier,
                    appName: appName,
                    bundleIdentifier: app.bundleIdentifier,
                    title: title.isEmpty ? appName : title,
                    bounds: frame,
                    isMinimized: isMinimized,
                    appIcon: app.icon,
                    axElement: axWin,
                    monitorId: assignedMonitor?.id
                )
                result.append(item)
            }
        }

        return result
    }

    /// Fallback window fetch using CoreGraphics when Accessibility is not yet granted
    private func fetchWindowsViaCoreGraphics() -> [WindowInfo] {
        var result: [WindowInfo] = []
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return result
        }

        for win in list {
            let layer = win[kCGWindowLayer as String] as? Int ?? -1
            guard layer == 0 else { continue }

            let pid = win[kCGWindowOwnerPID as String] as? Int32 ?? 0
            let wid = win[kCGWindowNumber as String] as? Int32 ?? 0
            let owner = win[kCGWindowOwnerName as String] as? String ?? "App"
            let name = win[kCGWindowName as String] as? String ?? ""

            guard let dict = win[kCGWindowBounds as String] as? NSDictionary else { continue }
            var bounds = CGRect.zero
            CGRectMakeWithDictionaryRepresentation(dict as CFDictionary, &bounds)
            guard bounds.width >= 50 && bounds.height >= 50 else { continue }

            let app = NSRunningApplication(processIdentifier: pid)
            if let app = app, app.activationPolicy != .regular {
                continue
            }

            let appName = app?.localizedName ?? owner
            let displayTitle = name.isEmpty ? appName : name
            let assignedMonitor = displayManager.monitor(for: bounds)

            let item = WindowInfo(
                id: "cg-\(wid)",
                pid: pid,
                appName: appName,
                bundleIdentifier: app?.bundleIdentifier,
                title: displayTitle,
                bounds: bounds,
                isMinimized: false,
                appIcon: app?.icon,
                axElement: nil,
                monitorId: assignedMonitor?.id
            )
            result.append(item)
        }

        return result
    }

    /// Read position and size of an AXUIElement
    private func getFrame(for axElement: AXUIElement) -> CGRect? {
        var posVal: CFTypeRef?
        var origin = CGPoint.zero
        if AXUIElementCopyAttributeValue(axElement, kAXPositionAttribute as CFString, &posVal) == .success,
           let val = posVal {
            AXValueGetValue(val as! AXValue, .cgPoint, &origin)
        } else {
            return nil
        }

        var sizeVal: CFTypeRef?
        var size = CGSize.zero
        if AXUIElementCopyAttributeValue(axElement, kAXSizeAttribute as CFString, &sizeVal) == .success,
           let val = sizeVal {
            AXValueGetValue(val as! AXValue, .cgSize, &size)
        } else {
            return nil
        }

        return CGRect(origin: origin, size: size)
    }
}
