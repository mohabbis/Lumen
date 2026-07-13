# Privacy Launch Readiness Audit

## Summary

This pass inspected the native Lumen iOS target, privacy manifest, entitlements, Info.plist, Xcode project wiring, and runtime privacy surfaces for App Store / TestFlight review. The app's strongest current privacy posture is local-first storage, no third-party tracking or native analytics, HomeKit behind the system permission flow, and CloudKit disabled. The main launch risk is that geofence-triggered scenes can auto-execute when a scene has an arrival/departure trigger.

## Files Inspected

- `Lumen.xcodeproj/project.pbxproj`
- `Lumen/Info.plist`
- `Lumen/PrivacyInfo.xcprivacy`
- `Lumen/Entitlements.plist`
- `Lumen/LumenCloud.entitlements`
- `Lumen/Views/LumenApp.swift`
- `Lumen/Features/RootView.swift`
- `Lumen/Features/Home/HomeDashboardView.swift`
- `Lumen/Features/Devices/DeviceListView.swift`
- `Lumen/Features/Scenes/SceneListView.swift`
- `Lumen/Features/Settings/SettingsView.swift`
- `Lumen/Integrations/HomeKit/HomeKitBridge.swift`
- `Lumen/Services/LocationService.swift`
- `Lumen/Services/NotificationService.swift`
- `Lumen/Services/Persistence/PersistenceCoordinator.swift`
- `Lumen/Services/Scene/SceneService.swift`
- `Lumen/Domain/Models/Remote/RemoteProfile.swift`
- `Lumen/Domain/Models/Remote/IRCommand.swift`
- `LumenTests/LocationServiceTests.swift`
- `LumenTests/GeofenceRoutingTests.swift`
- `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/`, `public/privacy/index.html`, `src/App.jsx`

## Privacy Manifest

`Lumen/PrivacyInfo.xcprivacy` was present before this pass and is part of the synchronized `Lumen/` app target folder. The Xcode project excludes only `Entitlements.plist` and `Info.plist` from the synchronized app target, so `PrivacyInfo.xcprivacy` is bundled with the app target.

Changes made:

- Preserved `NSPrivacyTracking = false`.
- Preserved empty `NSPrivacyTrackingDomains`.
- Preserved empty `NSPrivacyCollectedDataTypes`.
- Preserved `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`.
- Corrected the manifest comment to match actual runtime usage: app-only home coordinates stored in `UserDefaults`.

`plutil -lint Lumen/PrivacyInfo.xcprivacy` passed.

## Required-Reason API Findings

| API category | Usage | Runtime/test/docs | Manifest action |
| --- | --- | --- | --- |
| UserDefaults | `LocationService` writes and reads `homeLatitude` and `homeLongitude` for app-only home/away status. | Runtime | Kept `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1`. |
| UserDefaults | `LocationServiceTests` clears the home coordinate keys. | Test-only | No separate manifest action. |
| FileManager | `PersistenceCoordinator` resolves Application Support and creates the directory before SwiftData store creation. | Runtime | No declaration added; no file timestamp, disk-space, boot-time, or active-keyboard required-reason API usage was found. |
| ProcessInfo environment | `RootView` checks `XCTestConfigurationFilePath` to skip HomeKit bridge registration in tests. | Runtime guard for test environment | No required-reason category found. |

## Permission Flows

### HomeKit

The app target is `Lumen`, bundle identifier `com.muharafiq.lumen`, minimum iOS version `17.0`, and active signing entitlements are `Lumen/Entitlements.plist`. The active entitlements include `com.apple.developer.homekit` and keychain access only. `HomeKitBridge` uses `HMHomeManager`, discovers `HMAccessory` records, wraps them behind `SmartDevice`, and executes selected characteristic writes through HomeKit. `DeviceListView` surfaces denied HomeKit access with an Open Settings action. `AppState.enableLocalPreviewControls` defaults to true, so local preview mode remains available without HomeKit hardware.

Updated `NSHomeKitUsageDescription` to describe discovery and control of accessories the user chooses to connect.

