import SwiftUI
import SwiftData

// MARK: - Remote List View

struct RemoteListView: View {

    @State var viewModel: RemoteViewModel
    @Query(sort: \RemoteProfile.sortOrder) private var remotes: [RemoteProfile]
    @State private var newRemoteName = ""
    @State private var newRemoteBrand = ""

    var body: some View {
        Group {
            if remotes.isEmpty {
                EmptyStateView(
                    icon: "remote.fill",
                    title: "No Remotes",
                    message: "Add a remote to control IR devices like TVs and ACs.",
                    action: { viewModel.isShowingAddRemote = true },
                    actionTitle: "Add Remote"
                )
            } else {
                remoteList
            }
        }
        .navigationTitle("Remotes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.isShowingAddRemote = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddRemote) {
            addRemoteSheet
        }
    }

    private var remoteList: some View {
        List {
            ForEach(remotes) { remote in
                HStack(spacing: 12) {
                    Image(systemName: remote.iconName)
                        .font(.body)
                        .foregroundStyle(Color("MuhaBrown"))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(remote.name)
                            .font(.body)
                            .foregroundStyle(Color("PrimaryText"))
                        if let brand = remote.deviceBrand {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(Color("SecondaryText"))
                        }
                    }
                    Spacer()
                    Text("\(remote.commands.count) btn")
                        .font(.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for i in indexSet { viewModel.deleteRemote(remotes[i]) }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var addRemoteSheet: some View {
        NavigationStack {
            Form {
                Section("Remote Details") {
                    TextField("Name (e.g. Living Room TV)", text: $newRemoteName)
                    TextField("Brand (optional)", text: $newRemoteBrand)
                }
            }
            .navigationTitle("New Remote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.isShowingAddRemote = false
                        newRemoteName = ""; newRemoteBrand = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.createRemote(
                            name: newRemoteName,
                            brand: newRemoteBrand.isEmpty ? nil : newRemoteBrand
                        )
                        newRemoteName = ""; newRemoteBrand = ""
                    }
                    .disabled(newRemoteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(260)])
    }
}
