import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    @State private var apiKeyInput: String = ""
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var teamMembers: [TeamMember] = []
    @State private var isLoadingMembers = false
    @State private var membersError: String?

    private enum TestResult {
        case success(String)
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API key de lemlist", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Guardar") { save() }
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                    if settings.hasAPIKey {
                        Button("Eliminar API key", role: .destructive) { remove() }
                    }
                } header: {
                    Text("lemlist")
                } footer: {
                    Text("Consigue tu API key en app.lemlist.com → Settings → Integrations. Se guarda de forma segura en el Keychain del dispositivo, nunca en texto plano.")
                }

                if settings.hasAPIKey {
                    Section("Conexión") {
                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack {
                                Text("Probar conexión")
                                Spacer()
                                if isTesting { ProgressView() }
                            }
                        }
                        .disabled(isTesting)

                        if let testResult {
                            switch testResult {
                            case .success(let name):
                                Label("Conectado a \"\(name)\"", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .failure(let message):
                                Label(message, systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                if settings.hasAPIKey {
                    Section {
                        if let name = settings.currentUserDisplayName {
                            LabeledContent("Usando como", value: name)
                        }
                        Button {
                            Task { await loadTeamMembers() }
                        } label: {
                            HStack {
                                Text(settings.currentUserId == nil ? "Elegir quién eres" : "Cambiar usuario")
                                Spacer()
                                if isLoadingMembers { ProgressView() }
                            }
                        }
                        .disabled(isLoadingMembers)

                        if !teamMembers.isEmpty {
                            ForEach(teamMembers) { member in
                                Button {
                                    CurrentUserStore.set(userId: member.userId, displayName: member.displayName)
                                    settings.refresh()
                                    teamMembers = []
                                } label: {
                                    HStack {
                                        Text(member.displayName)
                                        Spacer()
                                        if member.userId == settings.currentUserId {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        if let membersError {
                            Text(membersError)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Tu usuario")
                    } footer: {
                        Text("Se usa para marcar las conversaciones de la Bandeja como leídas en tu nombre. Si no lo eliges, se usa el remitente original de cada campaña como aproximación.")
                    }
                }

                Section("Acerca de") {
                    LabeledContent("App", value: "LemPulse")
                    Link("Documentación de la API de lemlist", destination: URL(string: "https://developer.lemlist.com")!)
                }
            }
            .navigationTitle("Ajustes")
        }
    }

    private func save() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await LemlistAPIClient.shared.setAPIKey(trimmed)
            settings.refresh()
        }
        apiKeyInput = ""
        testResult = nil
    }

    private func remove() {
        Task {
            await LemlistAPIClient.shared.setAPIKey(nil)
            settings.refresh()
        }
        testResult = nil
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }
        do {
            let team = try await LemlistAPIClient.shared.testConnection()
            testResult = .success(team.name)
        } catch {
            testResult = .failure((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    private func loadTeamMembers() async {
        isLoadingMembers = true
        membersError = nil
        do {
            let team = try await LemlistAPIClient.shared.fetchTeam()
            teamMembers = team.users ?? []
            if teamMembers.isEmpty {
                membersError = "No se encontraron usuarios en el equipo."
            }
        } catch {
            membersError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingMembers = false
    }
}
