import Combine
import Foundation

@MainActor
final class MaseVpnViewModel: ObservableObject {
    @Published var settings = AppSettings()
    @Published var servers: [ServerEntry] = []
    @Published var vpnStatus = VpnStatusSnapshot()
    @Published var selectedTab: AppTab = .home
    @Published private(set) var isRefreshingSubscription = false
    @Published private(set) var isCheckingServers = false

    private let iosVpnManager = IOSVpnManager()
    private let subscriptionRepository = SubscriptionRepository()
    private var trafficTask: Task<Void, Never>?
    private var healthCheckTask: Task<Void, Never>?

    var selectedServer: ServerEntry? {
        servers.first { $0.id == settings.selectedServerId } ?? servers.first
    }

    var hasServers: Bool {
        !servers.isEmpty
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
        guard servers.contains(where: { $0.id == id }) else { return }

        settings.selectedServerId = id
    }

    func refreshSubscription() {
        settings.subscriptionURL = settings.subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !settings.subscriptionURL.isEmpty else {
            vpnStatus.lastError = "Введите ссылку подписки."
            vpnStatus.status = .error
            return
        }

        isRefreshingSubscription = true
        vpnStatus.lastError = nil

        Task {
            defer { isRefreshingSubscription = false }

            do {
                let fetched = try await subscriptionRepository.fetchServers(subscriptionURL: settings.subscriptionURL)
                let normalized = fetched.map(resetHealthState(for:))

                servers = normalized
                settings.selectedServerId = normalized.first?.id

                if vpnStatus.status == .error {
                    vpnStatus.status = .disconnected
                }

                vpnStatus.lastError = nil
                restartHealthCheckLoop()
                await performHealthChecks(showNoServersError: false)
            } catch {
                vpnStatus.lastError = error.localizedDescription
                vpnStatus.status = .error
            }
        }
    }

    func refreshPings() {
        Task {
            await performHealthChecks(showNoServersError: true)
        }
    }

    func pickBestServer() {
        guard !servers.isEmpty else { return }

        let best = bestAvailableServer(excluding: nil) ?? servers.first
        settings.selectedServerId = best?.id
    }

    func updateHealthCheckConfiguration() {
        settings.healthCheckInterval = sanitizedHealthCheckInterval(settings.healthCheckInterval)
        restartHealthCheckLoop()
    }

    func connect() {
        guard let server = selectedServer else {
            vpnStatus.status = .error
            vpnStatus.lastError = "Сначала загрузите подписку и выберите сервер."
            return
        }

        guard !server.isChecking else {
            vpnStatus.status = .error
            vpnStatus.lastError = "Дождитесь окончания проверки сервера."
            return
        }

        guard server.available else {
            vpnStatus.status = .error
            vpnStatus.lastError = server.lastError ?? "Выбранный сервер недоступен."
            return
        }

        vpnStatus.status = .connecting
        vpnStatus.isBusy = true
        vpnStatus.lastError = nil

        Task {
            do {
                try await installNativeProfileIfPossible(server: server)
            } catch {
                vpnStatus.status = .error
                vpnStatus.isBusy = false
                vpnStatus.lastError = error.localizedDescription
                return
            }

            try? await Task.sleep(nanoseconds: 900_000_000)

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
            try? await iosVpnManager.stop()
            try? await Task.sleep(nanoseconds: 500_000_000)

            trafficTask?.cancel()
            trafficTask = nil
            vpnStatus = VpnStatusSnapshot()
        }
    }

    private func performHealthChecks(showNoServersError: Bool) async {
        guard !servers.isEmpty else {
            if showNoServersError {
                vpnStatus.lastError = "Сначала загрузите подписку."
                if vpnStatus.status != .connected {
                    vpnStatus.status = .error
                }
            }
            return
        }

        guard !isCheckingServers else { return }

        isCheckingServers = true
        let snapshot = servers
        servers = snapshot.map { server in
            var updated = server
            updated.isChecking = true
            updated.pingMs = nil
            updated.lastError = nil
            updated.available = false
            return updated
        }

        let results = await ServerHealthChecker.measureAll(snapshot)
        let resultMap = Dictionary(uniqueKeysWithValues: results.map { ($0.serverId, $0) })

        servers = snapshot.map { server in
            var updated = server
            updated.isChecking = false

            if let result = resultMap[server.id] {
                updated.available = result.available
                updated.pingMs = result.pingMs
                updated.lastError = result.errorMessage
            }

            return updated
        }

        isCheckingServers = false

        if settings.autoSelectBest {
            pickBestServer()
        }

        handleActiveServerFailureIfNeeded()
    }

    private func handleActiveServerFailureIfNeeded() {
        guard
            settings.autoSwitchOnFailure,
            vpnStatus.status == .connected,
            let activeServerId = vpnStatus.activeServerId,
            let activeServer = servers.first(where: { $0.id == activeServerId }),
            !activeServer.available,
            let fallback = bestAvailableServer(excluding: activeServerId)
        else {
            return
        }

        settings.selectedServerId = fallback.id
        vpnStatus.activeServerId = fallback.id
        vpnStatus.activeServerName = fallback.name
        vpnStatus.lastError = "Активный сервер недоступен. Выбран \(fallback.name)."
    }

    private func bestAvailableServer(excluding excludedServerId: String?) -> ServerEntry? {
        servers
            .filter { server in
                server.available &&
                server.pingMs != nil &&
                (excludedServerId == nil || server.id != excludedServerId)
            }
            .min { ($0.pingMs ?? Int.max) < ($1.pingMs ?? Int.max) }
    }

    private func restartHealthCheckLoop() {
        stopHealthCheckLoop()

        guard settings.backgroundHealthChecksEnabled, !servers.isEmpty else {
            return
        }

        healthCheckTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                let seconds = self.currentHealthCheckInterval()
                try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)

                guard !Task.isCancelled else { break }
                await self.performHealthChecks(showNoServersError: false)
            }
        }
    }

    private func stopHealthCheckLoop() {
        healthCheckTask?.cancel()
        healthCheckTask = nil
    }

    private func currentHealthCheckInterval() -> Int {
        sanitizedHealthCheckInterval(settings.healthCheckInterval)
    }

    private func sanitizedHealthCheckInterval(_ value: Int) -> Int {
        min(max(value, 5), 300)
    }

    private func resetHealthState(for server: ServerEntry) -> ServerEntry {
        var updated = server
        updated.pingMs = nil
        updated.available = false
        updated.lastError = nil
        updated.isChecking = false
        return updated
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
        trafficTask?.cancel()
        trafficTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
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
