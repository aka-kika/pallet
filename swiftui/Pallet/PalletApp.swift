import SwiftUI
import UniformTypeIdentifiers

@main
struct PalletApp: App {
    @State private var store = PaletteStore()
    @State private var model = AppModel()

    var body: some Scene {
        Window("Pallet", id: "main") {
            ContentView()
                .environment(store)
                .environment(model)
        }
        .defaultSize(width: 1180, height: 860)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands { PalletCommands(store: store, model: model) }

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

    var selectedID: String { didSet { save("selected", selectedID) } }
    var appearance: Appearance { didSet { save("appearance", appearance.rawValue) } }
    var bgLock: String? { didSet { save("bgLock", bgLock) } }
    var hideKeyboardGuide: Bool { didSet { save("hideKeyboardGuide", hideKeyboardGuide) } }
    var autoImportOnDrop: Bool { didSet { save("autoImportOnDrop", autoImportOnDrop) } }
    var favoritesOnly = false

    var importing: ImportRequest?
    var exporting: Palette?
    var pendingDelete: Palette?
    var toast: Toast?

    init() {
        let d = UserDefaults.standard
        selectedID = d.string(forKey: "selected") ?? "seed-12"
        appearance = Appearance(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        bgLock = d.string(forKey: "bgLock").flatMap(ColorMath.parseHex)
        hideKeyboardGuide = d.bool(forKey: "hideKeyboardGuide")
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

struct PalletCommands: Commands {
    let store: PaletteStore
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Pallet") { openWindow(id: "about") }
        }
        CommandGroup(replacing: .newItem) {
            Button("Add Image...") { model.importing = ImportRequest() }
                .keyboardShortcut("o")
        }
        // Copy and Paste act on text fields when one is focused, otherwise
        // Copy takes the theme CSS and Paste takes an image, like the web app.
        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                if editingText { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) } else { copyCSS() }
            }
            .keyboardShortcut("c")
            Button("Paste") {
                if editingText { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) } else { pasteImage() }
            }
            .keyboardShortcut("v")
            Button("Select All") { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
                .keyboardShortcut("a")
        }
        CommandMenu("Palette") {
            Button("Copy CSS") { copyCSS() }
            Button("Export Theme...") { model.exporting = active }
                .keyboardShortcut("e")
            Divider()
            Button(model.bgLock == nil ? "Lock Background" : "Unlock Background") { toggleLock(model: model, store: store) }
            Button(model.favoritesOnly ? "Show All Palettes" : "Show Favorites") { model.favoritesOnly.toggle() }
            Divider()
            Button("Delete Palette...") { model.pendingDelete = active }
                .disabled(store.palettes.count <= 1)
        }
        CommandGroup(after: .toolbar) {
            Picker("Appearance", selection: Binding(get: { model.appearance }, set: { model.appearance = $0 })) {
                Text("Follow System").tag(AppModel.Appearance.system)
                Text("Light").tag(AppModel.Appearance.light)
                Text("Soft Dark").tag(AppModel.Appearance.dark)
            }
        }
    }

    private var active: Palette? { store.palettes.first { $0.id == model.selectedID } ?? store.palettes.first }

    private var editingText: Bool {
        guard let window = NSApp.keyWindow else { return false }
        return window.firstResponder is NSText || window.attachedSheet != nil || window.isSheet
    }

    private func copyCSS() {
        guard let p = active else { return }
        copyToPasteboard(ThemeExport.css(p))
        model.show("CSS copied", detail: "Light + soft dark, with the selected main color.")
    }

    private func pasteImage() {
        guard let image = NSImage(pasteboard: .general) else { return }
        model.importing = ImportRequest(image: image, fileName: nil)
    }
}

func copyToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}

@MainActor
func toggleLock(model: AppModel, store: PaletteStore) {
    if model.bgLock != nil { model.bgLock = nil; return }
    guard let p = store.palettes.first(where: { $0.id == model.selectedID }) ?? store.palettes.first else { return }
    let dark = model.appearance == .dark || (model.appearance == .system && NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    model.bgLock = Theme(p, dark: dark)["background"]
}
