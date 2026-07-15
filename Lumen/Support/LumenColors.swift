import SwiftUI

// MARK: - Lumen Colors
// A single, named source of truth for Lumen's semantic palette. These three
// colors were previously repeated as raw `Color(hex:)` literals across ~14 view
// files; naming them here keeps the brand consistent and makes a palette change
// a one-line edit instead of a find-and-replace.
//
// Each token is deliberately equal to the exact hex it replaced, so this is a
// behavior-preserving rename. Contextual one-off colors (gradient tints, per-mood
// backgrounds) intentionally stay as inline `Color(hex:)` — only the repeated,
// semantic colors live here.

extension Color {

    /// Warm gold — Lumen's primary accent (highlights, primary CTAs, "Lumen noticed").
    static let lumenAccent = Color(hex: "#C49A6C")

    /// The primary dark app background, and the base stop of the time-of-day gradients.
    static let lumenBackground = Color(hex: "#0E0819")

    /// Success / reachable-device green (online indicators, confirmations).
    static let lumenSuccess = Color(hex: "#6FDBA8")
}
