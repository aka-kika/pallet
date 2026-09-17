# Desktop implementation

Electron 44.4.1 wraps the React UI. `main.cjs` owns the tray, shortcut, clipboard, and sandboxed windows. `preload.cjs` exposes a small typed bridge (`lib/desktop.ts`). `server.cjs` serves the UI and persists palettes through `store.cjs`. Color extraction is local. No cloud account is required.

## Build from the included prebuilt interface

On a Mac with Node.js 24:

```sh
npm ci --prefix desktop/runtime
node desktop/package.mjs
```

`desktop/release/Pallet-darwin-arm64/Pallet.app` is produced on Apple Silicon; Intel produces `Pallet-darwin-x64/Pallet.app`. Build on the matching Mac architecture. Dependencies and Electron are downloaded from their standard public registries. The output is unsigned and not notarized.

## Rebuild after editing source

```sh
npx --yes pnpm@11.25.0 install --frozen-lockfile
node desktop/build.mjs
node --test desktop/server.test.cjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
```

For a native development run after rebuilding:

```sh
./desktop/runtime/node_modules/.bin/electron desktop/main.cjs
```

Prebuilt assets under `desktop/build` are included in the transfer ZIP, but ignored by git. Rebuild them whenever shared UI or provider code changes. `desktop/runtime/package-lock.json` locks the separate Electron tooling; it is not a runtime dependency of the hosted Site.

## Extraction

Local extraction works offline. Images are sampled on the device and are not stored. On Apple silicon, a small Foundation Models helper may refine a capture name; it does not see the image.

## Security and behavior

- Renderer has no Node access; context isolation and sandboxing are enabled. Navigation to other origins and new windows are blocked.
- API requests require a random per-launch header injected by Electron only for this local origin. Host and Origin are checked, request bodies are bounded, and palettes are validated.
- Clipboard is read only after paste or an explicit Paste button; no clipboard monitoring. CSS replaces it only after a successful save when enabled.
- A second launch focuses the existing app. Collection writes use temp-file + rename. Invalid stored JSON stops startup instead of overwriting data.
- Closing the main window hides it; explicit Quit terminates the process and unregisters the shortcut. No login-at-startup setting is included.

API references: [Tray](https://www.electronjs.org/docs/latest/api/tray), [global shortcuts](https://www.electronjs.org/docs/latest/api/global-shortcut), [clipboard](https://www.electronjs.org/docs/latest/api/clipboard), [security](https://www.electronjs.org/docs/latest/tutorial/security).
