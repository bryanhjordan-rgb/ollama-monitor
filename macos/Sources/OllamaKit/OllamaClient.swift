import Foundation

public enum OllamaError: LocalizedError, Equatable {
    case badURL(String)
    case http(Int, String)

    public var errorDescription: String? {
        switch self {
        case .badURL(let s): "Not a valid http or https URL: \(s)"
        case .http(let code, let body): body.isEmpty ? "Ollama answered HTTP \(code)" : "HTTP \(code): \(body)"
        }
    }
}

/// Talks to one Ollama server. Basic auth in the URL (http://user:pass@host) is sent as a header.
public struct OllamaClient: Sendable {
    public let baseURL: URL
    let authorization: String?
    let session: URLSession

    public static let defaultURL = "http://localhost:11434"

    public init(urlString: String, session: URLSession = .shared) throws {
        guard let url = Self.validate(urlString), var parts = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { throw OllamaError.badURL(urlString) }
        if let user = parts.user {
            let token = "\(user.removingPercentEncoding ?? user):\(parts.password?.removingPercentEncoding ?? "")"
            authorization = "Basic " + Data(token.utf8).base64EncodedString()
            parts.user = nil
            parts.password = nil
        } else {
            authorization = nil
        }
        baseURL = parts.url ?? url
        self.session = session
    }

    /// The URL when it is http(s) with a host, else nil. Trailing slashes are dropped.
    public static func validate(_ string: String) -> URL? {
        var s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasSuffix("/") { s.removeLast() }
        guard let url = URL(string: s), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https", url.host()?.isEmpty == false
        else { return nil }
        return url
    }

    /// Host and port for display, without credentials.
    public var displayHost: String {
        let host = baseURL.host() ?? baseURL.absoluteString
        guard let port = baseURL.port, port != 11434 else { return host }
        return "\(host):\(port)"
    }

    public func snapshot() async throws -> ServerSnapshot {
        async let v: VersionResponse = get("api/version")
        async let ps: PSResponse = get("api/ps")
        async let tags: TagsResponse = get("api/tags")
        return try await ServerSnapshot(
            version: v.version,
            running: ps.models,
            installed: tags.models.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
    }

    /// Frees the model's memory now.
    public func unload(_ model: String) async throws {
        try await post("api/generate", body: ["model": model, "keep_alive": 0], timeout: 30)
    }

    /// Loads the model with the server's default keep-alive. Big models can take a while.
    public func load(_ model: String) async throws {
        try await post("api/generate", body: ["model": model], timeout: 300)
    }

    // MARK: - HTTP

    func request(_ path: String, timeout: TimeInterval) -> URLRequest {
        var r = URLRequest(url: baseURL.appending(path: path), timeoutInterval: timeout)
        if let authorization { r.setValue(authorization, forHTTPHeaderField: "Authorization") }
        return r
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, response) = try await session.data(for: request(path, timeout: 3))
        try Self.check(response, data)
        return try Self.decoder.decode(T.self, from: data)
    }

    func post(_ path: String, body: [String: any Sendable], timeout: TimeInterval) async throws {
        var r = request(path, timeout: timeout)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: r)
        try Self.check(response, data)
    }

    static func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) else { return }
        // Ollama errors look like {"error":"model 'x' not found"}.
        let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? ""
        throw OllamaError.http(http.statusCode, message)
    }

    public static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            guard let date = parseDate(s) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(s)"))
            }
            return date
        }
        return d
    }()

    /// Ollama sends Go timestamps with up to 9 fractional digits, which ISO8601DateFormatter rejects.
    public static func parseDate(_ s: String) -> Date? {
        var trimmed = s
        if let dot = s.firstIndex(of: "."),
           let zone = s[dot...].firstIndex(where: { $0 == "Z" || $0 == "+" || $0 == "-" }) {
            let fraction = s[s.index(after: dot)..<zone].prefix(3)
            trimmed = String(s[..<dot]) + "." + fraction.padding(toLength: 3, withPad: "0", startingAt: 0) + s[zone...]
        }
        let f = ISO8601DateFormatter()
        f.formatOptions = trimmed.contains(".") ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
        return f.date(from: trimmed)
    }
}
