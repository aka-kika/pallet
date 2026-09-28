import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(PaletteStore.self) private var store
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @FocusState private var focused: Bool
    @State private var dropping = false

    private var active: Palette {
        store.palettes.first { $0.id == model.selectedID } ?? store.palettes.first
            ?? Palette(id: "empty", name: "Pallet", colors: ["#FFFFFF", "#111318"], main: 0, favorite: false, source: "")
    }
    private var dark: Bool { colorScheme == .dark }
    private var theme: Theme { Theme(active, dark: dark).locked(to: model.bgLock, dark: dark) }
    private var visible: [Palette] { model.favoritesOnly ? store.palettes.filter(\.favorite) : store.palettes }

    var body: some View {
        @Bindable var model = model
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SwatchStrip(palette: active, onMain: { setMain($0) }, onCopy: { copyHex($0) })
                    .frame(height: 200)
                RotationRow(palette: active, dark: dark, rotate: rotate)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                if active.source.contains("estimated") {
                    Text(active.source).font(.caption).foregroundStyle(theme.muted).padding(.bottom, 16)
                }
                if let error = store.loadError {
                    Text(error).font(.callout).foregroundStyle(theme.danger)
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.raised, in: .rect(cornerRadius: 10)).padding(.bottom, 16)
                }
                if visible.isEmpty {
                    EmptyFavorites { model.favoritesOnly = false }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 400), spacing: 28)], spacing: 22) {
                        ForEach(visible) { p in
                            PaletteCard(palette: p, selected: p.id == active.id,
                                        select: { model.selectedID = p.id; focused = true },
                                        favorite: { toggleFavorite(p) })
                                .id(p.id)
                                .contextMenu { cardMenu(p) }
                        }
                    }
                }
                CollectionTools()
                    .padding(.top, 36)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.never)
        .onChange(of: model.selectedID) { _, id in
            withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(id) }
        }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !model.hideKeyboardGuide { KeyboardBar(count: store.palettes.count, dark: dark, shuffle: shuffle) }
        }
        .overlay(alignment: .bottom) { ToastView() }
        .overlay { if dropping { DropOverlay() } }
        .toolbar { toolbar }
        .containerBackground(theme.background, for: .window)
        .environment(\.theme, theme)
        .tint(theme.link)
        .foregroundStyle(theme.text)
        .preferredColorScheme(model.colorScheme)
        .animation(.easeInOut(duration: 0.28), value: theme)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .task { await Task.detached(priority: .utility) { PaletteExtractor.warmUp() }.value }
        .onKeyPress(phases: .down, action: key)
        .onDrop(of: [.image, .fileURL], isTargeted: $dropping, perform: drop)
        .sheet(item: $model.importing) { request in
            ImportSheet(request: request) { saved in
                store.put(saved)
                model.selectedID = saved.id
                model.favoritesOnly = false
                model.show("Palette added")
            }
            .environment(\.theme, theme)
        }
        .sheet(item: $model.exporting) { p in ExportSheet(palette: p).environment(\.theme, theme) }
        .alert("Delete \(model.pendingDelete?.name ?? "")?", isPresented: Binding(get: { model.pendingDelete != nil }, set: { if !$0 { model.pendingDelete = nil } })) {
            Button("Delete", role: .destructive) { if let p = model.pendingDelete { delete(p) } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes it from your collection. You can add it again from an image later.")
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Brand().foregroundStyle(theme.uiDim)
        }
        .sharedBackgroundVisibility(.hidden)
        ToolbarSpacer(.flexible)
        ToolbarItemGroup(placement: .primaryAction) {
            Button { model.favoritesOnly.toggle() } label: {
                Image(systemName: model.favoritesOnly ? "heart.fill" : "heart")
                    .foregroundStyle(model.favoritesOnly ? theme.highlightInk : theme.icon)
            }
            .help(model.favoritesOnly ? "Show all" : "Show favorites")
            Button { toggleLock(model: model, store: store) } label: {
                Image(systemName: model.bgLock == nil ? "lock.open" : "lock")
                    .foregroundStyle(model.bgLock == nil ? theme.icon : theme.highlightInk)
            }
            .help(model.bgLock.map { "Unlock background \($0)" } ?? "Lock background")
            Button { copyCSS(active) } label: { Image(systemName: "doc.on.doc").foregroundStyle(theme.icon) }
                .help("Copy CSS")
            Button { model.exporting = active } label: { Image(systemName: "square.and.arrow.down").foregroundStyle(theme.icon) }
                .help("Export selected theme")
            Button { model.appearance = dark ? .light : .dark } label: {
                Image(systemName: dark ? "moon" : "sun.max").foregroundStyle(theme.icon)
            }
            .help(dark ? "Switch to light mode" : "Switch to soft dark mode")
            Button { model.importing = ImportRequest() } label: { Image(systemName: "photo.badge.plus").foregroundStyle(theme.icon) }
                .help("Add image")
        }
    }

    @ViewBuilder
    private func cardMenu(_ p: Palette) -> some View {
        Button("Copy CSS (light + dark)", systemImage: "doc.on.doc") { copyCSS(p) }
        Button("Export Theme...", systemImage: "square.and.arrow.down") { model.exporting = p }
        Button(p.favorite ? "Remove Favorite" : "Favorite", systemImage: p.favorite ? "heart.slash" : "heart") { toggleFavorite(p) }
        Divider()
        Button("Delete...", systemImage: "trash", role: .destructive) { model.pendingDelete = p }
            .disabled(store.palettes.count <= 1)
    }

    // MARK: Actions

    private func setMain(_ i: Int) { var p = active; p.main = i; store.put(p) }

    private func rotate(_ n: Int) {
        var p = active
        p.main = (p.main + n + p.colors.count) % p.colors.count
        store.put(p)
    }

    private func toggleFavorite(_ p: Palette) { var q = p; q.favorite.toggle(); store.put(q) }

    private func shuffle() {
        let pool = visible.filter { $0.id != active.id }
        guard let next = pool.randomElement() else { model.show("Add another palette to shuffle."); return }
        model.selectedID = next.id
    }

    private func copyCSS(_ p: Palette) {
        copyToPasteboard(ThemeExport.css(p))
        model.show("CSS copied", detail: "Light + soft dark, with the selected main color.")
    }

    private func copyHex(_ color: String) {
        copyToPasteboard(color)
        model.show("\(color) copied")
    }

    private func delete(_ p: Palette) {
        guard store.palettes.count > 1 else { model.show("Keep at least one palette."); return }
        let wasSelected = p.id == model.selectedID
        store.remove(p.id)
        if wasSelected, let first = store.palettes.first { model.selectedID = first.id }
        model.show("Palette deleted")
    }

    private func key(_ press: KeyPress) -> KeyPress.Result {
        guard model.importing == nil, model.exporting == nil, press.modifiers.isDisjoint(with: [.command, .option, .control, .shift]) else { return .ignored }
        switch press.key {
        case .space: shuffle()
        case .leftArrow: rotate(-1)
        case .rightArrow: rotate(1)
        case .upArrow, .downArrow:
            let list = visible
            guard !list.isEmpty else { return .handled }
            let i = list.firstIndex { $0.id == active.id } ?? 0
            model.selectedID = list[(i + (press.key == .downArrow ? 1 : -1) + list.count) % list.count].id
        default:
            if press.characters.lowercased() == "l" { toggleLock(model: model, store: store) } else { return .ignored }
        }
        return .handled
    }

    private func drop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, let image = NSImage(contentsOf: url) else { return }
                Task { @MainActor in receive(image, name: url.deletingPathExtension().lastPathComponent) }
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
        if model.autoImportOnDrop {
            Task {
                do {
                    let p = try await ImportSheet.quickPalette(from: image, fileName: name)
                    store.put(p)
                    model.selectedID = p.id
                    model.show("Palette added")
                } catch {
                    model.show(error.localizedDescription)
                }
            }
        } else {
            model.importing = ImportRequest(image: image, fileName: name)
        }
    }
}

// MARK: - Theme in the environment

extension EnvironmentValues {
    @Entry var theme = Theme(roles: [])
}
