# Astro Orange

Source: Earlier theme collection

Original palette: #E46036, #F1EDE5, #000000, #FFFFFF

Main color: #E46036

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F7EFED | #221514 |
| surface | #F9F4F2 | #2F2322 |
| raised | #F2DFDA | #3A2D2C |
| text | #000000 | #F5F5F7 |
| muted | #565453 | #ABA7A8 |
| border | #CFC9C7 | #443938 |
| accent | #E46036 | #E46036 |
| on-accent | #111318 | #111318 |
| accent-hover | #D35A34 | #D35A34 |
| highlight | #F1EDE5 | #F1EDE5 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #6A6969 | #F1EDE5 |
| highlight-hover | #E4E0D9 | #E4E0D9 |
| link | #AC4B2E | #E46036 |
| focus | #8A8987 | #F1EDE5 |
| selection | #F6EFEB | #605653 |
| on-selection | #000000 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Astro Orange · primary #E46036 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F7EFED;
  --surface: #F9F4F2;
  --raised: #F2DFDA;
  --text: #000000;
  --muted: #565453;
  --border: #CFC9C7;
  --accent: #E46036;
  --on-accent: #111318;
  --accent-hover: #D35A34;
  --highlight: #F1EDE5;
  --on-highlight: #111318;
  --highlight-ink: #6A6969;
  --highlight-hover: #E4E0D9;
  --link: #AC4B2E;
  --focus: #8A8987;
  --selection: #F6EFEB;
  --on-selection: #000000;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #221514;
  --surface: #2F2322;
  --raised: #3A2D2C;
  --text: #F5F5F7;
  --muted: #ABA7A8;
  --border: #443938;
  --accent: #E46036;
  --on-accent: #111318;
  --accent-hover: #D35A34;
  --highlight: #F1EDE5;
  --on-highlight: #111318;
  --highlight-ink: #F1EDE5;
  --highlight-hover: #E4E0D9;
  --link: #E46036;
  --focus: #F1EDE5;
  --selection: #605653;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #221514;
  --surface: #2F2322;
  --raised: #3A2D2C;
  --text: #F5F5F7;
  --muted: #ABA7A8;
  --border: #443938;
  --accent: #E46036;
  --on-accent: #111318;
  --accent-hover: #D35A34;
  --highlight: #F1EDE5;
  --on-highlight: #111318;
  --highlight-ink: #F1EDE5;
  --highlight-hover: #E4E0D9;
  --link: #E46036;
  --focus: #F1EDE5;
  --selection: #605653;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
