import SwiftUI

struct AddRoomView: View {

    let onAdd: (String, RoomType, Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: RoomType = .livingRoom
    @State private var levelText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Room Details") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(RoomType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.iconName).tag(t)
                        }
                    }
                    TextField("Floor (optional)", text: $levelText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let level = Int(levelText)
                        onAdd(name, type, level)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
