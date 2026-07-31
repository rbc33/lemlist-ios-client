import Foundation

/// Talks to https://api.lemlist.com/api using HTTP Basic Auth (empty username,
/// API key as password), per https://developer.lemlist.com/api-reference/getting-started/authentication
/// Modeled as an actor since the API key is mutable state read by many
/// concurrent tasks (e.g. fetching every mailbox in parallel).
actor LemlistAPIClient {
    static let shared = LemlistAPIClient()

    private let baseURL = URL(string: "https://api.lemlist.com/api")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private(set) var apiKey: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: string) { return date }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Fecha ISO8601 inválida: \(string)")
        }
        self.decoder = decoder
        self.encoder = JSONEncoder()
        self.apiKey = KeychainStore.loadAPIKey()
    }

    func setAPIKey(_ key: String?) {
        apiKey = key
        if let key, !key.isEmpty {
            KeychainStore.save(apiKey: key)
        } else {
            KeychainStore.delete()
        }
    }

    // MARK: - Low level request

    private func authHeader() throws -> String {
        guard let apiKey, !apiKey.isEmpty else { throw APIError.missingAPIKey }
        let raw = ":\(apiKey)"
        return "Basic " + Data(raw.utf8).base64EncodedString()
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> T {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(try authHeader(), forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

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

    // MARK: - Campaigns

    /// GET /campaigns — the `version=v2` query param is required per lemlist's docs.
    /// Note: despite the docs showing a bare array as the response, the API
    /// actually returns `{ "campaigns": [...], "pagination": {...} }` —
    /// verified against a live response.
    func fetchCampaigns(status: CampaignStatus? = nil) async throws -> [Campaign] {
        var allCampaigns: [Campaign] = []
        var page = 1
        while true {
            var query = [
                URLQueryItem(name: "version", value: "v2"),
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "page", value: String(page))
            ]
            if let status { query.append(URLQueryItem(name: "status", value: status.rawValue)) }

            let response: CampaignsListResponse = try await request(path: "campaigns", query: query)
            allCampaigns.append(contentsOf: response.campaigns.compactMap(\.base))

            guard let totalPage = response.pagination?.totalPage, page < totalPage, page < 20 else { break }
            page += 1
        }
        return allCampaigns
    }

    func pauseCampaign(id: String) async throws {
        let _: CampaignStateResponse = try await request(path: "campaigns/\(id)/pause", method: "POST")
    }

    func startCampaign(id: String) async throws {
        let _: CampaignStateResponse = try await request(path: "campaigns/\(id)/start", method: "POST")
    }

    /// GET /v2/campaigns/{id}/stats — note this one lives under a /v2 path prefix, not a query param.
    func fetchCampaignStats(id: String, startDate: Date, endDate: Date) async throws -> CampaignStats {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let query = [
            URLQueryItem(name: "startDate", value: formatter.string(from: startDate)),
            URLQueryItem(name: "endDate", value: formatter.string(from: endDate))
        ]
        return try await request(path: "v2/campaigns/\(id)/stats", query: query)
    }

    // MARK: - Team & mailboxes

    func fetchTeam() async throws -> TeamInfo {
        try await request(path: "team", query: [URLQueryItem(name: "version", value: "v2")])
    }

    func fetchUser(id: String) async throws -> LemlistUser {
        try await request(path: "users/\(id)")
    }

    /// Flattens every mailbox across every team member into one list, since
    /// the API only exposes mailboxes nested under a user.
    func fetchAllMailboxes() async throws -> [MailboxWithOwner] {
        let team = try await fetchTeam()
        let members = team.users ?? []

        var result: [MailboxWithOwner] = []
        try await withThrowingTaskGroup(of: [MailboxWithOwner].self) { group in
            for member in members {
                group.addTask {
                    let user = try await self.fetchUser(id: member.userId)
                    let mailboxes = user.mailboxes ?? []
                    return mailboxes.map {
                        MailboxWithOwner(mailbox: $0, ownerUserId: member.userId, ownerName: member.displayName)
                    }
                }
            }
            for try await batch in group {
                result.append(contentsOf: batch)
            }
        }
        return result.sorted { $0.mailbox.email.localizedCaseInsensitiveCompare($1.mailbox.email) == .orderedAscending }
    }

    // MARK: - Lemwarm

    func fetchLemwarmSettings(mailboxId: String) async throws -> LemwarmSettings {
        try await request(path: "lemwarm/\(mailboxId)/settings")
    }

    /// PATCH /lemwarm/{mailboxId}/settings — only warmEmailMax and warmEmailRampup
    /// are writable per lemlist's docs. This does NOT touch the mailbox's
    /// campaign sending limit (mailbox.lemlist.emailLimit), which has no
    /// write endpoint in the public API.
    func updateLemwarmSettings(mailboxId: String, warmEmailMax: Int, warmEmailRampup: Int) async throws {
        let body = try encoder.encode(LemwarmUpdateBody(warmEmailMax: warmEmailMax, warmEmailRampup: warmEmailRampup))
        let _: OKResponse = try await request(path: "lemwarm/\(mailboxId)/settings", method: "PATCH", body: body)
    }

    func pauseLemwarm(mailboxId: String) async throws {
        let _: OKResponse = try await request(path: "lemwarm/\(mailboxId)/pause", method: "POST")
    }

    func startLemwarm(mailboxId: String) async throws {
        let _: OKResponse = try await request(path: "lemwarm/\(mailboxId)/start", method: "POST")
    }

    // MARK: - Connection test

    @discardableResult
    func testConnection() async throws -> TeamInfo {
        try await fetchTeam()
    }
}
