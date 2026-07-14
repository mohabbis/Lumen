# Competitive Feature Scope — vs Home Assistant & Homebridge

Draft scope. Last updated: July 2026.

## The framing problem

Home Assistant and Homebridge win on **breadth and control density**: thousands of
integrations, arbitrary automations, and (for Homebridge) exposing non-HomeKit
hardware into the Apple ecosystem. Lumen's own `ROADMAP.md` is explicit that we
**do not compete on toggle density or integration count**, and must **never add an
auto-apply-without-confirmation mode**. The moat is calm + explainability + consent.

So "compete with Home Assistant and Homebridge" cannot mean "clone them." It means
closing the two gaps where a prospective user genuinely *can't use Lumen at all*
today — and closing them **on Lumen's terms** (explained, consented, calm).

Those two gaps map cleanly onto the two competitors:

| Competitor | What it gives users | Lumen's gap today |
|-----------|--------------------|-------------------|
| **Homebridge** | Control devices Apple Home can't see | Lumen only speaks HomeKit (+ fire-and-forget IR) |
| **Home Assistant** | Rich automations: time, sensor, conditional triggers | `Scene` has one trigger axis — geofence arrival/departure |

Everything below is filtered so it strengthens the moat instead of diluting it.

---

## Tier 1 — the two gaps that lock users out

### 1. A second real bridge: local-LAN device support (the Homebridge move)

> **Status (July 2026):** engine landed. `LocalNetworkBridge` + the
> `LocalDeviceTransport` seam + `ShellyGen2Transport` + capabilities + tests are
> in `Integrations/LocalNetwork/` (`LumenTests/LocalNetworkTests.swift`).
> Remaining: a SwiftData `LocalDeviceConfig` model + a Settings surface to author
> devices, then register the bridge in `RootView`. Tracked as "scaffolded but not
> yet wired" in `CLAUDE.md`.

**Why:** Today, a Shelly relay, a Tasmota/ESPHome switch, a LIFX bulb on LAN, or a
Tuya device that never made it into Apple Home is invisible to Lumen. This is the
single most common "I can't switch to your app" objection Homebridge exists to solve.

**Why it's cheap architecturally:** the app is already multi-bridge.
`DeviceService.registeredBridges: [BridgeID: any SmartHomeBridge]` routes every
action by `device.bridgeID` (`DeviceService.swift:38-51`); `BridgeID` is just a
string; `registerBridge` wires a new bridge into the `DeviceStateStore` state
stream. HomeKit is not special — it is simply the first bridge registered. The IR
layer already proves the "second ecosystem behind a transport seam" pattern
(`RemoteService` + `IRTransport`).

**Scope:** add a `LocalNetworkBridge` conforming to `SmartHomeBridge`, driving devices
that expose a **local HTTP/REST or simple socket API** — no cloud, no account, keeps the
local-first posture. Reuse the existing capability protocols (`OnOffCapability`,
`BrightnessCapability`, …) so these devices render in the exact same UI with zero
view changes. Start with one or two well-documented local protocols (Shelly Gen2 RPC
and generic REST-on/off are good first targets) rather than a plugin marketplace.

**Moat fit:** neutral-to-positive. More reachable devices, same consent surfaces. No
change to the execution/approval pipeline.

**Non-goals:** no cloud-polling integrations, no arbitrary plugin runtime (that is
Homebridge's maintenance-burden model, not ours), no Matter commissioning here (already
Roadmap Phase 5, and Matter already arrives via HomeKit).

### 2. Time & schedule triggers for scenes (the Home Assistant move)

**Why:** "Turn the porch light on at sunset," "Wind-down scene at 9pm" — schedule is
the #1 automation type in Home Assistant and the most-requested thing a geofence-only
model can't express. `Scene.geofenceTrigger` is the *only* trigger today.

