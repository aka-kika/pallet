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

You need Node.js 24 or newer.

```
pnpm install --frozen-lockfile
pnpm run dev
```

The web UI is at `http://localhost:5173/`. To build the Mac app:

```
npm ci --prefix desktop/runtime
node desktop/build.mjs
node desktop/package.mjs
```

See **[docs/mac.md](docs/mac.md)** for the unsigned app.

## Making a change

- Branch from `main`; name it `fix/short-description` or `feat/short-description`.
- Match the existing style. No emojis in UI copy or markdown.
- Add or update tests when you change desktop server behaviour: `node --test desktop/server.test.cjs`.

## Commit messages

Imperative mood, present tense: "Add X", not "Added X". Keep the first line under 72 characters.

## Submitting a pull request

- Confirm the web app and, if you touched desktop code, the test command pass locally.
- Link the issue it closes.

## Conduct and licensing

Be civil; assume good faith. By contributing, you agree your work is licensed under MIT (the project's license).
