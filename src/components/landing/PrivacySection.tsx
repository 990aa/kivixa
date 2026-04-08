"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";

export default function PrivacySection() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const lock = section.querySelector<HTMLElement>("[data-lock-body]");
      const shackle = section.querySelector<SVGGElement>("[data-lock-shackle]");
      const pillars = Array.from(section.querySelectorAll<HTMLElement>("[data-privacy-pillar]"));
      const cloudCount = section.querySelector<HTMLElement>("[data-cloud-count]");

      const timeline = gsap.timeline({
        defaults: { ease: "power2.out" },
        scrollTrigger: {
          trigger: section,
          start: "top 76%",
          toggleActions: "play none none reverse",
        },
      });

      timeline
        .fromTo(lock, { autoAlpha: 0, y: 26, scale: 0.88 }, { autoAlpha: 1, y: 0, scale: 1, duration: 0.7 }, 0)
        .fromTo(
          shackle,
          { rotation: -24, transformOrigin: "50% 92%" },
          { rotation: 0, duration: 0.55, ease: "power3.out" },
          0.25
        )
        .fromTo(
          pillars,
          { autoAlpha: 0, y: 34 },
          { autoAlpha: 1, y: 0, duration: 0.6, stagger: 0.11 },
          0.35
        );

      if (cloudCount) {
        const value = { n: 100 };
        timeline.to(
          value,
          {
            n: 0,
            duration: 0.9,
            ease: "power1.out",
            onUpdate: () => {
              cloudCount.textContent = `${Math.round(value.n)}%`;
            },
          },
          0.52
        );
      }
    },
    []
  );

  return (
    <section ref={sectionRef} className="privacy-section relative px-6 py-24 sm:py-28">
      <div className="privacy-fog" aria-hidden="true" />

      <div className="relative mx-auto max-w-6xl">
        <div className="privacy-header-block">
          <h2 className="privacy-heading">Your data never leaves your device.</h2>
          <p className="privacy-body-copy">
            No cloud sync required. No account needed. No telemetry.
            <br />
            Kivixa stores everything in your local file system - notes,
            <br />
            models, vectors, history - all yours, all offline.
          </p>
        </div>

        <div className="privacy-lock-row">
          <div data-lock-body className="privacy-lock-shell" aria-hidden="true">
            <svg viewBox="0 0 220 230" width="220" height="230" fill="none" xmlns="http://www.w3.org/2000/svg">
              <g data-lock-shackle>
                <path
                  d="M62 96V66C62 38 84 16 112 16C140 16 162 38 162 66V96"
                  stroke="url(#shackleStroke)"
                  strokeWidth="15"
                  strokeLinecap="round"
                />
              </g>
              <rect x="42" y="88" width="140" height="126" rx="20" fill="url(#lockBody)" stroke="url(#shackleStroke)" strokeWidth="2" />
              <circle cx="112" cy="146" r="16" fill="#b8a882" />
              <rect x="106" y="160" width="12" height="30" rx="6" fill="#b8a882" />
              <defs>
                <linearGradient id="shackleStroke" x1="42" y1="16" x2="182" y2="214" gradientUnits="userSpaceOnUse">
                  <stop stopColor="#e8edf2" />
                  <stop offset="0.58" stopColor="#c0c8d4" />
                  <stop offset="1" stopColor="#6c757d" />
                </linearGradient>
                <linearGradient id="lockBody" x1="42" y1="88" x2="182" y2="214" gradientUnits="userSpaceOnUse">
                  <stop stopColor="#242a32" />
                  <stop offset="1" stopColor="#121418" />
                </linearGradient>
              </defs>
            </svg>
          </div>
        </div>

        <div className="privacy-pillars-grid">
          <article data-privacy-pillar className="privacy-pillar-card">
            <p className="pillar-title">Local</p>
            <p className="pillar-title">Storage</p>
            <p className="pillar-line"><span data-cloud-count>0%</span> data</p>
            <p className="pillar-line">to cloud</p>
          </article>

          <article data-privacy-pillar className="privacy-pillar-card">
            <p className="pillar-title">Encrypted</p>
            <p className="pillar-title">Storage</p>
            <p className="pillar-line">Secure</p>
            <p className="pillar-line">at rest</p>
          </article>

          <article data-privacy-pillar className="privacy-pillar-card">
            <p className="pillar-title">Offline</p>
            <p className="pillar-title">First</p>
            <p className="pillar-line">No internet</p>
            <p className="pillar-line">required</p>
          </article>
        </div>
      </div>
    </section>
  );
}
