# Graph Report - ollama-monitor  (2026-11-23)

## Corpus Check
- 16 files · ~16,806 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 339 nodes · 566 edges · 31 communities (10 shown, 17 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 59 edges (avg confidence: 0.82)
- Token cost: 89,236 input · 0 output

## Community Hubs (Navigation)
- macOS Menu-Bar UI
- Go Tray App Core
- Swift Model Types
- Swift API Client
- macOS Monitor State
- Monitor Tests
- OllamaKit Tests
- Changelog & macOS Plan
- Swift Formatting Helpers
- README Features
- macOS Build Script
- Swift Package Manifest
- Blue Tray Icon
- Green Tray Icon
- Red Tray Icon
- Orphan Type Data
- Orphan Type Date
- Orphan Type Int
- Orphan Type Int64
- Orphan Type OllamaClient
- Go Module
- Orphan Type Set
- Orphan Type URL
- Orphan Type URLRequest
- Orphan Type URLSession
- Orphan Type UserDefaults
- Orphan Type Void

## God Nodes (most connected - your core abstractions)
1. `Monitor` - 44 edges
2. `OllamaClient` - 29 edges
3. `RunningModel` - 21 edges
4. `InstalledModel` - 19 edges
5. `ServerSnapshot` - 16 edges
6. `Ollama Monitor` - 13 edges
7. `ModelDetails` - 11 edges
8. `HeaderView` - 11 edges
9. `Ollama Monitor for macOS plan` - 10 edges
10. `StubURLProtocol` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Ollama Monitor for macOS plan` --semantically_similar_to--> `Ollama Monitor`  [INFERRED] [semantically similar]
  macos/PLAN.md → README.md
- `Adaptive polling (10s idle, 3s running)` --semantically_similar_to--> `OllamaMonitor app target (MenuBarExtra, Monitor poller, views)`  [INFERRED] [semantically similar]
  CHANGELOG.md → macos/PLAN.md
- `Proxy support and SSL bypass` --conceptually_related_to--> `Ollama Monitor`  [INFERRED]
  CHANGELOG.md → README.md
- `OllamaKit (API client, types, formatting)` --references--> `OllamaClient`  [INFERRED]
  macos/PLAN.md → macos/Sources/OllamaKit/OllamaClient.swift
- `main()` --calls--> `Run()`  [EXTRACTED]
  main.go → monitor/monitor.go

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **macOS app layering: OllamaKit, app target, snapshot mode** — macos_plan_ollamakit, macos_plan_ollamamonitor_target, macos_plan_snapshot_mode, macos_plan_build_script [INFERRED 0.85]
- **Popover UI components** — macos_plan_popover, macos_plan_model_card, macos_plan_installed_models, macos_plan_settings_window [INFERRED 0.85]
- **Ollama Monitor Frontends Sharing Ollama Status Monitoring** — readme_go_tray_app, readme_macos_native_app, readme_ollama [INFERRED 0.75]

## Communities (31 total, 17 thin omitted)

### Community 0 - "macOS Menu-Bar UI"
Cohesion: 0.06
Nodes (40): App, AppKit, Color, MenuBarLabel, .body, OllamaMonitorApp, .body, HeaderView (+32 more)

### Community 1 - "Go Tray App Core"
Cohesion: 0.07
Nodes (35): net/url.URL, os.File, sync.Mutex, testing.T, main(), getRunningModels(), initHTTPClient(), markOffline() (+27 more)

### Community 2 - "Swift Model Types"
Cohesion: 0.11
Nodes (31): Decodable, Equatable, Identifiable, Int64, LocalizedError, InstalledModel, .badges, .canGenerate (+23 more)

### Community 3 - "Swift API Client"
Cohesion: 0.11
Nodes (20): JSONDecoder, OllamaClient, .displayHost, .isLocal, badURL, http, Bool, Data (+12 more)

### Community 4 - "macOS Monitor State"
Cohesion: 0.10
Nodes (24): Monitor, .apiURL, .displayHost, .notifyModels, .notifyOffline, .pollSeconds, .running, .showCount (+16 more)

### Community 5 - "Monitor Tests"
Cohesion: 0.13
Nodes (20): .body, dropsOutOfOrderRefresh(), isolatedDefaults(), MonitorStubURLProtocol, ok(), previewMonitorPopoverOpenedMakesNoRequests(), serverSwitchDiscardsInFlightAndClearsError(), snapshotResponse() (+12 more)

### Community 6 - "OllamaKit Tests"
Cohesion: 0.11
Nodes (14): clientErrorParsing(), clientSnapshotRunningAndActions(), decodesInstalledModels(), httpResponse(), StubURLProtocol, Bool, Handler, HTTPURLResponse (+6 more)

### Community 7 - "Changelog & macOS Plan"
Cohesion: 0.10
Nodes (22): Adaptive polling (10s idle, 3s running), Proxy support and SSL bypass, Migration from Python to Go, Changelog release history, Startup registry path fix, v1.0.0 initial release, v1.1.0 proxy support release, v1.2.0 Go rewrite release (+14 more)

### Community 8 - "Swift Formatting Helpers"
Cohesion: 0.10
Nodes (14): Foundation, Format, Date, Double, Int, Int64, String, NotificationDelegate (+6 more)

### Community 9 - "README Features"
Cohesion: 0.16
Nodes (17): Build Scripts (build.bat, build.sh, go build), CHANGELOG.md, Customizable API URL Connection, Go Cross-Platform Tray App, MIT License, Native macOS Menu-Bar App (SwiftUI), macOS Popover Model Cards, Multi-Model Support (+9 more)

## Knowledge Gaps
- **54 isolated node(s):** `.body`, `ServiceManagement`, `ollamaMonitor`, `.directory`, `Blue Status Color Variant` (+49 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 130 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Monitor` connect `macOS Monitor State` to `macOS Menu-Bar UI`, `Swift Model Types`, `Swift API Client`, `Monitor Tests`, `Swift Formatting Helpers`?**
  _High betweenness centrality (0.266) - this node is a cross-community bridge._
- **Why does `OllamaClient` connect `Swift API Client` to `Swift Model Types`, `macOS Monitor State`, `OllamaKit Tests`, `Changelog & macOS Plan`, `Swift Formatting Helpers`?**
  _High betweenness centrality (0.259) - this node is a cross-community bridge._
- **Why does `OllamaKit (API client, types, formatting)` connect `Changelog & macOS Plan` to `Swift API Client`?**
  _High betweenness centrality (0.150) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `Monitor` (e.g. with `.body` and `.content`) actually correct?**
  _`Monitor` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `OllamaClient` (e.g. with `OllamaKit (API client, types, formatting)` and `clientErrorParsing()`) actually correct?**
  _`OllamaClient` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `ServiceManagement`, `ollamaMonitor` to the rest of the system?**
  _54 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `macOS Menu-Bar UI` be split into smaller, more focused modules?**
  _Cohesion score 0.06285714285714286 - nodes in this community are weakly interconnected._