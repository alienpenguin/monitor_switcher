import SwiftUI
import AppKit

public struct WindowAccessor: NSViewRepresentable {
    public var onWindowFound: (NSWindow) -> Void

    public init(onWindowFound: @escaping (NSWindow) -> Void) {
        self.onWindowFound = onWindowFound
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.onWindowFound(window)
            }
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            onWindowFound(window)
        }
    }
}
