import Foundation

public enum Format {
    /// "9.1 GB"
    public static func bytes(_ n: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: n, countStyle: .memory)
    }

    /// Time left before Ollama unloads the model: "4:12", "1:02:03", "now",
    /// or nil when it stays loaded (keep_alive -1 gives an expiry centuries away).
    public static func countdown(until expiry: Date?, now: Date = .now) -> String? {
        guard let expiry else { return nil }
        let seconds = Int(expiry.timeIntervalSince(now).rounded(.up))
        if seconds > 7 * 24 * 3600 { return nil }
        if seconds <= 0 { return "now" }
        let h = seconds / 3600, m = seconds % 3600 / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// "8K" for 8192, "128K" for 131072, "2048" below 4096.
    public static func context(_ tokens: Int) -> String {
        tokens >= 4096 && tokens % 1024 == 0 ? "\(tokens / 1024)K" : "\(tokens)"
    }

    /// "100% GPU", "40% GPU / 60% CPU", "CPU".
    public static func placement(gpuShare: Double) -> String {
        let gpu = Int((gpuShare * 100).rounded())
        switch gpu {
        case 100: return "100% GPU"
        case 0: return "CPU"
        default: return "\(gpu)% GPU / \(100 - gpu)% CPU"
        }
    }
}
