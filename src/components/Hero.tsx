"use client";

import { motion } from "framer-motion";
import type { ReleaseData } from "@/lib/github";
import ScreenshotImage from "./ScreenshotImage";

interface HeroProps {
  release: ReleaseData;
}

export default function Hero({ release }: HeroProps) {
  return (
    <section data-testid="hero-section" className="relative min-h-screen flex flex-col items-center justify-center px-6 pt-24 pb-16 overflow-hidden">
      {/* Animated gradient background */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-0 left-1/4 w-[600px] h-[600px] rounded-full bg-accent-primary/10 blur-[120px] animate-pulse-glow" />
        <div className="absolute bottom-1/4 right-1/4 w-[500px] h-[500px] rounded-full bg-accent-teal/8 blur-[100px] animate-pulse-glow [animation-delay:1.5s]" />
        <div className="absolute top-1/3 right-1/3 w-[400px] h-[400px] rounded-full bg-accent-blue/6 blur-[80px] animate-pulse-glow [animation-delay:3s]" />
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto text-center">
        {/* Badge chip */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="inline-flex items-center gap-2 rounded-full border border-border-default bg-surface-800/60 backdrop-blur-sm px-4 py-1.5 text-xs font-medium text-text-secondary mb-8"
        >
          <span className="w-1.5 h-1.5 rounded-full bg-accent-teal animate-shimmer" />
          Local-first · Privacy-first · Open source
        </motion.div>

        {/* Headline */}
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-[1.05] text-text-primary mb-6"
        >
          Your productivity workspace.{" "}
          <span className="bg-gradient-to-r from-accent-primary via-accent-secondary to-accent-teal bg-clip-text text-transparent">
            Your device.
          </span>{" "}
          <br className="hidden sm:block" />
          Your data.
        </motion.h1>

        {/* Subheadline */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="text-lg sm:text-xl text-text-secondary max-w-2xl mx-auto mb-10 leading-relaxed"
        >
          Notes, sketching, planning, and AI assistance — all running locally on your device.
          No cloud. No subscriptions. No data leaves your machine.
        </motion.p>

        {/* CTAs */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16"
        >
          <a
            data-testid="cta-winget"
            href="#download"
            className="group inline-flex items-center gap-2.5 rounded-xl bg-accent-primary px-6 py-3 text-sm font-semibold text-white hover:bg-accent-secondary transition-all shadow-glow-sm hover:shadow-glow-md hover:-translate-y-0.5"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="7 10 12 15 17 10" />
              <line x1="12" y1="15" x2="12" y2="3" />
            </svg>
            Install with winget
          </a>
          <a
            href="https://github.com/990aa/kivixa"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2.5 rounded-xl border border-border-default bg-surface-800/40 px-6 py-3 text-sm font-medium text-text-secondary hover:text-text-primary hover:border-border-hover hover:bg-surface-700/40 transition-all hover:-translate-y-0.5"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
            </svg>
            View on GitHub
          </a>
        </motion.div>

        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.45 }}
          className="mb-12 text-xs sm:text-sm text-text-muted font-mono"
        >
          Recommended on Windows: <span className="text-accent-teal">winget install Kivixa</span> ·{" "}
          <a
            href={release.windowsUrl ?? "#download"}
            className="text-accent-blue hover:text-accent-secondary underline underline-offset-2 transition-colors"
          >
            Download .exe v{release.version}
          </a>
        </motion.p>

        {/* Hero Screenshot */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.5, ease: [0.22, 1, 0.36, 1] }}
          className="relative max-w-5xl mx-auto"
        >
          {/* Glow behind screenshot */}
          <div className="absolute inset-0 -z-10 scale-95 blur-[60px] opacity-40 bg-gradient-to-br from-accent-primary/30 via-accent-teal/20 to-accent-blue/20 rounded-3xl" />

          <div className="space-y-5">
            {/* Main workspace screenshot */}
            <motion.div
              animate={{ y: [0, -8, 0] }}
              transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
              className="screenshot-frame rounded-2xl overflow-hidden shadow-2xl border border-border-default [transform:perspective(2000px)_rotateX(2deg)]"
            >
              <div className="flex items-center gap-2 px-4 py-2.5 bg-surface-850 border-b border-border-subtle">
                <span className="w-2.5 h-2.5 rounded-full bg-accent-rose/60" />
                <span className="w-2.5 h-2.5 rounded-full bg-accent-amber/60" />
                <span className="w-2.5 h-2.5 rounded-full bg-accent-teal/60" />
                <span className="ml-3 text-[10px] text-text-muted font-mono">Kivixa - Workspace</span>
              </div>
              <ScreenshotImage
                src="/assets/screenshots/workspace-notes.png"
                alt="Kivixa workspace showing notes, files, and productivity tools"
                width={1919}
                height={1002}
                loading="eager"
              />
            </motion.div>

            {/* Dark mode screenshot */}
            <motion.div
              initial={{ opacity: 0, y: 28 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.75, ease: [0.22, 1, 0.36, 1] }}
              className="screenshot-frame rounded-xl overflow-hidden border border-border-default max-w-3xl mx-auto"
            >
              <div className="flex items-center justify-between gap-2 px-4 py-2.5 bg-surface-850 border-b border-border-subtle">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-accent-rose/60" />
                  <span className="w-2.5 h-2.5 rounded-full bg-accent-amber/60" />
                  <span className="w-2.5 h-2.5 rounded-full bg-accent-teal/60" />
                </div>
                <span className="text-[10px] text-text-muted font-mono">Dark mode workspace</span>
              </div>
              <ScreenshotImage
                src="/assets/screenshots/workspace-notes-dark-mode.png"
                alt="Kivixa workspace in dark mode"
                width={1919}
                height={1005}
              />
            </motion.div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
