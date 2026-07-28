# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What Lumen is

A calm home companion for iOS. Lumen builds a local model of a home — rooms, devices, presence, time of day — and surfaces gentle, explainable suggestions instead of silent automations. It controls HomeKit devices when they're present and stays useful when they aren't (rhythm/awareness layer works without any smart hardware).

**Audience and tone:** calm, low cognitive load, consent-before-action. Design references are Apple Design Award-tier apps built for low-stress daily planning, applied to the home. Not a power-user HomeKit dashboard, not a tinkerer tool. **Competitive benchmark (internal only, never in public copy):** Controller for HomeKit — Lumen wins on calm, explainability, and consent-before-action, not toggle density.

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

The project builds and runs on the iOS Simulator. Standard targets are **iPhone 17 Pro Max** and **iPad Pro 13-inch (M5)**.

```bash
# Build via xcodebuild (use the simulator destination — no provisioning needed)
xcodebuild -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug build

# Run all tests
xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

**Easier path:** open `Lumen.xcodeproj` in Xcode and press **Cmd+R** with a simulator selected. Signing is set to automatic (team `CU67F9EY3Q`, bundle ID `com.muharafiq.lumen`); the simulator does not need provisioning.

**Note:** `xcodebuild` CLI builds fail with a "database is locked" error while Xcode is open on the same project. Close Xcode first or build from inside Xcode directly.

### Architecture

Protocol-driven MVVM using Swift Observation (`@Observable`) and SwiftData.

#### Core abstractions (`Domain/`)

- `SmartDevice` — protocol every device (real or preview) conforms to. Carries capabilities.
- `DeviceCapability` — protocol hierarchy (`OnOffCapability`, `BrightnessCapability`, etc.). UI renders only the capabilities a device actually reports.
- `SmartHomeBridge` — `Actor` protocol. Bridges (e.g. `HomeKitBridge`) implement this to connect a hardware ecosystem. Bridges emit `DeviceStateChange` via `AsyncStream`.

#### Services (`Services/`)

Most services are `@Observable @MainActor` classes passed through the SwiftUI environment from `LumenApp` (see the `.environment(...)` chain in `LumenApp.body`). They are the only places that touch `ModelContext`. Services are grouped into subfolders (`Home/`, `Device/`, `Scene/`, `Intelligence/`, `Persistence/`); `LocationService`, `NotificationService`, and `KeychainService` sit at the `Services/` root.

| Service | Path | Owns |
|---------|------|------|
| `HomeService` | `Services/Home/` | Home / Room CRUD, primary-home promotion |
| `DeviceService` | `Services/Device/` | PlannedDevice CRUD; routes `SceneActionSnapshot` to the right bridge |
| `DeviceStateStore` | `Services/Device/` | In-memory live state for all connected devices — rebuilt from bridges on each launch, never persisted |
| `SceneService` | `Services/Scene/` | Scene CRUD, execution, geofence-triggered + daily-schedule automation. Owns cancellable `monitoringTask` (geofence poller) and `scheduleTask` (schedule poller) |
| `LocationService` | `Services/` | CLLocationManager wrapper; publishes `GeofenceEvent` when the user crosses the home radius. Gates first-check event emission via `hasCompletedFirstCheck` so launching at home does not fire a spurious arrival |
| `NotificationService` | `Services/` | UNUserNotificationCenter wrapper; called by `SceneService` after automation fires |
| `SensorObservationService` | `Services/Intelligence/` | Subscribes to motion/contact `AsyncStream`s from all capable devices. Wired in `RootView` via `DeviceStateStore.onDevicesDiscovered/onDevicesRemoved` |
| `RemoteService` | `Services/Remote/` | Sends IR commands to a user-configured bridge over HTTP via an injectable `IRTransport` (default `HTTPIRTransport`). Standalone, **not** a `SmartHomeBridge` — IR is fire-and-forget |
| `LocalDeviceService` | `Services/LocalNetwork/` | `LocalDeviceRecord` CRUD; keeps the `LocalNetworkBridge` in sync by republishing a thread-safe config snapshot and re-registering the bridge through `DeviceService` on every change |
| `KeychainService` | `Services/` | Singleton (`KeychainService.shared`) wrapping the Security framework for secure string/data storage. **Not** an `@Observable` environment service — used directly when a feature needs secure storage |

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
| `ReasoningCalculator` | `LumenReasoningView` | Signal list + suggestion label from ambient state (incl. confidence / habit signals from the scored layer) |
| `SuggestionEngine` | `HomeDashboardView` | Scored-heuristic ranking of scenes → the "Lumen noticed" suggestion + explainable factors (see below) |
| `SceneService.scenesMatching(event:in:)` | `SceneService.handleGeofenceEvent` | Pure routing — which scenes fire for a given event |
| `ScheduleTiming` / `SceneService.scenesDue(at:in:lastFired:)` | `SceneService` schedule poller | Pure: whether a daily-schedule scene is due now (grace window, no same-day refire, midnight-safe) |

Follow this pattern for new feature work.

#### Scored suggestion layer (`Services/Intelligence/SuggestionEngine.swift`)

The "Lumen noticed" dashboard suggestion is produced by `SuggestionEngine`, a pure, testable scored-heuristic layer (ROADMAP Phase 1 — "move `ReasoningCalculator` toward a scored heuristic layer, staying explainable"). It replaced the old hardcoded time-of-day → scene switch in `HomeDashboardView`.

- **Inputs** (all value types, no SwiftData/SwiftUI): `timeOfDay`, `presence` (`PresenceState`), `reachableDevices`, `hourOfDay`, and `[SuggestionCandidate]`. The dashboard builds candidates from `@Query`'d `Scene`s + `ExecutionEvent` history (runs bucketed by `hourOfDay`, matched by denormalized `sceneName`).
- **Scoring** is additive and capped at 1.0: time-of-day keyword affinity (`0.45`), habit strength from history in a ±1h wrap-around window (`0.12 × runs`, capped `0.4`), presence/geofence alignment (away+`onDeparture` `0.3`, home+`onArrival` `0.2`), favorite (`0.1`), device readiness (`0.1`).
- **Output**: `topSuggestion()` returns the highest-confidence `SceneSuggestion` (name + confidence + `habitRuns` + `[SuggestionFactor]`), or `nil` when nothing clears `surfaceThreshold` (`0.2`) — so Lumen stays quiet rather than nudge on a hunch. `rankedSuggestions()` is deterministic (confidence, then run volume, then name).
- **Explainability**: the top suggestion's `confidence` and `habitRuns` flow into `ReasoningCalculator` as extra signals, so `LumenReasoningView` shows the scored layer's reasoning, not just raw ambient state. Every factor is a human-readable reason.
- Tested by `SuggestionEngineTests` (scoring, threshold, midnight wrap, presence, determinism, explainability).

#### SwiftData persistence (`Services/Persistence/`)

- Schema is versioned in `LumenSchema.swift`: `LumenSchemaV1` → `V2` → `V3` → `V4`, with a lightweight `LumenSchemaMigrationPlan`. `PersistenceCoordinator` always uses `LumenSchemaV4`.
- The registered `@Model` types are: `Home`, `Room`, `Zone`, `PlannedDevice`, `Scene`, `SceneAction`, `RemoteProfile`, `IRCommand`, `ExecutionEvent` (added in V2), `LocalDeviceRecord` (added in V4). V2→V3 only drops `@Attribute(.unique)` from `id` fields for CloudKit compatibility; V3→V4 adds the `LocalDeviceRecord` table (additive/lightweight). `Home.latitude`/`longitude`, and later `RemoteProfile.transportKindRaw`/`broadlinkMAC`/`broadlinkDeviceType`, were added via SwiftData's inferred nullable-column migration (no new version).
- CloudKit sync is **off** (`PersistenceCoordinator.enableCloudKitSync = false`). The flag is guarded by a test (`PersistenceTests.testCloudKitSyncIsGatedOffForBeta`). Flip only after provisioning `iCloud.com.muharafiq.lumen` in the Apple Developer portal.
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
| `Lumen/Domain/Models/LocalNetwork/` | `LocalDeviceRecord` (authoring record for a local-network device → `LocalDeviceConfig`) |

`Home` owns a cascade relationship to `[Zone]`; `Zone` can hang off either a `Home` (top-level) or a `Room` (sub-zone) with optional normalised `positionX/Y` coordinates.

#### Scaffolded but not yet wired

Some surfaces are persisted in the schema and have view/view-model code, but are **not** reachable from navigation yet. Treat them as in-progress, not dead code — extend rather than delete:

- **Zones** (`Models/Space/Zone.swift`): part of the schema and relationships, but no service or UI surfaces zones yet.

#### Local-network devices (`Integrations/LocalNetwork/`)

The second real `SmartHomeBridge` alongside HomeKit — the "control devices Apple Home can't see" surface (Home Assistant / Homebridge cover the same need). `LocalNetworkBridge` (an `actor`) reaches user-configured LAN devices over their local HTTP APIs — no cloud, no account, staying local-first. Because it registers through `DeviceService.registerBridge` and routes by `BridgeID` (`.localNetwork`), these devices flow through the exact same `DeviceStateStore` → capability UI → scene pipeline as HomeKit, with **no view changes**.

The seam is `Integrations/LocalNetwork/LocalDeviceTransport.swift`, which passes value types only (`LocalTarget` / `LocalDeviceCommand` / `LocalDeviceReading`, never a model), mirroring `IRTransport`. One transport conforms today:
- **`ShellyGen2Transport`** — Shelly Gen2 RPC over local HTTP (`GET /rpc/Switch.Set`, `Light.Set`, `*.GetStatus`). URL-building and JSON-parsing are pure static helpers (`normalizedBaseURL`, `setURL`, `statusURL`, `parseReading`), unit-tested without networking exactly like `HTTPIRTransport`. The protocol-agnostic `LocalComponent` (`relay`/`light`) keeps the seam vendor-neutral, so Tasmota/ESPHome/generic-REST can conform later.

`LocalDeviceKind` maps a device to its component + capability set (`shellySwitch` → on/off; `shellyDimmer` → on/off + brightness). Unlike HomeKit there is no OS authorization gate and no push channel — local HTTP is read on demand, so the state stream stays open for a future poller but only emits an echo after an executed action. The bridge is driven by injected `[LocalDeviceConfig]` + a transport factory, so the whole vertical is testable without a network.

**Wired and reachable via Settings → Local Devices.** `LocalDeviceRecord` (`@Model`, schema V4) persists the user-authored devices; `LocalDeviceService` (`@Observable @MainActor`) owns their CRUD and keeps the bridge in sync — on any change it republishes a thread-safe `LocalDeviceConfigProvider` snapshot and **re-registers** the bridge through `DeviceService` (so added devices are discovered and removed ones pruned). `LocalDeviceListView` → `LocalDeviceDetailView` author name/address/kind/channel. The bridge is registered in `RootView.bootstrap` (behind the same `XCTest` guard as HomeKit) via `LocalDeviceService.reloadBridge()`.

Tests: pure Shelly codec (vs crafted URLs/JSON) + bridge/device/capability flow (vs a fake `LocalDeviceTransport`) are covered by `LumenTests/LocalNetworkTests.swift`; `LocalDeviceService` CRUD → bridge (re)registration by `LumenTests/LocalDeviceServiceTests.swift`. Unlike IR, this **is** a `SmartHomeBridge` — local devices have controllable state and belong in the device/scene pipeline.

#### IR remotes (`Features/Remote/`, `Integrations/IR/`, `Domain/Models/Remote/`)

Wired and reachable via **Settings → Remotes**. `RemoteProfile` ⟶ `[IRCommand]` model a remote (Broadlink/pronto/raw/nec/samsung codes, a `bridgeHostname` for the blaster, and a `transportKind` + optional `broadlinkMAC`/`broadlinkDeviceType`). `RemoteListView` → `RemoteDetailView` lets you pick a transport, set the address, add buttons, and tap to send. Sending/learning goes through `RemoteViewModel` → `RemoteService` (routes by `transportKind`) → an `IRTransport`.

Two transports conform to the seam (`Integrations/IR/IRTransport.swift`, which passes an `IRHost` value, never a model):
- **`HTTPIRTransport`** — POST `<bridge>/send` with `{ "format", "code" }` to a user-run bridge. Pure `normalizedEndpoint(from:)` / `makeRequest(endpoint:code:format:)` helpers.
- **`BroadlinkTransport`** — native RM blaster over UDP (`actor`, `Integrations/IR/Broadlink/`). The byte-exact protocol (AES-128-CBC via `CommonCrypto`, checksums, auth/send/learn/discovery framing) lives in the pure `BroadlinkProtocol` codec; socket I/O is isolated behind the `UDPChannel` seam (`NWUDPChannel` uses `Network.framework`). It also conforms to `IRLearningTransport`, so `RemoteDetailView`'s **Learn** button captures a code from a physical remote. Device MAC/type come from a targeted discovery "hello" to the entered IP (broadcast auto-discovery is a follow-up).

Tests: the codec (vs crafted vectors) and the actor (vs a fake `UDPChannel`) are covered by `LumenTests/BroadlinkTests.swift`; transport routing + learn-capability by `RemoteIRTests`. The native protocol/socket and on-device Broadlink send/learn are verified on real hardware (not in CI) — see `docs/manual-qa.md`. Deliberately **not** a `SmartHomeBridge` — IR is fire-and-forget with no state stream, so it stays out of the device/scene pipeline.

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

#### Schedule automation

A scene can carry a daily schedule (`Scene.scheduleMinutesSinceMidnight: Int?`, nullable → inferred migration, no schema bump). `SceneService.startMonitoringScheduledScenes()` runs a `scheduleTask` poller (30 s tick) that fires due scenes via the same `execute(_:)` path and posts a notification. **Scheduled scenes fire directly** — the user set the time ahead of time, which is the consent — a deliberate decision logged in `ROADMAP.md` (distinct from the forbidden auto-apply-on-a-hunch; inferred `SuggestionEngine` suggestions stay confirmation-gated). Purity lives in `ScheduleTiming` (grace window so a missed schedule doesn't fire stale; no same-day refire) and `SceneService.scenesDue(...)`. Authored in `SceneDetailView`'s automation section (toggle + `DatePicker`), persisted via `SceneService.setSchedule(...)`. The poller starts in `RootView.bootstrap` next to the geofence poller.

### Tests

The `LumenTests` target uses XCTest with an in-memory `ModelContainer` via `PersistenceCoordinator.makeInMemoryContainer()`. Tests are `@MainActor` where they touch services or view models.

Coverage groups (~195 tests at time of writing):

`TestDoubles.swift` holds the shared test doubles — `FakeSmartHomeBridge` (in-memory `SmartHomeBridge` actor: records executed actions, vends a device set, feeds a live state stream), `TestSmartDevice` (configurable `bridgeID`/`reachability`, unlike `LocalSmartDevice`), stream-driven `FakeMotionCapability`/`FakeContactCapability`, and async polling helpers (`waitUntil`, `settle`, `waitForStreamOpen`). Use these rather than re-rolling bridge/device fakes per suite.

| File | Covers |
|------|--------|
| `CommissioningTests` | PlannedDevice ↔ live device link/unlink |
| `DeviceStateStoreTests` | `applyLocalAction` value clamping + implicit power, scene-preset mapping (`applyLocalScenePreset`), `syncLocalPreviewDevices` stale cleanup, and bridge lifecycle (discover→merge→notify, disconnect, live state stream, authorization failure) |
| `DeviceServiceRoutingTests` | `send(action:)` routing — bridge forwarding when reachable, `.localPreview` short-circuit, and the `deviceUnreachable` / `bridgeNotFound` / `deviceNotFound` error branches |
| `SensorObservationServiceTests` | Motion/contact event recording, 200-event ring-buffer cap, per-capability subscription dedup, targeted/global cancellation, re-subscription after stream termination |
| `PersistenceTests` | CloudKit gate, schema round-trip |
| `HomeServiceTests` | Home/Room CRUD, primary promotion, home coordinates |
| `HomeViewModelTests` | VM derived state, executeScene error surfacing |
| `LocationServiceTests` | At-home detection, geofence event emission, no-spurious-arrival on first check |
| `SceneServiceTests` | Scene CRUD, default seeding idempotency, execute records ExecutionEvent |
| `SceneApprovalTests` | Approval flow (request/cancel/confirm), `SceneActionDescription` humanization |
| `SceneActionBuilderTests` | Eligible-device filtering (read-only exclusion), sorted controllable-capability options, default payload per capability |
| `GeofenceRoutingTests` | `scenesMatching` routes events to correctly-triggered scenes |
| `ScheduleTests` | `ScheduleTiming` due-logic (grace window, no same-day refire, next-day, midnight) + `SceneService.scenesDue` routing |
| `RhythmTests` | `RhythmTiming` block math, midnight wrap |
| `ReasoningTests` | `ReasoningCalculator` signal generation, suggestion labels, confidence/habit signals from the scored layer |
| `SuggestionEngineTests` | `SuggestionEngine` scoring, surface threshold, ±1h midnight-wrap habit window, presence/geofence boost, deterministic ranking, explainable factors |
| `RoomViewModelTests` | RoomVM CRUD wrapper |
| `RemoteIRTests` | IR endpoint normalization, HTTP request building, `RemoteService` transport routing + learn-capability (fake transports), `RemoteViewModel` command/hostname/transport CRUD |
| `BroadlinkTests` | Broadlink codec vs crafted vectors (checksum, AES round-trip, packet framing, auth, IR/learn/discovery payloads) + `BroadlinkTransport` actor flow vs a fake `UDPChannel` (send, learn, timeout) |
| `LocalNetworkTests` | Shelly Gen2 codec (URL building, brightness scaling, status parsing, address normalization) + `LocalNetworkBridge`/device/capability flow vs a fake `LocalDeviceTransport` (discover, reachability probe, action routing, device lookup) |
| `LocalDeviceServiceTests` | `LocalDeviceService` CRUD → bridge (re)registration: add surfaces a device in the store, delete prunes it, kind/address edits republish, all vs a stub transport |
| `DashboardPresentationTests` | Dashboard notice / presentation helpers |
| `SensoryProfileTests` | Sensory profile defaults and persistence helpers |

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
npm run ci         # lint + test + build + e2e
```

