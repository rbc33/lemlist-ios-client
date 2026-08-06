import Foundation

struct VecyReviewsResponse: Decodable {
    let success: Bool
    let data: VecyReviewsData
}

/// GET /resenas/contador response — a lightweight server-computed total,
/// verified live via curl: {"success":true,"data":{"total_resenas":165}}
struct VecyReviewCountResponse: Decodable {
    let success: Bool
    let data: VecyReviewCountData
}

struct VecyReviewCountData: Decodable {
    let totalResenas: Int

    enum CodingKeys: String, CodingKey {
        case totalResenas = "total_resenas"
    }
}

struct VecyReviewsData: Decodable {
    let edificios: [VecyBuilding]
}

struct VecyBuilding: Decodable, Identifiable, Hashable {
    let direccion: String
    let valoracionMedia: Double?
    let numResenas: Int?
    let resenas: [VecyReview]?

    var id: String { direccion }

    enum CodingKeys: String, CodingKey {
        case direccion
        case valoracionMedia = "valoracion_media"
        case numResenas = "num_resenas"
        case resenas
    }

    /// Prefer the actual review array length over the `num_resenas` field —
    /// it's ground truth even if that count field is ever stale.
    var reviewCount: Int { resenas?.count ?? numResenas ?? 0 }
}

struct VecyReview: Decodable, Hashable {
    let fecha: String?
    let valoracion: Int?
    let texto: String?
}
