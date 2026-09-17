# Storm Cloud

Source: Photo reference

Original palette: #101721, #434A54, #838694, #474958

Main color: #434A54

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #D4D7DB | #181D24 |
| surface | #E3E5E7 | #23282F |
| raised | #C2C5CA | #2D3138 |
| text | #101721 | #F5F5F7 |
| muted | #555A62 | #A8A9AD |
| border | #B5B8BD | #3B4046 |
| accent | #434A54 | #434A54 |
| on-accent | #FFFFFF | #FFFFFF |
| accent-hover | #525862 | #525862 |
| highlight | #838694 | #838694 |
| on-highlight | #111318 | #111318 |
| highlight-ink | #575A64 | #838694 |
| highlight-hover | #7C7F8D | #7C7F8D |
| link | #434A54 | #858A91 |
| focus | #70737F | #838694 |
| selection | #C4C7CD | #383D46 |
| on-selection | #101721 | #F5F5F7 |
| success | #306640 | #86C89D |
| warning | #78561D | #EAC16B |
| danger | #A63245 | #F58A93 |

## CSS

```css
/* Storm Cloud · primary #434A54 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #D4D7DB;
  --surface: #E3E5E7;
  --raised: #C2C5CA;
  --text: #101721;
  --muted: #555A62;
  --border: #B5B8BD;
  --accent: #434A54;
  --on-accent: #FFFFFF;
  --accent-hover: #525862;
  --highlight: #838694;
  --on-highlight: #111318;
  --highlight-ink: #575A64;
  --highlight-hover: #7C7F8D;
  --link: #434A54;
  --focus: #70737F;
  --selection: #C4C7CD;
  --on-selection: #101721;
  --success: #306640;
  --warning: #78561D;
  --danger: #A63245;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #181D24;
  --surface: #23282F;
  --raised: #2D3138;
  --text: #F5F5F7;
  --muted: #A8A9AD;
  --border: #3B4046;
  --accent: #434A54;
  --on-accent: #FFFFFF;
  --accent-hover: #525862;
  --highlight: #838694;
  --on-highlight: #111318;
  --highlight-ink: #838694;
  --highlight-hover: #7C7F8D;
  --link: #858A91;
  --focus: #838694;
  --selection: #383D46;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #181D24;
  --surface: #23282F;
  --raised: #2D3138;
  --text: #F5F5F7;
  --muted: #A8A9AD;
  --border: #3B4046;
  --accent: #434A54;
  --on-accent: #FFFFFF;
  --accent-hover: #525862;
  --highlight: #838694;
  --on-highlight: #111318;
  --highlight-ink: #838694;
  --highlight-hover: #7C7F8D;
  --link: #858A91;
  --focus: #838694;
  --selection: #383D46;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
