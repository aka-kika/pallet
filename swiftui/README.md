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

## Keys

Space shuffle, Left/Right main color, Up/Down palettes, L lock background, Cmd+C copy CSS, Cmd+V paste an image, Cmd+O add image, Cmd+E export.
