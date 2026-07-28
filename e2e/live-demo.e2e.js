import { test, expect } from '@playwright/test';

test.describe('Lumen live demo', () => {
  test('hero shows interactive phone and guided steps', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByRole('heading', { level: 1 })).toContainText(/when your home shifts/i);
    await expect(page.getByText(/live interactive demo/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /home tab/i })).toBeVisible();
    await expect(page.getByText(/try the flow/i)).toBeVisible();
  });

  test('auto tab opens scene approval sheet', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');

    await demo.getByRole('button', { name: /auto tab/i }).click();
    await demo.getByRole('button', { name: /morning/i }).click();

    // The scene approval sheet mirrors the app's SceneApprovalSheet: an "Apply
    // scene" header for Morning and a plain "Apply" confirm button.
    await expect(demo.getByText(/apply scene/i)).toBeVisible();
    await expect(demo.getByRole('button', { name: /^apply$/i })).toBeVisible();
    await expect(demo.getByText('Power', { exact: true })).toBeVisible();
  });

  test('guided step drives reasoning sheet', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');

    await page.getByRole('button', { name: /lumen noticed/i }).click();

    await expect(demo.getByText(/why lumen noticed/i)).toBeVisible();
    await expect(demo.getByRole('button', { name: /apply evening/i })).toBeVisible();
  });

  test('flow card drives the live demo', async ({ page }) => {
    await page.goto('/');
    const demo = page.locator('#demo');
    const flow = page.locator('#flow');

    await flow.scrollIntoViewIfNeeded();
    await flow.getByRole('button', { name: /explains the why/i }).click();

    await expect(demo.getByText(/why lumen noticed/i)).toBeVisible();
  });

  test('opens full-screen app mode and plans a device', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: /open the app full screen/i }).click();

    const app = page.locator('.app-fullscreen');
    await expect(app).toBeVisible();

    // Rooms → Office (empty) → add a planned device.
    await app.getByRole('button', { name: /rooms tab/i }).click();
    await app.getByRole('button', { name: /office/i }).first().click();
    await app.getByRole('button', { name: /add a device/i }).click();
    await app.locator('.add-device-input').fill('Reading Lamp');
    const addButton = app.getByRole('button', { name: /^add device$/i });
    await expect(addButton).toBeEnabled();
    await addButton.click();

    await expect(app.getByRole('button', { name: /reading lamp/i })).toBeVisible();
    await expect(app.locator('.planned-dot')).toBeVisible();

    // Close returns to the marketing page.
    await app.getByRole('button', { name: /close app preview/i }).click();
    await expect(page.locator('.app-fullscreen')).toHaveCount(0);
  });
});
