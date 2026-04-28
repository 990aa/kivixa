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
  windowsMsixUrl: string | null;
  androidArm64Url: string | null;
  macOSUrl: string | null;
  linuxUrl: string | null;
  iOSUrl: string | null;
}

const FALLBACK: ReleaseData = {
  version: "0.7.1",
  tagName: "v0.7.1+7001",
  releaseUrl: "https://github.com/990aa/kivixa/releases/tag/v0.7.1%2B7001",
  releasesPageUrl: "https://github.com/990aa/kivixa/releases",
  windowsUrl:
    "https://github.com/990aa/kivixa/releases/download/v0.7.1%2B7001/Kivixa-Setup-0.7.1.exe",
  windowsMsixUrl:
    "https://github.com/990aa/kivixa/releases/download/v0.7.1%2B7001/kivixa.msix",
  androidArm64Url:
    "https://github.com/990aa/kivixa/releases/download/v0.7.1%2B7001/Kivixa-Android-0.7.1-arm64.apk",
  macOSUrl: null,
  linuxUrl: null,
  iOSUrl: null,
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
    const windowsMsixAsset = data.assets.find((a) =>
      a.name.toLowerCase().endsWith(".msix")
    );
    const androidArm64Asset = data.assets.find(
      (a) =>
        a.name.toLowerCase().includes("arm64") &&
        a.name.toLowerCase().endsWith(".apk")
    );
    const derivedMsixUrl = `https://github.com/990aa/kivixa/releases/download/${encodeURIComponent(
      data.tag_name
    )}/kivixa.msix`;

    // Extract semver from tag like "v0.3.9+3009" → "0.3.9"
    const version =
      data.tag_name.replace(/^v/, "").split("+")[0] || data.tag_name;

    const encodedTag = encodeURIComponent(data.tag_name);
    const baseUrl = `https://github.com/990aa/kivixa/releases/download/${encodedTag}`;

    // Construct URLs for macOS, Linux, iOS using naming convention
    const macOSUrl = `${baseUrl}/Kivixa-macOS-${version}-universal.zip`;
    const linuxUrl = `${baseUrl}/Kivixa-Linux-${version}-x86_64.tar.gz`;
    const iOSUrl = `${baseUrl}/Kivixa-iOS-${version}-arm64.ipa`;

    return {
      version,
      tagName: data.tag_name,
      releaseUrl: data.html_url,
      releasesPageUrl: "https://github.com/990aa/kivixa/releases",
      windowsUrl: windowsAsset?.browser_download_url ?? FALLBACK.windowsUrl,
      windowsMsixUrl:
        windowsMsixAsset?.browser_download_url ?? derivedMsixUrl,
      androidArm64Url:
        androidArm64Asset?.browser_download_url ?? FALLBACK.androidArm64Url,
      macOSUrl,
      linuxUrl,
      iOSUrl,
    };
  } catch {
    return FALLBACK;
  }
}
