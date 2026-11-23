import Foundation
import Testing
@testable import OllamaKit

// Captured from Ollama 0.40.17 on 2026-11-22 (digests trimmed).
let psJSON = """
{"models":[{"name":"gemma4:e4b","model":"gemma4:e4b","size":9781322372,"digest":"eb21",
"details":{"parent_model":"","format":"safetensors","family":"","families":null,"parameter_size":"","quantization_level":""},
"expires_at":"2026-11-22T00:47:40.764554-05:00","size_vram":9781322372,"context_length":8192,"runner":"mlx"}]}
"""

let tagsJSON = """
{"models":[{"name":"inkling-2-mini:latest","model":"inkling-2-mini:latest","modified_at":"2026-11-22T00:16:44.35179359-05:00",
"size":20188097680,"digest":"d183","details":{"parent_model":"","format":"safetensors","family":"","families":null,
"parameter_size":"","quantization_level":"","runner":"mlx"},"capabilities":["completion","vision","tools","thinking"]},
{"name":"llama3.2:3b","size":2019393189,"modified_at":"2026-10-01T10:00:00Z",
"details":{"parameter_size":"3.2B","quantization_level":"Q4_K_M","family":"llama"}}]}
"""

@Test func decodesRunningModels() throws {
    let ps = try OllamaClient.decoder.decode(PSResponse.self, from: Data(psJSON.utf8))
    let m = try #require(ps.models.first)
    #expect(m.name == "gemma4:e4b")
    #expect(m.contextLength == 8192)
    #expect(m.runner == "mlx")
    #expect(m.gpuShare == 1)
    #expect(m.details?.summary == nil)
    #expect(m.expiresAt == OllamaClient.parseDate("2026-11-22T05:47:40.764554Z"))
}

@Test func decodesInstalledModels() throws {
    let tags = try OllamaClient.decoder.decode(TagsResponse.self, from: Data(tagsJSON.utf8))
    #expect(tags.models.count == 2)
    #expect(tags.models[0].badges == ["vision", "tools", "thinking"])
    #expect(tags.models[1].details?.summary == "3.2B · Q4_K_M")
    #expect(tags.models[1].badges.isEmpty)
    #expect(tags.models[0].canGenerate)
    #expect(tags.models[1].canGenerate) // no capabilities: assume it can
    #expect(!InstalledModel(name: "e", size: 1, capabilities: ["embedding"]).canGenerate)
}

@Test func parsesGoTimestamps() {
    #expect(OllamaClient.parseDate("2026-11-22T00:16:44.35179359-05:00") != nil)
    #expect(OllamaClient.parseDate("2026-11-22T00:16:44Z") != nil)
    #expect(OllamaClient.parseDate("2026-11-22T00:16:44.5+01:00") != nil)
    #expect(OllamaClient.parseDate("yesterday") == nil)
}

@Test func countdown() {
    let now = Date(timeIntervalSince1970: 0)
    #expect(Format.countdown(until: now.addingTimeInterval(252), now: now) == "4:12")
    #expect(Format.countdown(until: now.addingTimeInterval(3723), now: now) == "1:02:03")
    #expect(Format.countdown(until: now.addingTimeInterval(-5), now: now) == "now")
    #expect(Format.countdown(until: now.addingTimeInterval(1e10), now: now) == nil)
    #expect(Format.countdown(until: nil, now: now) == nil)
}

@Test func contextAndPlacement() {
    #expect(Format.context(8192) == "8K")
    #expect(Format.context(2048) == "2048")
    #expect(Format.placement(gpuShare: 1) == "100% GPU")
    #expect(Format.placement(gpuShare: 0.4) == "40% GPU / 60% CPU")
    #expect(Format.placement(gpuShare: 0) == "CPU")
}

@Test func modelChanges() {
    func snap(_ names: String...) -> ServerSnapshot {
        ServerSnapshot(version: "1", running: names.map { RunningModel(name: $0, size: 1) }, installed: [])
    }
    let c = snap("b", "c", "d").modelChanges(since: snap("a", "b"))
    #expect(c.loaded == ["c", "d"])
    #expect(c.unloaded == ["a"])
    let busy = snap("b", "c").modelChanges(since: snap("a", "b"), ignoring: ["a", "c"])
    #expect(busy.loaded.isEmpty && busy.unloaded.isEmpty)
    #expect(snap("a").modelChanges(since: snap("a")).loaded.isEmpty)
}

