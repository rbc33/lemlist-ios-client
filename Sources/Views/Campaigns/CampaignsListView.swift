import SwiftUI

struct CampaignsListView: View {
    @Environment(AppSettings.self) private var settings

    @State private var campaigns: [Campaign] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var statusFilter: CampaignStatus?
    @State private var actionErrorMessage: String?

    private var filteredCampaigns: [Campaign] {
        guard let statusFilter else { return campaigns }
        return campaigns.filter { $0.effectiveStatus == statusFilter }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Campañas")
                .navigationDestination(for: Campaign.self) { CampaignDetailView(campaign: $0) }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                statusFilter = nil
                            } label: {
                                Label("Todas", systemImage: statusFilter == nil ? "checkmark" : "")
                            }
                            ForEach(CampaignStatus.allCases) { status in
                                Button {
                                    statusFilter = status
                                } label: {
                                    Label(status.displayName, systemImage: statusFilter == status ? "checkmark" : "")
                                }
                            }
                        } label: {
                            Label("Filtrar", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                .task { await load() }
                .alert("No se pudo completar la acción", isPresented: actionErrorBinding) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(actionErrorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !settings.hasAPIKey {
            MissingAPIKeyView()
        } else if isLoading && campaigns.isEmpty {
            ProgressView("Cargando campañas…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            RetryableErrorView(message: errorMessage) { await load() }
        } else if campaigns.isEmpty {
            ContentUnavailableView("Sin campañas", systemImage: "megaphone", description: Text("No se encontraron campañas en tu cuenta de lemlist."))
        } else {
            List(filteredCampaigns) { campaign in
                NavigationLink(value: campaign) {
                    CampaignRowView(campaign: campaign)
                }
                .swipeActions(edge: .trailing) {
                    if campaign.archived != true {
                        if campaign.status == .running {
                            Button {
                                Task { await toggle(campaign) }
                            } label: {
                                Label("Pausar", systemImage: "pause.fill")
                            }
                            .tint(.orange)
                        } else if campaign.status == .paused {
                            Button {
                                Task { await toggle(campaign) }
                            } label: {
                                Label("Reanudar", systemImage: "play.fill")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await load() }
        }
    }

    private var actionErrorBinding: Binding<Bool> {
        Binding(get: { actionErrorMessage != nil }, set: { if !$0 { actionErrorMessage = nil } })
    }

    private func load() async {
        guard settings.hasAPIKey else { return }
        isLoading = true
        errorMessage = nil
        do {
            campaigns = try await LemlistAPIClient.shared.fetchCampaigns()
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func toggle(_ campaign: Campaign) async {
        do {
            if campaign.status == .running {
                try await LemlistAPIClient.shared.pauseCampaign(id: campaign.id)
            } else {
                try await LemlistAPIClient.shared.startCampaign(id: campaign.id)
            }
            await load()
        } catch {
            actionErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
