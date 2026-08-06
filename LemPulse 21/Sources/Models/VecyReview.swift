import Foundation

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
