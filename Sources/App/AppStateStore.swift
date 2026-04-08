import Foundation

enum AppStateStore {
    private static let defaults = UserDefaults.standard
    private static let settingsKey = "online.maseai.vpnclient.ios.settings"
    private static let serversKey = "online.maseai.vpnclient.ios.servers"

    static func loadSettings() -> AppSettings {
        decode(AppSettings.self, forKey: settingsKey) ?? AppSettings()
    }

    static func saveSettings(_ settings: AppSettings) {
        encode(settings, forKey: settingsKey)
    }

    static func loadServers() -> [ServerEntry] {
        decode([ServerEntry].self, forKey: serversKey) ?? []
    }

    static func saveServers(_ servers: [ServerEntry]) {
        encode(servers, forKey: serversKey)
    }

    private static func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
