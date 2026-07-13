# Lumen Full Audit — July 2026

Snapshot of `main` at audit time (`dfbb355` lineage). Covers the iOS app (`Lumen/`, `LumenTests/`), marketing web lane (`src/`, `api/`, `lib/`), and top-level docs. iOS findings are from source review (this environment cannot run `xcodebuild`).

## Verdict

Lumen’s calm-consent positioning is real for **manual scenes** and the dashboard **4-mode** flow (noticed → reason → action → execute). The biggest gaps are **product-truth drift** (marketing “nothing runs on its own” vs geofence auto-execute), a **broken home-location setup path** (coordinates never writable from UI → SwiftData lat/lon stay nil → geofence never arms from the dashboard), **silent error surfaces** on Devices/Rooms/Remote list, and **contaminated docs** (`PROJECT.md` / dead Astro Car Wash leftovers). The web lane builds and unit-tests cleanly; Playwright e2e exists and is wired into CI (agent docs were wrong about an empty suite).

---

## Priority matrix

| # | Severity | Area | Finding | Status in this PR |
|---|----------|------|---------|-------------------|
| 1 | High | iOS / geofence | `Home.latitude`/`longitude` never set from UI or `HomeService`; dashboard only forwards coords when both exist → presence/geofence largely unreachable | **Fixed**: Settings “Use current location” + `HomeService.updateCoordinates` |
| 2 | High | iOS / consent | Geofence auto-executes opted-in scenes with no confirmation (intentional) while marketing claims nothing runs alone | **Copy qualified**; product decision tracked |
| 3 | High | iOS / security | Lock unlock is one tap, no confirm; Device Detail errors never alert | Open (needs confirm sheet + shared alert pattern) |
| 4 | High | Docs | `PROJECT.md` described a different product (Car Wash Guys) | **Fixed** |
| 5 | High | Web / security | Waitlist: no rate limit; personal inbox + FormSubmit fallback in client/server path | Documented; harden in follow-up |
| 6 | High | Docs / agents | `AGENTS.md`/`CLAUDE.md` claimed e2e empty (`./tests`) and omitted e2e from `ci` | **Fixed** |
| 7 | Medium | Architecture | `RemoteViewModel` owns `ModelContext` CRUD (violates “services only”) | Open |
| 8 | Medium | Explainability | `SuggestionFactor` labels from scored engine never shown in `LumenReasoningView` | Open |
| 9 | Medium | iOS / sensory | `SensoryProfile.dailySuggestionLimit` / cadence unused by SuggestionEngine | Open |
| 10 | Medium | Web | Deps pinned to `"latest"`; orphan Astro/CSS pollutes tree | Orphans **removed**; pin versions in follow-up |
| 11 | Medium | Tests | AGENTS “145 tests” stale (~160); no geofence-execution / DeviceViewModel tests | Count **updated** |
| 12 | Low | Region race | `didEnterRegion` on register can fire arrival without first-check gate | **Mitigated** via configure suppress window |

---

## iOS app

### Consent-before-action

**Solid**

- Scene list → `SceneApprovalSheet` → `confirmPending` → execute.
- Dashboard noticed → `LumenReasoningView` → `LumenActionView` → `handleLumenSuggestion` → execute.
- Errors on those paths surface via `viewModel.error` alerts.

**Gaps**

| Path | Behavior | Notes |
|------|----------|-------|
| Geofence | `SceneService.handleGeofenceEvent` → `execute` | User opts in per scene; no sheet; notification after. Markets as exception, not “never alone.” |
| Device Detail | Power / brightness / color / **lock** immediate | Lock deserves confirm; direct dimmers are fine product-wise if docs scope “consent” to scenes. |
| IR Remotes | Tap → send | Fire-and-forget by design. |
| Empty scenes | Consent then `applyLocalScenePreset` mutates many devices | Summary copy is vague (“Apply preset”). |

### Architecture vs AGENTS.md

- Core Home/Device/Scene services and VMs follow `@Observable` + `@MainActor`.
- **Drift:** `RemoteViewModel` inserts/saves remotes and commands directly; `RemoteService` only transports IR.
- `KeychainService` + vendor keys: unused scaffolding.
- `SensorObservationService` wired in `RootView` but never consumed by scoring/UI.
- Dual home-coord stores: SwiftData `Home` vs `UserDefaults` (`homeLatitude`/`homeLongitude`). Dashboard previously could not seed either from user action.

### Suggestion / reasoning layer

- `SuggestionEngine` weights, threshold `0.2`, midnight habit wrap, presence boosts match AGENTS.md and tests.
- Explainability hole: only `confidence` + `habitRuns` reach `ReasoningCalculator`; factor strings (“Fits evening”, favorite, etc.) are dropped.
- README/`ROADMAP` still framed “on-device reasoning” as not started; scored heuristic layer is already shipped (Phase 1 partial).

