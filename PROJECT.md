# Lumen

Local-first iOS smart-home companion (bundle ID `com.muharafiq.lumen`, team `CU67F9EY3Q`) plus a React/Vite marketing site at `lumen.muharafiq.com`.

## What this repo is

| Path | Role |
|------|------|
| `Lumen/` | Native SwiftUI / SwiftData iOS app |
| `Lumen.xcodeproj/` | Xcode project |
| `LumenTests/` | XCTest suite |
| `src/`, `public/`, `api/`, `lib/` | Marketing waitlist site (Vercel) |

The iOS app and marketing site are independent lanes. Prefer `AGENTS.md` / `CLAUDE.md` for architecture and conventions, `ROADMAP.md` for phased launch planning, and `docs/product-brief.md` for product framing.

## Local development

**iOS (macOS / Xcode):** open `Lumen.xcodeproj`, run on iPhone or iPad Simulator.

**Web:**

```bash
npm install
npm run dev      # http://0.0.0.0:5173
npm run ci       # lint + Vitest + build + Playwright e2e
```

Playwright browsers: `npx playwright install chromium` (also done in GitHub Actions CI).

## Authoritative docs

- [`AGENTS.md`](AGENTS.md) — agent / contributor guide (mirrored by `CLAUDE.md`)
- [`ROADMAP.md`](ROADMAP.md) — launch phases
- [`docs/full-audit-2026-07.md`](docs/full-audit-2026-07.md) — latest full audit snapshot
- [`docs/`](docs/) — product brief, design principles, manual QA, launch plan

Do not use stale Astro / unrelated business placeholders; the production web entry is `index.html` → `src/main.jsx` → `src/App.jsx`.
