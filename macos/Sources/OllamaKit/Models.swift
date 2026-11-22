import Foundation

public struct ModelDetails: Decodable, Sendable, Equatable {
    public var parameterSize: String?
    public var quantizationLevel: String?

    public init(parameterSize: String? = nil, quantizationLevel: String? = nil) {
        self.parameterSize = parameterSize
        self.quantizationLevel = quantizationLevel
    }

    /// "8.0B · Q4_K_M", or nil when Ollama reports neither (MLX models report empty strings).
    public var summary: String? {
        let parts = [parameterSize, quantizationLevel].compactMap { $0?.isEmpty == false ? $0 : nil }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// A model loaded in memory, from `/api/ps`.
public struct RunningModel: Decodable, Sendable, Equatable, Identifiable {
    public var id: String { name }
    public var name: String
    public var size: Int64
    public var sizeVram: Int64?
    public var expiresAt: Date?
    public var contextLength: Int?
    public var runner: String?
    public var details: ModelDetails?

    public init(name: String, size: Int64, sizeVram: Int64? = nil, expiresAt: Date? = nil,
                contextLength: Int? = nil, runner: String? = nil, details: ModelDetails? = nil) {
        self.name = name
        self.size = size
        self.sizeVram = sizeVram
        self.expiresAt = expiresAt
        self.contextLength = contextLength
        self.runner = runner
        self.details = details
    }

    /// Share of the model in GPU memory, 0...1.
    public var gpuShare: Double {
        guard size > 0, let vram = sizeVram else { return 0 }
        return min(1, max(0, Double(vram) / Double(size)))
    }
}

/// A model on disk, from `/api/tags`.
public struct InstalledModel: Decodable, Sendable, Equatable, Identifiable {
    public var id: String { name }
    public var name: String
    public var size: Int64
    public var details: ModelDetails?
    public var capabilities: [String]?

    public init(name: String, size: Int64, details: ModelDetails? = nil, capabilities: [String]? = nil) {
        self.name = name
        self.size = size
        self.details = details
        self.capabilities = capabilities
    }

    /// Capabilities worth a badge; every model can do "completion".
    public var badges: [String] { (capabilities ?? []).filter { $0 != "completion" } }

    /// Embedding-only models can't be loaded with /api/generate. Older servers send no capabilities.
    public var canGenerate: Bool { capabilities?.contains("completion") ?? true }
}

/// Everything the popover shows, fetched in one poll.
public struct ServerSnapshot: Sendable, Equatable {
    public var version: String
    public var running: [RunningModel]
    public var installed: [InstalledModel]

    public init(version: String, running: [RunningModel], installed: [InstalledModel]) {
        self.version = version
        self.running = running
        self.installed = installed
    }

    /// Names of models loaded and unloaded since `old`, sorted, leaving out `ignoring`.
    public func modelChanges(since old: ServerSnapshot, ignoring: Set<String> = []) -> (loaded: [String], unloaded: [String]) {
        let before = Set(old.running.map(\.name)), after = Set(running.map(\.name))
        return (after.subtracting(before).subtracting(ignoring).sorted(),
                before.subtracting(after).subtracting(ignoring).sorted())
    }
}

struct PSResponse: Decodable { var models: [RunningModel] }
struct TagsResponse: Decodable { var models: [InstalledModel] }
struct VersionResponse: Decodable { var version: String }
