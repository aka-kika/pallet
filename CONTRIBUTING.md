<!--
Contributing for Pallet. No emojis. One change per pull request.
-->

# Contributing to Pallet

Thanks for taking the time. This page covers how to get set up, what makes a change easy to accept, and how to submit it.

The maintainer is one person and replies when she can.

## Before you start

- For anything non-trivial, open an issue first so we agree on the approach before you build. Small fixes can go straight to a pull request.
- Keep the change focused; one concern per pull request.

## Getting set up

The Mac app needs Xcode 27.2 or newer on macOS 26 or newer:

```
xcodebuild -project swiftui/Pallet.xcodeproj -scheme Pallet build
```

See **[docs/mac.md](docs/mac.md)**. The web version needs Node.js 24 or newer:

```
pnpm install --frozen-lockfile
pnpm run dev
```

The web UI is at `http://localhost:5173/`.

## Making a change

- Branch from `main`; name it `fix/short-description` or `feat/short-description`.
- Match the existing style. No emojis in UI copy or markdown.
- Theme math lives in two places that must agree: `lib/palettes.ts` and `swiftui/Pallet/Model/Theme.swift`. Run `pnpm check:contrast` after changing either.

## Commit messages

Imperative mood, present tense: "Add X", not "Added X". Keep the first line under 72 characters.

## Submitting a pull request

- Confirm the Mac app builds and `pnpm check:contrast` passes; for web changes, `pnpm build` too.
- Link the issue it closes.

## Conduct and licensing

Be civil; assume good faith. By contributing, you agree your work is licensed under MIT (the project's license).
