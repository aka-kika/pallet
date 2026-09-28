import SwiftUI
import UniformTypeIdentifiers

@main
struct PalletApp: App {
    @State private var store: PaletteStore
    @State private var model: AppModel
    @State private var actions: PaletteActions

    init() {
        let store = PaletteStore(), model = AppModel()
        _store = State(initialValue: store)
        _model = State(initialValue: model)
        _actions = State(initialValue: PaletteActions(store: store, model: model))
    }

    var body: some Scene {
        Window("Pallet", id: "main") {
            ContentView()
                .environment(store)
                .environment(model)
                .environment(actions)
        }
        .defaultSize(width: 980, height: 680)
        .windowResizability(.contentMinSize)
        .commands { PalletCommands(store: store, model: model, actions: actions) }

        Window("About Pallet", id: "about") {
            AboutView()
                .environment(model)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .restorationBehavior(.disabled)

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}

/// UI state and the few preferences, kept in UserDefaults like the web app's palette-prefs.
@Observable
final class AppModel {
    enum Appearance: String, CaseIterable { case system, light, dark }

    /// Sidebar sections.
    enum Library: String, CaseIterable, Identifiable {
        case all, favorites, mine, starter
        var id: String { rawValue }
        var title: String {
            switch self { case .all: "All Palettes"; case .favorites: "Favorites"; case .mine: "My Palettes"; case .starter: "Starter Palettes" }
        }
        var symbol: String {
            switch self { case .all: "square.grid.2x2"; case .favorites: "heart"; case .mine: "photo.on.rectangle.angled"; case .starter: "sparkles" }
        }
    }

    var selectedID: String { didSet { save("selected", selectedID) } }
    var library: Library { didSet { save("library", library.rawValue) } }
    var appearance: Appearance { didSet { save("appearance", appearance.rawValue) } }
    var bgLock: String? { didSet { save("bgLock", bgLock) } }
    var showShuffleButton: Bool { didSet { save("showShuffleButton", showShuffleButton) } }
    var autoImportOnDrop: Bool { didSet { save("autoImportOnDrop", autoImportOnDrop) } }
    var query = ""

    var importing: ImportRequest?
    var exporting: Palette?
    var pendingDelete: Palette?
    var toast: Toast?
    /// Set by keyboard navigation only, so shuffle and saving keep the view still.
    var scrollTarget: String?

    init() {
        let d = UserDefaults.standard
        selectedID = d.string(forKey: "selected") ?? "seed-12"
        library = Library(rawValue: d.string(forKey: "library") ?? "") ?? .all
        appearance = Appearance(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        bgLock = d.string(forKey: "bgLock").flatMap(ColorMath.parseHex)
        showShuffleButton = d.object(forKey: "showShuffleButton") as? Bool ?? true
        autoImportOnDrop = d.bool(forKey: "autoImportOnDrop")
    }

    private func save(_ key: String, _ value: Any?) { UserDefaults.standard.set(value, forKey: key) }

    var colorScheme: ColorScheme? {
        switch appearance { case .system: nil; case .light: .light; case .dark: .dark }
    }

    func show(_ message: String, detail: String? = nil) {
        let t = Toast(message: message, detail: detail)
        toast = t
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            if toast?.id == t.id { toast = nil }
        }
    }
}

struct Toast: Equatable, Identifiable {
    let id = UUID()
    var message: String
    var detail: String?
}

/// An image waiting to be turned into a palette.
struct ImportRequest: Identifiable {
    let id = UUID()
    var image: NSImage?
    var fileName: String?
}

/// Everything that changes the collection goes through here, so menus, keys
/// and buttons behave the same and every change can be undone.
@Observable
final class PaletteActions {
    let store: PaletteStore
    let model: AppModel
    @ObservationIgnored weak var undoManager: UndoManager?

    init(store: PaletteStore, model: AppModel) {
        self.store = store
        self.model = model
    }

    var active: Palette? { store.palettes.first { $0.id == model.selectedID } ?? store.palettes.first }

    /// Palettes in the current sidebar section that match the search.
    var visible: [Palette] {
        let section: [Palette] = switch model.library {
        case .all: store.palettes
        case .favorites: store.palettes.filter(\.favorite)
        case .mine: store.palettes.filter { !store.isBuiltIn($0.id) }
        case .starter: store.palettes.filter { store.isBuiltIn($0.id) }
        }
        let q = model.query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return section }
        return section.filter { p in
            p.name.lowercased().contains(q)
                || p.colors.contains { $0.lowercased().contains(q.hasPrefix("#") ? q : "#" + q) && q.count >= 3 }
                || p.colors.contains { Naming.word($0).lowercased().hasPrefix(q) }
        }
    }

    var isDark: Bool {
        model.appearance == .dark || (model.appearance == .system && NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    }

    // MARK: Undoable changes

    /// Replace (or with nil remove) one palette and register the way back.
    private func commit(_ id: String, to new: Palette?, _ name: String) {
        let old = store.palettes.first { $0.id == id }
        let index = store.palettes.firstIndex { $0.id == id }
        let selected = model.selectedID
        if let new { store.put(new, at: index) } else { store.remove(id) }
        undoManager?.registerUndo(withTarget: store) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.restore(id, to: old, at: index, redo: new, selected: selected, name)
            }
        }
        undoManager?.setActionName(name)
    }

