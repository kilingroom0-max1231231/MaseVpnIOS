import BackgroundTasks
import Foundation

enum BackgroundRefreshManager {
    static let healthRefreshIdentifier = "online.maseai.vpnclient.ios.health-refresh"

    static func scheduleHealthRefresh(after interval: TimeInterval) {
        cancelHealthRefresh()

        let request = BGAppRefreshTaskRequest(identifier: healthRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: max(15 * 60, interval))

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("Failed to schedule background refresh: \(error)")
            #endif
        }
    }

    static func cancelHealthRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: healthRefreshIdentifier)
    }
}
