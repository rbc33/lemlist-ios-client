import Foundation

/// One recorded visit to the Reseñas tab: the date it was opened and the
/// total review count at that moment.
struct VecyReviewHistoryEntry: Codable, Identifiable, Hashable {
    let date: Date
    let count: Int
    var id: Date { date }
}

/// Persists every visit's review count locally so the app can show a
/// history over time and how many reviews are new since the last visit.
/// Not sensitive data, so plain UserDefaults is fine (unlike the lemlist
/// API key, which goes in Keychain).
enum VecyReviewsStore {
    private static let historyKey = "vecy.reviewHistory"
    /// Caps how many visits we keep on disk so this doesn't grow forever.
    private static let maxHistoryEntries = 200

    static var history: [VecyReviewHistoryEntry] {
        get {
            guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
            return (try? JSONDecoder().decode([VecyReviewHistoryEntry].self, from: data)) ?? []
        }
        set {
            let trimmed = Array(newValue.suffix(maxHistoryEntries))
            if let data = try? JSONEncoder().encode(trimmed) {
                UserDefaults.standard.set(data, forKey: historyKey)
            }
        }
    }

    /// The count recorded on the most recent prior visit, if any.
    static var lastKnownCount: Int? { history.last?.count }

    /// Records a new visit with today's total, and returns how many reviews
    /// are new compared to the previous visit (nil on the very first visit
    /// ever, since there's nothing to compare against).
    @discardableResult
    static func recordVisit(count: Int) -> Int? {
        let previous = lastKnownCount
        var updated = history
        updated.append(VecyReviewHistoryEntry(date: Date(), count: count))
        history = updated
        guard let previous else { return nil }
        return max(0, count - previous)
    }
}
