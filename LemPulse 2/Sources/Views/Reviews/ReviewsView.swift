import SwiftUI

struct ReviewsView: View {
    @State private var totalCount = 0
    @State private var newSinceLastCheck: Int?
    @State private var history: [VecyReviewHistoryEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedOnce = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Reseñas")
                .task { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && !hasLoadedOnce {
            ProgressView("Cargando reseñas…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            RetryableErrorView(message: errorMessage) { await load() }
        } else {
            List {
                Section("Total de reseñas") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(totalCount)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))

                        if let newSinceLastCheck, newSinceLastCheck > 0 {
                            Label("\(newSinceLastCheck) nueva\(newSinceLastCheck == 1 ? "" : "s") desde la última vez", systemImage: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else if newSinceLastCheck != nil {
                            Text("Sin novedades desde la última vez")
                                .font(.subheadline)
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
            .refreshable { await load() }
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

    /// Only calls GET /resenas/contador — deliberately does NOT fetch the
    /// full /resenas endpoint (buildings + nested reviews), which is far
    /// heavier and unnecessary just to track a running total.
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let total = try await VecyAPIClient.shared.fetchTotalCount()
            totalCount = total
            newSinceLastCheck = VecyReviewsStore.recordVisit(count: total)
            history = VecyReviewsStore.history
            hasLoadedOnce = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