    private func restore(_ id: String, to old: Palette?, at index: Int?, redo new: Palette?, selected: String, _ name: String) {
        if let old { store.put(old, at: index) } else { store.remove(id) }
        model.selectedID = store.palettes.contains { $0.id == selected } ? selected : (store.palettes.first?.id ?? selected)
        undoManager?.registerUndo(withTarget: store) { [weak self] _ in
            MainActor.assumeIsolated { self?.commit(id, to: new, name) }
        }
        undoManager?.setActionName(name)
    }

    func setMain(_ i: Int) {
        guard var p = active, p.main != i else { return }
        p.main = i
        commit(p.id, to: p, "Change Main Color")
    }

    func rotate(_ n: Int) {
        guard var p = active else { return }
        p.main = (p.main + n + p.colors.count) % p.colors.count
        commit(p.id, to: p, "Change Main Color")
    }

    func toggleFavorite(_ p: Palette? = nil) {
        guard var q = p ?? active else { return }
        q.favorite.toggle()
        commit(q.id, to: q, q.favorite ? "Favorite" : "Remove Favorite")
    }

    func add(_ p: Palette) {
        commit(p.id, to: p, "Add Palette")
        model.selectedID = p.id
        if model.library == .starter || (model.library == .favorites && !p.favorite) { model.library = .all }
        model.show("Palette added")
    }

    func delete(_ p: Palette) {
        guard store.palettes.count > 1 else { model.show("Keep at least one palette."); return }
        let list = visible
        let i = list.firstIndex { $0.id == p.id }
        commit(p.id, to: nil, "Delete Palette")
        if model.selectedID == p.id {
            let rest = visible
            model.selectedID = (i.flatMap { rest.indices.contains($0) ? rest[$0].id : rest.last?.id }) ?? store.palettes.first?.id ?? ""
        }
        model.show("Palette deleted", detail: "Edit > Undo brings it back.")
    }

    // MARK: Moving around

    func shuffle() {
        let pool = visible.filter { $0.id != model.selectedID }
        guard let next = pool.randomElement() else { model.show("Add another palette to shuffle."); return }
        model.selectedID = next.id
    }

    func step(_ n: Int) {
        let list = visible
        guard !list.isEmpty else { return }
        let i = list.firstIndex { $0.id == model.selectedID } ?? 0
        let next = list[(i + n + list.count) % list.count].id
        model.selectedID = next
        model.scrollTarget = next
    }

    func toggleLock() {
        if model.bgLock != nil { model.bgLock = nil; return }
        guard let p = active else { return }
        model.bgLock = Theme(p, dark: isDark)["background"]
    }

    // MARK: Copy, export, import

    func copyCSS(_ p: Palette? = nil) {
        guard let p = p ?? active else { return }
        copyToPasteboard(ThemeExport.css(p))
        model.show("CSS copied", detail: "Light + soft dark, with the selected main color.")
    }

