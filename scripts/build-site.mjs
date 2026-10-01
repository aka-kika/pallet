#!/usr/bin/env node
// Build the web app as static files for akakika.com/pallet and copy them into
// the site repo (public/pallet/). collection.json there is left alone: it is
// written by scripts/pallet-publish.mjs.
//
//   node scripts/build-site.mjs [--site <path>]
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const args = process.argv.slice(2);
const i = args.indexOf('--site');
const site = path.resolve(i >= 0 ? args[i + 1] : path.join(os.homedir(), 'Documents/PROJECTS/02_WEB/akakika.com'));
const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

execFileSync(path.join(root, 'node_modules/.bin/vite'), ['build', '--config', 'vite.site.config.ts'], {cwd: root, stdio: 'inherit'});

const out = path.join(site, 'public/pallet');
fs.mkdirSync(out, {recursive: true});
// Old hashed bundles go; the published collection stays.
for (const name of fs.readdirSync(out)) {
  if (name !== 'collection.json') fs.rmSync(path.join(out, name), {recursive: true, force: true});
}
fs.cpSync(path.join(root, 'dist-site'), out, {recursive: true});
console.log('Copied the Pallet page into', out);
