# Pallet for Mac

Pallet is a menu-bar color collection. Drop an image, extract a palette on this device, and copy light and soft-dark CSS.

The build is unsigned and not notarized.

## Build

1. Install **Node.js 24 LTS** from https://nodejs.org.
2. From the repo root, double-click **Setup Mac.command**, or run:

```sh
npm ci --prefix desktop/runtime
node desktop/build.mjs
node desktop/package.mjs
```

3. Move **Pallet.app** from `desktop/release/Pallet-darwin-<arch>/` into Applications. For an unsigned app, Control-click then Open, or use Privacy & Security → Open Anyway.

Data lives in `~/Library/Application Support/Palette/`. The local server binds to `127.0.0.1:45487`.

## Capture

- Click the menu-bar icon for the drop zone. Press it again to close.
- Esc closes and resets. In Settings you can copy CSS on Esc.
- Drop-zone sizes: Mini, Miny, Mo.
- Right-click the icon for Open Collection, Settings, and Quit.

PNG, JPG, WebP, GIF, and AVIF, up to 20 MB. Colors are sampled locally. Images are not stored.

## Rebuild after editing source

```sh
pnpm install --frozen-lockfile
node desktop/build.mjs
node --test desktop/server.test.cjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
```
