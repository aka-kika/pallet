# Desktop implementation

Electron 44.4.1 wraps the React UI. `main.cjs` owns the tray, shortcut, clipboard, and sandboxed windows. `preload.cjs` exposes a small typed bridge (`lib/desktop.ts`). `server.cjs` serves the UI and persists palettes through `store.cjs`. Color extraction is local. No cloud account is required.

## Build

On a Mac with Node.js 24 or newer, from the repo root:

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile
node desktop/build.mjs
node --test desktop/server.test.cjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
```

- `desktop/build.mjs` builds the shared UI and the small service bundle into `desktop/build/` (ignored by git).
- `desktop/package.mjs` packages `desktop/release/Pallet-darwin-<arch>/Pallet.app`. Build on the matching Mac architecture. The output is unsigned and not notarized.
- The version lives in `desktop/package.mjs` and `desktop/runtime/package.json`.
- `desktop/runtime/package-lock.json` locks the Electron tooling only.

## Icon

`desktop/icon.icon` is the Icon Composer source. On macOS 26 the packager compiles it into `Assets.car` for Liquid Glass. `desktop/icon.icns` is the fallback for older macOS.

For a native development run after building:

```sh
./desktop/runtime/node_modules/.bin/electron desktop/main.cjs
```

## Extraction

Local extraction works offline. Images are sampled on the device and are not stored. On Apple silicon, a small Foundation Models helper may refine a capture name; it does not see the image.

## Security and behavior

- Renderer has no Node access; context isolation and sandboxing are enabled. Navigation to other origins and new windows are blocked.
- API requests require a random per-launch header injected by Electron only for this local origin. Host and Origin are checked, request bodies are bounded, and palettes are validated.
- Clipboard is read only after paste or an explicit Paste button; no clipboard monitoring. CSS replaces it only after a successful save when enabled.
- A second launch focuses the existing app. Collection writes use temp-file + rename. Invalid stored JSON stops startup instead of overwriting data.
- Closing the main window hides it; explicit Quit terminates the process and unregisters the shortcut. No login-at-startup setting is included.
- **Show Pallet in** (`appPresence` in `capture-settings.json`): `both` keeps today's behavior, `dock` removes the menu-bar icon and keeps the Dock icon, `menubar` never shows the Dock icon.
- External links: only the three About links (X, GitHub, website) may open, in the default browser. Every other new window is denied.

API references: [Tray](https://www.electronjs.org/docs/latest/api/tray), [global shortcuts](https://www.electronjs.org/docs/latest/api/global-shortcut), [clipboard](https://www.electronjs.org/docs/latest/api/clipboard), [security](https://www.electronjs.org/docs/latest/tutorial/security).
