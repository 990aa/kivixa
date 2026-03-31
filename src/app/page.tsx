"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import type { Variants } from "framer-motion";
import { useReducedMotion, useScroll, useSpring } from "framer-motion";
import {
  BookText,
  Bot,
  BrainCircuit,
  Download,
  Network,
  ShieldCheck,
  Sigma,
  Smartphone,
  Workflow,
} from "lucide-react";

function GitHubMark(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" {...props}>
      <path d="M12 .5C5.65.5.5 5.65.5 12c0 5.1 3.3 9.42 7.88 10.95.57.1.78-.25.78-.56 0-.28-.01-1.19-.02-2.16-3.2.7-3.88-1.36-3.88-1.36-.53-1.33-1.28-1.69-1.28-1.69-1.04-.72.08-.71.08-.71 1.15.08 1.76 1.18 1.76 1.18 1.02 1.75 2.67 1.25 3.32.95.1-.74.4-1.25.72-1.54-2.56-.3-5.26-1.28-5.26-5.72 0-1.26.45-2.28 1.18-3.09-.12-.29-.51-1.46.11-3.04 0 0 .97-.31 3.17 1.18a10.92 10.92 0 0 1 5.77 0c2.2-1.49 3.17-1.18 3.17-1.18.62 1.58.23 2.75.11 3.04.74.81 1.18 1.83 1.18 3.09 0 4.45-2.7 5.41-5.28 5.7.41.36.78 1.05.78 2.13 0 1.53-.01 2.76-.01 3.14 0 .31.2.67.79.56A11.52 11.52 0 0 0 23.5 12C23.5 5.65 18.35.5 12 .5Z" />
    </svg>
  );
}

type ScreenshotItem = {
  src: string;
  title: string;
  caption: string;
};

type FeatureGroup = {
  title: string;
  description: string;
  bullets: string[];
};

