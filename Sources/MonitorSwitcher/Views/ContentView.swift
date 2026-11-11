import SwiftUI

public struct ContentView: View {
    @StateObject private var displayManager: DisplayManager
    @StateObject private var accessibilityManager: AccessibilityManager
    @StateObject private var windowManager: WindowManager
    @ObservedObject private var hotKeyManager = HotKeyManager.shared

    @State private var searchText: String = ""
    @State private var selectedStrategy: MoveStrategy = .smartCenter
    @State private var bringToFront: Bool = true
    @State private var targetScrollMonitorId: CGDirectDisplayID? = nil
    @State private var showingHotkeyPopover: Bool = false

    public init() {
        let disp = DisplayManager()
        let access = AccessibilityManager()
        let win = WindowManager(displayManager: disp, accessibilityManager: access)

        _displayManager = StateObject(wrappedValue: disp)
        _accessibilityManager = StateObject(wrappedValue: access)
        _windowManager = StateObject(wrappedValue: win)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            toolbarHeader

            Divider()

            // Accessibility permission reminder if untrusted
            if !accessibilityManager.isTrusted {
                PermissionBannerView(accessibilityManager: accessibilityManager)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Error banner if any
            if let errorMsg = windowManager.lastErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(errorMsg)
                        .font(.callout)
                        .foregroundColor(.red)
                    Spacer()
                    Button("Dismiss") {
                        windowManager.lastErrorMessage = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Visual Monitor Map
            if displayManager.monitors.count > 1 {
                MiniMonitorMap(
                    monitors: displayManager.monitors,
                    windows: windowManager.windows,
                    onSelectMonitor: { monitor in
                        targetScrollMonitorId = monitor.id
                    }
                )
                Divider()
            }

            // Main Content Area: Fully Responsive Side-by-Side Monitor Columns
            mainMonitorColumns
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Bottom Status Bar
            statusBar
        }
        .frame(minWidth: 700, minHeight: 460)
        .background(WindowAccessor { window in
            AppWindowManager.shared.attachWindow(window)
        })
        .onAppear {
            AppWindowManager.shared.configure(displayManager: displayManager, windowManager: windowManager)
            windowManager.refreshWindows()
        }
        .onChange(of: accessibilityManager.isTrusted) { isTrusted in
            if isTrusted {
                windowManager.refreshWindows()
            }
        }
    }

    // MARK: - Subviews

    private var toolbarHeader: some View {
        HStack(spacing: 10) {
            // App Branding
            HStack(spacing: 6) {
                Image(systemName: "rectangle.2.swap")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)

                Text("Monitor Switcher")
                    .font(.headline)
            }

            Spacer(minLength: 6)

            // Search Filter
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))

                TextField("Filter apps or titles...", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 150)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )

            // Move Mode Picker
            Menu {
                ForEach(MoveStrategy.allCases) { strategy in
                    Button(action: {
                        selectedStrategy = strategy
                    }) {
                        HStack {
                            Text(strategy.rawValue)
                            if selectedStrategy == strategy {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: selectedStrategy.iconName)
                    Text(selectedStrategy.rawValue)
                }
                .font(.system(size: 11))
            }
            .menuStyle(.borderedButton)
            .controlSize(.small)
            .help("Default placement strategy when moving windows")

            // Bring to Front Toggle
            Toggle(isOn: $bringToFront) {
                Text("Focus Window")
                    .font(.system(size: 11))
            }
            .toggleStyle(.checkbox)
            .help("Activate and bring the window to the front after moving")

            // Global Hotkey Popover Button
            Button(action: {
                showingHotkeyPopover.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                    Text(hotKeyManager.currentCombination.displayString)
                }
                .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .popover(isPresented: $showingHotkeyPopover, arrowEdge: .bottom) {
                HotkeySettingsView()
            }
            .help("Configure global hotkey to show/hide app")

            // Refresh Button
            Button(action: {
                windowManager.refreshWindows()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh monitors and windows (Cmd+R)")
            .keyboardShortcut("r", modifiers: .command)

            // Hide to Tray Button
            Button(action: {
                AppWindowManager.shared.hideWindow()
            }) {
                Image(systemName: "menubar.arrow.up.rectangle")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Hide to menu bar tray")

            // Permission status indicator
            if accessibilityManager.isTrusted {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("Ready")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .help("Accessibility permission is active")
            } else {
                Button(action: {
                    accessibilityManager.promptForPermission()
                }) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 7, height: 7)
                        Text("Permission")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var mainMonitorColumns: some View {
        Group {
            if displayManager.monitors.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "display.trianglebadge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No displays detected")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geo in
                    let monitorCount = CGFloat(displayManager.monitors.count)
                    let horizontalPadding: CGFloat = 12
                    let spacing: CGFloat = 12
                    let totalSpacing = spacing * max(0, monitorCount - 1)
                    let availableWidth = geo.size.width - (horizontalPadding * 2) - totalSpacing
                    let naturalWidthPerColumn = availableWidth / max(1, monitorCount)
                    let minColWidth: CGFloat = 340
                    let columnWidth = max(minColWidth, naturalWidthPerColumn)
                    let availableHeight = max(200, geo.size.height - 24)
                    let needsHorizontalScroll = naturalWidthPerColumn < minColWidth

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: needsHorizontalScroll) {
                            HStack(alignment: .top, spacing: spacing) {
                                ForEach(displayManager.monitors) { monitor in
                                    let wins = windowManager.windows.filter { $0.monitorId == monitor.id }
                                    MonitorView(
                                        monitor: monitor,
                                        allMonitors: displayManager.monitors,
                                        windows: wins,
                                        searchText: searchText,
                                        defaultStrategy: selectedStrategy,
                                        bringToFront: bringToFront,
                                        onMoveWindow: { win, target, strat in
                                            Task {
                                                _ = await windowManager.move(
                                                    window: win,
                                                    to: target,
                                                    strategy: strat,
                                                    bringToFront: bringToFront
                                                )
                                            }
                                        },
                                        onMoveAll: { src, target, strat in
                                            Task {
                                                await windowManager.moveAll(
                                                    from: src,
                                                    to: target,
                                                    strategy: strat
                                                )
                                            }
                                        },
                                        onFocusWindow: { win in
                                            if let ax = win.axElement {
                                                AXUIElementPerformAction(ax, kAXRaiseAction as CFString)
                                            }
                                            NSRunningApplication(processIdentifier: win.pid)?.activate(options: .activateIgnoringOtherApps)
                                        }
                                    )
                                    .frame(width: columnWidth, height: availableHeight)
                                    .id(monitor.id)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: targetScrollMonitorId) { targetId in
                            if let id = targetId {
                                withAnimation {
                                    proxy.scrollTo(id, anchor: .center)
                                }
                                targetScrollMonitorId = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private var statusBar: some View {
        HStack {
            let totalWindows = windowManager.windows.count
            let totalMonitors = displayManager.monitors.count

            Text("\(totalWindows) window\(totalWindows == 1 ? "" : "s") across \(totalMonitors) display\(totalMonitors == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if windowManager.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Text("Toggle Shortcut: \(hotKeyManager.currentCombination.displayString)")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.7))
    }
}
