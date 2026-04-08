import SwiftUI

enum MasePalette {
    static let backgroundBase = Color(red: 0.02, green: 0.03, blue: 0.09)
    static let backgroundTop = Color(red: 0.04, green: 0.07, blue: 0.18)
    static let backgroundBottom = Color(red: 0.03, green: 0.09, blue: 0.20)

    static let glassBlue = Color(red: 0.39, green: 0.62, blue: 1.00)
    static let glassCyan = Color(red: 0.32, green: 0.88, blue: 1.00)
    static let glassMint = Color(red: 0.42, green: 0.96, blue: 0.78)
    static let glassWhite = Color.white.opacity(0.12)
    static let glassWhiteStrong = Color.white.opacity(0.26)
    static let glassStroke = Color.white.opacity(0.18)
    static let glassShadow = Color.black.opacity(0.34)

    static let textPrimary = Color.white.opacity(0.98)
    static let textSecondary = Color.white.opacity(0.72)
    static let textMuted = Color.white.opacity(0.46)

    static let blue = glassBlue
    static let cyan = glassCyan
    static let green = glassMint
    static let red = Color(red: 1.00, green: 0.43, blue: 0.53)
    static let amber = Color(red: 1.00, green: 0.78, blue: 0.44)
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 30
    var padding: CGFloat = 18
    let content: Content

    init(
        cornerRadius: CGFloat = 30,
        padding: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(.ultraThinMaterial))
        .background(
            shape.fill(
                LinearGradient(
                    colors: [
                        MasePalette.glassWhite.opacity(0.95),
                        MasePalette.glassBlue.opacity(0.18),
                        Color.black.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        )
        .overlay(
            shape.fill(
                LinearGradient(
                    colors: [
                        MasePalette.glassWhiteStrong,
                        Color.white.opacity(0.03),
                        MasePalette.glassBlue.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.screen)
        )
        .overlay(
            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        MasePalette.glassWhiteStrong,
                        MasePalette.glassStroke,
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .clipShape(shape)
        .shadow(color: MasePalette.glassShadow, radius: 28, x: 0, y: 20)
    }
}
