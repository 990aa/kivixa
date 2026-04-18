"use client";

import { useEffect, useRef, useState } from "react";
import { gsap } from "gsap";

type CurtainState = "open" | "closed";

const EDGE_THRESHOLD = 2;
const SWIPE_THRESHOLD = 6;

export default function GlobalCurtain() {
  const shellRef = useRef<HTMLDivElement>(null);
  const leftRef = useRef<HTMLDivElement>(null);
  const rightRef = useRef<HTMLDivElement>(null);
  const stateRef = useRef<CurtainState>("closed");
  const isAnimatingRef = useRef(false);
  const touchYRef = useRef<number | null>(null);
  const [state, setState] = useState<CurtainState>("closed");

  useEffect(() => {
    const shell = shellRef.current;
    const left = leftRef.current;
    const right = rightRef.current;

    if (!shell || !left || !right) return;

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const openDuration = reducedMotion ? 0 : 1.05;
    const closeDuration = reducedMotion ? 0 : 0.9;

    const setClosedInstantly = () => {
      gsap.set(shell, { autoAlpha: 1 });
      gsap.set(left, {
        xPercent: 0,
        rotate: 0,
        scaleX: 1,
        scaleY: 1,
        filter: "brightness(1.25)",
      });
      gsap.set(right, {
        xPercent: 0,
        rotate: 0,
        scaleX: 1,
        scaleY: 1,
        filter: "brightness(1.25)",
      });
      stateRef.current = "closed";
      setState("closed");
      isAnimatingRef.current = false;
    };

    const openCurtain = () => {
      if (stateRef.current === "open" || isAnimatingRef.current) return;

      isAnimatingRef.current = true;
      gsap.killTweensOf([shell, left, right]);
      gsap.set(shell, { autoAlpha: 1 });

      gsap
        .timeline({
          defaults: { ease: "power3.inOut" },
          onComplete: () => {
            stateRef.current = "open";
            setState("open");
            isAnimatingRef.current = false;
            gsap.set(shell, { autoAlpha: 0 });
          },
        })
        .to(
          left,
          {
            xPercent: -102,
            rotate: 18,
            scaleX: 0.08,
            scaleY: 1.9,
            filter: "brightness(1)",
            duration: openDuration,
          },
          0
        )
        .to(
          right,
          {
            xPercent: 102,
            rotate: -18,
            scaleX: 0.08,
            scaleY: 1.9,
            filter: "brightness(1)",
            duration: openDuration,
          },
          0
        );
    };

    const closeCurtain = () => {
      if (stateRef.current === "closed" || isAnimatingRef.current) return;

      isAnimatingRef.current = true;
      gsap.killTweensOf([shell, left, right]);
      gsap.set(shell, { autoAlpha: 1 });

      gsap
        .timeline({
          defaults: { ease: "power3.inOut" },
          onComplete: () => {
            stateRef.current = "closed";
            setState("closed");
            isAnimatingRef.current = false;
          },
        })
        .to(
          left,
          {
            xPercent: 0,
            rotate: 0,
            scaleX: 1,
            scaleY: 1,
            filter: "brightness(1.25)",
            duration: closeDuration,
          },
          0
        )
        .to(
          right,
          {
            xPercent: 0,
            rotate: 0,
            scaleX: 1,
            scaleY: 1,
            filter: "brightness(1.25)",
            duration: closeDuration,
          },
          0
        );
    };

    const isAtTop = () => window.scrollY <= EDGE_THRESHOLD;

    const isAtBottom = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      if (maxScroll <= EDGE_THRESHOLD) return true;
      return window.scrollY >= maxScroll - EDGE_THRESHOLD;
    };

    const handleDirectionalInput = (deltaY: number) => {
      if (Math.abs(deltaY) < 0.5) return;

      if (deltaY < 0 && isAtTop()) {
        closeCurtain();
        return;
      }

      if (deltaY > 0 && isAtBottom()) {
        closeCurtain();
        return;
      }

      openCurtain();
    };

    const onWheel = (event: WheelEvent) => {
      handleDirectionalInput(event.deltaY);
    };

    const onPointerDown = () => {
      openCurtain();
    };

    const onTouchStart = (event: TouchEvent) => {
      touchYRef.current = event.touches[0]?.clientY ?? null;
    };

    const onTouchMove = (event: TouchEvent) => {
      if (touchYRef.current === null || event.touches.length === 0) return;

      const currentY = event.touches[0].clientY;
      const deltaY = touchYRef.current - currentY;

      if (Math.abs(deltaY) < SWIPE_THRESHOLD) return;

      handleDirectionalInput(deltaY);
      touchYRef.current = currentY;
    };

    const onTouchEnd = () => {
      touchYRef.current = null;
    };

    const onKeyDown = (event: KeyboardEvent) => {
      const isScrollDown =
        event.key === "ArrowDown" ||
        event.key === "PageDown" ||
        event.key === "End" ||
        (event.key === " " && !event.shiftKey);

      const isScrollUp =
        event.key === "ArrowUp" ||
        event.key === "PageUp" ||
        event.key === "Home" ||
        (event.key === " " && event.shiftKey);

      if (!isScrollDown && !isScrollUp) return;

      handleDirectionalInput(isScrollDown ? 1 : -1);
    };

    setClosedInstantly();

    window.addEventListener("wheel", onWheel, { passive: true });
    window.addEventListener("pointerdown", onPointerDown, { passive: true });
    window.addEventListener("touchstart", onTouchStart, { passive: true });
    window.addEventListener("touchmove", onTouchMove, { passive: true });
    window.addEventListener("touchend", onTouchEnd, { passive: true });
    window.addEventListener("keydown", onKeyDown);

    return () => {
      window.removeEventListener("wheel", onWheel);
      window.removeEventListener("pointerdown", onPointerDown);
      window.removeEventListener("touchstart", onTouchStart);
      window.removeEventListener("touchmove", onTouchMove);
      window.removeEventListener("touchend", onTouchEnd);
      window.removeEventListener("keydown", onKeyDown);
      gsap.killTweensOf([shell, left, right]);
    };
  }, []);

  return (
    <div
      ref={shellRef}
      data-testid="global-curtain"
      data-state={state}
      aria-hidden="true"
      className="global-curtain-shell"
    >
      <div ref={leftRef} className="global-curtain-side global-curtain-left" />
      <div ref={rightRef} className="global-curtain-side global-curtain-right" />
    </div>
  );
}
