import { test, expect } from '@playwright/test';

test.describe('Lumen live demo', () => {
  test('hero shows interactive preview and guided steps', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByRole('heading', { level: 1 })).toContainText(/when your home shifts/i);
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
    await expect(demo.getByText(/lumen will/i)).toBeVisible();
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

  test('mobile stage is tappable without a nested bezel', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto('/');

    const stage = page.locator('.app-preview-stage');
    await expect(stage).toBeVisible();
    await expect(page.locator('#demo .phone.phone-featured')).toHaveCount(0);
    await expect(page.getByRole('button', { name: /home tab/i })).toBeVisible();

    await page.getByRole('button', { name: /auto tab/i }).click();
    await expect(page.getByRole('button', { name: /morning/i })).toBeVisible();
  });
});
