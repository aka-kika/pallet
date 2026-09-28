# Theme rules

Which palette color goes where when a palette is picked. Code: `theme()` and `roles()` in `lib/palettes.ts`, CSS at the end of `app/globals.css`.

## Two colors drive the app

- **Main color** (the dot on the swatch, `accent`): sets the mood.
- **Companion** (`highlight`): the palette color most different from the main and most colorful. Marks "on" states.

## Where they go

| Part | Color |
| --- | --- |
| Page background | Lightest (light) or darkest (dark) palette color, tinted by the main |
| Arrow buttons, key hints | `wash`: soft main-color fill, icon in `link` |
| Hover on any button | `wash` (or `hover` on buttons that already have a fill) |
| Top bar and card icons | `icon`: dim text tinted toward the main |
| Links, "Export collection" | `link`: main color made readable |
| Primary buttons in dialogs | `accent` solid, text `on-accent` |
| Heart on, lock on, brand, selected ring, Space key | companion (`highlight-ink`, `highlight`, `focus`) |
| Body text | neutral `text`, `muted`, `text-soft`, `text-dim` |

## Guard rails

- Muted main colors tint the page more, loud ones less (`tint` scales with chroma).
- The page background never gets very colorful (chroma cap 0.07).
- Light mode keeps a light background even when every palette color is dark.
- `wash` and `hover` stay close to the background in lightness, so one text color reads on all of them.
- Every text color reaches 4.5:1 on background, surface, raised, wash and hover; icons and focus rings 3:1. If a color cannot get there, it falls back to black or white.
- `pnpm check:contrast` checks all of this for every built-in palette, every main color, light and dark, lock on and off.

## Playing with it

- Left and right arrows move the main color; the whole theme follows with a short color fade.
- Lock (L) keeps the background; everything else still follows the main color.
