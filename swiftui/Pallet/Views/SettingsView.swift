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
                LabeledContent("Capture shortcut") { ShortcutRecorder() }
                if MenuBarController.shared?.shortcutAvailable == false {
                    Label("Another app uses this shortcut. Pick a different one.", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
            } footer: {
                Text("Pick any area of the screen to turn it into a palette. The first capture asks for Screen Recording permission.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Toggle("Save new palettes right away", isOn: $model.autoImportOnDrop)
                Toggle("Copy CSS after saving a capture", isOn: $model.copyCSSAfterCapture)
            } footer: {
                Text("Right away skips the review step for drops, pastes and captures. Undo still works.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Click, then press the new shortcut. Esc cancels.
struct ShortcutRecorder: View {
    @Environment(AppModel.self) private var model
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(recording ? "Type shortcut..." : (model.captureShortcut?.display ?? "Record Shortcut")) {
                recording ? stop() : start()
            }
            .frame(minWidth: 120)
            if model.captureShortcut != nil && !recording {
                Button { model.captureShortcut = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
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
            if let shortcut = Shortcut(event: event) {
                model.captureShortcut = shortcut
                stop()
                return nil
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

struct KeyboardSettings: View {
    static let keys = [("Space  or  \u{2318}R", "Shuffle"), ("\u{2190} \u{2192}  or  \u{2318}[ \u{2318}]", "Change main color"), ("\u{2191} \u{2193}", "Next or previous palette"),
                       ("L  or  \u{2318}L", "Lock background"), ("\u{2318}C", "Copy CSS"), ("\u{2318}V", "Paste an image"),
                       ("\u{2318}D", "Add to Favorites"), ("\u{2318}O", "New palette from image"), ("\u{21E7}\u{2318}N", "New collection"),
                       ("\u{2318}E", "Export theme"), ("\u{2318}\u{232B}", "Delete palette"), ("\u{2318}Z", "Undo"), ("\u{2318}1 to \u{2318}4", "Library sections")]

    var body: some View {
        Form {
            ForEach(Self.keys, id: \.1) { key, label in
                LabeledContent(label) { Text(key).font(.system(.body, design: .rounded)).foregroundStyle(.secondary) }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
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
