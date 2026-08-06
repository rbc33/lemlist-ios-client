import Foundation

enum APIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case server(status: Int, message: String)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Añade tu API key de lemlist en Ajustes."
        case .invalidURL:
            return "URL inválida."
        case .server(let status, let message):
            return statusMessage(status: status, raw: message)
        case .decoding:
            return "No se pudo interpretar la respuesta del servidor."
        case .transport(let error):
            return error.localizedDescription
        }
    }

    private func statusMessage(status: Int, raw: String) -> String {
        switch status {
        case 400:
            return "Petición incorrecta (\(raw.isEmpty ? "400" : raw))."
        case 401:
            return "La API key no es válida."
        case 403:
            return "El usuario asociado a esta API key está bloqueado."
        case 404:
            return "No se encontró el recurso solicitado."
        default:
            return "Error \(status)\(raw.isEmpty ? "" : ": \(raw)")"
        }
    }
}
