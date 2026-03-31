"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import {
  BookText,
  Bot,
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

export default function Home() {
  const fadeUpSection = {
    hidden: { opacity: 0, y: 30 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.75, ease: "easeOut" } },
  };

  const featureCards = [
    {
      title: "On-Device AI + MCP",
      description:
        "Run multi-model local AI with Model Context Protocol for tool-capable assistance, with all executions requiring user confirmation.",
      icon: Bot,
      accent: "purple",
    },
    {
      title: "Privacy-First by Design",
      description:
        "Runs 100% on-device with no cloud dependency after model download, no API keys, and no subscriptions.",
      icon: ShieldCheck,
      accent: "teal",
    },
    {
      title: "Rich Markdown Workspace",
      description:
        "Create formatted documents with autosave, note linking, and support for .kvx, .md, .txt, and PDF files.",
      icon: BookText,
      accent: "indigo",
    },
    {
      title: "Knowledge Graph",
      description:
        "Build interactive mind maps with custom node types, draggable layouts, labeled links, and persistent local storage.",
      icon: Network,
      accent: "purple",
    },
    {
      title: "Rust-Powered Math Module",
      description:
        "A high-performance Rust backend powers calculus, statistics, algebra, and graphing for fast, accurate computation.",
      icon: Sigma,
      accent: "teal",
    },
    {
      title: "Cross-Platform Core",
      description:
        "Built with Flutter, Dart, Rust, and llama.cpp to deliver a consistent experience across desktop and mobile.",
      icon: Workflow,
      accent: "indigo",
    },
  ] as const;

  const accentClasses = {
    purple: "from-purple-500/25 to-purple-500/5 text-purple-300 border-purple-500/30",
    teal: "from-teal-500/25 to-teal-500/5 text-teal-300 border-teal-500/30",
    indigo: "from-indigo-500/25 to-indigo-500/5 text-indigo-300 border-indigo-500/30",
  } as const;

  const screenshots = [
    {
      src: "/assets/screenshots/workspace-overview.png",
      alt: "Kivixa workspace overview",
      size: "md:col-span-2",
    },
    {
      src: "/assets/screenshots/ai-chat.png",
      alt: "Kivixa local AI assistant panel",
      size: "md:col-span-1",
    },
    {
      src: "/assets/screenshots/knowledge-graph.png",
      alt: "Kivixa knowledge graph feature",
      size: "md:col-span-1",
    },
    {
      src: "/assets/screenshots/math-module.png",
      alt: "Kivixa Rust-powered math module",
      size: "md:col-span-1",
    },
    {
      src: "/assets/screenshots/quick-notes.png",
      alt: "Kivixa quick notes interface",
      size: "md:col-span-1",
    },
    {
      src: "/assets/screenshots/productivity-clock.png",
      alt: "Kivixa productivity clock dashboard",
      size: "md:col-span-2",
    },
  ] as const;

  return (
    <main className="relative min-h-screen overflow-hidden bg-[#0B1120] text-slate-100 selection:bg-purple-500/30">
      <div className="pointer-events-none absolute -left-24 top-20 h-72 w-72 rounded-full bg-purple-600/20 blur-[130px]" />
      <div className="pointer-events-none absolute -right-20 top-1/3 h-80 w-80 rounded-full bg-teal-500/15 blur-[140px]" />
      <div className="pointer-events-none absolute bottom-0 left-1/3 h-64 w-64 rounded-full bg-purple-500/10 blur-[130px]" />

      <section
        id="hero"
        data-testid="hero-section"
        className="relative flex min-h-screen items-center px-5 py-24"
      >
        <motion.div
          initial="hidden"
          animate="visible"
          variants={fadeUpSection}
          className="relative z-10 mx-auto flex w-full max-w-4xl flex-col items-center text-center"
        >
          <motion.div
            animate={{ y: [0, -10, 0] }}
            transition={{ duration: 5, repeat: Number.POSITIVE_INFINITY, ease: "easeInOut" }}
            className="relative mb-9 h-28 w-28 rounded-[2rem] border border-white/10 bg-white/5 p-3 shadow-[0_0_40px_rgba(147,51,234,0.45)] backdrop-blur"
          >
            <Image
              src="/assets/icon.png"
              alt="Kivixa app icon"
              fill
              priority
              className="rounded-[1.5rem] object-contain"
            />
          </motion.div>

          <p className="mb-3 text-sm uppercase tracking-[0.26em] text-slate-400">
            Privacy-First Cross-Platform Workspace
          </p>
          <h1 className="mb-6 bg-gradient-to-r from-white via-slate-100 to-teal-300 bg-clip-text text-6xl font-bold tracking-tight text-transparent sm:text-7xl md:text-8xl">
            Kivixa
          </h1>
          <p className="mb-4 max-w-3xl text-lg text-slate-300 sm:text-xl">
            A privacy-first cross-platform productivity workspace for notes, sketching,
            planning, and local AI assistance.
          </p>
          <p className="mb-12 max-w-2xl text-base leading-relaxed text-slate-400 sm:text-lg">
            Built with Flutter + Rust, powered by local AI, and designed to keep your ideas
            on your device, not in the cloud.
          </p>

          <div className="flex w-full flex-col justify-center gap-4 sm:w-auto sm:flex-row">
            <motion.a
              data-testid="cta-windows"
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.98 }}
              href="https://github.com/990aa/kivixa/releases/download/v0.3.9%2B3009/Kivixa-Setup-0.3.9.exe"
              target="_blank"
              rel="noreferrer"
              className="group relative inline-flex items-center justify-center gap-2 rounded-full border border-purple-400/40 bg-gradient-to-r from-purple-600 to-teal-500 px-8 py-4 text-base font-semibold text-white shadow-[0_0_35px_rgba(139,92,246,0.45)] transition-all hover:shadow-[0_0_55px_rgba(45,212,191,0.5)]"
            >
              <Download size={20} />
              <span>Download for Windows</span>
              <motion.span
                aria-hidden="true"
                className="absolute -z-10 h-12 w-12 rounded-full bg-purple-400/40 blur-2xl"
                whileHover={{ scale: 1.25 }}
                transition={{ duration: 0.2 }}
              />
            </motion.a>

            <motion.a
              data-testid="cta-uptodown"
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.98 }}
              href="https://kivixa.uptodown.com/android"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center justify-center gap-2 rounded-full border border-teal-400/30 bg-slate-900/70 px-8 py-4 text-base font-semibold text-slate-100 transition-all hover:border-teal-400/60 hover:bg-slate-800"
            >
              <Smartphone size={20} />
              <span>Get it on Uptodown</span>
            </motion.a>
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
        className="relative z-10 border-y border-white/5 bg-[#0A1223]/80 px-5 py-24"
      >
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-3xl font-semibold sm:text-4xl">Why People Choose Kivixa</h2>
          <p className="mx-auto mt-4 max-w-3xl text-center text-slate-400">
            Everything from note creation to AI reasoning works locally, with a stack tuned for
            speed, reliability, and complete user control.
          </p>

          <div className="mt-14 grid grid-cols-1 gap-6 md:grid-cols-3">
            {featureCards.map((card, index) => {
              const Icon = card.icon;
              return (
                <motion.article
                  key={card.title}
                  initial={{ opacity: 0, y: 24 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, amount: 0.3 }}
                  transition={{ delay: index * 0.07, duration: 0.55 }}
                  className="group rounded-3xl border border-slate-800 bg-slate-900/55 p-7 shadow-[0_20px_50px_rgba(0,0,0,0.25)] backdrop-blur transition-all hover:-translate-y-1 hover:border-purple-500/40"
                >
                  <div
                    className={`mb-5 inline-flex h-12 w-12 items-center justify-center rounded-2xl border bg-gradient-to-br ${accentClasses[card.accent]}`}
                  >
                    <motion.div
                      animate={{ y: [0, -3, 0] }}
                      transition={{ duration: 3 + index, repeat: Number.POSITIVE_INFINITY }}
                    >
                      <Icon size={23} />
                    </motion.div>
                  </div>
                  <h3 className="mb-3 text-xl font-semibold text-white">{card.title}</h3>
                  <p className="leading-relaxed text-slate-400">{card.description}</p>
                </motion.article>
              );
            })}
          </div>
        </div>
      </motion.section>

      <motion.section
        id="showcase"
        data-testid="showcase-section"
        initial="hidden"
        whileInView="visible"
        viewport={{ once: true, amount: 0.1 }}
        variants={fadeUpSection}
        className="relative z-10 px-5 py-24"
      >
        <div className="mx-auto max-w-6xl">
          <h2 className="text-center text-3xl font-semibold sm:text-4xl">
            A Workspace That Blends Notes, AI, and Flow
          </h2>
          <p className="mx-auto mt-4 max-w-3xl text-center text-slate-400">
            Real screenshots from the app: local AI chat, knowledge graph mapping, quick notes,
            and productivity tools in one cohesive experience.
          </p>

          <div className="mt-14 grid grid-cols-1 gap-5 md:grid-cols-3">
            {screenshots.map((shot, index) => (
              <motion.figure
                key={shot.src}
                initial={{ opacity: 0, y: 28 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.2 }}
                transition={{ duration: 0.6, delay: index * 0.05 }}
                className={`${shot.size} ${index % 2 === 1 ? "md:-translate-y-3" : ""} relative overflow-hidden rounded-3xl border border-slate-700/80 bg-slate-900/70 shadow-[0_30px_70px_rgba(2,6,23,0.7)]`}
              >
                <div className="relative aspect-[16/10] w-full">
                  <Image
                    src={shot.src}
                    alt={shot.alt}
                    fill
                    sizes="(max-width: 768px) 100vw, 33vw"
                    className="object-cover transition-transform duration-500 hover:scale-[1.02]"
                  />
                </div>
              </motion.figure>
            ))}
          </div>
        </div>
      </motion.section>

      <motion.footer
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
        className="border-t border-white/10 px-5 py-10"
      >
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 text-slate-400 sm:flex-row">
          <p className="text-sm">© {new Date().getFullYear()} Kivixa. Privacy-first and open source.</p>
          <a
            href="https://github.com/990aa/kivixa"
            target="_blank"
            rel="noreferrer"
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