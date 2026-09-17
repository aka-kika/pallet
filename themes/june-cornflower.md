# June & Cornflower

Source: Photo reference

Original palette: #BADE4F, #6E8EEC, #282B26, #F0ECE5

Main color: #6E8EEC

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #EBEFF6 | #262C35 |
| surface | #F2F4F7 | #323840 |
| raised | #DDE3F1 | #3C4249 |
| text | #282B26 | #F5F5F7 |
| muted | #676A6A | #ADAFB3 |
| border | #CCD0D5 | #474C54 |
| accent | #6E8EEC | #6E8EEC |
| on-accent | #111318 | #111318 |
| accent-hover | #6784DB | #6784DB |
| highlight | #BADE4F | #BADE4F |
| on-highlight | #111318 | #111318 |
| highlight-ink | #5D6E30 | #BADE4F |
| highlight-hover | #B0D24C | #B0D24C |
| link | #5168AA | #6E8EEC |
| focus | #788F3A | #BADE4F |
| selection | #E1ECD5 | #52613D |
| on-selection | #282B26 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* June & Cornflower · primary #6E8EEC */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #EBEFF6;
  --surface: #F2F4F7;
  --raised: #DDE3F1;
  --text: #282B26;
  --muted: #676A6A;
  --border: #CCD0D5;
  --accent: #6E8EEC;
  --on-accent: #111318;
  --accent-hover: #6784DB;
  --highlight: #BADE4F;
  --on-highlight: #111318;
  --highlight-ink: #5D6E30;
  --highlight-hover: #B0D24C;
  --link: #5168AA;
  --focus: #788F3A;
  --selection: #E1ECD5;
  --on-selection: #282B26;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #262C35;
  --surface: #323840;
  --raised: #3C4249;
  --text: #F5F5F7;
  --muted: #ADAFB3;
  --border: #474C54;
  --accent: #6E8EEC;
  --on-accent: #111318;
  --accent-hover: #6784DB;
  --highlight: #BADE4F;
  --on-highlight: #111318;
  --highlight-ink: #BADE4F;
  --highlight-hover: #B0D24C;
  --link: #6E8EEC;
  --focus: #BADE4F;
  --selection: #52613D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #262C35;
  --surface: #323840;
  --raised: #3C4249;
  --text: #F5F5F7;
  --muted: #ADAFB3;
  --border: #474C54;
  --accent: #6E8EEC;
  --on-accent: #111318;
  --accent-hover: #6784DB;
  --highlight: #BADE4F;
  --on-highlight: #111318;
  --highlight-ink: #BADE4F;
  --highlight-hover: #B0D24C;
  --link: #6E8EEC;
  --focus: #BADE4F;
  --selection: #52613D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
