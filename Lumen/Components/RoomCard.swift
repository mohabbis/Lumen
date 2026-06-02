import SwiftUI

struct RoomCard: View {

    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: room.type.iconName)
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "#C49A6C"))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(room.deviceCount == 0 ? "No devices" : "\(room.installedCount) active")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}
