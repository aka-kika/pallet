import SwiftUI
import UniformTypeIdentifiers

/// PALLET / by KIKA. The mark and "by KIKA" recolor with the palette.
struct Brand: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("PalettMark").resizable().frame(width: 24, height: 24).foregroundStyle(theme.highlightInk)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("PALLET").tracking(1.6).foregroundStyle(theme.uiDim)
                Text("/ by KIKA").tracking(0.8).fontWeight(.medium).foregroundStyle(theme.highlightInk)
            }
            .font(.system(size: 19, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .fixedSize()
    }
}

/// The big strip of the selected palette. Click a color to make it the main
/// color; click its hex chip to copy it.
struct SwatchStrip: View {
    let palette: Palette
    let onMain: (Int) -> Void
    let onCopy: (String) -> Void
    @Environment(\.theme) private var theme
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
                        Button { onCopy(color) } label: {
                            HStack(spacing: 8) {
                                if i == palette.main { Circle().fill(ink).frame(width: 9, height: 9) }
                                Text(color).font(.system(size: 11, weight: .medium, design: .monospaced)).tracking(1.5)
                            }
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(ink.opacity(0.14), in: .rect(cornerRadius: 7))
                            .foregroundStyle(ink)
                        }
                        .buttonStyle(.plain)
                        .help("Copy \(color)")
                        .padding(18)
                        .offset(y: hovered == i ? -3 : 0)
                    }
                    .frame(width: geo.size.width * weight(i) / total)
                    .onHover { hovered = $0 ? i : (hovered == i ? nil : hovered) }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Make \(color) primary")
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: hovered)
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: palette.main)
        }
        .clipShape(.rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.text.opacity(0.06)))
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
            ThemeIconButton(systemName: "arrow.left", filled: true, help: "Previous main color") { rotate(-1) }
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
            ThemeIconButton(systemName: "arrow.right", filled: true, help: "Next main color") { rotate(1) }
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
    @State private var hover = false
    @State private var heartHover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: select) {
                HStack(spacing: 0) {
                    ForEach(Array(palette.colors.enumerated()), id: \.offset) { _, c in Rectangle().fill(Color(hex: c)) }
                }
                .frame(height: 100)
                .clipShape(.rect(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(theme.text.opacity(0.08)))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                            .frame(width: 24, height: 24)
                            .background(theme.highlight, in: .circle)
                            .foregroundStyle(theme.onHighlight)
                            .padding(9)
                    }
                }
                .padding(4)
                .overlay {
                    if selected || hover {
                        RoundedRectangle(cornerRadius: 15).strokeBorder(selected ? theme.focus : theme.link, lineWidth: 2)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .onHover { hover = $0 }
            .accessibilityLabel("Select \(palette.name)")
            .accessibilityAddTraits(selected ? .isSelected : [])

            HStack {
                Text(palette.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(selected ? theme.textSoft : theme.textDim)
                    .lineLimit(1)
                    .onTapGesture(perform: select)
                Spacer()
                Button(action: favorite) {
                    Image(systemName: palette.favorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.favorite || heartHover ? theme.highlightInk : theme.icon)
                        .frame(width: 32, height: 32)
                        .background(heartHover ? theme.wash : .clear, in: .rect(cornerRadius: 8))
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .onHover { heartHover = $0 }
                .help(palette.favorite ? "Remove favorite" : "Favorite")
                .accessibilityLabel("\(palette.favorite ? "Unfavorite" : "Favorite") \(palette.name)")
            }
            .padding(.horizontal, 4)
            .frame(minHeight: 45)
        }
    }
}

struct EmptyFavorites: View {
    let showAll: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart").font(.system(size: 22)).foregroundStyle(theme.muted)
            Text("No favorites yet").font(.headline)
            Text("Tap a heart or right-click any palette to keep it here.").font(.callout).foregroundStyle(theme.muted)
            Button("View collection", action: showAll).buttonStyle(.theme).padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
    }
}

