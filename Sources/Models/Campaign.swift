import Foundation

struct Campaign: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let status: CampaignStatus
    let createdAt: Date?
    let hasError: Bool?
    let errors: [String]?
    let labels: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, status, createdAt, hasError, errors, labels
    }
}

enum CampaignStatus: String, Identifiable, Hashable {
    case running, paused, draft, ended, archived, errors
    /// Fallback for any status value lemlist adds later that this build
    /// doesn't know about yet — keeps the campaign visible instead of
    /// silently dropping it.
    case unknown

    var id: String { rawValue }

    /// Deliberately excludes `.unknown` — it's a decode fallback, not a
    /// real filter a user would pick.
    static var allCases: [CampaignStatus] { [.running, .paused, .draft, .ended, .archived, .errors] }

    var displayName: String {
        switch self {
        case .running: return "Activa"
        case .paused: return "Pausada"
        case .draft: return "Borrador"
        case .ended: return "Finalizada"
        case .archived: return "Archivada"
        case .errors: return "Con errores"
        case .unknown: return "Desconocido"
        }
    }

    var systemImage: String {
        switch self {
        case .running: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .draft: return "doc.circle"
        case .ended: return "checkmark.circle"
        case .archived: return "archivebox.circle"
        case .errors: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

extension CampaignStatus: Decodable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CampaignStatus(rawValue: raw) ?? .unknown
    }
}
