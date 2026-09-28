import SwiftUI
import UniformTypeIdentifiers

/// System frame (sidebar, toolbar, search) around the Pallet canvas.
struct ContentView: View {
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model
    @Environment(PaletteActions.self) private var actions
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 280)
        } detail: {
            Canvas()
        }
        .searchable(text: $model.query, placement: .toolbar, prompt: "Name or color")
        .frame(minWidth: 640, minHeight: 460)
        .preferredColorScheme(model.colorScheme)
        .onAppear { actions.undoManager = undoManager }
        .onChange(of: undoManager) { actions.undoManager = undoManager }
        .task { await Task.detached(priority: .utility) { PaletteExtractor.warmUp() }.value }
        .sheet(item: $model.importing) { request in
            ImportSheet(request: request) { actions.add($0) }
        }
        .sheet(item: $model.exporting) { ExportSheet(palette: $0) }
        .alert("Delete \u{201C}\(model.pendingDelete?.name ?? "")\u{201D}?", isPresented: Binding(get: { model.pendingDelete != nil }, set: { if !$0 { model.pendingDelete = nil } })) {
            Button("Delete", role: .destructive) { if let p = model.pendingDelete { actions.delete(p) } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can undo this with Edit > Undo.")
        }
    }
}

struct Sidebar: View {
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model

    var body: some View {
        List(selection: Binding(get: { model.library }, set: { if let s = $0 { model.library = s } })) {
            Section("Library") {
                ForEach(AppModel.Library.allCases) { section in
                    Label(section.title, systemImage: section.symbol)
                        .badge(count(section))
                        .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func count(_ section: AppModel.Library) -> Int {
        switch section {
        case .all: store.palettes.count
        case .favorites: store.palettes.filter(\.favorite).count
        case .mine: store.palettes.filter { !store.isBuiltIn($0.id) }.count
        case .starter: store.palettes.filter { store.isBuiltIn($0.id) }.count
        }
    }
}

/// The palette-colored content: swatch strip, arrows and the cards.
struct Canvas: View {
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model
    @Environment(PaletteActions.self) private var actions
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool
    @State private var dropping = false
    @State private var width: CGFloat = 760

    private var active: Palette {
        actions.active ?? Palette(id: "empty", name: "Pallet", colors: ["#FFFFFF", "#111318"], main: 0, favorite: false, source: "")
    }
    private var dark: Bool { colorScheme == .dark }
    private var theme: Theme { Theme(active, dark: dark).locked(to: model.bgLock, dark: dark) }
    /// Cards grow with the window; a column is added only when they get roomy.
    private var columns: Int { max(2, min(6, Int((width - 40 + 18) / (170 + 18)))) }

    var body: some View {
        let visible = actions.visible
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SwatchStrip(palette: active, onMain: actions.setMain, onCopy: actions.copyHex)
                        .frame(height: min(180, max(110, width * 0.2)))
                    RotationRow(palette: active, dark: dark, rotate: actions.rotate)
                        .padding(.vertical, 12)
                    if active.source.contains("estimated") {
                        Text(active.source).font(.caption).foregroundStyle(theme.muted).padding(.bottom, 12)
                    }
                    if let error = store.loadError {
                        Text(error).font(.callout).foregroundStyle(theme.danger)
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.raised, in: .rect(cornerRadius: 10)).padding(.bottom, 12)
                    }
                    if visible.isEmpty {
                        empty.frame(maxWidth: .infinity).padding(.vertical, 40)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: columns), spacing: 12) {
                            ForEach(visible) { p in
                                PaletteCard(palette: p, selected: p.id == active.id,
                                            select: { model.selectedID = p.id; focused = true },
                                            favorite: { actions.toggleFavorite(p) })
                                    .id(p.id)
                                    .draggable(ThemeFile(palette: p)) { PaletteDragPreview(palette: p) }
                                    .contextMenu { menu(p) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: columns)
            }
            .onChange(of: model.scrollTarget) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { proxy.scrollTo(id) }
                model.scrollTarget = nil
            }
        }
        .background { theme.background.ignoresSafeArea() }
        .overlay(alignment: .bottom) { ToastView() }
        .overlay { if dropping { DropOverlay() } }
        .environment(\.theme, theme)
        .tint(theme.link)
        .foregroundStyle(theme.text)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: theme)
        .navigationTitle(model.library.title)
        .navigationSubtitle(active.name)
        .toolbar { toolbar }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(phases: .down, action: key)
        .onDrop(of: [.image, .fileURL], isTargeted: $dropping, perform: drop)
    }

