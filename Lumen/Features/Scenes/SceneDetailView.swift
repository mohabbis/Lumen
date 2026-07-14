import SwiftUI
import SwiftData

// MARK: - Scene Detail View
// Edit scene metadata, geofence automation trigger, and per-device actions.

struct SceneDetailView: View {

    @Bindable var scene: Scene
    @State var viewModel: SceneViewModel
    @Environment(DeviceStateStore.self) private var stateStore

    @State private var isShowingAddAction = false
    @State private var editName: String = ""
    @State private var selectedGeofenceTrigger: GeofenceTrigger = .none
    @State private var isScheduled: Bool = false
    @State private var scheduleTime: Date = Calendar.current.date(
        bySettingHour: 21, minute: 0, second: 0, of: Date()
    ) ?? Date()

    var body: some View {
        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    automationSection
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            editName = scene.name
            selectedGeofenceTrigger = scene.geofenceTrigger
            if let (hour, minute) = scene.scheduledTime {
                isScheduled = true
                scheduleTime = Calendar.current.date(
                    bySettingHour: hour, minute: minute, second: 0, of: Date()
                ) ?? scheduleTime
            } else {
                isScheduled = false
            }
        }
        .sheet(isPresented: $isShowingAddAction) {
            AddSceneActionSheet(
                devices: SceneActionBuilder.eligibleDevices(from: stateStore.allDevices),
                onAdd: { deviceID, capabilityID, payload in
                    viewModel.addAction(to: scene, deviceID: deviceID, capabilityID: capabilityID, payload: payload)
                    isShowingAddAction = false
                },
                onCancel: { isShowingAddAction = false }
            )
        }
        .alert("Couldn't Save", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Something went wrong.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)
                    Image(systemName: scene.iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "#C49A6C"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("EDIT SCENE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(Color.white.opacity(0.35))
                    TextField("Scene name", text: $editName)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .onSubmit { saveName() }
                        .onChange(of: editName) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty, trimmed != scene.name else { return }
                            viewModel.updateScene(scene, name: trimmed)
                        }
                }
            }

            Button {
                viewModel.requestApproval(scene)
            } label: {
                Label("Run Scene", systemImage: "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#C49A6C"), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Automation

    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUTOMATION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            VStack(spacing: 0) {
                HStack {
                    Label("Geofence trigger", systemImage: "location.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("Trigger", selection: $selectedGeofenceTrigger) {
                        ForEach(GeofenceTrigger.allCases, id: \.self) { trigger in
                            Text(trigger.displayName).tag(trigger)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "#C49A6C"))
                    .onChange(of: selectedGeofenceTrigger) { _, newValue in
                        viewModel.updateScene(scene, geofenceTrigger: newValue)
                    }
                }
                .padding(16)

                if selectedGeofenceTrigger != .none {
                    Divider().overlay(Color.white.opacity(0.08))
                    Text(geofenceHint)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .padding(16)
                }
            }
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

            scheduleCard
        }
    }

    private var scheduleCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $isScheduled) {
                Label("Run on a schedule", systemImage: "clock.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            .tint(Color(hex: "#C49A6C"))
            .onChange(of: isScheduled) { _, enabled in
                // Ignore the toggle flip that comes from onAppear syncing to the model.
                guard enabled != (scene.scheduleMinutesSinceMidnight != nil) else { return }
                viewModel.setSchedule(
                    minutesSinceMidnight: enabled ? Self.minutes(from: scheduleTime) : nil,
                    on: scene
                )
            }
            .padding(16)

            if isScheduled {
                Divider().overlay(Color.white.opacity(0.08))
                DatePicker(
                    "Time",
                    selection: $scheduleTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .tint(Color(hex: "#C49A6C"))
                .foregroundStyle(.white)
                .onChange(of: scheduleTime) { _, newValue in
                    let mins = Self.minutes(from: newValue)
                    guard mins != scene.scheduleMinutesSinceMidnight else { return }
                    viewModel.setSchedule(minutesSinceMidnight: mins, on: scene)
                }
                .padding(16)

                Divider().overlay(Color.white.opacity(0.08))
                Text(scheduleHint)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .padding(16)
            }
        }
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private var geofenceHint: String {
        switch selectedGeofenceTrigger {
        case .none:
            return ""
        case .onArrival:
            return "Runs automatically when you arrive home. You'll get a notification."
        case .onDeparture:
            return "Runs automatically when you leave home. You'll get a notification."
        }
    }

    private var scheduleHint: String {
        let formatted = scheduleTime.formatted(date: .omitted, time: .shortened)
        return "Runs automatically at \(formatted) every day. It fires on its own — you'll get a notification each time."
    }

    private static func minutes(from date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Spacer()
                Button {
                    isShowingAddAction = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "#C49A6C"))
                }
            }

            if sortedActions.isEmpty {
                emptyActionsCard
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedActions, id: \.id) { action in
                        actionRow(action)
                    }
                }
            }
        }
    }

    private var emptyActionsCard: some View {
        VStack(spacing: 10) {
            Text("No device actions yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
            Text("Add actions for specific devices, or leave empty to use the scene name preset.")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }

    private func actionRow(_ action: SceneAction) -> some View {
        let description = SceneActionDescription(action: action)
        let deviceName = stateStore.device(id: action.deviceID)?.displayName ?? "Unknown device"

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(deviceName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text("\(description.capability) · \(description.detail)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            Spacer()
            Button(role: .destructive) {
                viewModel.removeAction(action, from: scene)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.red.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private var sortedActions: [SceneAction] {
        scene.actions.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func saveName() {
        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.updateScene(scene, name: trimmed)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
}

// MARK: - Add Scene Action Sheet

private struct AddSceneActionSheet: View {

    let devices: [any SmartDevice]
    let onAdd: (UUID, CapabilityID, ActionPayload) -> Void
    let onCancel: () -> Void

    @State private var selectedDeviceID: UUID?
    @State private var selectedCapabilityID: CapabilityID?
    @State private var powerOn = true
    @State private var brightness: Double = 0.5
    @State private var lockState: LockState = .locked

    private var selectedDevice: (any SmartDevice)? {
        guard let id = selectedDeviceID else { return nil }
        return devices.first { $0.id == id }
    }

    private var capabilityOptions: [SceneActionOption] {
        guard let device = selectedDevice else { return [] }
        return SceneActionBuilder.options(for: device)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Device") {
                    if devices.isEmpty {
                        Text("No controllable devices found. Add planned devices or connect HomeKit.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Device", selection: $selectedDeviceID) {
                            Text("Choose…").tag(Optional<UUID>.none)
                            ForEach(devices, id: \.id) { device in
                                Text(device.displayName).tag(Optional(device.id))
                            }
                        }
                        .onChange(of: selectedDeviceID) { _, _ in
                            selectedCapabilityID = capabilityOptions.first?.capabilityID
                        }
                    }
                }

                if !capabilityOptions.isEmpty {
                    Section("Action") {
                        Picker("Capability", selection: $selectedCapabilityID) {
                            ForEach(capabilityOptions) { option in
                                Text(option.displayName).tag(Optional(option.capabilityID))
                            }
                        }
                        valueControls
                    }
                }
            }
            .navigationTitle("Add Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addAction)
                        .disabled(!canAdd)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if selectedDeviceID == nil {
                selectedDeviceID = devices.first?.id
                selectedCapabilityID = capabilityOptions.first?.capabilityID
            }
        }
    }

    @ViewBuilder
    private var valueControls: some View {
        switch selectedCapabilityID {
        case .onOff:
            Toggle("Power on", isOn: $powerOn)
        case .brightness:
            VStack(alignment: .leading) {
                Text("Brightness: \(Int((brightness * 100).rounded()))%")
                Slider(value: $brightness, in: 0...1)
            }
        case .lock:
            Picker("Lock state", selection: $lockState) {
                Text("Locked").tag(LockState.locked)
                Text("Unlocked").tag(LockState.unlocked)
            }
        default:
            EmptyView()
        }
    }

    private var canAdd: Bool {
        selectedDeviceID != nil && selectedCapabilityID != nil && payload != nil
    }

    private var payload: ActionPayload? {
        guard let capabilityID = selectedCapabilityID else { return nil }
        switch capabilityID {
        case .onOff:
            return .bool(powerOn)
        case .brightness:
            return .double(brightness)
        case .lock:
            return .lockState(lockState)
        default:
            return SceneActionBuilder.defaultPayload(for: capabilityID)
        }
    }

    private func addAction() {
        guard let deviceID = selectedDeviceID, let capabilityID = selectedCapabilityID, let payload else { return }
        onAdd(deviceID, capabilityID, payload)
    }
}
