# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This repo contains two independent apps that ship together:

| Path | What it is |
|------|-----------|
| `Lumen/` | Native iOS app (Swift / SwiftUI / SwiftData) |
| `Lumen.xcodeproj/` | Xcode project for the iOS app |
| `LumenTests/` | Xcode unit test target |
| `src/` | React/Vite marketing landing page |
| `public/` | Static assets for the web app |

---

## iOS app

### Building & running

```bash
# Build to a connected device (replace the destination ID as needed)
xcodebuild -project Lumen.xcodeproj -scheme Lumen -configuration Debug \
  -destination 'id=<DEVICE_UDID>' -allowProvisioningUpdates build

# List connected devices
xcrun xctrace list devices
```

The signing team is `CU67F9EY3Q`, bundle ID `com.muhome.app`. Code signing is set to Automatic — just open in Xcode and press **Cmd+R** with your phone connected.

**Note:** `xcodebuild` CLI builds fail with a "database is locked" error while Xcode is open. Close Xcode first or use Xcode directly.

### Architecture

The app is a protocol-driven MVVM app using Swift Observation (`@Observable`) and SwiftData.

#### Core abstractions (`Domain/`)

- `SmartDevice` — protocol every device (real or preview) conforms to. Carries capabilities.
- `DeviceCapability` — protocol hierarchy (`OnOffCapability`, `BrightnessCapability`, etc.). UI renders only capabilities the device actually reports.
- `SmartHomeBridge` — `Actor` protocol. Bridges (e.g. `HomeKitBridge`) implement this to connect a hardware ecosystem. Bridges emit `DeviceStateChange` via `AsyncStream`.

#### Services (`Services/`)

All services are `@Observable @MainActor` classes passed through the SwiftUI environment from `MuhomeApp`. They are the only places that touch `ModelContext`.

| Service | Owns |
|---------|------|
| `HomeService` | Home / Room CRUD |
| `DeviceService` | PlannedDevice CRUD; routes `SceneActionSnapshot` to the right bridge |
| `DeviceStateStore` | In-memory live state for all connected devices — rebuilt from bridges on each launch, never persisted |
| `SceneService` | Scene CRUD, execution, geofence-triggered automation |
| `LocationService` | CLLocationManager wrapper; publishes `GeofenceEvent` when the user crosses the home radius |
| `NotificationService` | UNUserNotificationCenter wrapper; called by `SceneService` after automation fires |
| `SensorObservationService` | Subscribes to motion/contact `AsyncStream`s from all capable devices |

#### Data flow for a scene execution

```
SceneListView → SceneViewModel.execute()
  → SceneService.execute(scene)
    → scene.asSnapshots() → [SceneActionSnapshot]
    → DeviceService.send(action:) per snapshot
      → DeviceStateStore.applyLocalAction()   // optimistic local update
      → bridge.executeAction()                // real hardware
```

#### SwiftData persistence (`Services/Persistence/`)

- Schema is versioned: `MuhomeSchemaV1` → `V2` → `V3`. `PersistenceCoordinator` always uses `MuhomeSchemaV3`.
- CloudKit sync is **off** (`enableCloudKitSync = false`). Flip only after provisioning `iCloud.com.muhome.app` in the Apple Developer portal.
- `MuhomeDataModels.swift` and `SceneModels.swift` contain **legacy structs** (`MuhaScene`, `MuhaSceneRecord`, etc.) from an older design. They compile but are not wired to any active schema or service — treat as dead code.

#### Local preview mode

When `AppState.enableLocalPreviewControls` is true, `DeviceStateStore` populates itself from `PlannedDevice` records via `LocalSmartDevice`. This lets the UI run without any real hardware. The `bridgeID == .localPreview` guard in `DeviceService.send()` short-circuits real bridge calls.

#### Geofence automation

`LocationService` detects home arrival/departure within a 100 m radius and publishes a `GeofenceEvent`. `SceneService.startMonitoringGeofenceEvents(from:)` polls this every 0.5 s and auto-executes scenes whose `geofenceTrigger` matches.

---

## Web app (`src/`)

### Commands

```bash
npm run dev        # dev server on 0.0.0.0:5173
npm run build      # production build → dist/
npm run lint       # ESLint
npm run test       # Vitest (single run)
npm run ci         # lint + test + build
npx vitest run src/main.test.jsx   # single test file
```

### Architecture

Single-page React/Vite app — no router, anchor-scroll only. All components are co-located in `src/App.jsx`; all styles in `src/App.css`. `src/styles.css` is unused.

**Waitlist form** (`Waitlist` component) resolves its endpoint in priority order:
1. `VITE_WAITLIST_ENDPOINT` — POST to any custom endpoint
2. `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` — POST to `{url}/rest/v1/lumen_waitlist`
3. `mailto:m.rafiq2006@icloud.com` fallback

`public/privacy/index.html` is fully self-contained (no React). The `vercel.json` rewrite maps `/privacy` → `/privacy/index.html`.

**Tests in `src/main.test.jsx` are stale** — they reference an older version of the app and will fail. Rewrite them against the current `App.jsx` before `npm run ci` can pass.