    @ViewBuilder
    private var empty: some View {
        if !model.query.isEmpty {
            ContentUnavailableView.search(text: model.query)
        } else if model.library == .favorites {
            ContentUnavailableView("No Favorites Yet", systemImage: "heart", description: Text("Click a heart or choose Palette > Add to Favorites."))
        } else {
            ContentUnavailableView("No Palettes", systemImage: "photo.on.rectangle.angled", description: Text("Drop or paste an image to make one."))
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if model.showShuffleButton {
                Button("Shuffle", systemImage: "shuffle", action: actions.shuffle)
                    .help("Shuffle (Space)")
            }
            Button(model.bgLock == nil ? "Lock Background" : "Unlock Background", systemImage: model.bgLock == nil ? "lock.open" : "lock.fill") { actions.toggleLock() }
                .help(model.bgLock.map { "Unlock background \($0)" } ?? "Lock background (L)")
            Button("Copy CSS", systemImage: "doc.on.doc") { actions.copyCSS() }
                .help("Copy CSS")
            ShareLink(item: ThemeFile(palette: active), preview: SharePreview(active.name))
                .help("Share theme")
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
            Button("New Palette from Image", systemImage: "plus") { model.importing = ImportRequest() }
                .help("New palette from image")
        }
    }

    @ViewBuilder
    private func menu(_ p: Palette) -> some View {
        Button("Copy CSS", systemImage: "doc.on.doc") { actions.copyCSS(p) }
        Button("Export Theme...", systemImage: "square.and.arrow.down") { model.exporting = p }
        ShareLink(item: ThemeFile(palette: p), preview: SharePreview(p.name))
        Divider()
        Button(p.favorite ? "Remove from Favorites" : "Add to Favorites", systemImage: p.favorite ? "heart.slash" : "heart") { actions.toggleFavorite(p) }
        Divider()
        Button("Delete...", systemImage: "trash", role: .destructive) { model.pendingDelete = p }
            .disabled(store.palettes.count <= 1)
    }

    private func key(_ press: KeyPress) -> KeyPress.Result {
        guard model.importing == nil, model.exporting == nil, press.modifiers.isDisjoint(with: [.command, .option, .control, .shift]) else { return .ignored }
        switch press.key {
        case .space: actions.shuffle()
        case .leftArrow: actions.rotate(-1)
        case .rightArrow: actions.rotate(1)
        case .upArrow: actions.step(-1)
        case .downArrow: actions.step(1)
        default:
            if press.characters.lowercased() == "l" { actions.toggleLock() } else { return .ignored }
        }
        return .handled
    }

    private func drop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, let image = NSImage(contentsOf: url) else { return }
                let name = url.deletingPathExtension().lastPathComponent
                Task { @MainActor in receive(image, name: name) }
            }
            return true
        }
        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                guard let image = object as? NSImage else { return }
                Task { @MainActor in receive(image, name: nil) }
            }
            return true
        }
        return false
    }

    private func receive(_ image: NSImage, name: String?) {
        guard model.autoImportOnDrop else { model.importing = ImportRequest(image: image, fileName: name); return }
        Task {
            do { actions.add(try await ImportSheet.quickPalette(from: image, fileName: name)) } catch { model.show(error.localizedDescription) }
        }
    }
}

/// A palette's theme as a .css file, for Share and for dragging a card out.
nonisolated struct ThemeFile: Transferable {
    let palette: Palette

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .cssTheme) { file in
            let name = file.palette.name.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent((name.isEmpty ? "palette" : name) + ".css")
            try ThemeExport.css(file.palette).write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
        ProxyRepresentation { ThemeExport.css($0.palette) }
    }
}

extension UTType {
    nonisolated static let cssTheme = UTType(filenameExtension: "css", conformingTo: .plainText) ?? .plainText
}

struct PaletteDragPreview: View {
    let palette: Palette
    var body: some View {
        HStack(spacing: 0) { ForEach(Array(palette.colors.enumerated()), id: \.offset) { Rectangle().fill(Color(hex: $1)) } }
            .frame(width: 140, height: 60)
            .clipShape(.rect(cornerRadius: 8))
    }
}

// MARK: - Theme in the environment

extension EnvironmentValues {
    @Entry var theme = Theme(roles: [])
}
