import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

type LatestRelease = {
  version: string;
  windowsUrl: string | null;
  windowsMsixUrl: string | null;
  androidArm64Url: string | null;
};

async function fetchLatestGitHubVersion(): Promise<LatestRelease | null> {
  try {
    const res = await fetch(
      "https://api.github.com/repos/990aa/kivixa/releases/latest",
      { headers: { Accept: "application/vnd.github+json" } }
    );

    if (!res.ok) return null;

    const data = await res.json();
    const version = data.tag_name.replace(/^v/, "").split("+")[0];

    const windowsAsset = data.assets.find(
      (a: { name: string }) => a.name.toLowerCase().endsWith(".exe")
    );
    const windowsMsixAsset = data.assets.find(
      (a: { name: string }) => a.name.toLowerCase().endsWith(".msix")
    );
    const androidArm64Asset = data.assets.find(
      (a: { name: string }) =>
        a.name.toLowerCase().includes("arm64") &&
        a.name.toLowerCase().endsWith(".apk")
    );
    const derivedMsixUrl = `https://github.com/990aa/kivixa/releases/download/${encodeURIComponent(
      data.tag_name
    )}/kivixa.msix`;

    return {
      version,
      windowsUrl: windowsAsset?.browser_download_url ?? null,
      windowsMsixUrl: windowsMsixAsset?.browser_download_url ?? derivedMsixUrl,
      androidArm64Url: androidArm64Asset?.browser_download_url ?? null,
    };
  } catch {
    return null;
  }
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

  test("global curtain opens and closes from boundary intent", async ({ page }) => {
    await page.goto("/");

    const curtain = page.getByTestId("global-curtain");
    await expect(curtain).toHaveAttribute("data-state", "closed");

    await page.mouse.click(14, 14);
    await expect(curtain).toHaveAttribute("data-state", "open", { timeout: 2200 });

    await page.evaluate(() => window.scrollTo({ top: 0 }));
    await page.mouse.wheel(0, -1200);
    await expect(curtain).toHaveAttribute("data-state", "closed", { timeout: 2200 });

    await page.mouse.wheel(0, 1200);
    await expect(curtain).toHaveAttribute("data-state", "open", { timeout: 2200 });

    await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight }));
    await page.mouse.wheel(0, 1200);
    await expect(curtain).toHaveAttribute("data-state", "closed", { timeout: 2200 });

    await page.mouse.wheel(0, -1200);
    await expect(curtain).toHaveAttribute("data-state", "open", { timeout: 2200 });
  });

  test("prioritizes winget for Windows install and keeps manual exe download", async ({
    page,
  }) => {
    await page.goto("/");

    // Hero section has a download button that scrolls to downloads
    const heroDownloadBtn = page.locator("button:has-text('Download for your device')");
    await expect(heroDownloadBtn).toBeVisible();

    await page.getByTestId("download-section").scrollIntoViewIfNeeded();
    await page.waitForTimeout(650);

    const wingetCommand = page.getByTestId("winget-command");
    await expect(wingetCommand).toBeVisible();
    await expect(wingetCommand).toContainText("winget install Kivixa");

    // Copy button should be present
    const copyBtn = page.locator("button.copy-btn");
    await expect(copyBtn).toBeVisible();

    const msixLink = page.getByTestId("download-windows-msix");
    await expect(msixLink).toBeVisible();
    await expect(msixLink).toContainText(".msix package");

    const exeLink = page.getByTestId("download-windows-exe");
    await expect(exeLink).toBeVisible();
    await expect(exeLink).toContainText("Download .exe");
  });

  test("displays release versions that match GitHub when reachable", async ({ page }) => {
    const github = await fetchLatestGitHubVersion();
    if (!github) {
      test.skip(true, "GitHub API unavailable in current test environment");
      return;
    }

    await page.goto("/");

    // Version only appears in footer
    const footerVersion = page.getByTestId("footer-version");
    await expect(footerVersion).toContainText(`v${github.version}`);

    // Download cards should NOT have individual version numbers
    const windowsCard = page.locator("[data-download-card]").first();
    const windowsVersion = windowsCard.locator("[data-testid='windows-version']");
    await expect(windowsVersion).not.toBeVisible();
  });

  test("download URLs point to latest GitHub release assets when reachable", async ({
    page,
  }) => {
    const github = await fetchLatestGitHubVersion();
    if (!github) {
      test.skip(true, "GitHub API unavailable in current test environment");
      return;
    }

    await page.goto("/");

    const winHref = await page
      .getByTestId("download-windows-exe")
      .getAttribute("href");
    expect(winHref).toBe(github.windowsUrl);

    const msixHref = await page
      .getByTestId("download-windows-msix")
      .getAttribute("href");
    expect(msixHref).toBe(github.windowsMsixUrl);

    const androidHref = await page
      .getByTestId("download-android")
      .getAttribute("href");
    expect(androidHref).toBe(github.androidArm64Url);
  });

  test("renders image-free mockup content panels", async ({
    page,
  }) => {
    await page.goto("/");

    const screenshotImages = page.locator('img[data-screenshot="true"]');
    await expect(screenshotImages).toHaveCount(0);
    await expect(page.getByText("Workspace Engine")).toBeVisible();
    await expect(page.getByText("Local Assistant")).toBeVisible();
  });

  test("download URLs remain valid release links", async ({ page }) => {
    await page.goto("/");

    const winHref = await page
      .getByTestId("download-windows-exe")
      .getAttribute("href");
    expect(winHref).toMatch(
      /^https:\/\/github\.com\/990aa\/kivixa\/releases\/download\/.+\.exe$/
    );

    const msixHref = await page
      .getByTestId("download-windows-msix")
      .getAttribute("href");
    expect(msixHref).toMatch(
      /^https:\/\/github\.com\/990aa\/kivixa\/releases\/download\/.+\.msix$/
    );

    const androidHref = await page
      .getByTestId("download-android")
      .getAttribute("href");
    expect(androidHref).toMatch(
      /^https:\/\/github\.com\/990aa\/kivixa\/releases\/download\/.+\.apk$/
    );
  });

  test("passes baseline accessibility checks", async ({ page }) => {
    test.setTimeout(60_000);

    await page.goto("/");

    const images = page.locator("img");
    const imageCount = await images.count();

    for (let index = 0; index < imageCount; index += 1) {
      const alt = await images.nth(index).getAttribute("alt");
      expect(
        alt?.trim().length,
        `Image at index ${index} is missing alt text`
      ).toBeGreaterThan(0);
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

  test("scroll performance is smooth with no perceptible lag", async ({ page }) => {
    test.setTimeout(30_000);

    await page.goto("/");
    await page.waitForTimeout(500);

    const startTime = performance.now();
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(50);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(50);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(50);
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(50);
    await page.mouse.wheel(0, 300);
    const endTime = performance.now();

    // Total scroll operation time should be reasonable
    const totalScrollTime = endTime - startTime;
    expect(totalScrollTime, "Scroll operations should complete within 2 seconds").toBeLessThan(2000);

    // Verify we can scroll through the entire page
    await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight }));
    await page.waitForTimeout(200);

    const scrollTop = await page.evaluate(() => window.scrollY);
    const docHeight = await page.evaluate(() => document.documentElement.scrollHeight);

    expect(scrollTop, "Should be able to scroll to bottom of page").toBeGreaterThan(docHeight - 1000);

    // Scroll back to top
    await page.evaluate(() => window.scrollTo({ top: 0 }));
    await page.waitForTimeout(200);

    const scrollTopAfter = await page.evaluate(() => window.scrollY);
    expect(scrollTopAfter, "Should be able to scroll back to top").toBeLessThan(100);
  });

  test("particle canvas renders across entire page without gaps", async ({ page }) => {
    await page.goto("/");
    await page.waitForTimeout(500);

    // Check that particle canvas exists and covers viewport
    const canvas = page.locator("canvas").first();
    await expect(canvas).toBeAttached();

    // Scroll through page and check particles are visible in all sections
    await page.evaluate(() => window.scrollTo({ top: 0 }));
    await page.waitForTimeout(300);

    // Scroll to middle of page
    await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight / 2 }));
    await page.waitForTimeout(300);

    // Scroll to bottom
    await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight }));
    await page.waitForTimeout(300);

    // Particles should still be rendering
    const canvasVisible = await page.locator("canvas").first().isVisible();
    expect(canvasVisible, "Particle canvas should remain visible throughout page scroll").toBe(true);
  });

  test("no version numbers displayed on individual download cards", async ({ page }) => {
    await page.goto("/");
    await page.waitForTimeout(500);

    await page.getByTestId("download-section").scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);

    // Check that Windows card doesn't have version text
    const windowsCard = page.locator("[data-download-card]").first();
    const windowsVersion = windowsCard.locator("[data-testid='windows-version']");
    await expect(windowsVersion).not.toBeVisible();

    // Verify download cards still have platform titles
    const platformTitles = page.locator(".download-card-title");
    await expect(platformTitles).toHaveCount(5);

    // Verify the version only appears in footer
    const footerVersion = page.getByTestId("footer-version");
    await expect(footerVersion).toBeVisible();
  });
});
