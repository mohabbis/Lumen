import SwiftUI

struct SettingsView: View {

    @Environment(HomeService.self) private var homeService
    @Environment(DeviceService.self) private var deviceService
    @Environment(DeviceStateStore.self) private var stateStore
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()
            scrollContent
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                homeSection
                bridgesSection
                preferencesSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LUMEN")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.5)
                .foregroundStyle(Color.white.opacity(0.35))
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Home Section

    private var homeSection: some View {
        SettingsDarkCard(title: "HOME") {
            if let home = homeService.primaryHome {
                SettingsRow(label: "Name", value: home.name)
                SettingsRow(label: "Rooms", value: "\(home.roomCount)")
                SettingsRow(label: "Devices", value: "\(home.totalDeviceCount)", isLast: true)
            } else {
                Text("No home configured")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Bridges Section

    private var bridgesSection: some View {
        SettingsDarkCard(title: "BRIDGES") {
            if stateStore.bridgeStatuses.isEmpty {
                Text("No bridges registered")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            } else {
                let statuses = Array(stateStore.bridgeStatuses)
                ForEach(statuses.indices, id: \.self) { i in
                    let (bridgeID, status) = statuses[i]
                    SettingsRow(
                        label: bridgeID.rawValue.capitalized,
                        value: status.displayName,
                        isLast: i == statuses.count - 1
                    )
                }
            }
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        @Bindable var state = appState

        return SettingsDarkCard(title: "PREFERENCES") {
            VStack(spacing: 0) {
                SettingsToggleRow(label: "Preview controls", isOn: $state.enableLocalPreviewControls, isLast: false)
                    .onChange(of: appState.enableLocalPreviewControls) { _, enabled in
                        deviceService.setLocalPreviewEnabled(enabled, home: homeService.primaryHome)
                    }
                SettingsToggleRow(label: "Haptics", isOn: $state.hapticFeedbackEnabled, isLast: false)
                SettingsToggleRow(label: "Debug details", isOn: $state.showDebugDetails, isLast: true)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsDarkCard(title: "ABOUT") {
            SettingsRow(
                label: "Version",
                value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
            )
            SettingsRow(
                label: "Build",
                value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–",
                isLast: true
            )
        }
    }
}

// MARK: - Settings Dark Card

private struct SettingsDarkCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))
            content()
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let label: String
    let value: String
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.leading, 16)
            }
        }
    }
}

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "#C49A6C"))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.leading, 16)
            }
        }
    }
}
