import Foundation

/// Talks to Vecy's own reviews API at api.vecy.es — completely separate
/// from lemlist. Per live curl checks, both endpoints below are public and
/// need no auth headers:
///   GET /resenas          -> { "success": true, "data": { "edificios": [...] } }
///     each building carries its own nested `resenas` array.
///   GET /resenas/contador -> { "success": true, "data": { "total_resenas": N } }
///     a lightweight server-computed total, used instead of summing
///     buildings client-side.
actor VecyAPIClient {
    static let shared = VecyAPIClient()

    private let baseURL = URL(string: "https://api.vecy.es")!
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    private func request<T: Decodable>(path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw APIError.server(status: http.statusCode, message: message)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func fetchBuildings() async throws -> [VecyBuilding] {
        let decoded: VecyReviewsResponse = try await request(path: "resenas")
        return decoded.data.edificios
    }

    func fetchTotalCount() async throws -> Int {
        let decoded: VecyReviewCountResponse = try await request(path: "resenas/contador")
        return decoded.data.totalResenas
    }
}
