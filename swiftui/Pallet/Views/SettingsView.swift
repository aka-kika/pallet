import SwiftUI

/// Settings in tabs: General, Capture, Keyboard, About.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.settingsTab) {
            Tab("General", systemImage: "gearshape", value: AppModel.SettingsTab.general) { GeneralSettings() }
            Tab("Capture", systemImage: "viewfinder", value: AppModel.SettingsTab.capture) { CaptureSettings() }
            Tab("Keyboard", systemImage: "keyboard", value: AppModel.SettingsTab.keyboard) { KeyboardSettings() }
            Tab("About", systemImage: "info.circle", value: AppModel.SettingsTab.about) { AboutView() }
        }
        .frame(width: 460)
        .preferredColorScheme(model.colorScheme)
    }
}

struct GeneralSettings: View {
    @Environment(AppModel.self) private var model
    @State private var lockField = ""

    var body: some View {
        @Bindable var model = model
        Form {
            Picker("Appearance", selection: $model.appearance) {
                Text("Follow System").tag(AppModel.Appearance.system)
                Text("Light").tag(AppModel.Appearance.light)
                Text("Soft Dark").tag(AppModel.Appearance.dark)
            }
            .pickerStyle(.radioGroup)
            Toggle("Show Shuffle button", isOn: $model.showShuffleButton)
            Section {
                TextField("Background lock", text: $lockField, prompt: Text("#F4F1EA"))
                    .onSubmit {
                        if lockField.trimmingCharacters(in: .whitespaces).isEmpty { model.bgLock = nil } else if let hex = ColorMath.parseHex(lockField) { model.bgLock = hex }
                        lockField = model.bgLock ?? ""
                    }
            } footer: {
                Text("A hex color keeps the page background fixed while palettes change. Leave empty to unlock.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { lockField = model.bgLock ?? "" }
        .onChange(of: model.bgLock) { lockField = model.bgLock ?? "" }
    }
}

struct CaptureSettings: View {
    @Environment(AppModel.self) private var model
    @State private var openAtLogin = MenuBarController.shared?.launchAtLogin ?? false

    var body: some View {
        @Bindable var model = model
        Form {
            Picker("Show Pallet in", selection: $model.presence) {
                Text("Dock and menu bar").tag(AppModel.Presence.both)
                Text("Dock only").tag(AppModel.Presence.dock)
                Text("Menu bar only").tag(AppModel.Presence.menuBar)
            }
            Toggle("Open at login", isOn: $openAtLogin)
                .onChange(of: openAtLogin) { MenuBarController.shared?.launchAtLogin = openAtLogin }
            Section {
                Toggle("Save new palettes right away", isOn: $model.autoImportOnDrop)
                Toggle("Copy CSS after saving a capture", isOn: $model.copyCSSAfterCapture)
            } footer: {
                Text("Right away skips the review step for drops, pastes and captures. Undo still works. Shortcuts are in the Keyboard tab.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Click, then press the new shortcut. Esc cancels.
struct ShortcutRecorder: View {
    @Binding var shortcut: Shortcut?
    /// The other Pallet shortcut, which this one may not repeat.
    var other: Shortcut?
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(recording ? "Type shortcut..." : (shortcut?.display ?? "Record Shortcut")) {
                recording ? stop() : start()
            }
            .frame(minWidth: 120)
            if shortcut != nil && !recording {
                Button { shortcut = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
                    .buttonStyle(.plain)
                    .help("No shortcut")
            }
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        MenuBarController.shared?.setRecording(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { stop(); return nil }          // Esc
            if let new = Shortcut(event: event), new != other {
                shortcut = new
                stop()
            }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if recording { MenuBarController.shared?.setRecording(false) }
        recording = false
    }
}

/// Every shortcut, recordable: from any app, the menus, and the fixed keys
/// in the window.
struct KeyboardSettings: View {
    @Environment(AppModel.self) private var model
    static let fixed = [("Space", "Shuffle"), ("\u{2190} \u{2192}", "Change main color"), ("\u{2191} \u{2193}", "Next or previous palette"),
                        ("L", "Lock background"), ("\u{2318}C", "Copy CSS (or text)"), ("\u{2318}V", "Paste an image"),
                        ("\u{2318}\u{232B}", "Delete palette"), ("\u{2318}Z", "Undo"), ("\u{2318}1 to \u{2318}4", "Library sections")]

    var body: some View {
        @Bindable var model = model
        Form {
            Section("From any app") {
                LabeledContent("Capture area") { ShortcutRecorder(shortcut: $model.captureShortcut, other: model.panelShortcut) }
                if MenuBarController.shared?.shortcutAvailable == false { taken }
                LabeledContent("Open the menu bar panel") { ShortcutRecorder(shortcut: $model.panelShortcut, other: model.captureShortcut) }
                if MenuBarController.shared?.panelShortcutAvailable == false { taken }
            }
            Section {
                ForEach(AppCommand.allCases) { command in
                    LabeledContent(command.title) { AppShortcutRecorder(command: command) }
                }
            } header: {
                Text("In Pallet")
            } footer: {
                HStack {
                    Text("Click a shortcut, then press the new keys. Esc cancels.").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Restore Defaults") { model.resetCombos() }.controlSize(.small)
                }
            }
            Section("Fixed keys") {
                ForEach(Self.fixed, id: \.1) { key, label in
                    LabeledContent(label) { Text(key).font(.system(.body, design: .rounded)).foregroundStyle(.secondary) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 560)
    }

    private var taken: some View {
        Label("Another app uses this shortcut. Pick a different one.", systemImage: "exclamationmark.triangle")
            .font(.caption).foregroundStyle(.orange)
    }
}

/// Records a menu shortcut. Refuses one that another Pallet command uses.
struct AppShortcutRecorder: View {
    let command: AppCommand
    @Environment(AppModel.self) private var model
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(recording ? "Type shortcut..." : (model.combo(command)?.display ?? "None")) {
                recording ? stop() : start()
            }
            .frame(minWidth: 110)
            Button { model.setCombo(nil, for: command) } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
                .buttonStyle(.plain)
                .opacity(model.combo(command) != nil && !recording ? 1 : 0)
                .disabled(model.combo(command) == nil || recording)
                .help("No shortcut")
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { stop(); return nil }          // Esc
            if let new = KeyCombo(event: event),
               !AppCommand.allCases.contains(where: { $0 != command && model.combo($0) == new }) {
                model.setCombo(new, for: command)
                stop()
            }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recording = false
    }
}

/// Made by Kika, with only globe, X and GitHub icons.
struct AboutView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 104, height: 104)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("PALLET").tracking(1.2).fontWeight(.semibold)
                Text("/ by KIKA").tracking(0.6).foregroundStyle(.secondary)
            }
            .font(.system(size: 15))
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                .font(.caption).foregroundStyle(.secondary)
            Text("Made by Kika").font(.callout)
            HStack(spacing: 4) {
                link("globe", system: true, "https://akakika.com", "akakika.com")
                link("XLogo", system: false, "https://x.com/akakikaaa", "X")
                link("GitHubLogo", system: false, "https://github.com/aka-kika", "GitHub")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20).padding(.bottom, 24)
    }

    private func link(_ image: String, system: Bool, _ url: String, _ label: String) -> some View {
        Button { openURL(URL(string: url)!) } label: {
            Group {
                if system { Image(systemName: image).font(.system(size: 17)) } else { Image(image).resizable().scaledToFit().frame(width: 16, height: 16) }
            }
            .frame(width: 36, height: 36)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(label)
        .accessibilityLabel(label)
    }
}
