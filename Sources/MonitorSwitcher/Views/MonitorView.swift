import SwiftUI

public struct MonitorView: View {
    let monitor: Monitor
    let allMonitors: [Monitor]
    let windows: [WindowInfo]
    let searchText: String
    let defaultStrategy: MoveStrategy
    let bringToFront: Bool
    let onMoveWindow: (WindowInfo, Monitor, MoveStrategy) -> Void
    let onMoveAll: (Monitor, Monitor, MoveStrategy) -> Void
    let onFocusWindow: (WindowInfo) -> Void

    public init(
        monitor: Monitor,
        allMonitors: [Monitor],
        windows: [WindowInfo],
        searchText: String,
        defaultStrategy: MoveStrategy,
        bringToFront: Bool,
        onMoveWindow: @escaping (WindowInfo, Monitor, MoveStrategy) -> Void,
        onMoveAll: @escaping (Monitor, Monitor, MoveStrategy) -> Void,
        onFocusWindow: @escaping (WindowInfo) -> Void
    ) {
        self.monitor = monitor
        self.allMonitors = allMonitors
        self.windows = windows
        self.searchText = searchText
        self.defaultStrategy = defaultStrategy
        self.bringToFront = bringToFront
        self.onMoveWindow = onMoveWindow
        self.onMoveAll = onMoveAll
        self.onFocusWindow = onFocusWindow
    }

    private var filteredWindows: [WindowInfo] {
        windows.filter { $0.matchesSearch(searchText) }
    }

    private var otherMonitors: [Monitor] {
        allMonitors.filter { $0.id != monitor.id }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Monitor Header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: monitor.isMain ? "laptopcomputer" : "display")
                        .font(.system(size: 16))
                        .foregroundColor(monitor.isMain ? .blue : .purple)

                    Text(monitor.name)
                        .font(.headline)
                        .lineLimit(1)

                    if monitor.isMain {
                        Text("Main")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.15)))
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Text("\(windows.count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.2)))
                        .foregroundColor(.primary)

                    // Bulk action menu
                    if !otherMonitors.isEmpty && !windows.isEmpty {
                        Menu {
                            ForEach(otherMonitors) { target in
                                Button(action: {
                                    onMoveAll(monitor, target, defaultStrategy)
                                }) {
                                    Label("Move all to \(target.name)", systemImage: "arrow.right.to.line")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 13))
                        }
                        .menuStyle(.borderlessButton)
                        .help("Bulk actions for this monitor")
                    }
                }

                HStack(spacing: 6) {
                    Text(monitor.formattedResolution)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("Origin: (\(Int(monitor.bounds.origin.x)), \(Int(monitor.bounds.origin.y)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)

            Divider()

            // Window items
            if filteredWindows.isEmpty {
                VStack(spacing: 12) {
                    Spacer(minLength: 40)
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))

                    Text(searchText.isEmpty ? "No windows on this display" : "No matching windows")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredWindows) { win in
                            WindowRowView(
                                window: win,
                                allMonitors: allMonitors,
                                currentMonitor: monitor,
                                defaultStrategy: defaultStrategy,
                                bringToFront: bringToFront,
                                onMove: onMoveWindow,
                                onFocus: onFocusWindow
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
    }
}
