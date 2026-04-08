import Foundation

struct TunnelProfile: Codable, Equatable {
    var subscriptionURL: String
    var selectedServerId: String?
    var serverName: String?

    var isConfigured: Bool {
        !subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum TunnelMessageKind: String, Codable {
    case profile
    case status
}

struct TunnelMessageEnvelope: Codable {
    var kind: TunnelMessageKind
    var payload: Data?
}

enum TunnelBootstrapError: LocalizedError {
    case missingConfiguration
    case coreNotInstalled

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Профиль VPN не настроен."
        case .coreNotInstalled:
            return "Packet Tunnel создан, но Xray/tun2socks ещё не подключены."
        }
    }
}
