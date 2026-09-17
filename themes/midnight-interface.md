# Midnight Interface

Source: Earlier theme collection

Original palette: #101A33, #3F7CFF, #DDEBFF, #F8FBFF, #7C8794

Main color: #3F7CFF

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #E9F0FD | #17233D |
| surface | #F0F5FC | #243049 |
| raised | #D7E3FB | #2F3A52 |
| text | #101A33 | #F5F5F7 |
| muted | #5C657A | #A7ACB6 |
| border | #C6CEDD | #3B455B |
| accent | #3F7CFF | #3F7CFF |
| on-accent | #111318 | #111318 |
| accent-hover | #3B74ED | #3B74ED |
| highlight | #101A33 | #101A33 |
| on-highlight | #FFFFFF | #FFFFFF |
| highlight-ink | #101A33 | #878A98 |
| highlight-hover | #1E283F | #1E283F |
| link | #3565CC | #568BFF |
| focus | #101A33 | #6E7383 |
| selection | #BEC5D5 | #15203A |
| on-selection | #101A33 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Midnight Interface · primary #3F7CFF */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #E9F0FD;
  --surface: #F0F5FC;
  --raised: #D7E3FB;
  --text: #101A33;
  --muted: #5C657A;
  --border: #C6CEDD;
  --accent: #3F7CFF;
  --on-accent: #111318;
  --accent-hover: #3B74ED;
  --highlight: #101A33;
  --on-highlight: #FFFFFF;
  --highlight-ink: #101A33;
  --highlight-hover: #1E283F;
  --link: #3565CC;
  --focus: #101A33;
  --selection: #BEC5D5;
  --on-selection: #101A33;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #17233D;
  --surface: #243049;
  --raised: #2F3A52;
  --text: #F5F5F7;
  --muted: #A7ACB6;
  --border: #3B455B;
  --accent: #3F7CFF;
  --on-accent: #111318;
  --accent-hover: #3B74ED;
  --highlight: #101A33;
  --on-highlight: #FFFFFF;
  --highlight-ink: #878A98;
  --highlight-hover: #1E283F;
  --link: #568BFF;
  --focus: #6E7383;
  --selection: #15203A;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #17233D;
  --surface: #243049;
  --raised: #2F3A52;
  --text: #F5F5F7;
  --muted: #A7ACB6;
  --border: #3B455B;
  --accent: #3F7CFF;
  --on-accent: #111318;
  --accent-hover: #3B74ED;
  --highlight: #101A33;
  --on-highlight: #FFFFFF;
  --highlight-ink: #878A98;
  --highlight-hover: #1E283F;
  --link: #568BFF;
  --focus: #6E7383;
  --selection: #15203A;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
