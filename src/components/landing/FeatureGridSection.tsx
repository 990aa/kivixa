"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";

type FeatureCardItem = {
  title: string;
  body: string;
  tag: string;
  icon: "brain" | "audio" | "notes" | "graph" | "timer" | "terminal";
};

const cards: FeatureCardItem[] = [
  {
    title: "On-Device AI",
    body: "Run Phi-4, Qwen3.5, Gemma 4, and 12 other models entirely on your hardware. No API keys. No internet after download. Full reasoning, writing, and tool use - offline.",
    tag: "15 models",
    icon: "brain",
  },
  {
    title: "Audio Intelligence",
    body: "Whisper-powered speech-to-text, Kokoro neural TTS, voice notes with karaoke transcription, and a hands-free AI walkie-talkie - all running locally.",
    tag: "Fully offline",
    icon: "audio",
  },
  {
    title: "Rich Note-Taking",
    body: "Markdown editor, handwriting canvas, floating text boxes, bidirectional note linking, image/video embedding, and Life Git - automatic version control for every note.",
    tag: "+PDF support",
    icon: "notes",
  },
  {
    title: "Knowledge Graph",
    body: "Build visual mind maps with hub, note, and idea nodes. Connect them with labeled arrows, pan and zoom freely, and link graph nodes directly to your notes.",
    tag: "Interactive",
    icon: "graph",
  },
  {
    title: "Productivity Suite",
    body: "Pomodoro, 52/17, Ultradian timers. Chained routines. Multi-timer orchestration. Project manager with task tracking. Calendar with recurring events and reminders.",
    tag: "Built-in",
    icon: "timer",
  },
  {
    title: "Scriptable & Extensible",
    body: "Lua plugin system with a full App API - create, read, move, and search notes programmatically. MCP tool execution lets the AI perform file operations on your behalf.",
    tag: "Lua 5.3",
    icon: "terminal",
  },
];

function FeatureIcon({ kind }: { kind: FeatureCardItem["icon"] }) {
  switch (kind) {
    case "brain":
      return (
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M9 4a3 3 0 0 0-3 3v1a3 3 0 0 0-2 2.84A3 3 0 0 0 6 14v1a3 3 0 0 0 3 3h1" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
          <path d="M15 4a3 3 0 0 1 3 3v1a3 3 0 0 1 2 2.84A3 3 0 0 1 18 14v1a3 3 0 0 1-3 3h-1" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
          <path d="M12 4v16M9 8h3M12 12h3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
        </svg>
      );
    case "audio":
      return (
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M4 12h2m3-4v8m4-11v14m4-10v6m3-3h-2" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
        </svg>
      );
    case "notes":
      return (
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <rect x="4" y="3.5" width="16" height="17" rx="2" stroke="currentColor" strokeWidth="1.7" />
          <path d="M8 8h8M8 12h8M8 16h5" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
        </svg>
      );
    case "graph":
      return (
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <circle cx="6" cy="6" r="2" stroke="currentColor" strokeWidth="1.7" />
          <circle cx="18" cy="7" r="2" stroke="currentColor" strokeWidth="1.7" />
          <circle cx="12" cy="18" r="2" stroke="currentColor" strokeWidth="1.7" />
          <path d="M8 7.2l8 1.6M7.4 7.7l3.8 8.5M16.8 8.6l-3.6 7.3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
        </svg>
      );
    case "timer":
      return (
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <circle cx="12" cy="13" r="7" stroke="currentColor" strokeWidth="1.7" />
          <path d="M12 13V9m0-6h-3m3 0h3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
        </svg>
      );
    default:
      return (
        <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M8 8l-4 4 4 4m8-8l4 4-4 4M13 5l-2 14" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      );
  }
}

export default function FeatureGridSection() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const nodes = Array.from(section.querySelectorAll<HTMLElement>("[data-feature-card]"));

      nodes.forEach((card, index) => {
        const fromX = index % 2 === 0 ? -160 : 160;

        gsap.fromTo(
          card,
          { x: fromX, autoAlpha: 0 },
          {
            x: 0,
            autoAlpha: 1,
            duration: 0.78,
            delay: index * 0.12,
            ease: "power2.out",
            scrollTrigger: {
              trigger: section,
              start: "top 74%",
              toggleActions: "play none none reverse",
            },
          }
        );

        const icon = card.querySelector<HTMLElement>("[data-feature-icon]");
        gsap.fromTo(
          icon,
          { scale: 0.74, rotation: -14, autoAlpha: 0 },
          {
            scale: 1,
            rotation: 0,
            autoAlpha: 1,
            delay: index * 0.12 + 0.08,
            duration: 0.34,
            ease: "back.out(2)",
            scrollTrigger: {
              trigger: section,
              start: "top 74%",
              toggleActions: "play none none reverse",
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
      className="feature-grid-section px-6 py-24 sm:py-28"
    >
      <div className="mx-auto grid max-w-6xl gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {cards.map((card) => (
          <article key={card.title} data-feature-card className="feature-card-shell feature-card-hover">
            <div className="feature-card-inner">
              <div className="feature-header-row">
                <span data-feature-icon className="feature-icon" aria-hidden="true">
                  <FeatureIcon kind={card.icon} />
                </span>
                <span className="feature-tag">{card.tag}</span>
              </div>
              <h3 className="feature-title">{card.title}</h3>
              <p className="feature-body">{card.body}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
