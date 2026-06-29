# Test Strategy

Lumen's test suite covers core product logic without requiring HomeKit hardware or simulator state.

## Test Layers

- Pure helpers cover rhythm timing, scene action descriptions, reasoning signals, and geofence routing.
- Service tests use an in-memory SwiftData `ModelContainer`.
- View model tests cover derived state and visible error paths.
- Persistence tests guard the CloudKit gate and schema round trips.

## Current Gate

```sh
xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Close Xcode before running command-line builds or tests to avoid project database locking.

## Coverage Priorities

- Keep all consent-before-action paths covered.
- Add tests when view logic becomes more than simple rendering.
- Test local preview behavior because it is the demo and beta fallback path.
- Keep CloudKit disabled until provisioning and launch behavior are verified.
