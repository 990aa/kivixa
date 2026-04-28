"use client";

import { useRef, useState } from "react";
import { gsap } from "gsap";
import type { ReleaseData } from "@/lib/github";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";

interface DownloadsSectionProps {
  release: ReleaseData;
}

export default function DownloadsSection({ release }: DownloadsSectionProps) {
  const sectionRef = useRef<HTMLElement>(null);
  const [wingetCopied, setWingetCopied] = useState(false);

  const copyWinget = async () => {
    try {
      await navigator.clipboard.writeText("winget install Kivixa");
      setWingetCopied(true);
      window.setTimeout(() => setWingetCopied(false), 1600);
    } catch {
      setWingetCopied(false);
    }
  };

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const downloadCards = Array.from(section.querySelectorAll<HTMLElement>("[data-download-card]"));

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

        <div className="download-cards-grid">
          <article data-download-card className="download-card-box">
            <div className="download-card-header">
              <h3 className="download-card-title">Windows</h3>
              <span className="download-status-badge status-stable">Stable</span>
            </div>

            <div className="winget-row">
              <code data-testid="winget-command" className="winget-code-block">
                winget install Kivixa
              </code>
              <button type="button" onClick={copyWinget} className="copy-btn" aria-label="Copy winget command">
                {wingetCopied ? (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="20 6 9 17 4 12" />
                  </svg>
                ) : (
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                    <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
                  </svg>
                )}
              </button>
            </div>

            <div className="download-actions-stack">
              <a
                data-testid="download-windows-exe"
                href={release.windowsUrl ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download .exe
              </a>

              <p className="download-footnote mt-2">
                Also available:
                <a data-testid="download-windows-msix" href={release.windowsMsixUrl ?? release.releasesPageUrl} className="inline-link msix-link">
                  .msix package
                </a>
                * MSIX requires bypassing Windows security warnings. Not signed.
              </p>
            </div>
          </article>

          <article data-download-card className="download-card-box">
            <div className="download-card-header">
              <h3 className="download-card-title">Android</h3>
              <span className="download-status-badge status-stable">Stable</span>
            </div>

            <details className="fdroid-steps">
              <summary className="fdroid-steps-summary">Install via F-Droid (recommended)</summary>
              <ol className="fdroid-steps-list">
                <li>Install F-Droid from <strong>f-droid.org</strong></li>
                <li>Open the F-Droid app</li>
                <li>Go to <strong>Settings</strong></li>
                <li>Tap <strong>Repositories</strong></li>
                <li>Tap the <strong>+</strong> icon at the bottom</li>
                <li>
                  Choose one method:
                  <ul className="fdroid-method-list">
                    <li><strong>Scan QR code:</strong></li>
                  </ul>
                  <div className="qr-code-wrapper">
                    <img
                      src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://990aa.github.io/kivixa/repo"
                      alt="F-Droid Repo QR Code"
                      width="120"
                      height="120"
                    />
                  </div>
                  <ul className="fdroid-method-list">
                    <li><strong>Enter URL manually:</strong></li>
                    <li><code className="repo-url-code">https://990aa.github.io/kivixa/repo</code></li>
                  </ul>
                </li>
              </ol>
            </details>

            <div className="download-actions-stack">
              <a
                data-testid="download-android"
                href={release.androidArm64Url ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download ARM64 APK
              </a>
            </div>
          </article>

          <article data-download-card className="download-card-box">
            <div className="download-card-header">
              <h3 className="download-card-title">Linux</h3>
              <span className="download-status-badge status-distributed">Distributed</span>
            </div>
            <p className="download-footnote">Linux x86_64 bundle</p>

            <div className="download-actions-stack">
              <a
                href={release.linuxUrl ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download .tar.gz
              </a>
            </div>
          </article>

          <article data-download-card className="download-card-box">
            <div className="download-card-header">
              <h3 className="download-card-title">macOS</h3>
              <span className="download-status-badge status-distributed">Distributed</span>
            </div>
            <p className="download-footnote">macOS universal app (x86_64 + Apple Silicon)</p>

            <div className="download-actions-stack">
              <a
                href={release.macOSUrl ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download .zip
              </a>
            </div>
          </article>

          <article data-download-card className="download-card-box">
            <div className="download-card-header">
              <h3 className="download-card-title">iOS</h3>
              <span className="download-status-badge status-distributed">Distributed</span>
            </div>
            <p className="download-footnote">IPA (sideload via AltStore / Sideloadly)</p>

            <div className="download-actions-stack">
              <a
                href={release.iOSUrl ?? release.releasesPageUrl}
                className="silver-button silver-button-primary"
              >
                Download IPA
              </a>
            </div>
          </article>
        </div>
      </div>
    </section>
  );
}