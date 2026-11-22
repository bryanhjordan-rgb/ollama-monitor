import AppKit
import OllamaKit
import SwiftUI

/// `OllamaMonitor --snapshot <dir>` draws the popover in every state, and Settings,
/// in light and dark to PNGs with sample data, then quits. No Ollama needed.
enum Snapshot {
    static var directory: String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func run(to dir: String, settings: Monitor) async {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        UserDefaults.standard.set(true, forKey: "showInstalled")
        let states: [(String, Monitor.Status)] = [
            ("active", .online(Fixture.active)),
            ("idle", .online(Fixture.idle)),
            ("offline", .offline("Could not connect to the server.")),
            ("connecting", .connecting),
        ]
        for mode in ["light", "dark"] {
            for (name, status) in states {
                let monitor = Monitor(preview: status)
                if name == "active" { monitor.busy = ["llama3.2:3b"] }
                await capture(PopoverView(monitor: monitor), to: "\(dir)/popover-\(name)-\(mode).png", mode: mode)
            }
            await capture(SettingsView(monitor: settings), to: "\(dir)/settings-\(mode).png", mode: mode)
        }
        print("SNAPSHOT done \(dir)")
    }

    private static func capture(_ view: some View, to path: String, mode: String) async {
        let host = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 340, height: 200),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: mode == "light" ? .aqua : .darkAqua)
        window.contentView = host
        window.setContentSize(host.fittingSize)
        window.orderFrontRegardless()
        try? await Task.sleep(for: .seconds(0.5))
        host.layoutSubtreeIfNeeded()
        if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
            host.cacheDisplay(in: host.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            print("SNAPSHOT \(path)")
        }
        window.orderOut(nil)
    }
}

enum Fixture {
    static let installed: [InstalledModel] = [
        .init(name: "gemma4:e4b", size: 9_781_322_372, capabilities: ["completion", "vision", "tools", "thinking"]),
        .init(name: "inkling-2-mini:latest", size: 20_188_097_680, capabilities: ["completion", "vision", "tools", "thinking"]),
        .init(name: "llama3.2:3b", size: 2_019_393_189,
              details: .init(parameterSize: "3.2B", quantizationLevel: "Q4_K_M"), capabilities: ["completion", "tools"]),
        .init(name: "nomic-embed-text:latest", size: 274_302_450,
              details: .init(parameterSize: "137M", quantizationLevel: "F16"), capabilities: ["embedding"]),
        .init(name: "qwen3-coder:30b-a3b-instruct-q4_K_M", size: 18_556_701_000,
              details: .init(parameterSize: "30.5B", quantizationLevel: "Q4_K_M"), capabilities: ["completion", "tools", "insert"]),
    ]

    static var active: ServerSnapshot {
        ServerSnapshot(version: "0.40.17", running: [
            .init(name: "gemma4:e4b", size: 9_781_322_372, sizeVram: 9_781_322_372,
                  expiresAt: .now.addingTimeInterval(252), contextLength: 8192, runner: "mlx"),
            .init(name: "qwen3-coder:30b-a3b-instruct-q4_K_M", size: 18_556_701_000, sizeVram: 11_134_020_600,
                  expiresAt: .distantFuture, contextLength: 32768, runner: "llama",
                  details: .init(parameterSize: "30.5B", quantizationLevel: "Q4_K_M")),
        ], installed: installed)
    }

    static var idle: ServerSnapshot {
        ServerSnapshot(version: "0.40.17", running: [], installed: installed)
    }
}
