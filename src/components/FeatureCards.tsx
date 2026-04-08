"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import { useScrollTrigger } from "@/hooks/useScrollTrigger";
import SilverShimmer from "./SilverShimmer";

type FeatureItem = {
  title: string;
  description: string;
  icon: string;
};

const features: FeatureItem[] = [
  {
    title: "On-Device AI",
    description: "Phi, Qwen, Gemma, and more models run 100% locally with no cloud dependency.",
    icon: "AI",
  },
  {
    title: "Audio Intelligence",
    description: "Whisper STT, Kokoro TTS, read-aloud, dictation controls, and voice note workflows.",
    icon: "AU",
  },
  {
    title: "Rich Notes",
    description: "Markdown, handwriting canvas, floating text boxes, and linked file organization.",
    icon: "NT",
  },
  {
    title: "Knowledge Graph",
    description: "Interactive mind mapping, node linking, and visual relationship building for ideas.",
    icon: "KG",
  },
  {
    title: "Productivity Clock",
    description: "Pomodoro timers, chained routines, multi-timer orchestration, and focus analytics.",
    icon: "TM",
  },
  {
    title: "Privacy First",
    description: "No cloud. No API keys. No tracking. Your data and inference stay on your device.",
    icon: "PF",
  },
];

export default function FeatureCards() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollTrigger(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const cards = Array.from(section.querySelectorAll<HTMLElement>("[data-feature-card]"));

      cards.forEach((card, index) => {
        const fromX = index % 2 === 0 ? -150 : 150;

        gsap.fromTo(
          card,
          { x: fromX, autoAlpha: 0 },
          {
            x: 0,
            autoAlpha: 1,
            duration: 0.9,
            ease: "power3.out",
            scrollTrigger: {
              trigger: card,
              start: "top 82%",
              end: "top 44%",
              scrub: 1,
            },
          }
        );

        const icon = card.querySelector<HTMLElement>("[data-feature-icon]");
        gsap.fromTo(
          icon,
          { scale: 0.74, rotation: -18, autoAlpha: 0 },
          {
            scale: 1,
            rotation: 0,
            autoAlpha: 1,
            duration: 0.45,
            delay: 0.16,
            ease: "back.out(2)",
            scrollTrigger: {
              trigger: card,
              start: "top 82%",
              end: "top 44%",
              scrub: 1,
            },
          }
        );
      });
    },
    []
  );

  return (
    <section
      id="features"
      ref={sectionRef}
      data-testid="features-section"
      className="scene feature-constellation px-6 py-28 sm:py-32"
    >
      <div className="mx-auto max-w-6xl">
        <div className="mb-14 text-center">
          <p className="mb-4 text-xs font-mono uppercase tracking-[0.24em] text-silver-accent">Scene 3</p>
          <h2 className="text-balance text-3xl font-semibold tracking-tight text-text-primary sm:text-4xl md:text-5xl">
            Feature constellation
          </h2>
          <p className="mx-auto mt-4 max-w-3xl text-balance text-base leading-relaxed text-text-secondary sm:text-lg">
            The core capabilities of Kivixa surface as modular building blocks for writing, planning, and local intelligence.
          </p>
        </div>

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <SilverShimmer key={feature.title} className="h-full">
              <article
                data-feature-card
                className="feature-card-panel feature-card-lift h-full will-change-transform"
              >
                <div data-feature-icon className="feature-icon-chip will-change-transform" aria-hidden="true">
                  {feature.icon}
                </div>
                <h3 className="mt-5 text-xl font-semibold tracking-tight text-text-primary">
                  {feature.title}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-text-secondary sm:text-base">
                  {feature.description}
                </p>
              </article>
            </SilverShimmer>
          ))}
        </div>
      </div>
    </section>
  );
}
