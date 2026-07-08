import SwiftUI
import SwiftData

// MARK: - Remote Detail View
// Per-remote screen: set the IR bridge address, then tap a button to send its
// IR code over HTTP to that bridge. Adding a button takes a pasted IR code and
// a format; an on-device "learn" capture flow is a future step (needs the
// native Broadlink transport), so codes are entered by hand for now.

struct RemoteDetailView: View {

    @State var viewModel: RemoteViewModel
    let remote: RemoteProfile

    @State private var hostnameField: String
    @State private var newCommandName = ""
    @State private var newCommandCode = ""
    @State private var newCommandFormat: IRFormat = .broadlink

    init(viewModel: RemoteViewModel, remote: RemoteProfile) {
        _viewModel = State(wrappedValue: viewModel)
        self.remote = remote
        _hostnameField = State(initialValue: remote.bridgeHostname ?? "")
    }

    private var commands: [IRCommand] {
        remote.commands.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Form {
            bridgeSection
            buttonsSection
        }
        .navigationTitle(remote.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.isShowingAddCommand = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddCommand) { addCommandSheet }
        .alert("Something went wrong", isPresented: errorAlertBinding) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Please try again.")
        }
    }

    // MARK: - Bridge Address

    private var bridgeSection: some View {
        Section {
            TextField("IR bridge address (e.g. 192.168.1.50)", text: $hostnameField)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .onSubmit { viewModel.setBridgeHostname(hostnameField, on: remote) }
        } header: {
            Text("IR Bridge")
        } footer: {
            Text("Lumen sends IR codes to this address on your local network. Enter your IR blaster's IP or hostname, then tap a button below.")
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttonsSection: some View {
        if commands.isEmpty {
            Section {
                EmptyStateView(
                    icon: "dot.radiowaves.left.and.right",
                    title: "No Buttons",
                    message: "Add a button by pasting an IR code. Once the bridge address is set, tap a button to send it.",
                    action: { viewModel.isShowingAddCommand = true },
                    actionTitle: "Add Button"
                )
                .frame(minHeight: 220)
                .listRowBackground(Color.clear)
            }
        } else {
            Section("Buttons") {
                ForEach(commands, id: \.id) { command in
                    Button {
                        Task { await viewModel.send(command, from: remote) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: command.iconName)
                                .foregroundStyle(Color("MuhaBrown"))
                                .frame(width: 24)
                            Text(command.name)
                                .foregroundStyle(Color("PrimaryText"))
                            Spacer()
                            Image(systemName: "paperplane")
                                .font(.caption)
                                .foregroundStyle(Color("TertiaryText"))
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet { viewModel.deleteCommand(commands[i]) }
                }
            }
        }
    }

    // MARK: - Add Command Sheet

    private var addCommandSheet: some View {
        NavigationStack {
            Form {
                Section("Button") {
                    TextField("Name (e.g. Power)", text: $newCommandName)
                }
                Section("IR Code") {
                    TextField("Paste IR code", text: $newCommandCode, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(1...4)
                    Picker("Format", selection: $newCommandFormat) {
                        ForEach(IRFormat.allCases, id: \.self) { format in
                            Text(format.rawValue.capitalized).tag(format)
                        }
                    }
                }
            }
            .navigationTitle("New Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { resetNewCommand() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addCommand(
                            to: remote,
                            name: newCommandName,
                            code: newCommandCode,
                            format: newCommandFormat
                        )
                        resetNewCommand()
                    }
                    .disabled(!canAddCommand)
                }
            }
        }
        .presentationDetents([.height(320)])
    }

    private var canAddCommand: Bool {
        !newCommandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newCommandCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func resetNewCommand() {
        viewModel.isShowingAddCommand = false
        newCommandName = ""
        newCommandCode = ""
        newCommandFormat = .broadlink
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
}
