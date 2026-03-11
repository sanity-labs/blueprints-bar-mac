# Agent Guidelines for BlueprintsBar

## Project Overview

BlueprintsBar is a native macOS menubar app for browsing Sanity Blueprints API data. It is **read-only** — no POST, PUT, or DELETE operations. The app reads auth tokens from the local Sanity CLI config at `~/.config/sanity/config.json`.

## Architecture

Pure SwiftUI, macOS 14+ (Sonoma) deployment target. The app uses two scenes:

- `MenuBarExtra` with `.window` style — the primary popover UI
- `Window` scene — a detachable standalone window opened via menu action

Both scenes render the same `ContentView` and share a single `AppState` (via `@Observable` + `.environment()`). Navigation is a manual stack (`[Route]`) on `AppState`, not `NavigationStack` — this keeps both scenes in sync without framework-level navigation conflicts.

The API client (`BlueprintsClient`) is immutable and `Sendable`. Changing environment or scope creates a new client instance rather than mutating state.

### Data loading pattern

All API data is loaded lazily using the `.task {}` modifier on the view that needs it. Each tab in the stack detail view fetches its own data when selected, and re-fetches on every visit to ensure freshness. The single stack endpoint provides the header data (name, recent operation, resource count) while dedicated list endpoints provide the tab contents.

Models use `Decodable` (not `Codable`) since the app is read-only and never encodes models back to JSON.

## Key Constraints

**Minimal code footprint.** Prefer SwiftUI built-ins over custom styling. Let the framework handle materials, spacing, and colors. Every custom modifier is a maintenance burden — only add them when the default is clearly wrong.

**Don't fight the framework.** We tried intercepting `MenuBarExtra` clicks with custom `NSStatusItem`/`NSPopover` — it worked but doubled the code and lost all system styling. We also tried `NSEvent` monitors for right-click context menus on the menubar icon — not possible in pure SwiftUI, so we kept the existing menu structure. Concessions that simplify code are better than clever hacks.

**SwiftUI only.** Avoid AppKit except where SwiftUI has no reasonable alternative. Current exceptions: `NSApplication.shared.activate()` (required for LSUIElement apps), `NSApplication.shared.terminate()`, and `NSPasteboard.general` (no SwiftUI clipboard API on macOS). If a feature requires deeper AppKit integration, reconsider whether it's needed.

**LSUIElement app.** No dock icon. The menubar icon is the only entry point. `NSApplication.shared.activate()` is required when opening the detached window — LSUIElement apps don't activate automatically.

**No App Sandbox.** The app reads `~/.config/sanity/` which requires filesystem access outside the sandbox. This is a developer tool, not an App Store app.

**Swift 6 strict concurrency.** All model types must conform to `Sendable`. `AnyCodable` uses `@unchecked Sendable` because it wraps `Any` but only ever contains value types from JSON. The CI builds in Release mode (`-O`) which is stricter than Debug — always test with Release configuration before pushing.

**Colorblind-friendly status indicators.** Shape encodes state (circle = success, square = failure), color reinforces it. Never rely on color alone.

**Fixed timestamp format.** Use `yyyy-MM-dd HH:mm` (or `HH:mm:ss` for logs), not locale-dependent formatting.

## API Details

Blueprints endpoints are under `/vX/blueprints` with headers:
- `Authorization: Bearer <token>`
- `x-sanity-scope-type: organization|project`
- `x-sanity-scope-id: <id>`

Management API (orgs, projects) uses `/v2021-06-07/` prefix, no scope headers.

The app supports multiple API environments. Additional environments are only shown when their corresponding CLI config directory exists on disk.

**Note:** The API has an inconsistency where nested objects in some responses use `snake_case` keys while top-level fields use `camelCase`. The `Operation` model handles this with a custom decoder that tries both key conventions.

## Build and Release

Build locally:
```
xcodebuild -project BlueprintsBar.xcodeproj -scheme BlueprintsBar -configuration Debug build
```

Always verify Release builds before pushing — stricter Swift concurrency:
```
xcodebuild -project BlueprintsBar.xcodeproj -scheme BlueprintsBar -configuration Release -derivedDataPath build build
```

GitHub Actions builds and releases on `v*` tags. The app is unsigned — users clear quarantine with `xattr -cr` or System Settings.

The Xcode project file (`project.pbxproj`) was generated via script. Adding or removing source files requires updating it manually or regenerating.

## Style Preferences

- Lean on SwiftUI defaults for spacing, colors, and materials
- Use semantic styles (`.secondary`, `.tertiary`, `.quaternary`) not custom colors
- Keep views flat and declarative — avoid deep nesting or coordinator patterns
- Load data with `.task {}`, not `onAppear` + Task
- Error and loading states as simple inline views, not separate components
- Prefer computed properties over helper methods when no parameters needed
- Don't make extra API calls that aren't justified — each endpoint fetch should serve a clear purpose
- Always ask the user before git operations (commit, push, tag)
