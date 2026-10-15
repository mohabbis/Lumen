# Release Notes: 1.0 (7)

## Release Type

Internal TestFlight candidate.

## Beta Scope

- Local preview mode is the primary review and tester path.
- HomeKit discovery and control are available when permission is granted and the tester has a configured Home.
- Tap-to-run scenes and "Lumen noticed" suggestions open an approval sheet before anything changes. Arrival, departure, and daily schedules run at the configured time and post a local notification.
- Location-aware home/away behavior and local notifications are included for beta validation.
- CloudKit sync remains off for this build.

## Validation

Native gate, last recorded on a Mac (29 June 2026). That result predates later iOS work, including the consent-sheet change. Re-run it before archiving build 7:

```sh
xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Recorded result bundle from that June run:

```text
~/Library/Developer/Xcode/DerivedData/Lumen-eamhwlfegirvdcghiucenbvohqdg/Logs/Test/Test-Lumen-2026.06.29_08-42-30--0500.xcresult
```

iPad smoke from the same era:

```sh
xcodebuild -project Lumen.xcodeproj -scheme Lumen \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -configuration Debug build
```

October 2026 doc pass: `xcodebuild` was not run. This environment has no Xcode. `LumenTests` currently contains 235 `test` methods. Web unit tests (`npm test`) were run with this doc pass. App Store Connect was not checked.

## Known Limits

- CloudKit sync is disabled; beta data is local to the device.
- Preview controls are sample devices and do not represent real hardware state.
- HomeKit behavior depends on the tester's Home configuration and accessory support.
- Matter setup and multi-home workflows are outside this build's launch scope.
- NFC is not in this build.
- There is no crash reporter. A fatal store error prints and aborts.

## Screenshots

Documentation screenshots live in `docs/screenshots/`.

- `dashboard.png`
- `reasoning-view.png`
- `scene-approval.png`
- `device-discovery.png`
- `settings.png`

Captured 15 October 2026 from the React/Vite preview (`src/demo`), which mirrors the launch surfaces for review. These are not iOS simulator captures. Replace them with device or simulator shots before App Store submission. The reasoning image is the suggestion sheet (signals plus the proposed changes). The scene-approval image is the Auto-tab confirm sheet.

## TestFlight Notes

Start with preview controls even if you have HomeKit hardware. Then connect HomeKit and report where the reasoning, approval, or permission flow feels unclear. Real hardware is optional for first-pass review.
