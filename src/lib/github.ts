interface GitHubAsset {
  name: string;
  browser_download_url: string;
  size: number;
}

interface GitHubRelease {
  tag_name: string;
  name: string;
  html_url: string;
  published_at: string;
  assets: GitHubAsset[];
}

export interface ReleaseData {
  version: string;
  tagName: string;
  releaseUrl: string;
  releasesPageUrl: string;
  windowsUrl: string | null;
  androidArm64Url: string | null;
}

const FALLBACK: ReleaseData = {
  version: "0.3.9",
  tagName: "v0.3.9+3009",
  releaseUrl: "https://github.com/990aa/kivixa/releases/tag/v0.3.9%2B3009",
  releasesPageUrl: "https://github.com/990aa/kivixa/releases",
  windowsUrl:
    "https://github.com/990aa/kivixa/releases/download/v0.3.9%2B3009/Kivixa-Setup-0.3.9.exe",
  androidArm64Url:
    "https://github.com/990aa/kivixa/releases/download/v0.3.9%2B3009/Kivixa-Android-0.3.9-arm64.apk",
};

export async function getLatestRelease(): Promise<ReleaseData> {
  try {
    const res = await fetch(
      "https://api.github.com/repos/990aa/kivixa/releases/latest",
      {
        headers: { Accept: "application/vnd.github+json" },
        next: { revalidate: 3600 }, // ISR: revalidate every hour
      }
    );

    if (!res.ok) return FALLBACK;

    const data: GitHubRelease = await res.json();

    const windowsAsset = data.assets.find((a) =>
      a.name.toLowerCase().endsWith(".exe")
    );
    const androidArm64Asset = data.assets.find(
      (a) =>
        a.name.toLowerCase().includes("arm64") &&
        a.name.toLowerCase().endsWith(".apk")
    );

    // Extract semver from tag like "v0.3.9+3009" → "0.3.9"
    const version =
      data.tag_name.replace(/^v/, "").split("+")[0] || data.tag_name;

    return {
      version,
      tagName: data.tag_name,
      releaseUrl: data.html_url,
      releasesPageUrl: "https://github.com/990aa/kivixa/releases",
      windowsUrl: windowsAsset?.browser_download_url ?? FALLBACK.windowsUrl,
      androidArm64Url:
        androidArm64Asset?.browser_download_url ?? FALLBACK.androidArm64Url,
    };
  } catch {
    return FALLBACK;
  }
}
