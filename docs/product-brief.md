# Lumen Product Brief

Lumen is a local-first iOS smart-home companion for calm routines, explainable suggestions, and confirmation before meaningful actions.

## Product Wedge

Most smart-home apps expose devices as a control panel. Lumen starts with the user's lived context: rooms, presence, scenes, and time of day. The app helps a home feel understandable without hiding what it is doing.

## Core Experience

1. Open Lumen and see the current rhythm of the home.
2. Review rooms, active devices, and the next likely transition.
3. Inspect a suggestion in the reasoning view.
4. Approve a scene before it executes.
5. Continue using local preview mode when no HomeKit hardware is available.

## What Works Today

- Native SwiftUI dashboard for iPhone and iPad.
- Local preview mode with mock rooms and devices.
- HomeKit discovery and bridge-backed device control.
- Scene approval sheet before direct scene execution.
- Reasoning view for ambient suggestions.
- Geofence-aware arrival and departure routing.
- SwiftData persistence with versioned schema.

## Open Product Questions

- Which routines are useful enough for a first TestFlight group?
- Should beta onboarding lead with local preview mode or HomeKit discovery?
- Which explanations are essential, and which create unnecessary reading?
