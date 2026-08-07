import SwiftUI

struct InboxThreadView: View {
    let reply: InboxReplyActivity

    @State private var messages: [InboxMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var draft = ""
    @State private var isSending = false
    @State private var sendError: String?

    var body: some View {
        VStack(spacing: 0) {
            content
            Divider()
            composeBar
        }
        .navigationTitle(reply.leadDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("No se pudo enviar", isPresented: sendErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sendError ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && messages.isEmpty {
            ProgressView("Cargando conversación…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage, messages.isEmpty {
            RetryableErrorView(message: errorMessage) { await load() }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(sortedMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = sortedMessages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onAppear {
                    if let last = sortedMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var sortedMessages: [InboxMessage] {
        messages.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    private var composeBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Escribe una respuesta…", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
            Button {
                Task { await send() }
            } label: {
                if isSending {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding()
    }

    private var sendErrorBinding: Binding<Bool> {
        Binding(get: { sendError != nil }, set: { if !$0 { sendError = nil } })
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            // Prioriza quién está usando la app ahora mismo (elegido en Ajustes);
            // si no se ha elegido nadie, usa el remitente original de la
            // campaña como aproximación razonable.
            let userId = CurrentUserStore.userId ?? reply.sendUserId
            messages = try await LemlistAPIClient.shared.fetchThread(contactId: reply.contactId, userId: userId)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func send() async {
        guard let sendUserId = latestSendUserId,
              let sendUserEmail = latestSendUserEmail,
              let sendUserMailboxId = latestSendUserMailboxId else {
            sendError = "No se encontró el remitente de este hilo."
            return
        }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        do {
            let html = "<p>" + text.replacingOccurrences(of: "\n", with: "<br>") + "</p>"
            try await LemlistAPIClient.shared.sendReply(
                contactId: reply.contactId,
                sendUserId: sendUserId,
                sendUserEmail: sendUserEmail,
                sendUserMailboxId: sendUserMailboxId,
                message: html
            )
            draft = ""
            await load()
        } catch {
            sendError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isSending = false
    }

    /// Sender identity to reply as: prefer the most recent outgoing message
    /// already in the thread, falling back to what the replies list gave us.
    private var latestSendUserId: String? {
        sortedMessages.last(where: { !$0.isFromLead })?.sendUserId ?? reply.sendUserId
    }
    private var latestSendUserEmail: String? {
        sortedMessages.last(where: { !$0.isFromLead })?.sendUserEmail ?? reply.sendUserEmail
    }
    private var latestSendUserMailboxId: String? {
        sortedMessages.last(where: { !$0.isFromLead })?.sendUserMailboxId ?? reply.sendUserMailboxId
    }
}

private struct MessageBubble: View {
    let message: InboxMessage

    var body: some View {
        VStack(alignment: message.isFromLead ? .leading : .trailing, spacing: 4) {
            Text(HTMLPlainText.convert(message.message ?? ""))
                .padding(10)
                .background(message.isFromLead ? Color(.secondarySystemBackground) : Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let date = message.createdAt {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isFromLead ? .leading : .trailing)
    }
}
