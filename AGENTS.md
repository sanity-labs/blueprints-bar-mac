# Agent Guidelines for BlueprintsBar

## Project Overview

BlueprintsBar is a native macOS menubar app for browsing Sanity Blueprints API data. It is **read-only** — no POST, PUT, or DELETE operations. The app reads auth tokens from the local Sanity CLI config at `~/.config/sanity/config.json` (production).

## Architecture

Pure SwiftUI, macOS 14+ deployment target. The app uses two scenes:

- `MenuBarExtra` with `.window` style — the primary popover UI
- `Window` scene — a detachable standalone window opened via menu action

Both scenes render the same `ContentView` and share a single `AppState` (via `@Observable` + `.environment()`). Navigation is a manual stack (`[Route]`) on `AppState`, not `NavigationStack` — this keeps both scenes in sync without framework-level navigation conflicts.

The API client (`BlueprintsClient`) is immutable and `Sendable`. Changing environment or scope creates a new client instance rather than mutating state.

## Key Constraints

**Minimal code footprint.** Prefer SwiftUI built-ins over custom styling. Let the framework handle materials, spacing, and colors. Every custom modifier is a maintenance burden — only add them when the default is clearly wrong.

**Don't fight the framework.** We tried intercepting `MenuBarExtra` clicks with custom `NSStatusItem`/`NSPopover` — it worked but doubled the code and lost all system styling. The current approach accepts that the popover and detached window can coexist, because shared state keeps them in sync. Concessions that simplify code are better than clever hacks.

**LSUIElement app.** No dock icon. The menubar icon is the only entry point. `NSApplication.shared.activate()` is required when opening the detached window — LSUIElement apps don't activate automatically.

**No App Sandbox.** The app reads `~/.config/sanity/` which requires filesystem access outside the sandbox. This is a developer tool, not an App Store app.

**Swift 6 strict concurrency.** All model types must conform to `Sendable`. `AnyCodable` uses `@unchecked Sendable` because it wraps `Any` but only ever contains value types from JSON. The CI builds in Release mode (`-O`) which is stricter than Debug — always test with Release configuration before pushing.

## API Details

Two base URLs controlled by environment:
- Production: `https://api.sanity.io`
- Staging

Blueprints endpoints are under `/vX/blueprints` with headers:
- `Authorization: Bearer <token>`
- `x-sanity-scope-type: organization|project`
- `x-sanity-scope-id: <id>`

Management API (orgs, projects) uses `/v2021-06-07/` prefix, no scope headers.

The staging environment is only shown in the UI when sanity-staging config exists on disk.

## Build and Release

Build locally:
```
xcodebuild -project BlueprintsBar.xcodeproj -scheme BlueprintsBar -configuration Debug build
```

Always verify Release builds before pushing — stricter Swift concurrency:
```
xcodebuild -project BlueprintsBar.xcodeproj -scheme BlueprintsBar -configuration Release -derivedDataPath build build
```

GitHub Actions builds and releases on `v*` tags. The app is unsigned — users clear quarantine with `xattr -cr` or System Settings. The Xcode project file is generated via Python script (see git history) when source files are added or removed.

## Style Preferences

- Lean on SwiftUI defaults for spacing, colors, and materials
- Use semantic styles (`.secondary`, `.tertiary`, `.quaternary`) not custom colors
- Keep views flat and declarative — avoid deep nesting or coordinator patterns
- Async data loading with `.task {}` modifier, not `onAppear` + Task
- Error and loading states as simple inline views, not separate components
- Prefer computed properties over helper methods when no parameters needed
