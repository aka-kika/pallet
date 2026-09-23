# Pallet for Mac

Pallet is a menu-bar color collection. Drop an image, extract a palette on this device, and copy light and soft-dark CSS.

The build is unsigned and not notarized.

## Build

1. Install **Node.js 24 LTS** from https://nodejs.org.
2. From the repo root, double-click **Setup Mac.command**, or run:

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile
node desktop/build.mjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
```

3. Move **Pallet.app** from `desktop/release/Pallet-darwin-<arch>/` into Applications. For an unsigned app, Control-click then Open, or use Privacy & Security → Open Anyway.

Data lives in `~/Library/Application Support/Palette/`. The local server binds to `127.0.0.1:45487`.

## Capture

- Click the menu-bar icon for the drop zone. Press it again to close.
- Esc closes and resets. In Settings you can copy CSS on Esc.
- Drop-zone sizes: Mini, Miny, Mo.
- Right-click the icon for Open Collection, Settings, and Quit.

## Settings

- **App:** appearance, collection layout (cards or list), import on drop, hide the keyboard guide, and the background lock.
- **Menu bar:** drop-zone size, **Show Pallet in** (Dock and menu bar, Dock only, or Menu bar only), copy CSS on Esc, and the global shortcut. The shortcut opens the drop zone in every mode.
- **About:** the app icon and links to X, GitHub, and the website.

PNG, JPG, WebP, GIF, and AVIF, up to 20 MB. Colors are sampled locally. Images are not stored.

## Rebuild after editing source

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile
node desktop/build.mjs
node --test desktop/server.test.cjs
node scripts/contrast-check.mjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
```

`scripts/contrast-check.mjs` checks every palette, main color, mode, and background lock for readable text. It must print `PASS`.
