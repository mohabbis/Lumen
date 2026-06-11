# Lumen

A calm home companion for iOS.

Lumen builds a local model of your home — rooms, devices, presence, time of day — and surfaces gentle, explainable suggestions instead of silent automations. It controls HomeKit devices when they're present and stays useful when they aren't.

Design references are Apple Design Award–tier apps like Tiimo: low cognitive load, neurodivergent-friendly, explainable. Nothing fires from a tap without a confirmation surface.

---

## Status

Native SwiftUI / SwiftData app, iPhone + iPad. Local-first; CloudKit sync is provisioned but off. 90 unit tests, build clean.

**Shipped**

- Location-aware dashboard ("Welcome Home" / Away Mode with distance)
- Time-of-day ambient palette + "Lumen noticed" contextual cards
- **Now / Next** rhythm card (Tiimo-style daily structure, works without smart devices)
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

## Repository layout

```
Lumen/             # Native iOS app (SwiftUI / SwiftData)
Lumen.xcodeproj/   # Xcode project
LumenTests/        # XCTest target
src/, public/      # Independent React/Vite marketing site
```

The iOS app and the marketing site are independent lanes — each ships on its own cadence.

---

## Running the app

You don't need a physical iPhone — the app runs on the iOS Simulator with mock devices.

**Easiest path:** open `Lumen.xcodeproj` in Xcode, select an **iPhone 16 Pro Max** or **iPad Pro 13-inch (M4)** simulator, press **Cmd+R**.

Signing is automatic for the simulator (no provisioning needed). `AppState.enableLocalPreviewControls` defaults to `true`, so the dashboard populates with rooms and devices even without HomeKit hardware.

**Command line build:**

```sh
xcodebuild -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -configuration Debug build
```

Close Xcode before running CLI builds — the SQLite project lock is exclusive.

---

## Running tests

```sh
xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'
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

---

## Bundle

- Bundle ID: `com.muhome.app`
- Team: `CU67F9EY3Q`
- Minimum: iOS 18+ (uses `@Observable`, SwiftData, modern SwiftUI sheet APIs)

---

## License

Source-available, not yet OSI-licensed. Contact [m.rafiq2006@icloud.com](mailto:m.rafiq2006@icloud.com) for collaboration or use questions.
