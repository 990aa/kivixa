"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import { useScrollTrigger } from "@/hooks/useScrollTrigger";

const pillars = [
  { label: "Local", value: 100 },
  { label: "Encrypted", value: 100 },
  { label: "Offline", value: 100 },
];

export default function PrivacyVault() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollTrigger(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const lock = section.querySelector<HTMLElement>("[data-lock]");
      const shackle = section.querySelector<SVGElement>("[data-lock-shackle]");
      const quote = section.querySelector<HTMLElement>("[data-privacy-quote]");
      const pillarNodes = Array.from(section.querySelectorAll<HTMLElement>("[data-pillar]"));
      const counters = Array.from(section.querySelectorAll<HTMLElement>("[data-count]"));

      const timeline = gsap.timeline({
        defaults: { ease: "power2.out" },
        scrollTrigger: {
          trigger: section,
          start: "top 72%",
          end: "top 24%",
          scrub: 1,
        },
      });

      timeline
        .fromTo(lock, { autoAlpha: 0, y: 30, scale: 0.82 }, { autoAlpha: 1, y: 0, scale: 1, duration: 0.8 }, 0)
        .fromTo(
          shackle,
          { y: -20, rotation: -18, transformOrigin: "50% 100%" },
          { y: 0, rotation: 0, duration: 0.65, ease: "power3.out" },
          0.2
        )
        .fromTo(
          pillarNodes,
          { autoAlpha: 0, y: 52 },
          { autoAlpha: 1, y: 0, duration: 0.7, stagger: 0.12 },
          0.4
        )
        .fromTo(quote, { autoAlpha: 0, y: 16 }, { autoAlpha: 1, y: 0, duration: 0.55 }, 0.95);

      counters.forEach((counter) => {
        const target = Number(counter.dataset.target ?? "0");
        const value = { n: 0 };

        timeline.to(
          value,
          {
            n: target,
            duration: 1,
            ease: "power1.out",
            onUpdate: () => {
              counter.textContent = `${Math.round(value.n)}%`;
            },
          },
          0.56
        );
      });
    },
    []
  );

  return (
    <section className="scene privacy-vault relative min-h-[92vh] px-6 py-28 sm:py-32" ref={sectionRef}>
      <div className="fog-layer" aria-hidden="true" />

      <div className="relative mx-auto max-w-6xl">
        <div className="text-center">
          <p className="mb-4 text-xs font-mono uppercase tracking-[0.24em] text-silver-accent">Scene 5</p>
          <h2 className="text-balance text-3xl font-semibold tracking-tight text-text-primary sm:text-4xl md:text-5xl">
            Security architecture, not a marketing promise
          </h2>
        </div>

        <div className="mt-12 grid items-center gap-10 lg:grid-cols-[auto_1fr]">
          <div data-lock className="privacy-lock-shell will-change-transform" aria-hidden="true">
            <svg width="210" height="230" viewBox="0 0 210 230" fill="none" xmlns="http://www.w3.org/2000/svg">
              <g data-lock-shackle>
                <path
                  d="M56 92V62C56 34.3858 78.3858 12 106 12C133.614 12 156 34.3858 156 62V92"
                  stroke="url(#silverStroke)"
                  strokeWidth="16"
                  strokeLinecap="round"
                />
              </g>
              <rect x="35" y="84" width="140" height="132" rx="22" fill="url(#bodyFill)" stroke="url(#silverStroke)" strokeWidth="2" />
              <circle cx="105" cy="145" r="16" fill="#b8a882" />
              <rect x="99" y="158" width="12" height="32" rx="6" fill="#b8a882" />
              <defs>
                <linearGradient id="silverStroke" x1="35" y1="12" x2="176" y2="216" gradientUnits="userSpaceOnUse">
                  <stop stopColor="#e8edf2" />
                  <stop offset="0.5" stopColor="#c0c8d4" />
                  <stop offset="1" stopColor="#6c757d" />
                </linearGradient>
                <linearGradient id="bodyFill" x1="35" y1="84" x2="176" y2="216" gradientUnits="userSpaceOnUse">
                  <stop stopColor="#1f232a" />
                  <stop offset="1" stopColor="#121416" />
                </linearGradient>
              </defs>
            </svg>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            {pillars.map((pillar) => (
              <article key={pillar.label} data-pillar className="privacy-pillar will-change-transform">
                <h3 className="text-lg font-semibold text-text-primary">{pillar.label}</h3>
                <p className="mt-1 text-sm text-text-secondary">Protection coverage</p>
                <p data-count data-target={pillar.value} className="mt-4 text-3xl font-semibold tracking-tight text-silver-shine">
                  0%
                </p>
              </article>
            ))}
          </div>
        </div>

        <div className="mt-8 rounded-2xl border border-silver-700/70 bg-silver-900/55 p-5 text-center">
          <p className="text-sm text-text-secondary">
            Data leaving device
            <span data-count data-target={0} className="ml-2 font-mono text-base text-gold-accent">
              0%
            </span>
          </p>
        </div>

        <blockquote
          data-privacy-quote
          className="mx-auto mt-8 max-w-3xl text-balance text-center text-lg leading-relaxed text-text-primary sm:text-2xl"
        >
          &quot;No API keys. No subscriptions. No data leaving your device. Ever.&quot;
        </blockquote>
      </div>
    </section>
  );
}
