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

`OperationDetailView` runs two `.task {}` modifiers in parallel: one to fetch the single operation (for `systemMessage`/`userMessage`), one to fetch logs. The logs flow doesn't block on the operation fetch, and a failed operation refresh keeps the list-derived data.

The stack list is sorted client-side by `recentOperation?.createdAt ?? createdAt`, descending. The API doesn't guarantee ordering by recent activity, so the sort happens in `StackListView.filteredStacks`.

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

`Operation` exposes `systemMessage` and `userMessage` from the single-operation endpoint. The operations list row uses these as its title (preferring `userMessage`, then the first non-empty line of `systemMessage`, then "No message" with `.tertiary` styling).

`Resource` exposes `resolvedParameters` (parameters with templates expanded). Rendered in `ResourceDetailView` as a collapsed `DisclosureGroup`, only when non-nil and non-empty.

**Note:** The API has an inconsistency where nested objects in some responses use `snake_case` keys while top-level fields use `camelCase`. The `Operation` model handles this with a custom decoder that tries both key conventions.

## Display conventions

Many list rows and metadata blocks render small `·`-separated runs of text. To keep the eye trained, follow this order.

**Caption line, left to right:**

1. `id` (monospaced)
2. counts (e.g. "5 resources")
3. kind / type (e.g. resource type string)
4. timestamp (the row's primary event time)
5. secondary refs (parent IDs, etc.)

Captions don't use label prefixes. Fields are positional only.

`blueprintId` is intentionally omitted from list-row captions and the stack header — users rarely need it for navigation. It surfaces in the operation detail view header (where it's the only place it's actionable context).

**Right column of list rows, left to right:**

1. duration (`Xs`) — only when paired with a known completion
2. status indicator (shape via `StatusIndicator`)
3. status text (uppercase caption, when meaningful)
4. chevron (when navigable)

**Header metadata** (e.g. `StackDetailView.header`) is freer than list rows but groups into clusters: identity (`id · count`) first, then the recent-operation cluster (`statusIndicator opId · createdAt · Xs`). Duration stays inside the operation cluster since the header has no list-row right column.

**Detail views** (single-resource, single-operation) use labeled `metadataRow` pairs for created/updated/etc. The caption-line convention applies only to list rows and the stack header.

**Log rows** use `.system(.caption, design: .monospaced)` for the message body. The timestamp/level header is `.caption2` monospaced. Logs render inside a `List` with `.listStyle(.plain)`; do not replace this with a `ScrollView`.

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
