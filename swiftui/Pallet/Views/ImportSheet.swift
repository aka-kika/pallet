import SwiftUI
import UniformTypeIdentifiers

/// Add image: drop, paste or choose an image, check the colors found, name it, save.
struct ImportSheet: View {
    let request: ImportRequest
    let onSave: (Palette) -> Void
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var image: NSImage?
    @State private var fileName: String?
    @State private var colors: [String] = []
    @State private var name = ""
    @State private var kind: ExtractionResult.Kind?
    @State private var working = false
    @State private var error: String?
    @State private var over = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add image").font(.title2.weight(.semibold))
            if let image {
                HStack(alignment: .top, spacing: 20) {
                    Image(nsImage: image).resizable().scaledToFit()
                        .frame(width: 170, height: 210)
                        .background(theme.text.opacity(0.05), in: .rect(cornerRadius: 10))
                        .clipShape(.rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 12) {
                        if working {
                            HStack(spacing: 10) { ProgressView().controlSize(.small); Text("Reading the image...").foregroundStyle(theme.muted) }
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                        } else if !colors.isEmpty {
                            Text(kindLabel).font(.callout).foregroundStyle(theme.muted)
                            swatches
                            TextField("Palette name", text: $name).textFieldStyle(.roundedBorder)
                        }
                        if let error { Text(error).font(.callout).foregroundStyle(theme.danger) }
                    }
                }
            } else {
                dropTarget
            }
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction).buttonStyle(.theme)
                Spacer()
                if image != nil { Button("Choose another") { choose() }.buttonStyle(.theme) }
                Button("Save palette") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.themeProminent)
                    .disabled(colors.count < 2 || working || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 600)
        .background(theme.surface)
        .foregroundStyle(theme.text)
        .tint(theme.link)
        .onAppear {
            image = request.image
            fileName = request.fileName
            if image != nil { run() }
        }
        .onPasteCommand(of: [.image, .png, .tiff, .fileURL]) { providers in load(providers) }
    }

    private var kindLabel: String {
        switch kind {
        case .paletteGraphic: "Found \(colors.count) swatches. Frame, text and backdrop skipped."
        case .interface: "Interface colors: background, text and accents."
        case .photo, nil: "Main colors of the photo."
        }
    }

    private var swatches: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
            ForEach(Array(colors.enumerated()), id: \.offset) { i, c in
                let ink = Color(hex: ColorMath.ink(c))
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8).fill(Color(hex: c)).frame(height: 56)
                        .overlay(alignment: .bottomLeading) {
                            Text(c).font(.system(size: 10, design: .monospaced)).foregroundStyle(ink).padding(6)
                        }
                    if colors.count > 2 {
                        Button { colors.remove(at: i) } label: {
                            Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
                                .frame(width: 18, height: 18)
                                .background(ink.opacity(0.16), in: .circle)
                                .foregroundStyle(ink)
                        }
                        .buttonStyle(.plain)
                        .padding(5)
                        .help("Remove \(c)")
                    }
                }
            }
        }
    }

    private var dropTarget: some View {
        Button(action: choose) {
            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus").font(.system(size: 30, weight: .light)).foregroundStyle(theme.highlightInk)
                Text("Drop, paste or choose an image").font(.callout)
                Text("Palette cards, website screenshots and photos all work.").font(.caption).foregroundStyle(theme.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 210)
            .background(over ? theme.wash : theme.background, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(over ? theme.focus : theme.border, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onDrop(of: [.image, .fileURL], isTargeted: $over) { load($0); return true }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) else { return }
        take(img, name: url.deletingPathExtension().lastPathComponent)
    }

    private func load(_ providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, let img = NSImage(contentsOf: url) else { return }
                let base = url.deletingPathExtension().lastPathComponent
                Task { @MainActor in take(img, name: base) }
            }
        } else {
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                guard let img = object as? NSImage else { return }
                Task { @MainActor in take(img, name: nil) }
            }
        }
    }

    private func take(_ img: NSImage, name: String?) {
        image = img
        fileName = name
        run()
    }

    private func run() {
        guard let image else { return }
        working = true
        error = nil
        Task {
            do {
                let result = try await ImportSheet.extract(image)
                colors = result.colors
                kind = result.kind
                name = await Naming.name(for: result, fileName: fileName)
            } catch {
                self.error = error.localizedDescription
                colors = []
            }
            working = false
        }
    }

    private func save() {
        let p = Palette(id: Palette.newID(), name: String(name.trimmingCharacters(in: .whitespaces).prefix(100)), colors: colors, main: 0, favorite: false, source: sourceLabel)
        guard p.isValid else { error = "This palette could not be saved."; return }
        onSave(p)
        dismiss()
    }

    private var sourceLabel: String {
        switch kind {
        case .paletteGraphic: "Palette image · swatches read from the image"
        case .interface: "Screenshot · interface colors"
        case .photo, nil: "Photo · sampled colors"
        }
    }

    static func extract(_ image: NSImage) async throws -> ExtractionResult {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CocoaError(.fileReadCorruptFile, userInfo: [NSLocalizedDescriptionKey: "This image could not be read."])
        }
        return try await Task.detached(priority: .userInitiated) { try await PaletteExtractor.extract(from: cg) }.value
    }

    /// Settings > Add dropped images right away: no dialog.
    static func quickPalette(from image: NSImage, fileName: String?) async throws -> Palette {
        let result = try await extract(image)
        let name = await Naming.name(for: result, fileName: fileName)
        return Palette(id: Palette.newID(), name: name, colors: result.colors, main: 0, favorite: false, source: "Local quick capture · sampled colors")
    }
}

struct ExportSheet: View {
    let palette: Palette
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Export \(palette.name)").font(.title2.weight(.semibold))
            Text("Every theme export includes light and soft-dark modes.").font(.callout).foregroundStyle(theme.muted)
            VStack(spacing: 10) {
                row("CSS variables", "css", UTType(filenameExtension: "css") ?? .plainText) { ThemeExport.css(palette) }
                row("Markdown theme", "md", UTType(filenameExtension: "md") ?? .plainText) { ThemeExport.markdown(palette) }
                row("Palette JSON", "json", .json) { ThemeExport.json(palette) }
            }
            .padding(.top, 4)
            HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.cancelAction).buttonStyle(.theme) }
        }
        .padding(24)
        .frame(width: 420)
        .background(theme.surface)
        .foregroundStyle(theme.text)
    }

    private func row(_ label: String, _ ext: String, _ type: UTType, _ content: @escaping () -> String) -> some View {
        Button {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = palette.name.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression) + "." + ext
            panel.allowedContentTypes = [type]
            if panel.runModal() == .OK, let url = panel.url { try? content().write(to: url, atomically: true, encoding: .utf8) }
        } label: {
            Label(label, systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(.theme)
    }
}
