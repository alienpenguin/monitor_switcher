import Foundation
import CoreGraphics
import AppKit
import ApplicationServices

public struct WindowInfo: Identifiable, @unchecked Sendable {
    public let id: String
    public let pid: pid_t
    public let appName: String
    public let bundleIdentifier: String?
    public let title: String
    public var bounds: CGRect
    public let isMinimized: Bool
    public let appIcon: NSImage?
    public let axElement: AXUIElement?
    public var monitorId: CGDirectDisplayID?

    public init(
        id: String,
        pid: pid_t,
        appName: String,
        bundleIdentifier: String?,
        title: String,
        bounds: CGRect,
        isMinimized: Bool = false,
        appIcon: NSImage? = nil,
        axElement: AXUIElement? = nil,
        monitorId: CGDirectDisplayID? = nil
    ) {
        self.id = id
        self.pid = pid
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.bounds = bounds
        self.isMinimized = isMinimized
        self.appIcon = appIcon
        self.axElement = axElement
        self.monitorId = monitorId
    }

    public var displayTitle: String {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return appName
        }
        return title
    }

    public var formattedDimensions: String {
        let w = Int(bounds.width)
        let h = Int(bounds.height)
        let x = Int(bounds.origin.x)
        let y = Int(bounds.origin.y)
        return "\(w) × \(h) at (\(x), \(y))"
    }

    public func matchesSearch(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return appName.lowercased().contains(q) ||
               title.lowercased().contains(q) ||
               "\(pid)".contains(q)
    }
}
