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
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.34), lineWidth: 1))
            .clipShape(Capsule())
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
            GlassCard(cornerRadius: 30, padding: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                        Text(server.endpointLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MasePalette.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accent)
                            .frame(width: 10, height: 10)
                            .shadow(color: accent.opacity(0.55), radius: 10)
                        Text(server.pingLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                    }
                }

                HStack {
                    Label(server.statusLabel, systemImage: server.available ? "checkmark.icloud" : "wifi.exclamationmark")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(MasePalette.textSecondary)
                    Spacer()
                    if active || selected {
                        Text(active ? "Активен" : "Выбран")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(accent.opacity(0.32), lineWidth: 1))
                            .clipShape(Capsule())
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(active ? accent.opacity(0.44) : (selected ? MasePalette.blue.opacity(0.34) : Color.clear), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MaseTabDock: View {
    @Binding var selection: AppTab

    var body: some View {
        GlassCard(cornerRadius: 32, padding: 10) {
            HStack(spacing: 8) {
                DockButton(title: "Главная", systemImage: "house.fill", active: selection == .home) {
                    selection = .home
                }
                DockButton(title: "Настройки", systemImage: "gearshape.fill", active: selection == .settings) {
                    selection = .settings
                }
            }
        }
        .shadow(color: MasePalette.glassShadow.opacity(0.7), radius: 40, x: 0, y: 20)
    }
}

private struct DockButton: View {
    let title: String
    let systemImage: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(active ? MasePalette.textPrimary : MasePalette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                if active {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay(
                Capsule()
                    .stroke(active ? MasePalette.glassWhiteStrong : Color.clear, lineWidth: 1)
            )
            .shadow(color: active ? MasePalette.blue.opacity(0.18) : .clear, radius: 14, y: 8)
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
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.34), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
                    .frame(width: 138 + CGFloat(index * 24), height: 138 + CGFloat(index * 24))
                    .scaleEffect(pulse ? 1.08 : 0.90)
                    .opacity(pulse ? 0.06 : 0.24)
                    .animation(
                        .easeOut(duration: 2.1)
                            .repeatForever()
                            .delay(Double(index) * 0.28),
                        value: pulse
                    )
            }

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 128, height: 128)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    accent.opacity(0.18),
                                    MasePalette.backgroundBase.opacity(0.20)
                                ],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 110
                            )
                        )
                        .frame(width: 128, height: 128)
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .frame(width: 128, height: 128)
                    Circle()
                        .stroke(accent.opacity(0.22), lineWidth: 6)
                        .blur(radius: 10)
                        .frame(width: 110, height: 110)
                    Ellipse()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 64, height: 20)
                        .blur(radius: 6)
                        .offset(y: -28)

                    if busy {
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "power")
                            .font(.system(size: 44, weight: .regular, design: .rounded))
                            .foregroundStyle(accent)
                            .shadow(color: accent.opacity(0.34), radius: 12)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(width: 214, height: 214)
        .onAppear { pulse = true }
    }
}
