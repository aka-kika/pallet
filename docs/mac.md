# Pallet for Mac

The native SwiftUI app in `swiftui/`. It replaced the Electron app (version 1.1.1, removed from the repo in 2.0; see the `v1.1.1` tag) on 2026-10-01.

## Build

1. Xcode 27.2 or newer, macOS 26 or newer. The project uses Xcode's JSON project format (`swiftui/Pallet.xcodeproj/project.xcproj`).
2. From the repo root:

```sh
xcodebuild -project swiftui/Pallet.xcodeproj -scheme Pallet -configuration Release -derivedDataPath build/dd build
```

3. Move `build/dd/Build/Products/Release/Pallet.app` into Applications.

The app is signed with the maintainer's Developer ID (team in the project file) and not notarized. To build it yourself, set your own team or sign to run locally. Keep a stable signature: macOS ties the Screen Recording permission to it.

To try changes without touching your collection, launch with a copy: `open Pallet.app --args -PalletDataDirectory /path/to/copy`.

## Data

- `~/Library/Application Support/Palette/palettes.json`: your palettes (same format as the web app and the old Electron app).
- `hidden.json`: built-in palettes you deleted.
- `collections.json`: your collections (Mac only).
- If a file can't be read, Pallet copies it aside as `*.unreadable-<date>.json` and never writes over it. Entries it doesn't understand are kept as they are.

## Capture

- **Capture area** (Shift-Command-P, from any app): pick part of the screen. The first capture asks for Screen Recording; turn on Pallet in System Settings, then Quit & Reopen from the panel.
- **Menu bar panel** (click the icon, or Option-Shift-Command-P): drop an image, click to choose one, paste (Command-V), or Capture Area. Recent palettes are one click from their CSS.
- Dropping on the menu bar icon itself is not supported: in macOS 26, dragging to the top edge opens the Spaces bar.

## Settings

- **General:** appearance (system, light, soft dark), Shuffle button, background lock.
- **Capture:** show Pallet in the Dock and menu bar, the Dock only, or the menu bar only; open at login; save new palettes right away; copy CSS after a capture.
- **Keyboard:** record the two global shortcuts and every menu shortcut; restore defaults.
- **About:** made by Kika, with links to the website, X and GitHub.

## Checks after editing

- `pnpm check:contrast`: every palette, main color, mode and background lock keeps readable text (theme math in `lib/palettes.ts`; `Theme.swift` must match it).
- Build the Swift app with the command above; the project format can be checked with Xcode's `xcprojformatter`.
