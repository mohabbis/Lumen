import SwiftUI

// MARK: - Local Device Detail View
// Edit a single local device's address, kind, and channel. Changes save through
// LocalDeviceService, which re-registers the bridge so control reflects edits.

struct LocalDeviceDetailView: View {

    @Environment(LocalDeviceService.self) private var service
    @Environment(\.dismiss) private var dismiss

    let record: LocalDeviceRecord

    @State private var address: String = ""
    @State private var kind: LocalDeviceKind = .shellySwitch
    @State private var channel: Int = 0

    var body: some View {
        Form {
            Section("Address") {
                TextField("IP or hostname", text: $address)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { service.setAddress(address, on: record) }
            }

            Section("Type") {
                Picker("Kind", selection: $kind) {
                    ForEach(LocalDeviceKind.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .onChange(of: kind) { _, newValue in service.setKind(newValue, on: record) }

                Stepper("Channel: \(channel)", value: $channel, in: 0...8)
                    .onChange(of: channel) { _, newValue in service.setChannel(newValue, on: record) }
            }

            Section {
                Button(role: .destructive) {
                    service.deleteDevice(record)
                    dismiss()
                } label: {
                    Text("Remove Device")
                }
            }
        }
        .navigationTitle(record.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            address = record.address
            kind = record.kind
            channel = record.channel
        }
    }
}
