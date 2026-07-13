import SwiftUI

struct AddRoomView: View {

    let onAdd: (String, RoomType, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: RoomType = .livingRoom
    @State private var levelText = ""
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedLevel: Int? {
        Int(levelText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(addRoom)
                    Picker("Type", selection: $type) {
                        ForEach(RoomType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.iconName).tag(t)
                        }
                    }
                    TextField("Floor (optional)", text: $levelText)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Room Details")
                } footer: {
                    Text("Use the name people say at home. Lumen uses rooms to explain suggestions and group devices.")
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addRoom)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }

    private func addRoom() {
        guard !trimmedName.isEmpty else { return }
        onAdd(trimmedName, type, parsedLevel)
        dismiss()
    }
}