Single-page React/Vite app — no router, anchor-scroll only. Entry is `src/main.jsx`, which mounts `src/App.jsx` into `#root` in the top-level `index.html` and imports the page styles (`App.css`, `lumen-overrides.css`, `mobile-polish.css`; `App.jsx` also imports `theme.css` and `simulator.css`). `src/styles.css` is unused if present. The hero embeds an interactive iOS simulator (`src/InteractivePhone.jsx`) that mirrors the native app's surfaces — all five tabs (Home rhythm/stats/rooms/"Lumen noticed", Rooms→room→device drill-down, Intel device list, Auto scenes, Settings incl. the Sensory Profile) and the consent flow (Awareness → Reasoning → Action → Execution). Its markup deliberately reuses the app's copy, seeded scenes, and dark palette; `simulator.css` holds the styles the earlier demo didn't cover. Keep it in step with the Swift UI when that changes. The same app UI (the shared `AppShell`) also powers a **full-screen mode** — `FullscreenApp`, launched from the hero's "Open the app full screen" button, fills the viewport (edge-to-edge on phones, a centered phone column on desktop) sharing one `PhoneProvider` state. Running a scene applies its light preset to every light and tints the dashboard (`activeSceneAmbient`), and the Rooms `+` opens an Add-Device sheet (mirrors `AddDeviceView`) that adds a planned device to the room. Unit tests run on Vitest (`src/main.test.jsx`, setup in `src/test/setup.js`); end-to-end coverage uses Playwright (`playwright.config.js`, `testDir: ./e2e`). `public/privacy/index.html` is fully self-contained (no React); the `vercel.json` rewrite maps `/privacy` → `/privacy/index.html`.

