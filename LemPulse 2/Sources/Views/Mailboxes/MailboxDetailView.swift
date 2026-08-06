import SwiftUI

struct MailboxDetailView: View {
    let item: MailboxWithOwner

    @State private var settings: LemwarmSettings?
    @State private var isLoading = false
    @State private var loadError: String?

    @State private var maxWarmEmails: Int = 5
    @State private var rampup: Int = 1
    @State private var isSaving = false
    @State private var isTogglingWarmup = false
    @State private var actionError: String?
    @State private var warmupActive: Bool = false

    var body: some View {
        List {
            Section {
                LabeledContent("Email", value: item.mailbox.email)
                LabeledContent("Propietario", value: item.ownerName)
                if let provider = item.mailbox.provider {
                    LabeledContent("Proveedor", value: provider.capitalized)
                }
                LabeledContent("Estado") {
                    Text(item.mailbox.isConnected ? "Conectado" : (item.mailbox.status ?? "Desconocido"))
                        .foregroundStyle(item.mailbox.isConnected ? .green : .orange)
                }
            }

            Section {
                LabeledContent("Límite diario de campañas") {
                    Text(item.mailbox.dailySendLimit.map { "\($0) emails/día" } ?? "No disponible")
                }
            } footer: {
                Text("Este límite se ve pero no se puede modificar: la API pública de lemlist no expone un endpoint para escribirlo, solo se cambia desde la app web de lemlist.")
            }

            if warmupActive {
                warmupSections
            } else {
                Section {
                    Button {
                        Task { await toggleWarmup() }
                    } label: {
                        HStack {
                            if isTogglingWarmup { ProgressView() }
                            Text("Activar warmup")
                        }
                    }
                    .disabled(isTogglingWarmup)
                }
            }
        }
        .navigationTitle(item.mailbox.email)
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .alert("No se pudo completar la acción", isPresented: actionErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
        .onAppear { warmupActive = item.mailbox.warmupActive }
    }

    @ViewBuilder
    private var warmupSections: some View {
        Section("Warmup") {
            if isLoading {
                ProgressView()
            } else if let loadError {
                Text(loadError).foregroundStyle(.secondary).font(.subheadline)
            } else if let settings {
                HStack {
                    ScoreGauge(score: settings.score ?? 0, size: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Puntuación de deliverability")
                            .font(.subheadline.weight(.medium))
                        if let lastChecked = settings.lastCheckedAt {
                            Text("Actualizado \(lastChecked.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Button {
                Task { await toggleWarmup() }
            } label: {
                HStack {
                    if isTogglingWarmup { ProgressView() }
                    Text("Pausar warmup")
                }
            }
            .disabled(isTogglingWarmup)
            .foregroundStyle(.orange)
        }

        Section {
            Stepper(value: $maxWarmEmails, in: 1...200) {
                LabeledContent("Máx. emails de warmup/día", value: "\(maxWarmEmails)")
            }
            Stepper(value: $rampup, in: 0...50) {
                LabeledContent("Incremento diario", value: "\(rampup)")
            }
            Button {
                Task { await saveWarmupSettings() }
            } label: {
                HStack {
                    if isSaving { ProgressView() }
                    Text("Guardar cambios de warmup")
                }
            }
            .disabled(isSaving)
        } header: {
            Text("Configuración de warmup")
        } footer: {
            Text("Estos dos valores sí son editables vía API: cuántos emails de calentamiento se envían como máximo al día y en cuánto aumenta ese número cada día.")
        }
    }

    private var actionErrorBinding: Binding<Bool> {
        Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })
    }

    private func load() {
        guard warmupActive else { return }
        Task {
            isLoading = true
            loadError = nil
            do {
                let fetched = try await LemlistAPIClient.shared.fetchLemwarmSettings(mailboxId: item.mailbox.id)
                settings = fetched
                maxWarmEmails = fetched.effectiveMax
                rampup = fetched.effectiveRampup
            } catch {
                loadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }

    private func saveWarmupSettings() async {
        isSaving = true
        do {
            try await LemlistAPIClient.shared.updateLemwarmSettings(
                mailboxId: item.mailbox.id,
                warmEmailMax: maxWarmEmails,
                warmEmailRampup: rampup
            )
            load()
        } catch {
            actionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isSaving = false
    }

    private func toggleWarmup() async {
        isTogglingWarmup = true
        do {
            if warmupActive {
                try await LemlistAPIClient.shared.pauseLemwarm(mailboxId: item.mailbox.id)
                warmupActive = false
            } else {
                try await LemlistAPIClient.shared.startLemwarm(mailboxId: item.mailbox.id)
                warmupActive = true
                load()
            }
        } catch {
            actionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isTogglingWarmup = false
    }
}
