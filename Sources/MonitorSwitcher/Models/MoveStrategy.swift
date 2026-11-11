import Foundation
import CoreGraphics

public enum MoveStrategy: String, CaseIterable, Identifiable, Sendable {
    case smartCenter = "Center"
    case proportional = "Proportional"
    case maximize = "Maximize"
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .smartCenter: return "dot.circle.viewfinder"
        case .proportional: return "arrow.up.and.down.and.arrow.left.and.right"
        case .maximize: return "arrow.up.left.and.arrow.down.right"
        case .leftHalf: return "rectangle.leadinghalf.inset.filled"
        case .rightHalf: return "rectangle.trailinghalf.inset.filled"
        }
    }

    public var description: String {
        switch self {
        case .smartCenter:
            return "Center window on target display"
        case .proportional:
            return "Preserve relative position on target display"
        case .maximize:
            return "Fill target display visible area"
        case .leftHalf:
            return "Place on left half of target display"
        case .rightHalf:
            return "Place on right half of target display"
        }
    }

    /// Computes the target frame (position & size) for moving a window from source to target
    public func targetFrame(
        windowFrame: CGRect,
        sourceMonitor: Monitor?,
        targetMonitor: Monitor
    ) -> CGRect {
        let dest = targetMonitor.visibleBounds

        switch self {
        case .smartCenter:
            let fitWidth = min(windowFrame.width, dest.width)
            let fitHeight = min(windowFrame.height, dest.height)
            let x = dest.minX + max(0, (dest.width - fitWidth) / 2)
            let y = dest.minY + max(0, (dest.height - fitHeight) / 2)
            return CGRect(x: x, y: y, width: fitWidth, height: fitHeight)

        case .proportional:
            let src = sourceMonitor?.visibleBounds ?? targetMonitor.visibleBounds
            let relX = src.width > 0 ? (windowFrame.minX - src.minX) / src.width : 0
            let relY = src.height > 0 ? (windowFrame.minY - src.minY) / src.height : 0

            let fitWidth = min(windowFrame.width, dest.width)
            let fitHeight = min(windowFrame.height, dest.height)

            var x = dest.minX + (relX * dest.width)
            var y = dest.minY + (relY * dest.height)

            // Ensure window remains inside visible bounds
            x = max(dest.minX, min(x, dest.maxX - fitWidth))
            y = max(dest.minY, min(y, dest.maxY - fitHeight))

            return CGRect(x: x, y: y, width: fitWidth, height: fitHeight)

        case .maximize:
            return dest

        case .leftHalf:
            let halfWidth = dest.width / 2
            return CGRect(x: dest.minX, y: dest.minY, width: halfWidth, height: dest.height)

        case .rightHalf:
            let halfWidth = dest.width / 2
            return CGRect(x: dest.minX + halfWidth, y: dest.minY, width: halfWidth, height: dest.height)
        }
    }
}
