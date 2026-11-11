import Foundation
import AppKit
import CoreGraphics
import Combine

@MainActor
public final class DisplayManager: ObservableObject {
    @Published public private(set) var monitors: [Monitor] = []
    private var cancellables = Set<AnyCancellable>()

    public init() {
        refreshMonitors()
        setupNotificationObserver()
    }

    /// Refresh connected monitors and convert coordinate spaces
    public func refreshMonitors() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            self.monitors = []
            return
        }

        // Primary screen has origin (0, 0) in Cocoa coordinates and its height defines the flip offset
        guard let primaryScreen = screens.first else { return }
        let primaryHeight = primaryScreen.frame.height
        let mainDisplayID = CGMainDisplayID()

        var discovered: [Monitor] = []

        for screen in screens {
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let isMain = (displayID == mainDisplayID) || (screen == primaryScreen)

            // Convert NSScreen coordinates (bottom-left origin) to CoreGraphics (top-left origin)
            let f = screen.frame
            let vf = screen.visibleFrame

            let cgBounds = CGRect(
                x: f.origin.x,
                y: primaryHeight - (f.origin.y + f.size.height),
                width: f.size.width,
                height: f.size.height
            )

            let cgVisibleBounds = CGRect(
                x: vf.origin.x,
                y: primaryHeight - (vf.origin.y + vf.size.height),
                width: vf.size.width,
                height: vf.size.height
            )

            let monitor = Monitor(
                id: displayID,
                name: screen.localizedName,
                isMain: isMain,
                bounds: cgBounds,
                visibleBounds: cgVisibleBounds,
                scaleFactor: screen.backingScaleFactor
            )

            discovered.append(monitor)
        }

        // Sort monitors horizontally by their X coordinate to match physical desk placement
        discovered.sort { $0.bounds.minX < $1.bounds.minX }

        self.monitors = discovered
    }

    /// Find which monitor contains the given window rect
    public func monitor(for rect: CGRect) -> Monitor? {
        guard !monitors.isEmpty else { return nil }

        // Find monitor with greatest overlap area
        var bestMonitor: Monitor? = nil
        var maxArea: CGFloat = 0

        for monitor in monitors {
            let area = monitor.overlapArea(with: rect)
            if area > maxArea {
                maxArea = area
                bestMonitor = monitor
            }
        }

        if let best = bestMonitor, maxArea > 0 {
            return best
        }

        // If window is outside or on boundary, find nearest monitor to window center
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return monitors.min(by: { $0.distance(to: center) < $1.distance(to: center) })
    }

    public func monitor(withID id: CGDirectDisplayID) -> Monitor? {
        monitors.first { $0.id == id }
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshMonitors()
                }
            }
            .store(in: &cancellables)
    }
}
