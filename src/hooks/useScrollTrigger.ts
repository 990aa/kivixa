"use client";

import { DependencyList, RefObject, useLayoutEffect } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export function useScrollTrigger(
  scope: RefObject<HTMLElement | null>,
  createAnimations: () => void,
  deps: DependencyList = []
) {
  useLayoutEffect(() => {
    if (typeof window === "undefined") return;

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reducedMotion) return;

    const ctx = gsap.context(createAnimations, scope);

    const refresh = () => ScrollTrigger.refresh();

    if ("fonts" in document) {
      (document as Document & { fonts: { ready: Promise<void> } }).fonts.ready
        .then(refresh)
        .catch(() => {
          // Ignore font loading failures and keep existing trigger measurements.
        });
    }

    window.addEventListener("load", refresh, { once: true });

    return () => {
      window.removeEventListener("load", refresh);
      ctx.revert();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
}
