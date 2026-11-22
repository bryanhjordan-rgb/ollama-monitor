import AppKit
import OllamaKit
import UserNotifications

/// Polls Ollama, holds what the popover shows, runs Load/Unload, and sends notifications.
@Observable
final class Monitor {
    enum Status: Equatable {
        case connecting
        case offline(String)
        case online(ServerSnapshot)
    }

    var status: Status = .connecting
    /// Models with a Load or Unload in flight.
    var busy: Set<String> = []
    var actionError: String?

    // Settings, saved to UserDefaults.
    var apiURL: String = defaults.string(forKey: "apiURL") ?? OllamaClient.defaultURL {
        didSet { defaults.set(apiURL, forKey: "apiURL"); status = .connecting; start() }
    }
    var pollSeconds: Double = defaults.object(forKey: "pollSeconds") as? Double ?? 3 {
        didSet { defaults.set(pollSeconds, forKey: "pollSeconds") }
    }
    var notifyModels: Bool = defaults.object(forKey: "notifyModels") as? Bool ?? true {
        didSet { defaults.set(notifyModels, forKey: "notifyModels") }
    }
    var notifyOffline: Bool = defaults.object(forKey: "notifyOffline") as? Bool ?? true {
        didSet { defaults.set(notifyOffline, forKey: "notifyOffline") }
    }
    var showCount: Bool = defaults.object(forKey: "showCount") as? Bool ?? true {
        didSet { defaults.set(showCount, forKey: "showCount") }
    }

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private let notifier = NotificationDelegate()
    private static let defaults = UserDefaults.standard
    private var defaults: UserDefaults { Self.defaults }

    init() {}

    /// For snapshots and previews: a fixed status, no polling.
    init(preview: Status) { status = preview }

    var client: OllamaClient? { try? OllamaClient(urlString: apiURL) }
    var displayHost: String { client?.displayHost ?? apiURL }

    var running: [RunningModel] {
        if case .online(let s) = status { s.running } else { [] }
    }

    /// Menu bar symbol: filled while a model is loaded, outline when idle, see-through when offline.
    var symbol: String {
        switch status {
        case .online(let s): s.running.isEmpty ? "cube" : "cube.fill"
        case .offline, .connecting: "cube.transparent"
        }
    }

    // MARK: - Polling

    func start() {
        task?.cancel()
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = notifier
            Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) }
        }
        task = Task { [weak self] in
            while !Task.isCancelled, let self {
                await refresh()
                try? await Task.sleep(for: .seconds(pollSeconds))
            }
        }
    }

    func refresh() async {
        let url = apiURL
        guard let client else { apply(.offline("The API URL in Settings isn't valid.")); return }
        let next: Status
        do { next = .online(try await client.snapshot()) } catch { next = .offline(error.localizedDescription) }
        guard url == apiURL else { return } // Settings changed the server while this was in flight.
        apply(next)
    }

    private func apply(_ next: Status) {
        defer { status = next }
        switch (status, next) {
        case (.online, .offline) where notifyOffline:
            notify("Ollama stopped responding", displayHost)
        case (.offline, .online(let s)) where notifyOffline:
            notify("Ollama is running", "Version \(s.version) on \(displayHost)")
        case (.online(let old), .online(let new)) where notifyModels:
            // Skip models the person just loaded or unloaded from the popover.
            let before = Set(old.running.map(\.name)), after = Set(new.running.map(\.name))
            let loaded = after.subtracting(before).subtracting(busy).sorted()
            let unloaded = before.subtracting(after).subtracting(busy).sorted()
            if !loaded.isEmpty { notify("Model loaded", loaded.joined(separator: ", ")) }
            if !unloaded.isEmpty { notify("Model unloaded", unloaded.joined(separator: ", ")) }
        default:
            break
        }
    }

    // MARK: - Actions

    func unload(_ name: String) { perform(name) { try await $0.unload(name) } }
    func load(_ name: String) { perform(name) { try await $0.load(name) } }

    private func perform(_ name: String, _ op: @escaping @Sendable (OllamaClient) async throws -> Void) {
        guard let client, !busy.contains(name) else { return }
        busy.insert(name)
        actionError = nil
        Task {
            do { try await op(client) } catch { actionError = "\(name): \(error.localizedDescription)" }
            await refresh()
            busy.remove(name)
        }
    }

    // MARK: - Notifications

    private func notify(_ title: String, _ body: String) {
        // UNUserNotificationCenter crashes outside an app bundle (swift run).
        guard Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

/// Shows banners even while the popover has the app active.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
