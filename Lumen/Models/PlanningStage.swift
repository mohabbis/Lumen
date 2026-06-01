import SwiftUI

enum PlanningStage: String, CaseIterable, Codable {
    case planned          = "planned"
    case installed        = "installed"
    case discoveryPending = "discoveryPending"
    case namingPending    = "namingPending"
    case assignmentPending = "assignmentPending"
    case commissioned     = "commissioned"

    var displayName: String {
        switch self {
        case .planned:           return "Planned"
        case .installed:         return "Installed"
        case .discoveryPending:  return "Awaiting Discovery"
        case .namingPending:     return "Needs Name"
        case .assignmentPending: return "Needs Room"
        case .commissioned:      return "Active"
        }
    }

    var iconName: String {
        switch self {
        case .planned:           return "plus.circle"
        case .installed:         return "checkmark.circle"
        case .discoveryPending:  return "magnifyingglass"
        case .namingPending:     return "tag"
        case .assignmentPending: return "arrow.right.circle"
        case .commissioned:      return "bolt.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .planned:           return Color(red: 0.55, green: 0.50, blue: 0.44) // TertiaryText
        case .installed:         return Color(red: 0.20, green: 0.75, blue: 0.35) // OnColor
        case .discoveryPending:  return Color(red: 0.90, green: 0.68, blue: 0.20) // WarningColor
        case .namingPending:     return .blue
        case .assignmentPending: return Color(red: 0.90, green: 0.68, blue: 0.20)
        case .commissioned:      return Color(red: 0.20, green: 0.75, blue: 0.35)
        }
    }
}
