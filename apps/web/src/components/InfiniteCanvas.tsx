'use client';

import { useEffect, useRef, useState } from 'react';
import { CanvasEngine } from '@kivixa/canvas';

export function InfiniteCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const engineRef = useRef<CanvasEngine | null>(null);
  const [freePaperMovement, setFreePaperMovement] = useState(false);
  const [page, setPage] = useState(0);
  const [numPages, setNumPages] = useState(2); // Assuming 2 pages initially

  useEffect(() => {
    if (canvasRef.current) {
      const engine = new CanvasEngine(canvasRef.current);
      engineRef.current = engine;
      engine.freePaperMovementEnabled = freePaperMovement;
    }
  }, []);

  useEffect(() => {
    if (engineRef.current) {
      engineRef.current.freePaperMovementEnabled = freePaperMovement;
    }
  }, [freePaperMovement]);

  const moveToCorner = (corner: 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight') => {
    if (engineRef.current) {
      engineRef.current.moveToCorner(0, corner);
    }
  };

  const addPage = () => {
    if (engineRef.current) {
      engineRef.current.addPage();
      setNumPages(numPages + 1);
      setPage(numPages);
    }
  };

  const goToPage = (pageNumber: number) => {
    if (engineRef.current) {
      engineRef.current.goToPage(pageNumber);
      setPage(pageNumber);
    }
  };

  return (
    <div className="relative w-full h-full">
      <canvas ref={canvasRef} className="w-full h-full" />
      <div className="absolute top-2 left-2 bg-white p-2 rounded shadow">
        <div>
          <label>
            <input
              type="checkbox"
              checked={freePaperMovement}
              onChange={(e) => setFreePaperMovement(e.target.checked)}
            />
            Enable Free Paper Movement
          </label>
        </div>
        <div className="mt-2">
          <button onClick={() => moveToCorner('topLeft')} className="px-2 py-1 border rounded">
            Top Left
          </button>
          <button onClick={() => moveToCorner('topRight')} className="px-2 py-1 border rounded ml-2">
            Top Right
          </button>
          <button onClick={() => moveToCorner('bottomLeft')} className="px-2 py-1 border rounded ml-2">
            Bottom Left
          </button>
          <button onClick={() => moveToCorner('bottomRight')} className="px-2 py-1 border rounded ml-2">
            Bottom Right
          </button>
        </div>
      </div>
      <div className="absolute bottom-2 left-1/2 -translate-x-1/2 bg-white p-2 rounded shadow flex items-center">
        <button onClick={addPage} className="px-2 py-1 border rounded">
          Add Page
        </button>
        <div className="ml-4">
          <input
            type="range"
            min="0"
            max={numPages - 1}
            value={page}
            onChange={(e) => goToPage(parseInt(e.target.value))}
            className="w-64"
          />
        </div>
        <div className="ml-4">
          <span>
            Page {page + 1} of {numPages}
          </span>
          <input
            type="number"
            value={page + 1}
            onChange={(e) => goToPage(parseInt(e.target.value) - 1)}
            className="w-16 ml-2 border rounded px-2 py-1"
          />
        </div>
      </div>
    </div>
  );
}
