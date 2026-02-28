# BlueprintsBar

A macOS menubar app for browsing [Sanity Blueprints](https://www.sanity.io/docs/blueprints) stacks, resources, operations, and logs. Read-only.

## Install

Download `BlueprintsBar.zip` from the [latest release](../../releases/latest), unzip, and move to `/Applications`.

> **Note**: The app is not signed. On first launch, right-click the app → **Open** to bypass Gatekeeper.

## Prerequisites

Log in with the [Sanity CLI](https://www.sanity.io/docs/cli) so an auth token exists at `~/.config/sanity/config.json`:

```
npm create sanity@latest -- --login
```

## Usage

Click the menubar icon (☐⃞) to open the popover. Select an organization or project, then browse stacks.

- **Environment switcher** — toggle between sanity.io and sanity.work (staging only visible for Sanity employees)
- **Open in Window** — from the menu, detach into a standalone window
- **Quit** — from the menu, or ⌘Q

## Build from source

```
xcodebuild -project BlueprintsBar.xcodeproj -scheme BlueprintsBar -configuration Release build
```

Requires Xcode 16+ and macOS 14+.
