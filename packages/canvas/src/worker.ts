// worker.ts

class Page {
  width: number;
  height: number;

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }
}

class Document {
  pages: Page[] = [];

  addPage(page: Page) {
    this.pages.push(page);
  }
}

class Viewport {
  x: number = 0;
  y: number = 0;
  zoom: number = 1;
}

let ctx: OffscreenCanvasRenderingContext2D;
let document: Document;
let canvasWidth: number;
let canvasHeight: number;
let viewport: Viewport;

function render() {
  if (!ctx) return;

  // Clear canvas
  ctx.fillStyle = 'lightgray';
  ctx.fillRect(0, 0, canvasWidth, canvasHeight);

  ctx.save();
  ctx.translate(viewport.x, viewport.y);
  ctx.scale(viewport.zoom, viewport.zoom);

  // Render pages
  ctx.fillStyle = 'white';
  document.pages.forEach((page, index) => {
    const x = 50;
    const y = 50 + index * (page.height + 20); // Add some spacing between pages
    ctx.fillRect(x, y, page.width, page.height);
    ctx.strokeStyle = 'black';
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, page.width, page.height);
  });

  ctx.restore();
}

self.onmessage = (e) => {
  if (e.data.canvas) {
    const canvas = e.data.canvas as OffscreenCanvas;
    canvasWidth = canvas.width;
    canvasHeight = canvas.height;
    ctx = canvas.getContext('2d') as OffscreenCanvasRenderingContext2D;
    viewport = new Viewport();
    
    // Create a sample document
    document = new Document();
    const page1 = new Page(800, 600);
    document.addPage(page1);
    const page2 = new Page(800, 600);
    document.addPage(page2);

    render();
  } else if (e.data.type === 'resize') {
    canvasWidth = e.data.width;
    canvasHeight = e.data.height;
    if (ctx && ctx.canvas) {
      ctx.canvas.width = canvasWidth;
      ctx.canvas.height = canvasHeight;
    }
    render();
  } else if (e.data.type === 'pan') {
    viewport.x += e.data.dx;
    viewport.y += e.data.dy;
    render();
  } else if (e.data.type === 'zoom') {
    const newZoom = viewport.zoom * e.data.dz;
    
    const mouseX = e.data.x;
    const mouseY = e.data.y;

    // Adjust pan to zoom around the mouse pointer
    viewport.x = mouseX - (mouseX - viewport.x) * (newZoom / viewport.zoom);
    viewport.y = mouseY - (mouseY - viewport.y) * (newZoom / viewport.zoom);
    viewport.zoom = newZoom;
    
    render();
  } else if (e.data.type === 'moveToCorner') {
    const { pageIndex, corner } = e.data;
    const page = document.pages[pageIndex];
    if (!page) return;

    const pageX = 50;
    const pageY = 50 + pageIndex * (page.height + 20);

    let cornerX = pageX;
    let cornerY = pageY;

    if (corner === 'topRight') {
      cornerX += page.width;
    } else if (corner === 'bottomLeft') {
      cornerY += page.height;
    } else if (corner === 'bottomRight') {
      cornerX += page.width;
      cornerY += page.height;
    }

    // Center the corner
    viewport.x = canvasWidth / 2 - cornerX * viewport.zoom;
    viewport.y = canvasHeight / 2 - cornerY * viewport.zoom;
    
    render();
  } else if (e.data.type === 'addPage') {
    const newPage = new Page(800, 600);
    document.addPage(newPage);
    render();
  } else if (e.data.type === 'goToPage') {
    const { pageIndex } = e.data;
    const page = document.pages[pageIndex];
    if (!page) return;

    const pageX = 50;
    const pageY = 50 + pageIndex * (page.height + 20);

    // Center the page
    viewport.x = canvasWidth / 2 - (pageX + page.width / 2) * viewport.zoom;
    viewport.y = canvasHeight / 2 - (pageY + page.height / 2) * viewport.zoom;

    render();
  }
};