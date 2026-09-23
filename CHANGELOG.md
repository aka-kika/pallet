# Changelog

## Unreleased

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
