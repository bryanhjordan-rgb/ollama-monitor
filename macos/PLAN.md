# Ollama Monitor for macOS — plan

A native SwiftUI menu-bar app that replaces the Go tray menu on the Mac with a
popover. The Go app at the repo root stays as-is for Windows and Linux.

## What the popover shows

1. **Header**: status dot (green active, blue idle, red offline), "Ollama 0.40.17",
   the host it talks to.
2. **One card per loaded model** (`/api/ps`): name, parameter size and
   quantization when Ollama reports them, runner (mlx / llama), memory bar
   (VRAM share of size, "9.1 GB · 100% GPU"), context length, a live
   "unloads in 4:12" countdown from `expires_at`, and an **Unload** button
   (`POST /api/generate {model, keep_alive: 0}`).
3. **Installed models** (`/api/tags`), collapsed by default: name, size,
   capability badges (vision, tools, thinking), and **Load** for the ones not
   running (`POST /api/generate {model}`).
4. **Offline / idle states** with `ContentUnavailableView`.
5. **Footer**: Settings… (⌘,), Quit (⌘Q).

Menu-bar icon: a template SF Symbol that changes with the state, plus an
optional count of loaded models.

## Settings window

API URL (validated, http/https, basic auth in URL still works), poll interval,
notifications on model load/unload and on Ollama going offline, show model
count in the menu bar, launch at login (`SMAppService.mainApp`).

## Layout

```
macos/
  Package.swift            Swift package, macOS 26, no Xcode project
  build.sh                 build, sign, install ~/Applications/OllamaMonitor.app
  Info.plist.in            LSUIElement (no Dock icon)
  Sources/OllamaKit/       API client, Codable types, formatting — no SwiftUI
  Sources/OllamaMonitor/   app: MenuBarExtra, Monitor (poller), views, settings
  Tests/OllamaKitTests/    decoding fixtures from real Ollama output, formatting
```

`OllamaMonitor --snapshot <dir>` renders the popover in each state (active,
idle, offline) in light and dark to PNGs with fixture data, then exits, so the
UI can be checked without clicking through the menu bar.

## Iterations (each ends with build + check, then a commit)

1. Package + OllamaKit (types, client, formatting) + tests pass.
2. Monitor (poller, state) + popover views + snapshot mode; review snapshots.
3. Actions: Unload, Load, refresh; errors shown inline.
4. Settings window + persistence + launch at login + menu-bar count.
5. Notifications on model load/unload and offline.
6. build.sh + Info.plist + app icon; install over the Go build in
   ~/Applications; verify live against the local Ollama.
7. README section for macOS; final review of the whole diff.

## Done when

- `swift build` has no warnings, `swift test` passes.
- Snapshots of every state look right in light and dark.
- Installed app shows the real loaded model, Unload and Load work against
  the local Ollama, settings persist across relaunch.
