import AppKit
import OllamaKit
import SwiftUI

struct PopoverView: View {
    let monitor: Monitor
    @Environment(\.openSettings) private var openSettings
    @AppStorage("showInstalled") private var showInstalled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView(monitor: monitor)
                .padding(12)
            Divider()
            content
            if let error = monitor.actionError {
                HStack(alignment: .top, spacing: 6) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Button {
                        monitor.actionError = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Dismiss error")
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            Divider()
            HStack {
                Button {
                    NSApp.activate()
                    openSettings()
                } label: {
                    Label("Settings…", systemImage: "gearshape")
                }
                .keyboardShortcut(",")
                Spacer()
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .keyboardShortcut("q")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 340)
        .onAppear { monitor.popoverOpened() }
    }

    @ViewBuilder private var content: some View {
        switch monitor.status {
        case .connecting:
            ProgressView("Connecting…")
                .frame(maxWidth: .infinity)
                .padding(24)
        case .offline(let message):
            OfflineView(message: message, host: monitor.displayHost, isLocal: monitor.client?.isLocal ?? false)
        case .online(let snapshot):
            VStack(alignment: .leading, spacing: 8) {
                if snapshot.running.isEmpty {
                    ContentUnavailableView("No model loaded", systemImage: "moon.zzz",
                                           description: Text("Load one below, or send Ollama a prompt."))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(snapshot.running) { model in
                        ModelCard(model: model, isLocal: monitor.client?.isLocal ?? false,
                                  busy: monitor.busy.contains(model.name)) {
                            monitor.unload(model.name)
                        }
                    }
                }
                DisclosureGroup(isExpanded: $showInstalled) {
                    InstalledList(snapshot: snapshot, monitor: monitor)
                } label: {
                    Text("Installed models (\(snapshot.installed.count))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
    }
}

struct HeaderView: View {
    let monitor: Monitor

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .accessibilityLabel(stateName)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                monitor.actionError = nil
                Task { await monitor.refresh(full: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("r")
            .help("Refresh now (⌘R)")
            .accessibilityLabel("Refresh")
        }
    }

    private var title: String {
        if case .online(let s) = monitor.status { "Ollama \(s.version)" } else { "Ollama" }
    }

    private var subtitle: String {
        let running = monitor.running
        guard !running.isEmpty else { return "\(monitor.displayHost) · \(stateName)" }
        let used = running.reduce(Int64(0)) { $0 + $1.size }
        guard monitor.client?.isLocal == true else {
            return "\(monitor.displayHost) · \(Format.bytes(used)) loaded"
        }
        let total = Int64(ProcessInfo.processInfo.physicalMemory)
        return "\(monitor.displayHost) · \(Format.bytes(used)) of \(Format.bytes(total)) memory"
    }

    private var stateName: String {
        switch monitor.status {
        case .connecting: "connecting"
        case .offline: "offline"
        case .online(let s): s.running.isEmpty ? "idle" : "running"
        }
    }

    private var color: Color {
        switch monitor.status {
        case .connecting: .secondary
        case .offline: .red
        case .online(let s): s.running.isEmpty ? .blue : .green
        }
    }
}

struct ModelCard: View {
    let model: RunningModel
    let isLocal: Bool
    let busy: Bool
    let unload: () -> Void

    private var memoryShare: Double {
        Double(model.size) / Double(max(1, ProcessInfo.processInfo.physicalMemory))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                if let runner = model.runner, !runner.isEmpty {
                    Text(runner.uppercased())
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
            }
            if isLocal {
                ProgressView(value: min(1, max(0, memoryShare)))
                    .tint(memoryShare > 0.6 ? .orange : .accentColor)
                    .accessibilityLabel("Share of memory")
            }
            HStack {
                if isLocal {
                    Text("\(Format.bytes(model.size)) · \(Int((memoryShare * 100).rounded()))% of memory")
                } else {
                    Text(Format.bytes(model.size))
                }
                Spacer()
                if let summary = model.details?.summary { Text(summary) }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            // Full GPU is normal on Apple silicon; only a CPU spill is worth a line.
            if model.gpuShare < 0.995 {
                Label("\(Format.placement(gpuShare: model.gpuShare)): slower than all-GPU",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: 12) {
                if let ctx = model.contextLength {
                    Label("\(Format.context(ctx)) context", systemImage: "text.alignleft")
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if let left = Format.countdown(until: model.expiresAt, now: context.date) {
                        Label(left == "now" ? "unloading now" : "unloads in \(left)", systemImage: "timer")
                            .monospacedDigit()
                    } else {
                        Label("stays loaded", systemImage: "pin")
                    }
                }
                Spacer()
                if busy {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Unload", action: unload)
                        .controlSize(.small)
                        .help("Free this model's memory now")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InstalledList: View {
    let snapshot: ServerSnapshot
    let monitor: Monitor

    var body: some View {
        let loaded = Set(snapshot.running.map(\.name))
        let isLocal = monitor.client?.isLocal ?? false
        ScrollView {
            VStack(spacing: 0) {
                ForEach(snapshot.installed) { model in
                    InstalledRow(model: model, loaded: loaded.contains(model.name),
                                 isLocal: isLocal,
                                 busy: monitor.busy.contains(model.name)) {
                        monitor.load(model.name)
                    }
                    .padding(.vertical, 5)
                    if model.id != snapshot.installed.last?.id { Divider() }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxHeight: 240)
        .fixedSize(horizontal: false, vertical: snapshot.installed.count <= 5)
    }
}

struct InstalledRow: View {
    let model: InstalledModel
    let loaded: Bool
    let isLocal: Bool
    let busy: Bool
    let load: () -> Void

    private var tooBig: Bool {
        isLocal && Double(model.size) > 0.6 * Double(ProcessInfo.processInfo.physicalMemory)
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name).lineLimit(1).truncationMode(.middle)
                HStack(spacing: 6) {
                    if tooBig {
                        Label(Format.bytes(model.size), systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .help("Uses most of this Mac's memory; loading it may make the Mac swap")
                    } else {
                        Text(Format.bytes(model.size))
                    }
                    if let summary = model.details?.summary { Text(summary) }
                    ForEach(model.badges, id: \.self) { badge in
                        Image(systemName: Self.symbol(for: badge))
                            .help(badge.capitalized)
                            .accessibilityLabel(badge)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if loaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help("Loaded")
                    .accessibilityLabel("Loaded")
            } else if busy {
                ProgressView().controlSize(.small)
            } else if model.canGenerate {
                Button("Load", action: load)
                    .controlSize(.small)
                    .help("Load into memory now")
            }
        }
    }

    static func symbol(for capability: String) -> String {
        switch capability {
        case "vision": "eye"
        case "tools": "wrench.and.screwdriver"
        case "thinking": "brain"
        case "embedding": "point.3.connected.trianglepath.dotted"
        case "insert": "text.insert"
        default: "sparkle"
        }
    }
}

struct OfflineView: View {
    let message: String
    let host: String
    let isLocal: Bool

    var body: some View {
        ContentUnavailableView {
            Label("Ollama isn't responding", systemImage: "bolt.horizontal.circle")
        } description: {
            Text("\(host): \(message)")
        } actions: {
            if isLocal, let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.electron.ollama") {
                Button("Open Ollama") {
                    NSWorkspace.shared.openApplication(at: app, configuration: .init())
                }
            }
        }
    }
}
