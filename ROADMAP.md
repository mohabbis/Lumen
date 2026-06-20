# Roadmap

Last updated: June 2026.

Lumen is a solo/small-team indie iOS project (team `CU67F9EY3Q`, bundle ID `com.muhome.app`). This roadmap is intentionally conservative — phases can slip, and that's fine; shipping a calm, trustworthy app matters more than hitting a date.

## Phase 1 — Close out the "Not yet" list (June – August 2026)

- **On-device reasoning engine** — move "Lumen noticed" from rule-based (`ReasoningCalculator`) toward a lightweight on-device model or scored heuristic layer. Must stay explainable: every suggestion still needs a signal list a person can read and disagree with.
- **AI assistant (conversational layer)** — ship the "describe it, Lumen proposes, you approve" flow shown in the marketing site's AI section. Text input first; voice later if at all.
- **CloudKit sync hardening** — stabilize the SwiftData schema (V3) and sync path ahead of beta (currently off — `PersistenceCoordinator.enableCloudKitSync = false`).

## Phase 2 — TestFlight beta (September 2026)

- Internal TestFlight build, then external beta via waitlist signups collected on the marketing site.
- Priorities: crash-free sessions, geofence reliability, scene-approval flow clarity, and onboarding for non-technical/neurodivergent users specifically — this is where low-cognitive-load framing gets tested for real, not just asserted in copy.
- Collect structured feedback via short in-app prompts, not long surveys — matches the product's own low-cognitive-load principle.

## Phase 3 — App Store submission (October – November 2026)

- Address beta feedback; lock scope — resist adding automation-parity features under launch pressure (see "Competitive watch" below).
- App Store metadata, screenshots, privacy nutrition label, age rating.
- Submit for review; budget 1–2 review cycles for rejections/clarifications.

## Phase 4 — Public launch (target: December 2026 / Q1 2027)

- Public App Store availability.
- Marketing site updates: swap "Coming soon — iOS private beta" pill and waitlist CTA for "Download on the App Store."
- Light outreach to neurodivergent communities, ADHD/autism productivity spaces, and Tiimo-adjacent audiences — rather than broad tech press. Matches the niche positioning, not a mass-market launch.

## Phase 5 — Post-launch iteration (ongoing)

- Multi-home support, Matter integration — not required for v1.
- Expand the reasoning surface based on real usage signals.
- Revisit on-device model quality with real (anonymized, opt-in) usage data if/when that becomes feasible without compromising the local-first posture.

## Competitive watch

The broader smart-home market — other HomeKit-focused apps and platform-level AI expected in upcoming iOS releases — is moving toward fully automatic AI: agents that act on a user's behalf with little or no per-action confirmation. That's a reasonable bet for those products and platforms.

Lumen's bet is the opposite: explainability and mandatory consent are the product, not a missing feature. As the market converges on "more automatic," the gap between "automatic" and "explained, approved, calm" gets more visible — that gap is the moat. Roadmap decisions should protect it: **do not add an "auto-apply without confirmation" mode, even as a power-user opt-in, without revisiting this document first.**
