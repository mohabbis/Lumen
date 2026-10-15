import Foundation

// MARK: - LumenSuggestionConsent
// Pure routing for the dashboard suggestion path.
// Reasoning explains; SceneApprovalSheet consents; execution uses the approved scene.

enum LumenSuggestionConsent {

    /// Scene that should enter `SceneApprovalSheet` after Apply on the reasoning surface.
    static func sceneForApproval(suggestedName: String?, in scenes: [Scene]) -> Scene? {
        guard let suggestedName else { return nil }
        let target = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return nil }
        return scenes.first { $0.name.caseInsensitiveCompare(target) == .orderedSame }
    }
}
