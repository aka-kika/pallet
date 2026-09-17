# Willow & White

Source: Photo reference

Original palette: #FFFFFF, #F4F3EF, #DFDED9, #B5B1AE, #B0BFCC, #9ABDE2, #3F3F3F

Main color: #9ABDE2

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F1F6FB | #33393E |
| surface | #F5F9FC | #3F454A |
| raised | #E7EFF7 | #494F53 |
| text | #3C3C3D | #F5F5F7 |
| muted | #696B6E | #B1B3B6 |
| border | #D4D8DD | #52575C |
| accent | #9ABDE2 | #9ABDE2 |
| on-accent | #111318 | #111318 |
| accent-hover | #8FAFD2 | #8FAFD2 |
| highlight | #3F3F3F | #3F3F3F |
| on-highlight | #FFFFFF | #FFFFFF |
| highlight-ink | #3F3F3F | #A4A4A4 |
| highlight-hover | #4B4B4B | #4B4B4B |
| link | #5B6F86 | #9ABDE2 |
| focus | #3F3F3F | #838383 |
| selection | #CDD1D5 | #373B3E |
| on-selection | #3C3C3D | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Willow & White · primary #9ABDE2 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F1F6FB;
  --surface: #F5F9FC;
  --raised: #E7EFF7;
  --text: #3C3C3D;
  --muted: #696B6E;
  --border: #D4D8DD;
  --accent: #9ABDE2;
  --on-accent: #111318;
  --accent-hover: #8FAFD2;
  --highlight: #3F3F3F;
  --on-highlight: #FFFFFF;
  --highlight-ink: #3F3F3F;
  --highlight-hover: #4B4B4B;
  --link: #5B6F86;
  --focus: #3F3F3F;
  --selection: #CDD1D5;
  --on-selection: #3C3C3D;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #33393E;
  --surface: #3F454A;
  --raised: #494F53;
  --text: #F5F5F7;
  --muted: #B1B3B6;
  --border: #52575C;
  --accent: #9ABDE2;
  --on-accent: #111318;
  --accent-hover: #8FAFD2;
  --highlight: #3F3F3F;
  --on-highlight: #FFFFFF;
  --highlight-ink: #A4A4A4;
  --highlight-hover: #4B4B4B;
  --link: #9ABDE2;
  --focus: #838383;
  --selection: #373B3E;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #33393E;
  --surface: #3F454A;
  --raised: #494F53;
  --text: #F5F5F7;
  --muted: #B1B3B6;
  --border: #52575C;
  --accent: #9ABDE2;
  --on-accent: #111318;
  --accent-hover: #8FAFD2;
  --highlight: #3F3F3F;
  --on-highlight: #FFFFFF;
  --highlight-ink: #A4A4A4;
  --highlight-hover: #4B4B4B;
  --link: #9ABDE2;
  --focus: #838383;
  --selection: #373B3E;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
