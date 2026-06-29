# HomeKit Architecture

Lumen treats HomeKit as one bridge behind a local home model. The app remains useful when hardware is missing because rooms, planned devices, scenes, and reasoning surfaces can run from local preview state.

## Runtime Shape

- `SmartHomeBridge` defines the bridge contract.
- `HomeKitBridge` discovers HomeKit devices and emits device state changes.
- `DeviceStateStore` holds live state in memory and applies optimistic local updates.
- `DeviceService` routes scene action snapshots to the correct bridge.
- `SceneService` owns scene execution and geofence-triggered routing.

## Consent Path

Scene execution is intentionally indirect:

1. A user taps a scene or suggestion.
2. Lumen opens a confirmation surface.
3. The confirmation surface shows human-readable actions.
4. Only an explicit approval calls scene execution.
5. Errors are stored on the view model and shown by the UI.

## Local-First Behavior

SwiftData stores homes, rooms, planned devices, scenes, and execution history locally. CloudKit sync is gated off until the `iCloud.com.muharafiq.lumen` container is provisioned and tested.

## Hardware Boundaries

HomeKit capability code stays inside `Lumen/Integrations/HomeKit/`. UI and services depend on Lumen protocols, not HomeKit classes directly.
