"use client";

import { motion } from "framer-motion";
import ScreenshotImage from "./ScreenshotImage";

interface FeatureCardProps {
  title: string;
  description: string;
  screenshot: string;
  alt: string;
  imageWidth: number;
  imageHeight: number;
  colSpan?: string;
}

export default function FeatureCard({
  title,
  description,
  screenshot,
  alt,
  imageWidth,
  imageHeight,
  colSpan = "",
}: FeatureCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      whileHover={{ y: -4 }}
      transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
      className={`group relative rounded-2xl border border-border-subtle bg-glass-bg backdrop-blur-md overflow-hidden transition-all duration-300 hover:border-border-hover hover:shadow-card-hover ${colSpan}`}
    >
      {/* Screenshot */}
      <div className="relative overflow-hidden bg-surface-850 p-3">
        <div className="rounded-xl border border-border-subtle bg-surface-900/70 p-2">
          <ScreenshotImage
            src={screenshot}
            alt={alt}
            width={imageWidth}
            height={imageHeight}
            className="transition-transform duration-500 group-hover:scale-[1.01]"
          />
        </div>
        <div className="absolute inset-0 bg-gradient-to-t from-surface-900/80 via-transparent to-transparent" />
      </div>

      {/* Content */}
      <div className="p-6">
        <h3 className="text-lg font-semibold text-text-primary mb-2 tracking-tight">{title}</h3>
        <p className="text-sm text-text-secondary leading-relaxed">{description}</p>
      </div>
    </motion.div>
  );
}
