import SwiftUI

// A line-by-line port of lib/palettes.ts, so the web app and the Mac app give
// every palette the same theme. Rules: docs/THEME-RULES.md. Colors travel as
// "#RRGGBB" strings like on the web; SwiftUI colors are made at the edge.
nonisolated enum ColorMath {
    static func rgb(_ h: String) -> [Double] {
        let s = Array(h.uppercased())
        return [1, 3, 5].map { i in Double(Int(String(s[i..<i + 2]), radix: 16) ?? 0) }
    }

    static func hex(_ c: [Double]) -> String {
        "#" + c.map { String(format: "%02X", Int(max(0, min(255, $0)).rounded(.toNearestOrAwayFromZero))) }.joined()
    }

    static func mix(_ a: String, _ b: String, _ t: Double) -> String {
        let x = rgb(a), y = rgb(b)
        return hex(zip(x, y).map { $0 + ($1 - $0) * t })
    }

    static func luminance(_ h: String) -> Double {
        let w = [0.2126, 0.7152, 0.0722]
        return rgb(h).enumerated().reduce(0) { v, e in
            let s = e.element / 255
            return v + (s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)) * w[e.offset]
        }
    }

    static func contrast(_ a: String, _ b: String) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    static func chroma(_ c: String) -> Double {
        let ch = rgb(c)
        return (ch.max()! - ch.min()!) / 255
    }

    /// Black-ish or white text for a background.
    static func ink(_ bg: String) -> String {
        let dark = contrast(bg, "#111318"), light = contrast(bg, "#FFFFFF")
        return max(dark, light) < 4.5 ? "#000000" : dark > light ? "#111318" : "#FFFFFF"
    }

    static func readable(_ color: String, _ bg: String, _ ratio: Double = 4.5) -> String {
        let target = ink(bg)
        var c = color
        var n = 0
        while n < 100 && contrast(c, bg) < ratio { c = mix(c, target, 0.06); n += 1 }
        return c
    }

    /// Push a foreground until it reads on every background it can sit on.
    static func legible(_ color: String, _ bgs: [String], _ ratio: Double = 4.5) -> String {
        var c = color
        for _ in 0..<10 {
            guard let bad = bgs.first(where: { contrast(c, $0) < ratio }) else { return c }
            let next = readable(c, bad, ratio)
            if next == c { break }
            c = next
        }
        // Still short: fall back to whichever of black or white reads best.
        func worst(_ x: String) -> Double { bgs.map { contrast(x, $0) }.min() ?? 0 }
        return [c, "#000000", "#FFFFFF"].reduce(c) { worst($1) > worst($0) ? $1 : $0 }
    }

    static func parseHex(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard t.allSatisfy(\.isHexDigit) else { return nil }
        if t.count == 6 { return "#" + t.uppercased() }
        if t.count == 3 { return "#" + t.map { "\($0)\($0)" }.joined().uppercased() }
        return nil
    }
}

