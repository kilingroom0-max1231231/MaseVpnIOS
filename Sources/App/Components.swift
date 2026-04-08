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
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: Capsule())
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
        if server.available { return MasePalette.cyan }
        if server.lastError != nil { return MasePalette.red }
        return MasePalette.amber
    }

    var body: some View {
        Button(action: action) {
            GlassCard(cornerRadius: 30, padding: 18, interactive: true) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                            .lineLimit(1)
                        Text(server.endpointLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MasePalette.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accent)
                            .frame(width: 10, height: 10)
                        Text(server.pingLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                    }
                }

                HStack {
                    Label(server.statusLabel, systemImage: server.available ? "checkmark.icloud" : "wifi.exclamationmark")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(MasePalette.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    if active || selected {
                        Text(active ? "Активен" : "Выбран")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .glassEffect(.regular.tint(accent), in: Capsule())
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct PulseConnectButton: View {
    let status: ConnectionStatus
    let busy: Bool
    let action: () -> Void

    @State private var pulse = false

    private var accent: Color {
        switch status {
        case .connected: return MasePalette.green
        case .connecting: return MasePalette.cyan
        case .error: return MasePalette.red
        case .disconnecting, .disconnected: return MasePalette.blue
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(accent.opacity(0.12), lineWidth: 1.2)
                    .frame(width: 138 + CGFloat(index * 24), height: 138 + CGFloat(index * 24))
                    .scaleEffect(pulse ? 1.08 : 0.90)
                    .opacity(pulse ? 0.03 : 0.16)
                    .animation(
                        .easeOut(duration: 2.1)
                            .repeatForever()
                            .delay(Double(index) * 0.28),
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
                                    Color.white.opacity(0.18),
                                    accent.opacity(0.12),
                                    MasePalette.backgroundBase.opacity(0.18)
                                ],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 110
                            )
                        )
                        .frame(width: 128, height: 128)
                        .allowsHitTesting(false)

                    if busy {
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "power")
                            .font(.system(size: 44, weight: .regular, design: .rounded))
                            .foregroundStyle(accent)
                    }
                }
                .frame(width: 128, height: 128)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
        }
        .frame(width: 214, height: 214)
        .onAppear { pulse = true }
    }
}
