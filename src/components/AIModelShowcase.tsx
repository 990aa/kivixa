"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import { useScrollTrigger } from "@/hooks/useScrollTrigger";

gsap.registerPlugin(TextPlugin);

type ModelLine = {
  name: string;
  tag: string;
};

const modelLines: ModelLine[] = [
  { name: "Phi-4 Mini", tag: "Reasoning" },
  { name: "Phi-4 Mini Reasoning", tag: "Logic" },
  { name: "Qwen 2.5 3B", tag: "Writing" },
  { name: "Qwen3.5 4B Distilled", tag: "Code" },
  { name: "Qwen3.5 2B Distilled", tag: "Balanced" },
  { name: "Qwen3.5 0.8B Distilled", tag: "Speed" },
  { name: "DeepSeek R1 Distill Qwen 1.5B", tag: "Reasoning" },
  { name: "SmolLM2 1.7B Instruct", tag: "Compact" },
  { name: "SmolLM3 3B", tag: "General" },
  { name: "SmolVLM2 500M Video Instruct", tag: "Vision" },
  { name: "Function Gemma 270M", tag: "Tool Use" },
  { name: "Gemma 2B", tag: "General" },
  { name: "Gemma 3 4B IT", tag: "Writing" },
  { name: "Gemma 4 E2B IT", tag: "Code" },
  { name: "TranslateGemma 4B IT", tag: "Multilingual" },
];

export default function AIModelShowcase() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollTrigger(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const panel = section.querySelector<HTMLElement>("[data-terminal-panel]");
      const progress = section.querySelector<HTMLElement>("[data-progress-bar]");
      const rows = Array.from(section.querySelectorAll<HTMLElement>("[data-model-row]"));

      const timeline = gsap.timeline({
        defaults: { ease: "power2.out" },
        scrollTrigger: {
          trigger: section,
          start: "top 78%",
          end: "top 26%",
          scrub: 1,
        },
      });

      timeline.fromTo(panel, { y: 90, autoAlpha: 0 }, { y: 0, autoAlpha: 1, duration: 0.8 }, 0);

      rows.forEach((row, index) => {
        const name = row.querySelector<HTMLElement>("[data-model-name]");
        const tag = row.querySelector<HTMLElement>("[data-model-tag]");
        if (!name || !tag) return;

        timeline.set(name, { text: "" }, 0);
        timeline.to(
          name,
          {
            duration: 0.32,
            text: modelLines[index].name,
            ease: "none",
          },
          0.18 + index * 0.08
        );
        timeline.fromTo(
          tag,
          { scale: 0.4, autoAlpha: 0 },
          { scale: 1, autoAlpha: 1, duration: 0.2, ease: "back.out(1.8)" },
          0.26 + index * 0.08
        );
      });

      timeline.fromTo(
        progress,
        { scaleX: 0 },
        {
          scaleX: 1,
          duration: 1.1,
          transformOrigin: "left center",
          ease: "power1.out",
        },
        0.2
      );
    },
    []
  );

  return (
    <section className="scene ai-showcase px-6 py-28 sm:py-32">
      <div className="mx-auto max-w-6xl">
        <div className="mb-10 text-center">
          <p className="mb-4 text-xs font-mono uppercase tracking-[0.24em] text-silver-accent">Scene 4</p>
          <h2 className="text-balance text-3xl font-semibold tracking-tight text-text-primary sm:text-4xl md:text-5xl">
            15 models. Zero internet. All yours.
          </h2>
          <p className="mx-auto mt-4 max-w-3xl text-balance text-base leading-relaxed text-text-secondary sm:text-lg">
            Kivixa loads model families like a terminal boot sequence: private, local, and instantly ready for reasoning, writing, translation, and tool use.
          </p>
        </div>

        <div data-terminal-panel className="terminal-shell terminal-scanlines will-change-transform">
          <div className="terminal-header">
            <span className="terminal-dot" />
            <span className="terminal-dot" />
            <span className="terminal-dot" />
            <p className="terminal-title">kivixa-models://local-registry</p>
          </div>

          <div className="terminal-progress-track">
            <span data-progress-bar className="terminal-progress-fill" />
          </div>

          <ul className="terminal-list">
            {modelLines.map((model) => (
              <li key={model.name} data-model-row className="terminal-row">
                <span data-model-name className="terminal-model-name">
                  {model.name}
                </span>
                <span data-model-tag className="terminal-model-tag">
                  {model.tag}
                </span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
