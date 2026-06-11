import SwiftUI

// MARK: - Lumen Reasoning View
// Surfaces the signals behind a "Lumen noticed" suggestion: time-of-day,
// presence, distance, reachable devices. Opens as a sheet from the noticed
// card on the dashboard. This is the explainability surface.

struct LumenReasoningView: View {

    let reasoning: LumenReasoning
    var onApply: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            handle
            header
            signalList
            Spacer(minLength: 24)
            footer
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color(hex: "#0E0819").ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Subviews

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 36, height: 4)
            .padding(.bottom, 20)
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: "sparkles")
                    .font(.system(size: 26))
                    .foregroundStyle(Color(hex: "#C49A6C"))
            }
            VStack(spacing: 6) {
                Text("WHY LUMEN NOTICED")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(reasoning.headline)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 24)
    }

    private var signalList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGNALS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.35))

            ForEach(reasoning.signals) { signal in
                signalRow(signal)
            }
        }
    }

    private func signalRow(_ signal: ReasoningSignal) -> some View {
        HStack {
            Circle()
                .fill(signal.weight.tint)
                .frame(width: 6, height: 6)
            Text(signal.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
            Spacer()
            Text(signal.value)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var footer: some View {
        if let apply = onApply, let label = reasoning.suggestionLabel {
            Button(action: apply) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#C49A6C"), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.bottom, 10)
        }
        Button(action: onDismiss) {
            Text(onApply == nil ? "Close" : "Not now")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }
}

// MARK: - Reasoning model

struct LumenReasoning: Equatable {
    let headline: String
    let signals: [ReasoningSignal]
    let suggestionLabel: String?
}

struct ReasoningSignal: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
    let weight: SignalWeight
}

enum SignalWeight: Equatable {
    case high
    case medium
    case low

    var tint: Color {
        switch self {
        case .high:   return Color(hex: "#C49A6C")
        case .medium: return Color.white.opacity(0.55)
        case .low:    return Color.white.opacity(0.3)
        }
    }
}

// MARK: - ReasoningCalculator
// Pure logic: given current ambient state, produce signals + suggestion.
// Lifted out of the view so it can be unit-tested.

struct ReasoningCalculator: Equatable {

    let timeOfDay: TimeOfDay
    let isAtHome: Bool
    let distanceToHome: Double?
    let reachableDevices: Int
    let suggestedSceneName: String?

    var reasoning: LumenReasoning {
        LumenReasoning(
            headline: headline,
            signals: signals,
            suggestionLabel: suggestedSceneName.map { "Apply \($0)" }
        )
    }

    private var headline: String {
        switch timeOfDay {
        case .dawn:      return "Your home is waking with you."
        case .morning:   return "The morning is here."
        case .afternoon: return "The afternoon is steady."
        case .evening:   return "Sunset is moving across your home."
        case .night:     return "Your home is winding down."
        }
    }

    private var signals: [ReasoningSignal] {
        var result: [ReasoningSignal] = []

        result.append(
            ReasoningSignal(
                id: "time",
                label: "Time of day",
                value: timeOfDay.name,
                weight: .high
            )
        )

        result.append(
            ReasoningSignal(
                id: "presence",
                label: "Presence",
                value: presenceValue,
                weight: isAtHome ? .high : .medium
            )
        )

        if reachableDevices > 0 {
            result.append(
                ReasoningSignal(
                    id: "devices",
                    label: "Reachable devices",
                    value: "\(reachableDevices)",
                    weight: .medium
                )
            )
        }

        if let sceneName = suggestedSceneName {
            result.append(
                ReasoningSignal(
                    id: "scene",
                    label: "Matching scene",
                    value: sceneName,
                    weight: .high
                )
            )
        }

        return result
    }

    private var presenceValue: String {
        if isAtHome { return "At home" }
        if let distance = distanceToHome {
            let km = distance / 1000
            return String(format: "%.1f km away", km)
        }
        return "Away"
    }
}
