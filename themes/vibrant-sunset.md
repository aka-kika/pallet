# Vibrant Sunset

Source: Earlier theme collection

Original palette: #4D3A4D, #BE5CA9, #D59CC5, #EADADA

Main color: #BE5CA9

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F1E8EF | #3D2C3F |
| surface | #F5EFF4 | #49374A |
| raised | #EAD7E6 | #514152 |
| text | #403241 | #F5F5F7 |
| muted | #6B626D | #B5AFB7 |
| border | #D5CBD3 | #5A4C5C |
| accent | #BE5CA9 | #BE5CA9 |
| on-accent | #111318 | #111318 |
| accent-hover | #B0569D | #B0569D |
| highlight | #D59CC5 | #D59CC5 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #7A5D75 | #D59CC5 |
| highlight-hover | #C994BB | #C994BB |
| link | #984C89 | #CC80BC |
| focus | #A17897 | #D59CC5 |
| selection | #EBD9E7 | #6B4E67 |
| on-selection | #403241 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #865F1D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Vibrant Sunset · primary #BE5CA9 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F1E8EF;
  --surface: #F5EFF4;
  --raised: #EAD7E6;
  --text: #403241;
  --muted: #6B626D;
  --border: #D5CBD3;
  --accent: #BE5CA9;
  --on-accent: #111318;
  --accent-hover: #B0569D;
  --highlight: #D59CC5;
  --on-highlight: #111318;
  --highlight-ink: #7A5D75;
  --highlight-hover: #C994BB;
  --link: #984C89;
  --focus: #A17897;
  --selection: #EBD9E7;
  --on-selection: #403241;
  --success: #367749;
  --warning: #865F1D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #3D2C3F;
  --surface: #49374A;
  --raised: #514152;
  --text: #F5F5F7;
  --muted: #B5AFB7;
  --border: #5A4C5C;
  --accent: #BE5CA9;
  --on-accent: #111318;
  --accent-hover: #B0569D;
  --highlight: #D59CC5;
  --on-highlight: #111318;
  --highlight-ink: #D59CC5;
  --highlight-hover: #C994BB;
  --link: #CC80BC;
  --focus: #D59CC5;
  --selection: #6B4E67;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #3D2C3F;
  --surface: #49374A;
  --raised: #514152;
  --text: #F5F5F7;
  --muted: #B5AFB7;
  --border: #5A4C5C;
  --accent: #BE5CA9;
  --on-accent: #111318;
  --accent-hover: #B0569D;
  --highlight: #D59CC5;
  --on-highlight: #111318;
  --highlight-ink: #D59CC5;
  --highlight-hover: #C994BB;
  --link: #CC80BC;
  --focus: #D59CC5;
  --selection: #6B4E67;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
