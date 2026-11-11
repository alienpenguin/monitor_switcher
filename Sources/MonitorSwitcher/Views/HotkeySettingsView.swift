import SwiftUI

public struct HotkeySettingsView: View {
    @ObservedObject var hotKeyManager = HotKeyManager.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text("Global Hotkey")
                    .font(.headline)
            }

            Text("Press this combination from any application to quickly show or hide Monitor Switcher.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(HotKeyCombination.allPresets) { preset in
                    Button(action: {
                        hotKeyManager.setCombination(preset)
                    }) {
                        HStack {
                            Text(preset.name)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)

                            Spacer()

                            Text(preset.displayString)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)))

                            if hotKeyManager.currentCombination == preset {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.accentColor)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.clear)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 3)
                }
            }

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "menubar.arrow.up.rectangle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Also accessible via the tray icon in your menu bar.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(width: 290)
    }
}
