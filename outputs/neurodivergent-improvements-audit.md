# Neurodivergent-First Improvements & Issue Audit

**Purpose:** Identify gaps between Lumen's neurodivergent-first positioning and actual implementation. This document covers false claims, missing features, and concrete improvements.

---

## 🔴 Critical Issues (False Claims / Broken Promises)

### 1. Sensory Profile Settings Don't Actually Work
**Claim:** Lumen respects sensory limits and suggestion cadence preferences  
**Reality:** `SensoryProfile.dailySuggestionLimit` and `suggestionCadence` are defined but never enforced

**Files involved:**
- `/workspace/Lumen/Models/SensoryProfile.swift` - defines limits (2/4/unlimited)
- `/workspace/Lumen/Services/Intelligence/SuggestionEngine.swift` - ignores them completely
- `/workspace/docs/full-audit-2026-07.md` - explicitly flags this as open issue #9

**Impact:** Users who set "Quiet" mode (2 suggestions/day) still see unlimited suggestions. This breaks trust and could cause sensory overload.

**Fix required:**
```swift
// In SuggestionEngine.swift or calling layer:
func shouldShowSuggestion(todayCount: Int, profile: SensoryProfile) -> Bool {
    guard let limit = profile.dailySuggestionLimit else { return true }
    return todayCount < limit
}
```

---

### 2. "Calm Mode" Doesn't Reduce Motion System-Wide
**Claim:** `calmModeEnabled` reduces motion  
**Reality:** Only affects `shouldReduceMotion` boolean; not wired to SwiftUI `.accessibilityReducedMotion()` or animation suppression

**Files involved:**
- `/workspace/Lumen/Models/SensoryProfile.swift` line 29-31
- `/workspace/Lumen/Features/Settings/SettingsView.swift` - toggle exists
- Missing: Global animation controller that respects this setting

**Impact:** Users with vestibular disorders or motion sensitivity still see animations throughout the app.

**Fix required:**
- Create `@Environment` value for sensory profile
- Wrap all animations in conditional that checks `profile.shouldReduceMotion`
- Apply `.accessibilityReducedMotion(true)` when enabled

---

### 3. Transition Warnings Not Implemented
**Claim:** `transitionWarningMinutes` provides advance notice before scene execution  
**Reality:** Setting exists but no notification system uses it

**Files involved:**
- `/workspace/Lumen/Models/SensoryProfile.swift` line 11, 18, 25-27, 46
- Missing: Integration with `NotificationService` for pre-execution alerts

**Impact:** Users who need 15-minute warnings before environmental changes don't get them.

**Fix required:**
```swift
// Before executing any scene (manual or scheduled):
if profile.transitionWarningMinutes > 0 {
    NotificationService.scheduleWarning(
        title: "Lumen will run \"\(sceneName)\" in \(profile.transitionWarningMinutes) minutes",
        fireDate: Date().addingTimeInterval(-Double(profile.transitionWarningMinutes * 60))
    )
}
```

---

## 🟡 Medium Priority (Missing Features)

### 4. No Sensory Overload Prevention
**Problem:** Multiple suggestions can appear simultaneously during high-activity periods (evening arrival, morning routine)

**Recommendation:**
- Implement "quiet hours" where only critical notifications appear
- Add `maxSuggestionsPerHour` limit (e.g., 1 per hour regardless of cadence)
- Batch non-urgent suggestions into a single "Lumen noticed a few things..." card

---

### 5. Reasoning View Doesn't Show Factor Labels
**Problem:** `SuggestionFactor` objects contain explainable labels ("Fits evening", "Usual routine") but `LumenReasoningView` only shows confidence score

**Files involved:**
- `/workspace/Lumen/Services/Intelligence/SuggestionEngine.swift` - factors computed but dropped
- `/workspace/Lumen/Features/Home/LumenReasoningView.swift` - doesn't display factors
- `/workspace/docs/full-audit-2026-07.md` - issue #8

**Impact:** Explainability is a core neurodivergent need - users need to understand WHY something is suggested to feel safe approving it.

**Fix required:** Pass `factors` array through `ReasoningCalculator` and render as bullet list.

---

### 6. No "Overwhelm Escape Hatch"
**Problem:** When users are overstimulated, there's no quick way to silence all suggestions temporarily

**Recommendation:**
- Add "Pause suggestions for 1 hour / 2 hours / rest of day" button in Settings or Home tab
- Visual indicator when paused ("Suggestions muted until 8 PM")
- Respects sensory needs during meltdowns, visitors, illness, etc.

---

### 7. Color/Contrast Preferences Not Enforced
**Claim:** `contrastPreference` (.soft/.balanced/.clear) adjusts UI contrast  
**Reality:** Setting exists but no CSS/SwiftUI theme layer applies it

