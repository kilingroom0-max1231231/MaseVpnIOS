import SwiftUI

enum MasePalette {
    static let backgroundTop = Color(red: 0.02, green: 0.03, blue: 0.09)
    static let backgroundBottom = Color(red: 0.06, green: 0.10, blue: 0.19)
    static let panel = Color(red: 0.08, green: 0.12, blue: 0.21)
    static let panelSoft = Color(red: 0.11, green: 0.16, blue: 0.27)
    static let panelStroke = Color(red: 0.18, green: 0.24, blue: 0.38)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.58, green: 0.64, blue: 0.78)
    static let textMuted = Color(red: 0.42, green: 0.48, blue: 0.62)
    static let cyan = Color(red: 0.27, green: 0.88, blue: 1.00)
    static let blue = Color(red: 0.47, green: 0.66, blue: 1.00)
    static let green = Color(red: 0.31, green: 0.94, blue: 0.71)
    static let red = Color(red: 1.00, green: 0.42, blue: 0.49)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.38)
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [MasePalette.panel.opacity(0.96), MasePalette.panelSoft.opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(MasePalette.panelStroke.opacity(0.92), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
