#!/usr/bin/env node
// Publish Kika's Pallet collection to akakika.com/pallet.
//
// Reads the Mac app's collection (~/Library/Application Support/Palette),
// keeps only names, colors and the main color, and writes
// <site>/public/pallet/collection.json. Does nothing when nothing changed.
// Then commits that one file and pushes main (akakika.com deploys on push).
//
//   node scripts/pallet-publish.mjs            write, commit, push
//   node scripts/pallet-publish.mjs --no-push  write and commit only
//   node scripts/pallet-publish.mjs --dry-run  only show what would change
//   --site <path>   the akakika.com repo (default ~/Documents/PROJECTS/02_WEB/akakika.com)
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const args = process.argv.slice(2);
const flag = name => args.includes(name);
const option = name => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : undefined; };
const site = path.resolve(option('--site') ?? path.join(os.homedir(), 'Documents/PROJECTS/02_WEB/akakika.com'));
const dataDir = path.join(os.homedir(), 'Library/Application Support/Palette');
const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

const readJSON = (file, fallback) => { try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { if (fs.existsSync(file)) throw new Error(`Cannot read ${file}: ${e.message}`); return fallback; } };
const valid = p => p && typeof p.id === 'string' && /^[\w-]{1,80}$/.test(p.id) && typeof p.name === 'string' && p.name.trim() && p.name.length <= 100
  && Array.isArray(p.colors) && p.colors.length >= 2 && p.colors.length <= 10 && p.colors.every(c => /^#[\da-f]{6}$/i.test(c))
  && Number.isInteger(p.main) && p.main >= 0 && p.main < p.colors.length;

// Same merge as the app: built-ins not deleted or edited, then your own.
const builtins = readJSON(path.join(root, 'shared/builtin-palettes.json'), []);
const saved = readJSON(path.join(dataDir, 'palettes.json'), []).filter(valid);
const hidden = new Set(readJSON(path.join(dataDir, 'hidden.json'), []));
const order = new Map(builtins.map((p, i) => [p.id, i]));
const all = [...builtins.filter(b => !saved.some(p => p.id === b.id) && !hidden.has(b.id)), ...saved]
  .map((p, i) => ({p, i}))
  .sort((a, b) => ((order.get(a.p.id) ?? 1000) - (order.get(b.p.id) ?? 1000)) || a.i - b.i)
  .map(({p}) => ({id: p.id, name: p.name.trim(), colors: p.colors.map(c => c.toUpperCase()), main: p.main, favorite: false, source: "Kika's collection"}));

const target = path.join(site, 'public/pallet/collection.json');
const before = readJSON(target, null);
if (before && JSON.stringify(before.palettes) === JSON.stringify(all)) {
  console.log(`No change: ${all.length} palettes already published.`);
  process.exit(0);
}
const names = list => new Set((list ?? []).map(p => p.id));
const was = names(before?.palettes), now = names(all);
console.log(`${all.length} palettes (${[...now].filter(id => !was.has(id)).length} new, ${[...was].filter(id => !now.has(id)).length} removed).`);
if (flag('--dry-run')) process.exit(0);

fs.mkdirSync(path.dirname(target), {recursive: true});
fs.writeFileSync(target, JSON.stringify({version: 1, updated: new Date().toISOString().slice(0, 10), palettes: all}, null, 1) + '\n');

const git = (...a) => execFileSync('git', ['-C', site, ...a], {encoding: 'utf8'}).trim();
const rel = path.relative(site, target);
git('add', rel);
git('commit', '-m', `Pallet: publish collection (${all.length} palettes)`, '--', rel);
console.log('Committed', rel);
if (flag('--no-push')) process.exit(0);

// Push only a clean publish: on main, and nothing else waiting to go out.
const branch = git('rev-parse', '--abbrev-ref', 'HEAD');
git('fetch', '-q', 'origin', 'main');
const ahead = Number(git('rev-list', '--count', 'origin/main..HEAD'));
if (branch !== 'main' || ahead !== 1) {
  console.log(`Not pushed: the site repo is on ${branch} with ${ahead} commits ahead of origin/main. Push it yourself after a look.`);
  process.exit(0);
}
git('push', '-q', 'origin', 'main');
console.log('Pushed. akakika.com/pallet updates in about a minute.');
