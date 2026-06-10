# Car Wash Guys Website

Cloudflare-deployed Astro website for **Car Wash Guys** in Kenosha, Wisconsin.

## Business context

- Business: Car Wash Guys
- Address: 2918 Washington Rd, Kenosha, WI
- Domain: https://carwashguys.us
- Deployment target: Cloudflare Workers / Cloudflare-managed domain
- Current status: landing page / launch placeholder while services, hours, pricing, and photos are finalized

## Current site state

This repo contains a branded Astro landing page rather than the default Astro blog starter. The home page includes:

- Hero section with Car Wash Guys branding
- Location CTA for 2918 Washington Rd
- Coming-soon / launch status messaging
- Services teaser cards without inventing unconfirmed pricing or package names
- Branded placeholder pages for `/about` and `/blog`
- Disabled starter blog post routes
- Disabled starter RSS feed
- Sitemap configured for `https://carwashguys.us`

## Local development

```bash
npm install
npm run dev
```

Astro usually starts at:

```txt
http://localhost:4321
```

## Build

```bash
npm run build
```

A successful build writes output to:

```txt
dist/
```

The full-clone build succeeded locally on June 10, 2026 after the starter cleanup.

## Deploy

Use Cloudflare credentials locally, then run:

```bash
npm run deploy
```

The repo uses `@astrojs/cloudflare` and Wrangler. The domain `carwashguys.us` is managed through Cloudflare.

## Content rules

Do not invent public business details. Only add these when confirmed:

- Phone number
- Hours
- Wash package names
- Pricing
- Reviews or testimonials
- Membership checkout links
- Final service list
- Grand opening date

Use placeholders until those details are provided.

## Future DRB / membership integration

The site should be ready for future membership workflows. Possible approaches:

- Link to a DRB-hosted checkout
- Add a configurable membership CTA URL
- Add a provider handoff page
- Add iframe or redirect flow if approved by the provider
- Add future API routes for member lookup or account management only after provider details are confirmed

## Recommended dependency cleanup

The site no longer needs the starter RSS or MDX features. Run this locally so `package-lock.json` is regenerated correctly:

```bash
npm uninstall @astrojs/mdx @astrojs/rss
npm run build
git add package.json package-lock.json
git commit -m "Remove unused starter dependencies"
git push origin main
```

Manual lockfile surgery is how small websites acquire cursed artifacts. Let npm do the boring part.
