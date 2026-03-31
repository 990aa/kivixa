import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

/**
 * Fetches the latest release version from the GitHub API to compare
 * against what the page renders.
 */
async function fetchLatestGitHubVersion(): Promise<{
  version: string;
  windowsUrl: string | null;
  androidArm64Url: string | null;
}> {
  const res = await fetch(
    "https://api.github.com/repos/990aa/kivixa/releases/latest",
    { headers: { Accept: "application/vnd.github+json" } }
  );
  if (!res.ok) throw new Error(`GitHub API returned ${res.status}`);

  const data = await res.json();
  const version = data.tag_name.replace(/^v/, "").split("+")[0];

  const windowsAsset = data.assets.find(
    (a: { name: string }) => a.name.toLowerCase().endsWith(".exe")
  );
  const androidArm64Asset = data.assets.find(
    (a: { name: string }) =>
      a.name.toLowerCase().includes("arm64") &&
      a.name.toLowerCase().endsWith(".apk")
  );

  return {
    version,
    windowsUrl: windowsAsset?.browser_download_url ?? null,
    androidArm64Url: androidArm64Asset?.browser_download_url ?? null,
  };
}

const isIgnorableDevConsoleError = (message: string) =>
  message.includes("/_next/webpack-hmr") ||
  (message.includes("WebSocket connection to") &&
    message.includes("ERR_INVALID_HTTP_RESPONSE")) ||
  message.includes(
    "Failed to load resource: the server responded with a status of 400 (Bad Request)"
  );

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

    expect(
      consoleErrors,
      `Console errors found: ${consoleErrors.join("\n")}`
    ).toEqual([]);
    expect(
      pageErrors,
      `Runtime page errors found: ${pageErrors.join("\n")}`
    ).toEqual([]);
  });

  test("renders key sections", async ({ page }) => {
    await page.goto("/");

    await expect(page.getByTestId("hero-section")).toBeVisible();
    await expect(page.getByTestId("features-section")).toBeVisible();
    await expect(page.getByTestId("download-section")).toBeVisible();
  });

  test("displays the latest GitHub release version", async ({ page }) => {
    const github = await fetchLatestGitHubVersion();

    await page.goto("/");

    // Check the Windows version label in Download section
    const windowsVersion = page.getByTestId("windows-version");
    await expect(windowsVersion).toContainText(`v${github.version}`);

    // Check the Android version label in Download section
    const androidVersion = page.getByTestId("android-version");
    await expect(androidVersion).toContainText(`v${github.version}`);

    // Check the footer version badge
    const footerVersion = page.getByTestId("footer-version");
    await expect(footerVersion).toContainText(`v${github.version}`);
  });

  test("download buttons link to the latest release assets", async ({
    page,
  }) => {
    const github = await fetchLatestGitHubVersion();

    await page.goto("/");

    // Hero CTA should point to the latest Windows installer
    const heroCta = page.getByTestId("cta-windows");
    await expect(heroCta).toBeVisible();
    const heroHref = await heroCta.getAttribute("href");
    expect(heroHref).toBe(github.windowsUrl);

    // Download section Windows button
    const downloadWindows = page.getByTestId("download-windows");
    await expect(downloadWindows).toBeVisible();
    const winHref = await downloadWindows.getAttribute("href");
    expect(winHref).toBe(github.windowsUrl);

    // Download section Android button
    const downloadAndroid = page.getByTestId("download-android");
    await expect(downloadAndroid).toBeVisible();
    const androidHref = await downloadAndroid.getAttribute("href");
    expect(androidHref).toBe(github.androidArm64Url);
  });

  test("download URLs point to valid GitHub release assets", async ({
    page,
  }) => {
    await page.goto("/");

    // Verify the Windows download URL is a valid GitHub release URL
    const winHref = await page
      .getByTestId("download-windows")
      .getAttribute("href");
    expect(winHref).toMatch(
      /^https:\/\/github\.com\/990aa\/kivixa\/releases\/download\/.+\.exe$/
    );

    // Verify the Android download URL is a valid GitHub release URL
    const androidHref = await page
      .getByTestId("download-android")
      .getAttribute("href");
    expect(androidHref).toMatch(
      /^https:\/\/github\.com\/990aa\/kivixa\/releases\/download\/.+\.apk$/
    );
  });

  test("passes baseline accessibility checks", async ({ page }) => {
    await page.goto("/");

    // Every image must have alt text
    const images = page.locator("img");
    const imageCount = await images.count();
    expect(imageCount).toBeGreaterThan(0);

    for (let index = 0; index < imageCount; index += 1) {
      const alt = await images.nth(index).getAttribute("alt");
      expect(
        alt?.trim().length,
        `Image at index ${index} is missing alt text`
      ).toBeGreaterThan(0);
    }

    // axe-core WCAG checks
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
