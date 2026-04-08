import Foundation
import Network

struct ServerHealthResult: Sendable {
    let serverId: String
    let pingMs: Int?
    let available: Bool
    let errorMessage: String?
}

enum ServerHealthChecker {
    static func measureAll(_ servers: [ServerEntry], timeout: TimeInterval = 3) async -> [ServerHealthResult] {
        await withTaskGroup(of: ServerHealthResult.self, returning: [ServerHealthResult].self) { group in
            for server in servers {
                group.addTask {
                    await measure(server, timeout: timeout)
                }
            }

            var results: [ServerHealthResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    static func measure(_ server: ServerEntry, timeout: TimeInterval = 3) async -> ServerHealthResult {
        guard !server.host.isEmpty else {
            return ServerHealthResult(
                serverId: server.id,
                pingMs: nil,
                available: false,
                errorMessage: "Пустой host"
            )
        }

        guard server.port > 0, let port = NWEndpoint.Port(rawValue: UInt16(server.port)) else {
            return ServerHealthResult(
                serverId: server.id,
                pingMs: nil,
                available: false,
                errorMessage: "Неверный порт"
            )
        }

        return await withCheckedContinuation { (continuation: CheckedContinuation<ServerHealthResult, Never>) in
            let queue = DispatchQueue(label: "online.maseai.vpnclient.health.\(server.id)")
            let connection = NWConnection(host: NWEndpoint.Host(server.host), port: port, using: .tcp)
            let start = DispatchTime.now().uptimeNanoseconds
            var finished = false

            func finish(_ result: ServerHealthResult) {
                guard !finished else { return }
                finished = true
                connection.stateUpdateHandler = nil
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = DispatchTime.now().uptimeNanoseconds - start
                    let latencyMs = max(1, Int(Double(elapsed) / 1_000_000))
                    finish(
                        ServerHealthResult(
                            serverId: server.id,
                            pingMs: latencyMs,
                            available: true,
                            errorMessage: nil
                        )
                    )

                case .waiting(let error):
                    finish(
                        ServerHealthResult(
                            serverId: server.id,
                            pingMs: nil,
                            available: false,
                            errorMessage: message(for: error)
                        )
                    )

                case .failed(let error):
                    finish(
                        ServerHealthResult(
                            serverId: server.id,
                            pingMs: nil,
                            available: false,
                            errorMessage: message(for: error)
                        )
                    )

                default:
                    break
                }
            }

            queue.asyncAfter(deadline: .now() + timeout) {
                finish(
                    ServerHealthResult(
                        serverId: server.id,
                        pingMs: nil,
                        available: false,
                        errorMessage: "Таймаут"
                    )
                )
            }

            connection.start(queue: queue)
        }
    }

    private static func message(for error: NWError) -> String {
        switch error {
        case .posix(let code):
            switch code {
            case .ECONNREFUSED: return "Соединение отклонено"
            case .ETIMEDOUT: return "Таймаут"
            case .ENETUNREACH, .EHOSTUNREACH: return "Сервер недоступен"
            default: return "Ошибка сети"
            }

        case .dns(_):
            return "DNS ошибка"

        case .tls(_):
            return "TLS ошибка"

        @unknown default:
            return "Ошибка сети"
        }
    }
}
