"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import type { ReleaseData } from "@/lib/github";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";
import ParticleCanvas from "./ParticleCanvas";

interface FooterCTAProps {
  release: ReleaseData;
}

export default function FooterCTA({ release }: FooterCTAProps) {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const leftPanel = section.querySelector<HTMLElement>("[data-footer-curtain-left]");
      const rightPanel = section.querySelector<HTMLElement>("[data-footer-curtain-right]");
      const centerPanel = section.querySelector<HTMLElement>("[data-footer-center]");

      const timeline = gsap.timeline({
        defaults: { ease: "power3.inOut" },
        scrollTrigger: {
          trigger: section,
          start: "top 82%",
          toggleActions: "play none none reverse",
        },
      });

      timeline
        .fromTo(leftPanel, { xPercent: -104, autoAlpha: 0.9 }, { xPercent: 0, autoAlpha: 1, duration: 1.02 }, 0)
        .fromTo(rightPanel, { xPercent: 104, autoAlpha: 0.9 }, { xPercent: 0, autoAlpha: 1, duration: 1.02 }, 0)
        .fromTo(
          centerPanel,
          { autoAlpha: 0, y: 26, scale: 0.97 },
          { autoAlpha: 1, y: 0, scale: 1, duration: 0.7, ease: "power2.out" },
          0.56
        );
    },
    []
  );

  return (
    <footer ref={sectionRef} className="footer-cta-section relative overflow-hidden px-6 pt-24">
      <ParticleCanvas density="dense" count={90} />
      <div className="footer-aurora" aria-hidden="true" />

      <div data-footer-curtain-left className="footer-curtain-panel footer-curtain-left" aria-hidden="true" />
      <div data-footer-curtain-right className="footer-curtain-panel footer-curtain-right" aria-hidden="true" />

      <div data-footer-center className="relative z-20 mx-auto flex min-h-[56vh] max-w-4xl flex-col items-center justify-center text-center">
        <h2 className="footer-cta-heading">Build your private workspace with Kivixa.</h2>
        <p className="footer-cta-copy">
          One app for notes, sketching, planning, and local AI.
          <br />
          Cross-platform, offline, and entirely yours.
        </p>

        <div className="footer-cta-buttons">
          <a href={release.releaseUrl} className="silver-button silver-button-primary">
            Download latest
          </a>
          <a href="https://github.com/990aa/kivixa" target="_blank" rel="noopener noreferrer" className="silver-button silver-button-secondary">
            GitHub
          </a>
        </div>

        <p data-testid="footer-version" className="footer-release-line">
          · Release v{release.version} ·
        </p>
      </div>

      <div className="footer-bottom-strip">
        <p>© 2026 Kivixa · MIT Licensed · Built with Flutter & Rust · Privacy Policy</p>
      </div>
    </footer>
  );
}
