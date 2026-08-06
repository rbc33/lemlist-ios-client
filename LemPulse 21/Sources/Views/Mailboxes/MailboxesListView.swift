import SwiftUI

struct MailboxesListView: View {
    @Environment(AppSettings.self) private var settings

    @State private var mailboxes: [MailboxWithOwner] = []
    @State private var scores: [String: Int] = [:] // mailboxId -> deliverability score
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Correos")
                .navigationDestination(for: MailboxWithOwner.self) { MailboxDetailView(item: $0) }
                .task { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !settings.hasAPIKey {
            MissingAPIKeyView()
        } else if isLoading && mailboxes.isEmpty {
            ProgressView("Cargando mailboxes…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            RetryableErrorView(message: errorMessage) { await load() }
        } else if mailboxes.isEmpty {
            ContentUnavailableView("Sin mailboxes", systemImage: "envelope", description: Text("No se encontraron mailboxes conectados en tu equipo."))
        } else {
            List(mailboxes) { item in
                NavigationLink(value: item) {
                    MailboxRowView(item: item, warmupScore: scores[item.mailbox.id])
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
            let boxes = try await LemlistAPIClient.shared.fetchAllMailboxes()
            mailboxes = boxes
            await loadScores(for: boxes)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func loadScores(for boxes: [MailboxWithOwner]) async {
        let warmingUp = boxes.filter { $0.mailbox.warmupActive }
        guard !warmingUp.isEmpty else { return }

        await withTaskGroup(of: (String, Int?).self) { group in
            for box in warmingUp {
                group.addTask {
                    let settings = try? await LemlistAPIClient.shared.fetchLemwarmSettings(mailboxId: box.mailbox.id)
                    return (box.mailbox.id, settings?.score)
                }
            }
            for await (id, score) in group {
                if let score { scores[id] = score }
            }
        }
    }
}
