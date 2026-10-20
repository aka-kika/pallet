import AppKit
import Carbon.HIToolbox

// Checks for the collection store and the global shortcuts. They run on
// throwaway folders in the temp directory, never on the real collection.
// Run with swiftui/Tests/run.sh.

var failures = 0
var made: [URL] = []

func check(_ ok: Bool, _ what: String, line: Int = #line) {
    if ok { print("  ok   \(what)") } else { failures += 1; print("  FAIL \(what) (line \(line))") }
}

func folder() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("pallet-tests-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    made.append(url)
    return url
}

func palette(_ name: String) -> Palette {
    Palette(id: Palette.newID(), name: name, colors: ["#112233", "#AABBCC"], main: 0, favorite: false, source: "test")
}

func text(_ url: URL) -> String { (try? String(contentsOf: url, encoding: .utf8)) ?? "" }

func copies(in dir: URL) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []).filter { $0.contains("unreadable") }
}

let valid = """
[{"id": "palette-one", "name": "One", "colors": ["#112233", "#445566"], "main": 0, "favorite": false, "source": "test"}]
"""

print("Saving while palettes.json is locked")
do {
    let dir = folder()
    let file = dir.appendingPathComponent("palettes.json")
    try! "{ not json".write(to: file, atomically: true, encoding: .utf8)
    let store = PaletteStore(directory: dir)
    check(store.loadError != nil, "a file that can't be read shows the banner")
    check(store.put(palette("Locked")) == .notSaved, "put reports not saved")
    check(text(file) == "{ not json", "the locked file is left as it was")
    check(store.put(contentsOf: [palette("Batch")]).saved == false, "a batch put reports not saved")
    check(store.remove(store.palettes[0].id) == .notSaved, "remove reports not saved")
    check(store.setCollections([PaletteCollection(id: "c1", name: "C", paletteIDs: [])]) == .saved, "collections.json is not locked, so collections save")
    check(store.loadError?.contains("not saved") == true, "the banner says changes are not saved")
}

print("Saving normally")
do {
    let dir = folder()
    let store = PaletteStore(directory: dir)
    let p = palette("Fine")
    check(store.put(p) == .saved, "put reports saved")
    check(text(dir.appendingPathComponent("palettes.json")).contains(p.id), "the palette is in the file")
    check(store.put(palette("Second")) == .saved && store.remove(p.id) == .saved, "remove reports saved")
    var bad = p
    bad.colors = ["#112233"]
    check(store.put(bad) == .invalid, "an invalid palette is refused")
    check(store.loadError == nil, "no banner")
}

print("A sync changes the files while Pallet is open")
do {
    let dir = folder()
    let file = dir.appendingPathComponent("palettes.json")
    let store = PaletteStore(directory: dir)
    let mine = palette("Mine")
    store.put(mine)
    // Another Mac adds a palette; the watcher hasn't reloaded yet.
    var list = try! JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [Any]
    list.append(try! JSONSerialization.jsonObject(with: JSONEncoder().encode(palette("From Sync"))))
    try! JSONSerialization.data(withJSONObject: list).write(to: file)
    check(store.put(palette("Next")) == .saved, "the next save works")
    let names = text(file)
    check(names.contains("From Sync") && names.contains("Mine") && names.contains("Next"), "and keeps the palette the sync added")
    let collections = dir.appendingPathComponent("collections.json")
    try! #"[{"id": "c-sync", "name": "Synced", "paletteIDs": []}]"#.write(to: collections, atomically: true, encoding: .utf8)
    check(store.setCollections([PaletteCollection(id: "c-mine", name: "Mine", paletteIDs: [])]) == .stale, "a collection change made from an old list is refused")
    check(store.collections.map(\.id) == ["c-sync"] && text(collections).contains("c-sync"), "the synced collections stay and show")

    // An undo of a batch change (a snapshot) after a sync.
    let before = store.snapshot()
    store.put(palette("Imported"))
    try! JSONSerialization.data(withJSONObject: (try! JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [Any])
        + [try! JSONSerialization.jsonObject(with: JSONEncoder().encode(palette("Second Sync")))]).write(to: file)
    check(store.restore(before) == .stale, "putting a snapshot back after a sync is refused")
    check(text(file).contains("Second Sync") && store.palettes.contains { $0.name == "Second Sync" }, "and the sync's palette stays")
    check(store.restore(store.snapshot()) == .saved, "with nothing changed outside, a snapshot goes back")
}

print("Only hidden.json locked")
do {
    let dir = folder()
    try! "{ not json".write(to: dir.appendingPathComponent("hidden.json"), atomically: true, encoding: .utf8)
    let store = PaletteStore(directory: dir)
    check(store.put(palette("Own")) == .saved, "a new palette still saves, it doesn't need hidden.json")
}

print("Locked collections.json")
do {
    let dir = folder()
    try! "{ not json".write(to: dir.appendingPathComponent("collections.json"), atomically: true, encoding: .utf8)
    let store = PaletteStore(directory: dir)
    check(store.setCollections([PaletteCollection(id: "c1", name: "C", paletteIDs: [])]) == .notSaved, "setCollections reports not saved")
}

