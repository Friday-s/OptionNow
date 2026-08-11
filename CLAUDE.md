# OptionNow project rules

- Build a macOS-only, local-first desktop utility launcher.
- Keep the implementation native with SwiftUI and AppKit.
- Make surgical changes that map directly to the accepted PRD.
- Do not add accounts, cloud sync, a plugin marketplace, or unrelated automation.
- Keep external application targets configurable; never hardcode personal absolute paths.
- Store API credentials only in Keychain when translation is implemented.
- Treat `AGENTS.md` as a symlink mirror of this file and edit only `CLAUDE.md`.
