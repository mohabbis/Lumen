# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What Lumen is

A calm home companion for iOS. Lumen builds a local model of a home — rooms, devices, presence, time of day — and surfaces gentle, explainable suggestions instead of silent automations. It controls HomeKit devices when they're present and stays useful when they aren't (rhythm/awareness layer works without any smart hardware).

**Audience and tone:** calm, low cognitive load, neurodivergent-friendly. Design references are Apple Design Award–tier apps like Tiimo. Not a power-user HomeKit dashboard, not a tinkerer tool.

**Consent before action** is a core principle: nothing fires from a tap without a confirmation surface (`SceneApprovalSheet` for direct scene runs, `LumenReasoningView` for ambient suggestions).

---

## Repository layout

| Path | What it is |
|------|-----------|
| `Lumen/` | Native iOS app (Swift / SwiftUI / SwiftData) |
| `Lumen.xcodeproj/` | Xcode project for the iOS app |
| `LumenTests/` | Xcode unit test target |
| `src/` | React/Vite marketing landing page (separate lane — see note below) |
| `public/` | Static assets for the web app |

The iOS app and the marketing site are independent. Changes to one do **not** require touching the other. When working on iOS, do not pull from `src/` to validate claims — the two lanes are kept in sync separately.

---

## iOS app

### Building & running

The project builds and runs on the iOS Simulator. Standard targets are **iPhone 16 Pro Max** and **iPad Pro 13-inch (M4)**.

```bash
# Build via xcodebuild (use the simulator destination — no provisioning needed)
xcodebuild -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -configuration Debug build

# Run all tests
xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'
```

**Easier path:** open `Lumen.xcodeproj` in Xcode and press **Cmd+R** with a simulator selected. Signing is set to automatic (team `CU67F9EY3Q`, bundle ID `com.muhome.app`); the simulator does not need provisioning.

**Note:** `xcodebuild` CLI builds fail with a "database is locked" error while Xcode is open on the same project. Close Xcode first or build from inside Xcode directly.

### Architecture

Protocol-driven MVVM using Swift Observation (`@Observable`) and SwiftData.

#### Core abstractions (`Domain/`)

- `SmartDevice` — protocol every device (real or preview) conforms to. Carries capabilities.
- `DeviceCapability` — protocol hierarchy (`OnOffCapability`, `BrightnessCapability`, etc.). UI renders only the capabilities a device actually reports.
- `SmartHomeBridge` — `Actor` protocol. Bridges (e.g. `HomeKitBridge`) implement this to connect a hardware ecosystem. Bridges emit `DeviceStateChange` via `AsyncStream`.

#### Services (`Services/`)

All services are `@Observable @MainActor` classes passed through the SwiftUI environment from `MuhomeApp`. They are the only places that touch `ModelContext`.

| Service | Owns |
|---------|------|
| `HomeService` | Home / Room CRUD, primary-home promotion |
| `DeviceService` | PlannedDevice CRUD; routes `SceneActionSnapshot` to the right bridge |
| `DeviceStateStore` | In-memory live state for all connected devices — rebuilt from bridges on each launch, never persisted |
| `SceneService` | Scene CRUD, execution, geofence-triggered automation. Owns a cancellable `monitoringTask` for the geofence poller |
| `LocationService` | CLLocationManager wrapper; publishes `GeofenceEvent` when the user crosses the home radius. Gates first-check event emission via `hasCompletedFirstCheck` so launching at home does not fire a spurious arrival |
| `NotificationService` | UNUserNotificationCenter wrapper; called by `SceneService` after automation fires |
| `SensorObservationService` | Subscribes to motion/contact `AsyncStream`s from all capable devices |

#### Calm-tone surfaces (the consent + explainability layer)

These are the views that distinguish Lumen from a generic HomeKit controller:

