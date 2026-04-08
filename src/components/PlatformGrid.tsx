"use client";

import { useRef, useState } from "react";
import { gsap } from "gsap";
import type { ReleaseData } from "@/lib/github";
import { useScrollTrigger } from "@/hooks/useScrollTrigger";

interface PlatformGridProps {
  release: ReleaseData;
}

const platforms = [
  { name: "Windows", detail: "Stable" },
  { name: "Android", detail: "Stable" },
  { name: "Web", detail: "Experimental" },
  { name: "macOS", detail: "Supported" },
  { name: "Linux", detail: "Supported" },
  { name: "iOS", detail: "Supported" },
];

export default function PlatformGrid({ release }: PlatformGridProps) {
  const sectionRef = useRef<HTMLElement>(null);
  const [copied, setCopied] = useState(false);
  const wingetCommand = "winget install Kivixa";

  const copyWinget = async () => {
    try {
      await navigator.clipboard.writeText(wingetCommand);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      setCopied(false);
    }
  };

  useScrollTrigger(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const badges = Array.from(section.querySelectorAll<HTMLElement>("[data-platform-badge]"));
      const cards = Array.from(section.querySelectorAll<HTMLElement>("[data-download-card]"));
      const fdroid = section.querySelector<HTMLElement>("[data-fdroid-card]");

      gsap.fromTo(
        badges,
        { y: -60, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.95,
          stagger: 0.08,
          ease: "elastic.out(1, 0.5)",
          scrollTrigger: {
            trigger: section,
            start: "top 80%",
            end: "top 42%",
            scrub: 1,
          },
        }
      );

      gsap.fromTo(
        cards,
        { y: 28, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.7,
          stagger: 0.12,
          ease: "power2.out",
          scrollTrigger: {
            trigger: section,
            start: "top 72%",
            end: "top 28%",
            scrub: 1,
          },
        }
      );

      gsap.fromTo(
        fdroid,
        { autoAlpha: 0, scale: 0.88, boxShadow: "0 0 0 rgba(74, 222, 128, 0)" },
        {
          autoAlpha: 1,
          scale: 1,
          boxShadow: "0 0 36px rgba(74, 222, 128, 0.35)",
          duration: 0.85,
          ease: "power2.out",
          scrollTrigger: {
            trigger: section,
            start: "top 68%",
            end: "top 30%",
            scrub: 1,
          },
        }
      );
    },
    []
  );

  return (
    <section
      id="platforms"
      ref={sectionRef}
      data-testid="download-section"
      className="scene platform-scene px-6 py-28 sm:py-32"
    >
      <div className="mx-auto max-w-6xl">
        <div className="mb-12 text-center">
          <p className="mb-4 text-xs font-mono uppercase tracking-[0.24em] text-silver-accent">Scene 6</p>
          <h2 className="text-balance text-3xl font-semibold tracking-tight text-text-primary sm:text-4xl md:text-5xl">
            Platforms drop into place
          </h2>
          <p className="mx-auto mt-4 max-w-3xl text-balance text-base leading-relaxed text-text-secondary sm:text-lg">
            Kivixa runs cross-platform with the same privacy model and local-first behavior.
          </p>
        </div>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {platforms.map((platform) => (
            <article key={platform.name} data-platform-badge className="platform-badge-tile will-change-transform">
              <p className="text-lg font-semibold tracking-tight text-text-primary">{platform.name}</p>
              <p className="mt-1 text-xs font-mono uppercase tracking-[0.12em] text-text-secondary">
                {platform.detail}
              </p>
            </article>
          ))}
        </div>

        <div className="mt-10 grid gap-5 lg:grid-cols-3">
          <article data-download-card className="download-card">
            <h3 className="text-xl font-semibold tracking-tight text-text-primary">Windows</h3>
            <p data-testid="windows-version" className="mt-2 text-sm text-text-secondary">
              v{release.version} · Installer and MSIX package
            </p>

            <code data-testid="winget-command" className="mt-4 block rounded-xl border border-silver-700 bg-silver-900/70 px-4 py-2 text-sm text-silver-shine">
              {wingetCommand}
            </code>

            <button
              type="button"
              data-testid="copy-winget"
              onClick={copyWinget}
              className="liquid-btn silver-btn-secondary mt-4 w-full"
            >
              {copied ? "Copied" : "Copy winget command"}
            </button>

            <a
              data-testid="download-windows-msix"
              href={release.windowsMsixUrl ?? release.releasesPageUrl}
              className="liquid-btn silver-btn-primary mt-3 w-full"
            >
              Download .msix package
            </a>

            <a
              data-testid="download-windows-exe"
              href={release.windowsUrl ?? release.releasesPageUrl}
              className="liquid-btn silver-btn-secondary mt-3 w-full"
            >
              Download .exe
            </a>
          </article>

          <article data-download-card className="download-card">
            <h3 className="text-xl font-semibold tracking-tight text-text-primary">Android</h3>
            <p data-testid="android-version" className="mt-2 text-sm text-text-secondary">
              v{release.version} · ARM64 build
            </p>

            <a
              data-testid="download-android"
              href={release.androidArm64Url ?? release.releasesPageUrl}
              className="liquid-btn silver-btn-primary mt-6 w-full"
            >
              Download ARM64 APK
            </a>

            <p className="mt-4 text-sm text-text-secondary">
              Need other architectures? Use the full release page.
            </p>

            <a
              href={release.releasesPageUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="liquid-btn silver-btn-secondary mt-4 w-full"
            >
              Browse all release assets
            </a>
          </article>

          <article data-download-card data-fdroid-card className="download-card fdroid-highlight">
            <h3 className="text-xl font-semibold tracking-tight text-text-primary">F-Droid</h3>
            <p className="mt-2 text-sm text-text-secondary">
              Add the Kivixa repository for update-friendly Android installs.
            </p>

            <a href="https://990aa.github.io/kivixa/repo" className="liquid-btn silver-btn-primary mt-6 w-full">
              Open F-Droid repository
            </a>

            <p className="mt-4 text-sm text-text-secondary">
              Repo URL: <span className="font-mono text-silver-shine">https://990aa.github.io/kivixa/repo</span>
            </p>
          </article>
        </div>
      </div>
    </section>
  );
}
