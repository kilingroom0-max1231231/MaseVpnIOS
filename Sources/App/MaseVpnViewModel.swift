import Combine
import Foundation

@MainActor
final class MaseVpnViewModel: ObservableObject {
    @Published var settings = AppSettings()
    @Published var servers: [ServerEntry] = ServerEntry.mocks
    @Published var vpnStatus = VpnStatusSnapshot()
    @Published var selectedTab: AppTab = .home

    private var timerTask: Task<Void, Never>?

    var selectedServer: ServerEntry? {
        servers.first { $0.id == settings.selectedServerId } ?? servers.first
    }

    init() {
        settings.selectedServerId = servers.first?.id
    }

    func toggleConnection() {
        switch vpnStatus.status {
        case .connected:
            disconnect()
        case .disconnected, .error:
            connect()
        default:
            break
        }
    }

    func selectServer(_ id: String) {
        settings.selectedServerId = id
        if vpnStatus.status == .connected {
            vpnStatus.activeServerId = id
            vpnStatus.activeServerName = servers.first(where: { $0.id == id })?.name
        }
    }

    func refreshSubscription() {
        settings.subscriptionURL = settings.subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if settings.subscriptionURL.isEmpty {
            vpnStatus.lastError = "Введите ссылку подписки."
            vpnStatus.status = .error
            return
        }

        vpnStatus.lastError = nil
        servers = ServerEntry.mocks.shuffled().map { server in
            var updated = server
            updated.pingMs = Int.random(in: 35...110)
            updated.available = Bool.random() ? true : server.available
            updated.lastError = updated.available ? nil : "Нет ответа"
            return updated
        }

        if settings.selectedServerId == nil {
            settings.selectedServerId = servers.first?.id
        }
    }

    func refreshPings() {
        servers = servers.map { server in
            var updated = server
            updated.available = Bool.random(probability: 0.8)
            updated.pingMs = updated.available ? Int.random(in: 28...140) : nil
            updated.lastError = updated.available ? nil : "Нет ответа"
            return updated
        }
    }

    func pickBestServer() {
        let best = servers
            .filter { $0.available && $0.pingMs != nil }
            .min { ($0.pingMs ?? Int.max) < ($1.pingMs ?? Int.max) }
        settings.selectedServerId = best?.id
    }

    func connect() {
        guard let server = selectedServer else {
            vpnStatus.status = .error
            vpnStatus.lastError = "Нет доступного сервера."
            return
        }

        vpnStatus.status = .connecting
        vpnStatus.isBusy = true
        vpnStatus.lastError = nil

        Task {
            try? await Task.sleep(for: .milliseconds(900))
            vpnStatus.status = .connected
            vpnStatus.isBusy = false
            vpnStatus.activeServerId = server.id
            vpnStatus.activeServerName = server.name
            vpnStatus.connectedSince = Date()
            startTrafficSimulation()
        }
    }

    func disconnect() {
        vpnStatus.status = .disconnecting
        vpnStatus.isBusy = true

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            timerTask?.cancel()
            timerTask = nil
            vpnStatus = VpnStatusSnapshot()
        }
    }

    private func startTrafficSimulation() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard self.vpnStatus.status == .connected else { continue }

                self.vpnStatus.traffic.uplinkBytes += Int64.random(in: 18_000...70_000)
                self.vpnStatus.traffic.downlinkBytes += Int64.random(in: 45_000...210_000)
                self.vpnStatus.traffic.uplinkRateBytesPerSec = Double.random(in: 18_000...70_000)
                self.vpnStatus.traffic.downlinkRateBytesPerSec = Double.random(in: 45_000...210_000)
            }
        }
    }
}

enum AppTab {
    case home
    case settings
}

private extension Bool {
    static func random(probability: Double) -> Bool {
        Double.random(in: 0...1) <= probability
    }
}
