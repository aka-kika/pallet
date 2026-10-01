import SwiftUI
import UniformTypeIdentifiers

@main
struct PalletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var store: PaletteStore
    @State private var model: AppModel
    @State private var actions: PaletteActions

    init() {
        let store = PaletteStore(), model = AppModel()
        _store = State(initialValue: store)
        _model = State(initialValue: model)
        let actions = PaletteActions(store: store, model: model)
        _actions = State(initialValue: actions)
        MenuBarController.shared = MenuBarController(store: store, model: model, actions: actions)
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
        // Menu bar only: start quietly, the window opens from the menu bar.
        .defaultLaunchBehavior(model.presence == .menuBar ? .suppressed : .presented)
        .commands { PalletCommands(store: store, model: model, actions: actions) }

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
    /// A collection selected in the sidebar; nil means a Library section is.
    var collectionID: String? { didSet { save("collection", collectionID) } }
    /// Color slider position (0...1) while it filters; nil when it is off.
    var colorFilter: Double?
    var colorPosition: Double { didSet { save("colorPosition", colorPosition) } }
    var renaming: PaletteCollection?
    var appearance: Appearance { didSet { save("appearance", appearance.rawValue) } }
    var bgLock: String? { didSet { save("bgLock", bgLock) } }
    var showShuffleButton: Bool { didSet { save("showShuffleButton", showShuffleButton) } }
    var autoImportOnDrop: Bool { didSet { save("autoImportOnDrop", autoImportOnDrop) } }

    /// Where Pallet shows up: Dock and menu bar, Dock only, or menu bar only.
    enum Presence: String, CaseIterable { case both, dock, menuBar }
    var presence: Presence { didSet { save("presence", presence.rawValue); MenuBarController.shared?.apply() } }
    var captureShortcut: Shortcut? {
        didSet {
            UserDefaults.standard.set(captureShortcut.flatMap { try? JSONEncoder().encode($0) }, forKey: "captureShortcut")
            MenuBarController.shared?.apply()
        }
    }
    var panelShortcut: Shortcut? {
        didSet {
            UserDefaults.standard.set(panelShortcut.flatMap { try? JSONEncoder().encode($0) }, forKey: "panelShortcut")
            MenuBarController.shared?.apply()
        }
    }
    var copyCSSAfterCapture: Bool { didSet { save("copyCSSAfterCapture", copyCSSAfterCapture) } }

    /// Recorded menu shortcuts; an empty key means "no shortcut".
    private var keyCombos: [String: KeyCombo] {
        didSet { UserDefaults.standard.set(try? JSONEncoder().encode(keyCombos), forKey: "keyCombos") }
    }

    func combo(_ command: AppCommand) -> KeyCombo? {
        guard let k = keyCombos[command.rawValue] else { return command.standard }
        return k.key.isEmpty ? nil : k
    }

    func setCombo(_ combo: KeyCombo?, for command: AppCommand) {
        keyCombos[command.rawValue] = combo ?? KeyCombo("", [])
    }

    func resetCombos() { keyCombos = [:] }

    enum SettingsTab: String { case general, capture, keyboard, about }
    var settingsTab: SettingsTab = .general
    /// Set from the menu commands, which exist even when no window is open.
    @ObservationIgnored var openMainWindow: (() -> Void)?
    @ObservationIgnored var openSettingsWindow: (() -> Void)?
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
        collectionID = d.string(forKey: "collection")
        colorPosition = d.object(forKey: "colorPosition") as? Double ?? 0.12 + 0.88 * 255 / 360
        appearance = Appearance(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        bgLock = d.string(forKey: "bgLock").flatMap(ColorMath.parseHex)
        showShuffleButton = d.object(forKey: "showShuffleButton") as? Bool ?? true
        autoImportOnDrop = d.bool(forKey: "autoImportOnDrop")
        presence = Presence(rawValue: d.string(forKey: "presence") ?? "") ?? .both
        if d.object(forKey: "captureShortcut") == nil {
            captureShortcut = .standard
        } else {
            captureShortcut = d.data(forKey: "captureShortcut").flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) }
        }
        if d.object(forKey: "panelShortcut") == nil {
            panelShortcut = .panelStandard
        } else {
            panelShortcut = d.data(forKey: "panelShortcut").flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) }
        }
        copyCSSAfterCapture = d.bool(forKey: "copyCSSAfterCapture")
        keyCombos = d.data(forKey: "keyCombos").flatMap { try? JSONDecoder().decode([String: KeyCombo].self, from: $0) } ?? [:]
    }

    private func save(_ key: String, _ value: Any?) { UserDefaults.standard.set(value, forKey: key) }

    enum SidebarItem: Hashable { case library(Library), collection(String) }

    var sidebar: SidebarItem {
        get { collectionID.map { .collection($0) } ?? .library(library) }
        set {
            switch newValue {
            case .library(let l): library = l; collectionID = nil
            case .collection(let id): collectionID = id
            }
        }
    }

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
        var list: [Palette]
        if let collection = currentCollection {
            list = collection.paletteIDs.compactMap { id in store.palettes.first { $0.id == id } }
        } else {
            list = switch model.library {
            case .all: store.palettes
            case .favorites: store.palettes.filter(\.favorite)
            case .mine: store.palettes.filter { !store.isBuiltIn($0.id) }
            case .starter: store.palettes.filter { store.isBuiltIn($0.id) }
            }
        }
        let q = model.query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter { p in
                p.name.lowercased().contains(q)
                    || p.colors.contains { $0.lowercased().contains(q.hasPrefix("#") ? q : "#" + q) && q.count >= 3 }
                    || p.colors.contains { Naming.word($0).lowercased().hasPrefix(q) }
            }
        }
        // The color slider keeps matches only, closest first.
        if let position = model.colorFilter {
            list = list.map { ($0, ColorFilter.score($0, at: position)) }.filter { $0.1 > 0 }
                .enumerated().sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
                .map(\.element.0)
        }
        return list
    }

    var currentCollection: PaletteCollection? {
        model.collectionID.flatMap { id in store.collections.first { $0.id == id } }
    }

    var title: String { currentCollection?.name ?? model.library.title }

    var isDark: Bool {
        model.appearance == .dark || (model.appearance == .system && NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    }

    // MARK: Undoable changes

    /// Replace (or with nil remove) one palette and register the way back.
    @discardableResult
    private func commit(_ id: String, to new: Palette?, _ name: String) -> Bool {
        let old = store.palettes.first { $0.id == id }
        let index = store.palettes.firstIndex { $0.id == id }
        let selected = model.selectedID
        if let new {
            guard store.put(new, at: index) else { return false }
        } else {
            store.remove(id)
        }
        undoManager?.registerUndo(withTarget: store) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.restore(id, to: old, at: index, redo: new, selected: selected, name)
            }
        }
        undoManager?.setActionName(name)
        return true
    }

    private func restore(_ id: String, to old: Palette?, at index: Int?, redo new: Palette?, selected: String, _ name: String) {
        if let old { store.put(old, at: index) } else { store.remove(id) }
        model.selectedID = store.palettes.contains { $0.id == selected } ? selected : (store.palettes.first?.id ?? selected)
        undoManager?.registerUndo(withTarget: store) { [weak self] _ in
            MainActor.assumeIsolated { _ = self?.commit(id, to: new, name) }
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
        guard commit(p.id, to: p, "Add Palette") else { model.show("This palette could not be saved.", detail: "It needs a name and at least 2 colors."); return }
        model.selectedID = p.id
        if let c = currentCollection {
            addToCollection(p.id, c.id)
        } else if model.library == .starter || (model.library == .favorites && !p.favorite) {
            model.library = .all
        }
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

    func toggleAppearance() {
        model.appearance = isDark ? .light : .dark
    }

    func toggleLock() {
        if model.bgLock != nil { model.bgLock = nil; return }
        guard let p = active else { return }
        model.bgLock = Theme(p, dark: isDark)["background"]
    }

    // MARK: Collections

    /// Swap the collection list and register the way back.
    private func commitCollections(_ next: [PaletteCollection], _ name: String) {
        let old = store.collections
        store.setCollections(next)
        undoManager?.registerUndo(withTarget: store) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.commitCollections(old, name)
                if let id = self.model.collectionID, !old.contains(where: { $0.id == id }) { self.model.sidebar = .library(.all) }
            }
        }
        undoManager?.setActionName(name)
    }

    @discardableResult
    func newCollection(named name: String = "New Collection", with ids: [String] = []) -> PaletteCollection {
        let taken = Set(store.collections.map(\.name))
        var title = name, n = 2
        while taken.contains(title) { title = "\(name) \(n)"; n += 1 }
        let c = PaletteCollection(id: PaletteCollection.newID(), name: title, paletteIDs: ids)
        commitCollections(store.collections + [c], "New Collection")
        return c
    }

    func renameCollection(_ id: String, to name: String) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        commitCollections(store.collections.map { $0.id == id ? PaletteCollection(id: id, name: String(clean.prefix(60)), paletteIDs: $0.paletteIDs) : $0 }, "Rename Collection")
    }

    func deleteCollection(_ id: String) {
        commitCollections(store.collections.filter { $0.id != id }, "Delete Collection")
        if model.collectionID == id { model.sidebar = .library(.all) }
        model.show("Collection deleted", detail: "The palettes stay in your library. Edit > Undo brings it back.")
    }

    func addToCollection(_ paletteID: String, _ collectionID: String) {
        guard let c = store.collections.first(where: { $0.id == collectionID }), !c.paletteIDs.contains(paletteID) else { return }
        commitCollections(store.collections.map { $0.id == collectionID ? PaletteCollection(id: $0.id, name: $0.name, paletteIDs: $0.paletteIDs + [paletteID]) : $0 }, "Add to Collection")
        model.show("Added to \(c.name)")
    }

    func removeFromCollection(_ paletteID: String, _ collectionID: String) {
        commitCollections(store.collections.map { $0.id == collectionID ? PaletteCollection(id: $0.id, name: $0.name, paletteIDs: $0.paletteIDs.filter { $0 != paletteID }) : $0 }, "Remove from Collection")
    }

    func moveCollections(from source: IndexSet, to destination: Int) {
        var list = store.collections
        list.move(fromOffsets: source, toOffset: destination)
        commitCollections(list, "Move Collection")
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
        guard let (image, name) = pastedImage(.general) else { model.show("No image on the clipboard."); return }
        model.importing = ImportRequest(image: image, fileName: name)
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
        do {
            let data = try Data(contentsOf: url)
            guard data.count < 2_000_000,
                  let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = root["palettes"] as? [Any], items.count <= 1000 else { throw CocoaError(.fileReadCorruptFile) }
            // Read what can be read; one odd entry doesn't spoil the file.
            let list = items.compactMap { item in
                (try? JSONSerialization.data(withJSONObject: item)).flatMap { try? JSONDecoder().decode(Palette.self, from: $0) }
            }.filter(\.isValid)
            guard !list.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
            let before = store.snapshot()
            let (added, replaced) = store.put(contentsOf: list)
            registerSnapshotUndo(before, "Import Collection")
            let skipped = items.count - list.count
            var detail = replaced > 0 ? "\(replaced) replaced palettes with the same id." : ""
            if skipped > 0 { detail += (detail.isEmpty ? "" : " ") + "\(skipped) could not be read." }
            model.show("\(added + replaced) palettes imported", detail: detail.isEmpty ? nil : detail + " Edit > Undo reverts it.")
        } catch {
            model.show("Choose a valid Palette collection JSON file.")
        }
    }

    /// Undo for a batch change: put the whole collection back as it was.
    private func registerSnapshotUndo(_ before: PaletteStore.Snapshot, _ name: String) {
        let after = store.snapshot()
        undoManager?.registerUndo(withTarget: store) { [weak self] store in
            MainActor.assumeIsolated {
                store.restore(before)
                self?.undoManager?.registerUndo(withTarget: store) { [weak self] store in
                    MainActor.assumeIsolated {
                        store.restore(after)
                        if let self { self.registerSnapshotUndo(before, name) }
                    }
                }
            }
        }
        undoManager?.setActionName(name)
    }
}

