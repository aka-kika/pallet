// Contrast check for palette-derived UI themes.
// For every seed palette, every main color (as arrow keys rotate), light and
// soft dark, lock off and on: every text color must reach 4.5:1 against every
// surface it can sit on (background, surface, raised); focus rings 3:1.
// Prints each failure as: palette, main color, mode, pair, ratio. Exits 1 on failure.
const m = await import('../lib/palettes.ts');

const { seeds, theme, withLockedBackground, contrast } = m;

const TEXT_45 = ['text', 'muted', 'highlight-ink', 'link', 'success', 'warning', 'danger'];
const SURFACES = ['background', 'surface', 'raised'];
const ON_PAIRS = [
  ['on-accent', 'accent'],
  ['on-highlight', 'highlight'],
  ['on-selection', 'selection'],
];

let failures = 0;
for (const seed of seeds) {
  for (let main = 0; main < seed.colors.length; main++) {
    const p = { ...seed, main };
    for (const dark of [false, true]) {
      for (const locked of [false, true]) {
        let t = theme(p, dark);
        if (locked) t = withLockedBackground(t, t.background, dark);
        const mode = `${dark ? 'dark' : 'light'}${locked ? '+lock' : ''}`;
        for (const fg of TEXT_45) {
          for (const bg of SURFACES) {
            const r = contrast(t[fg], t[bg]);
            if (r < 4.5) {
              failures++;
              console.log(`${seed.name} | main ${p.colors[main]} | ${mode} | ${fg} on ${bg} | ${r.toFixed(2)}:1`);
            }
          }
        }
        for (const bg of SURFACES) {
          const r = contrast(t.focus, t[bg]);
          if (r < 3) {
            failures++;
            console.log(`${seed.name} | main ${p.colors[main]} | ${mode} | focus on ${bg} | ${r.toFixed(2)}:1`);
          }
        }
        for (const [fg, bg] of ON_PAIRS) {
          const r = contrast(t[fg], t[bg]);
          if (r < 4.5) {
            failures++;
            console.log(`${seed.name} | main ${p.colors[main]} | ${mode} | ${fg} on ${bg} | ${r.toFixed(2)}:1`);
          }
        }
      }
    }
  }
}
console.log(failures === 0 ? 'PASS: no contrast failures' : `FAIL: ${failures} contrast failures`);
process.exit(failures === 0 ? 0 : 1);
