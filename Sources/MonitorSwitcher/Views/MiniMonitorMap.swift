import SwiftUI
import CoreGraphics

public struct MiniMonitorMap: View {
    let monitors: [Monitor]
    let windows: [WindowInfo]
    var onSelectMonitor: ((Monitor) -> Void)? = nil

    public init(
        monitors: [Monitor],
        windows: [WindowInfo],
        onSelectMonitor: ((Monitor) -> Void)? = nil
    ) {
        self.monitors = monitors
        self.windows = windows
        self.onSelectMonitor = onSelectMonitor
    }

    public var body: some View {
        if monitors.isEmpty {
            EmptyView()
        } else {
            let boundingBox = computeBoundingBox()
            let availableHeight: CGFloat = 65
            let scale = availableHeight / max(1, boundingBox.height)
            let totalWidth = boundingBox.width * scale

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Displays Arrangement", systemImage: "rectangle.3.group")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                ZStack(alignment: .topLeading) {
                    ForEach(monitors) { monitor in
                        let relX = (monitor.bounds.minX - boundingBox.minX) * scale
                        let relY = (monitor.bounds.minY - boundingBox.minY) * scale
                        let width = monitor.bounds.width * scale
                        let height = monitor.bounds.height * scale
                        let winCount = windows.filter { $0.monitorId == monitor.id }.count

                        Button(action: {
                            onSelectMonitor?(monitor)
                        }) {
                            VStack(spacing: 2) {
                                HStack(spacing: 3) {
                                    Image(systemName: monitor.isMain ? "star.fill" : "display")
                                        .font(.system(size: 8))
                                        .foregroundColor(monitor.isMain ? .yellow : .accentColor)
                                    Text(monitor.name)
                                        .font(.system(size: 9, weight: .bold))
                                        .lineLimit(1)
                                }

                                Text("\(winCount) window\(winCount == 1 ? "" : "s")")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: max(50, width), height: max(35, height))
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(monitor.isMain ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .offset(x: relX, y: relY)
                    }
                }
                .frame(width: totalWidth, height: availableHeight)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
    }

    private func computeBoundingBox() -> CGRect {
        guard let first = monitors.first else { return .zero }
        var minX = first.bounds.minX
        var minY = first.bounds.minY
        var maxX = first.bounds.maxX
        var maxY = first.bounds.maxY

        for m in monitors {
            minX = min(minX, m.bounds.minX)
            minY = min(minY, m.bounds.minY)
            maxX = max(maxX, m.bounds.maxX)
            maxY = max(maxY, m.bounds.maxY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
