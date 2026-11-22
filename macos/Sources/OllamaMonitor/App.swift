import OllamaKit
import SwiftUI

@main
struct OllamaMonitorApp: App {
    // One instance for the app's life; @Observable needs no @State here.
    private let monitor = Monitor()

    init() {
        if let dir = Snapshot.directory {
            let monitor = monitor
            Task {
                await Snapshot.run(to: dir, settings: monitor)
                exit(0)
            }
        } else {
            monitor.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(monitor: monitor)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(monitor: monitor)
        }
    }
}

struct MenuBarLabel: View {
    let monitor: Monitor

    var body: some View {
        let count = monitor.running.count
        if monitor.showCount && count > 0 {
            Label("\(count)", systemImage: monitor.symbol)
                .labelStyle(.titleAndIcon)
        } else {
            Image(systemName: monitor.symbol)
                .accessibilityLabel("Ollama Monitor")
        }
    }
}
