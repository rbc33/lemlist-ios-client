import Foundation

/// Remembers which lemlist team member the app is being used as. Not
/// sensitive (just a userId + display name), so plain UserDefaults is fine
/// — unlike the API key, which goes in Keychain.
enum CurrentUserStore {
    private static let idKey = "lempulse.currentUserId"
    private static let nameKey = "lempulse.currentUserDisplayName"

    static var userId: String? {
        get { UserDefaults.standard.string(forKey: idKey) }
        set { UserDefaults.standard.set(newValue, forKey: idKey) }
    }

    static var displayName: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static func set(userId: String, displayName: String) {
        self.userId = userId
        self.displayName = displayName
    }

    static func clear() {
        userId = nil
        displayName = nil
    }
}
