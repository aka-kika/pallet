#!/bin/sh
# Builds the model files with the checks in main.swift and runs them.
# Doesn't open the app and doesn't touch the real collection.
set -e
here=$(cd "$(dirname "$0")" && pwd)
src="$here/../Pallet"
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
xcrun swiftc -swift-version 6 -default-isolation MainActor -enable-upcoming-feature NonisolatedNonsendingByDefault \
  -enable-upcoming-feature InferIsolatedConformances -module-name PalletTests -o "$out/pallet-tests" \
  "$here/main.swift" "$src/Model/Palette.swift" "$src/Model/Collections.swift" "$src/Model/Theme.swift" \
  "$src/Model/AppShortcuts.swift" "$src/MenuBar/HotKey.swift" "$src/WhatsNew.swift"
"$out/pallet-tests"
