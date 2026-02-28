# BlueprintsBar

A macOS menubar app for browsing [Sanity Blueprints](https://www.sanity.io/docs/blueprints) stacks, resources, operations, and logs. Read-only.

## Install

Download `BlueprintsBar.zip` from the [latest release](../../releases/latest), unzip, and move to `/Applications`.

The app is not signed. To open it for the first time, either:

- Run `xattr -cr /Applications/BlueprintsBar.app` in Terminal, then open normally
- Or attempt to open, then go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**

## Prerequisites

Log in with the [Sanity CLI](https://www.sanity.io/docs/cli) so an auth token exists at `~/.config/sanity/config.json`:

```
npx @sanity/cli login
```

## Usage

Click the menubar icon to open the popover. Select an organization or project, then browse stacks.

- **Open in Window** — from the menu, detach into a standalone resizable window
- **Quit** — from the menu, or ⌘Q

## Build from source

```
xcodebuild -project BlueprintsBar.xcodeproj -scheme BlueprintsBar -configuration Release build
```

Requires Xcode 16+ and macOS 14+.
