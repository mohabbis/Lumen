# App Review Privacy Note

## Overview

Lumen is a local-first smart-home companion for HomeKit routines, local preview mode, reasoning surfaces, and explicit approval before normal user-initiated scene actions. The current iOS app stores its home model locally with SwiftData and keeps CloudKit sync disabled for the first beta.

## HomeKit

Lumen requests HomeKit permission so it can discover accessories in the user's HomeKit homes, show rooms and devices, and control selected accessories through scene actions. HomeKit access is user-controlled through the system permission flow. If HomeKit access is denied or no hardware is available, the app remains usable through local preview devices and the main tabs continue to load.

## Local Network

The current beta build does not use native local-network discovery or control APIs directly. The repo contains scaffolded remote/IR models, including optional bridge host fields and Broadlink-format command storage, but there is no reachable runtime bridge execution path and no Bonjour, socket, `NWBrowser`, `NWConnection`, or native `URLSession` local-network path in the iOS app.

## Location

Lumen requests When-In-Use location on the home dashboard to show whether the user is home or away. After home coordinates are available, the app can request Always location and register a circular home region so arrival and departure events can be detected in the background. Denied or revoked permission stops location updates and leaves the rest of the app usable.

Location-triggered scene routing exists in the current code. Scenes whose geofence trigger is set to arrival or departure are executed automatically by `SceneService`, and local notifications are scheduled after success or failure. Seeded scenes default to no geofence trigger and the current add-scene UI does not expose trigger selection, but the runtime behavior should be reviewed before TestFlight because it is more automatic than the app's consent-first positioning.

## Notifications

Notifications are local only. Lumen requests notification authorization during app bootstrap and uses local notifications for automation success or failure alerts. Denial does not block core app usage.

## Data / Tracking

The native iOS app does not include third-party analytics, advertising tracking, App Tracking Transparency, crash-reporting SDKs, or external API calls. CloudKit sync is present only behind a disabled code flag, and the active app entitlements do not include iCloud or CloudKit. SwiftData stores the local home model, rooms, planned devices, scenes, remote profiles, sensor observations, and execution events on device. `UserDefaults` stores app-only home coordinates for local home/away status.
