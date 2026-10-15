import SwiftUI

// MARK: - Lumen Action View
// Compatibility wrapper. Ambient suggestions now use `SceneApprovalSheet` directly
// (same consent surface as the Scenes tab). Kept so older call sites/docs compile.

struct LumenActionView: View {

    let scene: Scene
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        SceneApprovalSheet(
            scene: scene,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}
