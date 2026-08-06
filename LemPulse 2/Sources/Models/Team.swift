import Foundation

struct TeamInfo: Codable {
    let id: String
    let name: String
    let users: [TeamMember]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, users
    }
}

struct TeamMember: Codable, Identifiable, Hashable {
    let userId: String
    let name: String?
    let email: String?
    let role: String?

    var id: String { userId }

    var displayName: String {
        name ?? email ?? userId
    }
}
