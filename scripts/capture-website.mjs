import { chromium } from '@playwright/test';

const site = process.env.SITE_URL || 'http://127.0.0.1:4173';
const browser = await chromium.launch();
try {
  for (const width of [320, 375, 390, 430, 768, 1024, 1440]) {
    const page = await browser.newPage({ viewport: { width, height: width < 768 ? 844 : 1000 }, deviceScaleFactor: 1 });
    await page.goto(site, { waitUntil: 'networkidle' });
    await page.screenshot({ path: `docs/qa/website-${width}.png`, fullPage: true });
    if ([390, 1440].includes(width)) {
      await page.locator('.hero').screenshot({ path: `docs/qa/hero-${width}.png` });
      await page.locator('#access').screenshot({ path: `docs/qa/signup-${width}.png` });
      await page.getByRole('button', { name: 'Expand preview' }).click();
      await page.evaluate(() => document.activeElement.blur());
      await page.screenshot({ path: `docs/qa/preview-${width}.png` });
      await page.getByRole('button', { name: /Lumen noticed A softer/ }).click();
      await page.evaluate(() => document.activeElement.blur());
      await page.screenshot({ path: `docs/qa/reasoning-${width}.png` });
    }
    await page.close();
  }
  console.log('Captured seven layouts plus hero, signup, expanded preview, and reasoning states.');
} finally { await browser.close(); }
