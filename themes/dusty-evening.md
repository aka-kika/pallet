# Dusty Evening

Source: Earlier theme collection

Original palette: #C98C96, #F4E9E2, #F0B49D, #6F5147, #7789A5

Main color: #C98C96

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F3EEEF | #4C3B3A |
| surface | #F6F4F4 | #564645 |
| raised | #EDE2E4 | #5F4F4E |
| text | #443531 | #F7F7F7 |
| muted | #6E6564 | #BBB5B5 |
| border | #D7D0D1 | #675958 |
| accent | #C98C96 | #C98C96 |
| on-accent | #111318 | #111318 |
| accent-hover | #BA828C | #BA828C |
| highlight | #F0B49D | #F0B49D |
| on-highlight | #111318 | #111318 |
| highlight-ink | #82645B | #F0B49D |
| highlight-hover | #E3AA95 | #E3AA95 |
| link | #886269 | #D29FA8 |
| focus | #A27B6E | #F0B49D |
| selection | #F2E2DF | #7D5F58 |
| on-selection | #443531 | #F7F7F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F69199 |

## CSS

```css
/* Dusty Evening · primary #C98C96 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F3EEEF;
  --surface: #F6F4F4;
  --raised: #EDE2E4;
  --text: #443531;
  --muted: #6E6564;
  --border: #D7D0D1;
  --accent: #C98C96;
  --on-accent: #111318;
  --accent-hover: #BA828C;
  --highlight: #F0B49D;
  --on-highlight: #111318;
  --highlight-ink: #82645B;
  --highlight-hover: #E3AA95;
  --link: #886269;
  --focus: #A27B6E;
  --selection: #F2E2DF;
  --on-selection: #443531;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #4C3B3A;
  --surface: #564645;
  --raised: #5F4F4E;
  --text: #F7F7F7;
  --muted: #BBB5B5;
  --border: #675958;
  --accent: #C98C96;
  --on-accent: #111318;
  --accent-hover: #BA828C;
  --highlight: #F0B49D;
  --on-highlight: #111318;
  --highlight-ink: #F0B49D;
  --highlight-hover: #E3AA95;
  --link: #D29FA8;
  --focus: #F0B49D;
  --selection: #7D5F58;
  --on-selection: #F7F7F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F69199;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #4C3B3A;
  --surface: #564645;
  --raised: #5F4F4E;
  --text: #F7F7F7;
  --muted: #BBB5B5;
  --border: #675958;
  --accent: #C98C96;
  --on-accent: #111318;
  --accent-hover: #BA828C;
  --highlight: #F0B49D;
  --on-highlight: #111318;
  --highlight-ink: #F0B49D;
  --highlight-hover: #E3AA95;
  --link: #D29FA8;
  --focus: #F0B49D;
  --selection: #7D5F58;
  --on-selection: #F7F7F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F69199;
}
```