print("A half-written file at launch")
do {
    let dir = folder()
    let file = dir.appendingPathComponent("palettes.json")
    try! "[{\"id\": \"palette-one\", \"na".write(to: file, atomically: true, encoding: .utf8)
    // A sync tool finishes its save half a second later.
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { try! valid.write(to: file, atomically: true, encoding: .utf8) }
    let store = PaletteStore(directory: dir)
    check(store.loadError == nil, "no lock once the save finishes")
    check(store.palettes.contains { $0.id == "palette-one" }, "the palettes are read")
    check(copies(in: dir).isEmpty, "no unreadable copy")
    check(store.put(palette("After")) == .saved && text(file).contains("palette-one"), "saving keeps the palettes from the file")
}

print("A file that stays broken at launch")
do {
    let dir = folder()
    try! "{ not json".write(to: dir.appendingPathComponent("palettes.json"), atomically: true, encoding: .utf8)
    let start = Date()
    let store = PaletteStore(directory: dir)
    let waited = Date().timeIntervalSince(start)
    check(store.loadError != nil, "it is locked")
    check(waited > 1.5 && waited < 3.5, "after about 2 seconds (\(String(format: "%.1f", waited)) s)")
    check(copies(in: dir).count == 1, "one copy is kept")
    store.load()
    _ = PaletteStore(directory: dir)
    check(copies(in: dir).count == 1, "a reload or a second launch adds no second copy")
}

print("No room for the copy")
do {
    let dir = folder()
    try! "{ not json".write(to: dir.appendingPathComponent("palettes.json"), atomically: true, encoding: .utf8)
    try! FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dir.path)
    let store = PaletteStore(directory: dir)
    try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
    check(copies(in: dir).isEmpty, "the copy could not be written")
    check(store.loadError?.contains("could not save a copy") == true, "the banner doesn't claim a copy")
}

print("Reserved global shortcuts")
func key(_ code: Int, _ mods: Int) -> Shortcut { Shortcut(keyCode: UInt32(code), modifiers: UInt32(mods)) }
for (code, name) in [(kVK_ANSI_Q, "Q"), (kVK_ANSI_C, "C"), (kVK_ANSI_V, "V"), (kVK_ANSI_W, "W"), (kVK_ANSI_Z, "Z"), (kVK_ANSI_Comma, ",")] {
    check(key(code, cmdKey).isReserved, "Cmd-\(name) is reserved")
}
check(key(kVK_ANSI_Z, cmdKey | shiftKey).isReserved, "Shift-Cmd-Z (Redo) is reserved")
check(key(kVK_Delete, cmdKey).isReserved, "Cmd-Delete is reserved")
check(!Shortcut.standard.isReserved && !Shortcut.panelStandard.isReserved, "the two defaults are free")
check(!key(kVK_ANSI_Q, cmdKey | optionKey).isReserved, "Option-Cmd-Q is free")
check(!key(kVK_ANSI_C, controlKey).isReserved, "Control-C is free")

func event(_ code: Int, _ chars: String, _ flags: NSEvent.ModifierFlags) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
                     characters: chars, charactersIgnoringModifiers: chars, isARepeat: false, keyCode: UInt16(code))!
}
check(Shortcut(event: event(kVK_ANSI_Q, "q", .command)) == nil, "the recorder refuses Cmd-Q")
check(Shortcut(event: event(kVK_ANSI_V, "v", .command)) == nil, "the recorder refuses Cmd-V")
check(Shortcut(event: event(kVK_ANSI_P, "p", [.command, .shift])) == .standard, "the recorder takes Shift-Cmd-P")

print("Stored global shortcuts")
// A dictionary stands in for UserDefaults, which drops a key set to nil the same way.
var prefs: [String: Any] = [:]
check(Shortcut.stored(prefs["captureShortcut"], default: .standard) == .standard, "never set: the default")
prefs["captureShortcut"] = Shortcut.storable(nil)
check(Shortcut.stored(prefs["captureShortcut"], default: .standard) == nil, "cleared: stays cleared")
let custom = key(kVK_ANSI_K, cmdKey | optionKey)
prefs["captureShortcut"] = Shortcut.storable(custom)
check(Shortcut.stored(prefs["captureShortcut"], default: .standard) == custom, "a recorded one comes back")
prefs["captureShortcut"] = Shortcut.storable(key(kVK_ANSI_Q, cmdKey))
check(Shortcut.stored(prefs["captureShortcut"], default: .standard) == .standard, "a stored Cmd-Q goes back to the default")

print("What's new")
let notesURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../docs/release-notes/2.0.4.md")
let lines = WhatsNew.parse(text(notesURL))
check(lines.first == .heading("Fixes in 2.0.4 (the 20 October code review)"), "the notes start with their heading, not the install line")
check(lines.dropFirst().allSatisfy { if case .bullet = $0 { true } else { false } } && lines.count > 5, "then the bullets")

for url in made { try? FileManager.default.removeItem(at: url) }

print(failures == 0 ? "\nAll checks passed." : "\n\(failures) check(s) failed.")
exit(failures == 0 ? 0 : 1)
