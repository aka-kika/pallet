# Wallet Lime

Source: Earlier theme collection

Original palette: #D7F266, #151514, #D3DDDA, #F7F8F6

Main color: #D7F266

## Light and soft dark

UI shades are derived from the original palette. Text pairs are contrast-adjusted.

| Role | Light | Dark |
| --- | --- | --- |
| background | #F5F9EF | #292D21 |
| surface | #F8FAF4 | #36392E |
| raised | #EFF5E0 | #404438 |
| text | #151514 | #F5F5F7 |
| muted | #636561 | #AEAFAC |
| border | #D1D5CC | #4A4D43 |
| accent | #D7F266 | #D7F266 |
| on-accent | #111318 | #111318 |
| accent-hover | #C7E060 | #C7E060 |
| highlight | #151514 | #151514 |
| on-highlight | #FFFFFF | #FFFFFF |
| highlight-ink | #151514 | #979796 |
| highlight-hover | #232322 | #232322 |
| link | #6A773B | #D7F266 |
| focus | #151514 | #797978 |
| selection | #C8CBC3 | #23261D |
| on-selection | #151514 | #F5F5F7 |
| success | #367749 | #86C89D |
| warning | #8D641D | #EAC16B |
| danger | #B03448 | #F58A93 |

## CSS

```css
/* Wallet Lime · primary #D7F266 */
:root, [data-theme="light"] {
  color-scheme: light;
  --background: #F5F9EF;
  --surface: #F8FAF4;
  --raised: #EFF5E0;
  --text: #151514;
  --muted: #636561;
  --border: #D1D5CC;
  --accent: #D7F266;
  --on-accent: #111318;
  --accent-hover: #C7E060;
  --highlight: #151514;
  --on-highlight: #FFFFFF;
  --highlight-ink: #151514;
  --highlight-hover: #232322;
  --link: #6A773B;
  --focus: #151514;
  --selection: #C8CBC3;
  --on-selection: #151514;
  --success: #367749;
  --warning: #8D641D;
  --danger: #B03448;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
  --background: #292D21;
  --surface: #36392E;
  --raised: #404438;
  --text: #F5F5F7;
  --muted: #AEAFAC;
  --border: #4A4D43;
  --accent: #D7F266;
  --on-accent: #111318;
  --accent-hover: #C7E060;
  --highlight: #151514;
  --on-highlight: #FFFFFF;
  --highlight-ink: #979796;
  --highlight-hover: #232322;
  --link: #D7F266;
  --focus: #797978;
  --selection: #23261D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
  }
}

[data-theme="dark"] {
  color-scheme: dark;
  --background: #292D21;
  --surface: #36392E;
  --raised: #404438;
  --text: #F5F5F7;
  --muted: #AEAFAC;
  --border: #4A4D43;
  --accent: #D7F266;
  --on-accent: #111318;
  --accent-hover: #C7E060;
  --highlight: #151514;
  --on-highlight: #FFFFFF;
  --highlight-ink: #979796;
  --highlight-hover: #232322;
  --link: #D7F266;
  --focus: #797978;
  --selection: #23261D;
  --on-selection: #F5F5F7;
  --success: #86C89D;
  --warning: #EAC16B;
  --danger: #F58A93;
}
```
