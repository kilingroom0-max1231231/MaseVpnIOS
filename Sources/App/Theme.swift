import SwiftUI

enum MasePalette {
    static let backgroundBase = Color(red: 0.03, green: 0.03, blue: 0.05)
    static let backgroundTop = Color(red: 0.06, green: 0.06, blue: 0.09)
    static let backgroundBottom = Color(red: 0.05, green: 0.05, blue: 0.08)

    static let blue = Color(red: 0.42, green: 0.67, blue: 1.00)
    static let cyan = Color(red: 0.45, green: 0.91, blue: 1.00)
    static let green = Color(red: 0.42, green: 0.94, blue: 0.76)
    static let red = Color(red: 1.00, green: 0.43, blue: 0.53)
    static let amber = Color(red: 1.00, green: 0.78, blue: 0.44)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.82)
    static let textMuted = Color.white.opacity(0.64)
    static let shadow = Color.black.opacity(0.24)
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 30
    var padding: CGFloat = 18
    var interactive: Bool = false
    let content: Content

    init(
        cornerRadius: CGFloat = 30,
        padding: CGFloat = 18,
        interactive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.interactive = interactive
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(interactive ? 0.045 : 0.03))
        )
        .glassEffect(
            interactive ? .regular.interactive() : .regular,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(interactive ? 0.18 : 0.10), lineWidth: 1)
        }
        .shadow(color: MasePalette.shadow, radius: 18, y: 8)
    }
}
