import Foundation
import Observation
import SwiftData

// MARK: - Remote View Model

@MainActor
@Observable
final class RemoteViewModel {

    private let modelContext: ModelContext

    var isShowingAddRemote = false
    var error: (any Error)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func createRemote(name: String, brand: String? = nil, iconName: String = "remote") {
        let remote = RemoteProfile(name: name, deviceBrand: brand, iconName: iconName)
        modelContext.insert(remote)
        do {
            try modelContext.save()
            isShowingAddRemote = false
        } catch {
            self.error = error
        }
    }

    func deleteRemote(_ remote: RemoteProfile) {
        modelContext.delete(remote)
        do { try modelContext.save() }
        catch { self.error = error }
    }
}
