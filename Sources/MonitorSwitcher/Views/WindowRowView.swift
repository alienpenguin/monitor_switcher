import SwiftUI
import AppKit

public struct WindowRowView: View {
    let window: WindowInfo
    let allMonitors: [Monitor]
    let currentMonitor: Monitor?
    let defaultStrategy: MoveStrategy
    let bringToFront: Bool
    let onMove: (WindowInfo, Monitor, MoveStrategy) -> Void
    let onFocus: (WindowInfo) -> Void

    public init(
        window: WindowInfo,
        allMonitors: [Monitor],
        currentMonitor: Monitor?,
        defaultStrategy: MoveStrategy,
        bringToFront: Bool,
        onMove: @escaping (WindowInfo, Monitor, MoveStrategy) -> Void,
        onFocus: @escaping (WindowInfo) -> Void
    ) {
        self.window = window
        self.allMonitors = allMonitors
        self.currentMonitor = currentMonitor
        self.defaultStrategy = defaultStrategy
        self.bringToFront = bringToFront
        self.onMove = onMove
        self.onFocus = onFocus
    }

    private var destinationMonitors: [Monitor] {
        allMonitors.filter { $0.id != window.monitorId }
    }

    public var body: some View {
        HStack(spacing: 10) {
            // App Icon (fixed size)
            if let icon = window.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.12), radius: 1.5, x: 0, y: 1)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.secondary)
            }

            // Window details (expands and truncates cleanly)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(window.appName)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if window.isMinimized {
                        Text("Minimized")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.secondary.opacity(0.2)))
                            .foregroundColor(.secondary)
                    }
                }

                Text(window.displayTitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(window.displayTitle)

                Text(window.formattedDimensions)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            // Move Actions (high priority, doesn't compress)
            if destinationMonitors.isEmpty {
                Text("Single Display")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .layoutPriority(1)
            } else if destinationMonitors.count == 1, let target = destinationMonitors.first {
                HStack(spacing: 3) {
                    Button(action: {
                        onMove(window, target, defaultStrategy)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("➔ \(target.name)")
                                .lineLimit(1)
                        }
                        .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    // Options menu for custom placement
                    Menu {
                        ForEach(MoveStrategy.allCases) { strategy in
                            Button(action: {
                                onMove(window, target, strategy)
                            }) {
                                Label(strategy.rawValue, systemImage: strategy.iconName)
                            }
                        }

                        Divider()

                        Button(action: {
                            onFocus(window)
                        }) {
                            Label("Bring to Front", systemImage: "macwindow.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 12))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                .layoutPriority(1)
            } else {
                // Multiple destination monitors
                HStack(spacing: 3) {
                    Menu {
                        ForEach(destinationMonitors) { target in
                            Menu(target.name) {
                                ForEach(MoveStrategy.allCases) { strategy in
                                    Button(action: {
                                        onMove(window, target, strategy)
                                    }) {
                                        Label(strategy.rawValue, systemImage: strategy.iconName)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button(action: {
                            onFocus(window)
                        }) {
                            Label("Bring to Front", systemImage: "macwindow.on.rectangle")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Move to...")
                        }
                        .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .layoutPriority(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}
