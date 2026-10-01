import AppKit
import Carbon.HIToolbox

/// A key plus modifiers, stored the way the system hot key API wants them.
nonisolated struct Shortcut: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var modifiers: UInt32   // Carbon: cmdKey, optionKey, controlKey, shiftKey

    static let standard = Shortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(cmdKey | shiftKey))
    /// Opens the menu bar panel.
    static let panelStandard = Shortcut(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(cmdKey | shiftKey | optionKey))

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// From a key press while recording. Needs Command or Control so it can't
    /// steal plain typing.
    init?(event: NSEvent) {
        let f = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard f.contains(.command) || f.contains(.control) else { return nil }
        var m: UInt32 = 0
        if f.contains(.command) { m |= UInt32(cmdKey) }
        if f.contains(.option) { m |= UInt32(optionKey) }
        if f.contains(.control) { m |= UInt32(controlKey) }
        if f.contains(.shift) { m |= UInt32(shiftKey) }
        self.init(keyCode: UInt32(event.keyCode), modifiers: m)
    }

    var display: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "\u{2303}" }
        if modifiers & UInt32(optionKey) != 0 { s += "\u{2325}" }
        if modifiers & UInt32(shiftKey) != 0 { s += "\u{21E7}" }
        if modifiers & UInt32(cmdKey) != 0 { s += "\u{2318}" }
        return s + Shortcut.keyName(keyCode)
    }

    private static func keyName(_ code: UInt32) -> String {
        let special: [Int: String] = [kVK_Space: "Space", kVK_Return: "\u{21A9}", kVK_Tab: "\u{21E5}", kVK_Delete: "\u{232B}",
                                      kVK_LeftArrow: "\u{2190}", kVK_RightArrow: "\u{2192}", kVK_UpArrow: "\u{2191}", kVK_DownArrow: "\u{2193}",
                                      kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
                                      kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12"]
        if let s = special[Int(code)] { return s }
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return "?" }
        let layout = unsafeBitCast(raw, to: CFData.self)
        var dead: UInt32 = 0, length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let status = CFDataGetBytePtr(layout).withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) {
            UCKeyTranslate($0, UInt16(code), UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &dead, 4, &length, &chars)
        }
        return status == noErr && length > 0 ? String(utf16CodeUnits: chars, count: length).uppercased() : "?"
    }
}

/// One system-wide hot key (no Accessibility permission needed).
final class HotKey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void
    private static var actions: [UInt32: () -> Void] = [:]
    private static var nextID: UInt32 = 1
    private var id: UInt32 = 0

    init(action: @escaping () -> Void) { self.action = action }

    /// Returns false when another app already owns the shortcut.
    @discardableResult
    func register(_ shortcut: Shortcut?) -> Bool {
        unregister()
        guard let shortcut else { return true }
        id = HotKey.nextID
        HotKey.nextID += 1
        HotKey.actions[id] = action
        if handler == nil {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
                var hk = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
                let id = hk.id
                DispatchQueue.main.async { MainActor.assumeIsolated { HotKey.actions[id]?() } }
                return noErr
            }, 1, &spec, nil, &handler)
        }
        let hotKeyID = EventHotKeyID(signature: OSType(0x504C4C54), id: id) // "PLLT"
        return RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref) == noErr
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
        HotKey.actions[id] = nil
    }
}
