import Foundation

enum ConnectionStatus: String, Codable, Sendable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error

    var title: String {
        switch self {
        case .disconnected: return "Отключено"
        case .connecting: return "Подключение"
        case .connected: return "Подключено"
        case .disconnecting: return "Отключение"
        case .error: return "Ошибка"
        }
    }
}

struct ServerEntry: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var host: String
    var port: Int
    var uuid: String = ""
    var network: String = "tcp"
    var security: String = "none"
    var flow: String = ""
    var sni: String = ""
    var fingerprint: String = "chrome"
    var publicKey: String = ""
    var shortId: String = ""
    var spiderX: String = "/"
    var path: String = "/"
    var hostHeader: String = ""
    var serviceName: String = ""
    var alpn: [String] = []
    var rawURL: String = ""
    var pingMs: Int?
    var available: Bool
    var lastError: String?
    var isChecking: Bool = false

    var endpointLabel: String { "\(host):\(port)" }

    var pingLabel: String {
        if isChecking {
            return "Проверка..."
        }
        return pingMs.map { "\($0) мс" } ?? "—"
    }

    var statusLabel: String {
        if isChecking {
            return "Проверяется..."
        }
        if available {
            return "Доступен"
        }
        if let lastError, !lastError.isEmpty {
            return "Ошибка: \(lastError)"
        }
        return "Не проверен"
    }
}

struct TrafficStats: Codable, Equatable, Sendable {
    var downlinkBytes: Int64 = 0
    var uplinkBytes: Int64 = 0
    var downlinkRateBytesPerSec: Double = 0
    var uplinkRateBytesPerSec: Double = 0

    var uploadLabel: String { ByteFormatter.string(from: uplinkBytes) }
    var downloadLabel: String { ByteFormatter.string(from: downlinkBytes) }
    var uploadRateLabel: String { "\(ByteFormatter.string(from: Int64(uplinkRateBytesPerSec)))/с" }
    var downloadRateLabel: String { "\(ByteFormatter.string(from: Int64(downlinkRateBytesPerSec)))/с" }
}

struct VpnStatusSnapshot: Equatable, Sendable {
    var status: ConnectionStatus = .disconnected
    var activeServerId: String?
    var activeServerName: String?
    var lastError: String?
    var traffic: TrafficStats = .init()
    var connectedSince: Date?
    var isBusy: Bool = false

    var durationLabel: String {
        guard let connectedSince else { return "00:00:00" }
        return DurationFormatter.string(from: connectedSince, to: Date())
    }
}

struct AppSettings: Codable, Equatable, Sendable {
    var subscriptionURL: String = ""
    var selectedServerId: String?
    var autoSelectBest: Bool = true
    var autoSwitchOnFailure: Bool = true
    var backgroundHealthChecksEnabled: Bool = true
    var healthCheckInterval: Int = 15
}

enum ByteFormatter {
    static func string(from bytes: Int64) -> String {
        let value = Double(max(0, bytes))
        let units = ["Б", "КБ", "МБ", "ГБ", "ТБ"]
        var amount = value
        var index = 0

        while amount >= 1024, index < units.count - 1 {
            amount /= 1024
            index += 1
        }

        if index == 0 {
            return "\(Int(amount)) \(units[index])"
        }

        return String(format: "%.1f %@", amount, units[index])
    }
}

enum DurationFormatter {
    static func string(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainder)
    }
}
