# Up!

A lightweight macOS menu bar utility that prevents your Mac from sleeping. No Dock icon, no windows — just a clean tray icon.

## Features

- **One-click toggle** — Left-click the menu bar icon to prevent sleep instantly
- **Timed activation** — Right-click to choose 15min, 30min, 1hr, 2hr, or 4hr
- **Visual indicator** — Shows `Up` when inactive, `Up!` when active
- **Launch at Login** — Optional auto-start on boot
- **Zero footprint** — No Dock icon, no windows, menu bar only

## Install

### Download

Grab the latest `Up!.app.zip` from [Releases](../../releases/latest), unzip, and move to your Applications folder.

> On first launch, right-click the app and select **Open** if macOS blocks it (the app is not notarized).

### Build from source

Requires macOS 13+ and Swift command-line tools.

```bash
./build.sh
open "build/Up!.app"
```

## Usage

| Action | Result |
|---|---|
| Left-click tray icon | Toggle sleep prevention on/off |
| Right-click tray icon | Open menu with timer options and settings |

## Requirements

- macOS 13.0 (Ventura) or later

## License

MIT
