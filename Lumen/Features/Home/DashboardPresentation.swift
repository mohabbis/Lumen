import CoreLocation

struct DashboardSetupPresentation: Equatable {
    let shouldShow: Bool
    let title: String
    let message: String
    let actionTitle: String
    let steps: [DashboardSetupStep]

    init(roomCount: Int, installedDeviceCount: Int, sceneCount: Int) {
        self.shouldShow = roomCount == 0
        self.title = roomCount == 0 ? "Start with one room" : "Your home layout is started"
        self.message = "Name the first room so Lumen can anchor devices, scenes, and suggestions to a real space."
        self.actionTitle = roomCount == 0 ? "Add first room" : "Add another room"
        self.steps = [
            DashboardSetupStep(
                id: "room",
                title: "Create a room",
                detail: "Start with the space you use most.",
                state: roomCount > 0 ? .complete : .current
            ),
            DashboardSetupStep(
                id: "device",
                title: "Add devices",
                detail: "Use preview controls or connect HomeKit.",
                state: installedDeviceCount > 0 ? .complete : (roomCount > 0 ? .current : .pending)
            ),
            DashboardSetupStep(
                id: "scene",
                title: "Review scenes",
                detail: "Suggestions stay explainable and require approval.",
                state: sceneCount > 0 ? .complete : .pending
            )
        ]
    }
}

struct DashboardSetupStep: Equatable, Identifiable {
    enum State: Equatable {
        case complete
        case current
        case pending
    }

    let id: String
    let title: String
    let detail: String
    let state: State
}

struct StatusOverlayPresentation: Equatable {
    let title: String
    let subtitle: String
    let iconName: String
    let tintHex: String
    let tintOpacity: Double

    init(isAtHome: Bool) {
        if isAtHome {
            self.title = "Welcome home"
            self.subtitle = "Lumen is following the home rhythm."
            self.iconName = "house.fill"
            self.tintHex = "#C49A6C"
            self.tintOpacity = 1
        } else {
            self.title = "Away mode"
            self.subtitle = "Home status stays visible while you are away."
            self.iconName = "location.fill"
            self.tintHex = "#FFFFFF"
            self.tintOpacity = 0.72
        }
    }
}

struct LocationPermissionPresentation: Equatable {
    let title: String
    let message: String
    let actionTitle: String

    init?(status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            self.title = "Location is off"
            self.message = "Home and away signals stay available once location access is enabled in Settings."
            self.actionTitle = "Open Settings"
        default:
            return nil
        }
    }
}
