import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MaseVpnViewModel

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppBackdrop()

                TabView(selection: $viewModel.selectedTab) {
                    HomeView(viewModel: viewModel, topInset: proxy.safeAreaInsets.top)
                        .tag(AppTab.home)
                        .tabItem {
                            Label("Главная", systemImage: "house.fill")
                        }

                    SettingsView(viewModel: viewModel, topInset: proxy.safeAreaInsets.top)
                        .tag(AppTab.settings)
                        .tabItem {
                            Label("Настройки", systemImage: "gearshape.fill")
                        }
                }
            }
            .ignoresSafeArea()
        }
    }
}

private struct HomeView: View {
    @ObservedObject var viewModel: MaseVpnViewModel
    let topInset: CGFloat

    var body: some View {
        ScrollView(showsIndicators: false) {
            GlassEffectContainer {
                VStack(spacing: 18) {
                    TopHeader(title: "MaseVpn", subtitle: "Безопасное подключение", status: viewModel.vpnStatus.status)

                    GlassCard(cornerRadius: 34, padding: 22) {
                        VStack(spacing: 18) {
                            Text(headline)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(MasePalette.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(subheadline)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(MasePalette.textSecondary)
                                .multilineTextAlignment(.center)

                            PulseConnectButton(
                                status: viewModel.vpnStatus.status,
                                busy: viewModel.vpnStatus.isBusy,
                                disabled: !viewModel.hasServers || viewModel.isCheckingServers,
                                action: viewModel.toggleConnection
                            )

                            if let error = viewModel.vpnStatus.lastError, !error.isEmpty {
                                ErrorBanner(error: error)
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
                        HStack {
                            Text("Серверы")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(MasePalette.textPrimary)

                            Spacer()

                            if viewModel.isCheckingServers {
                                Text("Проверка...")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(MasePalette.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(MasePalette.amber.opacity(0.24))
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(MasePalette.amber.opacity(0.45), lineWidth: 1)
                                    }
                            }
                        }

                        if viewModel.servers.isEmpty {
                            EmptyServersCard {
                                viewModel.selectedTab = .settings
                            }
                        } else {
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 6)
            .padding(.bottom, 104)
        }
    }

    private var headline: String {
        if !viewModel.hasServers {
            return "Загрузите подписку"
        }

        switch viewModel.vpnStatus.status {
        case .disconnected: return "Нажмите, чтобы подключиться"
        case .connecting: return "Подключение..."
        case .connected: return "VPN подключен"
        case .disconnecting: return "Отключение..."
        case .error: return "Ошибка подключения"
        }
    }

    private var subheadline: String {
        if !viewModel.hasServers {
            return "Откройте настройки, вставьте ссылку подписки и загрузите список серверов."
        }

        return viewModel.vpnStatus.activeServerName ?? "Выберите сервер и нажмите кнопку подключения"
    }
}

private struct SettingsView: View {
    @ObservedObject var viewModel: MaseVpnViewModel
    let topInset: CGFloat
    @FocusState private var isSubscriptionFieldFocused: Bool

    private var backgroundChecksBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.backgroundHealthChecksEnabled },
            set: { newValue in
                viewModel.settings.backgroundHealthChecksEnabled = newValue
                viewModel.updateHealthCheckConfiguration()
            }
        )
    }

    private var intervalBinding: Binding<Int> {
        Binding(
            get: { viewModel.settings.healthCheckInterval },
            set: { newValue in
                viewModel.settings.healthCheckInterval = newValue
                viewModel.updateHealthCheckConfiguration()
            }
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            GlassEffectContainer {
                VStack(spacing: 18) {
                    TopHeader(title: "Настройки", subtitle: "Параметры VPN", status: viewModel.vpnStatus.status)

                    GlassCard(cornerRadius: 32, padding: 20) {
                        Text("Подписка")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)

                        TextField("https://...", text: $viewModel.settings.subscriptionURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($isSubscriptionFieldFocused)
                            .padding(16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .foregroundStyle(MasePalette.textPrimary)
                            .onSubmit {
                                isSubscriptionFieldFocused = false
                            }

                        PrimaryButton(
                            title: viewModel.isRefreshingSubscription ? "Загрузка..." : "Загрузить подписку",
                            action: viewModel.refreshSubscription,
                            isDisabled: viewModel.isRefreshingSubscription
                        )

                        if let error = viewModel.vpnStatus.lastError, !error.isEmpty {
                            ErrorBanner(error: error)
                        }
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
                            subtitle: "Менять сервер, если активный перестал отвечать",
                            isOn: $viewModel.settings.autoSwitchOnFailure
                        )

                        ToggleRow(
                            title: "Фоновая проверка",
                            subtitle: "Автоматически проверять серверы, пока приложение открыто",
                            isOn: backgroundChecksBinding
                        )

                        HealthCheckIntervalRow(interval: intervalBinding)
                    }

                    GlassCard(cornerRadius: 32, padding: 20) {
                        Text("Быстрые действия")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(MasePalette.textPrimary)

                        SecondaryButton(
                            title: viewModel.isCheckingServers ? "Проверка..." : "Проверить серверы",
                            action: viewModel.refreshPings,
                            isDisabled: viewModel.isCheckingServers || viewModel.servers.isEmpty
                        )

                        SecondaryButton(
                            title: "Выбрать лучший сервер",
                            action: viewModel.pickBestServer,
                            isDisabled: viewModel.servers.isEmpty
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 6)
            .padding(.bottom, 104)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    isSubscriptionFieldFocused = false
                }
            }
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
                colors: [MasePalette.blue.opacity(0.10), Color.clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .offset(x: 120, y: -180)

            RadialGradient(
                colors: [Color.white.opacity(0.08), Color.clear],
                center: .topLeading,
                startRadius: 16,
                endRadius: 260
            )
            .offset(x: -80, y: -120)

            RadialGradient(
                colors: [MasePalette.cyan.opacity(0.06), Color.clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 340
            )
            .offset(x: -140, y: 200)
        }
        .allowsHitTesting(false)
    }
}

private struct EmptyServersCard: View {
    let openSettings: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 30, padding: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Список серверов пуст")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(MasePalette.textPrimary)

                Text("Пока вы не загрузили подписку, серверы здесь не отображаются.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MasePalette.textSecondary)

                SecondaryButton(title: "Открыть настройки", action: openSettings)
            }
        }
    }
}

private struct ErrorBanner: View {
    let error: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(MasePalette.red)

            Text(error)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MasePalette.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MasePalette.red.opacity(0.16))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MasePalette.red.opacity(0.42), lineWidth: 1)
        }
    }
}

private struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glassProminent)
        .tint(MasePalette.blue)
        .disabled(isDisabled)
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .disabled(isDisabled)
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
                .labelsHidden()
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct HealthCheckIntervalRow: View {
    @Binding var interval: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Интервал проверки")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(MasePalette.textPrimary)

                    Text("Серверы будут перепроверяться каждые \(interval) сек.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(MasePalette.textSecondary)
                }

                Spacer()

                Text("\(interval) c")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MasePalette.textPrimary)
            }

            Stepper(value: $interval, in: 5...300, step: 5) {
                EmptyView()
            }
            .labelsHidden()
            .tint(MasePalette.cyan)
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
