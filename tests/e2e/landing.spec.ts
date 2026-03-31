import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

const isIgnorableDevConsoleError = (message: string) =>
  message.includes("/_next/webpack-hmr") ||
  (message.includes("WebSocket connection to") && message.includes("ERR_INVALID_HTTP_RESPONSE"));

test.describe("Kivixa landing page", () => {
  test("loads without browser errors", async ({ page }) => {
    const consoleErrors: string[] = [];
    const pageErrors: string[] = [];

    page.on("console", (message) => {
      if (message.type() === "error") {
        const errorText = message.text();
        if (!isIgnorableDevConsoleError(errorText)) {
          consoleErrors.push(errorText);
        }
      }
    });

    page.on("pageerror", (error) => {
      pageErrors.push(error.message);
    });

    await page.goto("/");
    await expect(page).toHaveTitle(/Kivixa/i);
    await page.waitForTimeout(600);

    expect(consoleErrors, `Console errors found: ${consoleErrors.join("\n")}`).toEqual([]);
    expect(pageErrors, `Runtime page errors found: ${pageErrors.join("\n")}`).toEqual([]);
  });

  test("renders key sections and CTAs", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByTestId("hero-section")).toBeVisible();
    await expect(page.getByTestId("features-section")).toBeVisible();
    await expect(page.getByTestId("showcase-section")).toBeVisible();

    const windowsCta = page.getByTestId("cta-windows");
    const uptodownCta = page.getByTestId("cta-uptodown");

    await expect(windowsCta).toBeVisible();
    await expect(uptodownCta).toBeVisible();

    const windowsHref = await windowsCta.getAttribute("href");
    const uptodownHref = await uptodownCta.getAttribute("href");

    expect(windowsHref).toMatch(/^https?:\/\//);
    expect(uptodownHref).toMatch(/^https?:\/\//);
  });

  test("passes baseline accessibility checks", async ({ page }) => {
    await page.goto("/");

    const images = page.locator("img");
    const imageCount = await images.count();
    expect(imageCount).toBeGreaterThan(0);

    for (let index = 0; index < imageCount; index += 1) {
      const alt = await images.nth(index).getAttribute("alt");
      expect(alt?.trim().length, `Image at index ${index} is missing alt text`).toBeGreaterThan(0);
    }

    const axeResults = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa"])
      .analyze();

    expect(
      axeResults.violations,
      axeResults.violations
        .map((violation) => `${violation.id}: ${violation.help}`)
        .join("\n")
    ).toEqual([]);
  });
});
