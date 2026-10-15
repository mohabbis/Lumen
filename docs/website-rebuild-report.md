# Lumen website rebuild delivery

October 15, 2026. Local implementation and verification; no production deployment.

## 1. Executive summary

Rebuilt the marketing experience into six substantive sections around one working product simulation. The page now introduces Lumen concretely, gives visitors a useful evening routine to try, qualifies device compatibility and automation permissions, and consistently offers the beta waitlist.

The browser demo uses one reducer and one device registry. Device controls, room counts, scenes, suggestions, navigation, reset, and expanded presentation share that state. The signup API and existing server delivery providers are preserved, with stricter acknowledgement and safer failure handling.

The workspace changed revisions during the work. The initial checkout did not build; the restored newer web implementation was then audited and incorporated. Native changes and commits made elsewhere in the workspace were preserved. No native source or Xcode configuration was edited by this implementation.

## 2. Design changes

The approved direction uses aubergine, brass, warm white, and muted lavender, with a system sans-serif type scale and fewer competing surfaces. The frontend-design skill informed the restrained hierarchy, subject-specific architectural light treatment, and limited decorative elements. The room illustration is explicitly labeled as an illustration, not a native screenshot.

The hero names the practical benefit: “Your home. Less to manage.” Product appearance and interaction are visible immediately. Mobile uses its own stacked composition, with an edge-to-edge expanded demo instead of a scaled desktop phone. Repetitive feature sections, unsupported conversational-AI mockups, the marketing theme toggle, autoplay, and incomplete authoring controls were removed.

The social image is regenerated from a screenshot of the real browser preview. Legal pages and the favicon use the updated palette. Robots and sitemap files cover the real public routes.

Visual evidence: [desktop hero](qa/hero-1440.png), [mobile hero](qa/hero-390.png), [mobile reasoning](qa/reasoning-390.png), [full desktop page](qa/website-1440.png), [full mobile page](qa/website-390.png). Before screenshots capture the deployed production revision, not the initially broken local checkout: [desktop before](qa/before-production-1440.png), [mobile before](qa/before-production-390.png).

## 3. Demo repairs

The complete [interaction inventory](website-interaction-audit.md) records intended behavior, baseline findings, state dependencies, final feedback, and accessibility/mobile verification.

Key repairs include device-specific scene operations, controlled native sliders, explicit staged device changes, honest unavailable states, derived room summaries, reliable tab/back navigation, complete reset, and one optional guided routine. Confirmation is idempotent: repeated approval cannot execute an already-closed pending scene twice.

Expanded mode retains the same simulator instance. It locks page scrolling, makes background content inert, traps focus, handles nested Escape, and restores focus. Browser testing found and fixed Safari pointer-focus restoration, native dialog focus wrapping, a tablet decorative overflow, a marketing-to-simulator heading style leak, and a room label-in-name mismatch.

The native/browser differences are documented in the interaction inventory. The preview is clearly a simulation and makes no hardware or location requests.

## 4. Architecture changes

- `DemoContext` owns reducer state and UI opener refs. `demoModel` contains fixtures, pure selectors, bounded updates, scenes, guidance, and reset.
- `DemoScreens`, `DemoSheets`, and `InteractiveDemo` separate screen rendering, confirmation surfaces, and presentation/focus behavior.
- `Dialog` is a reusable native modal with focus handling. `Waitlist` is isolated from marketing composition.
- Styles are split into tokens, base, marketing, and simulator files. The old six active stylesheets and their override chains were removed.
- Stylesheet source decreased from 103,307 bytes to approximately 36 KB, about 65% less. Final built CSS is 28.39 KB, 6.77 KB gzipped. Main JavaScript is approximately 236.6 KB, 73.7 KB gzipped.
- Removed the unused Framer Motion dependency. There are no remote font requests or autoplay timers on the rebuilt homepage.
- The browser makes one POST to `VITE_WAITLIST_ENDPOINT` or `/api/waitlist`, preserving `{ email, source }`. An accepted API response must contain `{ ok: true }`; custom endpoints must implement that acknowledgement contract. Explicit duplicate responses can use HTTP 409 with `code: "already_subscribed"`.
- Server integrations remain in their existing order. Ambiguous network failures stop fallback. Provider acceptance is distinguished from inbox delivery; no persistent global deduplication claim is made.

## 5. Files modified

Meaningful changes, relative to the restored web baseline:

| Area | Files |
| --- | --- |
| Composition and entry | `src/App.jsx`, `src/main.jsx`, `index.html` |
| Shared controls and signup | `src/components/Dialog.jsx`, `src/components/Waitlist.jsx`, `src/siteConfig.js`, `src/waitlistSubmit.js`, `src/waitlistAnalytics.js` |
| Demo | `src/demo/DemoContext.jsx`, `src/demo/demoModel.js`, `src/demo/DemoScreens.jsx`, `src/demo/DemoSheets.jsx`, `src/demo/InteractiveDemo.jsx`, `src/demo/simulator.css` |
| Styles | `src/styles/tokens.css`, `src/styles/base.css`, `src/styles/marketing.css` |
| Backend | `api/waitlist.js`, `lib/waitlist.js` |
| Unit/API tests | `src/main.test.jsx`, `src/demo/demoModel.test.js`, `src/waitlistSubmit.test.jsx`, `src/waitlistAnalytics.test.js`, `src/test/setup.js`, `lib/waitlist.test.js`, `api/waitlist.test.js` |
| Browser/build configuration | `e2e/live-demo.e2e.js`, `playwright.config.js`, `vitest.config.js`, `vite.config.js`, `eslint.config.js`, `.github/workflows/ci.yml` |
| Dependencies | `package.json`, `package-lock.json` |
| Public assets/pages | `public/favicon.svg`, `public/Lumen-thumbnail.png`, `public/privacy/index.html`, `public/terms/index.html`, `public/robots.txt`, `public/sitemap.xml` |
| Tooling and handoff | `scripts/build-og-image.mjs`, `scripts/capture-website.mjs`, this report, `docs/website-interaction-audit.md`, and screenshots/Lighthouse reports in `docs/qa/` |

