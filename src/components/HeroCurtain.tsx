"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import type { ReleaseData } from "@/lib/github";
import ParticleCanvas from "./ParticleCanvas";

gsap.registerPlugin(TextPlugin);

interface HeroCurtainProps {
  release: ReleaseData;
}

export default function HeroCurtain({ release }: HeroCurtainProps) {
  const sectionRef = useRef<HTMLElement>(null);
  const leftPanelRef = useRef<HTMLDivElement>(null);
  const rightPanelRef = useRef<HTMLDivElement>(null);
  const logoRef = useRef<HTMLDivElement>(null);
  const taglineRef = useRef<HTMLParagraphElement>(null);
  const ctaRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;

    const ctx = gsap.context(() => {
      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

      const message = "Your private universe. On-device. Offline. Yours.";
      if (taglineRef.current) {
        taglineRef.current.textContent = reducedMotion ? message : "";
      }

      if (reducedMotion) {
        gsap.set([leftPanelRef.current, rightPanelRef.current], { autoAlpha: 0 });
        gsap.set([logoRef.current, ctaRef.current], { autoAlpha: 1 });
        return;
      }

      const ctaItems = ctaRef.current?.querySelectorAll("[data-hero-cta]") ?? [];

      const timeline = gsap.timeline({ defaults: { ease: "power3.inOut" } });

      timeline
        .to(leftPanelRef.current, { xPercent: -102, duration: 1.2 }, 0)
        .to(rightPanelRef.current, { xPercent: 102, duration: 1.2 }, 0)
        .fromTo(
          logoRef.current,
          { autoAlpha: 0, scale: 0.8, y: 26 },
          { autoAlpha: 1, scale: 1, y: 0, duration: 0.8, ease: "power2.out" },
          0.86
        )
        .fromTo(
          ".hero-subhead",
          { autoAlpha: 0, y: 24 },
          { autoAlpha: 1, y: 0, duration: 0.55, ease: "power2.out" },
          1.02
        )
        .to(
          taglineRef.current,
          {
            duration: 1.35,
            text: message,
            ease: "none",
          },
          1.2
        )
        .fromTo(
          ctaItems,
          { autoAlpha: 0, y: 18 },
          { autoAlpha: 1, y: 0, stagger: 0.12, duration: 0.55, ease: "power2.out" },
          2.14
        );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section
      id="hero"
      ref={sectionRef}
      data-testid="hero-section"
      className="scene hero-curtain relative min-h-screen overflow-hidden"
    >
      <ParticleCanvas count={96} speed={0.24} />
      <div className="hero-radial" aria-hidden="true" />

      <div ref={leftPanelRef} className="curtain-panel curtain-panel-left" aria-hidden="true" />
      <div ref={rightPanelRef} className="curtain-panel curtain-panel-right" aria-hidden="true" />

      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center px-6 py-20 text-center">
        <div ref={logoRef} className="mb-7 will-change-transform">
          <p className="mb-4 text-[11px] font-mono uppercase tracking-[0.28em] text-silver-accent">
            Kivixa Workspace
          </p>
          <h1 className="text-5xl font-semibold tracking-tight text-text-primary sm:text-6xl md:text-7xl">
            Kivixa
          </h1>
        </div>

        <p className="hero-subhead max-w-3xl text-balance text-lg leading-relaxed text-text-secondary sm:text-xl">
          Notes, sketching, planning, and local AI assistance in one privacy-first cross-platform workspace.
        </p>

        <p
          ref={taglineRef}
          className="mt-5 min-h-[2.2rem] text-balance text-base font-medium text-silver-shine sm:text-lg"
        />

        <div ref={ctaRef} className="mt-10 flex flex-wrap items-center justify-center gap-3 sm:gap-4">
          <a
            data-hero-cta
            data-testid="cta-winget"
            href="#platforms"
            className="liquid-btn silver-btn-primary"
          >
            Install with winget
          </a>
          <a
            data-hero-cta
            href={release.windowsMsixUrl ?? release.releasesPageUrl}
            className="liquid-btn silver-btn-secondary"
          >
            Download .msix
          </a>
          <a
            data-hero-cta
            href="https://github.com/990aa/kivixa"
            target="_blank"
            rel="noopener noreferrer"
            className="liquid-btn silver-btn-secondary"
          >
            View on GitHub
          </a>
        </div>

        <p className="mt-8 text-sm text-text-secondary">
          Latest release <span className="font-mono text-silver-shine">v{release.version}</span> is available for Windows and Android.
        </p>
      </div>
    </section>
  );
}
