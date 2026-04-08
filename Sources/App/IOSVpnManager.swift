import Combine
import Foundation
import NetworkExtension

@MainActor
final class IOSVpnManager: ObservableObject {
    static let tunnelBundleIdentifier = "online.maseai.vpnclient.ios.tunnel"
    private let managerDescription = "MaseVpn"

    func installProfile(_ profile: TunnelProfile) async throws {
        guard profile.isConfigured else {
            throw TunnelBootstrapError.missingConfiguration
        }

        let manager = try await loadOrCreateManager()
        let configuration = NETunnelProviderProtocol()
        configuration.providerBundleIdentifier = Self.tunnelBundleIdentifier
        configuration.serverAddress = profile.serverName ?? "MaseVpn"
        configuration.providerConfiguration = [
            "subscriptionURL": profile.subscriptionURL,
            "selectedServerId": profile.selectedServerId ?? "",
            "serverName": profile.serverName ?? ""
        ]

        manager.protocolConfiguration = configuration
        manager.localizedDescription = managerDescription
        manager.isEnabled = true

        try await save(manager)
        try await load(manager)
    }

    func start(profile: TunnelProfile) async throws {
        try await installProfile(profile)
        let manager = try await loadOrCreateManager()
        try manager.connection.startVPNTunnel()
    }

    func stop() async throws {
        let manager = try await loadOrCreateManager()
        manager.connection.stopVPNTunnel()
    }

    private func loadOrCreateManager() async throws -> NETunnelProviderManager {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        if let existing = managers.first(where: { $0.localizedDescription == managerDescription }) {
            return existing
        }
        return NETunnelProviderManager()
    }

    private func save(_ manager: NETunnelProviderManager) async throws {
        let _: Void = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            manager.saveToPreferences { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func load(_ manager: NETunnelProviderManager) async throws {
        let _: Void = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            manager.loadFromPreferences { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

private extension NETunnelProviderManager {
    static func loadAllFromPreferences() async throws -> [NETunnelProviderManager] {
        let managers: [NETunnelProviderManager] = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[NETunnelProviderManager], Error>) in
            loadAllFromPreferences { managers, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: managers ?? [])
                }
            }
        }
        return managers
    }
}
