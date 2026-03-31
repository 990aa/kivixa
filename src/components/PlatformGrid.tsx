"use client";

import { motion } from "framer-motion";

interface PlatformInfo {
  name: string;
  status: "stable" | "supported" | "experimental";
  note: string;
  icon: React.ReactNode;
}

const platforms: PlatformInfo[] = [
  {
    name: "Windows",
    status: "stable",
    note: "Fully tested and optimized",
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801" />
      </svg>
    ),
  },
  {
    name: "Android",
    status: "stable",
    note: "API 24+ (Android 7.0)",
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M17.523 15.341c-.628 0-1.137.51-1.137 1.137s.51 1.137 1.137 1.137 1.137-.51 1.137-1.137-.509-1.137-1.137-1.137zm-11.046 0c-.628 0-1.137.51-1.137 1.137s.509 1.137 1.137 1.137 1.137-.51 1.137-1.137-.509-1.137-1.137-1.137zM17.799 10.56l2.182-3.779a.454.454 0 00-.166-.619.454.454 0 00-.619.166l-2.209 3.826A13.298 13.298 0 0012 9.271c-1.855 0-3.607.354-5.187.883L4.604 6.328a.454.454 0 00-.619-.166.454.454 0 00-.166.619l2.182 3.779C2.581 12.353.39 15.484.0 19.108h24c-.39-3.624-2.581-6.755-6.201-8.548z" />
      </svg>
    ),
  },
  {
    name: "macOS",
    status: "supported",
    note: "Requires macOS",
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
      </svg>
    ),
  },
  {
    name: "Linux",
    status: "supported",
    note: "Requires Linux",
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M12.504 0c-.155 0-.311.005-.466.015C8.618.205 5.691 2.978 5.331 6.385c-.237 2.246.218 3.989.672 5.473.37 1.213.752 2.467.747 3.887-.009 2.3-1.284 3.658-1.734 4.22-.376.47-.522.756-.522 1.152 0 .612.396.979.838 1.183.444.205 1.034.31 1.715.31s1.424-.105 2.078-.321c.624-.207 1.186-.471 1.617-.681l.005-.002c.411-.202.687-.327.895-.327.207 0 .483.125.893.327l.006.002c.431.21.993.474 1.617.681.654.216 1.397.321 2.078.321s1.271-.105 1.715-.31c.442-.204.838-.571.838-1.183 0-.396-.146-.682-.522-1.152-.45-.562-1.725-1.92-1.734-4.22-.005-1.42.377-2.674.747-3.887.454-1.484.909-3.227.672-5.473C18.309 2.978 15.382.205 11.962.015A7.865 7.865 0 0012.504 0z" />
      </svg>
    ),
  },
  {
    name: "iOS",
    status: "supported",
    note: "Requires iOS",
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
      </svg>
    ),
  },
  {
    name: "Web",
    status: "experimental",
    note: "Limited features",
    icon: (
      <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="12" cy="12" r="10" />
        <path d="M2 12h20" />
        <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
      </svg>
    ),
  },
];

const statusStyles: Record<string, { bg: string; text: string; label: string }> = {
  stable: {
    bg: "bg-accent-teal/10 border-accent-teal/30",
    text: "text-accent-teal",
    label: "Stable",
  },
  supported: {
    bg: "bg-accent-blue/10 border-accent-blue/30",
    text: "text-accent-blue",
    label: "Supported",
  },
  experimental: {
    bg: "bg-accent-amber/10 border-accent-amber/30",
    text: "text-accent-amber",
    label: "Experimental",
  },
};

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.06 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export default function PlatformGrid() {
  return (
    <section className="relative py-24 sm:py-32 px-6">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <p className="text-xs font-mono uppercase tracking-[0.2em] text-accent-teal mb-4">
            Cross-Platform
          </p>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-text-primary mb-4">
            Runs where you do
          </h2>
          <p className="text-text-secondary max-w-lg mx-auto text-lg">
            One codebase. Six platforms. Your data stays local on every one.
          </p>
        </motion.div>

        {/* Platform grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-60px" }}
          className="grid grid-cols-2 sm:grid-cols-3 gap-4"
        >
          {platforms.map((platform) => {
            const style = statusStyles[platform.status];
            return (
              <motion.div
                key={platform.name}
                variants={itemVariants}
                className="group relative rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-sm p-6 text-center transition-all duration-300 hover:border-border-hover hover:-translate-y-1 hover:shadow-card"
              >
                {/* Icon */}
                <div className="flex justify-center mb-4 text-text-muted group-hover:text-text-secondary transition-colors">
                  {platform.icon}
                </div>

                {/* Name */}
                <h3 className="text-base font-semibold text-text-primary mb-2">{platform.name}</h3>

                {/* Status badge */}
                <span
                  className={`inline-block rounded-full border px-3 py-0.5 text-xs font-medium mb-2 ${style.bg} ${style.text}`}
                >
                  {style.label}
                </span>

                {/* Note */}
                <p className="text-xs text-text-muted">{platform.note}</p>
              </motion.div>
            );
          })}
        </motion.div>
      </div>
    </section>
  );
}
