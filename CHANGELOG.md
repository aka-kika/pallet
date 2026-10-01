# Changelog

## 2.0 (2026-10-01)

Pallet for Mac is now a native SwiftUI app (`swiftui/`), 4.4 MB instead of 295 MB. It reads the same collection, so nothing needs moving. The Electron app (`desktop/`) is retired on the Mac.

- Smart extraction with Apple's Vision: palette cards give only their swatches (no frame, text or backdrop photo), printed hex codes are read exactly, a title becomes the name; website screenshots give background, surface, text and accent colors.
- Menu bar panel and capture: pick any area of the screen from any app (Shift-Command-P), open the panel with Option-Shift-Command-P, drop, paste or choose an image there.
- Apple-style window: sidebar with library sections, collections and a color slider; search by name or color; customizable toolbar; undo for every change; light or soft dark from the toolbar (Shift-Command-D).
- Settings in tabs, with every shortcut recordable.
- Theme rules: picking a palette now tints the page, buttons, hover and icons, in the web app too ([docs/THEME-RULES.md](docs/THEME-RULES.md)). Built-in palettes live in `shared/builtin-palettes.json` for both.
- Data safety: a collection file that can't be read is copied aside and never overwritten; unknown entries are kept.
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
