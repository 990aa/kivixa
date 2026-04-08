"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import ScreenshotImage from "@/components/ScreenshotImage";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";

const badges = [
  { label: "PRIVACY", x: -150, y: 0, className: "badge-left" },
  { label: "OFFLINE", x: 150, y: 0, className: "badge-right" },
  { label: "AI", x: 0, y: 110, className: "badge-bottom-left" },
  { label: "SPEED", x: 0, y: 110, className: "badge-bottom-right" },
];

export default function AppMockupSection() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const mockup = section.querySelector<HTMLElement>("[data-mockup-shell]");
      const reflection = section.querySelector<HTMLElement>("[data-mockup-reflection]");
      const grid = section.querySelector<HTMLElement>("[data-mockup-grid]");
      const badgeNodes = Array.from(section.querySelectorAll<HTMLElement>("[data-floating-badge]"));

      const mm = gsap.matchMedia();

      mm.add("(max-width: 767px)", () => {
        gsap.fromTo(
          mockup,
          { y: 84, scale: 0.97, autoAlpha: 0 },
          {
            y: 0,
            scale: 1,
            autoAlpha: 1,
            ease: "none",
            scrollTrigger: {
              trigger: section,
              start: "top 86%",
              end: "bottom 25%",
              scrub: 1,
            },
          }
        );
      });

      mm.add("(min-width: 768px)", () => {
        gsap.fromTo(
          mockup,
          { y: 120, scale: 0.96, autoAlpha: 0 },
          {
            y: 0,
            scale: 1,
            autoAlpha: 1,
            ease: "none",
            scrollTrigger: {
              trigger: section,
              start: "top 80%",
              end: "bottom 18%",
              scrub: 1.5,
            },
          }
        );
      });

      gsap.fromTo(
        reflection,
        { autoAlpha: 0 },
        {
          autoAlpha: 0.58,
          scrollTrigger: {
            trigger: section,
            start: "top 82%",
            end: "top 40%",
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
            start: "top 86%",
            end: "top 40%",
            scrub: 1.5,
          },
        }
      );

      badgeNodes.forEach((node) => {
        const fromX = Number(node.dataset.fromX ?? "0");
        const fromY = Number(node.dataset.fromY ?? "0");

        gsap.fromTo(
          node,
          { x: fromX, y: fromY, autoAlpha: 0 },
          {
            x: 0,
            y: 0,
            autoAlpha: 1,
            duration: 0.8,
            ease: "power3.out",
            scrollTrigger: {
              trigger: section,
              start: "top 78%",
              toggleActions: "play none none reverse",
            },
          }
        );
      });

      return () => {
        mm.revert();
      };
    },
    []
  );

  return (
    <section ref={sectionRef} className="app-mockup-section relative overflow-hidden px-6 py-24 sm:py-30">
      <div className="mockup-grid-overlay" data-mockup-grid aria-hidden="true" />

      <div className="mx-auto max-w-6xl">
        <p className="mockup-copy text-center">
          A local-first workspace that feels native on every
          <br />
          platform, tuned for focused work and private intelligence.
        </p>

        <div className="mockup-stage" data-mockup-shell>
          <div className="mockup-glass-frame mockup-desktop">
            <ScreenshotImage
              src="/assets/screenshots/workspace-notes.png"
              alt="Kivixa desktop layout with file browser and notes view"
              width={1919}
              height={1002}
              loading="eager"
            />
          </div>

          <div className="mockup-glass-frame mockup-phone">
            <ScreenshotImage
              src="/assets/screenshots/ai-chat.png"
              alt="Kivixa local AI chat view"
              width={1919}
              height={1006}
            />
          </div>

          <div data-mockup-reflection className="mockup-reflection" aria-hidden="true" />

          {badges.map((badge) => (
            <span
              key={badge.label}
              className={`floating-pill ${badge.className}`}
              data-floating-badge
              data-from-x={badge.x}
              data-from-y={badge.y}
            >
              {badge.label}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
