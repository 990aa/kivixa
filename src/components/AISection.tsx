"use client";

import { motion } from "framer-motion";
import ScreenshotImage from "./ScreenshotImage";

const modelFamilies = [
  { name: "Phi-4", org: "Microsoft" },
  { name: "Qwen 2.5 / 3.5", org: "Alibaba" },
  { name: "Gemma 2 / 3", org: "Google" },
  { name: "DeepSeek R1", org: "DeepSeek" },
  { name: "SmolLM2", org: "Hugging Face" },
];

const mcpTools = [
  { label: "File Operations", desc: "Read, write, delete files" },
  { label: "Directory Listing", desc: "Browse notes folder" },
  { label: "Markdown Export", desc: "Export AI responses" },
  { label: "Lua Scripting", desc: "Run calendar & timer scripts" },
];

export default function AISection() {
  return (
    <section className="relative py-24 sm:py-32 px-6 overflow-hidden">
      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[600px] rounded-full bg-accent-primary/5 blur-[120px] -z-10" />

      <div className="max-w-7xl mx-auto">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left: Content */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6 }}
          >
            <p className="text-xs font-mono uppercase tracking-[0.2em] text-accent-teal mb-4">
              On-device AI
            </p>
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary mb-6 leading-tight">
              Private AI that runs{" "}
              <span className="bg-gradient-to-r from-accent-primary to-accent-teal bg-clip-text text-transparent">
                entirely on your hardware
              </span>
            </h2>
            <p className="text-text-secondary text-lg mb-8 leading-relaxed">
              Switch between multiple model families for different tasks — reasoning, code generation,
              writing, and tool execution — all without an internet connection. No API keys, no subscriptions,
              no data ever leaving your device.
            </p>

            {/* Model family chips */}
            <div className="mb-10">
              <p className="text-xs font-mono uppercase tracking-[0.15em] text-text-muted mb-3">
                Supported Models
              </p>
              <div className="flex flex-wrap gap-2">
                {modelFamilies.map((model) => (
                  <span
                    key={model.name}
                    className="inline-flex items-center gap-2 rounded-lg border border-border-default bg-surface-800/60 px-3 py-1.5 text-sm"
                  >
                    <span className="text-text-primary font-medium">{model.name}</span>
                    <span className="text-text-muted text-xs">· {model.org}</span>
                  </span>
                ))}
              </div>
            </div>

            {/* MCP Tools */}
            <div>
              <p className="text-xs font-mono uppercase tracking-[0.15em] text-text-muted mb-3">
                MCP Tool Execution
              </p>
              <div className="grid grid-cols-2 gap-3">
                {mcpTools.map((tool) => (
                  <div
                    key={tool.label}
                    className="flex items-start gap-3 rounded-xl border border-border-subtle bg-surface-800/30 p-3 transition-colors hover:border-border-hover"
                  >
                    <div className="w-5 h-5 mt-0.5 text-accent-secondary shrink-0">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                        <polyline points="14 2 14 8 20 8" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-text-primary">{tool.label}</p>
                      <p className="text-xs text-text-muted">{tool.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </motion.div>

          {/* Right: Screenshots */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-80px" }}
            transition={{ duration: 0.6, delay: 0.15 }}
            className="relative"
          >
            {/* Main AI chat screenshot */}
            <div className="screenshot-frame rounded-2xl overflow-hidden shadow-2xl mb-5">
              <div className="flex items-center gap-2 px-4 py-2.5 bg-surface-850 border-b border-border-subtle">
                <span className="w-2.5 h-2.5 rounded-full bg-accent-rose/60" />
                <span className="w-2.5 h-2.5 rounded-full bg-accent-amber/60" />
                <span className="w-2.5 h-2.5 rounded-full bg-accent-teal/60" />
                <span className="ml-3 text-[10px] text-text-muted font-mono">AI Chat</span>
              </div>
              <ScreenshotImage
                src="/assets/screenshots/ai-chat.png"
                alt="Kivixa AI chat interface showing on-device conversation with local model"
                width={1919}
                height={1006}
                className="w-full"
                loading="eager"
              />
            </div>

            {/* Overlapping smaller screenshots */}
            <div className="grid grid-cols-2 gap-4">
              <div className="screenshot-frame rounded-xl overflow-hidden">
                <ScreenshotImage
                  src="/assets/screenshots/ai-model-picker.png"
                  alt="Kivixa model picker showing available AI models for switching"
                  width={1919}
                  height={1009}
                  className="w-full"
                />
              </div>
              <div className="screenshot-frame rounded-xl overflow-hidden">
                <ScreenshotImage
                  src="/assets/screenshots/mcp-tools.png"
                  alt="Kivixa MCP tools panel showing AI tool execution options"
                  width={1919}
                  height={1007}
                  className="w-full"
                />
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
