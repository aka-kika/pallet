import SwiftUI

struct SettingsView: View {
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
            Toggle("Show keyboard guide", isOn: Binding(get: { !model.hideKeyboardGuide }, set: { model.hideKeyboardGuide = !$0 }))
            Toggle("Add dropped images right away", isOn: $model.autoImportOnDrop)
            Text("Skips the Add image dialog. The Add image button still opens it.")
                .font(.caption).foregroundStyle(.secondary)
            TextField("Background lock", text: $lockField, prompt: Text("#F4F1EA"))
                .onSubmit {
                    if lockField.trimmingCharacters(in: .whitespaces).isEmpty { model.bgLock = nil } else if let hex = ColorMath.parseHex(lockField) { model.bgLock = hex }
                    lockField = model.bgLock ?? ""
                }
            Text("A hex color keeps the page background fixed while palettes change. Empty to unlock.")
                .font(.caption).foregroundStyle(.secondary)
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
