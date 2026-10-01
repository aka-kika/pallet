import Foundation

nonisolated struct Palette: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var colors: [String]
    var main: Int
    var favorite: Bool
    var source: String

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

/// The collection: built-in palettes from shared/builtin-palettes.json, the
/// user's own in ~/Library/Application Support/Palette/palettes.json, deleted
/// built-ins in hidden.json, collections in collections.json. The file format
/// is the one the web app and the old Electron app use.
///
/// Safety rules: an entry this app can't read is kept and written back as it
/// was; a file that exists but can't be read at all is copied aside and never
/// written over.
@Observable
final class PaletteStore {
    private(set) var palettes: [Palette] = []
    private(set) var collections: [PaletteCollection] = []
    var loadError: String?

    private let builtins: [Palette]
    private let directory: URL
    private var saved: [Palette] = []
    /// palettes.json entries this app can't read, kept as they are.
    @ObservationIgnored private var foreign: [Any] = []
    private var hidden: [String] = []
    /// Files that exist but could not be read. Pallet never writes these.
    private var locked: Set<String> = []
    /// Modification dates seen at the last load or write, so the watcher only
    /// reloads on real outside changes.
    private var stamps: [String: Date] = [:]
    private var watcher: DispatchSourceFileSystemObject?

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
    private var collectionsFile: URL { directory.appendingPathComponent("collections.json") }
    private var files: [URL] { [file, hiddenFile, collectionsFile] }

    private enum Read { case missing, ok([Any]), unreadable }

    private func readArray(_ url: URL) -> Read {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url), let list = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return .unreadable }
        return .ok(list)
    }

    func load() {
        locked = []
        saved = []
        foreign = []
        switch readArray(file) {
        case .missing: break
        case .unreadable: lock(file)
        case .ok(let items):
            for item in items {
                if let data = try? JSONSerialization.data(withJSONObject: item),
                   let p = try? JSONDecoder().decode(Palette.self, from: data), p.isValid,
                   !saved.contains(where: { $0.id == p.id }) {
                    saved.append(p)
                } else {
                    foreign.append(item)
                }
            }
        }
        switch readArray(hiddenFile) {
        case .ok(let items): hidden = items.compactMap { $0 as? String }
        case .missing: hidden = []
        case .unreadable: hidden = []; lock(hiddenFile)
        }
        switch readArray(collectionsFile) {
        case .ok(let items):
            collections = items.compactMap { item in
                (try? JSONSerialization.data(withJSONObject: item)).flatMap { try? JSONDecoder().decode(PaletteCollection.self, from: $0) }
            }
        case .missing: collections = []
        case .unreadable: collections = []; lock(collectionsFile)
        }
        loadError = lockedMessage
        stamp()
        let order = Dictionary(uniqueKeysWithValues: builtins.enumerated().map { ($1.id, $0) })
        let all = builtins.filter { b in !saved.contains { $0.id == b.id } && !hidden.contains(b.id) } + saved
        palettes = all.enumerated().sorted { a, b in
            let oa = order[a.element.id] ?? 1000, ob = order[b.element.id] ?? 1000
            return oa != ob ? oa < ob : a.offset < b.offset
        }.map(\.element)
    }

    /// Keep a copy of a file that can't be read, and stop writing to it.
    private func lock(_ url: URL) {
        locked.insert(url.path)
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let copy = url.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
        try? FileManager.default.copyItem(at: url, to: copy)
    }

    private var lockedMessage: String? {
        guard !locked.isEmpty else { return nil }
        let names = locked.map { URL(fileURLWithPath: $0).lastPathComponent }.sorted().joined(separator: ", ")
        return "Pallet could not read \(names), so it will not change it. A copy was saved next to it in ~/Library/Application Support/Palette."
    }

    func isBuiltIn(_ id: String) -> Bool { builtins.contains { $0.id == id } }

    /// Add or replace a palette. `index` puts a restored palette back where it
    /// was. Returns false when the palette is not valid.
    @discardableResult
    func put(_ p: Palette, at index: Int? = nil) -> Bool {
        guard apply(p, at: index) else { return false }
        write()
        return true
    }

    /// Add or replace many palettes with one save. Returns how many were added
    /// and how many replaced an existing palette; invalid ones are skipped.
    func put(contentsOf list: [Palette]) -> (added: Int, replaced: Int) {
        var added = 0, replaced = 0
        for p in list where p.isValid {
            if palettes.contains(where: { $0.id == p.id }) { replaced += 1 } else { added += 1 }
            apply(p, at: nil)
        }
        write()
        return (added, replaced)
    }

    @discardableResult
    private func apply(_ p: Palette, at index: Int?) -> Bool {
        guard p.isValid else { return false }
        if let i = palettes.firstIndex(where: { $0.id == p.id }) {
            palettes[i] = p
        } else if let index, index <= palettes.count {
            palettes.insert(p, at: index)
        } else {
            palettes.append(p)
        }
        if let builtin = builtins.first(where: { $0.id == p.id }), builtin == p {
            saved.removeAll { $0.id == p.id }          // an untouched starter needs no copy
        } else if let i = saved.firstIndex(where: { $0.id == p.id }) {
            saved[i] = p                               // keep its place in the file
        } else {
            saved.append(p)
        }
        hidden.removeAll { $0 == p.id }
        return true
    }

    func remove(_ id: String) {
        guard palettes.count > 1 else { return }
        palettes.removeAll { $0.id == id }
        saved.removeAll { $0.id == id }
        if isBuiltIn(id) && !hidden.contains(id) { hidden.append(id) }
        write()
    }

    /// The whole collection, for undoing a batch change in one step.
    struct Snapshot { fileprivate var palettes: [Palette], saved: [Palette], hidden: [String] }
    func snapshot() -> Snapshot { Snapshot(palettes: palettes, saved: saved, hidden: hidden) }
    func restore(_ s: Snapshot) {
        palettes = s.palettes
        saved = s.saved
        hidden = s.hidden
        write()
    }

    private func write() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if !locked.contains(file.path) {
                let own = try JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [Any] ?? []
                try atomic(JSONSerialization.data(withJSONObject: own + foreign, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), to: file)
            }
            if !locked.contains(hiddenFile.path) { try atomic(JSONEncoder.pallet.encode(hidden), to: hiddenFile) }
            stamp()
            loadError = lockedMessage
        } catch {
            loadError = "Changes not saved. Your change is still visible."
        }
    }

    /// Replace the whole list of collections and save it.
    func setCollections(_ list: [PaletteCollection]) {
        collections = list
        guard !locked.contains(collectionsFile.path) else { loadError = lockedMessage; return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try atomic(JSONEncoder.pallet.encode(list), to: collectionsFile)
            stamp()
        } catch {
            loadError = "Collections not saved. Your change is still visible."
        }
    }

    private func atomic(_ data: Data, to url: URL) throws {
        let tmp = url.appendingPathExtension("\(UUID().uuidString).tmp")
        try data.write(to: tmp)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: tmp.path)
        guard rename(tmp.path, url.path) == 0 else {
            try? FileManager.default.removeItem(at: tmp)
            throw CocoaError(.fileWriteUnknown)
        }
    }

    private func modified(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    private func stamp() {
        stamps = Dictionary(uniqueKeysWithValues: files.compactMap { url in modified(url).map { (url.path, $0) } })
    }

    /// Reload when something else (the web app's export, a sync, a hand edit)
    /// changes one of the files. Other files in the folder are ignored.
    private func watch() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                let changed = self.files.contains { self.modified($0) != self.stamps[$0.path] }
                if changed { self.load() }
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }
}
