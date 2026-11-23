# Graph Report - ollama-monitor  (2026-11-23)

## Corpus Check
- 29 files · ~16,806 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 328 nodes · 572 edges · 22 communities (11 shown, 6 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 57 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `39de5294`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- HeaderView
- api.go
- RunningModel
- OllamaClient
- Monitor
- MonitorTests.swift
- OllamaKitTests.swift
- Ollama Monitor for macOS plan
- .bytes
- Ollama Monitor
- build.sh
- Package.swift
- Blue Status Color Variant
- Green Llama Tray Icon
- Red Llama Tray Icon
- Foundation
- ollamaMonitor

## God Nodes (most connected - your core abstractions)
1. `Monitor` - 44 edges
2. `OllamaClient` - 29 edges
3. `RunningModel` - 21 edges
4. `InstalledModel` - 19 edges
5. `ServerSnapshot` - 16 edges
6. `Ollama Monitor` - 13 edges
7. `ModelDetails` - 11 edges
8. `HeaderView` - 11 edges
9. `StubURLProtocol` - 10 edges
10. `MonitorStubURLProtocol` - 10 edges

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
- **Ollama Monitor Frontends Sharing Ollama Status Monitoring** — readme_go_tray_app, readme_macos_native_app, readme_ollama [INFERRED 0.75]
- **macOS app layering: OllamaKit, app target, snapshot mode** — macos_plan_ollamakit, macos_plan_ollamamonitor_target, macos_plan_snapshot_mode, macos_plan_build_script [INFERRED 0.85]
- **Popover UI components** — macos_plan_popover, macos_plan_model_card, macos_plan_installed_models, macos_plan_settings_window [INFERRED 0.85]

## Communities (22 total, 6 thin omitted)

### Community 0 - "HeaderView"
Cohesion: 0.07
Nodes (38): App, AppKit, Color, MenuBarLabel, .body, OllamaMonitorApp, .body, HeaderView (+30 more)

### Community 1 - "api.go"
Cohesion: 0.08
Nodes (33): net/url.URL, os.File, sync.Mutex, testing.T, main(), getRunningModels(), initHTTPClient(), markOffline() (+25 more)

### Community 2 - "RunningModel"
Cohesion: 0.11
Nodes (30): Decodable, Equatable, Identifiable, LocalizedError, InstalledModel, .badges, .canGenerate, .id (+22 more)

### Community 3 - "OllamaClient"
Cohesion: 0.11
Nodes (20): JSONDecoder, OllamaClient, .displayHost, .isLocal, badURL, http, Bool, Data (+12 more)

### Community 4 - "Monitor"
Cohesion: 0.10
Nodes (24): Monitor, .apiURL, .displayHost, .notifyModels, .notifyOffline, .pollSeconds, .running, .showCount (+16 more)

### Community 5 - "MonitorTests.swift"
Cohesion: 0.12
Nodes (21): .body, dropsOutOfOrderRefresh(), isolatedDefaults(), MonitorStubURLProtocol, ok(), previewMonitorPopoverOpenedMakesNoRequests(), serverSwitchDiscardsInFlightAndClearsError(), snapshotResponse() (+13 more)

### Community 6 - "OllamaKitTests.swift"
Cohesion: 0.12
Nodes (14): clientErrorParsing(), clientSnapshotRunningAndActions(), decodesInstalledModels(), httpResponse(), StubURLProtocol, Bool, Handler, HTTPURLResponse (+6 more)

### Community 7 - "Ollama Monitor for macOS plan"
Cohesion: 0.10
Nodes (22): Adaptive polling (10s idle, 3s running), Proxy support and SSL bypass, Migration from Python to Go, Changelog release history, Startup registry path fix, v1.0.0 initial release, v1.1.0 proxy support release, v1.2.0 Go rewrite release (+14 more)

### Community 8 - ".bytes"
Cohesion: 0.22
Nodes (9): Format, Date, Double, Int, Int64, String, .subtitle, .body (+1 more)

### Community 9 - "Ollama Monitor"
Cohesion: 0.16
Nodes (17): Build Scripts (build.bat, build.sh, go build), CHANGELOG.md, Customizable API URL Connection, Go Cross-Platform Tray App, MIT License, Native macOS Menu-Bar App (SwiftUI), macOS Popover Model Cards, Multi-Model Support (+9 more)

### Community 18 - "Foundation"
Cohesion: 0.18
Nodes (8): Foundation, NotificationDelegate, NSObject, UNNotification, UNNotificationPresentationOptions, UNUserNotificationCenter, UNUserNotificationCenterDelegate, UserNotifications

## Knowledge Gaps
- **52 isolated node(s):** `ollamaMonitor`, `PackageDescription`, `.summary`, `.id`, `.gpuShare` (+47 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 118 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Monitor` connect `Monitor` to `HeaderView`, `RunningModel`, `OllamaClient`, `MonitorTests.swift`, `Foundation`?**
  _High betweenness centrality (0.285) - this node is a cross-community bridge._
- **Why does `OllamaClient` connect `OllamaClient` to `Foundation`, `Monitor`, `OllamaKitTests.swift`, `Ollama Monitor for macOS plan`?**
  _High betweenness centrality (0.276) - this node is a cross-community bridge._
- **Why does `OllamaKit (API client, types, formatting)` connect `Ollama Monitor for macOS plan` to `OllamaClient`?**
  _High betweenness centrality (0.160) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `Monitor` (e.g. with `.body` and `.content`) actually correct?**
  _`Monitor` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `OllamaClient` (e.g. with `OllamaKit (API client, types, formatting)` and `clientErrorParsing()`) actually correct?**
  _`OllamaClient` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `ollamaMonitor`, `PackageDescription`, `.summary` to the rest of the system?**
  _52 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `HeaderView` be split into smaller, more focused modules?**
  _Cohesion score 0.06648936170212766 - nodes in this community are weakly interconnected._