/// Export or import the whole collection as JSON (same file as the web app).
struct CollectionTools: View {
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 20) {
            Text("Drop or paste an image anywhere. Right-click a card for more.")
                .font(.system(size: 12)).foregroundStyle(theme.muted)
            Spacer()
            Button("Export collection", action: exportAll)
            Button("Import collection", action: importAll)
        }
        .buttonStyle(.plain)
        .font(.system(size: 13))
        .foregroundStyle(theme.link)
    }

    private func exportAll() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "palette-collection.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let text = ThemeExport.collection(store.palettes)
        do { try text.write(to: url, atomically: true, encoding: .utf8); model.show("Collection exported") } catch { model.show("Could not export the collection.") }
    }

    private func importAll() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        struct File: Decodable { var palettes: [Palette] }
        do {
            let data = try Data(contentsOf: url)
            guard data.count < 2_000_000 else { throw CocoaError(.fileReadTooLarge) }
            let list = try JSONDecoder().decode(File.self, from: data).palettes
            guard list.count <= 1000, list.allSatisfy(\.isValid) else { throw CocoaError(.fileReadCorruptFile) }
            list.forEach(store.put)
            model.show("\(list.count) palettes imported")
        } catch {
            model.show("Choose a valid Palette collection JSON file.")
        }
    }
}

struct KeyboardBar: View {
    let count: Int
    let dark: Bool
    let shuffle: () -> Void
    @Environment(\.theme) private var theme
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 28) {
            Button(action: shuffle) {
                HStack(spacing: 10) { Key("Space", strong: true); Text("Shuffle") }
            }
            .buttonStyle(.plain)
            hint(["⌘C"], "Copy CSS")
            hint(["L"], "Lock")
            hint(["↑", "↓"], "Navigate")
            hint(["←", "→"], "Rotate color")
            Spacer()
            Text("\(count)").monospacedDigit().tracking(1.2)
            HStack(spacing: 6) {
                if model.appearance == .system { Image(systemName: "desktopcomputer").font(.system(size: 11)) }
                Text(dark ? "Soft dark" : "Light")
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(theme.muted)
        .padding(.horizontal, 32)
        .frame(height: 56)
        .background(theme.background)
        .overlay(alignment: .top) { Rectangle().fill(theme.border).frame(height: 1).padding(.horizontal, 32) }
    }

    private func hint(_ keys: [String], _ label: String) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) { ForEach(keys, id: \.self) { Key($0) } }
            Text(label)
        }
    }

    private struct Key: View {
        let label: String
        var strong = false
        @Environment(\.theme) private var theme
        init(_ label: String, strong: Bool = false) { self.label = label; self.strong = strong }
        var body: some View {
            Text(label).font(.system(size: 12))
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(strong ? theme.highlight : theme.wash, in: .rect(cornerRadius: 6))
                .foregroundStyle(strong ? theme.onHighlight : theme.text)
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
            .padding(.bottom, model.hideKeyboardGuide ? 24 : 76)
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

/// Buttons in theme colors: prominent = main color fill with its readable ink,
/// plain = text on a bordered surface with the wash on hover.
struct ThemeButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var enabled
    @State private var hover = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .frame(minHeight: 30)
            .foregroundStyle(prominent ? theme.onAccent : theme.text)
            .background(prominent ? (hover ? theme.color("accent-hover") : theme.accent) : (hover ? theme.wash : .clear), in: .rect(cornerRadius: 8))
            .overlay { if !prominent { RoundedRectangle(cornerRadius: 8).strokeBorder(theme.border) } }
            .opacity(enabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .contentShape(.rect)
            .onHover { hover = $0 && enabled }
    }
}

extension ButtonStyle where Self == ThemeButtonStyle {
    static var theme: ThemeButtonStyle { ThemeButtonStyle() }
    static var themeProminent: ThemeButtonStyle { ThemeButtonStyle(prominent: true) }
}
