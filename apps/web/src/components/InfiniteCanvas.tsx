'use client';

import { useEffect, useRef } from 'react';
import { CanvasEngine } from '@kivixa/canvas';

export function InfiniteCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (canvasRef.current) {
      const engine = new CanvasEngine(canvasRef.current);
    }
  }, []);

  return <canvas ref={canvasRef} className="w-full h-full" />;
}
