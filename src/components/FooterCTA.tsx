"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import type { ReleaseData } from "@/lib/github";
import { useScrollTrigger } from "@/hooks/useScrollTrigger";
import ParticleCanvas from "./ParticleCanvas";

interface FooterCTAProps {
  release: ReleaseData;
}

export default function FooterCTA({ release }: FooterCTAProps) {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollTrigger(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const left = section.querySelector<HTMLElement>("[data-final-left]");
      const right = section.querySelector<HTMLElement>("[data-final-right]");
      const center = section.querySelector<HTMLElement>("[data-final-center]");

      const timeline = gsap.timeline({
        defaults: { ease: "power3.inOut" },
        scrollTrigger: {
          trigger: section,
          start: "top 78%",
          end: "top 26%",
          scrub: 1,
        },
      });

      timeline
        .fromTo(left, { xPercent: -115 }, { xPercent: 0, duration: 1.1 }, 0)
        .fromTo(right, { xPercent: 115 }, { xPercent: 0, duration: 1.1 }, 0)
        .fromTo(
          center,
          { autoAlpha: 0, y: 32, scale: 0.96 },
          { autoAlpha: 1, y: 0, scale: 1, duration: 0.7, ease: "power2.out" },
          0.62
        );
    },
    []
  );

  return (
    <footer ref={sectionRef} className="scene footer-cta relative min-h-[70vh] overflow-hidden px-6 py-24 sm:py-28">
      <ParticleCanvas count={128} speed={0.18} />
      <div className="aurora-band" aria-hidden="true" />

      <div className="final-curtain-panel final-curtain-left" data-final-left aria-hidden="true" />
      <div className="final-curtain-panel final-curtain-right" data-final-right aria-hidden="true" />

      <div data-final-center className="relative z-10 mx-auto flex min-h-[54vh] max-w-4xl flex-col items-center justify-center text-center">
        <p className="mb-4 text-xs font-mono uppercase tracking-[0.24em] text-silver-accent">Scene 7</p>
        <h2 className="text-balance text-4xl font-semibold tracking-tight text-text-primary sm:text-5xl md:text-6xl">
          Build your private workspace with Kivixa
        </h2>
        <p className="mt-4 max-w-2xl text-balance text-base leading-relaxed text-text-secondary sm:text-lg">
          One app for notes, sketching, planning, and local AI. Cross-platform, offline, and entirely yours.
        </p>

        <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
          <a href={release.windowsMsixUrl ?? release.releasesPageUrl} className="liquid-btn silver-btn-primary">
            Download latest
          </a>
          <a
            href="https://github.com/990aa/kivixa"
            target="_blank"
            rel="noopener noreferrer"
            className="liquid-btn silver-btn-secondary"
          >
            GitHub
          </a>
        </div>

        <p className="mt-8 text-sm text-text-secondary">
          Release
          <span data-testid="footer-version" className="ml-2 rounded-full border border-silver-700 px-3 py-1 font-mono text-silver-shine">
            v{release.version}
          </span>
        </p>
      </div>
    </footer>
  );
}
