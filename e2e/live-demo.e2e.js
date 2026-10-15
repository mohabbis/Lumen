import { test, expect } from "@playwright/test";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const tab = (page, name) =>
  page
    .getByRole("navigation", { name: "Preview navigation" })
    .getByRole("button", { name, exact: true });
test.beforeEach(async ({ page }) => {
  await page.goto("/");
});
test("first visit: explore, close, then reach signup", async ({ page }) => {
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.getByRole("button", { name: "Try Lumen", exact: true }).click();
  await expect(
    page.getByRole("dialog", { name: "Interactive Lumen preview" }),
  ).toBeVisible();
  await tab(page, "Rooms").click();
  await page.getByRole("button", { name: "Office No devices" }).click();
  await expect(page.getByText("A little possibility.")).toBeVisible();
  await page.getByRole("button", { name: "Close preview" }).click();
  await page
    .getByRole("link", { name: "Join the waitlist", exact: true })
    .first()
    .click();
  await expect(
    page.getByRole("textbox", { name: "Your email address" }),
  ).toBeInViewport();
  expect(errors).toEqual([]);
});
test("lighting: keyboard adjustments synchronize across rooms, Intel, and Home", async ({
  page,
}) => {
  await page.getByRole("button", { name: "Expand preview" }).click();
  await page.getByRole("button", { name: "Living Room 2 lights on" }).click();
  await page.getByRole("button", { name: "Ceiling Light On · 72%" }).click();
  const slider = page.getByRole("slider", { name: "Brightness" });
  await slider.focus();
  await slider.press("Home");
  await slider.press("ArrowRight");
  await expect(slider).toHaveValue("1");
  await page.getByRole("button", { name: "Apply changes" }).click();
  await expect(
    page.getByRole("button", { name: "Ceiling Light On · 1%" }),
  ).toBeVisible();
  await tab(page, "Intel").click();
  await page.getByRole("button", { name: "Ceiling Light On · 1%" }).click();
  await page.getByRole("switch", { name: "Ceiling Light power" }).click();
  await expect(page.getByRole("slider", { name: "Brightness" })).toBeDisabled();
  await page.getByRole("button", { name: "Apply changes" }).click();
  await tab(page, "Home").click();
  await expect(
    page.getByRole("button", { name: "Living Room 1 light on" }),
  ).toBeVisible();
});
test("scene: preview and cancel before approving exact grouped changes", async ({
  page,
}) => {
  await tab(page, "Auto").click();
  await page.getByRole("button", { name: /Evening Softer/ }).click();
  await expect(
    page.getByText("Power on · 40% brightness · 2700 K"),
  ).toHaveCount(2);
  await page.getByRole("button", { name: "Cancel", exact: true }).click();
  await tab(page, "Intel").click();
  await expect(
    page.getByRole("button", { name: "Ceiling Light On · 72%" }),
  ).toBeVisible();
  await tab(page, "Auto").click();
  await page.getByRole("button", { name: /Evening Softer/ }).click();
  await page
    .getByRole("button", { name: "Apply Evening", exact: true })
    .click();
  await tab(page, "Intel").click();
  await expect(
    page.getByRole("button", { name: "Ceiling Light On · 40%" }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Pendant Light Off" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Ceiling Light On · 40%" }).click();
  await expect(
    page.getByRole("slider", { name: "Color temperature" }),
  ).toHaveValue("2700");
});
test("suggestion: reasoning and dismissal never alter device state", async ({
  page,
}) => {
  await page.getByRole("button", { name: /Lumen noticed A softer/ }).click();
  await expect(
    page.getByRole("dialog", { name: "A softer evening?" }),
  ).toBeVisible();
  await expect(page.getByText("Time of day", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Not now" }).click();
  await expect(page.getByText("Your home, your pace.")).toBeVisible();
  await tab(page, "Intel").click();
  await expect(
    page.getByRole("button", { name: "Ceiling Light On · 72%" }),
  ).toBeVisible();
});
test("guide: skip, restart, apply, and reset leave coherent state", async ({
  page,
}) => {
  await page.getByRole("button", { name: "Try an evening routine" }).click();
  await page.getByRole("button", { name: "Skip walkthrough" }).click();
  await page.getByRole("button", { name: "Close preview" }).click();
  await page.getByRole("button", { name: "Try an evening routine" }).click();
  await page
    .getByRole("button", { name: "Apply Evening", exact: true })
    .click();
  await expect(page.getByText(/Step 2 of 2 · Evening applied/)).toBeVisible();
  await page.getByRole("button", { name: "Restart", exact: true }).click();
  await page.keyboard.press("Escape");
  await page.getByRole("button", { name: "Reset demo", exact: true }).click();
  await expect(
    page.getByRole("button", { name: /Lumen noticed A softer/ }),
  ).toBeVisible();
  await tab(page, "Intel").click();
  await expect(
    page.getByRole("button", { name: "Ceiling Light On · 72%" }),
  ).toBeVisible();
});
test("dialogs: focus traps, nested Escape, restoration, and scroll locking", async ({
  page,
}) => {
  const open = page.getByRole("button", { name: "Expand preview" });
  await open.click();
  await expect(
    page.getByRole("button", { name: "Close preview" }),
  ).toBeFocused();
  await expect(page.locator("body")).toHaveCSS("overflow", "hidden");
  await page.getByRole("button", { name: /Lumen noticed A softer/ }).click();
  const sheet = page.getByRole("dialog", { name: "A softer evening?" });
  for (let i = 0; i < 8; i++) await page.keyboard.press("Tab");
  expect(
    await sheet.evaluate((element) => element.contains(document.activeElement)),
  ).toBe(true);
  await page.keyboard.press("Escape");
  await expect(sheet).not.toBeVisible();
  await expect(
    page.getByRole("button", { name: /Lumen noticed A softer/ }),
  ).toBeFocused();
  await expect(
    page.getByRole("dialog", { name: "Interactive Lumen preview" }),
  ).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(open).toBeFocused();
  await expect(page.locator("body")).not.toHaveCSS("overflow", "hidden");
});
test("unavailable devices, temperature, and sensory controls are honest", async ({
  page,
}) => {
  await tab(page, "Intel").click();
  await page.getByRole("button", { name: "Window Sensor Unavailable" }).click();
  await expect(page.getByText(/no changes can be sent/)).toBeVisible();
  await expect(page.getByRole("button", { name: "Apply changes" })).toHaveCount(
    0,
  );
  await page.getByRole("button", { name: "Close", exact: true }).click();
  await page.getByRole("button", { name: "Thermostat 21°C" }).click();
  await page.getByRole("slider", { name: "Temperature" }).press("End");
  await page.getByRole("button", { name: "Apply changes" }).click();
  await expect(
    page.getByRole("button", { name: "Thermostat 28°C" }),
  ).toBeVisible();
  await tab(page, "Settings").click();
  const sensory = page.getByRole("switch", { name: "Reduced stimulation" });
  await sensory.click();
  await expect(sensory).toBeChecked();
});
test("rapid navigation and repeated scene activation do not duplicate executions", async ({
  page,
}) => {
  for (let i = 0; i < 3; i++)
    for (const name of ["Auto", "Intel", "Rooms", "Home"])
      await tab(page, name).click();
  await tab(page, "Auto").click();
  await page.getByRole("button", { name: /Evening Softer/ }).click();
  await page
    .getByRole("button", { name: "Apply Evening", exact: true })
    .evaluate((button) => {
      button.click();
      button.click();
    });
  await expect(page.locator(".execution-history p")).toHaveCount(1);
});
test("signup: validation, failure, recovery, and acknowledged success", async ({
  page,
}) => {
  let count = 0;
  await page.route("**/api/waitlist", async (route) => {
    count++;
    const data = route.request().postDataJSON();
    expect(data.email).toBe("hello@example.com");
    expect(Object.keys(data).sort()).toEqual(["email", "source"]);
    await route.fulfill({
      status: count === 1 ? 503 : 200,
      json: { ok: count !== 1 },
    });
  });
  const input = page.getByRole("textbox", { name: "Your email address" });
  const submit = page.getByRole("button", {
    name: "Join the waitlist",
    exact: true,
  });
  await submit.click();
  await expect(page.getByRole("alert")).toContainText("valid email");
  await input.fill("HELLO@example.com");
  await submit.click();
  await expect(page.getByRole("alert")).toContainText("couldn’t confirm");
  await expect(input).toHaveValue("HELLO@example.com");
  await submit.click();
  await expect(page.getByText(/You’re on the waitlist/)).toBeVisible();
  await expect(input).toHaveValue("");
  expect(count).toBe(2);
  const events = await page.evaluate(() => window.dataLayer);
  expect(
    events.filter((event) => event.event === "waitlist_submit_success"),
  ).toHaveLength(1);
  expect(JSON.stringify(events)).not.toContain("hello@example.com");
});
test("responsive layouts, touch controls, and mobile navigation", async ({
  page,
  browserName,
}) => {
  for (const width of [320, 375, 390, 430, 768, 1024, 1440]) {
    await page.setViewportSize({ width, height: width < 768 ? 844 : 1000 });
    await expect(page.locator("h1")).toBeVisible();
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
    if (browserName === "chromium")
      await page.screenshot({
        path: "docs/qa/website-" + width + ".png",
        fullPage: true,
      });
    if (width < 768) {
      await page.getByRole("button", { name: "Open menu" }).click();
      await page
        .getByRole("navigation", { name: "Main navigation" })
        .getByRole("link", { name: "The details" })
        .click();
      await expect(
        page.getByRole("button", { name: "Open menu" }),
      ).toHaveAttribute("aria-expanded", "false");
    }
    await page.getByRole("button", { name: "Expand preview" }).click();
    await expect(
      page.getByRole("button", { name: "Close preview" }),
    ).toBeInViewport();
    await page.getByRole("button", { name: /Lumen noticed A softer/ }).click();
    await expect(
      page.getByRole("button", { name: "Apply Evening", exact: true }),
    ).toBeInViewport();
    if (browserName === "chromium" && [390, 1440].includes(width))
      await page.screenshot({ path: "docs/qa/reasoning-" + width + ".png" });
    await page.keyboard.press("Escape");
    await page.keyboard.press("Escape");
  }
  await page.setViewportSize({ width: 844, height: 390 });
  await page.getByRole("button", { name: "Expand preview" }).click();
  await tab(page, "Auto").click();
  await page.getByRole("button", { name: /Evening Softer/ }).click();
  await page
    .getByRole("button", { name: "Apply Evening", exact: true })
    .scrollIntoViewIfNeeded();
  await expect(
    page.getByRole("button", { name: "Apply Evening", exact: true }),
  ).toBeInViewport();
});
test("automated accessibility on page, expanded preview, and sheet", async ({
  page,
}) => {
  await page.addScriptTag({ path: require.resolve("axe-core/axe.min.js") });
  const violations = () =>
    page.evaluate(async () =>
      (
        await window.axe.run(document, {
          runOnly: {
            type: "tag",
            values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"],
          },
        })
      ).violations.map((item) => ({
        id: item.id,
        nodes: item.nodes.map((node) => node.target),
      })),
    );
  expect(await violations()).toEqual([]);
  await page.getByRole("button", { name: "Expand preview" }).click();
  expect(await violations()).toEqual([]);
  await page.getByRole("button", { name: /Lumen noticed A softer/ }).click();
  expect(await violations()).toEqual([]);
});
test("reduced motion and legal destinations stay usable", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.reload();
  expect(
    await page
      .locator("html")
      .evaluate((element) => getComputedStyle(element).scrollBehavior),
  ).toBe("auto");
  await page.getByRole("button", { name: "Try Lumen", exact: true }).click();
  await page.getByRole("button", { name: "Close preview" }).click();
  for (const path of ["/privacy/index.html", "/terms/index.html"]) {
    await page.goto(path);
    await expect(page.locator("h1")).toBeVisible();
  }
});

test("phone touch: navigation, staged sliders, and approval respond to taps", async ({
  browser,
  baseURL,
}) => {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    hasTouch: true,
  });
  const page = await context.newPage();
  try {
    await page.goto(baseURL);
    await page.getByRole("button", { name: "Try Lumen", exact: true }).tap();
    await tab(page, "Rooms").tap();
    await page.getByRole("button", { name: "Living Room 2 lights on" }).tap();
    await page.getByRole("button", { name: "Ceiling Light On · 72%" }).tap();
    const slider = page.getByRole("slider", { name: "Brightness" });
    const box = await slider.boundingBox();
    await page.touchscreen.tap(box.x + box.width * 0.3, box.y + box.height / 2);
    const value = await slider.inputValue();
    expect(Number(value)).toBeLessThan(40);
    await page.getByRole("button", { name: "Apply changes" }).tap();
    await expect(
      page.getByRole("button", { name: "Ceiling Light On · " + value + "%" }),
    ).toBeVisible();
    await page.getByRole("button", { name: "Close preview" }).tap();
  } finally {
    await context.close();
  }
});
