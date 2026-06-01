# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev        # start dev server (0.0.0.0:5173)
npm run build      # production build → dist/
npm run preview    # serve dist/ at 0.0.0.0:4173
npm run lint       # ESLint over src/
npm run test       # vitest unit tests (single run)
npm run test:watch # vitest in watch mode
npm run e2e        # Playwright tests (requires preview server running on :4173)
npm run ci         # lint + test + build (full gate)
```

To run a single test file: `npx vitest run src/main.test.jsx`

## Architecture

**Single-page React app** built with Vite. No router — all sections are anchor-scrolled on one page. The privacy policy is a fully standalone HTML file served as a static asset.

### Key files

| File | Role |
|------|------|
| `src/App.jsx` | Entire app — all components defined and rendered here |
| `src/App.css` | All styles for the React app (dark luxury editorial theme) |
| `public/privacy/index.html` | Self-contained privacy page (own CSS + JS, no React) |
| `vercel.json` | Rewrites `/privacy` → `/privacy/index.html` for clean URL routing |

### Component structure (all in `src/App.jsx`)

- `App` — shell, sticky nav with mobile menu state, all sections composed here
- `ProductGallery` — tabbed phone mockup viewer driven by `screens[]` data array
- `SensorVisualization` — live room sensor board + reasoning timeline
- `Architecture` — Muhome architecture diagram + tech stack grid
- `Waitlist` — email form with Supabase/endpoint/mailto fallback chain
- `AppScreen` / `FadeIn` — shared primitives (phone mockup renderer, motion wrapper)

### Styling

All styles live in `src/App.css` (imported by `App.jsx`). `src/styles.css` is a legacy file — it is not imported anywhere and can be ignored. The privacy page is fully self-contained and does not share CSS with the React app.

Design tokens (CSS custom properties) are not formally extracted — colours and spacing are inline in `App.css`. Core palette: `#080808` bg, `#e8e0d4` text, `#c8b89a` accent.

### Waitlist form logic

`Waitlist` checks env vars in priority order:
1. `VITE_WAITLIST_ENDPOINT` — POST to any custom endpoint
2. `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` — POST to `{url}/rest/v1/lumen_waitlist`
3. Falls back to `mailto:m.rafiq2006@icloud.com`

Supabase table requires RLS with an anon insert policy to accept submissions.

### Tests

`src/main.test.jsx` is **stale** — it references an older version of the app (different headings, nav links, and form fields). Running `npm test` will fail. Tests need to be rewritten against the current `App.jsx` before `npm run ci` can pass cleanly.

### Deployment

Deployed on Vercel. The `public/` directory is copied verbatim to the build output, so `public/privacy/index.html` is served at `/privacy/index.html`. The rewrite in `vercel.json` makes `/privacy` resolve to it.