struct PalletCommands: Commands {
    let store: PaletteStore
    let model: AppModel
    let actions: PaletteActions
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some Commands {
        // The menu bar panel opens windows through these.
        let _ = model.openMainWindow = { openWindow(id: "main") }
        let _ = model.openSettingsWindow = { openSettings() }
        CommandGroup(replacing: .appInfo) {
            Button("About Pallet") { model.settingsTab = .about; openSettings() }
        }
        CommandGroup(after: .newItem) {
            Button("Capture Screen Area") { MenuBarController.shared?.captureArea() }
        }
        CommandGroup(replacing: .newItem) {
            Button("New Palette from Image...") { model.importing = ImportRequest() }
                .shortcut(model.combo(.newFromImage))
            Button("New Collection") {
                let c = actions.newCollection()
                model.sidebar = .collection(c.id)
                model.renaming = c
            }
            .shortcut(model.combo(.newCollection))
        }
        CommandGroup(replacing: .importExport) {
            Button("Export Theme...") { model.exporting = actions.active }
                .shortcut(model.combo(.export))
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
            // Cmd-Delete in a text field deletes to the start of the line, as usual.
            Button("Delete Palette...") {
                if editingText { NSApp.sendAction(#selector(NSResponder.deleteToBeginningOfLine(_:)), to: nil, from: nil) } else { model.pendingDelete = actions.active }
            }
                .keyboardShortcut(.delete)
                .disabled(store.palettes.count <= 1)
        }
        CommandMenu("Palette") {
            Button("Shuffle") { actions.shuffle() }
                .shortcut(model.combo(.shuffle))
            Button("Previous Main Color") { actions.rotate(-1) }
                .shortcut(model.combo(.previousColor))
            Button("Next Main Color") { actions.rotate(1) }
                .shortcut(model.combo(.nextColor))
            Divider()
            Button(actions.active?.favorite == true ? "Remove from Favorites" : "Add to Favorites") { actions.toggleFavorite() }
                .shortcut(model.combo(.favorite))
            Button(model.bgLock == nil ? "Lock Background" : "Unlock Background") { actions.toggleLock() }
                .shortcut(model.combo(.lock))
            Button("Copy CSS") { actions.copyCSS() }
                .shortcut(model.combo(.copyCSS))
        }
        CommandGroup(after: .sidebar) {
            Divider()
            Button("Switch Light / Soft Dark") { actions.toggleAppearance() }
                .shortcut(model.combo(.appearance))
            Picker("Appearance", selection: Binding(get: { model.appearance }, set: { model.appearance = $0 })) {
                Text("Follow System").tag(AppModel.Appearance.system)
                Text("Light").tag(AppModel.Appearance.light)
                Text("Soft Dark").tag(AppModel.Appearance.dark)
            }
            Divider()
            ForEach(Array(AppModel.Library.allCases.enumerated()), id: \.element) { i, section in
                Button(section.title) { model.sidebar = .library(section) }
                    .keyboardShortcut(KeyEquivalent(Character(String(i + 1))))
            }
        }
    }

    private var editingText: Bool {
        guard let window = NSApp.keyWindow else { return false }
        return window.firstResponder is NSText || window.attachedSheet != nil || window.isSheet
    }
}

/// The image on a pasteboard or in a drag. A file copied in Finder carries
/// both the file and its Finder icon: the file wins, so we read the photo,
/// not the JPG icon.
func pastedImage(_ pb: NSPasteboard) -> (NSImage, String?)? {
    if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
        for url in urls {
            if let image = NSImage(contentsOf: url) { return (image, url.deletingPathExtension().lastPathComponent) }
        }
        return nil   // files, but none of them an image: never fall back to their icons
    }
    return NSImage(pasteboard: pb).map { ($0, nil) }
}

/// The image in a drop: a file (named after the file) or image data. Calls
/// `failed` when the drop holds files but no image.
@discardableResult
func loadDroppedImage(_ providers: [NSItemProvider], failed: @escaping @MainActor @Sendable () -> Void = {},
                      _ done: @escaping @MainActor @Sendable (NSImage, String?) -> Void) -> Bool {
    guard let provider = providers.first else { return false }
    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url, let image = NSImage(contentsOf: url) else { Task { @MainActor in failed() }; return }
            let name = url.deletingPathExtension().lastPathComponent
            Task { @MainActor in done(image, name) }
        }
        return true
    }
    guard provider.canLoadObject(ofClass: NSImage.self) else { return false }
    _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
        guard let image = object as? NSImage else { Task { @MainActor in failed() }; return }
        Task { @MainActor in done(image, nil) }
    }
    return true
}

func copyToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}
