import Foundation
import CoreGraphics
import AppKit

public struct Monitor: Identifiable, Hashable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let isMain: Bool
    public let bounds: CGRect          // Global CoreGraphics coordinates
    public let visibleBounds: CGRect   // Usable area excluding Menu Bar & Dock
    public let scaleFactor: CGFloat

    public init(
        id: CGDirectDisplayID,
        name: String,
        isMain: Bool,
        bounds: CGRect,
        visibleBounds: CGRect,
        scaleFactor: CGFloat
    ) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.bounds = bounds
        self.visibleBounds = visibleBounds
        self.scaleFactor = scaleFactor
    }

    /// Calculate the intersection area between a window rect and this monitor
    public func overlapArea(with rect: CGRect) -> CGFloat {
        let intersection = bounds.intersection(rect)
        if intersection.isNull || intersection.isEmpty {
            return 0
        }
        return intersection.width * intersection.height
    }

    /// Distance from monitor center to a given point
    public func distance(to point: CGPoint) -> CGFloat {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = center.x - point.x
        let dy = center.y - point.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Returns a human-friendly resolution string
    public var formattedResolution: String {
        let w = Int(bounds.width)
        let h = Int(bounds.height)
        let scale = scaleFactor > 1.0 ? " @\(Int(scaleFactor))x" : ""
        return "\(w) × \(h)\(scale)"
    }

    public var shortName: String {
        if isMain {
            return "\(name) (Main)"
        }
        return name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Monitor, rhs: Monitor) -> Bool {
        lhs.id == rhs.id
    }
}
