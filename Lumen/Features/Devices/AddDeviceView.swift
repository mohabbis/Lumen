import SwiftUI

struct AddDeviceView: View {

    let onAdd: (String, DeviceType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: DeviceType = .light
    @State private var manufacturer = ""
    @State private var notes = ""
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(addDevice)
                    Picker("Type", selection: $type) {
                        ForEach(DeviceType.allCases, id: \.self) { t in
                            Label(t.displayName, systemImage: t.iconName).tag(t)
                        }
                    }
                } header: {
                    Text("Device Details")
                } footer: {
                    Text("Planned devices become preview controls right away and can be linked to HomeKit hardware later.")
                }
                Section("Optional") {
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Plan a Device")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addDevice)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }

    private func addDevice() {
        guard !trimmedName.isEmpty else { return }
        onAdd(trimmedName, type)
        dismiss()
    }
}
