# Manual QA

## Purpose

Use this before each TestFlight upload. The automated XCTest suite covers core logic; this checklist covers launch behavior, permission recovery, and consent-before-action surfaces.

## Baseline Smoke Test

- Launch Lumen on a clean simulator or device.
- Confirm the app reaches the dashboard or onboarding without a black screen.
- If onboarding appears, create a home with a simple name such as `Home`.
- Confirm local preview controls are enabled by default.
- Confirm the dashboard shows rooms, devices, Now / Next rhythm, and the Lumen noticed card.
- Open Settings and confirm version/build, preview controls, haptics, and debug-details toggles render correctly.

## Consent-First Scenes

- Tap a scene row from the Scenes tab.
- Confirm the approval sheet opens before anything executes.
- Confirm the sheet lists the scene actions in human-readable terms.
- Cancel and verify no scene execution feedback appears.
- Repeat and approve the scene.
- Confirm any error appears through the visible dashboard alert path rather than being swallowed.

## Reasoning Flow

- Tap the Lumen noticed card.
- Confirm the reasoning sheet explains time of day, presence, reachable devices, and matching scene when available.
- Tap Not now and confirm no action occurs.
- Reopen the sheet and apply the suggestion.
- Confirm the apply path does not bypass the reasoning surface.

## HomeKit Permission

- Reset HomeKit permission before testing when possible.
- Open Devices and trigger HomeKit discovery.
- Grant HomeKit access.
- Confirm discovered devices show name, room, online state, and supported controls.
- Revoke HomeKit access from iOS Settings.
- Return to Lumen and confirm the Devices screen explains the blocked state and offers a Settings path.
- Confirm the rest of the app remains usable with local preview controls.

## Location Permission

- Reset location permission before testing when possible.
- Set or update the home location.
- Grant when-in-use permission.
- Confirm the dashboard home/away state updates without repeated prompts.
- If testing background geofence behavior, grant always permission after the when-in-use prompt.
- Revoke location access from iOS Settings.
- Return to Lumen and confirm the dashboard remains usable and does not repeatedly prompt.

## Notification Permission

- Reset notification permission before testing when possible.
- Launch Lumen and respond to the notification prompt.
- If granted, run a low-risk automation path and confirm the notification copy is understandable.
- If denied, confirm scene execution still works and no repeated prompt loop appears.

## iPad Smoke Test

- Build for iPad Pro 13-inch (M5).
- Launch and confirm the split-view navigation renders all tabs.
- Confirm dashboard, rooms, devices, scenes, and settings are reachable.
- Confirm text does not overlap in cards, sheets, or navigation rows.

## Fail The Build If

- First launch hangs or shows a black screen.
- Any scene executes without an approval surface.
- Permission denial makes a primary tab unusable.
- The dashboard repeatedly prompts for location or notifications.
- Homes, rooms, devices, or scenes disappear after relaunch.
