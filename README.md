<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Pallet app icon: three rounded color cards on a dark plate">
</p>

# Pallet

[![macOS](https://img.shields.io/badge/macOS-menu%20bar-111318?style=flat-square)](https://github.com/aka-kika/pallet)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Electron](https://img.shields.io/badge/Electron-44-47848F?style=flat-square&logo=electron&logoColor=white)](https://www.electronjs.org/)
[![data](https://img.shields.io/badge/data-on%20this%20device-367749?style=flat-square)](docs/mac.md)
[![build](https://img.shields.io/badge/build-unsigned-8D641D?style=flat-square)](docs/mac.md)
[![version](https://img.shields.io/badge/version-1.0.0-3B82F6?style=flat-square)](https://github.com/aka-kika/pallet)
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

## Collection

The main window is the selected palette on top and your cards below. Click a hex chip to copy it. Space shuffles. L locks the current background.

<img src="docs/screenshots/01-collection.png" alt="The Pallet collection window with large swatches, palette cards, and header actions" width="720">

## Add an image

Drop, paste, or choose a file. Pallet samples visible pixels. No image leaves this device.

<img src="docs/screenshots/02-add-image.png" alt="The Add image window in Pallet with a dashed drop zone and Extract palette" width="720">

## Edit before saving

Name the palette, set the main color, remove extras with the corner X, then add it to the collection.

<img src="docs/screenshots/03-extracted-palette.png" alt="An extracted palette in Pallet with named swatches, hex fields, and Add to collection" width="720">

## Install

See **[docs/mac.md](docs/mac.md)**. You need Node.js 24 to build the unsigned app once. After that, Pallet.app runs without Node.

```sh
npm ci --prefix desktop/runtime
node desktop/build.mjs
node desktop/package.mjs
```

Web preview while developing:

```sh
pnpm install --frozen-lockfile
pnpm run dev
```

## Docs

- [Mac build and capture](docs/mac.md)
- [Desktop implementation](desktop/README.md)

## Release

Unsigned local builds only. Not notarized. Data is `~/Library/Application Support/Palette/`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
