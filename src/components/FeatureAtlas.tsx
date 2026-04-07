"use client";

import { motion } from "framer-motion";

type ModelEntry = {
  name: string;
  family: string;
  role: string;
  tags: string[];
};

type FeatureCluster = {
  title: string;
  summary: string;
  points: string[];
};

const models: ModelEntry[] = [
  {
    name: "Phi-4 Mini",
    family: "Microsoft Phi",
    role: "Default local reasoning and conversation model.",
    tags: ["General", "Reasoning", "Daily assistant"],
  },
  {
    name: "Phi-4 Mini Reasoning",
    family: "Microsoft Phi",
    role: "Reasoning-tuned Phi model for heavier logic and math flows.",
    tags: ["Reasoning", "Math", "Logic"],
  },
  {
    name: "Qwen 2.5 3B",
    family: "Qwen",
    role: "Writing, notes, and code-friendly balanced model.",
    tags: ["Writing", "Code", "Balanced"],
  },
  {
    name: "Qwen3.5 4B Distilled",
    family: "Qwen",
    role: "Highest-quality distilled Qwen path for deep reasoning and coding.",
    tags: ["Strong quality", "Reasoning", "Code"],
  },
  {
    name: "Qwen3.5 2B Distilled",
    family: "Qwen",
    role: "Balanced speed and quality for broad day-to-day usage.",
    tags: ["Balanced", "General", "Fast"],
  },
  {
    name: "Qwen3.5 0.8B Distilled",
    family: "Qwen",
    role: "Lightweight option tuned for low-memory devices.",
    tags: ["Lightweight", "Low RAM", "Fast"],
  },
  {
    name: "DeepSeek R1 Distill Qwen 1.5B",
    family: "DeepSeek / Qwen",
    role: "Compact reasoning model with strong math and code behavior.",
    tags: ["Reasoning", "Math", "Code"],
  },
  {
    name: "SmolLM2 1.7B Instruct",
    family: "SmolLM",
    role: "Compact instruct model for lightweight coding and drafting.",
    tags: ["Compact", "Writing", "Instruct"],
  },
  {
    name: "SmolLM3 3B",
    family: "SmolLM",
    role: "Newer SmolLM generation with stronger assistant quality.",
    tags: ["General", "Stronger output", "Compact"],
  },
  {
    name: "SmolVLM2 500M Video Instruct",
    family: "SmolVLM",
    role: "Vision-language model for image-aware prompts and multimodal flows.",
    tags: ["Vision", "Multimodal", "GGUF + mmproj"],
  },
  {
    name: "Function Gemma 270M",
    family: "Gemma",
    role: "Ultra-fast MCP and tool-calling specialist.",
    tags: ["MCP", "Tool calling", "Ultra-fast"],
  },
  {
    name: "Gemma 2B",
    family: "Gemma",
    role: "Efficient compact general-purpose Gemma model.",
    tags: ["General", "Compact", "Efficient"],
  },
  {
    name: "Gemma 3 4B IT",
    family: "Gemma",
    role: "Balanced instruction model with stronger output quality.",
    tags: ["General", "Writing", "Code"],
  },
  {
    name: "Gemma 4 E2B IT",
    family: "Gemma",
    role: "High-quality Gemma-family instruct model for deeper workloads.",
    tags: ["High quality", "Coding", "General"],
  },
  {
    name: "TranslateGemma 4B IT",
    family: "Gemma",
    role: "Multilingual translation and rewriting for note workflows.",
    tags: ["Multilingual", "Translation", "Rewrite"],
  },
];

