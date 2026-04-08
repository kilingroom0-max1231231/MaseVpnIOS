import CryptoKit
import Foundation

struct SubscriptionException: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

final class SubscriptionRepository {
    private let session: URLSession
    private let parser: SubscriptionParser

    init(
        session: URLSession = .shared,
        parser: SubscriptionParser = SubscriptionParser()
    ) {
        self.session = session
        self.parser = parser
    }

    func fetchServers(subscriptionURL: String) async throws -> [ServerEntry] {
        try validateURL(subscriptionURL)

        guard let url = URL(string: subscriptionURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw SubscriptionException(message: "Введите корректный URL подписки.")
        }

        var request = URLRequest(url: url)
        request.setValue("MaseVpnIOS/1.0 (+https://sub.maseai.online)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionException(message: "Сервер подписки вернул некорректный ответ.")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SubscriptionException(message: "Не удалось скачать подписку: HTTP \(httpResponse.statusCode)")
        }

        guard let payload = String(data: data, encoding: .utf8), !payload.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SubscriptionException(message: "Пустой ответ от сервера подписки.")
        }

        return try parser.parseSubscriptionPayload(payload)
    }

    func validateURL(_ value: String) throws {
        guard
            let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http"
        else {
            throw SubscriptionException(message: "Введите корректный URL подписки формата https://domain/sub/user.")
        }
    }
}

struct SubscriptionParser {
    func parseSubscriptionPayload(_ payload: String) throws -> [ServerEntry] {
        let text = decodePayload(payload)
        var servers: [ServerEntry] = []
        var errors: [String] = []

        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { $0.lowercased().hasPrefix("vless://") }
            .forEach { line in
                do {
                    servers.append(try parseVlessURI(line))
                } catch {
                    errors.append(error.localizedDescription)
                }
            }

        if !servers.isEmpty {
            return servers
        }
        if !errors.isEmpty {
            throw SubscriptionException(message: errors.prefix(3).joined(separator: "; "))
        }
        throw SubscriptionException(message: "В подписке не найдено ни одного VLESS-сервера.")
    }

    func parseVlessURI(_ uri: String) throws -> ServerEntry {
        guard let components = URLComponents(string: uri) else {
            throw SubscriptionException(message: "Не удалось разобрать VLESS-ссылку.")
        }
        guard components.scheme?.lowercased() == "vless" else {
            throw SubscriptionException(message: "Поддерживаются только ссылки vless://")
        }

        let host = components.host ?? ""
        let port = components.port ?? 0
        let uuid = components.user?.removingPercentEncoding ?? components.user ?? ""

        guard !host.isEmpty else {
            throw SubscriptionException(message: "VLESS-ссылка не содержит host.")
        }
        guard port > 0 else {
            throw SubscriptionException(message: "VLESS-ссылка не содержит port.")
        }
        guard !uuid.isEmpty else {
            throw SubscriptionException(message: "VLESS-ссылка не содержит uuid.")
        }

        let query = parseQuery(components.percentEncodedQuery ?? "")
        let decodedFragment = components.fragment?.removingPercentEncoding ?? components.fragment ?? ""
        let name = decodedFragment.isEmpty ? "\(host):\(port)" : decodedFragment

        return ServerEntry(
            id: String(sha1(uri).prefix(16)),
            name: name,
            host: host,
            port: port,
            uuid: uuid,
            network: first(query, keys: ["type", "network"], defaultValue: "tcp").lowercased(),
            security: first(query, keys: ["security"], defaultValue: "none").lowercased(),
            flow: first(query, keys: ["flow"]),
            sni: first(query, keys: ["sni", "serverName"]),
            fingerprint: first(query, keys: ["fp", "fingerprint"], defaultValue: "chrome"),
            publicKey: first(query, keys: ["pbk", "publicKey"]),
            shortId: first(query, keys: ["sid", "shortId"]),
            spiderX: decodeValue(first(query, keys: ["spx"], defaultValue: "/").ifEmpty("/")),
            path: decodeValue(first(query, keys: ["path"], defaultValue: "/").ifEmpty("/")),
            hostHeader: first(query, keys: ["host"]),
            serviceName: first(query, keys: ["serviceName"]),
            alpn: first(query, keys: ["alpn"]).split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            rawURL: uri,
            pingMs: nil,
            available: false,
            lastError: nil
        )
    }

    private func decodePayload(_ payload: String) -> String {
        let candidate = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        if candidate.lowercased().contains("vless://") {
            return candidate
        }

        let normalized = candidate.filter { !$0.isWhitespace }
        let padding = (4 - normalized.count % 4) % 4
        let padded = normalized + String(repeating: "=", count: padding)

        if
            let data = Data(base64Encoded: padded, options: [.ignoreUnknownCharacters]),
            let decoded = String(data: data, encoding: .utf8),
            decoded.lowercased().contains("vless://")
        {
            return decoded
        }

        return candidate
    }

    private func parseQuery(_ rawQuery: String) -> [String: [String]] {
        guard !rawQuery.isEmpty else { return [:] }

        return rawQuery
            .split(separator: "&")
            .map(String.init)
            .filter { !$0.isEmpty }
            .reduce(into: [String: [String]]()) { result, item in
                let key = String(item.split(separator: "=", maxSplits: 1).first ?? "")
                let value = item.contains("=") ? String(item.split(separator: "=", maxSplits: 1)[1]) : ""
                result[key, default: []].append(decodeValue(value))
            }
    }

    private func first(_ query: [String: [String]], keys: [String], defaultValue: String = "") -> String {
        for key in keys {
            if let value = query[key]?.first, !value.isEmpty {
                return value
            }
        }
        return defaultValue
    }

    private func decodeValue(_ value: String) -> String {
        value.removingPercentEncoding ?? value
    }

    private func sha1(_ value: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
