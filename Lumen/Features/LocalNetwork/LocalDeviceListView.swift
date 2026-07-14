import SwiftUI
import SwiftData

// MARK: - Local Device List View
// Settings → Local Devices. Authors LocalDeviceRecords that drive the
// LocalNetworkBridge — the "control devices Apple Home can't see" surface.

struct LocalDeviceListView: View {

    @Environment(LocalDeviceService.self) private var service
    @Query(sort: \LocalDeviceRecord.sortOrder) private var devices: [LocalDeviceRecord]

    @State private var isShowingAdd = false
    @State private var newName = ""
    @State private var newAddress = ""
    @State private var newKind: LocalDeviceKind = .shellySwitch
    @State private var newChannel = 0

    var body: some View {
        Group {
            if devices.isEmpty {
                EmptyStateView(
                    icon: "wifi.router",
                    title: "No Local Devices",
                    message: "Add a Shelly switch or dimmer on your Wi-Fi to control it from Lumen — no cloud, no Apple Home needed.",
                    action: { isShowingAdd = true },
                    actionTitle: "Add Device"
                )
            } else {
                deviceList
            }
        }
        .navigationTitle("Local Devices")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $isShowingAdd) { addSheet }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { service.error != nil },
                set: { if !$0 { service.error = nil } }
            )
        ) {
            Button("OK", role: .cancel) { service.error = nil }
        } message: {
            Text(service.error?.localizedDescription ?? "")
        }
    }

    private var deviceList: some View {
        List {
            ForEach(devices, id: \.id) { device in
                NavigationLink {
                    LocalDeviceDetailView(record: device)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: device.kind == .shellyDimmer ? "lightbulb" : "power")
                            .font(.body)
                            .foregroundStyle(Color("MuhaBrown"))
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.displayName)
                                .font(.body)
                                .foregroundStyle(Color("PrimaryText"))
                            Text("\(device.kind.displayName) · \(device.address)")
                                .font(.caption)
                                .foregroundStyle(Color("SecondaryText"))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                for i in indexSet { service.deleteDevice(devices[i]) }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Device") {
                    TextField("Name (e.g. Porch Light)", text: $newName)
                    TextField("Address (e.g. 192.168.1.50)", text: $newAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Type") {
                    Picker("Kind", selection: $newKind) {
                        ForEach(LocalDeviceKind.allCases, id: \.self) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    Stepper("Channel: \(newChannel)", value: $newChannel, in: 0...8)
                }
            }
            .navigationTitle("New Local Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { resetAndDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        service.addDevice(
                            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
                            address: newAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                            kind: newKind,
                            channel: newChannel
                        )
                        resetAndDismiss()
                    }
                    .disabled(!canAdd)
                }
            }
        }
        .presentationDetents([.height(360)])
    }

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !newAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func resetAndDismiss() {
        isShowingAdd = false
        newName = ""; newAddress = ""; newKind = .shellySwitch; newChannel = 0
    }
}
