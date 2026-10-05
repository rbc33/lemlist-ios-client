import Foundation

struct LemlistUser: Codable {
    let id: String
    let email: String?
    let role: String?
    let mailboxes: [Mailbox]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, role, mailboxes
    }
}

struct Mailbox: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let provider: String?
    let status: String?
    let lemlist: MailboxLemlistSettings?
    let lemwarm: MailboxLemwarmFlag?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, provider, status, lemlist, lemwarm
    }

    /// Daily campaign sending limit. Read-only: lemlist's public API does not
    /// expose a way to write this value (only the lemwarm ramp-up settings are writable).
    var dailySendLimit: Int? { lemlist?.emailLimit }

    var warmupActive: Bool { lemwarm?.active ?? false }

    /// Verified live: healthy mailboxes report status "OK". "CONNECTED" is
    /// kept as a fallback in case lemlist's docs value ever shows up.
    var isConnected: Bool {
        let value = (status ?? "").uppercased()
        return value == "OK" || value == "CONNECTED"
    }
}

struct MailboxLemlistSettings: Codable, Hashable {
    let emailLimit: Int?

    enum CodingKeys: String, CodingKey { case emailLimit }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Verified live: lemlist returns this as a string ("50") for SMTP
        // mailboxes but as a number (200) for Google ones. Accept both.
        if let intValue = try? container.decode(Int.self, forKey: .emailLimit) {
            emailLimit = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .emailLimit) {
            emailLimit = Int(stringValue)
        } else {
            emailLimit = nil
        }
    }
}

struct MailboxLemwarmFlag: Codable, Hashable {
    let active: Bool?
}

/// Combines a mailbox with the team member who owns it, since the API only
/// nests mailboxes under a user, not the other way around.
struct MailboxWithOwner: Identifiable, Hashable {
    let mailbox: Mailbox
    let ownerUserId: String
    let ownerName: String

    var id: String { mailbox.id }
}
