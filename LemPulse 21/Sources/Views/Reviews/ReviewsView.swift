import SwiftUI

struct ReviewsView: View {
    /// Only auto-refresh on open if the last recorded entry is older than this.
    private static let minimumAutoRefreshInterval: TimeInterval = 24 * 60 * 60

    @State private var history: [VecyReviewHistoryEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Reseñas")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await refreshAndRecord() }
                        } label: {
                            Label("Refrescar", systemImage: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                    }
                }
                .task { await loadOnAppear() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && !hasLoadedOnce {
            ProgressView("Cargando reseñas…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage, history.isEmpty {
            RetryableErrorView(message: errorMessage) { await refreshAndRecord() }
        } else {
            List {
                Section("Total de reseñas") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(latestEntry?.count ?? 0)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))

                        if let latestDelta, latestDelta > 0 {
                            Label("\(latestDelta) nueva\(latestDelta == 1 ? "" : "s") desde el último registro", systemImage: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else if latestDelta != nil {
                            Text("Sin novedades desde el último registro")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let latestEntry {
                            Text("Actualizado \(latestEntry.date.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if !history.isEmpty {
                    Section("Historial de visitas") {
                        ForEach(historyRows, id: \.entry.id) { row in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                    if let delta = row.delta {
                                        if delta > 0 {
                                            Text("+\(delta) nueva\(delta == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        } else {
                                            Text("Sin cambios")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                Text("\(row.entry.count)")
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await refreshAndRecord() }
        }
    }

    /// History entries paired with the delta versus the visit right before
    /// them, newest first.
    private var historyRows: [(entry: VecyReviewHistoryEntry, delta: Int?)] {
        let newestFirst = history.sorted { $0.date > $1.date }
        return newestFirst.enumerated().map { index, entry in
            let delta = index + 1 < newestFirst.count ? entry.count - newestFirst[index + 1].count : nil
            return (entry, delta)
        }
    }

    private var latestEntry: VecyReviewHistoryEntry? { historyRows.first?.entry }
    private var latestDelta: Int? { historyRows.first?.delta }

    /// Called every time the tab appears. Only hits the network (and only
    /// records a new history point) if the last recorded entry is missing
    /// or older than 24h — otherwise just shows what's already saved
    /// locally, so opening the tab repeatedly doesn't spam the history.
    private func loadOnAppear() async {
        history = VecyReviewsStore.history
        if let last = history.max(by: { $0.date < $1.date }),
           Date().timeIntervalSince(last.date) < Self.minimumAutoRefreshInterval {
            hasLoadedOnce = true
            return
        }
        await refreshAndRecord()
    }

    /// Always hits GET /resenas/contador and always records the result —
    /// used by the refresh button, pull-to-refresh, and the 24h auto-check.
    private func refreshAndRecord() async {
        isLoading = true
        errorMessage = nil
        do {
            let total = try await VecyAPIClient.shared.fetchTotalCount()
            VecyReviewsStore.recordVisit(count: total)
            history = VecyReviewsStore.history
            hasLoadedOnce = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
