import Foundation

/// One row from GET /activities?type=emailsReplied — a lead who replied,
/// with enough context to show in a list without an extra call per row.
struct InboxReplyActivity: Decodable, Identifiable, Hashable {
    let id: String
    let contactId: String
    let leadId: String?
    let leadEmail: String?
    let leadFirstName: String?
    let leadLastName: String?
    let leadCompanyName: String?
    let campaignId: String?
    let campaignName: String?
    let subject: String?
    let messagePreview: String?
    let createdAt: Date?
    let sendUserId: String?
    let sendUserEmail: String?
    let sendUserMailboxId: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case contactId, leadId, leadEmail, leadFirstName, leadLastName, leadCompanyName
        case campaignId, campaignName, subject, messagePreview, createdAt
        case sendUserId, sendUserEmail, sendUserMailboxId
    }

    var leadDisplayName: String {
        let name = [leadFirstName, leadLastName].compactMap { $0 }.joined(separator: " ")
        if !name.trimmingCharacters(in: .whitespaces).isEmpty { return name }
        return leadEmail ?? leadCompanyName ?? "Lead"
    }
}

/// GET /inbox/{contactId} response. Wrapped in FailableDecodable so one
/// oddly-shaped message doesn't take down the whole thread.
struct InboxMessagesResponse: Decodable {
    let data: [FailableDecodable<InboxMessage>]
}

/// One message in a contact's thread — covers both outgoing (emailsSent) and
/// incoming (emailsReplied) entries, so most fields are optional since their
/// presence depends on the message type.
struct InboxMessage: Decodable, Identifiable, Hashable {
    let id: String
    let type: String
    let createdAt: Date?
    let message: String?
    let subject: String?
    let sendUserName: String?
    let sendUserEmail: String?
    let sendUserId: String?
    let sendUserMailboxId: String?
    let leadEmail: String?
    let fromEmail: String?
    let contactId: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type, createdAt, message, subject
        case sendUserName, sendUserEmail, sendUserId, sendUserMailboxId
        case leadEmail, fromEmail, contactId
    }

    /// True for a message the lead sent (as opposed to one we sent them).
    var isFromLead: Bool { type == "emailsReplied" }
}
