import SwiftUI

@main
struct MaseVpnIOSApp: App {
    @StateObject private var viewModel = MaseVpnViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
