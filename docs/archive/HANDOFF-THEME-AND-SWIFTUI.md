# Handoff: theme rules, then Pallet in SwiftUI

> Done 2026-10-01. Part 1 and part 2 shipped in Pallet 2.0 (see CHANGELOG.md). Kept as a record.

Written 2026-09-28 at Kika's ask, for a fresh Claude Code session in Temple Kika. Kika is nearby (organizing, scrolling on gamba) but wants to give as little input as possible. Work on this Mac.

Ignore the Maestro / Muse roles in `AGENTS.md`: Maestri is paused since 2026-09-26. The rest of `AGENTS.md` (talking to Kika, where files go) still applies.

## Where things stand

- Pallet 1.1.1 (released 2026-09-23): Next.js inside an Electron shell (`desktop/`). Built-in palettes in `lib/palettes.ts`; Kika's own collection in `~/Library/Application Support/Palette/palettes.json`.
- The contrast fix (1.1.0) is done. What is missing: picking a palette changes too little of the app.
- Kika's task file: `~/Documents/reeds base/next-weeks/06-pallet-app.md`. Tick steps there as they get done.

## Part 1: theme rules (in today's app, first)

Picking a palette should change more of the app, in a way that works most of the time; it does not have to be perfect.

1. Write the rules: which palette color goes where (buttons, the heart, hover, icons). Short, in `docs/THEME-RULES.md`.
2. More buttons that pick up the theme.
3. The heart and the hover in theme colors.
4. Icon contrast that stays readable on every palette (reuse the 1.1.0 contrast code).
5. Left and right arrows change the base color and the whole theme follows, so users can play with it.
6. Try it on 10 very different palettes (very light, very dark, neon, pastel, one-hue), fix the worst cases. Screenshots of each into `docs/theme-check/`.

Work on a branch (`theme/rules`). Tests and build must pass. Do not release, notarize or push without Kika.

## Part 2: Pallet in SwiftUI (after part 1 is settled)

Kika's call (2026-09-28): copy the app as it is, in SwiftUI, to match her other Mac apps. The web page on akakika.com keeps today's code and layout.

- New Xcode project in `swiftui/` inside this repo (or a sibling folder if cleaner), its own branch (`swiftui/start`).
- Tonight's goal: the main screen working (palette list, palette view, the theme rules from part 1), reading the same `palettes.json` and built-in palettes. Not the whole app.
- Keep the palette data in one shared JSON so the web and SwiftUI versions read the same collection.
- Kika's taste: Mac-like, native materials, calm, minimal chrome, unified toolbar; About screen "Made by Kika" with only globe, X and GitHub icons.
- Use the `xcodebuildmcp-cli` skill for builds, and the `macos-vision-autonomy` rules for checking the UI yourself (capture, look, fix, repeat); never ask Kika to paste screenshots.
- The Electron app stays the shipping app until the SwiftUI one matches it.

## When done

Report to Kika in short bullets: what changed, screenshots, what is next. Run `/wrap` at the end.
