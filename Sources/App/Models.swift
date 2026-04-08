import Foundation

enum ConnectionStatus: String, Codable {
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

struct ServerEntry: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var host: String
    var port: Int
    var pingMs: Int?
    var available: Bool
    var lastError: String?

    var endpointLabel: String { "\(host):\(port)" }
    var pingLabel: String { pingMs.map { "\($0) ms" } ?? "—" }
    var statusLabel: String {
        if available { return "Доступен" }
        if let lastError, !lastError.isEmpty { return "Ошибка: \(lastError)" }
        return "Не проверен"
    }

    static let mocks: [ServerEntry] = [
        .init(id: "1", name: "Singapore 01", host: "sg-01.mase.ai", port: 443, pingMs: 42, available: true, lastError: nil),
        .init(id: "2", name: "Germany 02", host: "de-02.mase.ai", port: 443, pingMs: 67, available: true, lastError: nil),
        .init(id: "3", name: "Netherlands 01", host: "nl-01.mase.ai", port: 8443, pingMs: 95, available: false, lastError: "Нет ответа"),
    ]
}

struct TrafficStats: Codable, Equatable {
    var downlinkBytes: Int64 = 0
    var uplinkBytes: Int64 = 0
    var downlinkRateBytesPerSec: Double = 0
    var uplinkRateBytesPerSec: Double = 0

    var uploadLabel: String { ByteFormatter.string(from: uplinkBytes) }
    var downloadLabel: String { ByteFormatter.string(from: downlinkBytes) }
    var uploadRateLabel: String { "\(ByteFormatter.string(from: Int64(uplinkRateBytesPerSec)))/с" }
    var downloadRateLabel: String { "\(ByteFormatter.string(from: Int64(downlinkRateBytesPerSec)))/с" }
}

struct VpnStatusSnapshot: Equatable {
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

struct AppSettings: Codable, Equatable {
    var subscriptionURL: String = ""
    var selectedServerId: String?
    var autoSelectBest: Bool = true
    var autoSwitchOnFailure: Bool = true
    var healthCheckInterval: Int = 15
}

enum ByteFormatter {
    static func string(from bytes: Int64) -> String {
        let value = Double(max(0, bytes))
        let units = ["B", "KB", "MB", "GB", "TB"]
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
