import Foundation
import Observation

/// Lightweight observable flag so views can react instantly when the API key
/// is added or removed in Settings, without re-reading the Keychain each time.
@Observable
final class AppSettings {
    var hasAPIKey: Bool

    init() {
        hasAPIKey = (KeychainStore.loadAPIKey()?.isEmpty == false)
    }

    func refresh() {
        hasAPIKey = (KeychainStore.loadAPIKey()?.isEmpty == false)
    }
}
