import SwiftUI

struct PlannedDeviceRow: View {

    let device: PlannedDevice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.type.iconName)
                .font(.body)
                .foregroundStyle(Color("MuhaBrown"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .font(.body)
                    .foregroundStyle(Color("PrimaryText"))
                if let notes = device.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color("TertiaryText"))
                        .lineLimit(1)
                }
            }

            Spacer()

            StageBadge(stage: device.planningStage)
        }
        .padding(.vertical, 2)
    }
}

struct StageBadge: View {

    let stage: PlanningStage

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: stage.iconName).font(.caption2)
            Text(stage.displayName).font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(stage.color.opacity(0.15), in: Capsule())
        .foregroundStyle(stage.color)
    }
}