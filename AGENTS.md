# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What Lumen is

A calm home companion for iOS. Lumen builds a local model of a home — rooms, devices, presence, time of day — and surfaces gentle, explainable suggestions instead of silent automations. It controls HomeKit devices when they're present and stays useful when they aren't (rhythm/awareness layer works without any smart hardware).

**Audience and tone:** calm, low cognitive load, neurodivergent-friendly. Design references are Apple Design Award–tier apps built for ADHD/autistic and sensory-sensitive users. Not a power-user HomeKit dashboard, not a tinkerer tool.

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

`AGENTS.md` at the repo root is a byte-for-byte mirror of this file — if you update one, update the other so both stay in sync. `.github/workflows/` holds the GitHub CI (`ci.yml` runs the **web** test + build on Node 22 — it does not build the iOS app) plus the Claude PR-assistant and code-review workflows.

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

Most services are `@Observable @MainActor` classes passed through the SwiftUI environment from `MuhomeApp` (see the `.environment(...)` chain in `MuhomeApp.body`). They are the only places that touch `ModelContext`. Services are grouped into subfolders (`Home/`, `Device/`, `Scene/`, `Intelligence/`, `Persistence/`); `LocationService`, `NotificationService`, and `KeychainService` sit at the `Services/` root.

| Service | Path | Owns |
|---------|------|------|
| `HomeService` | `Services/Home/` | Home / Room CRUD, primary-home promotion |
| `DeviceService` | `Services/Device/` | PlannedDevice CRUD; routes `SceneActionSnapshot` to the right bridge |
| `DeviceStateStore` | `Services/Device/` | In-memory live state for all connected devices — rebuilt from bridges on each launch, never persisted |
| `SceneService` | `Services/Scene/` | Scene CRUD, execution, geofence-triggered automation. Owns a cancellable `monitoringTask` for the geofence poller |
| `LocationService` | `Services/` | CLLocationManager wrapper; publishes `GeofenceEvent` when the user crosses the home radius. Gates first-check event emission via `hasCompletedFirstCheck` so launching at home does not fire a spurious arrival |
| `NotificationService` | `Services/` | UNUserNotificationCenter wrapper; called by `SceneService` after automation fires |
| `SensorObservationService` | `Services/Intelligence/` | Subscribes to motion/contact `AsyncStream`s from all capable devices. Wired in `RootView` via `DeviceStateStore.onDevicesDiscovered/onDevicesRemoved` |
| `KeychainService` | `Services/` | Singleton (`KeychainService.shared`) wrapping the Security framework for secure string/data storage. **Not** an `@Observable` environment service — used directly (e.g. for IR-bridge credentials) |

#### Calm-tone surfaces (the consent + explainability layer)

These are the views that distinguish Lumen from a generic HomeKit controller:

- **`Lumen/Components/NowNextCard.swift`** — Calm daily rhythm card on the dashboard. Shows current time block (e.g. "Evening") with a progress bar and the next transition ("Night at 9:00 PM"). Math lives in `RhythmTiming` (calendar-injectable, unit-tested).
- **`Lumen/Features/Scenes/SceneApprovalSheet.swift`** — Sheet that opens when a scene row is tapped. Shows scene name + humanized action list (e.g. "Power · On", "Brightness · 40%"). Confirm or cancel. Humanization lives in `SceneActionDescription` (pure, unit-tested).
- **`Lumen/Features/Home/LumenReasoningView.swift`** — Sheet that opens when the "Lumen noticed" dashboard card is tapped. Shows the signals (time of day, presence, reachable devices, matching scene) behind the current suggestion, with an explicit Apply button. Logic lives in `ReasoningCalculator` (pure, unit-tested).
- **`Lumen/Features/Home/LumenActionView.swift`** — Final consent surface for an ambient suggestion. After the user taps Apply in the reasoning view, this sheet shows the humanized action list ("Lumen will…") for the suggested scene and asks for an explicit Apply/Not now confirmation before the scene fires. Reuses `SceneActionDescription` (the same humanizer as `SceneApprovalSheet`).

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
        → HomeDashboardView.isShowingAction = true
          → LumenActionView renders the suggested scene's action list
            → user taps "Apply"
              → HomeDashboardView.handleLumenSuggestion()  // dismisses both sheets
                → HomeViewModel.executeScene(scene)        // failures stored to viewModel.error
                  → SceneService.execute(scene)
