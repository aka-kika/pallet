# Developer Dusk

Source: Photo reference

Original palette: #0F172A, #1E293B, #F1F5F9, #94A3B8, #818CF8, #4ADE80

Main color: #818CF8

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #EEF0FB | #1E2438 |
| surface | #F3F4FA | #2A3043 |
| raised | #DFE3F7 | #333A4C |
| text | #0F172A | #F5F5F7 |
| muted | #5D6373 | #AAACB4 |
| border | #CACDDA | #404557 |
| accent | #818CF8 | #818CF8 |
| on-accent | #111318 | #111318 |
| accent-hover | #7882E6 | #7882E6 |
| highlight | #4ADE80 | #4ADE80 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #2E7A4C | #4ADE80 |
| highlight-hover | #47D27A | #47D27A |
| link | #5E67B3 | #818CF8 |
| focus | #36975B | #4ADE80 |
| selection | #CDECE2 | #2B5C4E |
| on-selection | #0F172A | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Developer Dusk · primary #818CF8 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #EEF0FB;
  --surface: #F3F4FA;
  --raised: #DFE3F7;
  --text: #0F172A;
  --muted: #5D6373;
  --border: #CACDDA;
  --accent: #818CF8;
  --on-accent: #111318;
  --accent-hover: #7882E6;
  --highlight: #4ADE80;
  --on-highlight: #111318;
  --highlight-ink: #2E7A4C;
  --highlight-hover: #47D27A;
  --link: #5E67B3;
  --focus: #36975B;
  --selection: #CDECE2;
  --on-selection: #0F172A;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #1E2438;
  --surface: #2A3043;
  --raised: #333A4C;
  --text: #F5F5F7;
  --muted: #AAACB4;
  --border: #404557;
  --accent: #818CF8;
  --on-accent: #111318;
  --accent-hover: #7882E6;
  --highlight: #4ADE80;
  --on-highlight: #111318;
  --highlight-ink: #4ADE80;
  --highlight-hover: #47D27A;
  --link: #818CF8;
  --focus: #4ADE80;
  --selection: #2B5C4E;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #1E2438;
  --surface: #2A3043;
  --raised: #333A4C;
  --text: #F5F5F7;
  --muted: #AAACB4;
  --border: #404557;
  --accent: #818CF8;
  --on-accent: #111318;
  --accent-hover: #7882E6;
  --highlight: #4ADE80;
  --on-highlight: #111318;
  --highlight-ink: #4ADE80;
  --highlight-hover: #47D27A;
  --link: #818CF8;
  --focus: #4ADE80;
  --selection: #2B5C4E;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
