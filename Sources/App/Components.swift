import SwiftUI

struct TopHeader: View {
    let title: String
    let subtitle: String
    let status: ConnectionStatus

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(MasePalette.textPrimary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MasePalette.textSecondary)
            }

            Spacer()

            StatusBadge(status: status)
        }
    }
}

struct StatusBadge: View {
    let status: ConnectionStatus

    private var tint: Color {
        switch status {
        case .connected: return MasePalette.green
        case .connecting, .disconnecting: return MasePalette.cyan
        case .error: return MasePalette.red
        case .disconnected: return MasePalette.textSecondary
        }
    }

    var body: some View {
        Text(status.title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(MasePalette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.22))
            )
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.42), lineWidth: 1)
            }
    }
}

struct OverviewTile: View {
    let label: String
    let value: String

    var body: some View {
        GlassCard(cornerRadius: 24, padding: 16) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(MasePalette.textMuted)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(MasePalette.textPrimary)
        }
    }
}

struct ServerCard: View {
    let server: ServerEntry
    let selected: Bool
    let active: Bool
    let action: () -> Void

    private var accent: Color {
        if active { return MasePalette.green }
        if server.isChecking { return MasePalette.amber }
        if server.available { return MasePalette.cyan }
        if server.lastError != nil { return MasePalette.red }
        return MasePalette.amber
    }

    private var badgeTitle: String? {
        if active { return "Активен" }
        if selected { return "Выбран" }
        return nil
    }

    var body: some View {
        Button(action: action) {
            GlassCard(cornerRadius: 30, padding: 18, interactive: true) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(server.name)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                            .lineLimit(2)

                        Text(server.endpointLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MasePalette.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer(minLength: 10)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(accent)
                            .frame(width: 10, height: 10)
                            .shadow(color: accent.opacity(0.55), radius: 6)

                        Text(server.pingLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                            .lineLimit(1)
                    }
                }

                HStack(alignment: .center, spacing: 12) {
                    Label(server.statusLabel, systemImage: server.available ? "checkmark.icloud.fill" : "wifi.exclamationmark")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MasePalette.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    if let badgeTitle {
                        Text(badgeTitle)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(0.28))
                            )
                            .overlay {
                                Capsule()
                                    .stroke(accent.opacity(0.55), lineWidth: 1)
                            }
                    }
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

struct PulseConnectButton: View {
    let status: ConnectionStatus
    let busy: Bool
    let disabled: Bool
    let action: () -> Void

    @State private var pulse = false

    private var accent: Color {
        if disabled { return MasePalette.textMuted }

        switch status {
        case .connected: return MasePalette.green
        case .connecting: return MasePalette.cyan
        case .error: return MasePalette.red
        case .disconnecting, .disconnected: return MasePalette.blue
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(accent.opacity(0.26), lineWidth: 2)
                    .frame(width: 148 + CGFloat(index * 28), height: 148 + CGFloat(index * 28))
                    .scaleEffect(pulse ? 1.18 : 0.72)
                    .opacity(pulse ? 0.0 : 0.82)
                    .animation(
                        .easeOut(duration: 2.1)
                            .repeatForever()
                            .delay(Double(index) * 0.26),
                        value: pulse
                    )
                    .allowsHitTesting(false)
            }

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.20),
                                    accent.opacity(0.24),
                                    MasePalette.backgroundBase.opacity(0.28)
                                ],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 110
                            )
                        )
                        .frame(width: 128, height: 128)
                        .shadow(color: accent.opacity(0.32), radius: 24)
                        .allowsHitTesting(false)

                    if busy {
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: disabled ? "icloud.slash" : "power")
                            .font(.system(size: 44, weight: .regular, design: .rounded))
                            .foregroundStyle(accent)
                    }
                }
                .frame(width: 128, height: 128)
            }
            .buttonStyle(.plain)
            .disabled(disabled || busy)
            .glassEffect(.regular.interactive(), in: Circle())
        }
        .frame(width: 228, height: 228)
        .onAppear { pulse = true }
    }
}
