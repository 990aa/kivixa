export class CanvasEngine {
  private worker: Worker;

  constructor(canvas: HTMLCanvasElement) {
    const offscreen = canvas.transferControlToOffscreen();
    this.worker = new Worker(new URL('./worker.ts', import.meta.url));
    this.worker.postMessage({ canvas: offscreen }, [offscreen]);
  }
}
