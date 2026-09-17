# Asphalt Lime

Source: Earlier theme collection

Original palette: #111111, #737373, #4F6F9F, #D7FF3F, #F8F8F5

Main color: #4F6F9F

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #EAEFF4 | #1A1E26 |
| surface | #F0F4F6 | #262B32 |
| raised | #D9E0E7 | #31353B |
| text | #111111 | #F5F5F7 |
| muted | #5D5F60 | #A8AAAE |
| border | #C7CBD0 | #3D4047 |
| accent | #4F6F9F | #4F6F9F |
| on-accent | #FFFFFF | #FFFFFF |
| accent-hover | #5D7BA7 | #5D7BA7 |
| highlight | #D7FF3F | #D7FF3F |
| on-highlight | #111318 | #111318 |
| highlight-ink | #607029 | #D7FF3F |
| highlight-hover | #CBF13D | #CBF13D |
| link | #4B6997 | #6D88AF |
| focus | #7C922E | #D7FF3F |
| selection | #E6F2D0 | #53622E |
| on-selection | #111111 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Asphalt Lime · primary #4F6F9F */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #EAEFF4;
  --surface: #F0F4F6;
  --raised: #D9E0E7;
  --text: #111111;
  --muted: #5D5F60;
  --border: #C7CBD0;
  --accent: #4F6F9F;
  --on-accent: #FFFFFF;
  --accent-hover: #5D7BA7;
  --highlight: #D7FF3F;
  --on-highlight: #111318;
  --highlight-ink: #607029;
  --highlight-hover: #CBF13D;
  --link: #4B6997;
  --focus: #7C922E;
  --selection: #E6F2D0;
  --on-selection: #111111;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #1A1E26;
  --surface: #262B32;
  --raised: #31353B;
  --text: #F5F5F7;
  --muted: #A8AAAE;
  --border: #3D4047;
  --accent: #4F6F9F;
  --on-accent: #FFFFFF;
  --accent-hover: #5D7BA7;
  --highlight: #D7FF3F;
  --on-highlight: #111318;
  --highlight-ink: #D7FF3F;
  --highlight-hover: #CBF13D;
  --link: #6D88AF;
  --focus: #D7FF3F;
  --selection: #53622E;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #1A1E26;
  --surface: #262B32;
  --raised: #31353B;
  --text: #F5F5F7;
  --muted: #A8AAAE;
  --border: #3D4047;
  --accent: #4F6F9F;
  --on-accent: #FFFFFF;
  --accent-hover: #5D7BA7;
  --highlight: #D7FF3F;
  --on-highlight: #111318;
  --highlight-ink: #D7FF3F;
  --highlight-hover: #CBF13D;
  --link: #6D88AF;
  --focus: #D7FF3F;
  --selection: #53622E;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
