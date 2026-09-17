# Periwinkle Study

Source: Photo reference · estimated swatches; labels unreadable

Original palette: #101726, #6176AD, #9290CF, #92A2D8, #BBC2D7, #F4F4F4

Main color: #6176AD

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #EBEFF4 | #1B212F |
| surface | #F1F4F7 | #282E3B |
| raised | #DCE1EC | #323846 |
| text | #101726 | #F5F5F7 |
| muted | #5D636E | #A9ABB1 |
| border | #C8CCD3 | #3E434F |
| accent | #6176AD | #6176AD |
| on-accent | #000000 | #000000 |
| accent-hover | #596D9F | #596D9F |
| highlight | #92A2D8 | #92A2D8 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #60698D | #92A2D8 |
| highlight-hover | #8A99CC | #8A99CC |
| link | #586A9C | #7B8DBB |
| focus | #7682AD | #92A2D8 |
| selection | #D9E0EE | #3F4862 |
| on-selection | #101726 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Periwinkle Study · primary #6176AD */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #EBEFF4;
  --surface: #F1F4F7;
  --raised: #DCE1EC;
  --text: #101726;
  --muted: #5D636E;
  --border: #C8CCD3;
  --accent: #6176AD;
  --on-accent: #000000;
  --accent-hover: #596D9F;
  --highlight: #92A2D8;
  --on-highlight: #111318;
  --highlight-ink: #60698D;
  --highlight-hover: #8A99CC;
  --link: #586A9C;
  --focus: #7682AD;
  --selection: #D9E0EE;
  --on-selection: #101726;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #1B212F;
  --surface: #282E3B;
  --raised: #323846;
  --text: #F5F5F7;
  --muted: #A9ABB1;
  --border: #3E434F;
  --accent: #6176AD;
  --on-accent: #000000;
  --accent-hover: #596D9F;
  --highlight: #92A2D8;
  --on-highlight: #111318;
  --highlight-ink: #92A2D8;
  --highlight-hover: #8A99CC;
  --link: #7B8DBB;
  --focus: #92A2D8;
  --selection: #3F4862;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #1B212F;
  --surface: #282E3B;
  --raised: #323846;
  --text: #F5F5F7;
  --muted: #A9ABB1;
  --border: #3E434F;
  --accent: #6176AD;
  --on-accent: #000000;
  --accent-hover: #596D9F;
  --highlight: #92A2D8;
  --on-highlight: #111318;
  --highlight-ink: #92A2D8;
  --highlight-hover: #8A99CC;
  --link: #7B8DBB;
  --focus: #92A2D8;
  --selection: #3F4862;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