- **`Lumen/Components/NowNextCard.swift`** — Tiimo-style daily rhythm card on the dashboard. Shows current time block (e.g. "Evening") with a progress bar and the next transition ("Night at 9:00 PM"). Math lives in `RhythmTiming` (calendar-injectable, unit-tested).
- **`Lumen/Features/Scenes/SceneApprovalSheet.swift`** — Sheet that opens when a scene row is tapped. Shows scene name + humanized action list (e.g. "Power · On", "Brightness · 40%"). Confirm or cancel. Humanization lives in `SceneActionDescription` (pure, unit-tested).
- **`Lumen/Features/Home/LumenReasoningView.swift`** — Sheet that opens when the "Lumen noticed" dashboard card is tapped. Shows the signals (time of day, presence, reachable devices, matching scene) behind the current suggestion, with an explicit Apply button. Logic lives in `ReasoningCalculator` (pure, unit-tested).

#### Data flow for a scene execution (consent-first)

```
SceneListView row tap
  → SceneViewModel.requestApproval(scene)
    → SceneApprovalSheet renders
      → user taps Apply
        → SceneViewModel.confirmPending()
          → SceneViewModel.execute(scene)
            → SceneService.execute(scene)
              → scene.asSnapshots() → [SceneActionSnapshot]
              → DeviceService.send(action:) per snapshot
                → DeviceStateStore.applyLocalAction()  // optimistic local update
                → bridge.executeAction()               // real hardware
```

A separate consent path runs from the dashboard's "Lumen noticed" card:

```
LumenNoticedCard tap
  → HomeDashboardView.isShowingReasoning = true
    → LumenReasoningView renders with ReasoningCalculator output
      → user taps "Apply [Scene]"
        → HomeDashboardView.handleLumenSuggestion()
          → HomeViewModel.executeScene(scene)        // failures stored to viewModel.error
            → SceneService.execute(scene)
```

`HomeViewModel.executeScene` is `async` (not `throws`) — errors are written to `viewModel.error` and surfaced by the dashboard's error alert, matching the pattern used by `createHome` / `addRoom`. Do not introduce `try?` swallows in the dashboard control flow; the alert exists to make failures visible.

#### Testable helper structs

A convention: when view code carries non-trivial logic, lift it into a pure `struct` next to the view so it can be unit-tested without spinning up SwiftUI. Examples:

| Struct | Used by | What it computes |
|--------|---------|-----------------|
| `RhythmTiming` | `NowNextCard` | Current-block progress + next-block start date (handles midnight wrap) |
| `SceneActionDescription` | `SceneApprovalSheet` | Humanized (capability, value) pair for a `SceneAction` |
| `ReasoningCalculator` | `LumenReasoningView` | Signal list + suggestion label from ambient state |
| `SceneService.scenesMatching(event:in:)` | `SceneService.handleGeofenceEvent` | Pure routing — which scenes fire for a given event |

Follow this pattern for new feature work.

#### SwiftData persistence (`Services/Persistence/`)

- Schema is versioned: `MuhomeSchemaV1` → `V2` → `V3`. `PersistenceCoordinator` always uses `MuhomeSchemaV3`.
- CloudKit sync is **off** (`PersistenceCoordinator.enableCloudKitSync = false`). The flag is guarded by a test (`PersistenceTests.testCloudKitSyncIsGatedOffForBeta`). Flip only after provisioning `iCloud.com.muhome.app` in the Apple Developer portal.
- `MuhomeDataModels.swift` and `SceneModels.swift` contain **legacy structs** (`MuhaScene`, `MuhaSceneRecord`, etc.) from an older design. They compile but are not wired to any active schema or service — treat as dead code. The `TimeOfDay` enum in `SceneModels.swift` is the exception: it is actively used.

#### Local preview mode

When `AppState.enableLocalPreviewControls` is true, `DeviceStateStore` populates itself from `PlannedDevice` records via `LocalSmartDevice`. This lets the UI run without any real hardware. The `bridgeID == .localPreview` guard in `DeviceService.send()` short-circuits real bridge calls.

