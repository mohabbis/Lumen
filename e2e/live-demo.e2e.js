import { test, expect } from '@playwright/test';

test.describe('Lumen live demo', () => {
  test('hero shows interactive preview and guided steps', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByRole('heading', { level: 1 })).toContainText(/asks before it acts/i);
    await expect(page.getByText(/^interactive preview$/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /home tab/i })).toBeVisible();
    await expect(page.getByText(/try the flow/i)).toBeVisible();
  });

  test('consent loop runs on the in-page stage', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');

    await demo.getByRole('button', { name: /review evening scene/i }).click();
    await expect(demo.getByText(/why lumen noticed/i)).toBeVisible();
    await demo.getByRole('button', { name: /apply evening/i }).click();
    await expect(demo.getByText('Lumen will', { exact: true })).toBeVisible();
    await demo.getByRole('button', { name: /^apply$/i }).click();
    await expect(demo.getByText(/evening scene applied/i)).toBeVisible();
  });

  test('auto tab opens scene approval sheet', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');

    await demo.getByRole('button', { name: /auto tab/i }).click();
    await demo.getByRole('button', { name: /morning/i }).click();

    await expect(demo.getByText(/apply scene/i)).toBeVisible();
    await expect(demo.getByRole('button', { name: /^apply$/i })).toBeVisible();
    await expect(demo.getByText('Power', { exact: true })).toBeVisible();
  });

  test('guided step drives reasoning sheet', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');

    await page.getByRole('button', { name: /lumen noticed: tap the suggestion card/i }).click();

    await expect(demo.getByText(/why lumen noticed/i)).toBeVisible();
    await expect(demo.getByRole('button', { name: /apply evening/i })).toBeVisible();
  });

  test('guided execution step applies the scene', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');

    await page.getByRole('button', { name: /runs: see it apply/i }).click();

    await expect(demo.getByText(/evening scene applied/i)).toBeVisible();
  });

  test('flow card drives the preview', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');
    const flow = page.locator('#flow');

    await flow.scrollIntoViewIfNeeded();
    await flow.getByRole('button', { name: /explains the why/i }).click();

    await expect(demo.getByText(/why lumen noticed/i)).toBeVisible();
  });

  test('expands preview and plans a device', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: /expand preview/i }).click();

    const app = page.locator('.app-fullscreen');
    await expect(app).toBeVisible();

    await app.getByRole('button', { name: /rooms tab/i }).click();
    await app.getByRole('button', { name: /office/i }).first().click();
    await app.getByRole('button', { name: /add a device/i }).click();
    await app.locator('.add-device-input').fill('Reading Lamp');
    const addButton = app.getByRole('button', { name: /^add device$/i });
    await expect(addButton).toBeEnabled();
    await addButton.click();

    await expect(app.getByRole('button', { name: /reading lamp/i })).toBeVisible();
    await expect(app.locator('.planned-dot')).toBeVisible();

    await app.getByRole('button', { name: /close app preview/i }).click();
    await expect(page.locator('.app-fullscreen')).toHaveCount(0);
  });

  test('preview rows keep their height instead of being crushed', async ({ page }) => {
    // .app-screen is a column flex container, so its children shrink below
    // their own content by default rather than letting the screen scroll. That
    // squeezed the "Lumen noticed" card from 106px down to 14px at common
    // laptop sizes. Check the short viewport, where the squeeze was worst.
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto('/');

    const crushed = await page.evaluate(() => {
      const screen = document.querySelector('.app-preview-stage .app-screen');
      return [...screen.children]
        .filter(el => el.scrollHeight > el.clientHeight + 2)
        .map(el => `${el.className}: ${el.scrollHeight} > ${el.clientHeight}`);
    });

    expect(crushed).toEqual([]);
  });

  test('no button in the preview or its chrome is capsule-shaped', async ({ page }) => {
    // The native app uses RoundedRectangle(cornerRadius: 18) for its buttons;
    // capsules there are grab handles, progress bars and the iOS switch. A
    // fully-rounded button is the landing-page tell we removed, so keep it out.
    await page.goto('/');
    await page.locator('#demo').getByRole('button', { name: /review evening scene/i }).click();
    await expect(page.locator('#demo').getByText(/why lumen noticed/i)).toBeVisible();

    const pills = await page.evaluate(() => {
      const out = [];
      for (const el of document.querySelectorAll('button, a[href]')) {
        if (el.offsetParent === null) continue;
        const h = el.getBoundingClientRect().height;
        const cs = getComputedStyle(el);
        if (!h || cs.borderRadius.includes('%')) continue; // circular icon buttons are fine
        if (parseFloat(cs.borderRadius) >= h / 2 - 0.5) {
          out.push(`${el.className}: r=${cs.borderRadius} h=${Math.round(h)}`);
        }
      }
      return out;
    });

    expect(pills).toEqual([]);
  });

  test('mobile stage is tappable without a nested bezel', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto('/');

    const stage = page.locator('.app-preview-stage');
    await expect(stage).toBeVisible();
    await expect(page.locator('#demo .phone.phone-featured')).toHaveCount(0);
    await expect(page.getByRole('button', { name: /home tab/i })).toBeVisible();

    await page.getByRole('button', { name: /auto tab/i }).click({ force: false });
    await expect(page.locator('#demo').getByRole('button', { name: /morning/i })).toBeVisible();
  });
});
