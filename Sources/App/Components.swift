import SwiftUI

struct TopHeader: View {
    let title: String
    let subtitle: String
    let status: ConnectionStatus

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(MasePalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
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
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(tint.opacity(0.14))
            .overlay(Capsule().stroke(tint.opacity(0.24), lineWidth: 1))
            .clipShape(Capsule())
    }
}

struct OverviewTile: View {
    let label: String
    let value: String

    var body: some View {
        GlassCard {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MasePalette.textMuted)
            Text(value)
                .font(.system(size: 18, weight: .bold))
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
            GlassCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(MasePalette.textPrimary)
                        Text(server.endpointLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MasePalette.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accent)
                            .frame(width: 10, height: 10)
                        Text(server.pingLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MasePalette.textPrimary)
                    }
                }

                HStack {
                    Label(server.statusLabel, systemImage: server.available ? "checkmark.icloud" : "wifi.exclamationmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MasePalette.textSecondary)
                    Spacer()
                    if active || selected {
                        Text(active ? "Активен" : "Выбран")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(accent.opacity(0.14))
                            .overlay(Capsule().stroke(accent.opacity(0.22), lineWidth: 1))
                            .clipShape(Capsule())
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(active ? accent.opacity(0.44) : (selected ? MasePalette.blue.opacity(0.40) : Color.clear), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MaseTabDock: View {
    @Binding var selection: AppTab

    var body: some View {
        GlassCard {
            HStack(spacing: 8) {
                DockButton(title: "Главная", systemImage: "house.fill", active: selection == .home) {
                    selection = .home
                }
                DockButton(title: "Настройки", systemImage: "gearshape.fill", active: selection == .settings) {
                    selection = .settings
                }
            }
        }
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
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(active ? MasePalette.textPrimary : MasePalette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(active ? MasePalette.panelSoft : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(active ? MasePalette.blue.opacity(0.24) : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(accent.opacity(0.22 - Double(index) * 0.05), lineWidth: 4)
                    .frame(width: 140 + CGFloat(index * 26), height: 140 + CGFloat(index * 26))
                    .scaleEffect(pulse ? 1.08 : 0.92)
                    .opacity(pulse ? 0.15 : 0.35)
                    .animation(
                        .easeOut(duration: 1.9)
                            .repeatForever()
                            .delay(Double(index) * 0.32),
                        value: pulse
                    )
            }

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [MasePalette.panelSoft, MasePalette.panel, MasePalette.backgroundTop],
                                center: .center,
                                startRadius: 2,
                                endRadius: 90
                            )
                        )
                        .frame(width: 122, height: 122)
                    Circle()
                        .stroke(accent.opacity(0.34), lineWidth: 1)
                        .frame(width: 122, height: 122)

                    if busy {
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "power")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(accent)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(width: 220, height: 220)
        .onAppear { pulse = true }
    }
}
