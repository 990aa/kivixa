"use client";

import { useEffect, useRef, useState } from "react";
import { gsap } from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import type { ReleaseData } from "@/lib/github";
import ParticleCanvas from "./ParticleCanvas";

gsap.registerPlugin(TextPlugin);

interface HeroSectionProps {
  release: ReleaseData;
}

export default function HeroSection({ release }: HeroSectionProps) {
  const sectionRef = useRef<HTMLElement>(null);
  const leftCurtainRef = useRef<HTMLDivElement>(null);
  const rightCurtainRef = useRef<HTMLDivElement>(null);
  const typedLineRef = useRef<HTMLParagraphElement>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const scope = sectionRef.current;
    if (!scope) return;

    const typedMessage = "Your private universe. On-device. Offline. Yours.";

    const ctx = gsap.context(() => {
      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      const heroItems = scope.querySelectorAll("[data-hero-item]");

      if (typedLineRef.current) {
        typedLineRef.current.textContent = reducedMotion ? typedMessage : "";
      }

      if (reducedMotion) {
        gsap.set([leftCurtainRef.current, rightCurtainRef.current], { autoAlpha: 0 });
        gsap.set(heroItems, { autoAlpha: 1, y: 0 });
        return;
      }

      const timeline = gsap.timeline({ defaults: { ease: "power3.inOut" } });

      timeline
        .to(leftCurtainRef.current, { xPercent: -100, duration: 1.1 }, 0)
        .to(rightCurtainRef.current, { xPercent: 100, duration: 1.1 }, 0)
        .fromTo(
          heroItems,
          { y: 30, autoAlpha: 0 },
          {
            y: 0,
            autoAlpha: 1,
            duration: 0.65,
            stagger: 0.12,
            ease: "power2.out",
          },
          1.05
        )
        .to(
          typedLineRef.current,
          {
            duration: 1.15,
            text: typedMessage,
            ease: "none",
          },
          1.38
        );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  const handleWingetCopy = async () => {
    try {
      await navigator.clipboard.writeText("winget install Kivixa");
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1400);
    } catch {
      setCopied(false);
    }
  };

  return (
    <section
      ref={sectionRef}
      data-testid="hero-section"
      className="hero-section relative min-h-screen overflow-hidden px-6"
    >
      <ParticleCanvas count={80} />
      <div className="hero-radial-glow" aria-hidden="true" />

      <div ref={leftCurtainRef} className="hero-curtain-panel hero-curtain-left" aria-hidden="true" />
      <div ref={rightCurtainRef} className="hero-curtain-panel hero-curtain-right" aria-hidden="true" />

      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-5xl flex-col items-center justify-center text-center">
        <p data-hero-item className="hero-overline">
          KIVIXA WORKSPACE
        </p>

        <h1 data-hero-item className="hero-wordmark">
          Kivixa
        </h1>

        <p data-hero-item className="hero-primary-copy">
          Notes, sketching, planning, and local AI assistance
          <br />
          in one privacy-first cross-platform workspace.
        </p>

        <p ref={typedLineRef} data-hero-item className="hero-typed-line" />

        <div data-hero-item className="hero-cta-row">
          <button
            type="button"
            data-testid="cta-winget"
            onClick={handleWingetCopy}
            className="silver-button silver-button-primary"
          >
            Install with winget
          </button>
          <a
            data-testid="download-windows-exe-hero"
            href={release.windowsUrl ?? release.releasesPageUrl}
            className="silver-button silver-button-secondary"
          >
            Download .exe
          </a>
          <a
            href="https://github.com/990aa/kivixa"
            target="_blank"
            rel="noopener noreferrer"
            className="silver-button silver-button-secondary"
          >
            View on GitHub
          </a>
        </div>

        <p data-hero-item className="hero-release-note">
          Latest release v{release.version} · Available for Windows and Android.
        </p>

        {copied ? (
          <p role="status" aria-live="polite" className="hero-copy-toast">
            Copied!
          </p>
        ) : null}
      </div>
    </section>
  );
}
