import SwiftUI

struct AddDeviceView: View {

    let onAdd: (String, DeviceType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: DeviceType = .light
    @State private var manufacturer = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Device Details") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    Picker("Type", selection: $type) {
                        ForEach(DeviceType.allCases, id: \.self) { t in
                            Label(t.displayName, systemImage: t.iconName).tag(t)
                        }
                    }
                }
                Section("Optional") {
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Plan a Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, type)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
