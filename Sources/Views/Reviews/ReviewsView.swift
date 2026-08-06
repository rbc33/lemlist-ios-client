import SwiftUI

struct ReviewsView: View {
    @State private var buildings: [VecyBuilding] = []
    @State private var totalCount = 0
    @State private var newSinceLastCheck: Int?
    @State private var history: [VecyReviewHistoryEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Reseñas")
                .navigationDestination(for: VecyBuilding.self) { BuildingReviewsView(building: $0) }
                .task { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && buildings.isEmpty {
            ProgressView("Cargando reseñas…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            RetryableErrorView(message: errorMessage) { await load() }
        } else if buildings.isEmpty {
            ContentUnavailableView("Sin reseñas", systemImage: "star", description: Text("No se encontraron edificios con reseñas."))
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

                Section("Edificios") {
                    ForEach(buildings) { building in
                        NavigationLink(value: building) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(building.direccion)
                                    .font(.body.weight(.medium))
                                    .lineLimit(2)
                                HStack(spacing: 6) {
                                    if let media = building.valoracionMedia {
                                        Label(String(format: "%.1f", media), systemImage: "star.fill")
                                            .foregroundStyle(.orange)
                                    }
                                    Text("· \(building.reviewCount) reseña\(building.reviewCount == 1 ? "" : "s")")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
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

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let totalTask = VecyAPIClient.shared.fetchTotalCount()
            async let buildingsTask = VecyAPIClient.shared.fetchBuildings()
            let (total, fetchedBuildings) = try await (totalTask, buildingsTask)

            buildings = fetchedBuildings.sorted { $0.direccion.localizedCaseInsensitiveCompare($1.direccion) == .orderedAscending }
            totalCount = total
            newSinceLastCheck = VecyReviewsStore.recordVisit(count: total)
            history = VecyReviewsStore.history
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
