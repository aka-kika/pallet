import SwiftUI
import UniformTypeIdentifiers

/// The big strip of the selected palette. Click a color to make it the main
/// color; click its hex chip to copy it.
struct SwatchStrip: View {
    let palette: Palette
    let onMain: (Int) -> Void
    let onCopy: (String) -> Void
    @Environment(\.theme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var hovered: Int?

    private func weight(_ i: Int) -> Double {
        let main = i == palette.main
        if hovered == i { return main ? 1.7 : 1.55 }
        return main ? 1.35 : 1
    }

    var body: some View {
        GeometryReader { geo in
            let total = palette.colors.indices.reduce(0) { $0 + weight($1) }
            HStack(spacing: 0) {
                ForEach(Array(palette.colors.enumerated()), id: \.offset) { i, color in
                    let ink = Color(hex: ColorMath.ink(color))
                    ZStack(alignment: .bottomLeading) {
                        Rectangle().fill(Color(hex: color))
                            .contentShape(.rect)
                            .onTapGesture { onMain(i) }
                            .accessibilityLabel(i == palette.main ? "\(color), main color" : "Make \(color) the main color")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction { onMain(i) }
                        // Full label when it fits, then a tighter one, then only the dot:
                        // never a wrapped hex code.
                        ViewThatFits(in: .horizontal) {
                            chip(color, main: i == palette.main, ink: ink, tracking: 1.5, padding: 9)
                            chip(color, main: i == palette.main, ink: ink, tracking: 0, padding: 6)
                            chip(nil, main: i == palette.main, ink: ink, tracking: 0, padding: 6)
                        }
                        .padding(12)
                        .offset(y: hovered == i ? -3 : 0)
                    }
                    .frame(width: geo.size.width * weight(i) / total)
                    .onHover { hovered = $0 ? i : (hovered == i ? nil : hovered) }
                    .accessibilityElement(children: .contain)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: hovered)
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: palette.main)
        }
        .clipShape(.rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.text.opacity(contrast == .increased ? 0.4 : 0.06)))
    }

    @ViewBuilder
    private func chip(_ label: String?, main: Bool, ink: Color, tracking: CGFloat, padding: CGFloat) -> some View {
        if label != nil || main {
            Button { if let label { onCopy(label) } } label: {
                HStack(spacing: 6) {
                    if main { Circle().fill(ink).frame(width: 8, height: 8) }
                    if let label { Text(label).font(.system(size: 11, weight: .medium, design: .monospaced)).tracking(tracking).lineLimit(1).fixedSize() }
                }
                .padding(.horizontal, padding).padding(.vertical, 5)
                .background(ink.opacity(0.14), in: .rect(cornerRadius: 7))
                .foregroundStyle(ink)
            }
            .buttonStyle(.plain)
            .help(label.map { "Copy \($0)" } ?? "")
            .fixedSize()
        }
    }
}

/// Previous / next main color around the palette caption.
struct RotationRow: View {
    let palette: Palette
    let dark: Bool
    let rotate: (Int) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            ThemeIconButton(systemName: "arrow.left", filled: true, help: "Previous main color", size: 34) { rotate(-1) }
            Spacer(minLength: 14)
            HStack(spacing: 10) {
                Text(palette.name).font(.system(size: 13, weight: .medium)).tracking(1).foregroundStyle(theme.textSoft)
                Dot()
                Text("\(palette.colors.count) COLORS").caption(theme)
                Dot()
                Text(dark ? "SOFT DARK" : "LIGHT").caption(theme)
            }
            .lineLimit(1)
            Spacer(minLength: 14)
            ThemeIconButton(systemName: "arrow.right", filled: true, help: "Next main color", size: 34) { rotate(1) }
        }
    }

    private struct Dot: View {
        @Environment(\.theme) private var theme
        var body: some View { Circle().fill(theme.textDim).frame(width: 3, height: 3) }
    }
}

private extension Text {
    func caption(_ theme: Theme) -> some View {
        font(.system(size: 11, weight: .regular)).tracking(1.8).foregroundStyle(theme.textDim)
    }
}

/// Square icon button in theme colors: a soft main-color wash at rest when
/// filled, the wash on hover otherwise (docs/THEME-RULES.md).
struct ThemeIconButton: View {
    let systemName: String
    var filled = false
    var help = ""
    var size: CGFloat = 42
    var tint: Color?
    let action: () -> Void
    @Environment(\.theme) private var theme
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .regular))
                .frame(width: size, height: size)
                .foregroundStyle(tint ?? (filled || hover ? theme.link : theme.icon))
                .background(filled ? (hover ? theme.hover : theme.wash) : (hover ? theme.wash : .clear), in: .rect(cornerRadius: 9))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help(help)
        .accessibilityLabel(help)
    }
}

struct PaletteCard: View {
    let palette: Palette
    let selected: Bool
    let select: () -> Void
    let favorite: () -> Void
    @Environment(\.theme) private var theme
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var hover = false
    @State private var heartHover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: select) {
                HStack(spacing: 0) {
                    ForEach(Array(palette.colors.enumerated()), id: \.offset) { _, c in Rectangle().fill(Color(hex: c)) }
                }
                .aspectRatio(2.3, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(theme.text.opacity(contrast == .increased ? 0.4 : 0.08)))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                            .frame(width: 20, height: 20)
                            .background(theme.highlight, in: .circle)
                            .foregroundStyle(theme.onHighlight)
                            .padding(7)
                    }
                }
                .padding(4)
                .overlay {
                    if selected || hover {
                        RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? theme.focus : theme.link, lineWidth: 2)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .onHover { hover = $0 }
            .accessibilityLabel(palette.name)
            .accessibilityValue("\(palette.colors.count) colors")
            .accessibilityAddTraits(selected ? .isSelected : [])

            HStack {
                Text(palette.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selected ? theme.textSoft : theme.textDim)
                    .lineLimit(1)
                    .onTapGesture(perform: select)
                Spacer()
                Button(action: favorite) {
                    Image(systemName: palette.favorite ? "heart.fill" : "heart")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.favorite || heartHover ? theme.highlightInk : theme.icon)
                        .frame(width: 28, height: 28)
                        .background(heartHover ? theme.wash : .clear, in: .rect(cornerRadius: 8))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .onHover { heartHover = $0 }
                .help(palette.favorite ? "Remove favorite" : "Favorite")
                .accessibilityLabel("\(palette.favorite ? "Unfavorite" : "Favorite") \(palette.name)")
            }
            .padding(.horizontal, 4)
            .frame(minHeight: 36)
        }
    }
}

struct ToastView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        if let toast = model.toast {
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.message).font(.system(size: 13, weight: .medium))
                if let detail = toast.detail { Text(detail).font(.system(size: 12)).foregroundStyle(theme.muted) }
            }
            .padding(.horizontal, 16).padding(.vertical, 11)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id(toast.id)
        }
    }
}

struct DropOverlay: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.badge.plus").font(.system(size: 42, weight: .light)).foregroundStyle(theme.highlightInk)
            Text("Drop to extract a palette").font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surface.opacity(0.94), in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(theme.accent, style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
        .padding(12)
        .allowsHitTesting(false)
    }
}