/// Theme roles in the same order as the web export.
nonisolated struct Theme: Equatable, Sendable {
    var roles: [(String, String)]

    static func == (a: Theme, b: Theme) -> Bool { a.roles.elementsEqual(b.roles) { $0 == $1 } }

    subscript(_ key: String) -> String {
        get { roles.first { $0.0 == key }?.1 ?? "#FF00FF" }
        set {
            if let i = roles.firstIndex(where: { $0.0 == key }) { roles[i].1 = newValue } else { roles.append((key, newValue)) }
        }
    }

    func color(_ key: String) -> Color { Color(hex: self[key]) }

    var background: Color { color("background") }
    var surface: Color { color("surface") }
    var raised: Color { color("raised") }
    var wash: Color { color("wash") }
    var hover: Color { color("hover") }
    var text: Color { color("text") }
    var muted: Color { color("muted") }
    var border: Color { color("border") }
    var textSoft: Color { color("text-soft") }
    var textDim: Color { color("text-dim") }
    var uiDim: Color { color("ui-dim") }
    var icon: Color { color("icon") }
    var link: Color { color("link") }
    var focus: Color { color("focus") }
    var accent: Color { color("accent") }
    var onAccent: Color { color("on-accent") }
    var highlight: Color { color("highlight") }
    var onHighlight: Color { color("on-highlight") }
    var highlightInk: Color { color("highlight-ink") }
    var danger: Color { color("danger") }

    // Every role that sits on the page surfaces. The main color (accent) tints the
    // washes, hover, borders and icons; the companion (highlight) marks "on" states.
    private static func roles(bg: String, surface: String, raised: String, ink0: String, accent: String, highlight: String, dark: Bool) -> [(String, String)] {
        typealias M = ColorMath
        // Washes take the accent's hue but stay close to the background in lightness.
        func tint(_ t0: Double, _ limit: Double) -> String {
            var t = t0, c = M.mix(bg, accent, t)
            var n = 0
            while n < 20 && M.contrast(c, bg) > limit { t *= 0.85; c = M.mix(bg, accent, t); n += 1 }
            return c
        }
        let wash = tint(dark ? 0.22 : 0.16, 1.25), hover = tint(dark ? 0.32 : 0.26, 1.45)
        let surfaces = [bg, surface, raised, wash, hover]
        let text = M.legible(M.readable(ink0, bg, 10), surfaces)
        let muted = M.legible(M.readable(M.mix(text, bg, 0.35), bg, 4.6), surfaces)
        let soft = M.legible(M.mix(bg, text, 0.68), surfaces), dim = M.legible(M.mix(bg, text, 0.46), surfaces)
        let uidim = M.legible(M.mix(bg, text, 0.46), surfaces, 3)
        let link = M.legible(M.readable(accent, bg), surfaces)
        let selection = M.mix(bg, highlight, dark ? 0.30 : 0.20)
        return [
            ("background", bg), ("surface", surface), ("raised", raised), ("wash", wash), ("hover", hover),
            ("text", text), ("muted", muted), ("border", M.mix(bg, M.mix(text, accent, 0.45), 0.18)),
            ("text-soft", soft), ("text-dim", dim), ("ui-dim", uidim),
            ("icon", M.legible(M.mix(uidim, link, 0.55), surfaces, 3)),
            ("highlight-ink", M.legible(M.readable(highlight, bg), surfaces)), ("link", link),
            ("focus", M.legible(M.readable(highlight, bg, 3), surfaces, 3)),
            ("selection", selection), ("on-selection", M.legible(M.readable(text, selection), [selection])),
            ("success", M.legible(M.readable(dark ? "#86C89D" : "#367749", bg), surfaces)),
            ("warning", M.legible(M.readable(dark ? "#EAC16B" : "#8D641D", bg), surfaces)),
            ("danger", M.legible(M.readable(dark ? "#F58A93" : "#B03448", bg), surfaces)),
        ]
    }

    init(roles: [(String, String)]) { self.roles = roles }

    init(_ p: Palette, dark: Bool) {
        typealias M = ColorMath
        let main = p.colors.indices.contains(p.main) ? p.colors[p.main] : p.colors[0]
        let mainRGB = M.rgb(main)
        // Keep the selected color as the foundation and give a distinct companion
        // the small, high-visibility actions. Neutral palettes remain neutral.
        func score(_ c: String) -> Double {
            M.chroma(c) * 2 + sqrt(zip(M.rgb(c), mainRGB).reduce(0) { $0 + pow($1.0 - $1.1, 2) }) / 442
        }
        let companions = p.colors.enumerated().filter { $0.offset != p.main }.map(\.element)
            .enumerated().sorted { a, b in
                let sa = score(a.element), sb = score(b.element)
                return sa != sb ? sa > sb : a.offset < b.offset
            }.map(\.element)
        let highlight = companions.first ?? main
        let n = Double(p.colors.count)
        let companionWash = M.hex(p.colors.reduce([0.0, 0, 0]) { sum, c in zip(sum, M.rgb(c)).map { $0 + $1 / n } })
        let sorted = p.colors.enumerated().sorted { a, b in
            let la = M.luminance(a.element), lb = M.luminance(b.element)
            return la != lb ? la < lb : a.offset < b.offset
        }.map(\.element)
        // Muted mains tint the page more, loud ones less, so neon stays calm.
        let tint = (dark ? 0.18 : 0.14) * (1 - 0.5 * M.chroma(main))
        let base = dark ? M.mix(M.mix(sorted[0], "#16181D", 0.55), main, tint) : M.mix(M.mix(sorted.last!, "#F8FAFC", 0.8), main, tint)
        var bg = dark ? (M.luminance(base) > 0.07 ? M.mix(base, "#15171B", 0.65) : base) : base
        // Light mode stays light even when every palette color is dark.
        var i = 0
        while i < 20 && !dark && M.luminance(bg) < 0.72 { bg = M.mix(bg, "#F8FAFC", 0.2); i += 1 }
        // The page is a quiet backdrop: cap how colorful it can get.
        i = 0
        while i < 20 && M.chroma(bg) > 0.07 {
            let g = M.rgb(bg).reduce(0, +) / 3
            bg = M.mix(bg, M.hex([g, g, g]), 0.15); i += 1
        }
        let surface = M.mix(M.mix(bg, "#FFFFFF", dark ? 0.045 : 0.45), companionWash, 0.025)
        let raised = M.mix(M.mix(bg, dark ? "#FFFFFF" : main, dark ? 0.085 : 0.09), companionWash, 0.04)
        let accent = main
        let onAccent = M.legible(M.ink(accent), [accent])
        roles = Theme.roles(bg: bg, surface: surface, raised: raised, ink0: dark ? "#F5F5F7" : sorted[0], accent: accent, highlight: highlight, dark: dark) + [
            ("accent", accent), ("on-accent", onAccent), ("accent-hover", M.mix(accent, M.ink(accent), 0.08)),
            ("highlight", highlight), ("on-highlight", M.legible(M.ink(highlight), [highlight])),
            ("highlight-hover", M.mix(highlight, M.ink(highlight), 0.06)),
        ]
    }

    /// Keep a chosen background; everything else still follows the palette.
    func locked(to lock: String?, dark: Bool) -> Theme {
        guard let bg = lock else { return self }
        typealias M = ColorMath
        let surface = M.mix(M.mix(bg, "#FFFFFF", dark ? 0.045 : 0.45), self["highlight"], 0.025)
        let raised = M.mix(M.mix(bg, dark ? "#FFFFFF" : self["accent"], dark ? 0.085 : 0.09), self["highlight"], 0.04)
        var t = self
        for (k, v) in Theme.roles(bg: bg, surface: surface, raised: raised, ink0: dark ? "#F5F5F7" : "#111318", accent: self["accent"], highlight: self["highlight"], dark: dark) {
            t[k] = v
        }
        return t
    }
}

