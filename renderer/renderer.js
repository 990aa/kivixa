import { jsPDF } from "jspdf";
import showdown from 'showdown';

document.addEventListener('DOMContentLoaded', () => {
    // --- Sidebar logic ---
    const sidebar = document.getElementById('sidebar');
    const folderList = document.getElementById('folder-list');
    const noteList = document.getElementById('note-list');
    const toolbarDiv = document.getElementById('toolbar');

    // Helper to render folders
    async function loadFolders() {
        if (!folderList) return;
        folderList.innerHTML = '';
        try {
            const folders = await window.electron.getFolders();
            folders.forEach(folder => {
                const btn = document.createElement('button');
                btn.textContent = folder.name;
                btn.onclick = () => loadNotes(folder.id);
                folderList.appendChild(btn);
            });
        } catch (e) {
            folderList.innerHTML = '<div style="color:#c0392b">Failed to load folders</div>';
        }
    }

    // Helper to render notes
    async function loadNotes(folderId) {
        if (!noteList) return;
        noteList.innerHTML = '';
        try {
            const notes = await window.electron.getNotes(folderId);
            notes.forEach(note => {
                const btn = document.createElement('button');
                btn.textContent = note.title;
                btn.onclick = () => openNote(note.id);
                noteList.appendChild(btn);
            });
        } catch (e) {
            noteList.innerHTML = '<div style="color:#c0392b">Failed to load notes</div>';
        }
    }

    // Open note: show toolbar, hide sidebar
    function openNote(noteId) {
        if (toolbarDiv) toolbarDiv.style.display = '';
        if (sidebar) sidebar.style.display = 'none';
        // Optionally, load note content into canvas or main area here
    }

    // Home: show sidebar, hide toolbar
    function showHome() {
        if (toolbarDiv) toolbarDiv.style.display = 'none';
        if (sidebar) sidebar.style.display = '';
        loadFolders();
        loadNotes();
    }

    // Initial load
    showHome();

    // Optionally, add a Home button to return to sidebar view
    // Example: window.showHome = showHome;
    // --- Window Controls ---
    const minBtn = document.getElementById('min-btn');
    const maxBtn = document.getElementById('max-btn');
    const closeBtn = document.getElementById('close-btn');
    if (minBtn && maxBtn && closeBtn && window.electron?.windowControls) {
        minBtn.addEventListener('click', () => window.electron.windowControls.minimize());
        maxBtn.addEventListener('click', () => window.electron.windowControls.maximizeOrRestore());
        closeBtn.addEventListener('click', () => window.electron.windowControls.close());
    }
    // Set About version dynamically
    const aboutVersion = document.getElementById('about-version');
    if (aboutVersion && window.electron?.getAppVersion) {
        aboutVersion.textContent = window.electron.getAppVersion();
    }
    // --- Update Message UI ---
    const updateDiv = document.getElementById('update-message');
    let restartBtn = null;
    window.electron?.updater?.onUpdateStatus?.((msg) => {
        if (!updateDiv) return;
        updateDiv.style.display = 'block';
        updateDiv.innerHTML = '';
        updateDiv.style.background = msg.toLowerCase().includes('error') ? '#c0392b' : '#222';
        updateDiv.style.color = msg.toLowerCase().includes('error') ? '#fff' : '#fff';
        updateDiv.style.fontWeight = msg.toLowerCase().includes('error') ? 'bold' : 'normal';
        updateDiv.style.border = msg.toLowerCase().includes('error') ? '2px solid #e74c3c' : 'none';
        updateDiv.style.boxShadow = msg.toLowerCase().includes('error') ? '0 2px 8px #e74c3c44' : 'none';
        updateDiv.style.zIndex = 1000;
        if (msg.includes('Update downloaded. Restart to install.')) {
            updateDiv.textContent = msg + ' ';
            restartBtn = document.createElement('button');
            restartBtn.textContent = 'Restart & Install';
            restartBtn.style.marginLeft = '8px';
            restartBtn.style.background = '#27ae60';
            restartBtn.style.color = '#fff';
            restartBtn.style.border = 'none';
            restartBtn.style.padding = '6px 14px';
            restartBtn.style.borderRadius = '4px';
            restartBtn.style.cursor = 'pointer';
            restartBtn.onclick = () => window.electron.updater.restartApp();
            updateDiv.appendChild(restartBtn);
        } else if (msg.toLowerCase().includes('error')) {
            // Extract error message and show link
            let parts = msg.split('. Please report at ');
            let errorMsg = parts[0] + '.';
            let reportLink = parts[1] ? `<a href="${parts[1]}" target="_blank" style="color:#fff;text-decoration:underline;margin-left:10px;">Report Issue</a>` : '';
            updateDiv.innerHTML = `<span>${errorMsg}</span> ${reportLink}`;
        } else {
            updateDiv.textContent = msg;
        }
    });
    // -- Canvas and Context Setup --
    const canvases = { pages: document.getElementById('pages-canvas'), drawing: document.getElementById('drawing-canvas'), live: document.getElementById('live-canvas'), tool: document.getElementById('tool-overlay-canvas') };
    const ctx = { p: canvases.pages.getContext('2d'), d: canvases.drawing.getContext('2d'), l: canvases.live.getContext('2d'), t: canvases.tool.getContext('2d') };

    // -- Toolbar UI References --
    const toolbar = {
        penToolBtn: document.getElementById('pen-tool-btn'),
        eraserToolBtn: document.getElementById('eraser-tool-btn'),
        laserToolBtn: document.getElementById('laser-tool-btn'),
        shapeToolBtn: document.getElementById('shape-tool-btn'),
        rulerToolBtn: document.getElementById('ruler-tool-btn'),
        setSquareToolBtn: document.getElementById('set-square-tool-btn'),
        compassToolBtn: document.getElementById('compass-tool-btn'),
        commitShapeBtn: document.getElementById('commit-shape-btn'),
        shapeOptions: document.getElementById('shape-options'),
        pen: { color: document.getElementById('pen-color-picker'), thickness: document.getElementById('pen-thickness-slider') },
        addImageBtn: document.getElementById('add-image-btn'),
        imageUploadInput: document.getElementById('image-upload-input'),
        exportPdfBtn: document.getElementById('export-pdf-btn'),
        insertPageBtn: document.getElementById('insert-page-btn'),
    };

    // -- State Management --
    const state = {
        pages: [], panX: 0, panY: 0, zoom: 1,
        lastX: 0, lastY: 0, currentStroke: [],
        activeToolHandler: null, activeGuide: null, activeShape: null, activeObject: null,
        pen: { color: '#000000', style: 'fine-liner', thickness: 5, opacity: 1 },
        currentPageIndex: 0,
    };
    const CURRENT_NOTE_ID = 1; // Placeholder for the active note

    // -- Tab Switching Logic --
    const tabs = document.getElementById('tabs');
    const tabContents = {
        notebook: document.getElementById('notebook-view'),
        help: document.getElementById('help-view'),
    };
    const tabLinks = document.querySelectorAll('.tab-link');
    let helpContentLoaded = false;

    tabLinks.forEach(link => {
        link.addEventListener('click', () => {
            const tab = link.dataset.tab;

            tabLinks.forEach(l => l.classList.remove('active'));
            link.classList.add('active');

            Object.values(tabContents).forEach(content => content.classList.remove('active'));
            tabContents[tab.split('-')[0]].classList.add('active');

            if (tab === 'help-view' && !helpContentLoaded) {
                loadHelpContent();
            }
        });
    });

    async function loadHelpContent() {
        try {
            const markdown = await window.electron.getDocumentation();
            const converter = new showdown.Converter();
            const html = converter.makeHtml(markdown);
            tabContents.help.innerHTML = html;
            helpContentLoaded = true;
        } catch (err) {
            let msg = 'Error loading documentation.';
            if (err.message && err.message.includes('net::ERR_INTERNET_DISCONNECTED')) {
                msg = 'Network error: Please check your internet connection.';
            } else if (err.message && err.message.includes('ENOTFOUND')) {
                msg = 'Network error: Documentation server not found.';
            } else if (err.message && err.message.includes('EACCES')) {
                msg = 'File system error: Permission denied.';
            } else if (err.message && err.message.includes('EIO')) {
                msg = 'File system error: I/O error occurred.';
            }
            tabContents.help.innerHTML = `<div style=\"color:#fff;background:#c0392b;padding:10px 16px;border-radius:4px;font-weight:bold;\">${msg}</div>`;
        }
    }

    // -- Classes for Tools and Shapes --
    class BaseTool {
        constructor(x, y, w, h) { this.x = x; this.y = y; this.w = w; this.h = h; this.rotation = 0; }
        getCenter() { return { x: this.x + this.w / 2, y: this.y + this.h / 2 }; }
        getHandles() { return { tl: { x: this.x, y: this.y }, tr: { x: this.x + this.w, y: this.y }, bl: { x: this.x, y: this.y + this.h }, br: { x: this.x + this.w, y: this.y + this.h }, rot: { x: this.x + this.w / 2, y: this.y - 20 } }; }
        drawHandles(ctx) { const handles = this.getHandles(); ctx.fillStyle = '#00aaff'; Object.values(handles).forEach(h => { const rotated = this.rotatePoint(h, this.getCenter(), this.rotation); ctx.beginPath(); ctx.arc(rotated.x, rotated.y, 8, 0, 2 * Math.PI); ctx.fill(); }); }
        getHandleAt(point) { const handles = this.getHandles(); for (const [key, h] of Object.entries(handles)) { const rotated = this.rotatePoint(h, this.getCenter(), this.rotation); if (Math.hypot(rotated.x - point.x, rotated.y - point.y) < 10) return key; } return null; }
        rotatePoint(point, center, angle) { const dx = point.x - center.x, dy = point.y - center.y; return { x: dx * Math.cos(angle) - dy * Math.sin(angle) + center.x, y: dx * Math.sin(angle) + dy * Math.cos(angle) + center.y }; }
        isPointInside(point) { const unrotated = this.rotatePoint(point, this.getCenter(), -this.rotation); return unrotated.x >= this.x && unrotated.x <= this.x + this.w && unrotated.y >= this.y && unrotated.y <= this.y + this.h; }
    }

    class Shape extends BaseTool { constructor(type, x, y, w, h, color, thickness) { super(x, y, w, h); this.type = type; this.color = color; this.thickness = thickness; } draw(ctx, withHandles = false) { ctx.save(); const center = this.getCenter(); ctx.translate(center.x, center.y); ctx.rotate(this.rotation); ctx.translate(-center.x, -center.y); ctx.strokeStyle = this.color; ctx.lineWidth = this.thickness; ctx.beginPath(); if (this.type === 'rectangle') ctx.rect(this.x, this.y, this.w, this.h); else if (this.type === 'circle') ctx.arc(center.x, center.y, this.w / 2, 0, Math.PI * 2); else if (this.type === 'parallelogram') { ctx.transform(1, 0, 0.5, 1, 0, 0); ctx.rect(this.x, this.y, this.w, this.h); } ctx.stroke(); ctx.restore(); if (withHandles) this.drawHandles(ctx); } }
    class Ruler extends BaseTool { constructor(x, y) { super(x, y, 500, 50); } draw(ctx) { ctx.save(); const center = this.getCenter(); ctx.translate(center.x, center.y); ctx.rotate(this.rotation); ctx.translate(-center.x, -center.y); ctx.fillStyle = 'rgba(200, 200, 100, 0.7)'; ctx.fillRect(this.x, this.y, this.w, this.h); ctx.restore(); this.drawHandles(ctx); } }
    class SetSquare extends BaseTool { constructor(x, y) { super(x, y, 300, 300); } draw(ctx) { ctx.save(); const center = this.getCenter(); ctx.translate(center.x, center.y); ctx.rotate(this.rotation); ctx.translate(-center.x, -center.y); ctx.fillStyle = 'rgba(100, 150, 200, 0.7)'; ctx.beginPath(); ctx.moveTo(this.x, this.y + this.h); ctx.lineTo(this.x, this.y); ctx.lineTo(this.x + this.w, this.y + this.h); ctx.closePath(); ctx.fill(); ctx.restore(); this.drawHandles(ctx); } }
    class Compass { constructor(x, y) { this.cx = x; this.cy = y; this.radius = 100; this.isDrawing = false; } draw(ctx) { ctx.strokeStyle = 'rgba(0, 0, 0, 0.7)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(this.cx, this.cy, this.radius, 0, Math.PI * 2); ctx.setLineDash([5, 5]); ctx.stroke(); ctx.setLineDash([]); const handle = this.getHandle(); ctx.fillStyle = '#00aaff'; ctx.beginPath(); ctx.arc(handle.x, handle.y, 8, 0, 2 * Math.PI); ctx.fill(); ctx.beginPath(); ctx.arc(this.cx, this.cy, 8, 0, 2 * Math.PI); ctx.fill(); } getHandle() { return { x: this.cx + this.radius, y: this.cy }; } getHandleAt(point) { if (Math.hypot(point.x - this.cx, point.y - this.cy) < 10) return 'center'; const handle = this.getHandle(); if (Math.hypot(point.x - handle.x, point.y - handle.y) < 10) return 'radius'; if (Math.abs(Math.hypot(point.x - this.cx, point.y - this.cy) - this.radius) < 10) return 'edge'; return null; } }
    class ImageObject extends BaseTool { constructor(x, y, w, h, imageElement) { super(x, y, w, h); this.image = imageElement; this.type = 'image'; } draw(ctx, withHandles = false) { ctx.save(); const center = this.getCenter(); ctx.translate(center.x, center.y); ctx.rotate(this.rotation); ctx.translate(-center.x, -center.y); ctx.drawImage(this.image, this.x, this.y, this.w, this.h); ctx.restore(); if (withHandles) this.drawHandles(ctx); } }

    // -- Tool Handlers (State Pattern) --
    const toolHandlers = {
        pen: { currentStroke: [], onPointerDown(e, pos) { this.currentStroke = [getSnappedPos(pos, e.pressure)]; }, onPointerMove(e, pos) { if (this.currentStroke.length > 0) this.currentStroke.push(getSnappedPos(pos, e.pressure)); }, onPointerUp() { commitStroke(this.currentStroke); this.currentStroke = []; }, draw(lctx) { renderStroke(lctx, this.currentStroke, { ...state.pen, tool: 'pen' }, true); } },
        defineShape: { shapeType: 'rectangle', startPos: null, onActivate(options) { this.shapeType = options.shapeType; canvases.tool.style.cursor = 'crosshair'; }, onDeactivate() { canvases.tool.style.cursor = 'default'; }, onPointerDown(e, pos) { this.startPos = pos; }, onPointerMove(e, pos) { if (!this.startPos) return; const tempShape = new Shape(this.shapeType, this.startPos.x, this.startPos.y, pos.x - this.startPos.x, pos.y - this.startPos.y, state.pen.color, state.pen.thickness); tempShape.draw(ctx.t); }, onPointerUp(e, pos) { const w = pos.x - this.startPos.x; const h = pos.y - this.startPos.y; state.activeShape = new Shape(this.shapeType, this.startPos.x, this.startPos.y, w, h, state.pen.color, state.pen.thickness); switchTool(toolHandlers.manipulate, { target: state.activeShape }); } },
        manipulate: { target: null, handle: null, lastPos: null, onActivate(options) { this.target = options.target; }, onPointerDown(e, pos) { this.handle = this.target.getHandleAt(pos); this.lastPos = pos; }, onPointerMove(e, pos) { const dx = pos.x - this.lastPos.x; const dy = pos.y - this.lastPos.y; if (this.handle) { const t = this.target; if (this.handle === 'rot') t.rotation += Math.atan2(pos.y - t.getCenter().y, pos.x - t.getCenter().x) - Math.atan2(this.lastPos.y - t.getCenter().y, this.lastPos.x - t.getCenter().x); else { const unrotatedDx = dx * Math.cos(-t.rotation) - dy * Math.sin(-t.rotation); const unrotatedDy = dx * Math.sin(-t.rotation) + dy * Math.cos(-t.rotation); if (this.handle.includes('l')) { t.x += unrotatedDx; t.w -= unrotatedDx; } if (this.handle.includes('t')) { t.y += unrotatedDy; t.h -= unrotatedDy; } if (this.handle.includes('r')) { t.w += unrotatedDx; } if (this.handle.includes('b')) { t.h += unrotatedDy; } } } else if (this.target.isPointInside(pos)) { this.target.x += dx; this.target.y += dy; } this.lastPos = pos; }, onPointerUp() { /* Manipulation ends */ }, draw(tctx) { if (this.target) this.target.draw(tctx, true); } }
    };

    // -- Data Persistence --
    const saveNotebook = debounce(() => {
        console.log("Autosaving...");
        const notebookData = {
            pages: state.pages.map(p => {
                const pageCopy = { ...p, drawingCache: null }; // Don't save canvas elements
                // For images, convert Image element to src string
                pageCopy.strokes = pageCopy.strokes.map(s => {
                    if (s.tool.tool === 'image') {
                        return { ...s, points: [{ ...s.points[0], image: s.points[0].image.src }] };
                    }
                    return s;
                });
                return pageCopy;
            }),
        };
        const content = JSON.stringify(notebookData);
        window.electron.updateNoteContent({ id: CURRENT_NOTE_ID, content });
    });

    function debounce(func, timeout = 1000) {
        let timer;
        return (...args) => {
            clearTimeout(timer);
            timer = setTimeout(() => { func.apply(this, args); }, timeout);
        };
    }

    function markDirty() {
        saveNotebook();
    }

    async function loadNotebook() {
        try {
            const note = await window.electron.getNote(CURRENT_NOTE_ID);
            if (note && note.content) {
                const notebookData = JSON.parse(note.content);
                state.pages = notebookData.pages || [];
                // Recreate drawing caches and Image elements
                state.pages.forEach(page => {
                    page.drawingCache = document.createElement('canvas');
                    page.strokes.forEach(s => {
                        if (s.tool.tool === 'image') {
                            const img = new Image();
                            img.src = s.points[0].image;
                            s.points[0].image = img; // Replace src with Image element
                        }
                    });
                    redrawPageCache(page);
                });
                recalculatePagePositions();
                requestRedraw();
            } else {
                // If no content, start with a fresh page
                addPageToEnd();
            }
        } catch (err) {
            let msg = 'Error loading notebook.';
            if (err.message && err.message.includes('net::ERR_INTERNET_DISCONNECTED')) {
                msg = 'Network error: Please check your internet connection.';
            } else if (err.message && err.message.includes('ENOTFOUND')) {
                msg = 'Network error: Database server not found.';
            } else if (err.message && err.message.includes('EACCES')) {
                msg = 'File system error: Permission denied.';
            } else if (err.message && err.message.includes('EIO')) {
                msg = 'File system error: I/O error occurred.';
            }
            // Show error in a visible, non-blocking way
            if (updateDiv) {
                updateDiv.style.display = 'block';
                updateDiv.style.background = '#c0392b';
                updateDiv.style.color = '#fff';
                updateDiv.style.fontWeight = 'bold';
                updateDiv.style.border = '2px solid #e74c3c';
                updateDiv.style.boxShadow = '0 2px 8px #e74c3c44';
                updateDiv.style.zIndex = 1000;
                updateDiv.textContent = msg;
            }
        }
    }

    // -- Core Logic --
    function insertPage() {
        const newPage = { width: 794, height: 1123, strokes: [], drawingCache: document.createElement('canvas') };
        if (state.pages.length === 0) {
            state.pages.push(newPage);
            state.currentPageIndex = 0;
        } else {
            state.pages.splice(state.currentPageIndex + 1, 0, newPage);
            state.currentPageIndex++;
        }
        recalculatePagePositions();
        markDirty();
    }
    function commit(item) { const page = findPageAt(item.x, item.y); if (page) { const pageItem = { ...item, x: item.x - page.x, y: item.y - page.y }; page.strokes.push({ points: [pageItem], tool: { tool: item.type } }); redrawPageCache(page); } state.activeObject = null; requestRedraw(); markDirty(); }
    function commitStroke(stroke) { if (stroke.length < 2) return; const page = findPageAt(stroke[0].x, stroke[0].y); if (page) { const pageStroke = { points: stroke.map(p => ({ x: p.x - page.x, y: p.y - page.y, pressure: p.pressure })), tool: { ...state.pen, tool: 'pen' } }; page.strokes.push(pageStroke); redrawPageCache(page); } markDirty(); }
    function redrawPageCache(page) { const c = page.drawingCache; const cctx = c.getContext('2d'); c.width = page.width; c.height = page.height; cctx.clearRect(0, 0, c.width, c.height); page.strokes.forEach(s => renderStroke(cctx, s.points, s.tool, false)); requestRedraw(); }

    // -- Render --
    let redrawRequested = true;
    function requestRedraw() { redrawRequested = true; }
    function render() {
        ctx.l.clearRect(0, 0, canvases.live.width, canvases.live.height);
        ctx.t.clearRect(0, 0, canvases.tool.width, canvases.tool.height);
        if (state.activeToolHandler && state.activeToolHandler.draw) state.activeToolHandler.draw(ctx.l, ctx.t);
        if (state.activeGuide) state.activeGuide.draw(ctx.t);
        if (state.activeShape) state.activeShape.draw(ctx.t, true);
        if (state.activeObject && state.activeObject.type === 'image') state.activeObject.draw(ctx.t, true);
        if (redrawRequested) { ctx.p.clearRect(0, 0, canvases.pages.width, canvases.pages.height); ctx.d.clearRect(0, 0, canvases.drawing.width, canvases.drawing.height); ctx.p.save(); ctx.d.save(); ctx.p.translate(state.panX, state.panY); ctx.d.translate(state.panX, state.panY); ctx.p.scale(state.zoom, state.zoom); ctx.d.scale(state.zoom, state.zoom); state.pages.forEach(page => { ctx.p.fillStyle = '#FFF'; ctx.p.fillRect(page.x, page.y, page.width, page.height); ctx.d.drawImage(page.drawingCache, page.x, page.y); }); ctx.p.restore(); ctx.d.restore(); redrawRequested = false; }
        requestAnimationFrame(render);
    }
    function renderStroke(ctx, points, tool, isLive) {
        if (tool.tool === 'shape' || tool.tool === 'image') {
            const s = points[0];
            let item;
            if (tool.tool === 'image') {
                item = new ImageObject(s.x, s.y, s.w, s.h, s.image);
            } else {
                item = new Shape(s.type, s.x, s.y, s.w, s.h, s.color, s.thickness);
            }
            item.rotation = s.rotation;
            item.draw(ctx);
            return;
        }
        if (points.length < 2) return; ctx.save(); if (isLive) { ctx.translate(state.panX, state.panY); ctx.scale(state.zoom, state.zoom); } ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.strokeStyle = tool.color || '#000'; ctx.globalAlpha = tool.opacity || 1; ctx.beginPath(); ctx.moveTo(points[0].x, points[0].y); for (let i = 1; i < points.length; i++) { ctx.lineWidth = tool.style === 'brush' ? tool.thickness * points[i].pressure : tool.thickness; ctx.lineTo(points[i].x, points[i].y); } ctx.stroke(); ctx.restore(); }

    // -- Event Handlers & Tool Switching --
    function setupEventListeners() {
        toolbar.penToolBtn.addEventListener('click', () => switchTool(toolHandlers.pen, toolbar.penToolBtn));
        toolbar.eraserToolBtn.addEventListener('click', () => switchTool(toolHandlers.eraser, toolbar.eraserToolBtn));
        toolbar.laserToolBtn.addEventListener('click', () => switchTool(toolHandlers.laser, toolbar.laserToolBtn));
        toolbar.shapeToolBtn.addEventListener('click', () => {
            toolbar.shapeOptions.style.display = 'block';
            updateActiveButton(toolbar.shapeToolBtn);
        });
        document.querySelectorAll('.shape-type-btn').forEach(btn => btn.addEventListener('click', () => { 
            switchTool(toolHandlers.defineShape, { shapeType: btn.dataset.shape }); 
            toolbar.shapeOptions.style.display = 'none'; 
        }));
        toolbar.rulerToolBtn.addEventListener('click', () => toggleGuide('ruler'));
        toolbar.setSquareToolBtn.addEventListener('click', () => toggleGuide('setSquare'));
        toolbar.compassToolBtn.addEventListener('click', () => toggleGuide('compass'));
        toolbar.commitShapeBtn.addEventListener('click', () => { if (state.activeObject) { commit(state.activeObject); } switchTool(toolHandlers.pen, toolbar.penToolBtn); });
        canvases.tool.addEventListener('pointerdown', (e) => { const pos = getMousePos(e); const activeObject = state.activeShape || state.activeGuide || state.activeObject; if (activeObject && activeObject.getHandleAt(pos)) { switchTool(toolHandlers.manipulate, { target: activeObject }); } if (state.activeToolHandler && state.activeToolHandler.onPointerDown) state.activeToolHandler.onPointerDown(e, pos); });
        canvases.tool.addEventListener('pointermove', (e) => { const pos = getMousePos(e); if (state.activeToolHandler && state.activeToolHandler.onPointerMove) state.activeToolHandler.onPointerMove(e, pos); updateCursor(e, pos); });
        canvases.tool.addEventListener('pointerup', (e) => { const pos = getMousePos(e); if (state.activeToolHandler && state.activeToolHandler.onPointerUp) state.activeToolHandler.onPointerUp(e, pos); });
        window.addEventListener('resize', resizeCanvases);

        // Page Management
        toolbar.insertPageBtn.addEventListener('click', insertPage);

        // Image Upload
        toolbar.addImageBtn.addEventListener('click', () => toolbar.imageUploadInput.click());
        toolbar.imageUploadInput.addEventListener('change', (e) => { if (e.target.files.length > 0) loadImage(e.target.files[0]); });
        canvases.tool.addEventListener('dragover', (e) => e.preventDefault());
        canvases.tool.addEventListener('drop', (e) => { e.preventDefault(); if (e.dataTransfer.files.length > 0) loadImage(e.dataTransfer.files[0]); });

        // PDF Export
        toolbar.exportPdfBtn.addEventListener('click', exportToPDF);

        // Tab Switching
        tabLinks.forEach(link => {
            link.addEventListener('click', () => {
                const tab = link.dataset.tab;
                tabLinks.forEach(l => l.classList.remove('active'));
                link.classList.add('active');
                Object.values(tabContents).forEach(content => content.classList.remove('active'));
                tabContents[tab.split('-')[0]].classList.add('active');
                if (tab === 'help-view' && !helpContentLoaded) {
                    loadHelpContent();
                }
            });
        });
    }

    function updateActiveButton(activeButton) {
        const toolButtons = [
            toolbar.penToolBtn,
            toolbar.eraserToolBtn,
            toolbar.laserToolBtn,
            toolbar.shapeToolBtn,
            toolbar.rulerToolBtn,
            toolbar.setSquareToolBtn,
            toolbar.compassToolBtn,
        ];
        toolButtons.forEach(button => {
            if (button) {
                button.classList.remove('active');
            }
        });
        if (activeButton) {
            activeButton.classList.add('active');
        }
    }

    function switchTool(handler, activeButton, options = {}) { 
        if (state.activeToolHandler && state.activeToolHandler.onDeactivate) state.activeToolHandler.onDeactivate(); 
        state.activeToolHandler = handler; 
        if (state.activeToolHandler && state.activeToolHandler.onActivate) state.activeToolHandler.onActivate(options);
        updateActiveButton(activeButton);
    }
    function toggleGuide(guideType) { if (state.activeGuide?.type === guideType) { state.activeGuide = null; } else { const GuideClass = { ruler: Ruler, setSquare: SetSquare, compass: Compass }[guideType]; state.activeGuide = new GuideClass(300, 300); state.activeGuide.type = guideType; } requestRedraw(); }
    function updateCursor(e, pos) { let cursor = 'default'; const activeObject = state.activeShape || state.activeGuide || state.activeObject; if (activeObject) { const handle = activeObject.getHandleAt(pos); if (handle) { cursor = handle === 'rot' ? 'grab' : 'pointer'; } else if (activeObject.isPointInside(pos)) { cursor = 'move'; } } canvases.tool.style.cursor = cursor; }

    // -- Utility --
    function getMousePos(evt) { const rect = canvases.tool.getBoundingClientRect(); return { x: evt.clientX - rect.left, y: evt.clientY - rect.top }; }
    function findPageAt(x, y) { const worldPos = { x: (x - state.panX) / state.zoom, y: (y - state.panY) / state.zoom }; return state.pages.find(p => worldPos.x >= p.x && worldPos.x <= p.x + p.width && worldPos.y >= p.y && worldPos.y <= p.y + p.height); }
    function getSnappedPos(pos, pressure) { if (!state.activeGuide) return { ...pos, pressure: pressure || 0.5 }; const r = state.activeGuide; const center = r.getCenter(); const unrotatedPos = r.rotatePoint(pos, center, -r.rotation); const topEdgeY = r.y; const bottomEdgeY = r.y + r.h; if (Math.abs(unrotatedPos.y - topEdgeY) < 20) unrotatedPos.y = topEdgeY; else if (Math.abs(unrotatedPos.y - bottomEdgeY) < 20) unrotatedPos.y = bottomEdgeY; const snappedPos = r.rotatePoint(unrotatedPos, center, r.rotation); return { ...snappedPos, pressure: pressure || 0.5 }; }
    function recalculatePagePositions() { let y = 20; state.pages.forEach(p => { p.width = 794; p.height = 1123; p.x = (canvases.pages.width / 2) - (p.width / 2); p.y = y; y += p.height + 20; }); }
    function resizeCanvases() { const { width, height } = document.getElementById('canvas-container').getBoundingClientRect(); Object.values(canvases).forEach(c => { c.width = width; c.height = height; }); recalculatePagePositions(); requestRedraw(); }

    // -- Image Loading --
    function loadImage(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            const img = new Image();
            img.onload = () => {
                const { width, height } = canvases.tool.getBoundingClientRect();
                const aspectRatio = img.width / img.height;
                const newWidth = 300;
                const newHeight = newWidth / aspectRatio;
                state.activeObject = new ImageObject(width / 2 - newWidth / 2, height / 2 - newHeight / 2, newWidth, newHeight, img);
                switchTool(toolHandlers.manipulate, { target: state.activeObject });
                requestRedraw();
            };
            img.src = e.target.result;
        };
        reader.readAsDataURL(file);
    }

    // -- PDF Export --
    async function exportToPDF() {
        const doc = new jsPDF({
            orientation: 'p',
            unit: 'pt',
            format: 'a4'
        });

        for (let i = 0; i < state.pages.length; i++) {
            const page = state.pages[i];
            const tempCanvas = document.createElement('canvas');
            const tempCtx = tempCanvas.getContext('2d');
            tempCanvas.width = page.width;
            tempCanvas.height = page.height;

            tempCtx.fillStyle = page.color || '#FFFFFF';
            tempCtx.fillRect(0, 0, page.width, page.height);

            const c = page.drawingCache;
            tempCtx.drawImage(c, 0, 0);

            const imgData = tempCanvas.toDataURL('image/png');
            const pdfWidth = doc.internal.pageSize.getWidth();
            const pdfHeight = doc.internal.pageSize.getHeight();
            
            if (i > 0) doc.addPage();
            doc.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
        }

        doc.save('notebook.pdf');
    }

    // -- Init --
    function init() {
        resizeCanvases();
        setupEventListeners();
        loadNotebook();
        switchTool(toolHandlers.pen, toolbar.penToolBtn);
        render();
    }

    init();
});