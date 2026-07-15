import SwiftUI

// MARK: - Pressable Button Style
// A calm, tactile button style: the label eases down slightly and dims while
// pressed, giving immediate physical feedback on tap — the kind of small,
// responsive detail that separates an Apple-tier feel from a flat control.
//
// Honors Reduce Motion by dropping the scale (keeping only the gentle dim), and
// pairs naturally with LumenHaptics at the semantic moment the action fires.
//
// Usage: `.buttonStyle(.pressable)`

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        PressableButtonBody(configuration: configuration, scale: scale)
    }

    private struct PressableButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let scale: CGFloat
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? scale : 1))
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// Tactile press feedback for primary actions: `.buttonStyle(.pressable)`.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
