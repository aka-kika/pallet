# Ash & Jet Stream

Source: Photo reference

Original palette: #B4B9BA, #BACCD0, #000000, #111111

Main color: #BACCD0

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #E8EEF0 | #1D2023 |
| surface | #EEF2F3 | #282C2E |
| raised | #DFE6E8 | #323538 |
| text | #000000 | #F5F5F7 |
| muted | #515354 | #A9AAAD |
| border | #C3C8CA | #404245 |
| accent | #BACCD0 | #BACCD0 |
| on-accent | #111318 | #111318 |
| accent-hover | #ACBDC1 | #ACBDC1 |
| highlight | #000000 | #000000 |
| on-highlight | #FFFFFF | #FFFFFF |
| highlight-ink | #000000 | #8D8D8D |
| highlight-hover | #0F0F0F | #0F0F0F |
| link | #626B6F | #BACCD0 |
| focus | #000000 | #6D6D6D |
| selection | #BABEC0 | #141619 |
| on-selection | #000000 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Ash & Jet Stream · primary #BACCD0 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #E8EEF0;
  --surface: #EEF2F3;
  --raised: #DFE6E8;
  --text: #000000;
  --muted: #515354;
  --border: #C3C8CA;
  --accent: #BACCD0;
  --on-accent: #111318;
  --accent-hover: #ACBDC1;
  --highlight: #000000;
  --on-highlight: #FFFFFF;
  --highlight-ink: #000000;
  --highlight-hover: #0F0F0F;
  --link: #626B6F;
  --focus: #000000;
  --selection: #BABEC0;
  --on-selection: #000000;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #1D2023;
  --surface: #282C2E;
  --raised: #323538;
  --text: #F5F5F7;
  --muted: #A9AAAD;
  --border: #404245;
  --accent: #BACCD0;
  --on-accent: #111318;
  --accent-hover: #ACBDC1;
  --highlight: #000000;
  --on-highlight: #FFFFFF;
  --highlight-ink: #8D8D8D;
  --highlight-hover: #0F0F0F;
  --link: #BACCD0;
  --focus: #6D6D6D;
  --selection: #141619;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #1D2023;
  --surface: #282C2E;
  --raised: #323538;
  --text: #F5F5F7;
  --muted: #A9AAAD;
  --border: #404245;
  --accent: #BACCD0;
  --on-accent: #111318;
  --accent-hover: #ACBDC1;
  --highlight: #000000;
  --on-highlight: #FFFFFF;
  --highlight-ink: #8D8D8D;
  --highlight-hover: #0F0F0F;
  --link: #BACCD0;
  --focus: #6D6D6D;
  --selection: #141619;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
