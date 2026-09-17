# Graphic Garden

Source: Photo reference

Original palette: #59B9C7, #D2DEE3, #2B313F

Main color: #59B9C7

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #E4EFF3 | #25323C |
| surface | #EDF4F6 | #313D47 |
| raised | #D3E7EC | #3A4650 |
| text | #2B313F | #F5F5F7 |
| muted | #626972 | #ACB1B6 |
| border | #C6D1D6 | #46515A |
| accent | #59B9C7 | #59B9C7 |
| on-accent | #111318 | #111318 |
| accent-hover | #53ACB9 | #53ACB9 |
| highlight | #2B313F | #2B313F |
| on-highlight | #FFFFFF | #FFFFFF |
| highlight-ink | #2B313F | #94989E |
| highlight-hover | #383D4B | #383D4B |
| link | #3A737D | #59B9C7 |
| focus | #2B313F | #767A83 |
| selection | #BFC9CF | #27323D |
| on-selection | #2B313F | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Graphic Garden · primary #59B9C7 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #E4EFF3;
  --surface: #EDF4F6;
  --raised: #D3E7EC;
  --text: #2B313F;
  --muted: #626972;
  --border: #C6D1D6;
  --accent: #59B9C7;
  --on-accent: #111318;
  --accent-hover: #53ACB9;
  --highlight: #2B313F;
  --on-highlight: #FFFFFF;
  --highlight-ink: #2B313F;
  --highlight-hover: #383D4B;
  --link: #3A737D;
  --focus: #2B313F;
  --selection: #BFC9CF;
  --on-selection: #2B313F;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #25323C;
  --surface: #313D47;
  --raised: #3A4650;
  --text: #F5F5F7;
  --muted: #ACB1B6;
  --border: #46515A;
  --accent: #59B9C7;
  --on-accent: #111318;
  --accent-hover: #53ACB9;
  --highlight: #2B313F;
  --on-highlight: #FFFFFF;
  --highlight-ink: #94989E;
  --highlight-hover: #383D4B;
  --link: #59B9C7;
  --focus: #767A83;
  --selection: #27323D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #25323C;
  --surface: #313D47;
  --raised: #3A4650;
  --text: #F5F5F7;
  --muted: #ACB1B6;
  --border: #46515A;
  --accent: #59B9C7;
  --on-accent: #111318;
  --accent-hover: #53ACB9;
  --highlight: #2B313F;
  --on-highlight: #FFFFFF;
  --highlight-ink: #94989E;
  --highlight-hover: #383D4B;
  --link: #59B9C7;
  --focus: #767A83;
  --selection: #27323D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
