import SwiftUI

// MARK: - Device Detail View
// Renders only the controls that the device's capability set supports.
// No type-checking — pure capability-driven UI.

struct DeviceDetailView: View {

    let device: any SmartDevice
    @State var viewModel: DeviceViewModel
    @State private var isShowingCommissionSheet = false

    var body: some View {
        let currentDevice = viewModel.device(id: device.id) ?? device
        let state = viewModel.controlState(for: currentDevice)

        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()
            content(device: currentDevice, state: state)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingCommissionSheet) {
            CommissionDeviceView(liveDevice: currentDevice, viewModel: viewModel)
        }
    }

    // MARK: - Content

    private func content(device: any SmartDevice, state: LocalDeviceState) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(device: device)
                statusCard(device: device, state: state)

                if viewModel.isCommissionable(device) {
                    commissioningCard(device: device)
                }
                if device.supports(.onOff) { onOffCard(device: device, state: state) }
                if device.supports(.brightness) { brightnessCard(device: device, state: state) }
                if device.supports(.colorTemperature) { colorTempCard(device: device, state: state) }
                if device.supports(.colorHue) { colorCard(device: device, state: state) }
                if device.supports(.temperature) { temperatureCard(state: state) }
                if device.supports(.motion) { motionCard(state: state) }
                if device.supports(.contact) { contactCard(state: state) }
                if device.supports(.lock) { lockCard(device: device, state: state) }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Header

    private func header(device: any SmartDevice) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(device.category.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(device.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 46, height: 46)
                Image(systemName: device.category.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#C49A6C"))
            }
        }
    }

    // MARK: - Status Card

    private func statusCard(device: any SmartDevice, state: LocalDeviceState) -> some View {
        DarkCard(title: "STATUS") {
            VStack(spacing: 0) {
                DarkRow(label: "Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(device.reachability == .reachable ? Color(hex: "#6FDBA8") : Color.white.opacity(0.25))
                            .frame(width: 7, height: 7)
                        Text(device.reachability == .reachable ? "Online" : "Offline")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                if let room = device.roomName {
                    DarkRow(label: "Room") {
                        Text(room).font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                DarkRow(label: "Category") {
                    Text(device.category.rawValue).font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.6))
                }
                if device.supports(.onOff) {
                    DarkRow(label: "Power", isLast: true) {
                        Text(state.isPowered ? "On" : "Off")
                            .font(.system(size: 14))
                            .foregroundStyle(state.isPowered ? Color(hex: "#6FDBA8") : Color.white.opacity(0.4))
                    }
                }
            }
        }
    }

    // MARK: - Commissioning Card

    private func commissioningCard(device: any SmartDevice) -> some View {
        DarkCard(title: "PLANNING") {
            VStack(spacing: 0) {
                if let linked = viewModel.linkedPlannedDevice(for: device) {
                    DarkRow(label: "Linked to") {
                        HStack(spacing: 4) {
                            Image(systemName: "link").font(.caption).foregroundStyle(Color(hex: "#6FDBA8"))
                            Text(linked.displayName).font(.system(size: 14)).foregroundStyle(Color(hex: "#6FDBA8"))
                        }
                    }
                    if let room = linked.room?.name {
                        DarkRow(label: "Room") {
                            Text(room).font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                    Button(role: .destructive) { viewModel.decommission(linked) } label: {
                        Label("Unlink Device", systemImage: "link.badge.plus")
                            .font(.system(size: 14))
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                } else {
                    Button { isShowingCommissionSheet = true } label: {
                        Label("Link to Planned Device", systemImage: "link")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "#C49A6C"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
            }
        }
    }

    // MARK: - Control Cards

    private func onOffCard(device: any SmartDevice, state: LocalDeviceState) -> some View {
        DarkCard(title: "POWER") {
            HStack {
                Text("Power")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.isPowered },
                    set: { viewModel.setPower($0, deviceID: device.id) }
                ))
                .tint(Color(hex: "#6FDBA8"))
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func brightnessCard(device: any SmartDevice, state: LocalDeviceState) -> some View {
        DarkCard(title: "BRIGHTNESS") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "sun.min").foregroundStyle(Color.white.opacity(0.4))
                    Slider(
                        value: Binding(
                            get: { state.brightness },
                            set: { viewModel.setBrightness($0, deviceID: device.id) }
                        ),
                        in: 0...1
                    )
                    .tint(Color(hex: "#C49A6C"))
                    Image(systemName: "sun.max").foregroundStyle(Color.white.opacity(0.8))
                }
                Text("\(Int(state.brightness * 100))%")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func colorTempCard(device: any SmartDevice, state: LocalDeviceState) -> some View {
        DarkCard(title: "COLOR TEMPERATURE") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "flame").foregroundStyle(.orange.opacity(0.8))
                    Slider(
                        value: Binding(
                            get: { Double(state.colorTemperature) },
                            set: { viewModel.setColorTemperature(Int($0), deviceID: device.id) }
                        ),
                        in: 1800...6500
                    )
                    .tint(Color(hex: "#C49A6C"))
                    Image(systemName: "snowflake").foregroundStyle(.blue.opacity(0.8))
                }
                Text("\(state.colorTemperature)K")
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func colorCard(device: any SmartDevice, state: LocalDeviceState) -> some View {
        DarkCard(title: "COLOR") {
            HStack {
                Text("Hue")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                ColorPicker("", selection: Binding(
                    get: { Color(hue: state.hue, saturation: state.saturation, brightness: max(state.brightness, 0.3)) },
                    set: { color in
                        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0
                        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: nil)
                        viewModel.setColor(hue: Double(h), saturation: Double(s), deviceID: device.id)
                        viewModel.setBrightness(Double(b), deviceID: device.id)
                    }
                ))
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func temperatureCard(state: LocalDeviceState) -> some View {
        DarkCard(title: "TEMPERATURE") {
            DarkRow(label: "Current", isLast: true) {
                Text("\(state.currentTemperatureCelsius, specifier: "%.1f") °C")
                    .font(.system(size: 14).monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
    }

    private func motionCard(state: LocalDeviceState) -> some View {
        DarkCard(title: "MOTION") {
            DarkRow(label: "Detected", isLast: true) {
                Text(state.motionDetected ? "Yes" : "No")
                    .font(.system(size: 14))
                    .foregroundStyle(state.motionDetected ? Color(hex: "#C49A6C") : Color.white.opacity(0.4))
            }
        }
    }

    private func contactCard(state: LocalDeviceState) -> some View {
        DarkCard(title: "CONTACT") {
            DarkRow(label: "State", isLast: true) {
                Text(state.contactState.rawValue.capitalized)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
    }

    private func lockCard(device: any SmartDevice, state: LocalDeviceState) -> some View {
        DarkCard(title: "LOCK") {
            Button {
                viewModel.setLock(state.lockState == .locked ? .unlocked : .locked, deviceID: device.id)
            } label: {
                HStack {
                    Label(
                        state.lockState == .locked ? "Unlock" : "Lock",
                        systemImage: state.lockState == .locked ? "lock.open.fill" : "lock.fill"
                    )
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(state.lockState == .locked ? Color(hex: "#C49A6C") : Color.white.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Dark Card

private struct DarkCard<Content: View>: View {
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

// MARK: - Dark Row

private struct DarkRow<Trailing: View>: View {
    let label: String
    var isLast: Bool = false
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.leading, 16)
            }
        }
    }
}
