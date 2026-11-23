# Graph Report - ollama-monitor  (2026-11-23)

## Corpus Check
- 32 files · ~17,852 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 349 nodes · 617 edges · 23 communities (10 shown, 8 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 65 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a4f04eb9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- HeaderView
- api.go
- RunningModel
- OllamaClient
- Monitor
- .manifest
- StubURLProtocol
- Ollama Monitor
- .bytes
- claude.md
- build.sh
- Package.swift
- Blue Status Color Variant
- Green Llama Tray Icon
- Red Llama Tray Icon
- Monitor.swift
- todo.md
- ollamaMonitor

## God Nodes (most connected - your core abstractions)
1. `Monitor` - 48 edges
2. `OllamaClient` - 30 edges
3. `RunningModel` - 21 edges
4. `InstalledModel` - 19 edges
5. `ServerSnapshot` - 17 edges
6. `Ollama Monitor` - 13 edges
7. `ModelDetails` - 11 edges
8. `HeaderView` - 11 edges
9. `InstalledRow` - 11 edges
10. `StubURLProtocol` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Adaptive polling (10s idle, 3s running)` --semantically_similar_to--> `OllamaMonitor app target (MenuBarExtra, Monitor poller, views)`  [INFERRED] [semantically similar]
  CHANGELOG.md → macos/PLAN.md
- `Ollama Monitor for macOS plan` --semantically_similar_to--> `Ollama Monitor`  [INFERRED] [semantically similar]
  macos/PLAN.md → README.md
- `OllamaKit (API client, types, formatting)` --references--> `OllamaClient`  [INFERRED]
  macos/PLAN.md → macos/Sources/OllamaKit/OllamaClient.swift
- `Proxy support and SSL bypass` --conceptually_related_to--> `Ollama Monitor`  [INFERRED]
  CHANGELOG.md → README.md
- `main()` --calls--> `Run()`  [EXTRACTED]
  main.go → monitor/monitor.go

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Ollama Monitor Frontends Sharing Ollama Status Monitoring** — readme_go_tray_app, readme_macos_native_app, readme_ollama [INFERRED 0.75]
- **macOS app layering: OllamaKit, app target, snapshot mode** — macos_plan_ollamakit, macos_plan_ollamamonitor_target, macos_plan_snapshot_mode, macos_plan_build_script [INFERRED 0.85]
- **Popover UI components** — macos_plan_popover, macos_plan_model_card, macos_plan_installed_models, macos_plan_settings_window [INFERRED 0.85]

## Communities (23 total, 8 thin omitted)

### Community 0 - "HeaderView"
Cohesion: 0.07
Nodes (40): App, AppKit, Color, MenuBarLabel, .body, OllamaMonitorApp, .body, HeaderView (+32 more)

### Community 1 - "api.go"
Cohesion: 0.08
Nodes (35): net/url.URL, os.File, sync.Mutex, testing.T, main(), getRunningModels(), initHTTPClient(), markOffline() (+27 more)

### Community 2 - "RunningModel"
Cohesion: 0.14
Nodes (27): Decodable, Equatable, Identifiable, InstalledModel, .badges, .canGenerate, .id, ModelDetails (+19 more)

### Community 3 - "OllamaClient"
Cohesion: 0.07
Nodes (33): Foundation, JSONDecoder, LocalizedError, OllamaClient, .displayHost, .isLocal, OllamaError, badURL (+25 more)

### Community 4 - "Monitor"
Cohesion: 0.08
Nodes (39): Monitor, .apiURL, .displayHost, .notifyModels, .notifyOffline, .pollSeconds, .running, .showCount (+31 more)

### Community 5 - ".manifest"
Cohesion: 0.22
Nodes (7): ModelStorage, .directory, Bool, String, URL, findsModelManifestInBothStoreLayouts(), Substring

### Community 6 - "StubURLProtocol"
Cohesion: 0.12
Nodes (11): StubURLProtocol, Bool, Handler, String, URLRequest, URLSession, MonitorStubURLProtocol, Bool (+3 more)

### Community 7 - "Ollama Monitor"
Cohesion: 0.06
Nodes (39): Adaptive polling (10s idle, 3s running), Proxy support and SSL bypass, Migration from Python to Go, Changelog release history, Startup registry path fix, v1.0.0 initial release, v1.1.0 proxy support release, v1.2.0 Go rewrite release (+31 more)

### Community 8 - ".bytes"
Cohesion: 0.22
Nodes (9): Format, Date, Double, Int, Int64, String, .subtitle, .body (+1 more)

### Community 18 - "Monitor.swift"
Cohesion: 0.22
Nodes (7): NotificationDelegate, NSObject, UNNotification, UNNotificationPresentationOptions, UNUserNotificationCenter, UNUserNotificationCenterDelegate, UserNotifications

## Knowledge Gaps
- **55 isolated node(s):** `ollamaMonitor`, `PackageDescription`, `.summary`, `.id`, `.gpuShare` (+50 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 126 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Monitor` connect `Monitor` to `HeaderView`, `OllamaClient`, `Monitor.swift`, `RunningModel`?**
  _High betweenness centrality (0.294) - this node is a cross-community bridge._
- **Why does `OllamaClient` connect `OllamaClient` to `RunningModel`, `Monitor`, `Ollama Monitor`?**
  _High betweenness centrality (0.264) - this node is a cross-community bridge._
- **Why does `OllamaKit (API client, types, formatting)` connect `Ollama Monitor` to `OllamaClient`?**
  _High betweenness centrality (0.150) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `Monitor` (e.g. with `.body` and `.content`) actually correct?**
  _`Monitor` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `OllamaClient` (e.g. with `OllamaKit (API client, types, formatting)` and `clientErrorParsing()`) actually correct?**
  _`OllamaClient` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `ServerSnapshot` (e.g. with `.body` and `runningPollDoesNotDiscardInstalledRefresh()`) actually correct?**
  _`ServerSnapshot` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `ollamaMonitor`, `PackageDescription`, `.summary` to the rest of the system?**
  _55 weakly-connected nodes found - possible documentation gaps or missing edges._