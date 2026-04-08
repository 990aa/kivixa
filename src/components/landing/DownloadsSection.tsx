"use client";

import { useRef, useState } from "react";
import { gsap } from "gsap";
import type { ReleaseData } from "@/lib/github";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";

interface DownloadsSectionProps {
  release: ReleaseData;
}

const platformStatus = [
  { platform: "Windows", status: "STABLE" },
  { platform: "Android", status: "STABLE" },
  { platform: "Web", status: "EXPERIMENTAL" },
  { platform: "macOS", status: "SUPPORTED" },
  { platform: "Linux", status: "SUPPORTED" },
  { platform: "iOS", status: "SUPPORTED" },
];

export default function DownloadsSection({ release }: DownloadsSectionProps) {
  const sectionRef = useRef<HTMLElement>(null);
  const [copied, setCopied] = useState(false);

  const copyWinget = async () => {
    try {
      await navigator.clipboard.writeText("winget install Kivixa");
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1600);
    } catch {
      setCopied(false);
    }
  };

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const statusTiles = Array.from(section.querySelectorAll<HTMLElement>("[data-status-tile]"));
      const downloadCards = Array.from(section.querySelectorAll<HTMLElement>("[data-download-card]"));

      gsap.fromTo(
        statusTiles,
        { y: -50, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.9,
          stagger: 0.08,
          ease: "elastic.out(1, 0.5)",
          scrollTrigger: {
            trigger: section,
            start: "top 80%",
            toggleActions: "play none none reverse",
          },
        }
      );

      gsap.fromTo(
        downloadCards,
        { y: 28, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.62,
          stagger: 0.12,
          ease: "power2.out",
          scrollTrigger: {
            trigger: section,
            start: "top 70%",
            toggleActions: "play none none reverse",
          },
        }
      );
    },
    []
  );

  return (
    <section id="platforms" ref={sectionRef} data-testid="download-section" className="downloads-section px-6 py-24 sm:py-28">
      <div className="mx-auto max-w-6xl">
        <p className="downloads-intro">
          Kivixa runs cross-platform with the same privacy model and local-first behavior.
        </p>

        <div className="status-grid">
          {platformStatus.map((item) => (
            <article key={`${item.platform}-${item.status}`} data-status-tile className="status-tile">
              <p className="status-platform">{item.platform}</p>
              <p className="status-label">{item.status}</p>
            </article>
          ))}
        </div>

        <div className="download-cards-grid">
          <article data-download-card className="download-card-box">
            <h3 className="download-card-title">Windows</h3>
            <p data-testid="windows-version" className="download-version-text">v{release.version}</p>

            <code data-testid="winget-command" className="winget-code-block">
              winget install Kivixa
            </code>

            <div className="download-actions-stack">
              <button type="button" data-testid="copy-winget" onClick={copyWinget} className="silver-button silver-button-secondary">
                {copied ? "Copied!" : "Copy winget command"}
              </button>

              <a
                data-testid="download-windows-exe"
                href={release.windowsUrl ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download .exe
              </a>
            </div>

            <p className="download-footnote mt-3">
              Also available:
              <a data-testid="download-windows-msix" href={release.windowsMsixUrl ?? release.releasesPageUrl} className="inline-link msix-link">
                .msix package*
              </a>
            </p>
          </article>

          <article data-download-card className="download-card-box">
            <h3 className="download-card-title">Android</h3>
            <p data-testid="android-version" className="download-version-text">v{release.version}</p>

            <div className="download-actions-stack">
              <a
                data-testid="download-android"
                href={release.androidArm64Url ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download ARM64 APK
              </a>

              <p className="download-footnote">Need another arch?</p>
              <a
                href={release.releasesPageUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="silver-button silver-button-secondary"
              >
                Browse all releases
              </a>
            </div>
          </article>

          <article data-download-card className="download-card-box">
            <h3 className="download-card-title">F-Droid</h3>
            <p className="download-footnote mt-2">
              Add the Kivixa repo for automatic update-friendly Android installs.
            </p>

            <div className="download-actions-stack">
              <a href="https://990aa.github.io/kivixa/repo" className="silver-button silver-button-primary">
                Open F-Droid repo
              </a>
            </div>

            <p className="download-footnote mt-4">
              Repo URL:
              <span className="repo-url-text">990aa.github.io/kivixa/repo</span>
            </p>
          </article>
        </div>

        <p className="downloads-global-footnote">
          * MSIX requires bypassing Windows security warnings. Not signed.
          <br />
          Winget or .exe recommended for most users.
        </p>
      </div>
    </section>
  );
}
