"use client";

import { useRef } from "react";
import { gsap } from "gsap";
import { TextPlugin } from "gsap/TextPlugin";
import { useScrollAnimations } from "@/hooks/useScrollAnimations";

gsap.registerPlugin(TextPlugin);

type ModelEntry = {
  name: string;
  tag: string;
  tone: "silver" | "gold" | "bright" | "muted";
};

const modelEntries: ModelEntry[] = [
  { name: "Phi-4 Mini", tag: "REASONING", tone: "silver" },
  { name: "Phi-4 Mini Reasoning", tag: "REASONING", tone: "silver" },
  { name: "Qwen 2.5 3B", tag: "WRITING", tone: "gold" },
  { name: "Llama 3.2 3B Instruct", tag: "CHAT", tone: "silver" },
  { name: "Qwen2.5 1.5B Instruct", tag: "EFFICIENCY", tone: "muted" },
  { name: "Qwen3.5 4B Distilled", tag: "REASONING+", tone: "bright" },
  { name: "Qwen3.5 2B Distilled", tag: "BALANCED", tone: "muted" },
  { name: "Qwen3.5 0.8B Distilled", tag: "FAST", tone: "muted" },
  { name: "DeepSeek R1 Distill Qwen 1.5B", tag: "MATH/CODE", tone: "silver" },
  { name: "SmolLM2 1.7B Instruct", tag: "COMPACT", tone: "muted" },
  { name: "SmolLM3 3B", tag: "GENERAL", tone: "silver" },
  { name: "SmolVLM2 500M Video Instruct", tag: "VISION", tone: "gold" },
  { name: "Function Gemma 270M", tag: "TOOL USE", tone: "bright" },
  { name: "Gemma 2B", tag: "GENERAL", tone: "silver" },
  { name: "Gemma 3 4B IT", tag: "QUALITY", tone: "silver" },
  { name: "Gemma 4 E2B IT", tag: "QUALITY+", tone: "gold" },
  { name: "TranslateGemma 4B IT", tag: "TRANSLATE", tone: "gold" },
];

export default function AIModelsSection() {
  const sectionRef = useRef<HTMLElement>(null);

  useScrollAnimations(
    sectionRef,
    () => {
      const section = sectionRef.current;
      if (!section) return;

      const panel = section.querySelector<HTMLElement>("[data-terminal-panel]");
      const rows = Array.from(section.querySelectorAll<HTMLElement>("[data-terminal-row]"));
      const progress = section.querySelector<HTMLElement>("[data-terminal-progress]");
      const finalLine = section.querySelector<HTMLElement>("[data-terminal-final]");

      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

      if (reducedMotion) {
        rows.forEach((row, index) => {
          const text = row.querySelector<HTMLElement>("[data-model-text]");
          const badge = row.querySelector<HTMLElement>("[data-model-badge]");
          if (text) text.textContent = modelEntries[index].name;
          if (badge) badge.style.opacity = "1";
        });
        if (progress) progress.style.transform = "scaleX(1)";
        if (finalLine) finalLine.style.opacity = "1";
        return;
      }

      const timeline = gsap.timeline({
        defaults: { ease: "power2.out" },
        scrollTrigger: {
          trigger: section,
          start: "top 76%",
          toggleActions: "play none none reverse",
        },
      });

      timeline.fromTo(
        panel,
        { y: 56, autoAlpha: 0 },
        { y: 0, autoAlpha: 1, duration: 0.65 },
        0
      );

      rows.forEach((row, index) => {
        const text = row.querySelector<HTMLElement>("[data-model-text]");
        const badge = row.querySelector<HTMLElement>("[data-model-badge]");

        if (!text || !badge) return;

        timeline.set(text, { text: "" }, 0);
        timeline.to(
          text,
          {
            duration: 0.22,
            text: modelEntries[index].name,
            ease: "none",
          },
          0.18 + index * 0.08
        );

        timeline.fromTo(
          badge,
          { autoAlpha: 0, scale: 0.45 },
          { autoAlpha: 1, scale: 1, duration: 0.2, ease: "back.out(1.8)" },
          0.24 + index * 0.08
        );
      });

      timeline.fromTo(
        progress,
        { scaleX: 0, transformOrigin: "left center" },
        { scaleX: 1, duration: 1.25, ease: "power1.out" },
        0.2
      );

      timeline.fromTo(
        finalLine,
        { autoAlpha: 0, y: 8 },
        { autoAlpha: 1, y: 0, duration: 0.34 },
        0.18 + rows.length * 0.08 + 0.16
      );
    },
    []
  );

  return (
    <section className="ai-models-section px-6 py-24 sm:py-28" ref={sectionRef}>
      <div className="mx-auto max-w-6xl">
        <h2 className="models-heading text-center">
          17 models. Zero internet. All yours.
        </h2>
        <p className="models-subhead text-center">
          Kivixa loads local AI like a system boot - private, instant,
          <br />
          and ready for reasoning, writing, translation, and tool use.
        </p>

        <div data-terminal-panel className="models-terminal terminal-scanlines">
          <div className="terminal-topbar">
            <span className="terminal-dot dot-red" />
            <span className="terminal-dot dot-yellow" />
            <span className="terminal-dot dot-green" />
            <span className="terminal-registry-label">KIVIXA-MODELS://LOCAL-REGISTRY</span>
          </div>

          <div className="terminal-progress-track">
            <span data-terminal-progress className="terminal-progress-fill" />
          </div>

          <div className="terminal-lines">
            {modelEntries.map((entry) => (
              <div key={entry.name} data-terminal-row className="terminal-line">
                <span className="terminal-check">[✓]</span>
                <span data-model-text className="terminal-model-text">
                  {entry.name}
                </span>
                <span data-model-badge className={`terminal-badge tone-${entry.tone}`}>
                  {entry.tag}
                </span>
              </div>
            ))}

            <div data-terminal-final className="terminal-final-line">
              [✓] 17 models loaded · 0 bytes sent to cloud · GPU: Vulkan / Metal
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