extension Color {
    nonisolated init(hex: String) {
        let c = ColorMath.rgb(hex)
        self.init(.sRGB, red: c[0] / 255, green: c[1] / 255, blue: c[2] / 255)
    }
}

// Same text exports as the web app.
nonisolated enum ThemeExport {
    static func css(_ p: Palette) -> String {
        func block(_ dark: Bool) -> String { Theme(p, dark: dark).roles.map { "  --\($0.0): \($0.1);" }.joined(separator: "\n") }
        return """
        /* \(p.name.replacingOccurrences(of: "*/", with: "")) · primary \(p.colors[p.main]) */
        :root, [data-theme="light"] {
          color-scheme: light;
        \(block(false))
        }

        @media (prefers-color-scheme: dark) {
          :root:not([data-theme="light"]) {
            color-scheme: dark;
        \(block(true))
          }
        }

        [data-theme="dark"] {
          color-scheme: dark;
        \(block(true))
        }

        """
    }

    static func markdown(_ p: Palette) -> String {
        let l = Theme(p, dark: false), d = Theme(p, dark: true)
        let rows = l.roles.map { "| \($0.0) | \($0.1) | \(d[$0.0]) |" }.joined(separator: "\n")
        return """
        # \(p.name)

        Source: \(p.source)

        Original palette: \(p.colors.joined(separator: ", "))

        Main color: \(p.colors[p.main])

        ## Light and soft dark

        UI shades are derived from the original palette. Text pairs are contrast-adjusted.

        | Role | Light | Dark |
        | --- | --- | --- |
        \(rows)

        ## CSS

        ```css
        \(css(p))```

        """
    }

    static func object(_ p: Palette) -> [String: Any] {
        func dict(_ t: Theme) -> [String: String] { Dictionary(uniqueKeysWithValues: t.roles) }
        return ["id": p.id, "name": p.name, "colors": p.colors, "main": p.main, "favorite": p.favorite, "source": p.source,
                "light": dict(Theme(p, dark: false)), "dark": dict(Theme(p, dark: true))]
    }

    static func json(_ value: Any) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return (String(data: data, encoding: .utf8) ?? "{}") + "\n"
    }

    static func json(_ p: Palette) -> String { json(object(p)) }

    static func collection(_ list: [Palette]) -> String { json(["version": 1, "palettes": list.map(object)] as [String: Any]) }
}
