import SwiftUI

struct SettingsView: View {

    @Environment(HomeService.self) private var homeService
    @Environment(DeviceService.self) private var deviceService
    @Environment(DeviceStateStore.self) private var stateStore
    @Environment(AppState.self) private var appState
    @Environment(RemoteService.self) private var remoteService
    @Environment(LocationService.self) private var locationService
    @Environment(\.modelContext) private var modelContext

    @State private var homeLocationMessage: String?
    @State private var homeLocationError: String?

    var body: some View {
        ZStack {
            Color.lumenBackground.ignoresSafeArea()
            scrollContent
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            "Couldn’t update location",
            isPresented: Binding(
                get: { homeLocationError != nil },
                set: { if !$0 { homeLocationError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { homeLocationError = nil }
        } message: {
            Text(homeLocationError ?? "")
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                homeSection
                bridgesSection
                remotesSection
                localDevicesSection
                preferencesSection
                sensoryProfileSection
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
                SettingsRow(label: "Devices", value: "\(home.totalDeviceCount)")
                SettingsRow(label: "Home location", value: homeLocationStatus(for: home))
                Button(action: { setHomeLocationFromCurrent(home: home) }) {
                    HStack {
                        Text("Use current location")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.lumenAccent)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                if let homeLocationMessage {
                    Text(homeLocationMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
            } else {
                Text("No home configured")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
        }
    }

    private func homeLocationStatus(for home: Home) -> String {
        if home.latitude != nil, home.longitude != nil {
            return "Set"
        }
        if locationService.getHomeCoordinates() != nil {
            return "Armed (device only)"
        }
        return "Not set"
    }

    private func setHomeLocationFromCurrent(home: Home) {
        homeLocationMessage = nil
        locationService.requestLocationPermission()
        locationService.startMonitoringLocation()

        guard let coordinate = locationService.currentLocation else {
            homeLocationMessage = "Waiting for GPS — try again in a moment."
            return
        }

        do {
            try homeService.updateCoordinates(
                home,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            locationService.updateHomeCoordinates(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            homeLocationMessage = "Home radius set from your current location."
            locationService.requestBackgroundLocationPermission()
        } catch {
            homeLocationError = error.localizedDescription
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

    // MARK: - Remotes Section

    private var remotesSection: some View {
        SettingsDarkCard(title: "REMOTES") {
            NavigationLink {
                RemoteListView(
                    viewModel: RemoteViewModel(modelContext: modelContext, remoteService: remoteService)
                )
            } label: {
                HStack {
                    Text("IR Remotes")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Local Devices Section

    private var localDevicesSection: some View {
        SettingsDarkCard(title: "LOCAL DEVICES") {
            NavigationLink {
                LocalDeviceListView()
            } label: {
                HStack {
                    Text("Wi-Fi Devices")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
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

    // MARK: - Sensory Profile Section

    private var sensoryProfileSection: some View {
        @Bindable var state = appState

        return SettingsDarkCard(title: "SENSORY PROFILE") {
            VStack(spacing: 0) {
                SettingsRow(label: "Profile", value: appState.sensoryProfile.summaryTitle, isLast: false)
                SettingsToggleRow(label: "Calm Mode", isOn: $state.sensoryProfile.calmModeEnabled, isLast: false)
                    .onChange(of: appState.sensoryProfile.calmModeEnabled) { _, enabled in
                        if enabled {
                            appState.sensoryProfile.applyCalmModeDefaults()
                        }
                    }
                SettingsOptionRow(
                    label: "Suggestions",
                    selection: $state.sensoryProfile.suggestionCadence,
                    options: SensorySuggestionCadence.allCases,
                    title: \.title,
                    isLast: false
                )
                SettingsOptionRow(
                    label: "Motion",
                    selection: $state.sensoryProfile.motionPreference,
                    options: SensoryMotionPreference.allCases,
                    title: \.title,
                    isLast: false
                )
                SettingsOptionRow(
                    label: "Contrast",
                    selection: $state.sensoryProfile.contrastPreference,
                    options: SensoryContrastPreference.allCases,
                    title: \.title,
                    isLast: false
                )
                SettingsStepperRow(
                    label: "Transitions",
                    value: $state.sensoryProfile.transitionWarningMinutes,
                    range: 0...30,
                    step: 5,
                    displayValue: appState.sensoryProfile.transitionWarningLabel,
                    isLast: true
                )
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

// MARK: - Settings Option Row

private struct SettingsOptionRow<Option: CaseIterable & Hashable & Identifiable>: View where Option.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: Option
    let options: Option.AllCases
    let title: KeyPath<Option, String>
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option[keyPath: title]).tag(option)
                }
            }
            .tint(Color.lumenAccent)
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

// MARK: - Settings Stepper Row

private struct SettingsStepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let displayValue: String
    var isLast: Bool = false

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Text(displayValue)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .tint(Color.lumenAccent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.leading, 16)
            }
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
                .tint(Color.lumenAccent)
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
