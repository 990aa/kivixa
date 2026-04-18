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

    await expect(page.getByTestId("cta-winget")).toBeVisible();
    await expect(page.getByTestId("cta-winget")).toContainText("Install with winget");

    await page.getByTestId("download-section").scrollIntoViewIfNeeded();
    await page.waitForTimeout(650);

    const wingetCommand = page.getByTestId("winget-command");
    await expect(wingetCommand).toBeVisible();
    await expect(wingetCommand).toContainText("winget install Kivixa");

    await expect(page.getByTestId("copy-winget")).toBeVisible();

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

    const windowsVersion = page.getByTestId("windows-version");
    await expect(windowsVersion).toContainText(`v${github.version}`);

    const androidVersion = page.getByTestId("android-version");
    await expect(androidVersion).toContainText(`v${github.version}`);

    const footerVersion = page.getByTestId("footer-version");
    await expect(footerVersion).toContainText(`v${github.version}`);
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
});
