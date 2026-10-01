# Pallet for Mac (SwiftUI)

The native Mac version of Pallet. The Electron app in `desktop/` stays the shipping app until this one matches it.

## Build and run

- Xcode 27.2+, macOS 26+. The project uses Xcode's JSON project format (`Pallet.xcodeproj/project.xcproj`).
- `xcodebuild -project swiftui/Pallet.xcodeproj -scheme Pallet build`
- Try things on a copy of the collection: launch with `-PalletDataDirectory /some/folder`.

## Shared with the web app

- Built-in palettes: `shared/builtin-palettes.json` (the web app imports the same file).
- Your collection: `~/Library/Application Support/Palette/palettes.json` and `hidden.json`, same format and rules as `desktop/store.cjs`. Changes from either app show up in the other.
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

- Menu bar icon: click for the panel (Capture Area, Paste Image, recent palettes one click from their CSS), or drop an image on the icon.
- Capture shortcut (default Shift-Command-P, set in Settings > Capture) picks any area of the screen from any app. The first capture asks for Screen Recording permission.
- Settings > Capture: show in Dock, menu bar or both; open at login; save right away; copy CSS after a capture.
- Code: `Pallet/MenuBar/` (AppKit status item and popover, Carbon hot key, `screencapture -i`).

## Keys

Listed in Settings > Keyboard. Space shuffle, Left/Right or Cmd+[ ] main color, Up/Down palettes, L lock, Cmd+C copy CSS, Cmd+V paste an image, Cmd+D favorite, Cmd+O new from image, Cmd+E export, Cmd+Delete delete, Cmd+Z undo, Cmd+1 to 4 sidebar.
