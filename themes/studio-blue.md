# Studio Blue

Source: Earlier theme collection

Original palette: #1E56C3, #ECDCF4, #F3ECDE, #272932

Main color: #1E56C3

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #E6EAF2 | #1E2536 |
| surface | #EEF1F6 | #2A3142 |
| raised | #D1DAEC | #353C4B |
| text | #272932 | #F5F5F7 |
| muted | #65686F | #AAACB3 |
| border | #C7CBD3 | #404655 |
| accent | #1E56C3 | #1E56C3 |
| on-accent | #FFFFFF | #FFFFFF |
| accent-hover | #3064C8 | #3064C8 |
| highlight | #F3ECDE | #F3ECDE |
| on-highlight | #111318 | #111318 |
| highlight-ink | #6A6967 | #F3ECDE |
| highlight-hover | #E5DFD2 | #E5DFD2 |
| link | #1E56C3 | #6E91D8 |
| focus | #83817D | #F3ECDE |
| selection | #E9EAEE | #5E6168 |
| on-selection | #272932 | #F5F5F7 |
| success | #347146 | #86C89D |
| warning | #865F1D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Studio Blue · primary #1E56C3 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #E6EAF2;
  --surface: #EEF1F6;
  --raised: #D1DAEC;
  --text: #272932;
  --muted: #65686F;
  --border: #C7CBD3;
  --accent: #1E56C3;
  --on-accent: #FFFFFF;
  --accent-hover: #3064C8;
  --highlight: #F3ECDE;
  --on-highlight: #111318;
  --highlight-ink: #6A6967;
  --highlight-hover: #E5DFD2;
  --link: #1E56C3;
  --focus: #83817D;
  --selection: #E9EAEE;
  --on-selection: #272932;
  --success: #347146;
  --warning: #865F1D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #1E2536;
  --surface: #2A3142;
  --raised: #353C4B;
  --text: #F5F5F7;
  --muted: #AAACB3;
  --border: #404655;
  --accent: #1E56C3;
  --on-accent: #FFFFFF;
  --accent-hover: #3064C8;
  --highlight: #F3ECDE;
  --on-highlight: #111318;
  --highlight-ink: #F3ECDE;
  --highlight-hover: #E5DFD2;
  --link: #6E91D8;
  --focus: #F3ECDE;
  --selection: #5E6168;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #1E2536;
  --surface: #2A3142;
  --raised: #353C4B;
  --text: #F5F5F7;
  --muted: #AAACB3;
  --border: #404655;
  --accent: #1E56C3;
  --on-accent: #FFFFFF;
  --accent-hover: #3064C8;
  --highlight: #F3ECDE;
  --on-highlight: #111318;
  --highlight-ink: #F3ECDE;
  --highlight-hover: #E5DFD2;
  --link: #6E91D8;
  --focus: #F3ECDE;
  --selection: #5E6168;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