@Test func urlValidationAndAuth() throws {
    #expect(OllamaClient.validate("localhost:11434") == nil)
    #expect(OllamaClient.validate("ftp://x") == nil)
    #expect(OllamaClient.validate(" http://127.0.0.1:11434/ ")?.absoluteString == "http://127.0.0.1:11434")
    let c = try OllamaClient(urlString: "https://bob:p%40ss@ollama.example.com")
    #expect(c.baseURL.absoluteString == "https://ollama.example.com")
    #expect(c.authorization == "Basic " + Data("bob:p@ss".utf8).base64EncodedString())
    let pct = try OllamaClient(urlString: "https://bob:foo%25bar@ollama.example.com")
    #expect(pct.authorization == "Basic " + Data("bob:foo%bar".utf8).base64EncodedString())
    let pct20 = try OllamaClient(urlString: "https://bob:foo%2520bar@ollama.example.com")
    #expect(pct20.authorization == "Basic " + Data("bob:foo%20bar".utf8).base64EncodedString())
    #expect(c.displayHost == "ollama.example.com")
    #expect(try OllamaClient(urlString: "http://localhost:11434").displayHost == "localhost")
    #expect(try OllamaClient(urlString: "http://127.0.0.1:11434").isLocal)
    #expect(!c.isLocal)
    #expect(throws: OllamaError.self) { try OllamaClient(urlString: "nope") }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]

    static func makeSession(handler: @escaping Handler) -> URLSession {
        let id = UUID().uuidString
        lock.withLock { handlers[id] = handler }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        config.httpAdditionalHeaders = ["X-Stub-ID": id]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let id = request.value(forHTTPHeaderField: "X-Stub-ID"),
              let handler = Self.lock.withLock({ Self.handlers[id] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func httpResponse(_ url: URL, status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
}

@Test func clientSnapshotRunningAndActions() async throws {
    let seenLock = NSLock()
    nonisolated(unsafe) var requests: [(method: String, path: String, auth: String?, body: [String: Any]?)] = []

    let session = StubURLProtocol.makeSession { req in
        let url = req.url!
        let bodyData = req.httpBody ?? req.httpBodyStream.map { stream in
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buf = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let n = stream.read(&buf, maxLength: buf.count)
                if n > 0 { data.append(buf, count: n) } else { break }
            }
            return data
        }
        let bodyJSON = bodyData.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        seenLock.withLock {
            requests.append((req.httpMethod ?? "GET", url.path, req.value(forHTTPHeaderField: "Authorization"), bodyJSON))
        }
        switch url.path {
        case "/api/version":
            return (httpResponse(url, status: 200), Data(#"{"version":"0.40.17"}"#.utf8))
        case "/api/ps":
            return (httpResponse(url, status: 200), Data(psJSON.utf8))
        case "/api/tags":
            return (httpResponse(url, status: 200), Data(tagsJSON.utf8))
        case "/api/generate", "/api/delete":
            return (httpResponse(url, status: 200), Data("{}".utf8))
        default:
            return (httpResponse(url, status: 404), Data())
        }
    }

    let client = try OllamaClient(urlString: "https://bob:foo%25bar@ollama.example.com/", session: session)
    let snap = try await client.snapshot()
    #expect(snap.version == "0.40.17")
    #expect(snap.running.map(\.name) == ["gemma4:e4b"])
    #expect(snap.installed.map(\.name) == ["inkling-2-mini:latest", "llama3.2:3b"])

    let expectedAuth = "Basic " + Data("bob:foo%bar".utf8).base64EncodedString()
    let snapshotAuths = seenLock.withLock { requests.map(\.auth) }
    #expect(snapshotAuths == [expectedAuth, expectedAuth, expectedAuth])

    seenLock.withLock { requests.removeAll() }
    let running = try await client.running()
    #expect(running.map(\.name) == ["gemma4:e4b"])
    #expect(seenLock.withLock { requests.map(\.path) } == ["/api/ps"])

    seenLock.withLock { requests.removeAll() }
    try await client.load("gemma4:e4b")
    try await client.unload("gemma4:e4b")
    try await client.delete("gemma4:e4b")
    let actions = seenLock.withLock { requests }
    #expect(actions.map(\.method) == ["POST", "POST", "DELETE"])
    #expect(actions.map(\.path) == ["/api/generate", "/api/generate", "/api/delete"])
    #expect(actions.map { $0.body?["model"] as? String } == Array(repeating: "gemma4:e4b", count: 3))
    #expect(actions[0].body?["keep_alive"] == nil)
    #expect(actions[1].body?["keep_alive"] as? Int == 0)
    #expect(actions[2].auth == expectedAuth)
}

@Test func clientErrorParsing() async throws {
    let session = StubURLProtocol.makeSession { req in
        let url = req.url!
        if url.path == "/api/ps" || url.path == "/api/delete" {
            return (httpResponse(url, status: 404), Data(#"{"error":"model 'x' not found"}"#.utf8))
        }
        return (httpResponse(url, status: 500), Data("plain text error".utf8))
    }
    let client = try OllamaClient(urlString: "http://localhost:11434", session: session)
    await #expect(throws: OllamaError.http(404, "model 'x' not found")) {
        _ = try await client.running()
    }
    await #expect(throws: OllamaError.http(404, "model 'x' not found")) {
        try await client.delete("x")
    }
    await #expect(throws: OllamaError.http(500, "")) {
        _ = try await client.installed()
    }
}
