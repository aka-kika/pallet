# Carbon Electric

Source: Photo reference

Original palette: #101317, #343A40, #AAB2BD, #F4F7FA, #3B82F6

Main color: #3B82F6

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #E8EFFC | #172130 |
| surface | #EFF3FB | #232D3B |
| raised | #D4E1F7 | #2E3746 |
| text | #101317 | #F5F5F7 |
| muted | #5C6067 | #A7ABB1 |
| border | #C5CCD7 | #3B4350 |
| accent | #3B82F6 | #3B82F6 |
| on-accent | #111318 | #111318 |
| accent-hover | #3879E4 | #3879E4 |
| highlight | #101317 | #101317 |
| on-highlight | #FFFFFF | #FFFFFF |
| highlight-ink | #101317 | #87888A |
| highlight-hover | #1E2125 | #1E2125 |
| link | #3269C5 | #478AF7 |
| focus | #101317 | #6E6F72 |
| selection | #BDC3CE | #151D29 |
| on-selection | #101317 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Carbon Electric · primary #3B82F6 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #E8EFFC;
  --surface: #EFF3FB;
  --raised: #D4E1F7;
  --text: #101317;
  --muted: #5C6067;
  --border: #C5CCD7;
  --accent: #3B82F6;
  --on-accent: #111318;
  --accent-hover: #3879E4;
  --highlight: #101317;
  --on-highlight: #FFFFFF;
  --highlight-ink: #101317;
  --highlight-hover: #1E2125;
  --link: #3269C5;
  --focus: #101317;
  --selection: #BDC3CE;
  --on-selection: #101317;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #172130;
  --surface: #232D3B;
  --raised: #2E3746;
  --text: #F5F5F7;
  --muted: #A7ABB1;
  --border: #3B4350;
  --accent: #3B82F6;
  --on-accent: #111318;
  --accent-hover: #3879E4;
  --highlight: #101317;
  --on-highlight: #FFFFFF;
  --highlight-ink: #87888A;
  --highlight-hover: #1E2125;
  --link: #478AF7;
  --focus: #6E6F72;
  --selection: #151D29;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #172130;
  --surface: #232D3B;
  --raised: #2E3746;
  --text: #F5F5F7;
  --muted: #A7ABB1;
  --border: #3B4350;
  --accent: #3B82F6;
  --on-accent: #111318;
  --accent-hover: #3879E4;
  --highlight: #101317;
  --on-highlight: #FFFFFF;
  --highlight-ink: #87888A;
  --highlight-hover: #1E2125;
  --link: #478AF7;
  --focus: #6E6F72;
  --selection: #151D29;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
