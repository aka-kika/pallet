# Security Policy

## Supported versions

Only the latest release gets fixes.

| Version | Supported |
|---|---|
| 2.x (SwiftUI, macOS 26+) | Yes |
| 1.x (Electron) | No |

## How Pallet handles your data

- Everything runs on your Mac. Images are read on the device with Apple's Vision; nothing is uploaded.
- The collection is plain JSON in `~/Library/Application Support/Palette/`.
- Screen capture uses the system picker (`screencapture -i`) and needs the Screen Recording permission, which you grant in System Settings.
- The app is signed with a Developer ID and notarized by Apple.
- The web version at akakika.com/pallet keeps a visitor's own palettes in their browser only.

## Reporting a vulnerability

Please report it privately, not in a public issue:

1. Open the repository's **Security** tab.
2. Click **Report a vulnerability**.

Include the version, your macOS version, and the steps to reproduce. You can expect a first answer within 7 days. Once a fix is released, the report can be made public with credit to you, if you want it.
