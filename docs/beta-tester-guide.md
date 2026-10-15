# Beta Tester Guide

## Goal

Help us verify that Lumen feels calm, understandable, and consent-first before a wider App Store launch.

Start with preview controls even if you have HomeKit hardware. This gives every tester the same baseline before real devices add home-specific behavior.

## 10-Minute Preview Script

1. Launch Lumen.
2. Confirm the dashboard loads with rooms, devices, and the Now / Next card.
3. Open the "Lumen noticed" card.
4. Check whether the reasoning view explains the suggestion clearly.
5. From the reasoning sheet, continue to the approval sheet. Confirm the suggestion does not run until you approve that second sheet.
6. Open Scenes and tap a scene row.
7. Confirm that a tapped scene does not run until you approve it.
8. Open Devices and Settings.
9. Toggle preview controls off and on.
10. Note any moment where the app feels too busy, too technical, or surprising.

## HomeKit Script

Use this only after the preview script.

1. Open Devices.
2. Grant HomeKit access when prompted.
3. Confirm discovered devices appear with understandable names and states.
4. Try one low-risk device action, such as a light or plug.
5. Create or run a simple scene.
6. Confirm a tapped scene shows an approval sheet before anything changes. Scenes you schedule, or set for arrival and departure, run on their own and should notify you.
7. Deny or revoke HomeKit permission in Settings and confirm Lumen explains the blocked state.

## Location And Notifications Script

1. Set or update the home location.
2. Grant location permission.
3. Confirm Lumen shows home/away state without repeated prompts.
4. Grant notification permission.
5. If you are testing geofence behavior, set one low-risk scene to run on arrival or departure. Crossing the home radius runs that scene without another approval sheet. Expect a notification.
6. Revoke location permission in Settings and confirm the app remains usable.

## Report Format

Please include:

- Device model and iOS version.
- Whether you used preview controls, HomeKit, or both.
- The exact screen where something felt unclear.
- What you expected Lumen to do.
- What Lumen actually did.
- Whether any action happened without a clear confirmation.

## Known Beta Limits

- CloudKit sync is off, so data is local to the device.
- Preview controls are sample devices, not real hardware.
- HomeKit results vary by the tester's Home configuration and accessory support.
- Matter accessories already added to your Apple Home are controllable (iOS surfaces them through HomeKit); pairing Matter accessories from inside Lumen is outside the first beta scope.
- NFC tags are not in this build.
- There is no crash reporter. If the app quits, describe the last screen you saw.