const clusters: FeatureCluster[] = [
  {
    title: "On-Device AI Core",
    summary:
      "Private local AI stack with model routing, MCP tooling, and knowledge retrieval.",
    points: [
      "Task-aware multi-model routing for chat, coding, and tool usage.",
      "MCP with user-confirmed file operations, directory listing, export, and Lua scripting.",
      "Attachment-aware chat context with markdown rendering and prompt history recall.",
      "Knowledge graph plus local vector database for semantic retrieval.",
      "Model manager with background downloads, resume support, and progress telemetry.",
      "No API keys and no cloud dependency after model download.",
    ],
  },
  {
    title: "Audio Intelligence",
    summary:
      "Full offline speech stack from dictation to neural TTS and read-aloud controls.",
    points: [
      "Whisper-based streaming STT with timestamps and searchable transcriptions.",
      "Kokoro-based TTS with voice profile selection and speed controls.",
      "Voice activity detection with noise-floor calibration and sensitivity controls.",
      "Dictation bars in editors and chat surfaces, including floating assistant paths.",
      "Voice notes with waveform and transcript interactions.",
      "Read-aloud mini-player with sentence navigation and FAB access.",
    ],
  },
  {
    title: "Notes And Documents",
    summary:
      "Core writing workspace for markdown, text, and linked note structures.",
    points: [
      "Rich markdown editor with autosave and block/text formatting controls.",
      "Text editor support with syntax-oriented workflows.",
      "Floating text boxes for moveable/resizable in-canvas writing.",
      "File management for create, move, rename, and delete operations.",
      "Support for .kvx, .md, .txt, and PDF-based work.",
      "Bidirectional note linking for connected document systems.",
    ],
  },
  {
    title: "Media Embedding",
    summary:
      "Image and video embedding with transform controls and performance-focused rendering.",
    points: [
      "Upload local media or embed from URLs into markdown and text flows.",
      "Resize, rotate, drag, and precise move-handle transformations.",
      "Comment annotations for embedded media with edit/delete handling.",
      "Web image modes for local cache or fetch-on-demand behavior.",
      "Large-image preview tools with minimap-style visibility context.",
      "Extended markdown transform syntax with cached/lazy render optimizations.",
    ],
  },
  {
    title: "Life Git Versioning",
    summary:
      "Built-in note version control with timeline restore and SHA-256 blob storage.",
    points: [
      "Auto-snapshots after editing pauses for continuous history.",
      "Per-file commit history and chronological version browsing.",
      "Preview-and-restore historical states with low friction.",
      "Content-addressable backend for storage efficiency.",
      "Slider-based time travel for rapid rollback workflows.",
      "Zero-config default behavior for all note types.",
    ],
  },
  {
    title: "Plugins And Automation",
    summary:
      "Lua-based automation layer with app APIs and script runner tooling.",
    points: [
      "Lua 5.3 scripting integration for note automation.",
      "App API for create/read/write/move/delete/search note flows.",
      "Built-in plugin examples for recurring maintenance tasks.",
      "Plugin manager for enable/disable and run workflows.",
      "Ad-hoc script runner for one-off automations.",
      "Workflow-safe operations designed around local note folders.",
    ],
  },
  {
    title: "Projects And Planning",
    summary:
      "Structured planning for projects, tasks, and calendar-aligned execution.",
    points: [
      "Project dashboard with category-based organization.",
      "Task management and visual progress tracking.",
      "Calendar day/week/month event views.",
      "Recurring events and pre-event reminders.",
      "Date navigation shortcuts for planning continuity.",
      "Integrated productivity timing for scheduled deep-work blocks.",
    ],
  },
  {
    title: "Digital Canvas",
    summary:
      "High-fidelity handwritten and drawing canvas for visual thinking and annotation.",
    points: [
      "Pen, highlighter, laser pointer, eraser, shapes, and selection tools.",
      "Pressure-sensitive workflows for stylus-first writing.",
      "Smooth pan/zoom and large-canvas navigation.",
      "Mixed media note support alongside typed content.",
      "Tool customization for precision sketching.",
      "Productive bridge between handwritten and structured notes.",
    ],
  },
  {
    title: "PDF And Browser Workflows",
    summary:
      "Research-ready reading stack with PDF annotation and a built-in browser.",
    points: [
      "Import, annotate, and export PDFs with high-quality rendering.",
      "In-app browser tabs with history and quick-link support.",
      "Find in page, developer console, and JavaScript dialog handling.",
      "Dark mode injection and runtime permission controls.",
      "Floating browser window for side-by-side workflows.",
      "Android and desktop browser integrations for continuity.",
    ],
  },
  {
    title: "Productivity Clock",
    summary:
      "Timer system with presets, chained routines, analytics, and notifications.",
    points: [
      "Pomodoro and custom work/break session types with floating timer access.",
      "Context tags with filterable analytics for activity-based insights.",
      "Quick-switch productivity presets for coding, reading, design, and meetings.",
      "Parallel secondary timers for reminders and posture/water/eye-break habits.",
      "Chained routines with auto-advance block execution.",
      "Session history, completion metrics, and notification controls.",
    ],
  },
  {
    title: "Math Suite",
    summary:
      "Rust-powered math module across general, algebra, calculus, stats, and graphing tabs.",
    points: [
      "General scientific calculator and expression evaluation.",
      "Algebra solving, simplification, factorization, and polynomial operations.",
      "Calculus with derivatives, limits, Taylor, and multiple integrals.",
      "Statistics with distributions, regression, and test workflows.",
      "Discrete math including combinatorics and number-theory tools.",
      "Graphing plus utilities like conversions, constants, and formula references.",
    ],
  },
  {
    title: "Quick Notes And Personalization",
    summary:
      "Fast-capture quick notes, flexible theming, and privacy-first defaults.",
    points: [
      "Quick notes via floating hub and browse widget entry points.",
      "Text and handwriting input modes with live sync.",
      "Configurable auto-expiration with manual override controls.",
      "Material You theming, dark/light modes, and custom fonts.",
      "Flexible layout and toolbar customization options.",
      "Local-first encrypted storage with full data-export control.",
    ],
  },
];

