import SwiftUI

public struct PermissionBannerView: View {
    @ObservedObject var accessibilityManager: AccessibilityManager

    public init(accessibilityManager: AccessibilityManager) {
        self.accessibilityManager = accessibilityManager
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 26))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 3) {
                Text("Accessibility Permission Required")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("macOS requires Accessibility access to detect window titles and move windows between monitors.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    accessibilityManager.promptForPermission()
                }) {
                    Label("Grant Permission", systemImage: "checkmark.shield")
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    accessibilityManager.openSystemSettings()
                }) {
                    Label("Open Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}
