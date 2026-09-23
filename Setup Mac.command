#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Building Pallet for this Mac…"
if command -v brew >/dev/null 2>&1; then
  brew_bin="$(brew --prefix 2>/dev/null)/bin"
  [ -x "$brew_bin/node" ] && PATH="$brew_bin:$PATH"
fi
if ! command -v node >/dev/null 2>&1; then
  echo "Install Node.js 24 LTS from https://nodejs.org, then run this file again."
  read -r -p "Press Return to close. "
  exit 1
fi
node -e 'if (Number(process.versions.node.split(".")[0]) < 24) { console.error("Install Node.js 24 LTS or newer first."); process.exit(1); }'
npx --yes pnpm@11.25.0 install --frozen-lockfile
node desktop/build.mjs
npm ci --prefix desktop/runtime
node desktop/package.mjs
open desktop/release
echo "Done. Move Pallet.app from the folder that opened into Applications."
read -r -p "Press Return to close. "
