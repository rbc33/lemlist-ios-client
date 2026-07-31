import Foundation

/// lemlist's own API docs show two different shapes for this object depending
/// on which page you read (the endpoint example uses `warmEmailMax` /
/// `warmEmailRampup` / `activeAt`, while the schema reference uses `dailyLimit`
/// / `warmupTemplate`). Every field here is optional on purpose so decoding
/// never fails regardless of which shape the API actually returns, and the
/// `effective*` helpers pick whichever value is present.
struct LemwarmSettings: Codable {
    let active: Bool?
    let dailyLimit: Int?
    let warmupTemplate: String?
    let warmDailyVarianceEnabled: Bool?
    let deliverability: Deliverability?
    let warmEmailMax: Int?
    let warmEmailRampup: Int?
    let activeAt: Date?

    struct Deliverability: Codable {
        let score: Int?
        let lastAt: Date?
    }

    /// Best-effort current "max warm emails per day".
    var effectiveMax: Int { warmEmailMax ?? dailyLimit ?? 5 }

    /// Best-effort current daily ramp-up increase. lemlist doesn't return this
    /// under the schema-documented shape at all, so this just falls back to a
    /// sane default if only `dailyLimit`-style data came back.
    var effectiveRampup: Int { warmEmailRampup ?? 1 }

    var score: Int? { deliverability?.score }
    var lastCheckedAt: Date? { deliverability?.lastAt }
}

struct LemwarmUpdateBody: Encodable {
    let warmEmailMax: Int
    let warmEmailRampup: Int
}

struct OKResponse: Decodable {
    let ok: Bool?
}
