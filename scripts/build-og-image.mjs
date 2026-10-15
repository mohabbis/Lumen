/** Generate the social card from a real screenshot of the current demo. */
import { chromium } from "@playwright/test";
const site = process.env.SITE_URL || "http://127.0.0.1:4173";
const browser = await chromium.launch(
  process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {},
);
try {
  const page = await browser.newPage({
    viewport: { width: 1440, height: 1100 },
    deviceScaleFactor: 2,
  });
  await page.goto(site, { waitUntil: "networkidle" });
  const image = await page.locator(".phone-frame").screenshot();
  const shot = image.toString("base64");
  await page.setViewportSize({ width: 1200, height: 627 });
  await page.setContent(`<!doctype html><html><head><meta charset="utf-8"><style>
    *{box-sizing:border-box}body{margin:0;width:1200px;height:627px;background:#0e0819;color:#f2ede7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;display:flex;align-items:center;padding:60px 90px;gap:70px}
    .copy{flex:1}.brand{color:#dfbc93;font-size:25px;margin-bottom:58px}h1{font-size:68px;line-height:1.06;letter-spacing:-4px;font-weight:450;margin:0 0 26px}p{font-size:18px;line-height:1.7;color:#b9b0c4;max-width:390px}.foot{font-size:13px;color:#dfbc93;margin-top:34px}img{width:275px;height:auto;border-radius:30px;box-shadow:0 25px 70px #0007}
    </style></head><body><div class="copy"><div class="brand">Lumen</div><h1>Your home.<br>Less to manage.</h1><p>A calmer home companion for rooms, devices, and everyday routines.</p><div class="foot">iPhone & iPad · Join the beta waitlist</div></div><img src="data:image/png;base64,${shot}" alt="Interactive Lumen preview"></body></html>`);
  await page.screenshot({ path: "public/Lumen-thumbnail.png" });
  console.log(
    "Generated public/Lumen-thumbnail.png from the current interactive preview.",
  );
} finally {
  await browser.close();
}
