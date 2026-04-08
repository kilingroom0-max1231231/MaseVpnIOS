import SwiftUI

@main
struct MaseVpnIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = MaseVpnViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                viewModel.sceneDidBecomeActive()
            case .background:
                viewModel.sceneDidEnterBackground()
            default:
                break
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefreshManager.healthRefreshIdentifier)) {
            await viewModel.handleBackgroundRefresh()
        }
    }
}
