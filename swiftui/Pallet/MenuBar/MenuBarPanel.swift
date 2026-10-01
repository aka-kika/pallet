import SwiftUI
import UniformTypeIdentifiers

/// The panel under the menu bar icon: capture, the colors just found, and the
/// latest palettes one click from their CSS.
struct MenuBarPanel: View {
    let controller: MenuBarController
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model
    @State private var copied: String?
    @State private var dropping = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch controller.phase {
            case .idle: start
            case .working:
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Reading the colors...").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 90)
            case .result(let r): result(r)
            case .needsPermission:
                VStack(alignment: .leading, spacing: 10) {
                    Label("Pallet needs Screen Recording to read colors from the screen.", systemImage: "lock")
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Turn on Pallet in System Settings > Privacy & Security > Screen Recording. macOS applies it after Pallet restarts.")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Open Settings") { controller.openScreenRecordingSettings() }
                        Spacer()
                        Button("Quit & Reopen") { controller.relaunch() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 10) {
                    Label(message, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                    Button("Try Again") { controller.done() }
                }
            }
            if !recent.isEmpty {
                Divider()
                Text("Recent").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(recent) { p in recentRow(p) }
            }
            Divider()
            HStack(spacing: 4) {
                Button("Open Pallet") { controller.openMain() }
                Spacer()
                Button { controller.openSettings(tab: .capture) } label: { Image(systemName: "gearshape") }
                    .help("Settings")
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                    .help("Quit Pallet")
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .frame(width: 300)
        // Drop an image anywhere on the panel, whatever it is showing.
        .onDrop(of: [.fileURL, .image], isTargeted: $dropping) { providers in
            load(providers)
            return true
        }
        .preferredColorScheme(model.colorScheme)
    }

    /// Three ways in: drop or choose an image, capture part of the screen,
    /// or paste.
    private var start: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { controller.chooseImage() } label: {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus").font(.system(size: 22, weight: .light))
                    Text("Drop an image here").font(.callout)
                    Text("or click to choose one").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 104)
                .background(dropping ? AnyShapeStyle(.tint.opacity(0.14)) : AnyShapeStyle(.quaternary.opacity(0.5)), in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(dropping ? AnyShapeStyle(.tint) : AnyShapeStyle(.separator), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            HStack(spacing: 8) {
                Button { controller.captureArea() } label: {
                    Label("Capture Area", systemImage: "viewfinder").frame(maxWidth: .infinity)
                }
                .help(model.captureShortcut.map { "Pick part of the screen (\($0.display), from any app)" } ?? "Pick part of the screen")
                Button { controller.pasteImage() } label: {
                    Label("Paste", systemImage: "doc.on.clipboard").frame(maxWidth: .infinity)
                }
                .keyboardShortcut("v")
                .help("Paste a copied image or image file (\u{2318}V)")
            }
            .controlSize(.large)
        }
    }

    private func load(_ providers: [NSItemProvider]) {
        loadDroppedImage(providers, failed: { controller.phase = .failed("That file is not an image.") }) { image, name in
            controller.take(image, name: name)
        }
    }

    private func result(_ r: MenuBarController.CaptureResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(r.colors.enumerated()), id: \.offset) { i, c in
                    Rectangle().fill(Color(hex: c))
                        .overlay(alignment: .topTrailing) {
                            if r.saved == nil && r.colors.count > 2 {
                                Button { controller.removeColor(at: i) } label: {
                                    Image(systemName: "xmark").font(.system(size: 7, weight: .bold))
                                        .frame(width: 14, height: 14)
                                        .background(Color(hex: ColorMath.ink(c)).opacity(0.16), in: .circle)
                                        .foregroundStyle(Color(hex: ColorMath.ink(c)))
                                }
                                .buttonStyle(.plain)
                                .padding(3)
                                .help("Remove \(c)")
                            }
                        }
                }
            }
            .frame(height: 54)
            .clipShape(.rect(cornerRadius: 8))
            if let saved = r.saved {
                Text(saved.name).font(.headline)
                Label("Saved to your library", systemImage: "checkmark.circle").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Copy CSS") { copy(saved) }
                    Button("Show in Pallet") { model.selectedID = saved.id; controller.openMain() }
                    Spacer()
                    Button("Done") { controller.done() }
                }
            } else {
                TextField("Name", text: Binding(get: { r.name }, set: { controller.rename($0) }))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { controller.save() }
                HStack {
                    Button("Discard") { controller.done() }
                    Spacer()
                    Button("Save") { controller.save() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(r.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    /// Your newest palettes, newest first.
    private var recent: [Palette] {
        Array(store.palettes.filter { !store.isBuiltIn($0.id) }.suffix(4).reversed())
    }

    private func recentRow(_ p: Palette) -> some View {
        Button { copy(p) } label: {
            HStack(spacing: 10) {
                HStack(spacing: 0) { ForEach(Array(p.colors.enumerated()), id: \.offset) { Rectangle().fill(Color(hex: $1)) } }
                    .frame(width: 64, height: 22)
                    .clipShape(.rect(cornerRadius: 5))
                Text(p.name).lineLimit(1)
                Spacer()
                Text(copied == p.id ? "Copied" : "Copy CSS").font(.caption).foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("Copy this theme's CSS")
    }

    private func copy(_ p: Palette) {
        copyToPasteboard(ThemeExport.css(p))
        copied = p.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if copied == p.id { copied = nil }
        }
    }
}
