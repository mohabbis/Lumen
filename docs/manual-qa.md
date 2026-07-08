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

## Matter Accessories

Lumen controls Matter accessories through the same path as HomeKit: iOS surfaces Matter accessories in your Apple Home as `HMAccessory`, so `HomeKitBridge` discovers them and `HomeKitDevice` maps their capabilities with no separate Matter stack. This checklist confirms that on real hardware.

- Pair a Matter accessory into your **Apple Home** first, using the Home app or the accessory's own setup flow (scan the Matter QR / pairing code). Lumen does not need to be the one that commissions it.
- Open **Intel** (Devices) in Lumen and trigger discovery.
- Confirm the Matter accessory appears with its name, room, and online state, exactly like a HomeKit-native accessory.
- Confirm the controls match what the accessory reports (for example a Matter light shows power, and brightness/color when supported).
- Toggle or adjust the accessory from Lumen and confirm the **physical** device responds.
- Add the accessory to a scene, run the scene through the approval sheet, and confirm it actuates.
- Confirm parity: a Matter light and a HomeKit-native light behave the same in Lumen.
- Boundary check: an accessory that is **not** added to your Apple Home must **not** appear in Lumen. Lumen only sees what is in Apple Home.

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

## Remotes / IR

Requires an IR bridge on your local network that accepts `POST <address>/send` with a JSON body `{ "format", "code" }` (a small DIY / ESP blaster or a Home Assistant style REST shim). Native Broadlink discovery is a future step.

- Open Settings and tap **Remotes** under the REMOTES card.
- Add a remote (for example `Living Room TV`), then open it.
- Set the **IR bridge address** to your bridge's IP or hostname (for example `192.168.1.50`).
- Add a button: give it a name (for example `Power`), paste a known-good IR code, and pick the matching format.
- Tap the button and confirm the **physical** device reacts (the first send may prompt for Local Network access; grant it).
- Clear the bridge address and tap a button; confirm a visible "no IR bridge address" error appears rather than a silent failure.
- Set a malformed address and confirm the invalid-address error appears.
- Delete a button and a remote; confirm both persist after relaunch.

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
