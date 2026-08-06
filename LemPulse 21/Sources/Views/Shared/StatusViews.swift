import SwiftUI

/// Shown on Campaigns/Mailboxes tabs when no API key has been saved yet.
struct MissingAPIKeyView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Falta la API key", systemImage: "key.slash")
        } description: {
            Text("Añade tu API key de lemlist en la pestaña Ajustes para empezar.")
        }
    }
}

/// Generic error state with a retry action.
struct RetryableErrorView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No se pudo cargar", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Reintentar") { Task { await retry() } }
        }
    }
}
