# Changelog

## 2.0.3 (2026-10-14)

Two more fixes from the code review. Nothing to move or set up.

- Export Collection now writes the same format as `palettes.json`: a plain list of palettes (each with its light and dark theme added). Import Collection reads both that and files exported before 2.0.3, so your old exports still work, and you can import a copy of `palettes.json` directly.
- Web: a deleted starter palette stays deleted after a reload, and editing a palette (main color, favorite) no longer moves it to another place in the collection.

## 2.0.2 (2026-10-14)

Fixes from a code review. Nothing to move or set up.

- Your collection is safer. When a sync tool or editor saves `palettes.json`, `hidden.json` or `collections.json` in several steps, Pallet waits for it to finish instead of reading a half-written file and refusing to touch it for the rest of the session. It also checks the files again when you come back to the app.
- Entries and fields Pallet doesn't know are now really kept when it saves, in all three files, as promised.
- A collection file with a plain text entry in it no longer crashes Pallet at launch.
- Pasting a copied image (a screenshot or an image copied from a web page) works again; before, only copied image files did. Command-V also works inside New Palette from Image.
- **Save new palettes right away** now covers pasted images too, and **Copy CSS after saving a capture** works however the palette was made from an image.
- Quit & Reopen after granting Screen Recording keeps the global shortcuts working.
- Space, the arrow keys and L work right after a click in the sidebar or on the color slider.
- The Background lock field in Settings keeps what you typed without pressing Return.
- Searching a hex code without `#` finds it anywhere in a color (`82f6` finds `#3B82F6`).
- A palette card that reads as a single color is now read as a screenshot or photo instead of giving a palette that can't be saved.
- A damaged keyboard shortcut setting no longer crashes the menus.
- Web: images the browser can't read (HEIC outside Safari, for example) get a clear message, and files with a missing type are tried instead of refused.

## 2.0 (2026-10-01)

Pallet for Mac is now a native SwiftUI app (`swiftui/`), 4.4 MB instead of 295 MB. It reads the same collection, so nothing needs moving. The Electron app (`desktop/`) is retired on the Mac.

- Smart extraction with Apple's Vision: palette cards give only their swatches (no frame, text or backdrop photo), printed hex codes are read exactly, a title becomes the name; website screenshots give background, surface, text and accent colors.
- Menu bar panel and capture: pick any area of the screen from any app (Shift-Command-P), open the panel with Option-Shift-Command-P, drop, paste or choose an image there.
- Apple-style window: sidebar with library sections, collections and a color slider; search by name or color; customizable toolbar; undo for every change; light or soft dark from the toolbar (Shift-Command-D).
- Settings in tabs, with every shortcut recordable.
- Theme rules: picking a palette now tints the page, buttons, hover and icons, in the web app too ([docs/THEME-RULES.md](docs/THEME-RULES.md)). Built-in palettes live in `shared/builtin-palettes.json` for both.
- Data safety: a collection file that can't be read is copied aside and never overwritten; unknown entries are kept.
- Web: the app runs at [akakika.com/pallet](https://akakika.com/pallet/) with Kika's collection and a Download for Mac button; visitors' own palettes stay in their browser. `pnpm site:build` and `pnpm site:publish` keep it in step with the Mac app.
- Menu bar panel shortcut (Option-Shift-Command-P), every shortcut recordable in Settings, light or soft dark from the toolbar (Shift-Command-D).
- The Electron app and its web-only helpers (quick capture window, menu bar settings) are removed from the repo; the `v1.1.1` tag keeps them.

## Unreleased (web)

- Cleanup: removed unused UI components, dependencies, the unused AI-provider endpoint, and the first-draft hosting scaffolding.
- The browser preview runs without a database; palettes saved there last until the server restarts.
- `Setup Mac.command` now builds the UI before packaging, so it works on a fresh download.

## 1.1.1 (2026-09-23)

- New app icon: three cards on a dark slate plate. Liquid Glass on macOS 26, classic icon on older macOS.
- Settings: new About tab with the icon and links to X, GitHub, and the website.
- The thin line above the collection is gone.
- Menu-bar drop zone: tighter frame whose corners follow the window corners.

## 1.1.0 (2026-09-23)

- Readable text on every palette: every text color reaches 4.5:1 against every surface it sits on, in light and soft dark, with or without the background lock. `scripts/contrast-check.mjs` proves it.
- Dim text (captions, card names, icons) now uses checked colors instead of see-through white.
- Settings > Menu bar: **Show Pallet in** Dock and menu bar, Dock only, or Menu bar only. Applies at once.
- Settings help text is readable again.

## 1.0.0 (2026-09-17)

- First release: menu-bar drop zone, local color extraction, collection with light and soft-dark theming, CSS copy, background lock, favorites, and a global shortcut.