Waitlist validation/delivery logic (`normalizeWaitlistPayload`, `isValidWaitlistEmail`, `postWebhook`/`deliverWaitlist`) is factored into `lib/waitlist.js` and shared by both sides of the submit path: `api/waitlist.js` (the Vercel serverless handler) imports it server-side, and `src/waitlistSubmit.js` (the browser-side submit + provider-fallback chain) imports `DEFAULT_TO_EMAIL` from it. `lib/waitlist.test.js` covers the shared module directly.

---

## Conventions when extending the iOS app

- New service surfaces and view models should follow the `@Observable @MainActor` pattern.
- New views that carry math or rules should extract a pure helper `struct` for testing. See "Testable helper structs" above.
- New SwiftData models live under `Lumen/Models/` (spatial/analytics types) or `Lumen/Domain/Models/` (automation/remote types). One model per file; register it in **all three** schema versions in `LumenSchema.swift` (or add a new versioned schema + migration stage if the change isn't lightweight).
- Errors surface through `viewModel.error: (any Error)?`. The dashboard already has an alert binding pattern (`errorAlertBinding`); reuse it on new views rather than swallowing with `try?`.
- Default `AppState.enableLocalPreviewControls = true` should be respected — many tests rely on the local-preview state store path.
- Keep consent-before-action. New tap → action paths route through a confirmation surface (sheet/alert), not direct execution.

---

## Cursor Cloud specific instructions

Cloud agents run on **Linux**, so the **iOS app (`Lumen/`, `LumenTests/`) cannot be built or run here** — `xcodebuild` and the iOS Simulator require macOS/Xcode. On Linux the only runnable lane is the **web marketing site** (`src/`). Do iOS work by reasoning about the Swift source; you cannot compile or test it in this environment.

- **Runtime:** Node 22 is pre-installed. Dependencies install with `npm install` (npm + `package-lock.json`; deps are pinned to `latest`, so a fresh install may drift from the lockfile). The startup update script already runs `npm install`.
- **Web commands** are the ones in `package.json` (`dev`, `build`, `preview`, `lint`, `test`, `e2e`, `ci`) and are documented in the "Web app" section above. `npm run dev` serves on `0.0.0.0:5173`.
- **Waitlist form does not fully work under `npm run dev`.** The form POSTs to `/api/waitlist`, a Vercel serverless function (`api/waitlist.js`) that Vite does **not** run; the client fallbacks (`web3forms`/`formsubmit.co`) need external network egress + secrets. Locally the form shows its error state after submitting — this is expected, not a bug. Use the theme toggle (nav icon left of "Request Access", persists to `localStorage`) or anchor-nav for an offline, reliable end-to-end interaction check.
- **`npm run e2e`** runs Playwright tests under `e2e/` (live demo flows). Browsers are not necessarily preinstalled locally — run `npx playwright install chromium` first (CI does this). Use `npm run test` (Vitest) for the web unit suite without browsers.