**Files involved:**
- `/workspace/Lumen/Models/SensoryProfile.swift` lines 10, 17, 45, 80-94
- Missing: Theme system that reads this preference

**Impact:** Users with light sensitivity or low vision don't get appropriate contrast levels.

**Fix required:**
- Create dynamic color tokens that adjust based on `contrastPreference`
- Apply `.opacity()` modifiers for "Soft" mode
- Ensure WCAG AA compliance for "Clear" mode

---

## 🟢 Low Priority (Polish / Future Enhancements)

### 8. Language Too Clinical in Places
**Problem:** Some UI text uses technical terms ("geofence", "reachability", "automation") instead of plain language

**Examples to fix:**
- "Geofence trigger" → "When you arrive/leave home"
- "Reachable devices" → "Devices that are working right now"
- "Scene execution" → "Running your scene"

**Files to audit:**
- All SwiftUI view files in `/workspace/Lumen/Features/`
- Marketing site `/workspace/src/App.jsx` and `/workspace/src/FeatureSections.jsx`

---

### 9. No Executive Function Scaffolding
**Problem:** ADHD users benefit from external cues, but Lumen doesn't offer:
- Visual progress indicators for multi-step routines
- "What should I do first?" guidance
- Gentle reminders without pressure

**Recommendation:**
- Optional "Step-by-step mode" for complex scenes (e.g., "Goodnight" shows: 1. Lock doors ✓ 2. Turn off lights 3. Adjust thermostat)
- Checkbox-style completion feedback
- Celebratory micro-interactions (subtle haptic + visual checkmark)

---

### 10. No Sensory Profile Onboarding
**Problem:** Users discover sensory settings buried in Settings tab; no guided setup explains benefits

**Recommendation:**
- First-launch flow: "Let's make Lumen comfortable for you" with 3 questions:
  1. "How many suggestions feel helpful?" (Quiet/Balanced/Supportive)
  2. "Do animations bother you?" (Reduce/Keep)
  3. "How much warning before changes?" (5/10/15 min)
- Auto-apply Calm Mode if user selects all "reduced" options

---

## ✅ What's Already Working Well

### Strengths to Preserve:
1. **Consent-before-action** - Scene approval sheets are genuinely calming
2. **Explainable suggestions** - Confidence scores + factor system (once surfaced)
3. **Local-first architecture** - No cloud anxiety, works offline
4. **Preview mode** - Safe testing without consequences
5. **Low-pressure language** - "Lumen noticed" vs "You should"
6. **Single suggestion focus** - Not overwhelming with multiple options

---

## 📋 Implementation Priority Order

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| P0 | Enforce `dailySuggestionLimit` | Low | High |
| P0 | Wire `calmModeEnabled` to reduce motion | Medium | High |
| P0 | Implement `transitionWarningMinutes` notifications | Medium | High |
| P1 | Surface `SuggestionFactor` labels in reasoning UI | Low | Medium |
| P1 | Add "Pause suggestions" escape hatch | Low | Medium |
| P1 | Apply `contrastPreference` to theme | Medium | Medium |
| P2 | Plain language audit across app | Medium | Medium |
| P2 | Sensory profile onboarding flow | High | Medium |
| P3 | Executive function scaffolding | High | Low-Medium |

---

## 🧪 Testing Requirements

Before claiming "neurodivergent-first":

1. **Recruit beta testers** with ADHD, autism, sensory processing differences
2. **Measure:**
   - Do users in "Quiet" mode actually see ≤2 suggestions/day?
   - Do motion-sensitive users report fewer symptoms?
   - Can users successfully set up transition warnings?
3. **Iterate** based on feedback before App Store launch

---

## 🚨 Marketing Claims That Need Qualification

Current website copy that overpromises:

| Claim | Issue | Suggested Revision |
|-------|-------|-------------------|
| "Built for calm" | Vague, unproven | "Designed with sensory-friendly settings" |
| "Nothing runs on its own" | Geofence scenes auto-execute | "Suggestions always ask first; opted-in arrival/departure scenes run with notification" |
| "Low cognitive load" | Not validated with target users | "Designed to reduce decision fatigue" |
| "Gentle suggestion" | Can overwhelm if limits not enforced | "One suggestion at a time, with daily limits you control" |

---

## References

- `/workspace/Lumen/Models/SensoryProfile.swift` - Current settings model
- `/workspace/Lumen/Services/Intelligence/SuggestionEngine.swift` - Scoring logic (ignores limits)
- `/workspace/docs/design-principles.md` - Stated principles (need sensory specifics)
- `/workspace/docs/full-audit-2026-07.md` - Audit findings (issues #8, #9)
- `/workspace/ROADMAP.md` - Mentions neurodivergent onboarding but no timeline

---

**Last updated:** Based on code review of main branch (July 2026 audit lineage)  
**Author:** Code analysis assistant
