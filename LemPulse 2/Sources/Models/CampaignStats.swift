import Foundation

struct CampaignStats: Codable {
    let nbLeads: Int?
    let nbLeadsLaunched: Int?
    let nbLeadsReached: Int?
    let nbLeadsInterested: Int?
    let nbLeadsUnsubscribed: Int?
    let messagesSent: Int?
    let messagesNotSent: Int?
    let messagesBounced: Int?
    let delivered: Int?
    let opened: Int?
    let clicked: Int?
    let replied: Int?
    let meetingBooked: Int?
}

struct CampaignStateResponse: Decodable {
    let id: String?
    let state: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case state
    }
}
