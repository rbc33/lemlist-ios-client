import SwiftUI

struct InboxRepliesListView: View {
    @Environment(AppSettings.self) private var settings

    @State private var replies: [InboxReplyActivity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bandeja")
                .navigationDestination(for: InboxReplyActivity.self) { InboxThreadView(reply: $0) }
                .task { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !settings.hasAPIKey {
            MissingAPIKeyView()
        } else if isLoading && replies.isEmpty {
            ProgressView("Cargando respuestas…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            RetryableErrorView(message: errorMessage) { await load() }
        } else if replies.isEmpty {
            ContentUnavailableView("Sin respuestas", systemImage: "tray", description: Text("Todavía no hay leads que hayan respondido."))
        } else {
            List(replies) { reply in
                NavigationLink(value: reply) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(reply.leadDisplayName)
                                .font(.body.weight(.medium))
                                .lineLimit(1)
                            Spacer()
                            if let date = reply.createdAt {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let campaign = reply.campaignName {
                            Text(campaign)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        if let preview = reply.messagePreview, !preview.isEmpty {
                            Text(preview)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .refreshable { await load() }
        }
    }

    private func load() async {
        guard settings.hasAPIKey else { return }
        isLoading = true
        errorMessage = nil
        do {
            replies = try await LemlistAPIClient.shared.fetchRecentReplies()
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
