<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Pallet app icon: three color cards, pale, citron, and slate, fanned on a dark slate plate">
</p>

# Pallet

[![macOS](https://img.shields.io/badge/macOS-26%2B-111318?style=flat-square)](https://github.com/aka-kika/pallet)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-native-F05138?style=flat-square&logo=swift&logoColor=white)](swiftui/README.md)
[![data](https://img.shields.io/badge/data-on%20this%20device-367749?style=flat-square)](docs/mac.md)
[![version](https://img.shields.io/badge/version-2.0-3B82F6?style=flat-square)](https://github.com/aka-kika/pallet/releases/latest)
[![notarized](https://img.shields.io/badge/Developer%20ID-notarized-367749?style=flat-square)](docs/mac.md)
[![license](https://img.shields.io/badge/license-MIT-111318?style=flat-square)](LICENSE)

Pallet is a Mac app for collecting color palettes from images and the screen. Drop a picture, paste one, or capture any area of the screen: Pallet reads the real palette on this device and gives you light and soft-dark CSS. Nothing is uploaded.

<p align="center">
  <img src="docs/screenshots/main-light.png" alt="Pallet for Mac in light mode: a sidebar with the library and a color slider, the selected palette Deep Earth and Sky on top and palette cards below, tinted by the palette" width="49%">
  <img src="docs/screenshots/main-dark.png" alt="Pallet for Mac in soft dark mode with the Soft Earth Tones palette selected" width="49%">
</p>

## Features

- **Smart extraction.** Palette graphics give only their swatches: no page frame, no text color, no photo behind the cards. Printed hex codes are read exactly, and a title becomes the name. Website screenshots give the site's background, surface, text and accent colors. Photos give their main colors.
- **Menu bar capture.** Pick any area of the screen from any app (Shift-Command-P), or open the menu bar panel (Option-Shift-Command-P) to drop or paste an image.
- **Theme that follows the palette.** The whole canvas recolors from the selected palette; left and right arrows change its main color. Every text color stays readable ([theme rules](docs/THEME-RULES.md)).
- **Library and collections.** All, Favorites, My Palettes, Starter Palettes, your own collections, search by name or color, and a color slider that keeps palettes with a chosen color.
- **Copy and export.** Copy one hex or the light and dark CSS, export CSS, Markdown or JSON, share or drag a palette out as a .css file.
- **A real Mac app.** Sidebar, customizable toolbar, undo for every change, recordable shortcuts, Dock and menu bar options.

## Menu bar capture

<p>
  <img src="docs/screenshots/menu-bar.png" alt="The Pallet menu bar panel: a drop area, Capture Area and Paste buttons, and recent palettes with Copy CSS" width="300">
  <img src="docs/screenshots/menu-bar-result.png" alt="The panel after a capture: five colors read from a palette card, a name field, and Save" width="300">
</p>

## New palette from an image

The colors come straight from the swatches; the tulip photo behind the cards is skipped.

<img src="docs/screenshots/new-palette.png" alt="New Palette from Image: a palette card over a tulip field gives exactly its five swatch colors, named Tulip" width="760">

## Color slider

<img src="docs/screenshots/color-slider.png" alt="The color slider set to blue keeps only palettes with a blue color, closest first" width="760">

## Install

Download **[Pallet 2.0](https://github.com/aka-kika/pallet/releases/latest)** (macOS 26 or newer), unzip, and move Pallet.app to Applications. It is signed with Developer ID and notarized by Apple. What changed: [CHANGELOG.md](CHANGELOG.md).

## Build

Build with Xcode 27.2 or newer on macOS 26 or newer. See **[docs/mac.md](docs/mac.md)**.

```sh
xcodebuild -project swiftui/Pallet.xcodeproj -scheme Pallet -configuration Release build
```

Your palettes live in `~/Library/Application Support/Palette/`.

## Web version

The same app runs as a web page at **[akakika.com/pallet](https://akakika.com/pallet/)**, with Kika's collection and a download button. Visitors' own palettes stay in their browser.

```sh
pnpm install --frozen-lockfile
pnpm run dev            # local preview (Next.js)
pnpm site:build         # static build into the akakika.com repo (public/pallet/)
pnpm site:publish       # copy the Mac collection (names and colors) to the site, commit, push
```

Built-in palettes are shared in `shared/builtin-palettes.json`; `lib/palettes.ts` and `swiftui/Pallet/Model/Theme.swift` compute the same theme.

## Docs

- [Mac app: build, capture, settings](docs/mac.md)
- [SwiftUI code map](swiftui/README.md)
- [Theme rules](docs/THEME-RULES.md)
- [Changelog](CHANGELOG.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
