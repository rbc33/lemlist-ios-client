import Foundation

/// Wraps a Decodable type so that a single malformed element inside a JSON
/// array doesn't fail decoding of the whole array. Used for list endpoints
/// where the API might return a field/shape we don't fully model yet — we'd
/// rather show 19 out of 20 campaigns than show none with a generic
/// "couldn't read the server response" error.
struct FailableDecodable<Base: Decodable>: Decodable {
    let base: Base?

    init(from decoder: Decoder) {
        base = try? Base(from: decoder)
    }
}
