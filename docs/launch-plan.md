# Launch Plan

## Launch Position

Lumen should launch first as a calm, local-first TestFlight beta. The first public promise is not "full smart-home automation"; it is an iOS companion that makes the current home rhythm understandable, shows why a suggestion exists, and asks before meaningful action.

The beta scope is intentionally narrow:

- Works without hardware through local preview mode.
- Discovers and controls HomeKit devices when permission is granted.
- Shows Now / Next rhythm, rooms, devices, scenes, and reasoning surfaces.
- Requires confirmation before direct scene execution.
- Keeps CloudKit sync off until the container and entitlement path are proven end to end.

## Current Readiness

| Area | Status | Launch decision |
| --- | --- | --- |
| Bundle identity | `com.muharafiq.lumen`, version `1.0`, build `7` | Ready for App Store Connect setup |
| Minimum OS | iOS 17.0 in Xcode project | Market as iOS 17+ |
| Local preview | Enabled by default | Primary demo and reviewer path |
| HomeKit | Entitlement present; discovery and control implemented | Beta-supported with real-home testing |
| Location | Foreground and region monitoring implemented | Beta-supported, explain clearly in permission copy |
| Notifications | Local automation alerts implemented | Beta-supported after opt-in |
| CloudKit | Code path exists but `enableCloudKitSync = false` | Do not enable for first beta |
| Privacy manifest | No tracking; UserDefaults accessed API reason declared | Needs App Store privacy-label review |
| Tests | 235 XCTest methods across `LumenTests` | Must pass on a Mac before each TestFlight archive. The June 2026 result in the release notes is stale. This October doc pass did not re-run `xcodebuild`. |

## Ship Criteria

Internal TestFlight can start when:

- `xcodebuild test -project Lumen.xcodeproj -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` passes from a clean checkout.
- A simulator smoke test covers first launch, local preview dashboard, scene approval, reasoning sheet, and settings.
- App Store Connect has the `com.muharafiq.lumen` record, HomeKit capability, privacy labels, and beta app information.
- The first tester guide explains local preview first, then HomeKit connection.
- Screenshots exist for dashboard, scene approval, reasoning view, settings, and HomeKit discovery.

External beta can start when:

- At least one non-developer internal tester completes the local-preview path without coaching.
- At least two real HomeKit homes verify discovery, device control, and scene execution.
- Location and notification prompts are accepted, denied, and recovered through Settings during manual QA.
- No known crash, data-loss, or silent-action bug is open.
- CloudKit remains disabled unless provisioning has been validated on a fresh install and upgrade path.

App Store submission can start when:

- External beta feedback does not show recurring confusion around "Lumen noticed", approval sheets, or geofence behavior.
- The App Review note includes the local preview path and explains that HomeKit hardware is optional for review.
- Privacy labels match actual app behavior: local home data, HomeKit access, location, notifications, no tracking, no third-party sharing.
- The support URL, privacy URL, screenshots, app icon, subtitle, keywords, and review contact are final.

## P0 Implementation Backlog

- `docs/screenshots/` holds the five review surfaces captured from the web preview (dashboard, reasoning, scene approval, device list, settings). Capture the same five from the iOS simulator before App Store submission. The web images are a stand-in, not a device archive.
- Use `docs/beta-tester-guide.md` for the 10-minute local-preview script and separate HomeKit script.
- Use `docs/manual-qa.md` for permission denial and recovery: HomeKit, location, notifications.
- Verify App Store Connect capability setup for HomeKit; leave CloudKit disabled for build 7 unless the container is fully provisioned.
- Run a clean native test pass and record the result in `docs/release-notes-1.0-build-7.md`.

## P1 Beta Backlog

- Add crash reporting or an equivalent lightweight feedback channel before external beta.
- Add a visible "Preview controls" explanation in Settings if testers confuse local preview with real hardware.
- Add one real-home regression checklist for lights, locks, thermostat, sensors, and unavailable devices.
- Decide whether geofence automation stays internal-only or ships to external beta behind explicit onboarding.

## TestFlight Build Procedure

1. Close Xcode if running command-line validation.
2. Run the native test gate:

   ```sh
   xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
   ```

3. Run an iPad build smoke check:

   ```sh
   xcodebuild -project Lumen.xcodeproj -scheme Lumen \
     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
     -configuration Debug build
   ```

4. Archive from Xcode with automatic signing.
5. Upload to App Store Connect.
6. Add beta notes that lead with local preview mode and explicitly state that real HomeKit hardware is optional.

## App Review Notes

Use this as the starting reviewer note:

> Lumen can be reviewed without smart-home hardware. On first launch, local preview mode is enabled by default and shows sample rooms and devices, so the dashboard, Now / Next rhythm, reasoning view, scene approval sheet, and settings can be tested immediately. If HomeKit permission is granted on a device with a configured Home, Lumen can also discover and control supported HomeKit accessories. Tapping a scene, or applying a suggestion from "Lumen noticed", opens an approval sheet before anything changes. A scene the reviewer has already scheduled, or set to run on arrival or departure, runs at that moment and posts a local notification. CloudKit sync is off. This build does not include NFC.

## Launch Copy

Subtitle:

> Calm routines for your home

Short description:

> Lumen helps your home feel easier to understand. See the current rhythm of the day, review gentle suggestions, and approve them before anything changes. Routines you schedule, or set for arrival and departure, run at that time and notify you.

Beta tester note:

> Start with preview controls even if you have HomeKit hardware. Then connect HomeKit and tell us where the reasoning, approval, or permission flow feels unclear. Arrival, departure, and scheduled scenes run without a second confirmation once you set them.

## Rollback Triggers

Pull a TestFlight build or pause rollout if any of these occur:

- First launch hangs or crashes for more than one tester.
- A tapped scene, or a "Lumen noticed" suggestion, runs without the approval sheet.
- An arrival, departure, or scheduled scene runs when the tester did not configure that trigger.
- HomeKit denial leaves the device screen unusable.
- Location denial causes repeated prompts or broken dashboard state.
- SwiftData migration or persistence errors lose homes, rooms, devices, or scenes.
