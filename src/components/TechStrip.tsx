"use client";

const techItems = [
  "Flutter 3.41.6",
  "Dart 3.11.4",
  "Rust",
  "llama.cpp",
  "Local Vector DB",
  "MCP",
  "On-device AI",
  "Whisper STT",
  "Kokoro TTS",
  "Vulkan / Metal",
  "Content-Addressable Storage",
  "Lua Scripting",
];

export default function TechStrip() {
  // Double the items for seamless loop
  const doubled = [...techItems, ...techItems];

  return (
    <section className="relative py-8 overflow-hidden border-y border-border-subtle">
      <div className="absolute inset-0 bg-surface-850/50" />
      <div className="marquee-track">
        {doubled.map((item, i) => (
          <span
            key={`${item}-${i}`}
            className="inline-flex items-center gap-3 px-6 text-sm font-mono text-text-muted whitespace-nowrap select-none"
          >
            <span className="w-1 h-1 rounded-full bg-accent-primary/40" />
            {item}
          </span>
        ))}
      </div>
    </section>
  );
}
