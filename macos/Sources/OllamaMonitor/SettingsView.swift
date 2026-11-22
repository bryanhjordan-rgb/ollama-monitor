import OllamaKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var monitor: Monitor
    @State private var urlDraft = ""
    @State private var urlError: String?
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Connection") {
                TextField("API URL", text: $urlDraft, prompt: Text(OllamaClient.defaultURL))
                    .onSubmit(applyURL)
                if let urlError {
                    Text(urlError).font(.caption).foregroundStyle(.red)
                }
                HStack {
                    Button("Use Default") {
                        urlDraft = OllamaClient.defaultURL
                        applyURL()
                    }
                    .disabled(monitor.apiURL == OllamaClient.defaultURL)
                    Spacer()
                    Button("Apply", action: applyURL)
                        .keyboardShortcut(.defaultAction)
                        .disabled(urlDraft == monitor.apiURL)
                }
                Picker("Check every", selection: $monitor.pollSeconds) {
                    ForEach([2.0, 3, 5, 10, 30], id: \.self) { Text("\(Int($0)) seconds").tag($0) }
                }
            }
            Section("Notifications") {
                Toggle("When a model loads or unloads", isOn: $monitor.notifyModels)
                Toggle("When Ollama stops or starts responding", isOn: $monitor.notifyOffline)
            }
            Section("Menu Bar") {
                Toggle("Show the number of loaded models", isOn: $monitor.showCount)
                Toggle("Open at login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { _, on in setOpenAtLogin(on) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { urlDraft = monitor.apiURL }
    }

    private func applyURL() {
        guard OllamaClient.validate(urlDraft) != nil else {
            urlError = "Enter a URL that starts with http:// or https://, like \(OllamaClient.defaultURL)."
            return
        }
        urlError = nil
        let cleaned = urlDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        urlDraft = cleaned
        if cleaned != monitor.apiURL { monitor.apiURL = cleaned }
    }

    private func setOpenAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        guard on != (service.status == .enabled) else { return }
        do {
            try on ? service.register() : service.unregister()
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            openAtLogin = service.status == .enabled
        }
    }
}
