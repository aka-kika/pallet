import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Palette names: a title read from the image wins, then a real file name,
/// then Apple Intelligence, then plain color words (port of lib/name.ts).
nonisolated enum Naming {
    static func name(for result: ExtractionResult, fileName: String?) async -> String {
        if let title = result.name?.trimmingCharacters(in: .whitespaces), !title.isEmpty { return String(title.prefix(100)) }
        if let file = fileName.map(clean), !isGeneric(file) { return String(file.prefix(100)) }
        if let suggested = await suggest(result.colors) { return suggested }
        return fromColors(result.colors)
    }

    static func clean(_ s: String) -> String {
        s.replacingOccurrences(of: "[-_]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    static func isGeneric(_ n: String) -> Bool {
        n.isEmpty
            || n.range(of: #"^(clipboard|image|img|dsc|screenshot|screen shot|paste|untitled|quick capture|palette)\b"#, options: [.regularExpression, .caseInsensitive]) != nil
            || n.range(of: #"^\d{4}.\d{2}.\d{2}"#, options: .regularExpression) != nil
    }

    /// On-device model, when Apple Intelligence is on. Nil otherwise.
    static func suggest(_ colors: [String]) async -> String? {
        #if canImport(FoundationModels)
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        do {
            let described = colors.map { "\($0) (\(word($0)))" }.joined(separator: ", ")
            let session = LanguageModelSession(instructions: "You name color palettes for designers. Answer with the name only: 2 or 3 evocative words in Title Case, like Desert Dusk, Harbor Mist or Neon Orchard. Use an ampersand, never the word And. No quotes, no color codes.")
            let response = try await session.respond(to: "Palette colors: \(described)")
            let name = response.content.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\"'.")))
            return name.isEmpty || name.count > 60 ? nil : name
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    private static let hues: [(Double, String)] = [(15, "Coral"), (40, "Orange"), (55, "Gold"), (75, "Lime"), (150, "Green"), (175, "Teal"), (200, "Cyan"), (230, "Blue"), (255, "Indigo"), (280, "Violet"), (320, "Magenta"), (345, "Rose"), (361, "Coral")]

    static func word(_ hex: String) -> String {
        let c = ColorMath.rgb(hex), r = c[0], g = c[1], b = c[2]
        let mx = c.max()!, mn = c.min()!
        let l = (mx + mn) / 510, s = mx == mn ? 0 : (mx - mn) / (255 * (1 - abs(2 * l - 1)))
        if s < 0.12 { return l > 0.92 ? "Snow" : l > 0.78 ? "Ivory" : l > 0.55 ? "Silver" : l > 0.32 ? "Slate" : l > 0.14 ? "Charcoal" : "Ink" }
        var h = atan2(sqrt(3) * (g - b), 2 * r - g - b) * 180 / .pi
        if h < 0 { h += 360 }
        let hue = hues.first { h < $0.0 }?.1 ?? "Blue"
        if l < 0.18 { return ["Coral", "Rose"].contains(hue) ? "Wine" : hue == "Orange" ? "Umber" : hue == "Gold" ? "Bronze" : ["Blue", "Indigo"].contains(hue) ? "Navy" : "Ink" }
        if l > 0.82 { return ["Gold", "Orange"].contains(hue) ? "Cream" : ["Coral", "Rose"].contains(hue) ? "Blush" : "Mist" }
        return hue
    }

    static func fromColors(_ colors: [String]) -> String {
        var words: [String] = []
        for c in colors {
            let w = word(c)
            if !words.contains(w) { words.append(w) }
            if words.count == 3 { break }
        }
        switch words.count {
        case 0: return "New palette"
        case 1: return words[0] + " Study"
        case 2: return words[0] + " & " + words[1]
        default: return words[0] + ", " + words[1] + " & " + words[2]
        }
    }
}
