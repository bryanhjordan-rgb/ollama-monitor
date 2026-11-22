# Graph Report - ollama-monitor  (2026-11-22)

## Corpus Check
- 3 files · ~16,788 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 273 nodes · 436 edges · 29 communities (10 shown, 14 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 39 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- macOS Menu-Bar UI
- macOS Monitor State
- Swift API Client
- Swift Model Types
- Docs & Release History
- Go Tray App Core
- Swift Formatting Helpers
- Settings & Snapshot Views
- OllamaKit Tests
- Go Log Rotation
- macOS Notification Delegate
- Root Logo Image
- macOS Build Script
- Swift Package Manifest
- Blue Tray Icon
- Green Tray Icon
- Red Tray Icon
- Embedded Logo Image
- Orphan Type Date
- Orphan Type Int
- Orphan Type Int64
- Orphan Type Void
- Go Module
- Orphan Type Set

## God Nodes (most connected - your core abstractions)
1. `Monitor` - 40 edges
2. `OllamaClient` - 20 edges
3. `RunningModel` - 20 edges
4. `InstalledModel` - 19 edges
5. `ServerSnapshot` - 15 edges
6. `HeaderView` - 11 edges
7. `Ollama Monitor for macOS plan` - 11 edges
8. `ModelDetails` - 11 edges
9. `InstalledRow` - 9 edges
10. `ModelCard` - 9 edges

## Surprising Connections (you probably didn't know these)
- `Adaptive polling (10s idle, 3s running)` --semantically_similar_to--> `OllamaMonitor app target (MenuBarExtra, Monitor poller, views)`  [INFERRED] [semantically similar]
  CHANGELOG.md → macos/PLAN.md
- `Ollama Monitor for macOS plan` --semantically_similar_to--> `Ollama Monitor (Go tray app)`  [INFERRED] [semantically similar]
  macos/PLAN.md → README.md
- `OllamaKit (API client, types, formatting)` --references--> `OllamaClient`  [INFERRED]
  macos/PLAN.md → macos/Sources/OllamaKit/OllamaClient.swift
- `Proxy support and SSL bypass` --conceptually_related_to--> `Ollama Monitor (Go tray app)`  [INFERRED]
  CHANGELOG.md → README.md
- `Multi-model support` --references--> `v1.2.0 Go rewrite release`  [INFERRED]
  README.md → CHANGELOG.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **macOS app layering: OllamaKit, app target, snapshot mode** — macos_plan_ollamakit, macos_plan_ollamamonitor_target, macos_plan_snapshot_mode, macos_plan_build_script [INFERRED 0.85]
- **Popover UI components** — macos_plan_popover, macos_plan_model_card, macos_plan_installed_models, macos_plan_settings_window [INFERRED 0.85]

## Communities (29 total, 14 thin omitted)

### Community 0 - "macOS Menu-Bar UI"
Cohesion: 0.08
Nodes (33): App, AppKit, Color, MenuBarLabel, .body, OllamaMonitorApp, .body, HeaderView (+25 more)

### Community 1 - "macOS Monitor State"
Cohesion: 0.09
Nodes (27): Monitor, .apiURL, .client, .defaults, .displayHost, .notifyModels, .notifyOffline, .pollSeconds (+19 more)

### Community 2 - "Swift API Client"
Cohesion: 0.11
Nodes (22): Data, Equatable, JSONDecoder, LocalizedError, OllamaClient, .displayHost, .isLocal, OllamaError (+14 more)

### Community 3 - "Swift Model Types"
Cohesion: 0.14
Nodes (25): Date, Decodable, Identifiable, Int, Int64, InstalledModel, .badges, .canGenerate (+17 more)

### Community 4 - "Docs & Release History"
Cohesion: 0.10
Nodes (28): Adaptive polling (10s idle, 3s running), Proxy support and SSL bypass, Migration from Python to Go, Changelog release history, Startup registry path fix, v1.0.0 initial release, v1.1.0 proxy support release, v1.2.0 Go rewrite release (+20 more)

### Community 5 - "Go Tray App Core"
Cohesion: 0.12
Nodes (19): main(), getRunningModels(), initHTTPClient(), notifyModelChanges(), sliceContains(), loadSettings(), saveSettings(), saveSettingsLocked() (+11 more)

### Community 6 - "Swift Formatting Helpers"
Cohesion: 0.26
Nodes (8): Format, Date, Double, Int, Int64, String, .subtitle, .body

### Community 7 - "Settings & Snapshot Views"
Cohesion: 0.24
Nodes (8): SettingsView, .body, Bool, String, Snapshot, .directory, String, View

### Community 9 - "Go Log Rotation"
Cohesion: 0.31
Nodes (5): os.File, sync.Mutex, NewRotatedWriter(), setupLogging(), RotatedWriter

### Community 10 - "macOS Notification Delegate"
Cohesion: 0.29
Nodes (6): NotificationDelegate, NSObject, UNNotification, UNNotificationPresentationOptions, UNUserNotificationCenter, UNUserNotificationCenterDelegate

## Knowledge Gaps
- **51 isolated node(s):** `.displayHost`, `.isLocal`, `.errorDescription`, `.body`, `.color` (+46 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 115 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Monitor` connect `macOS Monitor State` to `macOS Menu-Bar UI`, `macOS Notification Delegate`, `Swift Model Types`, `Settings & Snapshot Views`?**
  _High betweenness centrality (0.244) - this node is a cross-community bridge._
- **Why does `OllamaClient` connect `Swift API Client` to `OllamaKit Tests`, `Docs & Release History`?**
  _High betweenness centrality (0.199) - this node is a cross-community bridge._
- **Why does `RunningModel` connect `Swift Model Types` to `macOS Menu-Bar UI`, `macOS Monitor State`, `Swift API Client`?**
  _High betweenness centrality (0.184) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Monitor` (e.g. with `.body` and `.content`) actually correct?**
  _`Monitor` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.displayHost`, `.isLocal`, `.errorDescription` to the rest of the system?**
  _51 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `macOS Menu-Bar UI` be split into smaller, more focused modules?**
  _Cohesion score 0.08367071524966262 - nodes in this community are weakly interconnected._
- **Should `macOS Monitor State` be split into smaller, more focused modules?**
  _Cohesion score 0.08571428571428572 - nodes in this community are weakly interconnected._