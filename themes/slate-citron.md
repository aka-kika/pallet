# Slate & Citron

Source: Photo reference

Original palette: #FFFFFF, #57677A, #E1E821

Main color: #57677A

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #ECEFF3 | #37404C |
| surface | #F4F5F5 | #434C55 |
| raised | #DEE2E4 | #4D555D |
| text | #313943 | #F7F7F7 |
| muted | #62686F | #B4B7BB |
| border | #CED2D7 | #565D67 |
| accent | #57677A | #57677A |
| on-accent | #FFFFFF | #FFFFFF |
| accent-hover | #647385 | #647385 |
| highlight | #E1E821 | #E1E821 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #686D20 | #E1E821 |
| highlight-hover | #D5DB20 | #D5DB20 |
| link | #57677A | #A4AEB8 |
| focus | #888D20 | #E1E821 |
| selection | #EAEEC9 | #6A723F |
| on-selection | #313943 | #F7F7F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F69199 |

## CSS

```css
/* Slate & Citron · primary #57677A */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #ECEFF3;
  --surface: #F4F5F5;
  --raised: #DEE2E4;
  --text: #313943;
  --muted: #62686F;
  --border: #CED2D7;
  --accent: #57677A;
  --on-accent: #FFFFFF;
  --accent-hover: #647385;
  --highlight: #E1E821;
  --on-highlight: #111318;
  --highlight-ink: #686D20;
  --highlight-hover: #D5DB20;
  --link: #57677A;
  --focus: #888D20;
  --selection: #EAEEC9;
  --on-selection: #313943;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #37404C;
  --surface: #434C55;
  --raised: #4D555D;
  --text: #F7F7F7;
  --muted: #B4B7BB;
  --border: #565D67;
  --accent: #57677A;
  --on-accent: #FFFFFF;
  --accent-hover: #647385;
  --highlight: #E1E821;
  --on-highlight: #111318;
  --highlight-ink: #E1E821;
  --highlight-hover: #D5DB20;
  --link: #A4AEB8;
  --focus: #E1E821;
  --selection: #6A723F;
  --on-selection: #F7F7F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F69199;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #37404C;
  --surface: #434C55;
  --raised: #4D555D;
  --text: #F7F7F7;
  --muted: #B4B7BB;
  --border: #565D67;
  --accent: #57677A;
  --on-accent: #FFFFFF;
  --accent-hover: #647385;
  --highlight: #E1E821;
  --on-highlight: #111318;
  --highlight-ink: #E1E821;
  --highlight-hover: #D5DB20;
  --link: #A4AEB8;
  --focus: #E1E821;
  --selection: #6A723F;
  --on-selection: #F7F7F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F69199;
}
```
