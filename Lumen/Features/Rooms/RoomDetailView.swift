import SwiftUI

// MARK: - Room Detail View

struct RoomDetailView: View {

    let room: Room
    @State var viewModel: RoomViewModel
    @State private var isShowingAddDevice = false
    @State private var isRenamingRoom = false
    @State private var renameText = ""

    var body: some View {
        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()
            scrollContent
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Rename Room", isPresented: $isRenamingRoom) {
            TextField("Room name", text: $renameText)
            Button("Save") { viewModel.updateRoom(room, name: renameText, type: room.type) }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $isShowingAddDevice) {
            AddDeviceView { name, type in
                viewModel.addDevice(name: name, type: type, to: room)
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                let liveDevices = viewModel.liveDevices(in: room)
                let planned = room.plannedDevices.sorted { $0.name < $1.name }

                if liveDevices.isEmpty && planned.isEmpty {
                    emptyState
                } else {
                    if !liveDevices.isEmpty {
                        deviceSection(title: "ACTIVE DEVICES", devices: liveDevices)
                    }
                    if !planned.isEmpty {
                        plannedSection(planned: planned)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(room.type.iconName.isEmpty ? "ROOM" : room.type.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(room.name)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .onLongPressGesture {
                        renameText = room.name
                        isRenamingRoom = true
                    }
            }
            Spacer()
            Button { isShowingAddDevice = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Device Section

    private func deviceSection(title: String, devices: [any SmartDevice]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            VStack(spacing: 10) {
                ForEach(devices, id: \.id) { device in
                    NavigationLink(destination: DeviceDetailView(
                        device: device,
                        viewModel: viewModel.makeDeviceViewModel()
                    )) {
                        LiveDeviceDarkRow(device: device)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Planned Section

    private func plannedSection(planned: [PlannedDevice]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PLANNED")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            VStack(spacing: 10) {
                ForEach(planned) { device in
                    PlannedDeviceRow(device: device)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: room.type.iconName)
                .font(.system(size: 36))
                .foregroundStyle(Color.white.opacity(0.2))
            Text("No Devices")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))
            Text("Plan the devices you want in this room.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.28))
                .multilineTextAlignment(.center)
            Button("Add Device") { isShowingAddDevice = true }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }
}

// MARK: - Live Device Dark Row

private struct LiveDeviceDarkRow: View {
    let device: any SmartDevice

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 46, height: 46)
                Image(systemName: device.category.systemImage)
                    .font(.system(size: 19))
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(device.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text(device.category.rawValue)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            Circle()
                .fill(device.reachability == .reachable ? Color(hex: "#6FDBA8") : Color.white.opacity(0.2))
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}