    func copyHex(_ color: String) {
        copyToPasteboard(color)
        model.show("\(color) copied")
    }

    func pasteImage() {
        guard let image = NSImage(pasteboard: .general) else { model.show("No image on the clipboard."); return }
        model.importing = ImportRequest(image: image, fileName: nil)
    }

    func exportCollection() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "palette-collection.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ThemeExport.collection(store.palettes).write(to: url, atomically: true, encoding: .utf8)
            model.show("Collection exported")
        } catch {
            model.show("Could not export the collection.")
        }
    }

    func importCollection() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        struct File: Decodable { var palettes: [Palette] }
        do {
            let data = try Data(contentsOf: url)
            guard data.count < 2_000_000 else { throw CocoaError(.fileReadTooLarge) }
            let list = try JSONDecoder().decode(File.self, from: data).palettes
            guard list.count <= 1000, list.allSatisfy(\.isValid) else { throw CocoaError(.fileReadCorruptFile) }
            undoManager?.beginUndoGrouping()
            list.forEach { commit($0.id, to: $0, "Import Collection") }
            undoManager?.endUndoGrouping()
            model.show("\(list.count) palettes imported")
        } catch {
            model.show("Choose a valid Palette collection JSON file.")
        }
    }
}

struct PalletCommands: Commands {
    let store: PaletteStore
    let model: AppModel
    let actions: PaletteActions
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Pallet") { openWindow(id: "about") }
        }
        CommandGroup(replacing: .newItem) {
            Button("New Palette from Image...") { model.importing = ImportRequest() }
                .keyboardShortcut("o")
        }
        CommandGroup(replacing: .importExport) {
            Button("Export Theme...") { model.exporting = actions.active }
                .keyboardShortcut("e")
            Divider()
            Button("Export Collection...") { actions.exportCollection() }
            Button("Import Collection...") { actions.importCollection() }
        }
        // Copy and Paste act on text fields when one is focused, otherwise
        // Copy takes the theme CSS and Paste takes an image, like the web app.
        CommandGroup(replacing: .pasteboard) {
            Button("Cut") { NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil) }
                .keyboardShortcut("x")
            Button("Copy") {
                if editingText { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) } else { actions.copyCSS() }
            }
            .keyboardShortcut("c")
            Button("Paste") {
                if editingText { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) } else { actions.pasteImage() }
            }
            .keyboardShortcut("v")
            Button("Select All") { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
                .keyboardShortcut("a")
            Divider()
            Button("Delete Palette...") { model.pendingDelete = actions.active }
                .keyboardShortcut(.delete)
                .disabled(store.palettes.count <= 1)
        }
        CommandMenu("Palette") {
            Button("Shuffle") { actions.shuffle() }
                .keyboardShortcut("r")
            Button("Previous Main Color") { actions.rotate(-1) }
                .keyboardShortcut("[")
            Button("Next Main Color") { actions.rotate(1) }
                .keyboardShortcut("]")
            Divider()
            Button(actions.active?.favorite == true ? "Remove from Favorites" : "Add to Favorites") { actions.toggleFavorite() }
                .keyboardShortcut("d")
            Button(model.bgLock == nil ? "Lock Background" : "Unlock Background") { actions.toggleLock() }
                .keyboardShortcut("l")
            Button("Copy CSS") { actions.copyCSS() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
        }
        CommandGroup(after: .sidebar) {
            Divider()
            Picker("Appearance", selection: Binding(get: { model.appearance }, set: { model.appearance = $0 })) {
                Text("Follow System").tag(AppModel.Appearance.system)
                Text("Light").tag(AppModel.Appearance.light)
                Text("Soft Dark").tag(AppModel.Appearance.dark)
            }
            Divider()
            ForEach(Array(AppModel.Library.allCases.enumerated()), id: \.element) { i, section in
                Button(section.title) { model.library = section }
                    .keyboardShortcut(KeyEquivalent(Character(String(i + 1))))
            }
        }
    }

    private var editingText: Bool {
        guard let window = NSApp.keyWindow else { return false }
        return window.firstResponder is NSText || window.attachedSheet != nil || window.isSheet
    }
}

func copyToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}
