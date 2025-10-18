# Quick Reference Guide - PDF Annotation Features

## 🎨 Drawing Tools

### Pen Tool
- **Icon**: ✏️ Edit icon
- **Default Color**: Black
- **Stroke Width Range**: 1.0 - 10.0
- **Usage**: Draw permanent ink annotations
- **Color**: Independent color picker (supports RGB/HSV)

### Highlighter Tool  
- **Icon**: 🖍️ Highlight icon
- **Default Color**: Yellow with 50% transparency
- **Stroke Width Range**: 8.0 - 20.0
- **Usage**: Create semi-transparent highlights
- **Color**: Independent color picker with alpha channel support

### Eraser Tool
- **Icon**: ✨ Auto-fix icon
- **Color**: Fixed light gray (cannot be changed)
- **Usage**: Remove ink strokes and image annotations
- **Behavior**: 
  - Shows light gray stroke while erasing (visual feedback only)
  - Removes intersecting ink strokes
  - Removes overlapping images
  - Eraser stroke is NOT saved

## 🖼️ Image Annotations

### Adding Images

**Method 1: File Picker**
1. Click the 📷 "Insert Image" button in toolbar
2. Select an image file (PNG, JPG, etc.)
3. Image appears centered on the page

**Method 2: Clipboard** (Keyboard Shortcut)
1. Copy an image to clipboard (Ctrl+C / Cmd+C)
2. Press `Ctrl+V` (Windows/Linux) or `Cmd+V` (Mac) while viewing PDF
3. Image is inserted from clipboard

### Moving Images
1. Tap an image to select it (blue border and handles appear)
2. Drag anywhere on the image to move it
3. Movement is **smooth and continuous** - no snapping to grid
4. Image stays within page boundaries

### Resizing Images
1. Tap an image to select it
2. Drag any of the **4 corner handles**:
   - **Top-Left**: Resize from top-left corner
   - **Top-Right**: Resize from top-right corner
   - **Bottom-Left**: Resize from bottom-left corner
   - **Bottom-Right**: Resize from bottom-right corner
3. Resizing is **smooth and free** - no step quantization
4. Minimum size: 50x50 to prevent images becoming too small

### Deleting Images
1. Select an image (tap it)
2. Tap the ❌ red close button in the top-right corner
3. Confirmation is immediate

### Deselecting Images
- **Tap anywhere outside** the selected image
- Selection handles and border disappear
- Image position and size are automatically saved

## 🎨 Color Management

### Pen Color
1. Select the Pen tool (✏️)
2. Tap the ▼ arrow to expand settings
3. Tap the color circle to open color picker
4. Choose color using RGB/HSV sliders
5. Pen remembers this color even when switching tools

### Highlighter Color
1. Select the Highlighter tool (🖍️)
2. Tap the ▼ arrow to expand settings
3. Tap the color circle to open color picker
4. Choose color and adjust alpha (transparency)
5. Highlighter remembers this color independently

### Important: Independent Colors
- **Pen** and **Highlighter** have separate color memories
- Changing pen color **does NOT affect** highlighter color
- Changing highlighter color **does NOT affect** pen color
- Eraser color is **always fixed** at light gray

## ⚙️ Toolbar Features

### Tool Settings
- Click the ▼ arrow on **Pen** or **Highlighter** to show:
  - Color preview circle (tap to change)
  - Stroke width slider
  - Visual preview of current stroke

### Action Buttons

| Icon | Action | Description |
|------|--------|-------------|
| ↶ | Undo | Remove last annotation stroke |
| ↷ | Redo | Restore last undone stroke |
| 📷 | Insert Image | Add image from file |
| 🗑️ | Clear | Remove all annotations from current page |
| 💾 | Save | Manually save annotations (auto-saves after 3 seconds) |

## 🔄 Coordinate Transformation

All annotations (ink and images) use **PDF coordinate system**:
- ✅ Annotations stick to PDF content during zoom
- ✅ Annotations move with page during scroll
- ✅ Positions are saved in PDF space (not screen pixels)
- ✅ Zoom in/out - annotations scale correctly
- ✅ Save and reload - annotations appear in exact positions

## 💾 Data Persistence

### Auto-Save
- Annotations are **automatically saved** 3 seconds after last edit
- Orange dot indicator shows unsaved changes
- No manual save required (but available)

### Manual Save
- Click 💾 Save button to force immediate save
- Useful before closing app or switching PDFs

### Save Location
- Annotations saved as `.annotations.json` file next to PDF
- Example: `document.pdf` → `document.pdf.annotations.json`
- JSON format includes:
  - Ink strokes with coordinates and properties
  - Images with bytes, position, size
  - Page numbers for all annotations

## 🎯 Best Practices

### For Smooth Performance
1. Use **Pen** for detailed line work (1-10 width)
2. Use **Highlighter** for broad emphasis (8-20 width)
3. **Deselect images** when done editing (tap outside)
4. **Clear unused annotations** to reduce file size

### For Accurate Annotations
1. **Zoom in** before making detailed annotations
2. **Position images** carefully - they use PDF coordinates
3. **Test zoom/scroll** after adding images to verify positioning
4. **Save frequently** using manual save button

### For Large Documents
1. Annotations are saved **per page** (efficient loading)
2. Clear pages you no longer need annotated
3. Use **eraser** to remove unwanted marks instead of clearing entire page

## 🐛 Troubleshooting

### Issue: Image "jumps" when moving
- **Fixed**: Movement is now smooth and continuous
- If still occurring, try selecting the image again

### Issue: Image doesn't stay in correct position after zoom
- **Fixed**: Images now use PDF coordinate transformation
- Position is saved in PDF space, not screen space

### Issue: Can't change eraser color
- **Expected**: Eraser color is fixed at light gray
- Use Pen or Highlighter if you need different colors

### Issue: Annotations lost after closing app
- Check for `.annotations.json` file next to PDF
- Ensure PDF is not read-only
- Use manual save button before closing

### Issue: PDFium WASM warning on web
- **Expected** during debug/development
- See `PDFRX_PRODUCTION_NOTES.md` for production configuration
- No action needed for mobile/desktop builds

## 🚀 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+V` / `Cmd+V` | Paste image from clipboard |
| `Ctrl+Z` / `Cmd+Z` | Undo last annotation *(coming soon)* |
| `Ctrl+Y` / `Cmd+Y` | Redo last undo *(coming soon)* |

## 📱 Platform-Specific Notes

### Windows
- ✅ Full touch support for tablets with stylus
- ✅ Mouse support for desktop
- ✅ Multi-touch zoom/pan gestures

### Android/iOS
- ✅ Touch and stylus support (Apple Pencil, S-Pen)
- ✅ Multi-finger gestures for zoom/pan
- ✅ Image insertion via file picker and clipboard

### Web
- ✅ Mouse and touch support
- ⚠️ PDFium WASM bundled in debug (see notes)
- ✅ All annotation features available

---

## 📚 Additional Documentation

- **IMPROVEMENTS_SUMMARY.md** - Technical implementation details
- **PDFRX_PRODUCTION_NOTES.md** - Production build configuration
- **ARCHITECTURE.md** - Application architecture overview
- **VIEWER_IMPLEMENTATION.md** - PDF viewer implementation guide

---

**Version**: 1.0.0  
**Last Updated**: October 14, 2025
