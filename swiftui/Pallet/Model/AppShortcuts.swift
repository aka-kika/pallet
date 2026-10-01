import SwiftUI

/// Menu commands whose shortcuts can be recorded in Settings > Keyboard.
/// Plain keys in the window (Space, arrows, L) and the standard Edit keys
/// stay fixed.
enum AppCommand: String, CaseIterable, Identifiable {
    case shuffle, previousColor, nextColor, favorite, lock, copyCSS, appearance, newFromImage, newCollection, export

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shuffle: "Shuffle"
        case .previousColor: "Previous main color"
        case .nextColor: "Next main color"
        case .favorite: "Add to Favorites"
        case .lock: "Lock background"
        case .copyCSS: "Copy CSS"
        case .appearance: "Light or soft dark"
        case .newFromImage: "New palette from image"
        case .newCollection: "New collection"
        case .export: "Export theme"
        }
    }

    var standard: KeyCombo {
        switch self {
        case .shuffle: KeyCombo("r")
        case .previousColor: KeyCombo("[")
        case .nextColor: KeyCombo("]")
        case .favorite: KeyCombo("d")
        case .lock: KeyCombo("l")
        case .copyCSS: KeyCombo("c", [.command, .shift])
        case .appearance: KeyCombo("d", [.command, .shift])
        case .newFromImage: KeyCombo("o")
        case .newCollection: KeyCombo("n", [.command, .shift])
        case .export: KeyCombo("e")
        }
    }
}

/// A menu key equivalent: one key plus modifiers.
nonisolated struct KeyCombo: Codable, Equatable, Sendable {
    /// A single character, or a name for special keys ("delete", "left"...).
    var key: String
    var modifiers: Int

    init(_ key: String, _ modifiers: EventModifiers = .command) {
        self.key = key
        self.modifiers = modifiers.rawValue
    }

    private static let special: [String: (KeyEquivalent, String)] = [
        "delete": (.delete, "\u{232B}"), "return": (.return, "\u{21A9}"), "tab": (.tab, "\u{21E5}"), "space": (.space, "Space"),
        "left": (.leftArrow, "\u{2190}"), "right": (.rightArrow, "\u{2192}"), "up": (.upArrow, "\u{2191}"), "down": (.downArrow, "\u{2193}"),
    ]

    var keyEquivalent: KeyEquivalent { KeyCombo.special[key]?.0 ?? KeyEquivalent(Character(key)) }
    var eventModifiers: EventModifiers { EventModifiers(rawValue: modifiers) }

    var display: String {
        let m = eventModifiers
        var s = ""
        if m.contains(.control) { s += "\u{2303}" }
        if m.contains(.option) { s += "\u{2325}" }
        if m.contains(.shift) { s += "\u{21E7}" }
        if m.contains(.command) { s += "\u{2318}" }
        return s + (KeyCombo.special[key]?.1 ?? key.uppercased())
    }

    /// From a key press while recording. Needs Command or Control, so plain
    /// keys stay free for the window (Space, arrows, L).
    init?(event: NSEvent) {
        let f = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard f.contains(.command) || f.contains(.control) else { return nil }
        var m: EventModifiers = []
        if f.contains(.command) { m.insert(.command) }
        if f.contains(.option) { m.insert(.option) }
        if f.contains(.control) { m.insert(.control) }
        if f.contains(.shift) { m.insert(.shift) }
        let names: [UInt16: String] = [51: "delete", 36: "return", 48: "tab", 49: "space", 123: "left", 124: "right", 126: "up", 125: "down"]
        if let name = names[event.keyCode] {
            key = name
        } else if let c = event.characters(byApplyingModifiers: [])?.lowercased().first, !c.isWhitespace {
            // The unshifted key, so Shift-Cmd-1 is stored as "1" with Shift, not "!".
            key = String(c)
        } else {
            return nil
        }
        // Standard keys (Quit, Close, Hide, Edit, Undo, Settings) and Pallet's
        // fixed ones (Cmd-1 to 4, Cmd-Delete) stay theirs.
        let reserved: Set<String> = ["q", "w", "h", "m", "x", "c", "v", "a", "z", ",", "1", "2", "3", "4", "delete"]
        if m == .command && reserved.contains(key) { return nil }
        if m == [.command, .shift] && key == "z" { return nil }   // Redo
        modifiers = m.rawValue
    }
}

extension View {
    /// A menu item's shortcut, or none when it was cleared in Settings.
    @ViewBuilder
    func shortcut(_ combo: KeyCombo?) -> some View {
        if let combo { keyboardShortcut(combo.keyEquivalent, modifiers: combo.eventModifiers) } else { self }
    }
}
