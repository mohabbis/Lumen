# Release Notes: 1.0 (7)

## Release Type

Internal TestFlight candidate.

## Beta Scope

- Local preview mode is the primary review and tester path.
- HomeKit discovery and control are available when permission is granted and the tester has a configured Home.
- Scene execution remains consent-first: scene rows and Lumen suggestions must show an approval surface before applying changes.
- Location-aware home/away behavior and local notifications are included for beta validation.
- CloudKit sync remains off for this build.

## Validation

- Native XCTest gate passed on iPhone 17 Pro Max:

  ```sh
  xcodebuild test -project Lumen.xcodeproj -scheme Lumen \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
  ```

- Result bundle from the latest local validation:

  ```text
  ~/Library/Developer/Xcode/DerivedData/Lumen-eamhwlfegirvdcghiucenbvohqdg/Logs/Test/Test-Lumen-2026.06.29_08-42-30--0500.xcresult
  ```

- iPad build smoke check passed:

  ```sh
  xcodebuild -project Lumen.xcodeproj -scheme Lumen \
    -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
    -configuration Debug build
  ```

- Web preview CI passed:

  ```sh
  npm run ci
  ```

## Known Limits

- CloudKit sync is disabled; beta data is local to the device.
- Preview controls are sample devices and do not represent real hardware state.
- HomeKit behavior depends on the tester's Home configuration and accessory support.
- Matter setup and multi-home workflows are outside this build's launch scope.

## Screenshots

Documentation screenshots live in `docs/screenshots/`.

- `dashboard.png`
- `reasoning-view.png`
- `scene-approval.png`
- `device-discovery.png`
- `settings.png`

The dashboard, reasoning, scene approval, and device-discovery screenshots are captured from the repo's React/Vite preview, which mirrors the native launch surfaces for review. The settings screenshot is a native-style documentation capture based on `Lumen/Features/Settings/SettingsView.swift`.

## TestFlight Notes

Start with preview controls even if you have HomeKit hardware. Then connect HomeKit and report where the reasoning, approval, or permission flow feels unclear. Real hardware is optional for first-pass review.
