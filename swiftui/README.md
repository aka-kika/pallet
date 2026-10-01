# Pallet for Mac (SwiftUI)

The Mac app. It replaced the Electron app in `desktop/` on 2026-10-01 (installed as /Applications/Pallet.app, bundle id `com.akakika.pallet`, signed with Developer ID).

## Build and run

- Xcode 27.2+, macOS 26+. The project uses Xcode's JSON project format (`Pallet.xcodeproj/project.xcproj`).
- `xcodebuild -project swiftui/Pallet.xcodeproj -scheme Pallet build`
- Try things on a copy of the collection: launch with `-PalletDataDirectory /some/folder`.

## Shared with the web app

- Built-in palettes: `shared/builtin-palettes.json` (the web app imports the same file).
- Your collection: `~/Library/Application Support/Palette/palettes.json` and `hidden.json`, the format the web app and the old Electron app use. `collections.json` is Mac only. Unreadable files are copied aside and never overwritten; unknown entries are kept. Code: `Pallet/Model/Palette.swift`.
- Theme colors: `Pallet/Model/Theme.swift` is a line-by-line port of `lib/palettes.ts`. Rules: `docs/THEME-RULES.md`. Change both together.

## Image extraction

`Pallet/Extraction/PaletteExtractor.swift`, Apple frameworks only (Vision, CoreGraphics).

- Palette graphics: finds the flat swatch shapes and skips the page frame, text and any photo behind the cards. Printed hex codes are read with Vision and used as exact values. A big title becomes the name.
- Website and app screenshots: background, surface, text and accent colors.
- Photos: main colors, with a boost for colorful ones.
- Names: title in the image, then the file name, then Apple Intelligence (Foundation Models), then plain color words.

## Layout (Apple HIG)

- System frame: sidebar with search (All, Favorites, My Palettes, Starter), customizable toolbar (right-click it), standard menus, Undo for every change. Search sits in the sidebar: in the toolbar it crashes AppKit when the toolbar is customized (macOS 27.2).
- Pallet content: the palette-colored canvas, swatch strip, arrows and cards.

## Menu bar capture

- Menu bar icon or Option-Shift-Command-P: the panel (drop, paste or choose an image, Capture Area, recent palettes one click from their CSS). No drop on the icon itself: in macOS 26 dragging to the top edge opens the Spaces bar.
- Capture shortcut (default Shift-Command-P; both shortcuts set in Settings > Capture) picks any area of the screen from any app. The first capture asks for Screen Recording permission.
- Settings > Capture: show in Dock, menu bar or both; open at login; save right away; copy CSS after a capture.
- Code: `Pallet/MenuBar/` (AppKit status item and popover, Carbon hot key, `screencapture -i`).

## Code map

- `PalletApp.swift`: app, `AppModel` (UI state and preferences), `PaletteActions` (every change, with undo), menus.
- `Model/`: `Palette.swift` (store), `Theme.swift` (theme math, exports), `Collections.swift` (collections, color slider), `AppShortcuts.swift` (recordable shortcuts), `Naming.swift`.
- `Views/`: `ContentView.swift` (sidebar, canvas, toolbar), `Components.swift`, `ImportSheet.swift` (new palette, export), `SettingsView.swift`.
- `MenuBar/`: status item and panel, Carbon hot keys, screen capture.
- `Extraction/PaletteExtractor.swift`: Vision text reading and flat-region analysis.

## Keys

All in Settings > Keyboard, where the menu and global ones can be recorded. Defaults: Shift-Cmd-P capture area and Option-Shift-Cmd-P menu bar panel (from any app); Space shuffle, Left/Right or Cmd-[ ] main color, Up/Down palettes, L or Cmd-L lock, Cmd-C copy CSS, Cmd-V paste an image, Cmd-D favorite, Shift-Cmd-D light or soft dark, Cmd-O new from image, Shift-Cmd-N new collection, Cmd-E export, Cmd-Delete delete, Cmd-Z undo, Cmd-1 to 4 library sections.