export default function Home() {
  const shouldReduceMotion = useReducedMotion();
  const { scrollYProgress } = useScroll();
  const scrollProgress = useSpring(scrollYProgress, {
    stiffness: 120,
    damping: 28,
    mass: 0.24,
  });

  const fadeUpSection: Variants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: shouldReduceMotion ? 0.01 : 0.72,
        ease: [0.16, 1, 0.3, 1],
      },
    },
  };

  const staggerContainer: Variants = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: shouldReduceMotion ? 0 : 0.08,
        delayChildren: shouldReduceMotion ? 0 : 0.04,
      },
    },
  };

  const revealCard: Variants = {
    hidden: { opacity: 0, y: 24 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: shouldReduceMotion ? 0.01 : 0.55,
        ease: [0.16, 1, 0.3, 1],
      },
    },
  };

  const heroHighlights = [
    "On-device multi-model AI + MCP",
    "Markdown, sketching, planning, and voice workflows",
    "Flutter + Rust architecture with local vector intelligence",
  ] as const;

  const featureIcons = [Bot, ShieldCheck, BookText, Network, Sigma, Workflow, BrainCircuit] as const;

  const topFeatureCards = [
    {
      title: "On-Device AI + MCP",
      description:
        "Multi-model local AI with task routing, MCP tool execution, sandboxed file operations, and explicit user confirmation.",
    },
    {
      title: "Deep Knowledge Tools",
      description:
        "Semantic search, auto-categorization, smart summaries, Q&A, title suggestions, and a persistent local vector database.",
    },
    {
      title: "Audio Intelligence",
      description:
        "Offline STT, neural TTS, VAD, neural dictation, voice notes, voice search, and walkie-talkie-style AI conversations.",
    },
    {
      title: "Pro Notes Workflow",
      description:
        "Rich markdown editor, text editor, note linking, floating text boxes, media embedding, transforms, and annotation comments.",
    },
    {
      title: "Creative + Analytical Workspace",
      description:
        "Infinite digital canvas, productivity clock orchestration, calendar events, project dashboard, and Rust-powered math suite.",
    },
    {
      title: "Life Git + Plugins",
      description:
        "Git-like note history with snapshots, version restore, Lua plugin automation, and built-in app APIs for scripting.",
    },
  ] as const;

  const screenshots: ScreenshotItem[] = [
    {
      src: "/assets/screenshots/workspace-notes.png",
      title: "Workspace Notes",
      caption: "Core writing and project organization workspace.",
    },
    {
      src: "/assets/screenshots/markdown-editor.png",
      title: "Markdown Editor",
      caption: "Rich markdown editing with structure and formatting.",
    },
    {
      src: "/assets/screenshots/ai-chat.png",
      title: "AI Chat",
      caption: "Local assistant conversation with note context.",
    },
    {
      src: "/assets/screenshots/ai-model-picker.png",
      title: "AI Model Picker",
      caption: "Switch and route between local models quickly.",
    },
    {
      src: "/assets/screenshots/mcp-tools.png",
      title: "MCP Tools",
      caption: "Action-capable AI tools with safe confirmations.",
    },
    {
      src: "/assets/screenshots/knowledge-graph.png",
      title: "Knowledge Graph",
      caption: "Visual mind mapping and linked note networks.",
    },
    {
      src: "/assets/screenshots/file-version-control.png",
      title: "File Version Control",
      caption: "Track changes with note-level history controls.",
    },
    {
      src: "/assets/screenshots/version-history.png",
      title: "Version History",
      caption: "Time-travel through previous revisions instantly.",
    },
    {
      src: "/assets/screenshots/productivity-calendar.png",
      title: "Productivity Calendar",
      caption: "Events, reminders, and recurring schedules.",
    },
    {
      src: "/assets/screenshots/productivity-clock.png",
      title: "Productivity Clock",
      caption: "Pomodoro, templates, chained routines, analytics.",
    },
    {
      src: "/assets/screenshots/math-module.png",
      title: "Math Module",
      caption: "Fast Rust-backed scientific and algebra workflows.",
    },
    {
      src: "/assets/screenshots/math-module-graph.png",
      title: "Math Graphing",
      caption: "Function graphing and interactive visual analysis.",
    },
    {
      src: "/assets/screenshots/floating-hub.png",
      title: "Floating Hub",
      caption: "Quick access launcher for rapid productivity.",
    },
  ];

  const featureAtlas: FeatureGroup[] = [
    {
      title: "On-Device AI",
      description: "Private local AI engine with broad model and tool support.",
      bullets: [
        "Models include Phi-4 Mini, Qwen variants, DeepSeek distill, SmolLM2, Gemma family, and Function Gemma.",
        "Automatic model routing and seamless switching based on task type.",
        "MCP tool execution for file actions, directory browsing, markdown export, and Lua integrations.",
        "Smart model manager with resume downloads, background fetching, speed/ETA tracking, and GPU acceleration.",
        "Semantic search, auto-categorization, summaries, Q&A, and title suggestions.",
      ],
    },
    {
      title: "Knowledge Graph Visualization",
      description: "Interactive mind mapping with structured, persistent relationships.",
      bullets: [
        "Pan/zoom navigation, draggable nodes, optional alignment grid.",
        "Hub, Note, and Idea nodes with multiple shapes and color options.",
        "Custom links with labels, thickness choices, and arrow styles.",
        "Link note nodes to .kvx, .md, and text files from browse view.",
      ],
    },
    {
      title: "Audio Intelligence",
      description: "Entire voice pipeline operates fully offline.",
      bullets: [
        "Whisper-based STT with multiple model sizes and multilingual support.",
        "Kokoro TTS with natural voices, pitch/rate control, and playback helpers.",
        "Voice Activity Detection for efficient speech-only processing.",
        "Neural dictation bar, voice notes, voice search, AI walkie-talkie, and read-aloud support.",
      ],
    },
    {
      title: "Notes & Documents",
      description: "Versatile writing and document workflows in one local workspace.",
      bullets: [
        "Rich markdown editor with formatting, blocks, links, and autosave.",
        "Floating text boxes and full-featured text editing with syntax highlighting.",
        "File organization with move, rename, delete, and bidirectional note linking.",
        "Supports .kvx, .md, .txt, and PDF-based workflows.",
      ],
    },
    {
      title: "Media Embedding",
      description: "Powerful media insertion and manipulation inside documents.",
      bullets: [
        "Embed local or web images/videos into markdown and text files.",
        "Interactive transforms: resize, rotate, move, drag, and aspect-ratio locking.",
        "Comment annotations on media and configurable web image caching modes.",
        "Large-image preview, lazy loading, LRU caching, thumbnails, and isolated repaints.",
      ],
    },
    {
      title: "Life Git (Version Control)",
      description: "Built-in note history with Git-inspired storage primitives.",
      bullets: [
        "Time-travel slider to restore previous note states.",
        "Automatic snapshots with typing debounce behavior.",
        "SHA-256 content-addressable storage and per-file histories.",
        "Preview historical versions before restore with zero setup.",
      ],
    },
    {
      title: "Scriptable Plugin System",
      description: "Lua automation with direct in-app APIs and plugin control.",
      bullets: [
        "Lua 5.3 scripting plus script runner for ad-hoc commands.",
        "Built-in App API for creating, reading, writing, searching, and moving notes.",
        "Plugin manager for enable/disable and on-demand execution.",
        "Example plugins include task archiving and daily summary automation.",
      ],
    },
    {
      title: "Project Manager",
      description: "Structured delivery view for projects and progress.",
      bullets: [
        "Project dashboard and categorized organization.",
        "Task tracking within dedicated project scopes.",
        "Visual completion indicators for progress monitoring.",
      ],
    },
    {
      title: "Calendar & Events",
      description: "Integrated scheduling for planning and reminders.",
      bullets: [
        "Day/week/month calendar views with date jumping.",
        "Event creation, editing, deletion, and color coding.",
        "Recurring event support and proactive reminders.",
      ],
    },
    {
      title: "Digital Canvas",
      description: "Professional sketching and diagramming environment.",
      bullets: [
        "Pen pressure, highlighter, laser pointer, shape tools, and eraser modes.",
        "Infinite canvas with smooth pan/zoom and transform controls.",
        "Layer support, custom backgrounds, grid, and snap-to-grid options.",
      ],
    },
    {
      title: "Productivity + Clock",
      description: "Focus systems, routines, and timer orchestration.",
      bullets: [
        "Pomodoro, 52/17, Ultradian, custom sessions, and progress indicators.",
        "Session tags, context analytics, daily goals, and completion tracking.",
        "Parallel secondary timers with built-in reminder presets.",
        "Chained routines, notifications, floating clock, and full clock page.",
      ],
    },
    {
      title: "Math Module",
      description: "High-performance Rust backend for advanced computations.",
      bullets: [
        "Scientific calculator, algebra tools, and equation solving.",
        "Calculus, partial/multiple integrals, limits, Taylor series, ODE solving.",
        "Statistics/probability with t-test, z-test, chi-squared, and ANOVA.",
        "Discrete math, graphing beta tools, unit conversion, and formula references.",
      ],
    },
    {
      title: "Quick Notes",
      description: "Ephemeral note-taking with auto-expiration controls.",
      bullets: [
        "Floating hub and browse widget integration with real-time sync.",
        "Configurable retention from 15 minutes to one week.",
        "Text and handwriting modes with easy switching.",
        "Quick bulk clear, single delete, and settings-level management.",
      ],
    },
    {
      title: "Customization + Security",
      description: "Personalized interface with strict local-first data guarantees.",
      bullets: [
        "Dynamic theming, dark/light modes, custom fonts, and flexible layout controls.",
        "Secure local storage with flutter_secure_storage for sensitive data.",
        "No cloud dependencies after setup and full export ownership.",
      ],
    },
    {
      title: "In-App Browser",
      description: "Integrated browsing with productivity and developer tooling.",
      bullets: [
        "WebView2/native webview with full navigation and secure URL indicators.",
        "Find-in-page, JavaScript console, dark mode injection, and keyboard shortcuts.",
        "Permission handling, dialog support, quick links, Android back behavior, floating browser window.",
      ],
    },
    {
      title: "PDF Integration",
      description: "Readable and editable document handoff for PDFs.",
      bullets: [
        "Import and annotate PDFs with retained markups.",
        "Export notes to PDF with high-quality rendering.",
        "Cross-device annotation continuity.",
      ],
    },
  ];

  const techStack = [
    "Flutter 3.41.6+",
    "Dart 3.11.4+",
    "Rust native engine",
    "llama.cpp inference",
    "flutter_rust_bridge",
    "Local vector database",
  ] as const;

  const platformSupport = [
    "Windows - Stable and fully optimized",
    "Android - Stable (API 24+)",
    "macOS - Supported on macOS",
    "Linux - Supported on Linux",
    "iOS - Supported on iOS",
    "Web - Experimental with limited features",
  ] as const;

  const modelCredits = [
    "Microsoft (Phi family)",
    "Alibaba Cloud Qwen Team (Qwen family)",
    "Google Gemma Team (Gemma family)",
    "DeepSeek-AI (DeepSeek-R1 family)",
    "Hugging Face TB SmolLM Team (SmolLM2)",
    "Community GGUF contributors including Jackrong, Unsloth, and bartowski",
  ] as const;

  return (
    <main className="relative min-h-screen overflow-hidden bg-[#070E1A] text-slate-100 selection:bg-teal-400/30">
      <motion.div
        aria-hidden="true"
        className="fixed left-0 top-0 z-[80] h-0.5 w-full origin-left bg-gradient-to-r from-indigo-400 via-teal-300 to-purple-400"
        style={{ scaleX: scrollProgress }}
      />

      <div className="pointer-events-none absolute inset-0 opacity-60 [background:radial-gradient(circle_at_20%_15%,rgba(99,102,241,0.2),transparent_40%),radial-gradient(circle_at_80%_10%,rgba(45,212,191,0.2),transparent_34%),radial-gradient(circle_at_55%_70%,rgba(168,85,247,0.16),transparent_35%)]" />
      <div className="pointer-events-none absolute inset-0 opacity-40 [background-image:linear-gradient(rgba(148,163,184,0.06)_1px,transparent_1px),linear-gradient(90deg,rgba(148,163,184,0.05)_1px,transparent_1px)] [background-size:46px_46px]" />

      <header className="fixed right-5 top-5 z-50">
        <a
          href="https://github.com/990aa/kivixa"
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Open Kivixa GitHub repository"
          className="inline-flex items-center gap-2 rounded-full border border-slate-700/80 bg-[#0d162a]/85 px-4 py-2 text-sm font-medium text-slate-200 shadow-[0_0_30px_rgba(15,23,42,0.8)] backdrop-blur transition-colors hover:border-teal-300/50 hover:text-white"
        >
          <GitHubMark className="h-4 w-4" />
          GitHub
        </a>
      </header>

      <section id="hero" data-testid="hero-section" className="relative z-10 flex min-h-screen items-center px-5 py-28">
        <motion.div
          initial="hidden"
          animate="visible"
          variants={fadeUpSection}
          className="mx-auto flex w-full max-w-5xl flex-col items-center text-center"
        >
          <motion.div
            animate={
              shouldReduceMotion
                ? undefined
                : {
                    y: [0, -10, 0],
                    rotate: [0, 0.8, 0],
                  }
            }
            transition={
              shouldReduceMotion
                ? undefined
                : { duration: 5.4, repeat: Number.POSITIVE_INFINITY, ease: "easeInOut" }
            }
            className="relative mb-10 h-32 w-32 rounded-[2rem] border border-white/15 bg-white/10 p-3 shadow-[0_0_55px_rgba(20,184,166,0.35)] backdrop-blur"
          >
            <Image
              src="/assets/icon.png"
              alt="Kivixa app icon"
              fill
              sizes="128px"
              priority
              className="rounded-[1.5rem] object-contain"
            />
          </motion.div>

          <p className="mb-3 text-xs uppercase tracking-[0.28em] text-teal-200/80 sm:text-sm">
            Cross-Platform Local-First Workspace
          </p>
          <h1 className="mb-6 bg-gradient-to-r from-white via-sky-100 to-teal-300 bg-clip-text text-6xl font-bold tracking-tight text-transparent sm:text-7xl md:text-8xl">
            Kivixa
          </h1>
          <p className="mb-5 max-w-4xl text-lg text-slate-200 sm:text-2xl">
            A privacy-first cross-platform productivity workspace for notes, sketching, planning,
            and local AI assistance.
          </p>
          <p className="mb-11 max-w-3xl text-base leading-relaxed text-slate-300 sm:text-lg">
            Built with Flutter 3.41.6 and Dart 3.11.4, accelerated by Rust and llama.cpp, and engineered so your data stays on your device.
          </p>

          <ul className="mb-10 flex w-full max-w-4xl flex-col gap-2 text-left text-sm text-slate-300 sm:grid sm:grid-cols-3 sm:text-center">
            {heroHighlights.map((point) => (
              <li key={point} className="rounded-xl border border-white/10 bg-white/5 px-4 py-3 backdrop-blur">
                {point}
              </li>
            ))}
          </ul>

          <div className="flex w-full flex-col justify-center gap-4 sm:w-auto sm:flex-row">
            <motion.a
              data-testid="cta-windows"
              whileHover={shouldReduceMotion ? undefined : { scale: 1.03, y: -2 }}
              whileTap={shouldReduceMotion ? undefined : { scale: 0.98 }}
              href="https://github.com/990aa/kivixa/releases/download/v0.3.9%2B3009/Kivixa-Setup-0.3.9.exe"
              target="_blank"
              rel="noopener noreferrer"
              className="group relative inline-flex items-center justify-center gap-2 rounded-full border border-purple-300/40 bg-gradient-to-r from-indigo-600 via-purple-600 to-teal-500 px-8 py-4 text-base font-semibold text-white shadow-[0_0_50px_rgba(99,102,241,0.38)] transition-all duration-300 hover:shadow-[0_0_70px_rgba(45,212,191,0.5)]"
            >
              <Download size={20} />
              <span>Download for Windows</span>
              <motion.span
                aria-hidden="true"
                className="absolute -z-10 h-12 w-12 rounded-full bg-purple-400/40 blur-2xl"
                whileHover={shouldReduceMotion ? undefined : { scale: 1.25 }}
                transition={{ duration: 0.24 }}
              />
            </motion.a>

            <motion.a
              data-testid="cta-uptodown"
              whileHover={shouldReduceMotion ? undefined : { scale: 1.02, y: -1 }}
              whileTap={shouldReduceMotion ? undefined : { scale: 0.98 }}
              href="https://kivixa.uptodown.com/android"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 rounded-full border border-teal-300/40 bg-[#081223]/80 px-8 py-4 text-base font-semibold text-slate-100 transition-all duration-300 hover:border-teal-300/75 hover:bg-[#10223a]"
            >
              <Smartphone size={20} />
              <span>Get it on Uptodown</span>
            </motion.a>
          </div>

          <div className="mt-10 flex flex-wrap justify-center gap-2 text-xs text-slate-300 sm:text-sm">
            {techStack.map((item) => (
              <span
                key={item}
                className="rounded-full border border-slate-600/70 bg-slate-900/70 px-3 py-1.5 tracking-wide transition-colors duration-300 hover:border-teal-300/45"
              >
                {item}
              </span>
            ))}
          </div>
        </motion.div>
      </section>

      <motion.section
        id="features"
        data-testid="features-section"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.15 }}
        variants={fadeUpSection}
        className="relative z-10 border-y border-white/10 bg-[#071023]/85 px-5 py-24"
      >
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-3xl font-semibold sm:text-4xl">Designed for Deep Work and Local Intelligence</h2>
          <p className="mx-auto mt-4 max-w-3xl text-center text-slate-300">
            Every major capability in the README is represented here as a structured product narrative, not raw blocks of text.
          </p>

          <motion.div
            variants={staggerContainer}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.2 }}
            className="mt-14 grid grid-cols-1 gap-6 md:grid-cols-3"
          >
            {topFeatureCards.map((card, index) => {
              const Icon = featureIcons[index % featureIcons.length];
              return (
                <motion.article
                  key={card.title}
                  variants={revealCard}
                  whileHover={shouldReduceMotion ? undefined : { y: -6, scale: 1.012 }}
                  className="group rounded-3xl border border-slate-700/80 bg-slate-900/55 p-7 shadow-[0_24px_65px_rgba(2,6,23,0.6)] backdrop-blur transition-all duration-300 hover:border-teal-300/45 hover:shadow-[0_26px_75px_rgba(45,212,191,0.15)]"
                >
                  <div className="mb-5 inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-teal-300/30 bg-gradient-to-br from-teal-500/25 to-indigo-500/20 text-teal-200">
                    <Icon size={23} />
                  </div>
                  <h3 className="mb-3 text-xl font-semibold text-white">{card.title}</h3>
                  <p className="leading-relaxed text-slate-300">{card.description}</p>
                </motion.article>
              );
            })}
          </motion.div>
        </div>
      </motion.section>

      <motion.section
        id="showcase"
        data-testid="showcase-section"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.08 }}
        variants={fadeUpSection}
        className="relative z-10 px-5 py-24"
      >
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-[1.05fr_1fr] lg:items-start">
          <div className="space-y-6">
            <h2 className="text-3xl font-semibold sm:text-4xl">Vertical Product Gallery</h2>
            <p className="text-slate-300">
              Every screenshot in public/assets/screenshots is included below with proper titles, compact framed presentation, and a vertical sliding window for a premium showcase.
            </p>
            <div className="grid grid-cols-1 gap-4 text-sm text-slate-300 sm:grid-cols-2">
              {screenshots.map((shot) => (
                <article key={`meta-${shot.src}`} className="rounded-xl border border-white/10 bg-white/5 px-4 py-3">
                  <p className="font-semibold text-white">{shot.title}</p>
                  <p className="mt-1 text-xs text-slate-300">{shot.caption}</p>
                </article>
              ))}
            </div>
          </div>

          <div className="relative">
            <div className="hidden h-[620px] overflow-hidden rounded-[2rem] border border-teal-300/30 bg-[#081120]/80 p-4 shadow-[0_30px_90px_rgba(8,14,26,0.85)] lg:block">
              <motion.div
                animate={shouldReduceMotion ? undefined : { y: ["0%", "-50%"] }}
                transition={
                  shouldReduceMotion
                    ? undefined
                    : { duration: 48, repeat: Number.POSITIVE_INFINITY, ease: "linear" }
                }
                className="flex flex-col gap-4"
              >
                {[...screenshots, ...screenshots].map((shot, index) => (
                  <figure
                    key={`${shot.src}-${index}`}
                    className="overflow-hidden rounded-2xl border border-slate-600/60 bg-slate-900/80 transition-all duration-300 hover:-translate-y-0.5 hover:border-teal-300/45"
                  >
                    <div className="relative h-44 w-full">
                      <Image
                        src={shot.src}
                        alt={shot.title}
                        fill
                        sizes="(max-width: 1200px) 40vw, 32vw"
                        className="object-cover"
                      />
                    </div>
                    <figcaption className="border-t border-slate-700/80 px-3 py-2 text-xs text-slate-200">
                      {shot.title}
                    </figcaption>
                  </figure>
                ))}
              </motion.div>
            </div>

            <div className="grid grid-cols-1 gap-4 lg:hidden">
              {screenshots.map((shot) => (
                <figure
                  key={`mobile-${shot.src}`}
                  className="overflow-hidden rounded-2xl border border-slate-700 bg-slate-900/80"
                >
                  <div className="relative h-44 w-full">
                    <Image src={shot.src} alt={shot.title} fill sizes="100vw" className="object-cover" />
                  </div>
                  <figcaption className="px-3 py-2 text-xs text-slate-200">{shot.title}</figcaption>
                </figure>
              ))}
            </div>
          </div>
        </div>
      </motion.section>

      <section className="relative z-10 border-y border-white/10 bg-[#081121]/85 px-5 py-24">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-3xl font-semibold sm:text-4xl">Feature Atlas from README</h2>
          <p className="mx-auto mt-4 max-w-3xl text-center text-slate-300">
            Full coverage of every detailed capability category, presented in structured cards with visual anchors.
          </p>

          <motion.div
            variants={staggerContainer}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, amount: 0.16 }}
            className="mt-12 grid grid-cols-1 gap-6 md:grid-cols-2"
          >
            {featureAtlas.map((group, index) => {
              const Icon = featureIcons[index % featureIcons.length];
              const referenceShot = screenshots[index % screenshots.length];
              return (
                <motion.article
                  key={group.title}
                  variants={revealCard}
                  whileHover={shouldReduceMotion ? undefined : { y: -4 }}
                  className="overflow-hidden rounded-3xl border border-slate-700/70 bg-slate-900/65 shadow-[0_22px_55px_rgba(2,6,23,0.65)] transition-all duration-300 hover:border-teal-300/40 hover:shadow-[0_26px_70px_rgba(56,189,248,0.12)]"
                >
                  <div className="grid gap-0 sm:grid-cols-[190px_1fr]">
                    <div className="relative h-44 sm:h-52">
                      <Image
                        src={referenceShot.src}
                        alt={`${group.title} preview`}
                        fill
                        sizes="(max-width: 640px) 100vw, 220px"
                        className="object-cover"
                      />
                    </div>
                    <div className="p-6">
                      <div className="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-xl border border-teal-300/30 bg-teal-500/10 text-teal-200">
                        <Icon size={20} />
                      </div>
                      <h3 className="text-2xl font-semibold text-white">{group.title}</h3>
                      <p className="mt-2 text-sm text-slate-300">{group.description}</p>
                      <ul className="mt-4 space-y-2 text-sm text-slate-300">
                        {group.bullets.map((bullet) => (
                          <li key={bullet} className="rounded-lg border border-white/10 bg-white/[0.03] px-3 py-2">
                            {bullet}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </motion.article>
              );
            })}
          </motion.div>
        </div>
      </section>

      <section className="relative z-10 px-5 py-24">
        <div className="mx-auto grid max-w-6xl gap-8 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-3xl border border-slate-700/80 bg-slate-900/70 p-7">
            <h2 className="text-3xl font-semibold">Android via F-Droid Repository</h2>
            <p className="mt-4 text-slate-300">
              Add the official Kivixa F-Droid repository exactly as documented in the README.
            </p>
            <a
              href="https://990aa.github.io/kivixa/repo/"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-5 inline-flex rounded-full border border-amber-300/40 bg-amber-400/10 px-4 py-2 text-sm font-medium text-amber-200 hover:bg-amber-300/20"
            >
              Open F-Droid Repo Link
            </a>

            <ol className="mt-6 space-y-3 text-slate-200">
              <li className="rounded-xl border border-slate-700 bg-[#0c1426] px-4 py-3">
                1. Open the F-Droid app on Android and go to repository add/import options.
              </li>
              <li className="rounded-xl border border-slate-700 bg-[#0c1426] px-4 py-3">
                2. Scan the QR code for https://990aa.github.io/kivixa/repo.
              </li>
              <li className="rounded-xl border border-slate-700 bg-[#0c1426] px-4 py-3">
                3. Confirm adding the repo, refresh indexes, then install Kivixa packages.
              </li>
              <li className="rounded-xl border border-slate-700 bg-[#0c1426] px-4 py-3">
                4. This follows the README flow where scanning auto-adds the repository.
              </li>
            </ol>
          </div>

          <div className="rounded-3xl border border-teal-300/30 bg-[#0a1428]/85 p-7 text-center shadow-[0_20px_60px_rgba(5,150,105,0.18)]">
            <h3 className="text-xl font-semibold">F-Droid Repo QR</h3>
            <p className="mt-2 text-sm text-slate-300">Scan this code with F-Droid to auto-add the Kivixa repo.</p>
            <div className="mx-auto mt-6 w-fit rounded-2xl border border-slate-700 bg-white p-3">
              <img
                src="https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=https://990aa.github.io/kivixa/repo"
                alt="F-Droid Repo QR Code for Kivixa"
                width="260"
                height="260"
                loading="lazy"
              />
            </div>
          </div>
        </div>
      </section>

      <section className="relative z-10 border-y border-white/10 bg-[#071024]/85 px-5 py-24">
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-3xl font-semibold sm:text-4xl">Getting Started and Build Matrix</h2>

          <div className="mt-10 grid gap-6 lg:grid-cols-3">
            <article className="rounded-2xl border border-slate-700 bg-slate-900/70 p-6">
              <h3 className="text-lg font-semibold">Prerequisites</h3>
              <ul className="mt-4 space-y-2 text-sm text-slate-300">
                <li>Flutter 3.41.6 or higher</li>
                <li>Dart 3.11.4 or higher</li>
                <li>Rust toolchain for native code and math module</li>
                <li>Platform toolchains: Visual Studio, Xcode, Android SDK/NDK, or Linux build tools</li>
              </ul>
            </article>

            <article className="rounded-2xl border border-slate-700 bg-slate-900/70 p-6">
              <h3 className="text-lg font-semibold">Install + Run</h3>
              <ul className="mt-4 space-y-2 text-sm text-slate-300">
                <li>git clone https://github.com/990aa/kivixa.git</li>
                <li>flutter pub get</li>
                <li>flutter run -d windows / android / macos / linux / ios</li>
                <li>Production builds for apk, appbundle, windows, macos, linux, and ios</li>
              </ul>
            </article>

            <article className="rounded-2xl border border-slate-700 bg-slate-900/70 p-6">
              <h3 className="text-lg font-semibold">Windows Installer</h3>
              <ul className="mt-4 space-y-2 text-sm text-slate-300">
                <li>Inno Setup script: windows/installer/kivixa-installer.iss</li>
                <li>Build command: iscc windows/installer/kivixa-installer.iss</li>
                <li>Custom uninstaller can optionally wipe Documents/Kivixa data</li>
              </ul>
            </article>
          </div>

          <div className="mt-8 grid gap-6 lg:grid-cols-2">
            <article className="rounded-2xl border border-slate-700 bg-slate-900/70 p-6">
              <h3 className="text-lg font-semibold">Platform Support</h3>
              <ul className="mt-4 grid gap-2 text-sm text-slate-300 sm:grid-cols-2">
                {platformSupport.map((platform) => (
                  <li key={platform} className="rounded-lg border border-white/10 bg-white/[0.03] px-3 py-2">
                    {platform}
                  </li>
                ))}
              </ul>
            </article>

            <article className="rounded-2xl border border-slate-700 bg-slate-900/70 p-6">
              <h3 className="text-lg font-semibold">AI Model Credits</h3>
              <ul className="mt-4 space-y-2 text-sm text-slate-300">
                {modelCredits.map((credit) => (
                  <li key={credit} className="rounded-lg border border-white/10 bg-white/[0.03] px-3 py-2">
                    {credit}
                  </li>
                ))}
              </ul>
            </article>
          </div>
        </div>
      </section>

      <motion.footer
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
        className="relative z-10 border-t border-white/10 px-5 py-10"
      >
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 text-slate-400 sm:flex-row">
          <p className="text-sm">
            © {new Date().getFullYear()} Kivixa. Privacy-first workspace with local AI at the core.
          </p>
          <a
            href="https://github.com/990aa/kivixa"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Kivixa GitHub repository"
            className="inline-flex items-center gap-2 text-sm transition-colors hover:text-white"
          >
            <GitHubMark className="h-[18px] w-[18px]" />
            <span>GitHub</span>
          </a>
        </div>
      </motion.footer>
    </main>
  );
}
