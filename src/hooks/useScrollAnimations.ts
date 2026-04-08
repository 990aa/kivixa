"use client";

import { DependencyList, RefObject, useLayoutEffect } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export function useScrollAnimations(
  scope: RefObject<HTMLElement | null>,
  init: () => void,
  deps: DependencyList = []
) {
  useLayoutEffect(() => {
    if (typeof window === "undefined") return;

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return;
    }

    const ctx = gsap.context(() => {
      init();
    }, scope);

    const refresh = () => ScrollTrigger.refresh();

    if ("fonts" in document) {
      (document as Document & { fonts: { ready: Promise<void> } }).fonts.ready
        .then(refresh)
        .catch(() => {
          // Keep existing trigger measurements when font readiness fails.
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
