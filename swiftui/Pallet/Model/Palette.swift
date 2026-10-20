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

/// One entry of a JSON list read as T. Only objects are tried: re-encoding a
/// bare string or number raises an exception and would crash the app.
nonisolated func decodeEntry<T: Decodable>(_ type: T.Type, from item: Any) -> T? {
    guard item is [String: Any], let data = try? JSONSerialization.data(withJSONObject: item) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}

/// The palette list in a collection file: a plain list, as palettes.json and
/// Export Collection write it, or {"palettes": [...]}, as exports before 2.0.3 did.
nonisolated func paletteEntries(_ root: Any) -> [Any]? {
    if let list = root as? [Any] { return list }
    return (root as? [String: Any])?["palettes"] as? [Any]
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
    /// Entries this app can't read, kept as they are, one list per file.
    @ObservationIgnored private var foreign: [Any] = []
    @ObservationIgnored private var hiddenForeign: [Any] = []
    @ObservationIgnored private var collectionsForeign: [Any] = []
    /// The objects as read, by id, so fields this app doesn't know survive a save.
    @ObservationIgnored private var rawPalettes: [String: [String: Any]] = [:]
    @ObservationIgnored private var rawCollections: [String: [String: Any]] = [:]
    private var hidden: [String] = []
    /// What the files hold as far as Pallet knows, so a change that could not
    /// be written to a locked file is reported instead of looking saved.
    @ObservationIgnored private var savedOnDisk: [Palette] = []
    @ObservationIgnored private var hiddenOnDisk: [String] = []
    /// Files that exist but could not be read. Pallet never writes these.
    private var locked: Set<String> = []
    /// Locked files with a copy kept aside, for the banner.
    @ObservationIgnored private var copied: Set<String> = []
    /// Modification date and size seen at the last load or write, so the
    /// watcher only reloads on real outside changes.
    private struct Stamp: Equatable { var date: Date; var size: Int }
    private var stamps: [String: Stamp] = [:]
    private var watcher: DispatchSourceFileSystemObject?
    @ObservationIgnored private var pendingReload: DispatchWorkItem?

    init(directory custom: URL? = nil) {
        let url = Bundle.main.url(forResource: "builtin-palettes", withExtension: "json")
        builtins = url.flatMap { try? JSONDecoder().decode([Palette].self, from: Data(contentsOf: $0)) } ?? []
        // Launch with -PalletDataDirectory <path> to try things on a copy of the collection.
        if let custom {
            directory = custom
        } else if let custom = UserDefaults.standard.string(forKey: "PalletDataDirectory") {
            directory = URL(fileURLWithPath: custom, isDirectory: true)
        } else {
            directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Palette", isDirectory: true)
        }
        load(settle: true)
        watch()
    }

    private var file: URL { directory.appendingPathComponent("palettes.json") }
    private var hiddenFile: URL { directory.appendingPathComponent("hidden.json") }
    private var collectionsFile: URL { directory.appendingPathComponent("collections.json") }
    private var files: [URL] { [file, hiddenFile, collectionsFile] }

    private enum Read {
        case missing, ok([Any]), unreadable
        var isUnreadable: Bool { if case .unreadable = self { true } else { false } }
    }

    private func readArray(_ url: URL, entries: (Any) -> [Any]? = { $0 as? [Any] }) -> Read {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url), let root = try? JSONSerialization.jsonObject(with: data),
              let list = entries(root) else { return .unreadable }
        return .ok(list)
    }

    /// `settle` is for launch, where the watcher's wait in reloadSoon doesn't
    /// help: a sync tool halfway through a save gets about 2 seconds to finish
    /// before a file that can't be read is locked.
    func load(settle: Bool = false) {
        func readAll() -> [Read] { [readArray(file, entries: paletteEntries), readArray(hiddenFile), readArray(collectionsFile)] }
        var reads = readAll()
        var tries = 0
        while settle && tries < 8 && reads.contains(where: \.isUnreadable) {
            Thread.sleep(forTimeInterval: 0.25)
            reads = readAll()
            tries += 1
        }
        locked = []
        saved = []
        foreign = []
        rawPalettes = [:]
        switch reads[0] {
        case .missing: break
        case .unreadable: lock(file)
        case .ok(let items):
            for item in items {
                if let p = decodeEntry(Palette.self, from: item), p.isValid,
                   !saved.contains(where: { $0.id == p.id }) {
                    saved.append(p)
                    rawPalettes[p.id] = item as? [String: Any]
                } else {
                    foreign.append(item)
                }
            }
        }
        hidden = []
        hiddenForeign = []
        switch reads[1] {
        case .ok(let items):
            for item in items {
                if let id = item as? String { hidden.append(id) } else { hiddenForeign.append(item) }
            }
        case .missing: break
        case .unreadable: lock(hiddenFile)
        }
        var list: [PaletteCollection] = []
        collectionsForeign = []
        rawCollections = [:]
        switch reads[2] {
        case .ok(let items):
            for item in items {
                if let c = decodeEntry(PaletteCollection.self, from: item),
                   !list.contains(where: { $0.id == c.id }) {
                    list.append(c)
                    rawCollections[c.id] = item as? [String: Any]
                } else {
                    collectionsForeign.append(item)
                }
            }
        case .missing: break
        case .unreadable: lock(collectionsFile)
        }
        collections = list
        savedOnDisk = saved
        hiddenOnDisk = hidden
        loadError = lockedMessage
        stamp()
        let order = Dictionary(uniqueKeysWithValues: builtins.enumerated().map { ($1.id, $0) })
        let all = builtins.filter { b in !saved.contains { $0.id == b.id } && !hidden.contains(b.id) } + saved
        palettes = all.enumerated().sorted { a, b in
            let oa = order[a.element.id] ?? 1000, ob = order[b.element.id] ?? 1000
            return oa != ob ? oa < ob : a.offset < b.offset
        }.map(\.element)
    }

    /// Keep a copy of a file that can't be read, and stop writing to it. A
    /// copy with the same contents from an earlier load or launch is enough.
    private func lock(_ url: URL) {
        locked.insert(url.path)
        guard let data = try? Data(contentsOf: url) else { copied.remove(url.path); return }
        let prefix = url.deletingPathExtension().lastPathComponent + ".unreadable-"
        let earlier = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        if earlier.contains(where: { $0.lastPathComponent.hasPrefix(prefix) && (try? Data(contentsOf: $0)) == data }) {
            copied.insert(url.path)
            return
        }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let copy = url.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
        if (try? data.write(to: copy, options: .withoutOverwriting)) != nil { copied.insert(url.path) } else { copied.remove(url.path) }
    }

    private var lockedMessage: String? {
        guard !locked.isEmpty else { return nil }
        let names = locked.map { URL(fileURLWithPath: $0).lastPathComponent }.sorted().joined(separator: ", ")
        let copy = locked.isSubset(of: copied)
            ? "A copy was saved next to it in \(directory.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))."
            : "Pallet could not save a copy of it, so keep one yourself before changing it."
        return "Pallet could not read \(names), so it will not change it, and changes to it are not saved. " + copy
    }

    func isBuiltIn(_ id: String) -> Bool { builtins.contains { $0.id == id } }

    /// The outcome of a change. Not saved: the change shows in the app, but a
    /// file it needs is locked or could not be written, so it is gone after a
    /// reload. Stale: it was made from an older copy of a file another app
    /// changed since, so the file was read again and nothing was written.
    enum Save { case saved, notSaved, invalid, stale }

    /// Add or replace a palette. `index` puts a restored palette back where it was.
    @discardableResult
    func put(_ p: Palette, at index: Int? = nil) -> Save {
        refreshIfChanged()
        guard apply(p, at: index) else { return .invalid }
        return write() ? .saved : .notSaved
    }

    /// Add or replace many palettes with one save. Returns how many were added
    /// and how many replaced an existing palette; invalid ones are skipped.
    func put(contentsOf list: [Palette]) -> (added: Int, replaced: Int, saved: Bool) {
        refreshIfChanged()
        var added = 0, replaced = 0
        for p in list where p.isValid {
            if palettes.contains(where: { $0.id == p.id }) { replaced += 1 } else { added += 1 }
            apply(p, at: nil)
        }
        return (added, replaced, write())
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

    @discardableResult
    func remove(_ id: String) -> Save {
        refreshIfChanged()
        guard palettes.count > 1 else { return .invalid }
        palettes.removeAll { $0.id == id }
        saved.removeAll { $0.id == id }
        if isBuiltIn(id) && !hidden.contains(id) { hidden.append(id) }
        return write() ? .saved : .notSaved
    }

    /// The whole collection, for undoing a batch change in one step.
    struct Snapshot { fileprivate var palettes: [Palette], saved: [Palette], hidden: [String] }
    func snapshot() -> Snapshot { Snapshot(palettes: palettes, saved: saved, hidden: hidden) }
    /// Put a snapshot back, unless the files changed outside Pallet since:
    /// writing it then would drop that change.
    @discardableResult
    func restore(_ s: Snapshot) -> Save {
        if refreshIfChanged() { return .stale }
        palettes = s.palettes
        saved = s.saved
        hidden = s.hidden
        return write() ? .saved : .notSaved
    }

    /// Save palettes.json and hidden.json. False when the change didn't reach
    /// the disk: a file it needs is locked, or the write failed.
    private func write() -> Bool {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if !locked.contains(file.path) {
                let own = try merged(saved, into: rawPalettes, id: \.id)
                try atomic(JSONSerialization.data(withJSONObject: own + foreign, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), to: file)
                savedOnDisk = saved
                stamp(file)
            }
            if !locked.contains(hiddenFile.path) {
                try atomic(JSONSerialization.data(withJSONObject: hidden + hiddenForeign, options: [.prettyPrinted, .withoutEscapingSlashes]), to: hiddenFile)
                hiddenOnDisk = hidden
                stamp(hiddenFile)
            }
            loadError = lockedMessage
            return saved == savedOnDisk && hidden == hiddenOnDisk
        } catch {
            loadError = "Changes not saved. Your change is still visible."
            return false
        }
    }

    /// Replace the whole list of collections and save it.
    @discardableResult
    func setCollections(_ list: [PaletteCollection]) -> Save {
        // The list was made from the collections as Pallet knew them: if
        // another app changed the file since, show its version instead.
        let changed = current(collectionsFile) != stamps[collectionsFile.path]
        refreshIfChanged()
        if changed {
            loadError = (lockedMessage.map { $0 + " " } ?? "") + "collections.json was changed outside Pallet and has been read again. Try your change again."
            return .stale
        }
        collections = list
        guard !locked.contains(collectionsFile.path) else { loadError = lockedMessage; return .notSaved }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let own = try merged(list, into: rawCollections, id: \.id)
            try atomic(JSONSerialization.data(withJSONObject: own + collectionsForeign, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), to: collectionsFile)
            stamp(collectionsFile)
            return .saved
        } catch {
            loadError = "Collections not saved. Your change is still visible."
            return .notSaved
        }
    }

    /// Each item as JSON, laid over the object it was read from, so fields
    /// this app doesn't know (written by a newer version or the web app) stay.
    private func merged<T: Encodable>(_ items: [T], into raw: [String: [String: Any]], id: (T) -> String) throws -> [Any] {
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(items)) as? [[String: Any]] ?? []
        return zip(items, encoded).map { item, own in
            raw[id(item)].map { $0.merging(own) { _, new in new } } ?? own
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

    private func current(_ url: URL) -> Stamp? {
        guard let a = try? FileManager.default.attributesOfItem(atPath: url.path), let date = a[.modificationDate] as? Date else { return nil }
        return Stamp(date: date, size: (a[.size] as? NSNumber)?.intValue ?? 0)
    }

    private func stamp() {
        stamps = Dictionary(uniqueKeysWithValues: files.compactMap { url in current(url).map { (url.path, $0) } })
    }

    /// Only a file just written: another one may have changed and not been read yet.
    private func stamp(_ url: URL) { stamps[url.path] = current(url) }

    /// Read the files again when something else changed them since Pallet
    /// last read or wrote them, so a change never writes over a sync's edit.
    /// Call it before building a change from the current palettes. A sync
    /// caught halfway gets the launch wait (about 2 s) to finish.
    @discardableResult
    func refreshIfChanged() -> Bool {
        guard files.contains(where: { current($0) != stamps[$0.path] }) else { return false }
        pendingReload?.cancel()
        load(settle: true)
        return true
    }

    /// Reload if one of the files changed since the last load or write, for
    /// edits made in place, which the folder watcher doesn't see.
    func recheck() {
        if files.contains(where: { current($0) != stamps[$0.path] }) { reloadSoon() }
    }

    /// A sync tool or editor may save in several steps (empty the file, then
    /// fill it; or delete it, then write a new one). Wait for the writes to
    /// settle, and give a file that looks half written or gone a few more
    /// tries before treating it as unreadable or deleted.
    private func reloadSoon(attempt: Int = 0) {
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                let changed = self.files.filter { self.current($0) != self.stamps[$0.path] }
                guard !changed.isEmpty else { return }
                let unsettled = changed.contains { url in
                    switch self.readArray(url) {
                    case .unreadable: true
                    case .missing: self.stamps[url.path] != nil   // was there before
                    case .ok: false
                    }
                }
                if unsettled && attempt < 4 { self.reloadSoon(attempt: attempt + 1); return }
                self.load()
            }
        }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 0 ? 0.3 : 0.6), execute: work)
    }

    /// Reload when something else (the web app's export, a sync, a hand edit)
    /// changes one of the files. Other files in the folder are ignored.
    private func watch() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.recheck() }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }
}
