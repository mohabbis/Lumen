/**
 * Renders public/Lumen-thumbnail.png, the Open Graph card.
 *
 * The card is a real screenshot of the running preview beside the site's own
 * headline, so the link preview shows the app as it actually is. It is not a
 * hand-drawn mockup, and it must not become one: if the preview changes, run
 * this again rather than editing the PNG.
 *
 *   npm run build && npm run preview   # in one terminal
 *   npm run og                         # in another
 */
import { chromium } from '@playwright/test';
import { mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const SITE = process.env.OG_SITE_URL ?? 'http://127.0.0.1:4173/';
const OUT = new URL('../public/Lumen-thumbnail.png', import.meta.url).pathname;
const EXECUTABLE_PATH = process.env.CHROMIUM_PATH || undefined;

const HEADLINE_LEAD = 'A home app that ';
const HEADLINE_ACCENT = 'asks before it acts.';
const SUBHEAD = 'One suggestion at a time, explained in plain language. '
  + 'Nothing runs until you tap Apply.';

function card(phoneDataUri) {
  return `<!doctype html><html><head><meta charset="utf-8"/>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet"/>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{width:1200px;height:627px;overflow:hidden;
    background:radial-gradient(ellipse 70% 60% at 22% -20%, rgba(138,180,248,0.16) 0%, transparent 62%),
      linear-gradient(180deg,#0a0c12 0%,#08090d 55%,#060709 100%);
    color:#f4f6fb;font-family:'Inter',system-ui,sans-serif;
    display:flex;align-items:center;gap:56px;padding:0 64px;-webkit-font-smoothing:antialiased}
  .copy{flex:1;min-width:0}
  .mark{font-size:16px;font-weight:600;letter-spacing:0.3em;margin-bottom:36px}
  .badge{display:inline-flex;align-items:center;gap:8px;padding:6px 12px;border-radius:8px;
    border:1px solid rgba(138,180,248,0.28);background:rgba(138,180,248,0.08);
    font-family:'JetBrains Mono',monospace;font-size:11px;letter-spacing:0.08em;
    color:rgba(196,214,255,0.9);margin-bottom:22px}
  .badge i{width:5px;height:5px;border-radius:50%;background:#8ab4f8;display:block}
  h1{font-size:58px;font-weight:700;line-height:1.04;letter-spacing:-0.035em;margin-bottom:22px}
  h1 em{font-style:normal;color:#8ab4f8}
  p{font-size:19px;line-height:1.6;color:rgba(226,231,242,0.72);max-width:20em}
  .foot{margin-top:34px;font-family:'JetBrains Mono',monospace;font-size:13px;
    letter-spacing:0.06em;color:rgba(214,221,236,0.5)}
  .shot{width:286px;flex-shrink:0;border-radius:32px;overflow:hidden;
    box-shadow:0 40px 90px -30px rgba(0,0,0,0.85);transform:translateY(8px)}
  .shot img{display:block;width:100%}
</style></head><body>
  <div class="copy">
    <div class="mark">LUMEN</div>
    <div class="badge"><i></i>Beta on TestFlight</div>
    <h1>${HEADLINE_LEAD}<em>${HEADLINE_ACCENT}</em></h1>
    <p>${SUBHEAD}</p>
    <div class="foot">iPhone and iPad &nbsp;&middot;&nbsp; lumen.muharafiq.com</div>
  </div>
  <div class="shot"><img src="${phoneDataUri}"/></div>
</body></html>`;
}

const browser = await chromium.launch({ executablePath: EXECUTABLE_PATH });
const work = await mkdtemp(join(tmpdir(), 'lumen-og-'));

try {
  // 1. Photograph the live preview.
  const site = await browser.newPage({
    viewport: { width: 1440, height: 1200 },
    deviceScaleFactor: 3,
  });
  await site.goto(SITE, { waitUntil: 'networkidle' });
  await site.waitForTimeout(1200);
  const phonePath = join(work, 'phone.png');
  await site.locator('.app-preview-stage').first().screenshot({ path: phonePath });
  await site.close();

  const phoneDataUri = `data:image/png;base64,${(await readFile(phonePath)).toString('base64')}`;

  // 2. Lay it out beside the headline and shoot the card at 1200x627.
  const cardPath = join(work, 'card.html');
  await writeFile(cardPath, card(phoneDataUri));
  const page = await browser.newPage({
    viewport: { width: 1200, height: 627 },
    deviceScaleFactor: 2,
  });
  await page.goto(`file://${cardPath}`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: OUT });
  console.log(`wrote ${OUT}`);
} finally {
  await browser.close();
}