Removed superseded files: `src/App.css`, `src/theme.css`, `src/simulator.css`, `src/mobile-polish.css`, `src/a11y-polish.css`, `src/lumen-overrides.css`, `src/FeatureSections.jsx`, `src/InteractivePhone.jsx`, `src/components/AIComingSoonSection.jsx`, `src/components/GettingStartedSection.jsx`, `src/components/GuidedDemoSteps.jsx`, `src/components/FadeIn.jsx`, and `src/hooks/useReducedMotion.js`. The old `src/waitlistSubmit.test.js` was replaced by its JSX test file. Removed tracked files are recoverable through Git.

## 6. Verification results

| Command | Result |
| --- | --- |
| `npm run lint` | Passed |
| `npm run test` | 44 unit, component, provider, analytics, and API tests passed |
| `npm run build` | Passed |
| `npm run e2e` | 39 scenarios passed across Chromium, WebKit, and Firefox |
| `npm run ci` | Passed the combined lint, test, build, and browser gate |
| `npm run og` | Generated the social card from the current demo |
| `node scripts/capture-website.mjs` | Captured seven layouts plus expanded, reasoning, hero, and signup states |
| `git diff --check` | Passed |

Browsers exercised 320, 375, 390, 430, 768, 1024, and 1440 pixel layouts plus 844×390 landscape. Coverage includes real emulated touchscreen events, keyboard sliders, empty rooms, unavailable devices, cross-screen changes, scene cancellation, rapid navigation, repeated confirmation, guidance, reset, focus, scroll locking, responsive menu behavior, reduced motion, legal pages, and mocked signup outcomes. Axe checks cover WCAG 2/2.1/2.2 A/AA tags in page, expanded, and dialog states.

Manual browser checks also opened the preview, inspected reasoning, approved Evening, and confirmed both living-room lights showed 40% and the kitchen showed zero lights on. Screenshots were visually reviewed. No physical iPhone, iPad, assistive-technology session, or real hardware was tested.

### Performance measurement

Lighthouse 13.5.0 against the local production preview, Chromium 148, Node 26.0.0, simulated mobile 412×823 at device scale 1.75, 4× CPU slowdown, 150 ms RTT and 1,638.4 Kbps throughput. The saved report contains the full configuration and audit data. The final run completed without Lighthouse warnings.

| Metric | Measured |
| --- | --- |
| Performance | 100 |
| Accessibility | 100 |
| Best practices | 100 |
| SEO | 100 |
| Largest Contentful Paint | 1.5 seconds |
| Cumulative Layout Shift | 0 |
| Total Blocking Time | 20 ms |

[Lighthouse HTML report](qa/lighthouse-mobile.report.html) and [raw JSON](qa/lighthouse-mobile.report.json).

Measurement command (with `CHROME_PATH` set to the installed Playwright Chromium executable):

```sh
npm exec --yes --package=lighthouse -- lighthouse http://127.0.0.1:4173 \
  --output=json --output=html --output-path=docs/qa/lighthouse-mobile \
  --chrome-flags='--headless=new --no-sandbox' \
  --only-categories=performance,accessibility,best-practices,seo --quiet
```

An additional unthrottled desktop interaction sample reported event durations of 16–32 ms. This is laboratory evidence only. Field INP is not available and is not inferred from Lighthouse or these samples. Production network and cache behavior may differ from localhost.

## 7. Remaining issues and verification limits

- No deployment was performed. The current production domain still represents the separately deployed revision.
- Actual waitlist storage, provider credentials, inbox delivery, and TestFlight availability were not verified. All submission tests used mocks; no real emails were sent. The interface promises a waitlist request, not immediate installation.
- The internal Vercel API does not execute under plain Vite preview. Without a configured external endpoint or Vercel runtime, local real signup correctly shows failure. Browser tests mock the endpoint deliberately.
- The server preserves existing provider fallback, including FormSubmit. Operator-side activation and delivery configuration still need a controlled production check before release. Ambiguous transport failures stop fallback, but durable duplicate prevention depends on the configured storage/provider.
- A custom endpoint must acknowledge acceptance with `{ ok: true }`. A bare HTTP 200 HTML page is rejected.
- The small demo intentionally omits native authoring, real bridges, location, schedules, IR/LAN controls, and most sensory settings. Native/browser consent-flow differences are explicitly documented.
- Automated accessibility scores do not replace screen-reader testing. Physical mobile behavior, field INP, and production hosting performance remain unmeasured.
- Before a later Vercel deployment, update the session’s reported outdated CLI with `npm i -g vercel@latest`; no global CLI upgrade or production configuration change was made here.

## 8. Critical assessment

| Area | Score / 10 | Reason |
| --- | --- | --- |
| Design | 8.3 | Coherent and restrained; real native beta screenshots and user research could strengthen it further. |
| Usability | 8.7 | Core simulation paths are consistent and tested; physical-device and screen-reader sessions remain. |
| Performance | 9.2 | Strong measured local mobile results and a small asset footprint; production and field data remain. |
| Credibility | 8.8 | Clear simulation, qualified compatibility, truthful automation wording, and conservative availability. |
| Conversion readiness | 7.5 | Clear single form and verified failure handling; live delivery and invitation availability still need confirmation. |

The code is ready for review and a controlled deployment check. The remaining release dependency is live integration verification, not unfinished simulator behavior.
