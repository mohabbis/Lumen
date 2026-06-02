import SwiftUI

// MARK: - Commission Device View
// Links a discovered live device to a PlannedDevice in the home model, completing
// the planning → installed lifecycle. Presented as a sheet from DeviceDetailView.

struct CommissionDeviceView: View {

    let liveDevice: any SmartDevice
    @State var viewModel: DeviceViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                let candidates = viewModel.uncommissionedPlannedDevices()
                if candidates.isEmpty {
                    EmptyStateView(
                        icon: "square.stack.3d.up.slash",
                        title: "No Planned Devices",
                        message: "Add a device to a room first, then link this discovered device to it.",
                        action: nil,
                        actionTitle: nil
                    )
                } else {
                    candidateList(candidates)
                }
            }
            .navigationTitle("Link Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func candidateList(_ candidates: [PlannedDevice]) -> some View {
        List {
            Section {
                LabeledContent("Discovered", value: liveDevice.displayName)
                if let room = liveDevice.roomName {
                    LabeledContent("Reported Room", value: room)
                }
                LabeledContent("Bridge", value: liveDevice.bridgeID.rawValue.capitalized)
            } header: {
                Text("Live Device")
            } footer: {
                Text("Choose the planned device this represents. It will be marked installed and controlled live.")
            }

            Section("Planned Devices") {
                ForEach(candidates, id: \.id) { planned in
                    Button {
                        viewModel.commission(planned, to: liveDevice)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: planned.type.iconName)
                                .foregroundStyle(Color("MuhaBrown"))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(planned.displayName)
                                    .foregroundStyle(Color("PrimaryText"))
                                if let room = planned.room?.name {
                                    Text(room)
                                        .font(.caption)
                                        .foregroundStyle(Color("SecondaryText"))
                                }
                            }
                            Spacer()
                            Image(systemName: "link")
                                .font(.caption)
                                .foregroundStyle(Color("SecondaryText"))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
