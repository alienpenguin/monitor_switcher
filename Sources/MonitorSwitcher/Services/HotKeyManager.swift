import Foundation
import Carbon
import Combine

public struct HotKeyCombination: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let displayString: String
    public let keyCode: UInt32
    public let modifiers: UInt32

    public init(id: String, name: String, displayString: String, keyCode: UInt32, modifiers: UInt32) {
        self.id = id
        self.name = name
        self.displayString = displayString
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let optionShiftM = HotKeyCombination(
        id: "option_shift_m",
        name: "Option + Shift + M",
        displayString: "⌥⇧M",
        keyCode: UInt32(kVK_ANSI_M),
        modifiers: UInt32(optionKey | shiftKey)
    )

    public static let controlOptionM = HotKeyCombination(
        id: "control_option_m",
        name: "Control + Option + M",
        displayString: "⌃⌥M",
        keyCode: UInt32(kVK_ANSI_M),
        modifiers: UInt32(controlKey | optionKey)
    )

    public static let commandOptionM = HotKeyCombination(
        id: "command_option_m",
        name: "Command + Option + M",
        displayString: "⌥⌘M",
        keyCode: UInt32(kVK_ANSI_M),
        modifiers: UInt32(cmdKey | optionKey)
    )

    public static let controlShiftM = HotKeyCombination(
        id: "control_shift_m",
        name: "Control + Shift + M",
        displayString: "⌃⇧M",
        keyCode: UInt32(kVK_ANSI_M),
        modifiers: UInt32(controlKey | shiftKey)
    )

    public static let optionSpace = HotKeyCombination(
        id: "option_space",
        name: "Option + Space",
        displayString: "⌥Space",
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(optionKey)
    )

    public static let allPresets: [HotKeyCombination] = [
        .optionShiftM,
        .controlOptionM,
        .commandOptionM,
        .controlShiftM,
        .optionSpace
    ]
}

@MainActor
public final class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()

    @Published public private(set) var currentCombination: HotKeyCombination
    public var onHotKeyTriggered: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4D535754), id: 1) // 'MSWT', 1

    private init() {
        let savedId = UserDefaults.standard.string(forKey: "SelectedHotKeyID") ?? HotKeyCombination.optionShiftM.id
        let initial = HotKeyCombination.allPresets.first(where: { $0.id == savedId }) ?? .optionShiftM
        self.currentCombination = initial

        setupCarbonEventHandler()
        register(combination: initial)
    }

    deinit {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }

    public func setCombination(_ combination: HotKeyCombination) {
        guard combination != currentCombination else { return }
        unregister()
        register(combination: combination)
        currentCombination = combination
        UserDefaults.standard.set(combination.id, forKey: "SelectedHotKeyID")
    }

    private func setupCarbonEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    manager.onHotKeyTriggered?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func register(combination: HotKeyCombination) {
        let status = RegisterEventHotKey(
            combination.keyCode,
            combination.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("HotKeyManager: Failed to register hotkey \(combination.name) with error \(status)")
        }
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}
