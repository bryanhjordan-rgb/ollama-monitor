import Foundation

enum ModelStorage {
    static var directory: URL {
        if let path = ProcessInfo.processInfo.environment["OLLAMA_MODELS"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appending(path: ".ollama/models", directoryHint: .isDirectory)
    }

    static func manifest(for name: String, in directory: URL = ModelStorage.directory) -> URL? {
        var parts = name.split(separator: "/", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count), let last = parts.popLast() else { return nil }

        let modelAndTag = last.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard let model = modelAndTag.first else { return nil }
        let tag = modelAndTag.count == 2 ? modelAndTag[1] : "latest"
        let namespace = parts.popLast() ?? "library"
        let host = parts.popLast() ?? "registry.ollama.ai"
        guard [namespace, model, tag].allSatisfy({ validComponent($0) }),
              validComponent(host, allowingPort: true)
        else { return nil }

        let isPublicHost = ["registry.ollama.ai", "ollama.com"].contains(host.lowercased())
        let v2Host = isPublicHost ? "ollama.com" : host.replacingOccurrences(of: ":", with: "%3A")
        let hosts = isPublicHost ? [("manifests-v2", v2Host), ("manifests", "registry.ollama.ai"), ("manifests", "ollama.com")]
            : [("manifests-v2", v2Host), ("manifests", String(host))]
        for (store, host) in hosts {
            let url = directory.appending(path: "\(store)/\(host)/\(namespace)/\(model)/\(tag)")
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue { return url }
        }
        return nil
    }

    private static func validComponent(_ component: Substring, allowingPort: Bool = false) -> Bool {
        let pattern = allowingPort ? #"^[A-Za-z0-9_][A-Za-z0-9_.:-]*$"# : #"^[A-Za-z0-9_][A-Za-z0-9_.-]*$"#
        return component.range(of: pattern, options: .regularExpression) != nil
    }
}
