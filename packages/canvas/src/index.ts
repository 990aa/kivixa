export class CanvasEngine {
  private worker: Worker;
  private isPanning = false;
  private lastX = 0;
  private lastY = 0;
  public freePaperMovementEnabled = false;

  constructor(canvas: HTMLCanvasElement) {
    const offscreen = canvas.transferControlToOffscreen();
    this.worker = new Worker(new URL('./worker.ts', import.meta.url));
    this.worker.postMessage({ canvas: offscreen }, [offscreen]);

    this.handleResize(canvas);
    window.addEventListener('resize', () => this.handleResize(canvas));

    canvas.addEventListener('mousedown', this.handleMouseDown.bind(this));
    canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
    canvas.addEventListener('mouseup', this.handleMouseUp.bind(this));
    canvas.addEventListener('wheel', this.handleWheel.bind(this));
  }

  public moveToCorner(pageIndex: number, corner: 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight') {
    if (this.freePaperMovementEnabled) {
      this.worker.postMessage({ type: 'moveToCorner', pageIndex, corner });
    }
  }

  public addPage() {
    this.worker.postMessage({ type: 'addPage' });
  }

  public goToPage(pageIndex: number) {
    this.worker.postMessage({ type: 'goToPage', pageIndex });
  }

  private handleResize(canvas: HTMLCanvasElement) {
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    this.worker.postMessage({
      type: 'resize',
      width: canvas.width,
      height: canvas.height,
    });
  }

  private handleMouseDown(e: MouseEvent) {
    if (e.button === 1) { // Middle mouse button
      this.isPanning = true;
      this.lastX = e.clientX;
      this.lastY = e.clientY;
    }
  }

  private handleMouseMove(e: MouseEvent) {
    if (this.isPanning) {
      const dx = e.clientX - this.lastX;
      const dy = e.clientY - this.lastY;
      this.lastX = e.clientX;
      this.lastY = e.clientY;
      this.worker.postMessage({ type: 'pan', dx, dy });
    }
  }

  private handleMouseUp(e: MouseEvent) {
    if (e.button === 1) {
      this.isPanning = false;
    }
  }

  private handleWheel(e: WheelEvent) {
    e.preventDefault();
    const zoomFactor = 1.1;
    const dz = e.deltaY > 0 ? 1 / zoomFactor : zoomFactor;
    this.worker.postMessage({ type: 'zoom', dz, x: e.clientX, y: e.clientY });
  }
}
