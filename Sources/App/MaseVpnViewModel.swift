import Combine
import Foundation

@MainActor
final class MaseVpnViewModel: ObservableObject {
    @Published var settings = AppSettings()
    @Published var servers: [ServerEntry] = ServerEntry.mocks
    @Published var vpnStatus = VpnStatusSnapshot()
    @Published var selectedTab: AppTab = .home

    private let iosVpnManager = IOSVpnManager()
    private let subscriptionRepository = SubscriptionRepository()
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

        guard !settings.subscriptionURL.isEmpty else {
            vpnStatus.lastError = "Введите ссылку подписки."
            vpnStatus.status = .error
            return
        }

        vpnStatus.isBusy = true
        vpnStatus.lastError = nil

        Task {
            defer { vpnStatus.isBusy = false }

            do {
                let fetched = try await subscriptionRepository.fetchServers(subscriptionURL: settings.subscriptionURL)
                servers = fetched

                if let currentId = settings.selectedServerId, fetched.contains(where: { $0.id == currentId }) {
                    settings.selectedServerId = currentId
                } else {
                    settings.selectedServerId = fetched.first?.id
                }

                if vpnStatus.status == .error {
                    vpnStatus.status = .disconnected
                }
                vpnStatus.lastError = nil
            } catch {
                vpnStatus.lastError = error.localizedDescription
                vpnStatus.status = .error
            }
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

        settings.selectedServerId = best?.id ?? servers.first?.id
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
            try? await installNativeProfileIfPossible(server: server)
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

    private func installNativeProfileIfPossible(server: ServerEntry) async throws {
        let profile = TunnelProfile(
            subscriptionURL: settings.subscriptionURL,
            selectedServerId: server.id,
            serverName: server.name
        )

        guard profile.isConfigured else { return }
        try await iosVpnManager.installProfile(profile)
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

enum AppTab: Hashable {
    case home
    case settings
}

private extension Bool {
    static func random(probability: Double) -> Bool {
        Double.random(in: 0...1) <= probability
    }
}
