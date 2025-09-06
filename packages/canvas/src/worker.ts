let ctx: OffscreenCanvasRenderingContext2D;

self.onmessage = (e) => {
  if (e.data.canvas) {
    const canvas = e.data.canvas as OffscreenCanvas;
    ctx = canvas.getContext('2d') as OffscreenCanvasRenderingContext2D;
    if (ctx) {
      // For now, just draw a red rectangle to show it's working
      ctx.fillStyle = 'red';
      ctx.fillRect(10, 10, 100, 100);
    }
  }
};
