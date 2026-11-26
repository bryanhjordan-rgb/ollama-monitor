# Ollama Monitor
Purpose: cross-platform tray app that shows which Ollama models are loaded. Go tray (Windows/Linux/macOS) plus a native macOS menu-bar app.
Layout: `main.go` + `monitor/` (Go tray, poll loop) · `macos/` (SwiftPM: `OllamaKit`, `OllamaMonitor`, `build.sh`) · `todo.md` open items.
Check: `scripts/check.sh` runs `go test -race ./...` and `swift test --package-path macos` · Lock: none · Install: `macos/build.sh` (installs `~/Applications/OllamaMonitor.app`; `--open` restarts the running copy)
Cycle overrides: Push: yes · Default branch: main
Pointers: `macos/PLAN.md` · `CHANGELOG.md` · `todo.md` · [docs/agent-reference.md](docs/agent-reference.md) (how refresh, filter, Finder and delete work)