```

This realizes the 4-mode flow shown on lumen.muharafiq.com end-to-end: **Awareness** (dashboard "Lumen noticed" card) → **Reasoning** (`LumenReasoningView` signals) → **Action** (`LumenActionView` confirmation) → **Execution** (`SceneService.execute`). The reasoning view's Apply button advances to the action confirmation rather than executing directly, keeping consent-before-action explicit. `handleLumenSuggestion` executes whatever `suggestedSceneName` resolves to, so the scene that runs is always the one the Action sheet displayed.

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

- Schema is versioned in `MuhomeSchema.swift`: `MuhomeSchemaV1` → `V2` → `V3`, with a lightweight `MuhomeSchemaMigrationPlan`. `PersistenceCoordinator` always uses `MuhomeSchemaV3`.
- The registered `@Model` types (identical across V1–V3 except `ExecutionEvent`, added in V2) are: `Home`, `Room`, `Zone`, `PlannedDevice`, `Scene`, `SceneAction`, `RemoteProfile`, `IRCommand`, `ExecutionEvent`. V2→V3 only drops `@Attribute(.unique)` from `id` fields for CloudKit compatibility; `Home.latitude`/`longitude` were added via SwiftData's inferred nullable-column migration (no new version).
- CloudKit sync is **off** (`PersistenceCoordinator.enableCloudKitSync = false`). The flag is guarded by a test (`PersistenceTests.testCloudKitSyncIsGatedOffForBeta`). Flip only after provisioning `iCloud.com.muhome.app` in the Apple Developer portal.
- The old `MuhomeDataModels.swift` / `SceneModels.swift` legacy-struct files (`MuhaScene`, `MuhaSceneRecord`, etc.) have been **removed**. `TimeOfDay` — the one enum from that era still in use — now lives in its own file, `Lumen/Models/TimeOfDay.swift`. There is no dead legacy schema to avoid anymore.

#### Data models & their homes

SwiftData `@Model` types are split by domain across two roots:

| Location | Models |
|----------|--------|
| `Lumen/Models/Space/` | `Home`, `Room`, `Zone`, `PlannedDevice` (plus value enums `DeviceType`, `RoomType`, `ZoneType`) |
| `Lumen/Models/Analytics/` | `ExecutionEvent` (persisted), `SensorEvent` (in-memory value type, **not** in the schema) |
| `Lumen/Models/` | `TimeOfDay`, `PlanningStage` (planned→commissioned lifecycle enum for `PlannedDevice`) |
| `Lumen/Domain/Models/Automation/` | `Scene`, `SceneAction` |
| `Lumen/Domain/Models/Remote/` | `RemoteProfile`, `IRCommand` |

`Home` owns a cascade relationship to `[Zone]`; `Zone` can hang off either a `Home` (top-level) or a `Room` (sub-zone) with optional normalised `positionX/Y` coordinates.

#### Scaffolded but not yet wired

Some surfaces are persisted in the schema and have view/view-model code, but are **not** reachable from navigation yet. Treat them as in-progress, not dead code — extend rather than delete:

- **IR remote control** (`Features/Remote/`, `Domain/Models/Remote/`): `RemoteProfile` ⟶ `[IRCommand]` model a learnable IR remote (Broadlink/raw codes, optional `bridgeHostname` for an IR blaster). `RemoteListView` + `RemoteViewModel` exist but no tab routes to them yet.
- **Zones** (`Models/Space/Zone.swift`): part of the schema and relationships, but no service or UI surfaces zones yet.

#### Navigation

`RootView` renders an iPhone `TabView` and an iPad `NavigationSplitView` over the same `AppState.Tab` cases: **Home** (`HomeDashboardView`), **Rooms** (`RoomListView`), **Intel** (`DeviceListView`), **Auto** (`SceneListView`), **Settings** (`SettingsView`). Note the "Intel" tab is the device list. The selected tab is driven by `AppState.selectedTab`.

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

Coverage groups (91 tests at time of writing):

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
npm run e2e        # Playwright end-to-end tests
npm run ci         # lint + test + build
```

Single-page React/Vite app — no router, anchor-scroll only. Entry is `src/main.jsx`, which mounts `src/App.jsx` into `#root` in the top-level `index.html` and imports the page styles (`App.css`, `lumen-overrides.css`, `mobile-polish.css`, `architecture-actions.css`). `src/styles.css` is unused. Unit tests run on Vitest (`src/main.test.jsx`, setup in `src/test/setup.js`); end-to-end coverage uses Playwright (`playwright.config.js`). `public/privacy/index.html` is fully self-contained (no React); the `vercel.json` rewrite maps `/privacy` → `/privacy/index.html`.

> The `src/pages/*.astro` files and `src/styles/global.css` are exploratory and **not** part of the Vite build (there is no `astro` dependency or config) — the production site is the React entry above.

---

## Conventions when extending the iOS app

- New service surfaces and view models should follow the `@Observable @MainActor` pattern.
- New views that carry math or rules should extract a pure helper `struct` for testing. See "Testable helper structs" above.
- New SwiftData models live under `Lumen/Models/` (spatial/analytics types) or `Lumen/Domain/Models/` (automation/remote types). One model per file; register it in **all three** schema versions in `MuhomeSchema.swift` (or add a new versioned schema + migration stage if the change isn't lightweight).
- Errors surface through `viewModel.error: (any Error)?`. The dashboard already has an alert binding pattern (`errorAlertBinding`); reuse it on new views rather than swallowing with `try?`.
- Default `AppState.enableLocalPreviewControls = true` should be respected — many tests rely on the local-preview state store path.
- Keep consent-before-action. New tap → action paths route through a confirmation surface (sheet/alert), not direct execution.
