import Foundation

nonisolated struct Palette: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var colors: [String]
    var main: Int
    var favorite: Bool
    var source: String

    var mainColor: String { colors.indices.contains(main) ? colors[main] : colors[0] }

    /// Same rules as validPalette() in lib/palettes.ts.
    var isValid: Bool {
        id.range(of: #"^[\w-]{1,80}$"#, options: .regularExpression) != nil
            && !name.trimmingCharacters(in: .whitespaces).isEmpty && name.count <= 100
            && (2...10).contains(colors.count)
            && colors.allSatisfy { $0.range(of: #"^#[0-9A-Fa-f]{6}$"#, options: .regularExpression) != nil }
            && colors.indices.contains(main) && source.count < 300
    }

    static func newID() -> String {
        "palette-" + (0..<16).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
    }
}

extension JSONEncoder {
    nonisolated static var pallet: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return e
    }
}

/// The collection, shared with the Electron app: built-in palettes from
/// shared/builtin-palettes.json, the user's own in
/// ~/Library/Application Support/Palette/palettes.json, deleted built-ins in hidden.json.
/// Mirrors desktop/store.cjs so both apps can run on the same files.
@Observable
final class PaletteStore {
    private(set) var palettes: [Palette] = []
    var loadError: String?

    private let builtins: [Palette]
    private let directory: URL
    private var saved: [Palette] = []
    private var hidden: [String] = []
    private var watcher: DispatchSourceFileSystemObject?
    private var lastWrite = Date.distantPast

    init() {
        let url = Bundle.main.url(forResource: "builtin-palettes", withExtension: "json")
        builtins = url.flatMap { try? JSONDecoder().decode([Palette].self, from: Data(contentsOf: $0)) } ?? []
        // Launch with -PalletDataDirectory <path> to try things on a copy of the collection.
        if let custom = UserDefaults.standard.string(forKey: "PalletDataDirectory") {
            directory = URL(fileURLWithPath: custom, isDirectory: true)
        } else {
            directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Palette", isDirectory: true)
        }
        load()
        watch()
    }

    private var file: URL { directory.appendingPathComponent("palettes.json") }
    private var hiddenFile: URL { directory.appendingPathComponent("hidden.json") }

    func load() {
        do {
            if let data = try? Data(contentsOf: file) {
                saved = try JSONDecoder().decode([Palette].self, from: data).filter(\.isValid)
            } else {
                saved = []
            }
            hidden = (try? JSONDecoder().decode([String].self, from: Data(contentsOf: hiddenFile))) ?? []
            loadError = nil
        } catch {
            loadError = "Your saved collection could not be read. Showing starter palettes."
        }
        let order = Dictionary(uniqueKeysWithValues: builtins.enumerated().map { ($1.id, $0) })
        let all = builtins.filter { b in !saved.contains { $0.id == b.id } && !hidden.contains(b.id) } + saved
        palettes = all.enumerated().sorted { a, b in
            let oa = order[a.element.id] ?? 1000, ob = order[b.element.id] ?? 1000
            return oa != ob ? oa < ob : a.offset < b.offset
        }.map(\.element)
    }

    func put(_ p: Palette) {
        guard p.isValid else { return }
        if let i = palettes.firstIndex(where: { $0.id == p.id }) { palettes[i] = p } else { palettes.append(p) }
        saved = saved.filter { $0.id != p.id } + [p]
        hidden.removeAll { $0 == p.id }
        write()
    }

    func remove(_ id: String) {
        guard palettes.count > 1 else { return }
        palettes.removeAll { $0.id == id }
        saved.removeAll { $0.id == id }
        if !hidden.contains(id) { hidden.append(id) }
        write()
    }

    private func write() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            lastWrite = Date()
            try atomic(JSONEncoder.pallet.encode(saved), to: file)
            try atomic(JSONEncoder.pallet.encode(hidden), to: hiddenFile)
            loadError = nil
        } catch {
            loadError = "Changes not saved. Your change is still visible."
        }
    }

    private func atomic(_ data: Data, to url: URL) throws {
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: tmp.path)
        guard rename(tmp.path, url.path) == 0 else { throw CocoaError(.fileWriteUnknown) }
    }

    /// Reload when the Electron app (or anything else) changes the files.
    private func watch() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self, Date().timeIntervalSince(self.lastWrite) > 1 else { return }
                self.load()
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }
}
