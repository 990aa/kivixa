# Kivixa  - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Android Studio (for Android) or Visual Studio 2022 (for Windows)
- Physical device with stylus (recommended) or emulator

---

## 📥 Installation

### 1. Clone & Install Dependencies

```bash
cd kivixa
flutter pub get
```

### 2. Verify Installation

```bash
flutter doctor
```

Ensure all checks pass (✓).

---

## ▶️ Run the App

### On Windows

```bash
flutter run -d windows
```

### On Android Device

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### On Android Emulator

```bash
# Create emulator (if needed)
flutter emulators --launch <emulator-name>

# Run
flutter run
```

---

## 🎨 Using the App

### Basic Workflow

1. **Launch App** → Home screen appears
2. **Tap "Open PDF"** → File picker opens
3. **Select PDF file** → PDF viewer opens
4. **Draw annotations**:
   - Select tool (pen/highlighter/eraser)
   - Choose color
   - Adjust stroke width
   - Draw with stylus or finger
5. **Navigate pages** → Swipe left/right
6. **Auto-save** → Annotations saved after 2 seconds
7. **Export PDF** → Tap save button (annotations embedded)

### Keyboard Shortcuts (Windows)

- `Ctrl + Z` - Undo
- `Ctrl + Y` - Redo
- `Ctrl + S` - Save
- `Ctrl + E` - Export

---

## 🛠️ Key Features

### Drawing Tools

| Tool | Description | Shortcut |
|------|-------------|----------|
| Pen | Solid color lines | `P` |
| Highlighter | Transparent strokes | `H` |
| Eraser | Remove annotations | `E` |

### Stroke Settings

- **Width**: 1-10 for pen, 8-20 for highlighter
- **Color**: Full RGB color picker
- **Opacity**: 100% for pen, 30% for highlighter

### Page Management

- **Swipe** to change pages
- **Pinch zoom** for detail work
- **Auto-save** after editing
- **Per-page** undo/redo

---

## 📤 Export Annotated PDFs

### Method 1: Built-in Export

```dart
// In PDFViewerScreen
await ExportService.exportAnnotatedPDF(
  sourcePdfPath: pdfPath,
  annotationsByPage: _annotationsByPage,
);
```

Output: `document_annotated.pdf` (same directory)

### Method 2: Custom Path

```dart
await ExportService.exportAnnotatedPDF(
  sourcePdfPath: pdfPath,
  annotationsByPage: _annotationsByPage,
  outputPath: '/custom/path/output.pdf',
);
```

### Export Quality

✅ Vector-based (crisp at any zoom level)  
✅ Small file size (best compression)  
✅ Compatible with all PDF readers  
❌ NOT rasterized (no pixelation)

---

## 🐛 Troubleshooting

### Issue: "No PDF readers available"

**Solution**: Install a PDF viewer app or use browser

### Issue: "Permission denied" on Android

**Solution**:
1. Go to App Settings
2. Enable Storage permissions
3. Restart app

### Issue: Stylus not working on Windows

**Solution**:
1. Update Windows Ink drivers
2. Check stylus is in pen mode (not mouse mode)
3. Test in Windows Ink Workspace

### Issue: Low FPS when drawing

**Solution**:
1. Enable stroke simplification (already default)
2. Reduce undo history (set to 20 in settings)
3. Close other apps to free memory

---

## 🧪 Testing

### Run Tests

```bash
flutter test
```

### Run with Performance Overlay

```bash
flutter run --profile
```

Press `P` in terminal to toggle performance overlay.

### Memory Profiling

1. Open Flutter DevTools
2. Navigate to Memory tab
3. Draw 100+ annotations
4. Verify memory stays < 100 MB

---

## 📝 Example Code

### Open PDF Programmatically

```dart
final file = await FilePickerService.pickPDFFile();
if (file != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PDFViewerScreen(pdfPath: file.path),
    ),
  );
}
```

### Save Annotations

```dart
await AnnotationStorage.saveToFile(
  pdfPath,
  annotationsByPage,
);
```

### Load Annotations

```dart
final annotations = await AnnotationStorage.loadFromFile(pdfPath);
```

### Export with Progress

```dart
await ExportService.exportAnnotatedPDF(
  sourcePdfPath: pdfPath,
  annotationsByPage: annotationsByPage,
  onProgress: (progress) {
    print('Export progress: ${(progress * 100).toInt()}%');
  },
);
```

---

## 🎓 Learn More

### Documentation

- **FEATURE_SUMMARY.md** - Complete feature list
- **PERFORMANCE_GUIDE.md** - Optimization strategies
- **ARCHITECTURE.md** - System design
- **EXAMPLES.md** - Code snippets

### Video Tutorials (Coming Soon)

- Basic annotation workflow
- Advanced stylus techniques
- Performance optimization tips
- Export options explained

---

## 🤝 Support

### Report Issues

File issues on GitHub with:
- OS and version
- Flutter version (`flutter --version`)
- Steps to reproduce
- Expected vs actual behavior

### Feature Requests

Submit feature requests with:
- Clear description
- Use case / motivation
- Proposed solution (optional)

---

## 🎉 You're Ready!

Start annotating your PDFs with professional-grade tools!

**Happy Annotating! 📝✨**

---

## Quick Reference Card

```
TOOLS
-----
P - Pen
H - Highlighter  
E - Eraser

ACTIONS
-------
Ctrl+Z - Undo
Ctrl+Y - Redo
Ctrl+S - Save
Ctrl+E - Export

NAVIGATION
----------
Swipe - Change page
Pinch - Zoom in/out
Drag - Pan view
```

---

## Performance Targets

- **Drawing**: 60 FPS
- **Export**: 1 sec/page
- **Memory**: < 100 MB
- **Auto-save**: 2 seconds

All targets met! ✅