The flag defaults to `true`. Tests rely on it indirectly: `DeviceService.addPlannedDevice` upserts a local-preview device into the state store automatically.

#### Geofence automation

`LocationService` detects home arrival/departure within a 100 m radius and publishes a `GeofenceEvent`. It supports both foreground and background monitoring (using region monitoring) so events are received even when the app is closed. `SceneService.startMonitoringGeofenceEvents(from:)` polls this every 0.5 s and auto-executes scenes whose `geofenceTrigger` matches.

- The poller's task handle is stored on `SceneService.monitoringTask`. Calling `startMonitoringGeofenceEvents` again cancels the prior task before starting a new one — no task fan-out.
- `stopMonitoringGeofenceEvents()` exists for explicit teardown.
- During tests, `RootView` skips registering the HomeKit bridge (`if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil`). The poller still starts but has nothing to react to.
- Arrival and departure events trigger a status overlay in `HomeDashboardView` (e.g., “🏠 Welcome Home!” or “🌙 Away Mode”) to inform the user of the detected state change.

### Tests

The `LumenTests` target uses XCTest with an in-memory `ModelContainer` via `PersistenceCoordinator.makeInMemoryContainer()`. Tests are `@MainActor` where they touch services or view models.

Coverage groups (90 tests at time of writing):

| File | Covers |
|------|--------|
| `CommissioningTests` | PlannedDevice ↔ live device link/unlink |
| `PersistenceTests` | CloudKit gate, schema round-trip |
| `HomeServiceTests` | Home/Room CRUD, primary promotion |
| `HomeViewModelTests` | VM derived state, executeScene error surfacing |
| `LocationServiceTests` | At-home detection, geofence event emission, no-spurious-arrival on first check |
| `SceneServiceTests` | Scene CRUD, default seeding idempotency, execute records ExecutionEvent |
| `SceneApprovalTests` | Approval flow (request/cancel/confirm), `SceneActionDescription` humanization |
| `GeofenceRoutingTests` | `scenesMatching` routes events to correctly-triggered scenes |
| `RhythmTests` | `RhythmTiming` block math, midnight wrap |
| `ReasoningTests` | `ReasoningCalculator` signal generation, suggestion labels |
| `RoomViewModelTests` | RoomVM CRUD wrapper |

Run from inside Xcode (Cmd+U) or via the xcodebuild test command above.

---

## Web app (`src/`)

Separate lane. The marketing site at `lumen.muharafiq.com` is built from `src/App.jsx` and `src/App.css`. iOS work in this repo does not depend on the web app, and changes to one should not gate the other.

### Commands

```bash
npm run dev        # dev server on 0.0.0.0:5173
npm run build      # production build → dist/
npm run lint       # ESLint
npm run test       # Vitest (single run)
npm run ci         # lint + test + build
```

Single-page React/Vite app — no router, anchor-scroll only. All components are co-located in `src/App.jsx`; all styles in `src/App.css`. `src/styles.css` is unused. `public/privacy/index.html` is fully self-contained (no React); the `vercel.json` rewrite maps `/privacy` → `/privacy/index.html`.

---

## Conventions when extending the iOS app

- New service surfaces and view models should follow the `@Observable @MainActor` pattern.
- New views that carry math or rules should extract a pure helper `struct` for testing. See "Testable helper structs" above.
- New SwiftData models live under `Lumen/Models/` (or `Lumen/Domain/Models/` for automation/remote types). Do not add to `MuhomeDataModels.swift` or `SceneModels.swift` — both are legacy.
- Errors surface through `viewModel.error: (any Error)?`. The dashboard already has an alert binding pattern (`errorAlertBinding`); reuse it on new views rather than swallowing with `try?`.
- Default `AppState.enableLocalPreviewControls = true` should be respected — many tests rely on the local-preview state store path.
- Keep consent-before-action. New tap → action paths route through a confirmation surface (sheet/alert), not direct execution.
