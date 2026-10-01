import SwiftUI

/// A named group of palettes. A palette can be in several collections.
nonisolated struct PaletteCollection: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var paletteIDs: [String]

    static func newID() -> String { "collection-" + UUID().uuidString.lowercased() }
}

/// The color slider: a grey ramp on the left, then the hue circle, measured in
/// OKLCH so equal steps look equally different (same idea as Iconzzz).
nonisolated enum ColorFilter {
    static let neutralShare = 0.12

    static func isNeutral(_ position: Double) -> Bool { position < neutralShare }
    static func lightness(at position: Double) -> Double { 0.15 + position / neutralShare * 0.8 }
    static func hue(at position: Double) -> Double { (position - neutralShare) / (1 - neutralShare) * 360 }

    /// The color shown at a slider position, also the knob color.
    static func color(at position: Double) -> Color {
        isNeutral(position) ? oklch(lightness(at: position), 0, 0) : oklch(0.72, 0.13, hue(at: position))
    }

    @MainActor private static var lchMemo: [String: (l: Double, c: Double, h: Double)] = [:]

    /// Above zero means the palette has a color near this position; higher is closer.
    @MainActor static func score(_ p: Palette, at position: Double) -> Double {
        let lch = p.colors.map { hex in
            if let v = lchMemo[hex] { return v }
            let v = toOKLCH(hex)
            lchMemo[hex] = v
            return v
        }
        if isNeutral(position) {
            let target = lightness(at: position)
            return lch.filter { $0.c < 0.04 }.map { max(0, 1 - abs($0.l - target) / 0.2) }.max() ?? 0
        }
        let target = hue(at: position)
        return lch.filter { $0.c >= 0.04 }.map { c -> Double in
            let d = abs((c.h - target + 540).truncatingRemainder(dividingBy: 360) - 180)
            return d <= 30 ? (1 - d / 30) * min(1, c.c / 0.12) : 0
        }.max() ?? 0
    }

    static func toOKLCH(_ hex: String) -> (l: Double, c: Double, h: Double) {
        let lin = ColorMath.rgb(hex).map { v -> Double in
            let s = v / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        let l = cbrt(0.4122214708 * lin[0] + 0.5363325363 * lin[1] + 0.0514459929 * lin[2])
        let m = cbrt(0.2119034982 * lin[0] + 0.6806995451 * lin[1] + 0.1073969566 * lin[2])
        let s = cbrt(0.0883024619 * lin[0] + 0.2817188376 * lin[1] + 0.6299787005 * lin[2])
        let L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        let a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        let b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        var h = atan2(b, a) * 180 / .pi
        if h < 0 { h += 360 }
        return (L, sqrt(a * a + b * b), h)
    }

    static func oklch(_ L: Double, _ C: Double, _ h: Double) -> Color {
        let a = C * cos(h * .pi / 180), b = C * sin(h * .pi / 180)
        let l = pow(L + 0.3963377774 * a + 0.2158037573 * b, 3)
        let m = pow(L - 0.1055613458 * a - 0.0638541728 * b, 3)
        let s = pow(L - 0.0894841775 * a - 1.2914855480 * b, 3)
        let rgb = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                   -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                   -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s].map { v -> Double in
            let c = max(0, min(1, v))
            return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055
        }
        return Color(.sRGB, red: rgb[0], green: rgb[1], blue: rgb[2])
    }

    /// Grey ramp, a hairline gap, then the hue circle.
    static let track: LinearGradient = {
        var stops: [Gradient.Stop] = [
            .init(color: oklch(0.15, 0, 0), location: 0),
            .init(color: oklch(0.95, 0, 0), location: neutralShare - 0.012),
            .init(color: .clear, location: neutralShare - 0.011),
            .init(color: .clear, location: neutralShare - 0.001),
        ]
        for h in stride(from: 0.0, through: 360, by: 15) {
            stops.append(.init(color: oklch(0.72, 0.13, h), location: neutralShare + (1 - neutralShare) * h / 360))
        }
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
    }()
}
