"use client";

import { motion } from "framer-motion";
import FeatureCard from "./FeatureCard";

const features = [
  {
    title: "Rich Markdown Editor",
    description:
      "Create beautiful formatted documents with real-time autosave, text formatting, checklists, code blocks, and hyperlinks.",
    screenshot: "/assets/screenshots/markdown-editor.png",
    alt: "Kivixa markdown editor with formatting toolbar and live preview",
    colSpan: "md:col-span-2",
  },
  {
    title: "Knowledge Graph",
    description:
      "Build interactive mind maps with multiple node types, customizable links, and pan-zoom navigation to visualize your ideas.",
    screenshot: "/assets/screenshots/knowledge-graph.png",
    alt: "Kivixa knowledge graph showing connected nodes and relationships",
    colSpan: "",
  },
  {
    title: "Productivity Clock",
    description:
      "Pomodoro timers, chained routines, multi-timer orchestration, and deep work presets with full session analytics.",
    screenshot: "/assets/screenshots/productivity-clock.png",
    alt: "Kivixa productivity clock with circular timer and session stats",
    colSpan: "",
  },
  {
    title: "Life Git Version Control",
    description:
      "Time-travel through your notes with auto-snapshots, SHA-256 content-addressable storage, and per-file commit history.",
    screenshot: "/assets/screenshots/file-version-control.png",
    alt: "Kivixa version control showing commit history and version slider",
    colSpan: "md:col-span-2",
  },
  {
    title: "Math Module",
    description:
      "A full mathematics suite: calculus, algebra, statistics, graphing, and number theory — all powered by a Rust backend.",
    screenshot: "/assets/screenshots/math-module.png",
    alt: "Kivixa math module showing calculator and equation solver",
    colSpan: "",
  },
  {
    title: "Floating Hub",
    description:
      "Quick access to notes, quick-notes, browser, clock, and AI from a floating overlay — always one tap away.",
    screenshot: "/assets/screenshots/floating-hub.png",
    alt: "Kivixa floating hub overlay with productivity shortcuts",
    colSpan: "",
  },
];

const containerVariants = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.08,
    },
  },
};

export default function Features() {
  return (
    <section id="features" data-testid="features-section" className="relative py-24 sm:py-32 px-6">
      <div className="max-w-7xl mx-auto">
        {/* Section header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <p className="text-xs font-mono uppercase tracking-[0.2em] text-accent-teal mb-4">
            Capabilities
          </p>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-text-primary mb-4">
            Everything you need.{" "}
            <span className="text-text-muted">Nothing leaves your device.</span>
          </h2>
          <p className="text-text-secondary max-w-xl mx-auto text-lg">
            A complete workspace built from the ground up for privacy, speed, and depth.
          </p>
        </motion.div>

        {/* Bento grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-60px" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-5"
        >
          {features.map((feature) => (
            <FeatureCard
              key={feature.title}
              title={feature.title}
              description={feature.description}
              screenshot={feature.screenshot}
              alt={feature.alt}
              colSpan={feature.colSpan}
            />
          ))}
        </motion.div>
      </div>
    </section>
  );
}