**Scope:** generalize the single `geofenceTrigger` enum into a small set of
composable triggers. Add `TimeTrigger` (fixed time-of-day; sunset/sunrise as a
fast-follow once we have `Home` coordinates from Roadmap Phase 1). Keep the pure
routing pattern already used by `SceneService.scenesMatching(event:in:)` — a
scheduled poll analogous to the geofence poller (`SceneService.monitoringTask`).

**The consent question (must resolve before building):** does a scheduled scene fire
directly, or surface a suggestion? A defensible reading of the moat: **setting a
schedule *is* the consent** — the user pre-authorized this exact scene at this exact
time, explicitly, ahead of time. That is categorically different from the forbidden
"auto-apply on a hunch." Recommend: scheduled scenes fire directly **but** post an
explainable notification ("Wind-down ran at 9:00 PM — you scheduled this. Undo?"),
preserving explainability and reversibility. This needs a `ROADMAP.md` sign-off since
it touches the auto-apply boundary.

---

## Tier 2 — turn latent capability into explainable automation

These use machinery Lumen already has; they deepen the moat rather than chase parity.

### 3. Sensor-driven suggestions

`SensorObservationService` already ingests motion/contact `AsyncStream`s from every
capable device — but only **records** them into a ring buffer. Feed those signals into
`SuggestionEngine` so "motion in the hallway after dark → suggest Path Lighting"
becomes a scored, explainable suggestion. This is Home Assistant-style reactivity
delivered the Lumen way: it *suggests and asks*, it doesn't silently fire. Purely
additive to the existing scored layer; every factor stays human-readable.

### 4. Conditional / multi-signal rules (explainable rule builder)

Home Assistant's power is trigger **+ condition + action**. Lumen can offer a calm,
readable version: "When [motion] **and** [it's evening] **and** [I'm home] → suggest
[Cozy]." The scoring layer already combines time-of-day, presence, and habit signals;
this exposes that combination as a user-authorable rule while keeping the one-sentence
explanation per factor. Deliberately *not* a YAML/DSL — a guided, low-cognitive-load
builder.

### 5. Calm home history ("what happened today")

`ExecutionEvent` is already persisted (schema V2). Surface it — plus in-memory
`SensorEvent`s — as a gentle daily timeline, not Home Assistant's dense logbook. This
directly serves the trust/explainability mission: users see what Lumen did and why,
after the fact. Read-only, no new schema for the execution side.

---

## Tier 3 — parity/adjacent, lower priority

- **Richer notifications** — `NotificationService` exists but only fires on geofence.
  Alert on "contact sensor left open," "unusual late-night motion." Consent-neutral.
- **Capability breadth** — no fan/speed, garage door, cover tilt, or thermostat-mode
  UI beyond the `HVACMode` enum, no media transport. Each is an incremental capability
  add (`DeviceCapability` + a renderer), not architectural work. Prioritize by what
  Tier-1 bridges actually expose.
- **Config export / backup** — Home Assistant users expect their setup to be portable.
  A local-first export of homes/rooms/scenes reinforces "your data is yours."
- **Matter in-app commissioning** — already Roadmap Phase 5; noted here for completeness.

---

## Explicit non-goals (protect the moat)

- No auto-apply-without-confirmation mode, even as a power-user opt-in (per `ROADMAP.md`).
- No plugin/add-on runtime or marketplace (Homebridge's maintenance model).
- No cloud-account integrations that break the local-first posture.
- No dashboard/entity-grid density race (Controller-for-HomeKit's game, not ours).

## Recommended sequence

1. **Tier 1.2 (time/schedule triggers)** — highest user value, self-contained, but land
   the `ROADMAP.md` consent sign-off first.
2. **Tier 1.1 (LocalNetworkBridge)** — highest strategic value vs both competitors;
   larger surface, so scope to one local protocol end-to-end before generalizing.
3. **Tier 2.3 (sensor-driven suggestions)** — cheap, on-brand, reuses the scored layer.
4. Everything else as pull demand dictates.
