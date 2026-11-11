import Foundation
import AppKit
import ApplicationServices
import Combine

@MainActor
public final class AccessibilityManager: ObservableObject {
    @Published public private(set) var isTrusted: Bool = false
    private var timer: Timer?

    public init() {
        self.isTrusted = AXIsProcessTrusted()
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    /// Refresh trust status immediately
    public func checkPermission() {
        let trusted = AXIsProcessTrusted()
        if self.isTrusted != trusted {
            self.isTrusted = trusted
        }
    }

    /// Prompt system dialog asking for accessibility permission
    public func promptForPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        checkPermission()
    }

    /// Open macOS System Settings directly to Privacy & Security -> Accessibility
    public func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startPolling() {
        // Poll every 1.5 seconds if untrusted so UI auto-updates when granted
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.checkPermission()
                if self.isTrusted {
                    // Slow down polling once trusted
                    self.timer?.invalidate()
                    self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            self?.checkPermission()
                        }
                    }
                }
            }
        }
    }
}
