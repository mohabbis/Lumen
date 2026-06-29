# Lumen

[![CI](https://github.com/mohabbis/Lumen/actions/workflows/ci.yml/badge.svg)](https://github.com/mohabbis/Lumen/actions/workflows/ci.yml)
[![Last commit](https://img.shields.io/github/last-commit/mohabbis/Lumen)](https://github.com/mohabbis/Lumen/commits)
[![Open issues](https://img.shields.io/github/issues/mohabbis/Lumen)](https://github.com/mohabbis/Lumen/issues)
[![Open PRs](https://img.shields.io/github/issues-pr/mohabbis/Lumen)](https://github.com/mohabbis/Lumen/pulls)
[![Top language](https://img.shields.io/github/languages/top/mohabbis/Lumen)](https://github.com/mohabbis/Lumen)

Lumen is a local-first iOS smart-home companion that turns rooms, scenes, presence, and time of day into calm, explainable routines.

Lumen builds a local model of your home — rooms, devices, presence, time of day — and surfaces gentle, explainable suggestions instead of silent automations. It controls HomeKit devices when they're present and stays useful when they aren't.

Lumen is designed for low cognitive load: calm surfaces, clear explanations, and confirmation before meaningful actions. Nothing fires from a tap without a confirmation surface.

---

## Status

Native SwiftUI / SwiftData app, iPhone + iPad. Local-first; CloudKit sync is gated off pending final provisioning. 90 unit tests, build clean.

## Preview

| Dashboard | Scene Approval | Reasoning View |
|---|---|---|
| `docs/screenshots/dashboard.png` | `docs/screenshots/scene-approval.png` | `docs/screenshots/reasoning-view.png` |

The app also ships with a React/Vite marketing preview in `src/` that recreates the dashboard, reasoning, and scene approval surfaces for web review.

## Launch Readiness

- [x] Native SwiftUI app
- [x] Local preview mode
- [x] HomeKit discovery
- [x] Scene approval flow
- [x] Unit test coverage for core logic
- [ ] Internal TestFlight
- [ ] External beta
- [ ] App Store review

**Shipped**

- Location-aware dashboard ("Welcome Home" / Away Mode with distance)
- Time-of-day ambient palette + "Lumen noticed" contextual cards
- **Now / Next** rhythm card (calm daily-rhythm structure, works without smart devices)
- **Scene approval sheet** (consent before any scene executes, with humanized action list)
- **Lumen reasoning view** (signals behind every suggestion — time, presence, devices, matching scene)
- Geofence-triggered scene automations (arrival/departure, 100 m radius)
- HomeKit device discovery, control, and a local preview mode that runs the UI with mock devices
- SwiftData persistence with versioned schema (V1 → V2 → V3)
- Local notifications for automation triggers

**Not yet**

- Multi-home support
- Matter integration
- On-device reasoning engine (the current "Lumen noticed" surface is rule-based)
- TestFlight beta

---

## Roadmap to launch

Lumen is on a deliberately gradual path from "Not yet" to public release:

1. **Close remaining gaps** — on-device reasoning engine, conversational AI assistant, CloudKit sync hardening.
2. **TestFlight beta** — internal, then external via the marketing site waitlist.
3. **App Store submission** — after beta feedback is incorporated.
4. **Public launch** — iOS App Store, with site copy updated accordingly.
5. **Post-launch** — multi-home support, Matter integration, continued reasoning-quality improvements.

Full month-by-month detail, including a note on how Lumen's roadmap relates to the broader smart-home AI landscape, lives in [`ROADMAP.md`](ROADMAP.md).

---

## Repo Map

```
Lumen/             # Native iOS app
Lumen.xcodeproj/   # Xcode project
LumenTests/        # XCTest suite
src/, public/      # Marketing site
docs/              # Product, design, architecture, and launch notes
```

The iOS app and the marketing site are independent lanes — each ships on its own cadence.

---

## Running the app

You don't need a physical iPhone — the app runs on the iOS Simulator with mock devices.

**Easiest path:** open `Lumen.xcodeproj` in Xcode, select an **iPhone 17 Pro Max** or **iPad Pro 13-inch (M5)** simulator, press **Cmd+R**.

Signing is automatic for the simulator (no provisioning needed). `AppState.enableLocalPreviewControls` defaults to `true`, so the dashboard populates with rooms and devices even without HomeKit hardware.

**Command line build:**

```sh
xcodebuild -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug build
```

Close Xcode before running CLI builds — the SQLite project lock is exclusive.

---

## Running tests

```sh
xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Or **Cmd+U** in Xcode. All tests use an in-memory `ModelContainer` and are timezone-deterministic where dates matter; no simulator state pollution.

Coverage map lives in [`CLAUDE.md`](CLAUDE.md) under the "Tests" section.

---

## Architecture

Protocol-driven MVVM. Three layers:

- **Domain** (`Lumen/Domain/`) — `SmartDevice`, `DeviceCapability`, `SmartHomeBridge` protocols. UI renders only the capabilities a device actually reports.
- **Services** (`Lumen/Services/`) — `@Observable @MainActor` classes; the only places `ModelContext` is touched. `HomeService`, `DeviceService`, `SceneService`, `LocationService`, `NotificationService`, `SensorObservationService`.
- **Features** (`Lumen/Features/`) — SwiftUI views and view models per tab.

A convention: when view code carries logic, lift it into a pure helper `struct` next to the view so it can be unit-tested without SwiftUI. Existing examples: `RhythmTiming`, `SceneActionDescription`, `ReasoningCalculator`, `SceneService.scenesMatching`.

Full architecture notes — including the consent-first data flow for scene execution and the reasoning surface — are in [`CLAUDE.md`](CLAUDE.md).

## Product Docs

- [`docs/product-brief.md`](docs/product-brief.md)
- [`docs/homekit-architecture.md`](docs/homekit-architecture.md)
- [`docs/design-principles.md`](docs/design-principles.md)
- [`docs/test-strategy.md`](docs/test-strategy.md)
- [`docs/launch-plan.md`](docs/launch-plan.md)
- [`docs/beta-tester-guide.md`](docs/beta-tester-guide.md)
- [`docs/manual-qa.md`](docs/manual-qa.md)
- [`docs/release-notes-1.0-build-7.md`](docs/release-notes-1.0-build-7.md)

---

## Bundle

- Bundle ID: `com.muharafiq.lumen`
- Team: `CU67F9EY3Q`
- Minimum: iOS 17+ (uses `@Observable`, SwiftData, modern SwiftUI sheet APIs)

---

## License

Source-available, not yet OSI-licensed. Contact [m.rafiq2006@icloud.com](mailto:m.rafiq2006@icloud.com) for collaboration or use questions.
