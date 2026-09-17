# Signal Orange

Source: Earlier theme collection

Original palette: #FC5723, #DFDFDF, #AAAAAA, #FFFFFF

Main color: #FC5723

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F9EEEC | #3E231D |
| surface | #FBF4F3 | #4B302A |
| raised | #F8DED8 | #543B35 |
| text | #5E2A20 | #F5F5F7 |
| muted | #85645E | #B5ACAB |
| border | #E0CFCB | #5B4540 |
| accent | #FC5723 | #FC5723 |
| on-accent | #111318 | #111318 |
| accent-hover | #E95222 | #E95222 |
| highlight | #FFFFFF | #FFFFFF |
| on-highlight | #111318 | #111318 |
| highlight-ink | #6A6A6E | #FFFFFF |
| highlight-hover | #F1F1F1 | #F1F1F1 |
| link | #BE4520 | #FC6130 |
| focus | #8A8A8D | #FFFFFF |
| selection | #FAF1F0 | #786561 |
| on-selection | #5E2A20 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Signal Orange · primary #FC5723 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F9EEEC;
  --surface: #FBF4F3;
  --raised: #F8DED8;
  --text: #5E2A20;
  --muted: #85645E;
  --border: #E0CFCB;
  --accent: #FC5723;
  --on-accent: #111318;
  --accent-hover: #E95222;
  --highlight: #FFFFFF;
  --on-highlight: #111318;
  --highlight-ink: #6A6A6E;
  --highlight-hover: #F1F1F1;
  --link: #BE4520;
  --focus: #8A8A8D;
  --selection: #FAF1F0;
  --on-selection: #5E2A20;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #3E231D;
  --surface: #4B302A;
  --raised: #543B35;
  --text: #F5F5F7;
  --muted: #B5ACAB;
  --border: #5B4540;
  --accent: #FC5723;
  --on-accent: #111318;
  --accent-hover: #E95222;
  --highlight: #FFFFFF;
  --on-highlight: #111318;
  --highlight-ink: #FFFFFF;
  --highlight-hover: #F1F1F1;
  --link: #FC6130;
  --focus: #FFFFFF;
  --selection: #786561;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #3E231D;
  --surface: #4B302A;
  --raised: #543B35;
  --text: #F5F5F7;
  --muted: #B5ACAB;
  --border: #5B4540;
  --accent: #FC5723;
  --on-accent: #111318;
  --accent-hover: #E95222;
  --highlight: #FFFFFF;
  --on-highlight: #111318;
  --highlight-ink: #FFFFFF;
  --highlight-hover: #F1F1F1;
  --link: #FC6130;
  --focus: #FFFFFF;
  --selection: #786561;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
