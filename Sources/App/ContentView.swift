import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MaseVpnViewModel

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppBackdrop()

                Group {
                    switch viewModel.selectedTab {
                    case .home:
                        HomeView(viewModel: viewModel, topInset: proxy.safeAreaInsets.top)
                    case .settings:
                        SettingsView(viewModel: viewModel, topInset: proxy.safeAreaInsets.top)
                    }
                }
            }
            .ignoresSafeArea()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MaseTabDock(selection: $viewModel.selectedTab)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, max(12, proxy.safeAreaInsets.bottom == 0 ? 12 : proxy.safeAreaInsets.bottom))
            }
        }
    }
}

private struct HomeView: View {
    @ObservedObject var viewModel: MaseVpnViewModel
    let topInset: CGFloat

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TopHeader(title: "MaseVpn", subtitle: "Безопасное подключение", status: viewModel.vpnStatus.status)

                GlassCard(cornerRadius: 34, padding: 22) {
                    VStack(spacing: 18) {
                        Text(headline)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(viewModel.vpnStatus.activeServerName ?? "Нажмите, чтобы подключиться")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(MasePalette.textSecondary)
                            .multilineTextAlignment(.center)

                        PulseConnectButton(
                            status: viewModel.vpnStatus.status,
                            busy: viewModel.vpnStatus.isBusy,
                            action: viewModel.toggleConnection
                        )

                        if let error = viewModel.vpnStatus.lastError, !error.isEmpty {
                            Text(error)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(MasePalette.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    OverviewTile(label: "Время", value: viewModel.vpnStatus.durationLabel)
                    OverviewTile(label: "Отправлено", value: viewModel.vpnStatus.traffic.uploadLabel)
                    OverviewTile(label: "Получено", value: viewModel.vpnStatus.traffic.downloadLabel)
                    OverviewTile(label: "Скорость", value: viewModel.vpnStatus.traffic.downloadRateLabel)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Серверы")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
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
            .padding(.horizontal, 20)
            .padding(.top, topInset + 6)
            .padding(.bottom, 36)
        }
    }

    private var headline: String {
        switch viewModel.vpnStatus.status {
        case .disconnected: return "Нажмите, чтобы подключиться"
        case .connecting: return "Подключение..."
        case .connected: return "VPN подключен"
        case .disconnecting: return "Отключение..."
        case .error: return "Ошибка подключения"
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var viewModel: MaseVpnViewModel
    let topInset: CGFloat

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TopHeader(title: "Настройки", subtitle: "Параметры VPN", status: viewModel.vpnStatus.status)

                GlassCard(cornerRadius: 32, padding: 20) {
                    Text("Подписка")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MasePalette.textPrimary)

                    TextField("https://...", text: $viewModel.settings.subscriptionURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(MasePalette.glassWhiteStrong, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .foregroundStyle(MasePalette.textPrimary)

                    PrimaryButton(title: "Обновить подписку", action: viewModel.refreshSubscription)
                }

                GlassCard(cornerRadius: 32, padding: 20) {
                    Text("Автоматизация")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MasePalette.textPrimary)

                    ToggleRow(
                        title: "Автовыбор лучшего",
                        subtitle: "Выбирать сервер с минимальной задержкой",
                        isOn: $viewModel.settings.autoSelectBest
                    )

                    ToggleRow(
                        title: "Автопереключение",
                        subtitle: "Переключаться на другой сервер при сбое",
                        isOn: $viewModel.settings.autoSwitchOnFailure
                    )
                }

                GlassCard(cornerRadius: 32, padding: 20) {
                    Text("Быстрые действия")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MasePalette.textPrimary)

                    SecondaryButton(title: "Обновить пинг", action: viewModel.refreshPings)
                    SecondaryButton(title: "Выбрать лучший сервер", action: viewModel.pickBestServer)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 6)
            .padding(.bottom, 36)
        }
    }
}

private struct AppBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MasePalette.backgroundBase, MasePalette.backgroundTop, MasePalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MasePalette.blue.opacity(0.34), Color.clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .offset(x: 120, y: -180)

            RadialGradient(
                colors: [MasePalette.cyan.opacity(0.24), Color.clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 360
            )
            .offset(x: -140, y: 220)

            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.clear, Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            .ignoresSafeArea()
        }
    }
}

private struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MasePalette.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [MasePalette.cyan.opacity(0.92), MasePalette.blue.opacity(0.92)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: MasePalette.blue.opacity(0.28), radius: 18, y: 10)
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
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MasePalette.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(MasePalette.glassWhiteStrong, lineWidth: 1)
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
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(MasePalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MasePalette.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(MasePalette.blue)
                .labelsHidden()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MasePalette.glassWhiteStrong, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
