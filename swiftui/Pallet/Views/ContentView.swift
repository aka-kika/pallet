import SwiftUI
import UniformTypeIdentifiers

/// System frame (sidebar, toolbar, search) around the Pallet canvas.
struct ContentView: View {
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model
    @Environment(PaletteActions.self) private var actions
    @Environment(\.undoManager) private var undoManager
    @State private var renameText = ""

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 280)
        } detail: {
            Canvas()
        }
        .searchable(text: $model.query, placement: .sidebar, prompt: "Name or color")
        .frame(minWidth: 640, minHeight: 460)
        .preferredColorScheme(model.colorScheme)
        .onAppear { actions.undoManager = undoManager }
        .onChange(of: undoManager) { actions.undoManager = undoManager }
        .task { await Task.detached(priority: .utility) { PaletteExtractor.warmUp() }.value }
        .sheet(item: $model.importing) { request in
            ImportSheet(request: request) { actions.add($0) }
        }
        .sheet(item: $model.exporting) { ExportSheet(palette: $0) }
        .alert("Rename Collection", isPresented: Binding(get: { model.renaming != nil }, set: { if !$0 { model.renaming = nil } })) {
            TextField("Name", text: $renameText)
            Button("Rename") { if let c = model.renaming { actions.renameCollection(c.id, to: renameText) } }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: model.renaming) { renameText = model.renaming?.name ?? "" }
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
    @Environment(PaletteActions.self) private var actions

    var body: some View {
        List(selection: Binding(get: { model.sidebar }, set: { if let s = $0 { model.sidebar = s } })) {
            Section("Library") {
                ForEach(AppModel.Library.allCases) { section in
                    Label(section.title, systemImage: section.symbol)
                        .badge(count(section))
                        .tag(AppModel.SidebarItem.library(section))
                        .dropDestination(for: PaletteDrag.self) { items, _ in
                            guard section == .favorites else { return false }
                            items.map(\.palette).filter { p in store.palettes.contains { $0.id == p.id && !$0.favorite } }.forEach { actions.toggleFavorite($0) }
                            return true
                        }
                }
            }
            Section("Collections") {
                ForEach(store.collections) { c in
                    Label(c.name, systemImage: "folder")
                        .badge(c.paletteIDs.filter { id in store.palettes.contains { $0.id == id } }.count)
                        .tag(AppModel.SidebarItem.collection(c.id))
                        .dropDestination(for: PaletteDrag.self) { items, _ in
                            items.forEach { actions.addToCollection($0.palette.id, c.id) }
                            return true
                        }
                        .contextMenu {
                            Button("Rename...") { model.renaming = c }
                            Button("Delete Collection", role: .destructive) { actions.deleteCollection(c.id) }
                        }
                }
                .onMove(perform: actions.moveCollections)
                if store.collections.isEmpty {
                    Text("No collections yet")
                        .font(.caption).foregroundStyle(.secondary)
                        .selectionDisabled()
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                ColorSlider()
                Button("New Collection", systemImage: "plus") {
                    let c = actions.newCollection()
                    model.sidebar = .collection(c.id)
                    model.renaming = c
                }
                .buttonStyle(.borderless)
                .help("New collection (Shift-Command-N)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
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

/// Greys, then the color wheel. Drag to keep only palettes with a color near
/// the knob, closest first. Same idea as the color slider in Iconzzz.
struct ColorSlider: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Color").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                if model.colorFilter != nil {
                    Button { model.colorFilter = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
                        .buttonStyle(.plain)
                        .help("Clear the color")
                        .accessibilityLabel("Clear the color")
                }
            }
            GeometryReader { geo in
                let width = geo.size.width
                let knob = model.colorFilter ?? model.colorPosition
                ZStack(alignment: .leading) {
                    Capsule().fill(ColorFilter.track).frame(height: 8)
                    Circle()
                        .fill(ColorFilter.color(at: knob))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.35), radius: 1)
                        .opacity(model.colorFilter == nil ? 0.5 : 1)
                        .offset(x: knob * width - 8)
                }
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let position = min(0.999, max(0, value.location.x / max(width, 1)))
                    model.colorPosition = position
                    model.colorFilter = position
                })
            }
            .frame(height: 18)
            .accessibilityElement()
            .accessibilityLabel("Color filter")
            .accessibilityValue(model.colorFilter == nil ? "Off" : "On")
            .accessibilityAdjustableAction { direction in
                let position = min(0.999, max(0, (model.colorFilter ?? model.colorPosition) + (direction == .increment ? 0.02 : -0.02)))
                model.colorPosition = position
                model.colorFilter = position
            }
        }
        .help("Drag to show palettes with this color")
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
                                    .draggable(PaletteDrag(palette: p)) { PaletteDragPreview(palette: p) }
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
        .navigationTitle(actions.title)
        .navigationSubtitle(active.name)
        .toolbar(id: "canvas") { toolbar }
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
        } else if model.colorFilter != nil {
            ContentUnavailableView("No Palettes with This Color", systemImage: "paintpalette", description: Text("Drag the color slider, or clear it."))
        } else if actions.currentCollection != nil {
            ContentUnavailableView("Empty Collection", systemImage: "folder", description: Text("Drag palettes onto it in the sidebar, or right-click a palette > Add to Collection."))
        } else if model.library == .favorites {
            ContentUnavailableView("No Favorites Yet", systemImage: "heart", description: Text("Click a heart or choose Palette > Add to Favorites."))
        } else {
            ContentUnavailableView("No Palettes", systemImage: "photo.on.rectangle.angled", description: Text("Drop or paste an image to make one."))
        }
    }

    /// Right-click the toolbar (or View > Customize Toolbar) to add, remove or move items.
    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        if model.showShuffleButton {
            ToolbarItem(id: "shuffle", placement: .primaryAction) {
                Button("Shuffle", systemImage: "shuffle", action: actions.shuffle)
                    .help("Shuffle (Space)")
            }
        }
        ToolbarItem(id: "lock", placement: .primaryAction) {
            Button(model.bgLock == nil ? "Lock Background" : "Unlock Background", systemImage: model.bgLock == nil ? "lock.open" : "lock.fill") { actions.toggleLock() }
                .help(model.bgLock.map { "Unlock background \($0)" } ?? "Lock background (L)")
        }
        ToolbarItem(id: "favorite", placement: .primaryAction) {
            Button(active.favorite ? "Remove from Favorites" : "Add to Favorites", systemImage: active.favorite ? "heart.fill" : "heart") { actions.toggleFavorite() }
                .help("Favorite (\u{2318}D)")
        }
        .defaultCustomization(.hidden)
        ToolbarItem(id: "copy", placement: .primaryAction) {
            Button("Copy CSS", systemImage: "doc.on.doc") { actions.copyCSS() }
                .help("Copy CSS")
        }
        ToolbarItem(id: "export", placement: .primaryAction) {
            Button("Export Theme", systemImage: "square.and.arrow.down") { model.exporting = active }
                .help("Export theme (\u{2318}E)")
        }
        .defaultCustomization(.hidden)
        ToolbarItem(id: "share", placement: .primaryAction) {
            ShareLink(item: ThemeFile(palette: active), preview: SharePreview(active.name))
                .help("Share theme")
        }
        ToolbarItem(id: "appearance", placement: .primaryAction) {
            Button(dark ? "Light Mode" : "Soft Dark Mode", systemImage: dark ? "sun.max" : "moon") { actions.toggleAppearance() }
                .help((dark ? "Switch to light" : "Switch to soft dark") + (model.combo(.appearance).map { " (\($0.display))" } ?? ""))
        }
        ToolbarItem(id: "new", placement: .primaryAction) {
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
        Menu("Add to Collection", systemImage: "folder.badge.plus") {
            ForEach(store.collections) { c in
                Button(c.name) { actions.addToCollection(p.id, c.id) }
                    .disabled(c.paletteIDs.contains(p.id))
            }
            if !store.collections.isEmpty { Divider() }
            Button("New Collection...") {
                let c = actions.newCollection(with: [p.id])
                model.renaming = c
            }
        }
        if let c = actions.currentCollection {
            Button("Remove from \u{201C}\(c.name)\u{201D}", systemImage: "folder.badge.minus") { actions.removeFromCollection(p.id, c.id) }
        }
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
        FileRepresentation(exportedContentType: .cssTheme) { file in try write(file.palette) }
        ProxyRepresentation { ThemeExport.css($0.palette) }
    }

    static func write(_ p: Palette) throws -> SentTransferredFile {
        let name = p.name.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent((name.isEmpty ? "palette" : name) + ".css")
        try ThemeExport.css(p).write(to: url, atomically: true, encoding: .utf8)
        return SentTransferredFile(url)
    }
}

/// What a dragged card carries: its theme as a .css file and text for other
/// apps, and the palette as JSON so a sidebar collection can take it in.
nonisolated struct PaletteDrag: Codable, Transferable {
    let palette: Palette

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
        FileRepresentation(exportedContentType: .cssTheme) { drag in
            try ThemeFile.write(drag.palette)
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
