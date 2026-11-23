import Foundation
import Testing
@testable import OllamaKit
@testable import OllamaMonitor

nonisolated final class MonitorStubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)
    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]

    static func makeSession(handler: @escaping Handler) -> URLSession {
        let id = UUID().uuidString
        lock.withLock { handlers[id] = handler }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MonitorStubURLProtocol.self]
        config.httpAdditionalHeaders = ["X-Monitor-Stub": id]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let id = request.value(forHTTPHeaderField: "X-Monitor-Stub"),
              let handler = Self.lock.withLock({ Self.handlers[id] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let req = request
        let clientRef = client
        Task {
            do {
                let (response, data) = try await handler(req)
                clientRef?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                clientRef?.urlProtocol(self, didLoad: data)
                clientRef?.urlProtocolDidFinishLoading(self)
            } catch {
                clientRef?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}

nonisolated private func ok(_ url: URL, json: String) -> (HTTPURLResponse, Data) {
    (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(json.utf8))
}

nonisolated private func snapshotResponse(for url: URL, version: String, runningName: String) -> (HTTPURLResponse, Data) {
    switch url.path {
    case "/api/version":
        ok(url, json: #"{"version":"\#(version)"}"#)
    case "/api/ps":
        ok(url, json: #"{"models":[{"name":"\#(runningName)","size":1024}]}"#)
    default:
        ok(url, json: #"{"models":[]}"#)
    }
}

private func isolatedDefaults() -> UserDefaults {
    let suite = "OllamaMonitorTests-\(UUID().uuidString)"
    let d = UserDefaults(suiteName: suite)!
    d.removePersistentDomain(forName: suite)
    return d
}

@Test func dropsOutOfOrderRefresh() async throws {
    let gate = AsyncStream<Void>.makeStream()
    let lock = NSLock()
    nonisolated(unsafe) var versionCalls = 0
    nonisolated(unsafe) var psCalls = 0

    let session = MonitorStubURLProtocol.makeSession { req in
        let url = req.url!
        if url.path == "/api/version" {
            let n = lock.withLock {
                versionCalls += 1
                return versionCalls
            }
            if n == 1 {
                var iter = gate.stream.makeAsyncIterator()
                _ = await iter.next()
                return snapshotResponse(for: url, version: "0.1.0", runningName: "stale-model")
            }
            return snapshotResponse(for: url, version: "0.2.0", runningName: "fresh-model")
        }
        if url.path == "/api/ps" {
            let n = lock.withLock {
                psCalls += 1
                return psCalls
            }
            return snapshotResponse(for: url, version: "unused", runningName: n == 1 ? "stale-model" : "fresh-model")
        }
        return snapshotResponse(for: url, version: "unused", runningName: "unused")
    }

    let defaults = isolatedDefaults()
    defaults.set("http://first.local:11434", forKey: "apiURL")
    let monitor = Monitor(session: session, defaults: defaults)

    // Start slow refresh #1 and wait until its /api/version request is parked on the gate.
    let slowRefresh = Task { await monitor.refresh(full: true) }
    while lock.withLock({ versionCalls }) == 0 {
        await Task.yield()
    }

    // Run refresh #2 while #1 is blocked; #2 lands with version 0.2.0.
    await monitor.refresh(full: true)
    guard case .online(let snap2) = monitor.status else {
        Issue.record("expected .online after refresh #2")
        gate.continuation.yield()
        await slowRefresh.value
        return
    }
    #expect(snap2.version == "0.2.0")

    // Unblock refresh #1; its stale 0.1.0 response must not overwrite 0.2.0.
    gate.continuation.yield()
    await slowRefresh.value
    #expect(monitor.status == .online(snap2))
}

@Test func serverSwitchDiscardsInFlightAndClearsError() async {
    let gate = AsyncStream<Void>.makeStream()
    let lock = NSLock()
    nonisolated(unsafe) var oldEntered = false

    let session = MonitorStubURLProtocol.makeSession { req in
        let url = req.url!
        if url.host() == "old.local" {
            let shouldBlock = lock.withLock {
                if !oldEntered && url.path == "/api/version" {
                    oldEntered = true
                    return true
                }
                return false
            }
            if shouldBlock {
                var iter = gate.stream.makeAsyncIterator()
                _ = await iter.next()
            }
            return snapshotResponse(for: url, version: "0.1.0", runningName: "old-model")
        }
        return snapshotResponse(for: url, version: "0.9.0", runningName: "new-model")
    }

    let defaults = isolatedDefaults()
    defaults.set("http://old.local:11434", forKey: "apiURL")
    let monitor = Monitor(session: session, defaults: defaults)
    monitor.actionError = "old error"

    let oldRefresh = Task { await monitor.refresh(full: true) }
    while !lock.withLock({ oldEntered }) {
        await Task.yield()
    }

    // Switching apiURL clears actionError, sets .connecting, and starts polling new.local.
    monitor.apiURL = "http://new.local:11434"
    #expect(monitor.actionError == nil)

    // Ensure a full refresh from new.local completes, then unblock old.local — old.local must be ignored.
    await monitor.refresh(full: true)
    gate.continuation.yield()
    await oldRefresh.value

    if case .online(let snap) = monitor.status {
        #expect(snap.version == "0.9.0")
        #expect(snap.running.map(\.name) == ["new-model"])
    } else {
        Issue.record("expected .online from new.local, got \(monitor.status)")
    }
}

@Test func previewMonitorPopoverOpenedMakesNoRequests() async {
    let lock = NSLock()
    nonisolated(unsafe) var count = 0
    let session = MonitorStubURLProtocol.makeSession { req in
        lock.withLock { count += 1 }
        return snapshotResponse(for: req.url!, version: "1", runningName: "x")
    }
    let preview = Monitor(preview: .offline("offline"), session: session)
    preview.popoverOpened()
    try? await Task.sleep(for: .milliseconds(50))
    #expect(lock.withLock { count } == 0)
    #expect(preview.status == .offline("offline"))
}

@Test func findsModelManifestInBothStoreLayouts() throws {
    let root = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }

    let legacy = root.appending(path: "manifests/registry.ollama.ai/library/llama/latest")
    let v2 = root.appending(path: "manifests-v2/ollama.com/library/llama/latest")
    let privateRegistry = root.appending(path: "manifests-v2/registry.example.com%3A5000/team/llama/custom")
    for manifest in [legacy, privateRegistry] {
        try FileManager.default.createDirectory(at: manifest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: manifest)
    }
    #expect(ModelStorage.manifest(for: "llama", in: root) == legacy)
    #expect(ModelStorage.manifest(for: "registry.example.com:5000/team/llama:custom", in: root) == privateRegistry)
    #expect(ModelStorage.manifest(for: "../llama:latest", in: root) == nil)
    #expect(ModelStorage.manifest(for: "missing:latest", in: root) == nil)
    #expect(ModelStorage.manifest(for: "", in: root) == nil)

    try FileManager.default.createDirectory(at: v2.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createSymbolicLink(at: v2, withDestinationURL: legacy)
    #expect(ModelStorage.manifest(for: "llama:latest", in: root) == v2)
}

@Test func deleteRejectsAChangedConnection() {
    let session = MonitorStubURLProtocol.makeSession { req in
        Issue.record("Delete confirmation must stay on the original server")
        return ok(req.url!, json: "{}")
    }
    let defaults = isolatedDefaults()
    defaults.set("http://second.local:11434", forKey: "apiURL")
    let monitor = Monitor(session: session, defaults: defaults)

    monitor.delete("llama:latest", from: "http://first.local:11434")

    #expect(monitor.busy.isEmpty)
    #expect(monitor.actionError != nil)
}

@Test func runningPollDoesNotDiscardInstalledRefresh() async {
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let session = MonitorStubURLProtocol.makeSession { req in
        let url = req.url!
        if url.path == "/api/tags" {
            entered.continuation.yield()
            var iterator = resume.stream.makeAsyncIterator()
            _ = await iterator.next()
        }
        return snapshotResponse(for: url, version: "0.1.0", runningName: "other-model")
    }
    let original = ServerSnapshot(version: "0.1.0", running: [], installed: [.init(name: "deleted-model", size: 1)])
    let monitor = Monitor(preview: .online(original), session: session)

    let full = Task { await monitor.refresh() }
    var iterator = entered.stream.makeAsyncIterator()
    _ = await iterator.next()
    await monitor.refresh(full: false)
    resume.continuation.yield()
    await full.value

    guard case .online(let refreshed) = monitor.status else {
        Issue.record("expected an updated server snapshot")
        return
    }
    #expect(refreshed.installed.isEmpty)
}
