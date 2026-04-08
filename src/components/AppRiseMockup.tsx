"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import ScreenshotImage from "./ScreenshotImage";
import { useScrollTrigger } from "@/hooks/useScrollTrigger";

const badges = [
  { label: "Privacy", offsetX: -140, offsetY: -70 },
  { label: "Offline", offsetX: 140, offsetY: -76 },
  { label: "AI", offsetX: -160, offsetY: 80 },
  { label: "Speed", offsetX: 165, offsetY: 94 },
];

export default function AppRiseMockup() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollTrigger(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const mockup = section.querySelector<HTMLElement>("[data-mockup]");
      const reflection = section.querySelector<HTMLElement>("[data-reflection]");
      const grid = section.querySelector<HTMLElement>("[data-grid]");
      const badgeNodes = Array.from(section.querySelectorAll<HTMLElement>("[data-badge]"));

      const mm = gsap.matchMedia();

      mm.add("(max-width: 767px)", () => {
        gsap.fromTo(
          mockup,
          { y: 120, rotateX: 7, scale: 0.96 },
          {
            y: 0,
            rotateX: 0,
            scale: 1,
            ease: "none",
            scrollTrigger: {
              trigger: section,
              start: "top 86%",
              end: "bottom 22%",
              scrub: 1.1,
            },
          }
        );
      });

      mm.add("(min-width: 768px)", () => {
        gsap.fromTo(
          mockup,
          { y: 200, rotateX: 12, scale: 0.94 },
          {
            y: 0,
            rotateX: 0,
            scale: 1,
            ease: "none",
            scrollTrigger: {
              trigger: section,
              start: "top 80%",
              end: "bottom 20%",
              scrub: 1.5,
            },
          }
        );
      });

      gsap.fromTo(
        reflection,
        { autoAlpha: 0 },
        {
          autoAlpha: 0.62,
          scrollTrigger: {
            trigger: section,
            start: "top 82%",
            end: "top 45%",
            scrub: 1,
          },
        }
      );

      gsap.fromTo(
        grid,
        { autoAlpha: 0 },
        {
          autoAlpha: 0.1,
          scrollTrigger: {
            trigger: section,
            start: "top 90%",
            end: "top 45%",
            scrub: 1.5,
          },
        }
      );

      badgeNodes.forEach((badge) => {
        const offsetX = Number(badge.dataset.offsetX ?? "0");
        const offsetY = Number(badge.dataset.offsetY ?? "0");

        gsap.fromTo(
          badge,
          { x: offsetX, y: offsetY, autoAlpha: 0 },
          {
            x: 0,
            y: 0,
            autoAlpha: 1,
            duration: 0.9,
            ease: "power3.out",
            scrollTrigger: {
              trigger: section,
              start: "top 78%",
              toggleActions: "play none none reverse",
            },
          }
        );
      });

      return () => mm.revert();
    },
    []
  );

  return (
    <section ref={sectionRef} className="scene app-rise relative overflow-hidden px-6 py-28 sm:py-32">
      <div className="scene-grid-overlay" data-grid aria-hidden="true" />

      <div className="relative mx-auto max-w-6xl">
        <div className="mb-12 text-center">
          <p className="mb-4 text-xs font-mono uppercase tracking-[0.24em] text-silver-accent">Scene 2</p>
          <h2 className="text-balance text-3xl font-semibold tracking-tight text-text-primary sm:text-4xl md:text-5xl">
            The app rises into view
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-balance text-base leading-relaxed text-text-secondary sm:text-lg">
            A local-first workspace that feels native on every platform, tuned for focused work and private intelligence.
          </p>
        </div>

        <div className="mockup-stage perspective-wrap">
          <div data-mockup className="mockup-shell preserve-3d will-change-transform">
            <div className="mockup-device laptop">
              <ScreenshotImage
                src="/assets/screenshots/workspace-notes.png"
                alt="Kivixa workspace with note editor and sidebar"
                width={1919}
                height={1002}
                loading="eager"
              />
            </div>
            <div className="mockup-device phone">
              <ScreenshotImage
                src="/assets/screenshots/ai-chat.png"
                alt="Kivixa AI chat interface in compact view"
                width={1919}
                height={1006}
              />
            </div>
          </div>

          <div data-reflection className="mockup-reflection" aria-hidden="true" />

          {badges.map((badge) => (
            <span
              key={badge.label}
              data-badge
              data-offset-x={badge.offsetX}
              data-offset-y={badge.offsetY}
              className="floating-badge will-change-transform"
            >
              {badge.label}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
