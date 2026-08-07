import Foundation
import Observation

/// Lightweight observable flags so views can react instantly to changes in
/// Settings, without re-reading Keychain/UserDefaults each time.
@Observable
final class AppSettings {
    var hasAPIKey: Bool
    var currentUserId: String?
    var currentUserDisplayName: String?

    init() {
        hasAPIKey = (KeychainStore.loadAPIKey()?.isEmpty == false)
        currentUserId = CurrentUserStore.userId
        currentUserDisplayName = CurrentUserStore.displayName
    }

    func refresh() {
        hasAPIKey = (KeychainStore.loadAPIKey()?.isEmpty == false)
        currentUserId = CurrentUserStore.userId
        currentUserDisplayName = CurrentUserStore.displayName
    }
}
