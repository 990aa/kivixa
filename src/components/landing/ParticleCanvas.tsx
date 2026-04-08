"use client";

import { useEffect, useRef } from "react";

type Particle = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  alphaPhase: number;
  alphaSpeed: number;
};

interface ParticleCanvasProps {
  className?: string;
  count?: number;
  density?: "normal" | "dense";
}

export default function ParticleCanvas({
  className = "",
  count = 80,
  density = "normal",
}: ParticleCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || typeof window === "undefined") return;

    const context = canvas.getContext("2d");
    if (!context) return;

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const particles: Particle[] = [];
    let rafId = 0;

    const velocityFactor = density === "dense" ? 0.52 : 0.4;
    const particleCount = density === "dense" ? Math.floor(count * 1.35) : count;

    const initialize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const { width, height } = canvas.getBoundingClientRect();

      canvas.width = Math.max(1, Math.floor(width * dpr));
      canvas.height = Math.max(1, Math.floor(height * dpr));

      context.setTransform(dpr, 0, 0, dpr, 0, 0);

      particles.length = 0;
      for (let index = 0; index < particleCount; index += 1) {
        particles.push({
          x: Math.random() * width,
          y: Math.random() * height,
          vx: (Math.random() - 0.5) * velocityFactor,
          vy: (Math.random() - 0.5) * velocityFactor,
          radius: 0.45 + Math.random() * 1.6,
          alphaPhase: Math.random() * Math.PI * 2,
          alphaSpeed: 0.0016 + Math.random() * 0.0024,
        });
      }
    };

    const draw = () => {
      const width = canvas.clientWidth;
      const height = canvas.clientHeight;
      const now = performance.now();

      context.clearRect(0, 0, width, height);

      for (const particle of particles) {
        if (!reducedMotion) {
          particle.x += particle.vx;
          particle.y += particle.vy;

          if (particle.x < -4) particle.x = width + 4;
          if (particle.x > width + 4) particle.x = -4;
          if (particle.y < -4) particle.y = height + 4;
          if (particle.y > height + 4) particle.y = -4;
        }

        context.beginPath();
        context.arc(particle.x, particle.y, particle.radius, 0, Math.PI * 2);
        const alpha = 0.16 + (Math.sin(now * particle.alphaSpeed + particle.alphaPhase) + 1) * 0.22;
        context.fillStyle = `rgba(192, 200, 212, ${Math.min(alpha, 0.58).toFixed(3)})`;
        context.fill();
      }

      if (!reducedMotion) {
        rafId = window.requestAnimationFrame(draw);
      }
    };

    initialize();
    draw();

    const onResize = () => {
      initialize();
      if (reducedMotion) {
        draw();
      }
    };

    window.addEventListener("resize", onResize, { passive: true });

    return () => {
      window.removeEventListener("resize", onResize);
      window.cancelAnimationFrame(rafId);
    };
  }, [count, density]);

  return <canvas ref={canvasRef} className={`particle-canvas ${className}`} aria-hidden="true" />;
}
