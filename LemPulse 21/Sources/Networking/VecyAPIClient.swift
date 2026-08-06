import Foundation

/// Talks to Vecy's own reviews API at api.vecy.es — completely separate
/// from lemlist. Only calls GET /resenas/contador, a lightweight
/// server-computed total, verified live via curl:
///   {"success":true,"data":{"total_resenas":165}}
/// Deliberately does NOT call GET /resenas (the full buildings + nested
/// reviews list) — that endpoint is heavier and isn't needed just to
/// track a running total.
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

    func fetchTotalCount() async throws -> Int {
        let decoded: VecyReviewCountResponse = try await request(path: "resenas/contador")
        return decoded.data.totalResenas
    }
}
