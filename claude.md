# Working on Ollama Monitor

The Go tray routes manual and API URL refreshes through the existing poll loop. The native macOS filter works on the installed models already in the current snapshot. Finder looks up named manifests in the local model store. Model deletion goes through Ollama's API and refreshes that snapshot.

- Go tests with the race detector: `go test -race ./...`
- Swift tests: `swift test --package-path macos`
