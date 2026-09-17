# Graphite Sprout

Source: Photo reference

Original palette: #23262C, #3A3F47, #D1D5DB, #FE7733, #B1FA63, #FFFFFF

Main color: #B1FA63

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F3FBF1 | #2B342A |
| surface | #F6FBF4 | #383F36 |
| raised | #EAF7E0 | #41483F |
| text | #23262C | #F5F5F7 |
| muted | #6C7171 | #AEB1AF |
| border | #D2D9D1 | #4B534B |
| accent | #B1FA63 | #B1FA63 |
| on-accent | #111318 | #111318 |
| accent-hover | #A4E85D | #A4E85D |
| highlight | #FE7733 | #FE7733 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #B5582C | #FE7733 |
| highlight-hover | #F07131 | #F07131 |
| link | #587A3A | #B1FA63 |
| focus | #E36B30 | #FE7733 |
| selection | #F5E1CB | #6A482D |
| on-selection | #23262C | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Graphite Sprout · primary #B1FA63 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F3FBF1;
  --surface: #F6FBF4;
  --raised: #EAF7E0;
  --text: #23262C;
  --muted: #6C7171;
  --border: #D2D9D1;
  --accent: #B1FA63;
  --on-accent: #111318;
  --accent-hover: #A4E85D;
  --highlight: #FE7733;
  --on-highlight: #111318;
  --highlight-ink: #B5582C;
  --highlight-hover: #F07131;
  --link: #587A3A;
  --focus: #E36B30;
  --selection: #F5E1CB;
  --on-selection: #23262C;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #2B342A;
  --surface: #383F36;
  --raised: #41483F;
  --text: #F5F5F7;
  --muted: #AEB1AF;
  --border: #4B534B;
  --accent: #B1FA63;
  --on-accent: #111318;
  --accent-hover: #A4E85D;
  --highlight: #FE7733;
  --on-highlight: #111318;
  --highlight-ink: #FE7733;
  --highlight-hover: #F07131;
  --link: #B1FA63;
  --focus: #FE7733;
  --selection: #6A482D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #2B342A;
  --surface: #383F36;
  --raised: #41483F;
  --text: #F5F5F7;
  --muted: #AEB1AF;
  --border: #4B534B;
  --accent: #B1FA63;
  --on-accent: #111318;
  --accent-hover: #A4E85D;
  --highlight: #FE7733;
  --on-highlight: #111318;
  --highlight-ink: #FE7733;
  --highlight-hover: #F07131;
  --link: #B1FA63;
  --focus: #FE7733;
  --selection: #6A482D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
