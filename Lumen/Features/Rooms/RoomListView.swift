import SwiftUI

// MARK: - Room List View

struct RoomListView: View {

    @State var viewModel: RoomViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            Color.lumenBackground.ignoresSafeArea()

            if viewModel.rooms.isEmpty {
                emptyState
            } else {
                scrollContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.isShowingAddRoom) {
            AddRoomView { name, type, level in
                viewModel.addRoom(name: name, type: type, level: level)
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    Text("ALL ROOMS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(Color.white.opacity(0.35))

                    let columns = sizeClass == .regular
                        ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                        : [GridItem(.flexible()), GridItem(.flexible())]

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.rooms, id: \.id) { room in
                            NavigationLink(destination: RoomDetailView(room: room, viewModel: viewModel)) {
                                RoomCard(room: room)
                            }
                            .buttonStyle(.plain)
                        }
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
                Text("LUMEN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text("Rooms")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button { viewModel.isShowingAddRoom = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
            Spacer()
            DarkEmptyStateView(
                icon: "door.left.hand.open",
                title: "Start with one room",
                message: "Rooms give Lumen enough context to keep devices, scenes, and suggestions easy to review.",
                guidance: [
                    "Use the space you spend time in most.",
                    "Add planned devices after the room exists.",
                    "Lumen will keep suggestions tied to named spaces."
                ],
                actionTitle: "Add Room",
                action: { viewModel.isShowingAddRoom = true }
            )
            .padding(.horizontal, 20)
            Spacer()
        }
    }
}