const cardVariants = {
  hidden: { opacity: 0, y: 16 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.45, ease: [0.22, 1, 0.36, 1] as const },
  },
};

export default function FeatureAtlas() {
  return (
    <section id="atlas" data-testid="feature-atlas-section" className="relative py-24 sm:py-32 px-6">
      <div className="absolute inset-0 -z-10 pointer-events-none">
        <div className="absolute top-28 left-1/2 -translate-x-1/2 w-[960px] h-[380px] rounded-full bg-accent-blue/6 blur-[120px]" />
        <div className="absolute bottom-10 left-0 right-0 h-px bg-gradient-to-r from-transparent via-border-default to-transparent" />
      </div>

      <div className="max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.55 }}
          className="text-center mb-14"
        >
          <p className="text-xs font-mono uppercase tracking-[0.2em] text-accent-teal mb-4">
            Readme Atlas
          </p>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-text-primary mb-4">
            Feature map of the full Kivixa stack
          </h2>
          <p className="text-text-secondary text-lg max-w-3xl mx-auto">
            Every major capability and model family documented in Kivixa&apos;s README is mapped below in a browsable visual index.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-60px" }}
          transition={{ duration: 0.5 }}
          className="rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-sm p-6 sm:p-8 mb-14"
        >
          <div className="flex items-center justify-between gap-4 mb-6 flex-wrap">
            <h3 className="text-2xl font-semibold tracking-tight text-text-primary">
              Included AI Models
            </h3>
            <span className="inline-flex items-center rounded-full border border-border-default bg-surface-800/60 px-3 py-1 text-xs font-mono text-text-muted">
              {models.length} models listed
            </span>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {models.map((model) => (
              <motion.article
                key={model.name}
                variants={cardVariants}
                initial="hidden"
                whileInView="visible"
                viewport={{ once: true, margin: "-40px" }}
                className="rounded-xl border border-border-subtle bg-surface-800/45 p-4 hover:border-border-hover transition-colors"
              >
                <div className="flex items-start justify-between gap-3 mb-2">
                  <h4 className="text-sm font-semibold text-text-primary leading-snug">{model.name}</h4>
                  <span className="text-[10px] uppercase tracking-[0.12em] text-accent-teal font-mono whitespace-nowrap">
                    {model.family}
                  </span>
                </div>
                <p className="text-xs text-text-secondary mb-3 leading-relaxed">{model.role}</p>
                <div className="flex flex-wrap gap-2">
                  {model.tags.map((tag) => (
                    <span
                      key={`${model.name}-${tag}`}
                      className="text-[11px] rounded-md border border-border-subtle bg-surface-700/50 px-2 py-1 text-text-muted"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </motion.article>
            ))}
          </div>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-5">
          {clusters.map((cluster) => (
            <motion.article
              key={cluster.title}
              variants={cardVariants}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true, margin: "-50px" }}
              className="rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-sm p-6"
            >
              <h3 className="text-xl font-semibold tracking-tight text-text-primary mb-2">
                {cluster.title}
              </h3>
              <p className="text-sm text-text-secondary leading-relaxed mb-4">{cluster.summary}</p>
              <ul className="space-y-2.5">
                {cluster.points.map((point) => (
                  <li key={`${cluster.title}-${point}`} className="flex items-start gap-2.5 text-sm text-text-secondary">
                    <span className="mt-2 h-1.5 w-1.5 rounded-full bg-accent-blue shrink-0" aria-hidden="true" />
                    <span>{point}</span>
                  </li>
                ))}
              </ul>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  );
}
