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
    stiffness: 110,
    damping: 30,
    mass: 0.28,
  });

  const sectionReveal: Variants = {
    hidden: {
      opacity: 0,
      y: 36,
      filter: shouldReduceMotion ? "blur(0px)" : "blur(8px)",
    },
    visible: {
      opacity: 1,
      y: 0,
      filter: "blur(0px)",
      transition: {
        duration: shouldReduceMotion ? 0.01 : 0.82,
        ease: [0.18, 1, 0.3, 1],
      },
    },
  };

  const staggerContainer: Variants = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: shouldReduceMotion ? 0 : 0.1,
        delayChildren: shouldReduceMotion ? 0 : 0.08,
      },
    },
  };

  const revealCard: Variants = {
    hidden: { opacity: 0, y: 24, scale: 0.985 },
    visible: {
      opacity: 1,
      y: 0,
      scale: 1,
      transition: {
        duration: shouldReduceMotion ? 0.01 : 0.62,
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

  const fdroidSteps = [
    "Open the F-Droid app on Android and go to repository add/import options.",
    "Scan the QR code for https://990aa.github.io/kivixa/repo.",
    "Confirm adding the repo, refresh indexes, then install Kivixa packages.",
    "This follows the README flow where scanning auto-adds the repository.",
  ] as const;

  return (
    <main className="relative min-h-screen overflow-hidden bg-[#07111d] text-slate-100 selection:bg-cyan-300/30">
      <motion.div
        aria-hidden="true"
        className="fixed left-0 top-0 z-[80] h-0.5 w-full origin-left bg-gradient-to-r from-sky-300 via-cyan-300 to-amber-200"
        style={{ scaleX: scrollProgress }}
      />

      <div className="pointer-events-none absolute inset-0 opacity-75 [background:radial-gradient(circle_at_15%_16%,rgba(82,212,197,0.19),transparent_36%),radial-gradient(circle_at_88%_12%,rgba(120,190,255,0.16),transparent_33%),radial-gradient(circle_at_50%_80%,rgba(244,196,141,0.1),transparent_36%)]" />
      <div className="pointer-events-none absolute inset-0 opacity-35 [background-image:linear-gradient(rgba(148,163,184,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(148,163,184,0.04)_1px,transparent_1px)] [background-size:58px_58px]" />
      <div className="pointer-events-none absolute inset-0 opacity-25 [background:conic-gradient(from_110deg_at_70%_30%,rgba(14,165,233,0.18),transparent_35%,rgba(251,191,36,0.12),transparent_60%)]" />

      <header className="fixed right-5 top-5 z-50">
        <a
          href="https://github.com/990aa/kivixa"
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Open Kivixa GitHub repository"
          className="glass-panel-soft inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium text-slate-100 hover:text-white"
        >
          <GitHubMark className="h-4 w-4" />
          GitHub
        </a>
      </header>

      <section
        id="hero"
        data-testid="hero-section"
        className="relative z-10 flex min-h-screen items-center px-5 py-28"
      >
        <motion.div
          initial="hidden"
          animate="visible"
          variants={sectionReveal}
          className="mx-auto flex w-full max-w-5xl flex-col items-center text-center"
        >
          <motion.div
            animate={
              shouldReduceMotion
                ? undefined
                : {
                    y: [0, -9, 0],
                    rotate: [0, 0.7, 0],
                    scale: [1, 1.02, 1],
                  }
            }
            transition={
              shouldReduceMotion
                ? undefined
                : { duration: 6.6, repeat: Number.POSITIVE_INFINITY, ease: "easeInOut" }
            }
            className="glass-panel relative mb-10 h-32 w-32 rounded-[2rem] p-3"
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

          <p className="kicker mb-4 sm:text-sm">
            Cross-Platform Local-First Workspace
          </p>
          <h1 className="display-title mb-7 bg-gradient-to-r from-white via-slate-100 to-cyan-200 bg-clip-text text-6xl font-bold text-transparent sm:text-7xl md:text-8xl">
            Kivixa
          </h1>
          <p className="lead-copy mb-5 max-w-4xl text-lg text-slate-100 sm:text-2xl">
            A privacy-first cross-platform productivity workspace for notes, sketching, planning,
            and local AI assistance.
          </p>
          <p className="caption-tight mb-11 max-w-3xl text-base sm:text-lg">
            Built with Flutter 3.41.6 and Dart 3.11.4, accelerated by Rust and llama.cpp, and engineered so your data stays on your device.
          </p>

          <ul className="mb-11 flex w-full max-w-4xl flex-col gap-2 text-left text-sm sm:grid sm:grid-cols-3 sm:text-center">
            {heroHighlights.map((point) => (
              <li key={point} className="float-chip px-4 py-3">
                {point}
              </li>
            ))}
          </ul>

          <div className="flex w-full flex-col justify-center gap-4 sm:w-auto sm:flex-row">
            <motion.a
              data-testid="cta-windows"
              whileHover={shouldReduceMotion ? undefined : { scale: 1.02, y: -3 }}
              whileTap={shouldReduceMotion ? undefined : { scale: 0.98 }}
              href="https://github.com/990aa/kivixa/releases/download/v0.3.9%2B3009/Kivixa-Setup-0.3.9.exe"
              target="_blank"
              rel="noopener noreferrer"
              className="group relative inline-flex items-center justify-center gap-2 overflow-hidden rounded-full border border-cyan-200/45 bg-gradient-to-r from-cyan-500 via-sky-500 to-blue-500 px-8 py-4 text-base font-semibold text-white shadow-[0_16px_50px_rgba(2,132,199,0.45)]"
            >
              <Download size={20} />
              <span>Download for Windows</span>
              <motion.span
                aria-hidden="true"
                className="absolute inset-y-0 left-[-30%] w-1/3 -skew-x-12 bg-white/30 blur-md"
                animate={
                  shouldReduceMotion
                    ? undefined
                    : {
                        x: ["0%", "240%"],
                      }
                }
                transition={
                  shouldReduceMotion
                    ? undefined
                    : {
                        duration: 2.9,
                        repeat: Number.POSITIVE_INFINITY,
                        repeatDelay: 1.2,
                        ease: "easeInOut",
                      }
                }
              />
            </motion.a>

            <motion.a
              data-testid="cta-uptodown"
              whileHover={shouldReduceMotion ? undefined : { scale: 1.015, y: -2 }}
              whileTap={shouldReduceMotion ? undefined : { scale: 0.98 }}
              href="https://kivixa.uptodown.com/android"
              target="_blank"
              rel="noopener noreferrer"
              className="glass-panel-soft inline-flex items-center justify-center gap-2 rounded-full px-8 py-4 text-base font-semibold text-slate-100"
            >
              <Smartphone size={20} />
              <span>Get it on Uptodown</span>
            </motion.a>
          </div>

          <div className="mt-11 flex flex-wrap justify-center gap-2 text-xs sm:text-sm">
            {techStack.map((item) => (
              <span
                key={item}
                className="float-chip px-3 py-1.5 font-medium tracking-wide"
              >
                {item}
              </span>
            ))}
          </div>
        </motion.div>

        <div className="section-fade-divider absolute bottom-0 left-0" />
      </section>

      <motion.section
        id="features"
        data-testid="features-section"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.15 }}
        variants={sectionReveal}
        className="relative z-10 px-5 py-24"
      >
        <div className="mx-auto max-w-6xl">
          <p className="kicker mx-auto w-fit">Capability Layers</p>
          <h2 className="section-title mx-auto mt-4 max-w-3xl text-center text-3xl font-semibold text-white sm:text-4xl">
            Designed for Deep Work and Local Intelligence
          </h2>
          <p className="caption-tight mx-auto mt-4 max-w-3xl text-center">
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
              const staggerDepth = index % 3 === 1 ? "md:-translate-y-3" : index % 3 === 2 ? "md:translate-y-2" : "";
              return (
                <motion.article
                  key={card.title}
                  variants={revealCard}
                  whileHover={shouldReduceMotion ? undefined : { y: -8, scale: 1.01 }}
                  className={`glass-panel group rounded-[1.7rem] p-7 ${staggerDepth}`}
                >
                  <div className="mb-5 inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-cyan-200/45 bg-gradient-to-br from-cyan-500/18 to-sky-400/14 text-cyan-100">
                    <Icon size={23} />
                  </div>
                  <h3 className="section-title mb-3 text-xl font-semibold text-white">{card.title}</h3>
                  <p className="caption-tight leading-relaxed">{card.description}</p>
                </motion.article>
              );
            })}
          </motion.div>

          <div className="section-fade-divider mt-20" />
        </div>
      </motion.section>

      <motion.section
        id="showcase"
        data-testid="showcase-section"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.08 }}
        variants={sectionReveal}
        className="relative z-10 px-5 py-24"
      >
        <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-[1.05fr_1fr] lg:items-start">
          <div className="space-y-6">
            <p className="kicker">Visual Walkthrough</p>
            <h2 className="section-title text-3xl font-semibold text-white sm:text-4xl">Vertical Product Gallery</h2>
            <p className="caption-tight">
              Every screenshot in public/assets/screenshots is included below with proper titles, compact framed presentation, and a vertical sliding window for a premium showcase.
            </p>

            <div className="grid grid-cols-1 gap-4 text-sm sm:grid-cols-2">
              {screenshots.map((shot) => (
                <article key={`meta-${shot.src}`} className="feature-line py-1">
                  <p className="font-semibold text-slate-100">{shot.title}</p>
                  <p className="caption-tight mt-1 text-xs">{shot.caption}</p>
                </article>
              ))}
            </div>
          </div>

          <div className="relative">
            <div className="glass-panel hidden h-[620px] overflow-hidden rounded-[2rem] p-4 lg:block">
              <motion.div
                animate={shouldReduceMotion ? undefined : { y: ["0%", "-50%"] }}
                transition={
                  shouldReduceMotion
                    ? undefined
                    : { duration: 44, repeat: Number.POSITIVE_INFINITY, ease: "linear" }
                }
                className="flex flex-col gap-4"
              >
                {[...screenshots, ...screenshots].map((shot, index) => (
                  <figure
                    key={`${shot.src}-${index}`}
                    className="glass-panel-soft overflow-hidden rounded-2xl"
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
                    <figcaption className="border-t border-cyan-200/15 px-3 py-2 text-xs text-slate-200">
                      {shot.title}
                    </figcaption>
                  </figure>
                ))}
              </motion.div>
            </div>

            <div className="grid grid-cols-1 gap-4 lg:hidden">
              {screenshots.map((shot) => (
                <figure key={`mobile-${shot.src}`} className="glass-panel-soft overflow-hidden rounded-2xl">
                  <div className="relative h-44 w-full">
                    <Image src={shot.src} alt={shot.title} fill sizes="100vw" className="object-cover" />
                  </div>
                  <figcaption className="px-3 py-2 text-xs text-slate-200">{shot.title}</figcaption>
                </figure>
              ))}
            </div>
          </div>
        </div>

        <div className="section-fade-divider mx-auto mt-20 max-w-6xl" />
      </motion.section>

      <section className="relative z-10 px-5 py-24">
        <div className="mx-auto max-w-6xl">
          <p className="kicker mx-auto w-fit">Complete Coverage</p>
          <h2 className="section-title mx-auto mt-4 max-w-3xl text-center text-3xl font-semibold text-white sm:text-4xl">
            Feature Atlas from README
          </h2>
          <p className="caption-tight mx-auto mt-4 max-w-3xl text-center">
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
                  whileHover={shouldReduceMotion ? undefined : { y: -6 }}
                  className="glass-panel overflow-hidden rounded-[1.75rem]"
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
                      <div className="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-xl border border-cyan-200/45 bg-cyan-500/10 text-cyan-100">
                        <Icon size={20} />
                      </div>
                      <h3 className="section-title text-2xl font-semibold text-white">{group.title}</h3>
                      <p className="caption-tight mt-2 text-sm">{group.description}</p>
                      <ul className="bullet-flow mt-4 space-y-2 text-sm">
                        {group.bullets.map((bullet) => (
                          <li key={bullet}>
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

          <div className="section-fade-divider mt-20" />
        </div>
      </section>

      <section className="relative z-10 px-5 py-24">
        <div className="mx-auto grid max-w-6xl gap-8 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="glass-panel rounded-[1.8rem] p-7">
            <p className="kicker">Android Distribution</p>
            <h2 className="section-title mt-4 text-3xl font-semibold text-white">Android via F-Droid Repository</h2>
            <p className="caption-tight mt-4">
              Add the official Kivixa F-Droid repository exactly as documented in the README.
            </p>
            <a
              href="https://990aa.github.io/kivixa/repo/"
              target="_blank"
              rel="noopener noreferrer"
              className="mt-5 inline-flex rounded-full border border-amber-200/45 bg-amber-300/12 px-4 py-2 text-sm font-medium text-amber-100 hover:bg-amber-300/20"
            >
              Open F-Droid Repo Link
            </a>

            <ol className="mt-6 space-y-4">
              {fdroidSteps.map((step, index) => (
                <li key={step} className="glass-panel-soft relative rounded-2xl px-4 py-3 pl-11 text-slate-200">
                  <span className="absolute left-3 top-3 inline-flex h-6 w-6 items-center justify-center rounded-full bg-cyan-300/20 text-xs font-semibold text-cyan-100">
                    {index + 1}
                  </span>
                  {step}
                </li>
              ))}
            </ol>
          </div>

          <div className="glass-panel rounded-[1.8rem] p-7 text-center">
            <h3 className="section-title text-xl font-semibold text-white">F-Droid Repo QR</h3>
            <p className="caption-tight mt-2 text-sm">Scan this code with F-Droid to auto-add the Kivixa repo.</p>
            <div className="mx-auto mt-6 w-fit rounded-2xl border border-cyan-300/25 bg-white p-3">
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

        <div className="section-fade-divider mx-auto mt-20 max-w-6xl" />
      </section>

      <section className="relative z-10 px-5 py-24">
        <div className="mx-auto max-w-6xl">
          <p className="kicker mx-auto w-fit">Build + Platform Matrix</p>
          <h2 className="section-title mx-auto mt-4 max-w-3xl text-center text-3xl font-semibold text-white sm:text-4xl">
            Getting Started and Build Matrix
          </h2>

          <div className="mt-10 grid gap-6 lg:grid-cols-3">
            <article className="glass-panel-soft rounded-2xl p-6">
              <h3 className="section-title text-lg font-semibold text-slate-100">Prerequisites</h3>
              <ul className="bullet-flow mt-4 space-y-2 text-sm">
                <li>Flutter 3.41.6 or higher</li>
                <li>Dart 3.11.4 or higher</li>
                <li>Rust toolchain for native code and math module</li>
                <li>Platform toolchains: Visual Studio, Xcode, Android SDK/NDK, or Linux build tools</li>
              </ul>
            </article>

            <article className="glass-panel-soft rounded-2xl p-6">
              <h3 className="section-title text-lg font-semibold text-slate-100">Install + Run</h3>
              <ul className="bullet-flow mt-4 space-y-2 text-sm">
                <li>git clone https://github.com/990aa/kivixa.git</li>
                <li>flutter pub get</li>
                <li>flutter run -d windows / android / macos / linux / ios</li>
                <li>Production builds for apk, appbundle, windows, macos, linux, and ios</li>
              </ul>
            </article>

            <article className="glass-panel-soft rounded-2xl p-6">
              <h3 className="section-title text-lg font-semibold text-slate-100">Windows Installer</h3>
              <ul className="bullet-flow mt-4 space-y-2 text-sm">
                <li>Inno Setup script: windows/installer/kivixa-installer.iss</li>
                <li>Build command: iscc windows/installer/kivixa-installer.iss</li>
                <li>Custom uninstaller can optionally wipe Documents/Kivixa data</li>
              </ul>
            </article>
          </div>

          <div className="mt-8 grid gap-6 lg:grid-cols-2">
            <article className="glass-panel-soft rounded-2xl p-6">
              <h3 className="section-title text-lg font-semibold text-slate-100">Platform Support</h3>
              <ul className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                {platformSupport.map((platform) => (
                  <li key={platform} className="feature-line py-1.5">
                    {platform}
                  </li>
                ))}
              </ul>
            </article>

            <article className="glass-panel-soft rounded-2xl p-6">
              <h3 className="section-title text-lg font-semibold text-slate-100">AI Model Credits</h3>
              <ul className="bullet-flow mt-4 space-y-2 text-sm">
                {modelCredits.map((credit) => (
                  <li key={credit}>
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
        transition={{ duration: shouldReduceMotion ? 0.01 : 0.62, ease: [0.18, 1, 0.3, 1] }}
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
