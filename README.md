<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Pallet app icon: three color cards, pale, citron, and slate, fanned on a dark slate plate">
</p>

# Pallet

[![macOS](https://img.shields.io/badge/macOS-menu%20bar-111318?style=flat-square)](https://github.com/aka-kika/pallet)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Electron](https://img.shields.io/badge/Electron-44-47848F?style=flat-square&logo=electron&logoColor=white)](https://www.electronjs.org/)
[![data](https://img.shields.io/badge/data-on%20this%20device-367749?style=flat-square)](docs/mac.md)
[![build](https://img.shields.io/badge/build-unsigned-8D641D?style=flat-square)](docs/mac.md)
[![version](https://img.shields.io/badge/version-1.1.1-3B82F6?style=flat-square)](https://github.com/aka-kika/pallet/releases/latest)
[![license](https://img.shields.io/badge/license-MIT-111318?style=flat-square)](LICENSE)

Pallet is a Mac menu-bar app for collecting color palettes from images. Drop a picture, extract colors on this device, and copy light and soft-dark CSS. Nothing is uploaded.

<p align="center">
  <img src="docs/screenshots/01-collection.png" alt="Pallet for Mac showing the Orchid Mint palette, collection grid of color cards, and a Shuffle control" width="720">
</p>

## Features

- Local color extraction. Pixels stay on this Mac.
- A drop zone in the menu bar, with Mini, Miny, and Mo sizes.
- A collection that restyles the whole window from the selected palette.
- Copy one hex, or copy light and dark CSS.
- Lock the background while you shuffle palettes.
- Favorites, delete with confirm, and a global shortcut you can record.
- Readable text on every palette, checked by `scripts/contrast-check.mjs`.
- Show Pallet in the Dock and menu bar, the Dock only, or the menu bar only.

## Collection

The main window is the selected palette on top and your cards below. Click a hex chip to copy it. Space shuffles. L locks the current background.

<img src="docs/screenshots/04-collection-cards.png" alt="Pallet collection grid of color cards with Orchid Mint and Signal Orange selected" width="720">

## Add an image

Drop, paste, or choose a file. Pallet samples visible pixels. No image leaves this device.

<img src="docs/screenshots/02-add-image.png" alt="The Add image window in Pallet with a dashed drop zone and Extract palette" width="720">

## Edit before saving

Name the palette, set the main color, remove extras with the corner X, then add it to the collection.

<img src="docs/screenshots/03-extracted-palette.png" alt="An extracted palette in Pallet with named swatches, hex fields, and Add to collection" width="720">

## Install

Latest release: **[1.1.1](https://github.com/aka-kika/pallet/releases/latest)**. What changed: [CHANGELOG.md](CHANGELOG.md).

Build it yourself with Node.js 24. See **[docs/mac.md](docs/mac.md)**, or double-click **Setup Mac.command**. After that, Pallet.app runs without Node.

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile
node desktop/build.mjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
```

Browser preview while developing (palettes saved there last until the server restarts):

```sh
pnpm run dev
```

## Docs

- [Mac build, capture, and settings](docs/mac.md)
- [Desktop implementation](desktop/README.md)
- [Changelog](CHANGELOG.md)

## Release

Releases are tagged on GitHub (`v1.1.1` is the latest). Builds are unsigned and not notarized: Control-click Pallet.app, then Open, the first time. Data lives in `~/Library/Application Support/Palette/`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
