# Orchid Mint

Source: Earlier theme collection

Original palette: #7269E3, #272C39, #A783A6, #98DEA3

Main color: #7269E3

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #DCE9E9 | #26283D |
| surface | #E9F0F1 | #323448 |
| raised | #CED9E5 | #3A3D50 |
| text | #272C39 | #F5F5F7 |
| muted | #5C646C | #ADADB6 |
| border | #BFCBCD | #47495B |
| accent | #7269E3 | #7269E3 |
| on-accent | #000000 | #000000 |
| accent-hover | #6961D1 | #6961D1 |
| highlight | #98DEA3 | #98DEA3 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #4D6E57 | #98DEA3 |
| highlight-hover | #90D29B | #90D29B |
| link | #5D56B7 | #918AE9 |
| focus | #5E8868 | #98DEA3 |
| selection | #CEE7DB | #485F5C |
| on-selection | #272C39 | #F5F5F7 |
| success | #347146 | #86C89D |
| warning | #865F1D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Orchid Mint · primary #7269E3 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #DCE9E9;
  --surface: #E9F0F1;
  --raised: #CED9E5;
  --text: #272C39;
  --muted: #5C646C;
  --border: #BFCBCD;
  --accent: #7269E3;
  --on-accent: #000000;
  --accent-hover: #6961D1;
  --highlight: #98DEA3;
  --on-highlight: #111318;
  --highlight-ink: #4D6E57;
  --highlight-hover: #90D29B;
  --link: #5D56B7;
  --focus: #5E8868;
  --selection: #CEE7DB;
  --on-selection: #272C39;
  --success: #347146;
  --warning: #865F1D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #26283D;
  --surface: #323448;
  --raised: #3A3D50;
  --text: #F5F5F7;
  --muted: #ADADB6;
  --border: #47495B;
  --accent: #7269E3;
  --on-accent: #000000;
  --accent-hover: #6961D1;
  --highlight: #98DEA3;
  --on-highlight: #111318;
  --highlight-ink: #98DEA3;
  --highlight-hover: #90D29B;
  --link: #918AE9;
  --focus: #98DEA3;
  --selection: #485F5C;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #26283D;
  --surface: #323448;
  --raised: #3A3D50;
  --text: #F5F5F7;
  --muted: #ADADB6;
  --border: #47495B;
  --accent: #7269E3;
  --on-accent: #000000;
  --accent-hover: #6961D1;
  --highlight: #98DEA3;
  --on-highlight: #111318;
  --highlight-ink: #98DEA3;
  --highlight-hover: #90D29B;
  --link: #918AE9;
  --focus: #98DEA3;
  --selection: #485F5C;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
