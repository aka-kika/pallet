import AppKit
import SwiftUI
import ServiceManagement

/// The menu bar icon and its panel. Click the icon or press the panel
/// shortcut for the panel (drop, paste or choose an image there), or press
/// the capture shortcut anywhere to pick an area of the screen. AppKit so the
/// panel can open by itself after a capture or a shortcut.
/// Dropping on the icon itself is left out on purpose: dragging to the top of
/// the screen opens the Spaces bar in macOS 26 and the icon never sees it.
@Observable
final class MenuBarController: NSObject, NSPopoverDelegate {
    enum Phase {
        case idle
        case working
        case result(CaptureResult)
        case failed(String)
        case needsPermission
    }

    struct CaptureResult {
        var image: NSImage
        var colors: [String]
        var name: String
        var kind: ExtractionResult.Kind
        var saved: Palette?
    }

    static var shared: MenuBarController?

    var phase: Phase = .idle
    /// False when another app already owns the capture shortcut.
    var shortcutAvailable = true
    @ObservationIgnored private var askedForPermission = false

    @ObservationIgnored let store: PaletteStore
    @ObservationIgnored let model: AppModel
    @ObservationIgnored let actions: PaletteActions
    @ObservationIgnored private var item: NSStatusItem?
    @ObservationIgnored private let popover = NSPopover()
    @ObservationIgnored private lazy var hotKey = HotKey { [weak self] in self?.captureArea() }
    @ObservationIgnored private lazy var panelHotKey = HotKey { [weak self] in self?.panelShortcutPressed() }
    /// False when another app already owns the panel shortcut.
    var panelShortcutAvailable = true

    init(store: PaletteStore, model: AppModel, actions: PaletteActions) {
        self.store = store
        self.model = model
        self.actions = actions
        super.init()
        popover.delegate = self
        // Stays open while you drag a file over from Finder; Esc or a click on
        // the icon closes it.
        popover.behavior = .semitransient
        popover.animates = true
        let host = NSHostingController(rootView: MenuBarPanel(controller: self)
            .environment(store).environment(model).environment(actions))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
    }

    /// Called once the app has launched, and again when the settings change.
    func apply() {
        switch model.presence {
        case .both, .menuBar: showIcon()
        case .dock: hideIcon()
        }
        NSApp.setActivationPolicy(model.presence == .menuBar ? .accessory : .regular)
        shortcutAvailable = hotKey.register(model.captureShortcut)
        panelShortcutAvailable = panelHotKey.register(model.panelShortcut)
    }

    /// While the shortcut recorder listens, the old shortcut must not fire.
    func setRecording(_ on: Bool) {
        if on {
            hotKey.unregister()
            panelHotKey.unregister()
        } else {
            shortcutAvailable = hotKey.register(model.captureShortcut)
            panelShortcutAvailable = panelHotKey.register(model.panelShortcut)
        }
    }

    private func showIcon() {
        guard item == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(named: "PalettMark") ?? NSImage(systemSymbolName: "swatchpalette", accessibilityDescription: nil)!
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            button.image = image
            button.setAccessibilityLabel("Pallet")
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.item = item
    }

    private func hideIcon() {
        if let item { NSStatusBar.system.removeStatusItem(item) }
        item = nil
        popover.performClose(nil)
    }

    /// A finished result is cleared when the panel closes; an unsaved one waits.
    func popoverDidClose(_ notification: Notification) {
        switch phase {
        case .result(let r) where r.saved == nil: break
        case .working: break
        default: phase = .idle
        }
    }

    @objc private func statusClicked() { toggle() }

    /// The panel shortcut: the panel when the menu bar icon is shown, the
    /// window otherwise.
    func panelShortcutPressed() {
        if item != nil { toggle() } else { openMain() }
    }

    func toggle() {
        if popover.isShown { popover.performClose(nil) } else { showPanel() }
    }

    func showPanel() {
        guard let button = item?.button else { return }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    // MARK: Capture

    /// The system area picker (Esc cancels); the picked area becomes a palette.
    func captureArea() {
        popover.performClose(nil)
        // Without Screen Recording the picker only sees the wallpaper. Ask once,
        // then explain instead of failing quietly.
        guard CGPreflightScreenCaptureAccess() else {
            // The system prompt only once per launch; after that, the panel explains.
            if !askedForPermission { askedForPermission = true; CGRequestScreenCaptureAccess() }
            phase = .needsPermission
            showPanel()
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pallet-capture-\(UUID().uuidString).png")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", url.path]
        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let image = NSImage(contentsOf: url) else { return }   // cancelled
                    try? FileManager.default.removeItem(at: url)
                    MenuBarController.shared?.take(image, name: nil)
                }
            }
        }
        do { try process.run() } catch { phase = .failed("Screen capture could not start."); showPanel() }
    }

    func chooseImage() {
        popover.performClose(nil)
        NSApp.activate()
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
        take(image, name: url.deletingPathExtension().lastPathComponent)
    }

    func pasteImage() {
        guard let (image, name) = pastedImage(.general) else { phase = .failed("No image on the clipboard. Copy an image or an image file first."); return }
        take(image, name: name)
    }

    /// Read an image's colors and show them in the panel (or in the main
    /// window when the menu bar icon is hidden).
    func take(_ image: NSImage, name: String?) {
        guard item != nil else {
            model.importing = ImportRequest(image: image, fileName: name)
            openMain()
            return
        }
        phase = .working
        showPanel()
        Task {
            do {
                let result = try await ImportSheet.extract(image)
                let title = await Naming.name(for: result, fileName: name)
                phase = .result(CaptureResult(image: image, colors: result.colors, name: title, kind: result.kind, saved: nil))
                if model.autoImportOnDrop { save() }
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func save() {
        guard case .result(var r) = phase, r.saved == nil else { return }
        let source = switch r.kind {
        case .paletteGraphic: "Palette image · swatches read from the image"
        case .interface: "Screenshot · interface colors"
        case .photo: "Photo · sampled colors"
        }
        let p = Palette(id: Palette.newID(), name: String(r.name.trimmingCharacters(in: .whitespaces).prefix(100)), colors: r.colors, main: 0, favorite: false, source: source)
        guard p.isValid else { phase = .failed("This palette could not be saved."); return }
        actions.add(p)
        if model.copyCSSAfterCapture { copyToPasteboard(ThemeExport.css(p)) }
        r.saved = p
        phase = .result(r)
    }

    func rename(_ name: String) {
        guard case .result(var r) = phase else { return }
        r.name = name
        phase = .result(r)
    }

    func removeColor(at i: Int) {
        guard case .result(var r) = phase, r.saved == nil, r.colors.count > 2 else { return }
        r.colors.remove(at: i)
        phase = .result(r)
    }

    func done() { phase = .idle }

    func openScreenRecordingSettings() {
        popover.performClose(nil)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    /// Screen Recording applies only to a fresh launch of the app.
    func relaunch() {
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    func openMain() {
        popover.performClose(nil)
        NSApp.activate()
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.hasPrefix("main") == true && $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            model.openMainWindow?()
        }
    }

    func openSettings(tab: AppModel.SettingsTab = .general) {
        popover.performClose(nil)
        model.settingsTab = tab
        NSApp.activate()
        model.openSettingsWindow?()
    }

    // MARK: Launch at login

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do { if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } } catch {}
        }
    }
}

/// Keeps the app running in the menu bar when the window closes, and brings
/// the window back when the Dock icon is clicked.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MenuBarController.shared?.apply()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { MenuBarController.shared?.openMain() }
        return true
    }
}