### Persistence

- CloudKit correctly gated off (`PersistenceTests`).
- V2→V3 “drop unique on id” is documented but current `@Model` types have no `@Attribute(.unique)` — version story is soft.
- Inferred nullable columns for `Home` coords / Broadlink fields without a new schema version — acceptable for beta, fragile long-term.

### Error handling

Silent (sets `error`, no alert): Device list/detail, Room list/detail, Remote list, `HomeViewModel.renameHome` (`try?`), RootView bootstrap `try?` load/seed.

### Tests (`LumenTests`)

~160 `test*` across 17 files. Documented table missed `DashboardPresentationTests`, `SensoryProfileTests`. Gaps: geofence execution integration, DeviceViewModel live control, DeviceStateStore presets, SensorObservation, Keychain, Notification, HomeKit bridge.

### Home location (critical path) — fixed here

Previously: `Home.init` could take lat/lon but nothing wrote them after create; Settings showed name/room/device counts only; QA doc assumed “set home location.”

This PR adds:

- `HomeService.updateCoordinates(_:latitude:longitude:)`
- Settings → Home → “Use current location” (requests permission, persists to SwiftData, arms `LocationService`)
- Region-configure suppress window so registering while already inside does not emit a spurious arrival

---

## Marketing web

### What works

- Vite React entry (`main.jsx` → `App.jsx`) is coherent with product tone.
- Waitlist shared module has unit coverage (`lib/waitlist.test.js`, submit/analytics tests).
- Playwright suite under `e2e/` (4 live-demo tests); CI installs Chromium and runs `npm run ci` including e2e.

### Product truth

- Hero / calm pillar: “nothing runs on its own” contradicted Presence section (geofence can run scenes) and `SceneService`.
- Copy updated to: suggestions need approval; opted-in arrival/departure scenes may run with a notification.
- “Now in private beta” may be aspirational vs README TestFlight checkboxes / ROADMAP Phase 2 timing — leave as product call.
- Mac “on the roadmap” on site; `ROADMAP.md` has no Mac item.

### Security / privacy

- No waitlist rate limit, CAPTCHA, or honeypot.
- `DEFAULT_TO_EMAIL` personal inbox used by FormSubmit fallback and imported into the **client** bundle via `waitlistSubmit.js`.
- Privacy page does not document waitlist third parties (webhook / Supabase / Resend / Web3Forms / FormSubmit).
- `VITE_*` env aliases for server providers risk shipping secrets if mis-set.

### Orphans (removed in this PR)

- `PROJECT.md` Car Wash content → replaced with Lumen project brief.
- `src/pages/**` Astro Car Wash leftovers, `src/consts.ts`, unused `src/styles.css` / `global.css` / `architecture-actions.css`.

### Dependencies

All `package.json` deps are `"latest"` — lockfile freezes today; unconstrained reinstall can major-bump. Pin in a dedicated PR.

---

## Docs drift checklist

| Doc | Issue | Resolution |
|-----|-------|------------|
| `PROJECT.md` | Wrong product | Replaced |
| `AGENTS.md` / `CLAUDE.md` | E2e empty; `ci` omits e2e; dead CSS import listed; 145 tests | Updated (mirrors kept identical) |
| `README.md` | 145 tests; “rule-based” only for noticed | Updated |
| `ROADMAP.md` | Phase 1 ignores shipped SuggestionEngine | Annotated |
| `outputs/*` audits | IR / geofence UI claims stale | Left; prefer `docs/full-audit-2026-07.md` |
| `docs/screenshots/` | README links missing images | Noted; no screenshots added |

---

## Recommended follow-ups (ordered)

1. **Confirm before lock unlock** + bind Device/Room/Remote list errors to alerts.
2. **Waitlist hardening:** rate limit on `api/waitlist.js`; move recipient to server-only env; drop unauthenticated FormSubmit default from client; privacy-page processors.
3. **Pin npm semver**; trim unused deps (`jest-axe`, unused ESLint React plugins).
4. **Surface `SuggestionFactor`s** in `ReasoningCalculator` / reasoning UI; honor sensory cadence/limit.
5. **`RemoteService` CRUD** so ViewModels stay ModelContext-free.
6. **Geofence execution tests** + region-suppress coverage in `LocationServiceTests`.
7. Decide whether marketing should soften “private beta” until TestFlight is literally live.

---

## Out of scope / not defects

- Zones scaffolded without UI (documented as in-progress).
- IR not a `SmartHomeBridge` (by design).
- CloudKit off until portal provisioning (correct for beta).
- Local-preview mode defaulting on (tests depend on it).
