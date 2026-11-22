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
    #expect(m.expiresAt == OllamaClient.parseDate("2026-11-22T05:47:40.764Z"))
}

@Test func decodesInstalledModels() throws {
    let tags = try OllamaClient.decoder.decode(TagsResponse.self, from: Data(tagsJSON.utf8))
    #expect(tags.models.count == 2)
    #expect(tags.models[0].badges == ["vision", "tools", "thinking"])
    #expect(tags.models[0].modifiedAt != nil)
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

@Test func urlValidationAndAuth() throws {
    #expect(OllamaClient.validate("localhost:11434") == nil)
    #expect(OllamaClient.validate("ftp://x") == nil)
    #expect(OllamaClient.validate(" http://127.0.0.1:11434/ ")?.absoluteString == "http://127.0.0.1:11434")
    let c = try OllamaClient(urlString: "https://bob:p%40ss@ollama.example.com")
    #expect(c.baseURL.absoluteString == "https://ollama.example.com")
    #expect(c.authorization == "Basic " + Data("bob:p@ss".utf8).base64EncodedString())
    #expect(c.displayHost == "ollama.example.com")
    #expect(try OllamaClient(urlString: "http://localhost:11434").displayHost == "localhost")
    #expect(try OllamaClient(urlString: "http://127.0.0.1:11434").isLocal)
    #expect(!c.isLocal)
    #expect(throws: OllamaError.self) { try OllamaClient(urlString: "nope") }
}
