import SwiftUI

struct BuildingReviewsView: View {
    let building: VecyBuilding

    var body: some View {
        List {
            Section {
                if let media = building.valoracionMedia {
                    LabeledContent("Valoración media") {
                        Label(String(format: "%.1f", media), systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                }
                LabeledContent("Nº de reseñas", value: "\(building.reviewCount)")
            }

            if let reviews = building.resenas, !reviews.isEmpty {
                Section("Reseñas") {
                    ForEach(Array(reviews.enumerated()), id: \.offset) { _, review in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if let valoracion = review.valoracion {
                                    HStack(spacing: 2) {
                                        ForEach(0..<5, id: \.self) { i in
                                            Image(systemName: i < valoracion ? "star.fill" : "star")
                                                .foregroundStyle(.orange)
                                                .font(.caption2)
                                        }
                                    }
                                }
                                Spacer()
                                if let fecha = review.fecha {
                                    Text(fecha)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if let texto = review.texto {
                                Text(texto)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(building.direccion)
        .navigationBarTitleDisplayMode(.inline)
    }
}
