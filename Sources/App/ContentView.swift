import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MaseVpnViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [MasePalette.backgroundTop, MasePalette.backgroundBottom, MasePalette.panel],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            BackgroundGlow()
                .ignoresSafeArea()

            Group {
                switch viewModel.selectedTab {
                case .home:
                    HomeView(viewModel: viewModel)
                case .settings:
                    SettingsView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 112)

            MaseTabDock(selection: $viewModel.selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
        }
    }
}

private struct HomeView: View {
    @ObservedObject var viewModel: MaseVpnViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TopHeader(title: "MaseVpn", subtitle: "Управление VPN", status: viewModel.vpnStatus.status)

                GlassCard {
                    VStack(spacing: 18) {
                        Text(headline)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(MasePalette.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(viewModel.vpnStatus.activeServerName ?? "Нажмите чтобы подключиться")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MasePalette.textSecondary)
                            .multilineTextAlignment(.center)

                        PulseConnectButton(
                            status: viewModel.vpnStatus.status,
                            busy: viewModel.vpnStatus.isBusy,
                            action: viewModel.toggleConnection
                        )

                        if let error = viewModel.vpnStatus.lastError, !error.isEmpty {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(MasePalette.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(MasePalette.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 12) {
                    OverviewTile(label: "Время", value: viewModel.vpnStatus.durationLabel)
                    OverviewTile(label: "Отправлено", value: viewModel.vpnStatus.traffic.uploadLabel)
                }

                HStack(spacing: 12) {
                    OverviewTile(label: "Получено", value: viewModel.vpnStatus.traffic.downloadLabel)
                    OverviewTile(label: "Скорость", value: viewModel.vpnStatus.traffic.downloadRateLabel)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Серверы")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(MasePalette.textPrimary)

                    ForEach(viewModel.servers) { server in
                        ServerCard(
                            server: server,
                            selected: viewModel.settings.selectedServerId == server.id,
                            active: viewModel.vpnStatus.activeServerId == server.id
                        ) {
                            viewModel.selectServer(server.id)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var headline: String {
        switch viewModel.vpnStatus.status {
        case .disconnected: return "Нажмите чтобы подключиться"
        case .connecting: return "Подключение..."
        case .connected: return "VPN подключен"
        case .disconnecting: return "Отключение..."
        case .error: return "Ошибка подключения"
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var viewModel: MaseVpnViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TopHeader(title: "Настройки", subtitle: "Параметры VPN", status: viewModel.vpnStatus.status)

                GlassCard {
                    Text("Подписка")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MasePalette.textPrimary)

                    TextField("https://...", text: $viewModel.settings.subscriptionURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(MasePalette.backgroundTop.opacity(0.34))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(MasePalette.panelStroke.opacity(0.9), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .foregroundStyle(MasePalette.textPrimary)

                    PrimaryButton(title: "Обновить подписку", action: viewModel.refreshSubscription)
                }

                GlassCard {
                    Text("Автоматизация")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MasePalette.textPrimary)

                    ToggleRow(
                        title: "Автовыбор лучшего",
                        subtitle: "Выбирать сервер с меньшей задержкой",
                        isOn: $viewModel.settings.autoSelectBest
                    )

                    ToggleRow(
                        title: "Автопереключение",
                        subtitle: "Переключаться на другой сервер при сбое",
                        isOn: $viewModel.settings.autoSwitchOnFailure
                    )
                }

                GlassCard {
                    Text("Быстрые действия")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MasePalette.textPrimary)

                    SecondaryButton(title: "Обновить пинг", action: viewModel.refreshPings)
                    SecondaryButton(title: "Выбрать лучший сервер", action: viewModel.pickBestServer)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

private struct BackgroundGlow: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(MasePalette.blue.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 120, y: -220)

            Circle()
                .fill(MasePalette.cyan.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -110, y: 20)

            Circle()
                .fill(MasePalette.green.opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 120, y: 420)
        }
    }
}

private struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MasePalette.backgroundTop)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [MasePalette.cyan, MasePalette.blue], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MasePalette.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MasePalette.backgroundTop.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(MasePalette.panelStroke.opacity(0.86), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MasePalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MasePalette.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(MasePalette.blue)
                .labelsHidden()
        }
        .padding(14)
        .background(MasePalette.backgroundTop.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MasePalette.panelStroke.opacity(0.82), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
