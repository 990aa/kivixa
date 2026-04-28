"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import type { ReleaseData } from "@/lib/github";

gsap.registerPlugin(TextPlugin);

interface HeroSectionProps {
  release: ReleaseData;
}

export default function HeroSection({ release }: HeroSectionProps) {
  const sectionRef = useRef<HTMLElement>(null);
  const typedLineRef = useRef<HTMLParagraphElement>(null);

  useEffect(() => {
    const scope = sectionRef.current;
    if (!scope) return;

    const typedMessage = "Your private universe. On-device. Offline. Yours.";

    const ctx = gsap.context(() => {
      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      const heroItems = scope.querySelectorAll("[data-hero-item");

      if (typedLineRef.current) {
        typedLineRef.current.textContent = reducedMotion ? typedMessage : "";
      }

      if (reducedMotion) {
        gsap.set(heroItems, { autoAlpha: 1, y: 0 });
        return;
      }

      gsap.set(heroItems, { y: 30, autoAlpha: 0 });

      const timeline = gsap.timeline({ defaults: { ease: "power3.inOut" } });

      timeline
        .fromTo(
          heroItems,
          { y: 30, autoAlpha: 0 },
          { y: 0, autoAlpha: 1, duration: 0.65, stagger: 0.12, ease: "power2.out" },
          0.16
        )
        .to(
          typedLineRef.current,
          {
            duration: 1.15,
            text: typedMessage,
            ease: "none",
          },
          0.56
        );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  const scrollToDownloads = () => {
    const downloadsSection = document.getElementById("platforms");
    if (downloadsSection) {
      downloadsSection.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <section
      ref={sectionRef}
      data-testid="hero-section"
      className="hero-section relative min-h-screen overflow-hidden px-6"
    >
      <div className="hero-radial-glow" aria-hidden="true" />

      <div className="relative z-10 mx-auto flex min-h-screen w-full max-w-5xl flex-col items-center justify-center text-center">
        <p data-hero-item className="hero-overline">
          KIVIXA WORKSPACE
        </p>

        <h1 data-hero-item className="hero-wordmark">
          <img src="/assets/icon.png" alt="" className="hero-logo" aria-hidden="true" />
          ivixa
        </h1>

        <p data-hero-item className="hero-primary-copy">
          Notes, sketching, planning, and local AI assistance
          <br />
          in one privacy-first cross-platform workspace.
        </p>

        <p ref={typedLineRef} data-hero-item className="hero-typed-line" />

        <div data-hero-item>
          <button
            type="button"
            onClick={scrollToDownloads}
            className="silver-button silver-button-primary"
          >
            Download for your device
          </button>
        </div>
      </div>
    </section>
  );
}
