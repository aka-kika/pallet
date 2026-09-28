import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    static let keys = [("Space  or  \u{2318}R", "Shuffle"), ("\u{2190} \u{2192}  or  \u{2318}[ \u{2318}]", "Change main color"), ("\u{2191} \u{2193}", "Next or previous palette"),
                       ("L  or  \u{2318}L", "Lock background"), ("\u{2318}C", "Copy CSS"), ("\u{2318}V", "Paste an image"),
                       ("\u{2318}D", "Add to Favorites"), ("\u{2318}O", "New palette from image"),
                       ("\u{2318}E", "Export theme"), ("\u{2318}\u{232B}", "Delete palette"), ("\u{2318}Z", "Undo"), ("\u{2318}1 to \u{2318}4", "Sidebar sections")]
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
            Toggle("Add dropped images right away", isOn: $model.autoImportOnDrop)
            Text("Skips the New Palette window. The New button still opens it.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("Background lock", text: $lockField, prompt: Text("#F4F1EA"))
                .onSubmit {
                    if lockField.trimmingCharacters(in: .whitespaces).isEmpty { model.bgLock = nil } else if let hex = ColorMath.parseHex(lockField) { model.bgLock = hex }
                    lockField = model.bgLock ?? ""
                }
            Text("A hex color keeps the page background fixed while palettes change. Empty to unlock.")
                .font(.caption).foregroundStyle(.secondary)
            Section("Keyboard") {
                ForEach(Self.keys, id: \.0) { key, label in
                    LabeledContent(label) { Text(key).font(.system(.body, design: .rounded)).foregroundStyle(.secondary) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .preferredColorScheme(model.colorScheme)
        .onAppear { lockField = model.bgLock ?? "" }
        .onChange(of: model.bgLock) { lockField = model.bgLock ?? "" }
    }
}

/// Made by Kika, with only globe, X and GitHub links.
struct AboutView: View {
    @Environment(\.openURL) private var openURL
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 112, height: 112)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("PALLET").tracking(1.2).fontWeight(.semibold)
                Text("/ by KIKA").tracking(0.6).foregroundStyle(.secondary)
            }
            .font(.system(size: 15))
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                .font(.caption).foregroundStyle(.secondary)
            Text("Made by Kika").font(.callout)
            HStack(spacing: 6) {
                link("globe", system: true, "https://akakika.com", "akakika.com")
                link("XLogo", system: false, "https://x.com/akakikaaa", "X")
                link("GitHubLogo", system: false, "https://github.com/aka-kika", "GitHub")
            }
        }
        .padding(.horizontal, 48).padding(.top, 28).padding(.bottom, 22)
        .frame(width: 300)
        .preferredColorScheme(model.colorScheme)
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
