# Handoff: contrast on shuffle (for Muse)

From Claude Code for Kika, 2026-09-23.

## Rules (read these first, they are not optional)

1. Work only on branch `muse/contrast-on-shuffle`. It is already checked out. Never switch to `main`, never merge, never rebase, never push. Git hooks block commits on `main` and every push.
2. Change only `lib/palettes.ts` and a new file `scripts/contrast-check.mjs`. If you think another file must change, stop and write why at the bottom of this file instead.
3. Keep the look. Kika likes the interface as it is: same layout, same colors wherever they already read well. Adjust only the colors that fail contrast, and by the smallest step that passes.
4. Commit on this branch with clear messages. Do not delete or rename anything.

## The problem

Press Space (shuffle) a few times: on some palettes, text or icons are hard to read. The app recolors the whole interface from the selected palette in `theme()` in `lib/palettes.ts`.

Where to look:

- `theme(p, dark)` builds every UI color. `withLockedBackground()` rebuilds them when the background is locked.
- `readable(color, bg, ratio)` pushes a color toward black or white until it reaches the ratio. `ink(bg)` picks black or white text for a fill.
- Likely cause: `text` and `muted` are checked against `background` only, never against `surface` and `raised`, which cards and panels use. The same for `highlight-ink` and `link`. On some palettes those surfaces drift far enough from the background that the text fails on them.
- Also check `on-selection` against `selection`, `on-accent` against `accent`, and `on-highlight` against `highlight`.

## The fix

- Every text color must reach 4.5:1 against every surface it can sit on (`background`, `surface`, `raised`). Large text, icons and focus rings: 3:1.
- Do it inside `theme()` and `withLockedBackground()` with the existing `readable()` and `contrast()` helpers, so both light and soft dark stay consistent.

## Proof: `scripts/contrast-check.mjs`

Write a small Node script (no new dependencies) that:

- imports `lib/palettes.ts` directly (`const m = await import('../lib/palettes.ts')`; Node 22 on this Mac already loads it, checked: 20 seeds, `theme` works),
- for every seed palette, every main color (rotate through all of them, the way the left and right arrow keys do), in light and in dark, and with the background lock both off and on (lock set to that theme's background),
- checks every text and surface pair above and prints each failure as: palette, main color, mode, pair, ratio,
- exits with code 1 if anything fails.

Run it before your fix (it should fail, so save that output at the bottom of this file) and after (it must pass with zero failures).

Then run the app and shuffle about 20 times in light and 20 in soft dark, and check by eye that nothing is hard to read. Take 3 screenshots of palettes that failed before and read well now, and save them in `docs/screenshots/contrast-fix/`.

## Done means

- [ ] `node scripts/contrast-check.mjs` failed before, passes now (both outputs at the bottom)
- [ ] 20 shuffles in light and 20 in soft dark read well
- [ ] 3 before and after screenshots in `docs/screenshots/contrast-fix/`
- [ ] Commits only on `muse/contrast-on-shuffle`, nothing pushed
- [ ] A short note at the bottom: what changed and why

Reminder: branch `muse/contrast-on-shuffle` only, `lib/palettes.ts` plus the check script only, keep the look.

## Notes from Muse

(write here)
