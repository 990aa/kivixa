"use client";

import { motion } from "framer-motion";
import CodeBlock from "./CodeBlock";
import type { ReleaseData } from "@/lib/github";

interface DownloadSectionProps {
  release: ReleaseData;
}

export default function DownloadSection({ release }: DownloadSectionProps) {
  return (
    <section id="download" data-testid="download-section" className="relative py-24 sm:py-32 px-6">
      <div className="absolute inset-0 -z-10">
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] rounded-full bg-accent-primary/5 blur-[120px]" />
      </div>

      <div className="max-w-6xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <p className="text-xs font-mono uppercase tracking-[0.2em] text-accent-teal mb-4">Get Started</p>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary mb-4">Download Kivixa</h2>
          <p className="text-text-secondary max-w-lg mx-auto text-lg">Available now for Windows and Android. Build from source for any platform.</p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-6">
          {/* Windows */}
          <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: "-60px" }} transition={{ duration: 0.5 }}
            className="rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-sm p-8 flex flex-col">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-xl bg-accent-primary/10 border border-accent-primary/20 flex items-center justify-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" className="text-accent-primary" aria-hidden="true"><path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/></svg>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Windows</h3>
                <p data-testid="windows-version" className="text-xs text-text-muted">v{release.version} · 64-bit installer</p>
              </div>
            </div>
            <p className="text-sm text-text-secondary mb-6 flex-1">Download the Windows installer for the full desktop experience with Vulkan GPU acceleration.</p>
            <a data-testid="download-windows" href={release.windowsUrl ?? "#"}
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-accent-primary px-5 py-3 text-sm font-semibold text-white hover:bg-accent-secondary transition-all shadow-glow-sm hover:shadow-glow-md hover:-translate-y-0.5">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download .exe
            </a>
          </motion.div>

          {/* Android */}
          <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: "-60px" }} transition={{ duration: 0.5, delay: 0.1 }}
            className="rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-sm p-8 flex flex-col">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-xl bg-accent-teal/10 border border-accent-teal/20 flex items-center justify-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" className="text-accent-teal" aria-hidden="true"><path d="M17.523 15.341c-.628 0-1.137.51-1.137 1.137s.51 1.137 1.137 1.137 1.137-.51 1.137-1.137-.509-1.137-1.137-1.137zm-11.046 0c-.628 0-1.137.51-1.137 1.137s.509 1.137 1.137 1.137 1.137-.51 1.137-1.137-.509-1.137-1.137-1.137zM17.799 10.56l2.182-3.779a.454.454 0 00-.166-.619.454.454 0 00-.619.166l-2.209 3.826A13.298 13.298 0 0012 9.271c-1.855 0-3.607.354-5.187.883L4.604 6.328a.454.454 0 00-.619-.166.454.454 0 00-.166.619l2.182 3.779C2.581 12.353.39 15.484.0 19.108h24c-.39-3.624-2.581-6.755-6.201-8.548z"/></svg>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Android</h3>
                <p data-testid="android-version" className="text-xs text-text-muted">v{release.version} · API 24+ · ARM64</p>
              </div>
            </div>
            <p className="text-sm text-text-secondary mb-4 flex-1">
              Download the ARM64 APK directly, or use F-Droid for automatic updates.
            </p>
            <a data-testid="download-android" href={release.androidArm64Url ?? "#"}
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-accent-teal/90 px-5 py-3 text-sm font-semibold text-surface-900 hover:bg-accent-teal transition-all hover:-translate-y-0.5 mb-4">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download ARM64 APK
            </a>
            <div className="rounded-xl border border-border-subtle bg-surface-800/40 p-4 space-y-3">
              <p className="text-xs font-mono uppercase tracking-[0.15em] text-text-muted">F-Droid Repo</p>
              <div className="flex items-center gap-4">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=https://990aa.github.io/kivixa/repo&bgcolor=0a0a0f&color=ffffff" alt="QR code to add Kivixa F-Droid repository" width={64} height={64} className="rounded-md" />
                <p className="text-xs text-text-muted">Scan with F-Droid to auto-add the repo</p>
              </div>
            </div>
            <p className="text-xs text-text-muted mt-4">
              Need ARMv7 or x86_64?{" "}
              <a href={release.releasesPageUrl} target="_blank" rel="noopener noreferrer" className="text-accent-blue hover:text-accent-secondary transition-colors underline underline-offset-2">
                View all builds on GitHub Releases
              </a>
            </p>
          </motion.div>

          {/* Build from Source */}
          <motion.div initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: "-60px" }} transition={{ duration: 0.5, delay: 0.2 }}
            className="rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-sm p-8 flex flex-col">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-xl bg-accent-blue/10 border border-accent-blue/20 flex items-center justify-center">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-accent-blue" aria-hidden="true"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-text-primary">Build from Source</h3>
                <p className="text-xs text-text-muted">Any platform</p>
              </div>
            </div>
            <div className="mb-6 flex-1">
              <CodeBlock title="terminal" lines={[
                { content: "# Clone and build", className: "code-comment" },
                { content: "git clone https://github.com/990aa/kivixa.git", className: "code-command" },
                { content: "cd kivixa", className: "code-command" },
                { content: "flutter pub get", className: "code-command" },
                { content: "flutter run -d windows", className: "code-command" },
              ]} />
            </div>
            <div className="rounded-xl border border-border-subtle bg-surface-800/30 p-4">
              <p className="text-xs font-mono uppercase tracking-[0.15em] text-text-muted mb-2">Prerequisites</p>
              <div className="flex flex-wrap gap-2">
                <span className="text-xs rounded-md bg-surface-700/60 border border-border-subtle px-2 py-1 text-text-secondary">Flutter 3.41.6+</span>
                <span className="text-xs rounded-md bg-surface-700/60 border border-border-subtle px-2 py-1 text-text-secondary">Dart 3.11.4+</span>
                <span className="text-xs rounded-md bg-surface-700/60 border border-border-subtle px-2 py-1 text-text-secondary">Rust toolchain</span>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
