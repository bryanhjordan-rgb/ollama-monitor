import Foundation
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
        didSet { defaults.set(apiURL, forKey: "apiURL"); actionError = nil; status = .connecting; start() }
    }
    var pollSeconds: Double = defaults.object(forKey: "pollSeconds") as? Double ?? 3 {
        didSet {
            defaults.set(pollSeconds, forKey: "pollSeconds")
            if task != nil { start() }
        }
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

    @ObservationIgnored private let isPreview: Bool
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private var notificationsConfigured = false
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var refreshCount = 0
    @ObservationIgnored private var appliedRefresh = 0
    @ObservationIgnored private let notifier = NotificationDelegate()
    private static let defaults = UserDefaults.standard
    private var defaults: UserDefaults { Self.defaults }

    init(session: URLSession = .shared) {
        self.session = session
        self.isPreview = false
    }

    /// For snapshots and previews: a fixed status, no polling.
    init(preview: Status) {
        self.session = .shared
        self.isPreview = true
        self.status = preview
    }

    var client: OllamaClient? { try? OllamaClient(urlString: apiURL, session: session) }
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
        if !notificationsConfigured && Bundle.main.bundleIdentifier != nil {
            notificationsConfigured = true
            UNUserNotificationCenter.current().delegate = notifier
            Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) }
        }
        task = Task { [weak self] in
            while !Task.isCancelled, let self {
                let isOnline: Bool = if case .online = status { true } else { false }
                await refresh(full: !isOnline)
                let base = max(1, pollSeconds)
                let delay: Double = if case .offline = status { max(base, 10) } else { base }
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    func popoverOpened() {
        guard !isPreview else { return }
        Task { await refresh(full: true) }
    }

    func refresh(full: Bool = true) async {
        // The poll loop, Load/Unload and ⌘R can overlap; a slow older answer must not overwrite a newer one.
        refreshCount += 1
        let id = refreshCount, url = apiURL
        guard let client else { appliedRefresh = id; apply(.offline("The API URL in Settings isn't valid.")); return }
        let next: Status
        do {
            if !full, case .online(let current) = status {
                let running = try await client.running()
                next = .online(ServerSnapshot(version: current.version, running: running, installed: current.installed))
            } else {
                next = .online(try await client.snapshot())
            }
        } catch is CancellationError {
            return
        } catch let err as URLError where err.code == .cancelled {
            return
        } catch {
            next = .offline(error.localizedDescription)
        }
        guard url == apiURL, id > appliedRefresh else { return } // Server changed, or a newer refresh already landed.
        appliedRefresh = id
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
            let (loaded, unloaded) = new.modelChanges(since: old, ignoring: busy)
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
