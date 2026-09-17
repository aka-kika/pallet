# Apple Modern

Source: Earlier theme collection

Original palette: #F5F5F7, #1D1D1F, #AAAAAA, #007AFF

Main color: #007AFF

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #E3EFFB | #172435 |
| surface | #EDF3FB | #233041 |
| raised | #CBE1F8 | #2E3A4A |
| text | #1D1D1F | #F5F5F7 |
| muted | #62676C | #A7ACB3 |
| border | #C3CDD8 | #3B4554 |
| accent | #007AFF | #007AFF |
| on-accent | #111318 | #111318 |
| accent-hover | #0172ED | #0172ED |
| highlight | #F5F5F7 | #F5F5F7 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #66676B | #F5F5F7 |
| highlight-hover | #E7E7EA | #E7E7EA |
| link | #0464CC | #1D8AFF |
| focus | #858589 | #F5F5F7 |
| selection | #E7F0FA | #5A636F |
| on-selection | #1D1D1F | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Apple Modern · primary #007AFF */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #E3EFFB;
  --surface: #EDF3FB;
  --raised: #CBE1F8;
  --text: #1D1D1F;
  --muted: #62676C;
  --border: #C3CDD8;
  --accent: #007AFF;
  --on-accent: #111318;
  --accent-hover: #0172ED;
  --highlight: #F5F5F7;
  --on-highlight: #111318;
  --highlight-ink: #66676B;
  --highlight-hover: #E7E7EA;
  --link: #0464CC;
  --focus: #858589;
  --selection: #E7F0FA;
  --on-selection: #1D1D1F;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #172435;
  --surface: #233041;
  --raised: #2E3A4A;
  --text: #F5F5F7;
  --muted: #A7ACB3;
  --border: #3B4554;
  --accent: #007AFF;
  --on-accent: #111318;
  --accent-hover: #0172ED;
  --highlight: #F5F5F7;
  --on-highlight: #111318;
  --highlight-ink: #F5F5F7;
  --highlight-hover: #E7E7EA;
  --link: #1D8AFF;
  --focus: #F5F5F7;
  --selection: #5A636F;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #172435;
  --surface: #233041;
  --raised: #2E3A4A;
  --text: #F5F5F7;
  --muted: #A7ACB3;
  --border: #3B4554;
  --accent: #007AFF;
  --on-accent: #111318;
  --accent-hover: #0172ED;
  --highlight: #F5F5F7;
  --on-highlight: #111318;
  --highlight-ink: #F5F5F7;
  --highlight-hover: #E7E7EA;
  --link: #1D8AFF;
  --focus: #F5F5F7;
  --selection: #5A636F;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