### Location

`HomeDashboardView` calls `requestLocationPermission()` and `startMonitoringLocation()` on appear. `LocationService` requests When-In-Use first, then calls `requestAlwaysAuthorization()` after home coordinates are stored. It registers a `CLCircularRegion` for the home radius and handles region entry/exit callbacks. `Info.plist` includes When-In-Use and Always usage descriptions plus `UIBackgroundModes` `location`.

Updated both location usage strings so they reflect home/away status and configured location-based routines. Removed the unrelated `fetch` background mode.

### Local Network

No native runtime local-network discovery/control path was found. Searches found no `NWBrowser`, `NWConnection`, `NetService`, native `URLSession`, Bonjour declaration, socket path, or reachable IR bridge network execution. Remote/IR models exist (`RemoteProfile`, `IRCommand`, `bridgeHostname`, Broadlink-format codes), but current UI only creates local remote profiles and does not perform local-network communication.

Removed `NSLocalNetworkUsageDescription` and `UIRequiresPersistentWiFi` from `Info.plist` to avoid declaring behavior the native app does not currently perform.

### Notifications

`RootView` requests notification authorization during bootstrap. `NotificationService` schedules local notifications for geofence automation success or failure and clears the app badge. No push-notification or notification-service-extension path was found. Denial does not block core app usage.

## Tracking / Network / Cloud

The native app has no App Tracking Transparency usage, IDFA access, third-party analytics SDK, native external API call, Firebase, Amplitude, Mixpanel, Sentry, PostHog, or push-notification integration. The marketing site uses `fetch` for a Supabase waitlist and loads external web fonts; that is separate from the native iOS app and was not added to the app privacy manifest.

`PersistenceCoordinator.enableCloudKitSync` is `false`, and the active app entitlements do not include iCloud or CloudKit. `Lumen/LumenCloud.entitlements` exists in the repo and declares future CloudKit/multicast capabilities, but `project.pbxproj` points `CODE_SIGN_ENTITLEMENTS` to `Lumen/Entitlements.plist`, not `Lumen/LumenCloud.entitlements`.

## App Review Note

Saved concise reviewer-facing notes at `outputs/app-review-privacy-note.md`.

## Validation

- `plutil -lint Lumen/PrivacyInfo.xcprivacy Lumen/Info.plist Lumen/Entitlements.plist Lumen/LumenCloud.entitlements` passed.
- `xcodebuild` via XcodeBuildMCP built the `Lumen` scheme for `iPhone 17 Pro Max` simulator in Debug configuration successfully with no diagnostics.
- The built simulator app bundle contains a single `PrivacyInfo.xcprivacy`.
- The built app `Info.plist` contains the updated HomeKit and location strings, `UIBackgroundModes = location`, and no `NSLocalNetworkUsageDescription`, `NSBonjourServices`, or `UIRequiresPersistentWiFi` keys.
- The simulated entitlements file includes HomeKit and keychain access for `com.muharafiq.lumen`; no iCloud, CloudKit, multicast, or app group entitlement is active in the simulator build.
- Full test execution was attempted with XcodeBuildMCP. The test build reached `TEST BUILD SUCCEEDED`, but the runner timed out before producing a completed result bundle, so test execution is not counted as passed.

## Risks / Follow-ups

- Geofence-triggered scene auto-execution may conflict with Lumen's consent-first positioning. Before TestFlight, gate geofence scene execution behind a confirmation or explicitly document the automation behavior in product and review materials.
- `RootView` requests notification permission on bootstrap instead of at the moment the user enables an automation path. This is reviewable, but a just-in-time prompt would be easier to explain.
- `HomeDashboardView` requests location permission on first dashboard appear. Confirm this is acceptable for first beta, or move it closer to the home/away setup flow.
- `Lumen/LumenCloud.entitlements` is not the active signing entitlement file, but it can confuse future privacy reviews because it declares CloudKit and multicast capabilities that are not active in the beta.
- Privacy strings should receive final product-owner approval before App Store submission.
