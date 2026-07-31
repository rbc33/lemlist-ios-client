import SwiftUI

struct CampaignDetailView: View {
    @State var campaign: Campaign

    @State private var stats: CampaignStats?
    @State private var isLoadingStats = false
    @State private var statsError: String?
    @State private var isToggling = false
    @State private var toggleError: String?

    var body: some View {
        List {
            Section {
                LabeledContent("Estado") {
                    Label(campaign.status.displayName, systemImage: campaign.status.systemImage)
                        .foregroundStyle(campaign.status.tint)
                }
                if let createdAt = campaign.createdAt {
                    LabeledContent("Creada", value: createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                if let labels = campaign.labels, !labels.isEmpty {
                    LabeledContent("Etiquetas", value: labels.joined(separator: ", "))
                }
            }

            if campaign.hasError == true, let errors = campaign.errors, !errors.isEmpty {
                Section("Errores") {
                    ForEach(errors, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }

            Section("Últimos 30 días") {
                if isLoadingStats {
                    ProgressView()
                } else if let statsError {
                    Text(statsError)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else if let stats {
                    statGrid(stats)
                }
            }

            if campaign.status == .running || campaign.status == .paused {
                Section {
                    Button {
                        Task { await toggle() }
                    } label: {
                        HStack {
                            if isToggling { ProgressView() }
                            Text(campaign.status == .running ? "Pausar campaña" : "Reanudar campaña")
                        }
                    }
                    .disabled(isToggling)
                    .foregroundStyle(campaign.status == .running ? .orange : .green)
                }
            }
        }
        .navigationTitle(campaign.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadStats() }
        .alert("No se pudo actualizar la campaña", isPresented: toggleErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(toggleError ?? "")
        }
    }

    private var toggleErrorBinding: Binding<Bool> {
        Binding(get: { toggleError != nil }, set: { if !$0 { toggleError = nil } })
    }

    @ViewBuilder
    private func statGrid(_ stats: CampaignStats) -> some View {
        StatRow(label: "Leads", value: stats.nbLeads)
        StatRow(label: "Lanzados", value: stats.nbLeadsLaunched)
        StatRow(label: "Emails enviados", value: stats.messagesSent)
        StatRow(label: "Entregados", value: stats.delivered)
        StatRow(label: "Abiertos", value: stats.opened)
        StatRow(label: "Clics", value: stats.clicked)
        StatRow(label: "Respuestas", value: stats.replied)
        StatRow(label: "Interesados", value: stats.nbLeadsInterested)
        StatRow(label: "Rebotes", value: stats.messagesBounced)
        StatRow(label: "Reuniones", value: stats.meetingBooked)
    }

    private func loadStats() async {
        isLoadingStats = true
        statsError = nil
        do {
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
            stats = try await LemlistAPIClient.shared.fetchCampaignStats(id: campaign.id, startDate: start, endDate: end)
        } catch {
            statsError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingStats = false
    }

    private func toggle() async {
        isToggling = true
        do {
            if campaign.status == .running {
                try await LemlistAPIClient.shared.pauseCampaign(id: campaign.id)
                campaign = Campaign(id: campaign.id, name: campaign.name, status: .paused, createdAt: campaign.createdAt, hasError: campaign.hasError, errors: campaign.errors, labels: campaign.labels)
            } else {
                try await LemlistAPIClient.shared.startCampaign(id: campaign.id)
                campaign = Campaign(id: campaign.id, name: campaign.name, status: .running, createdAt: campaign.createdAt, hasError: campaign.hasError, errors: campaign.errors, labels: campaign.labels)
            }
        } catch {
            toggleError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isToggling = false
    }
}

private struct StatRow: View {
    let label: String
    let value: Int?

    var body: some View {
        LabeledContent(label, value: value.map(String.init) ?? "—")
    }
}
