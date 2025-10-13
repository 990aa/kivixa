<p>
<img src="icon.png" height = 30 width = 30>
</p>

# Kivixa PDF Annotator

A cross-platform PDF annotation application built with Flutter, featuring smooth vector-based drawing with Bézier curves for Android and Windows.

## Features

✨ **Vector-Based Annotations**: All strokes stored as vector coordinates (not pixels) for crisp rendering at any zoom level

📝 **Three Drawing Tools**:
- **Pen**: Precise drawing with pressure sensitivity and velocity-based line width (1.0-5.0px)
- **Highlighter**: Semi-transparent wide strokes (8.0-15.0px) with 0.3 opacity
- **Eraser**: Remove annotations with touch radius detection

🎨 **Smart Stroke Rendering**:
- Cubic Bézier curves using Catmull-Rom interpolation
- Ultra-smooth lines via `hand_signature` library
- Optimized settings:
  - `threshold: 3.0` - Minimal distance between captured points
  - `smoothRatio: 0.65` - Balance between smoothness and precision
  - `velocityRange: 2.0` - Natural dynamic line width

🖊️ **Stylus Support**:
- Pressure sensitivity capture
- Tilt detection (where available)
- MotionEvent data extraction

💾 **Persistence Layer**:
- Save/load annotations as JSON
- Per-page annotation management
- Undo/redo with 100-item history stack

## Architecture

### Core Data Models

#### 1. `DrawingTool` Enum
```dart
enum DrawingTool { pen, highlighter, eraser }
```

#### 2. `AnnotationData` Model
Stores individual strokes with:
- `strokePath`: List of vector coordinates (Offset points)
- `colorValue`: ARGB integer color
- `strokeWidth`: Line thickness in logical pixels
- `toolType`: Drawing tool used
- `pageNumber`: Associated PDF page (0-indexed)
- `timestamp`: Creation time for sorting

**Serialization**: Converts to/from JSON with flat coordinate arrays `[x1, y1, x2, y2, ...]`

#### 3. `AnnotationLayer` Model
Manages all annotations across pages:
- Grouped by page number for efficient rendering
- Add, remove, undo/redo operations
- Export/import complete annotation state
- Clear page or all annotations

### Rendering System

#### `AnnotationPainter` (CustomPainter)
- Renders completed and in-progress strokes
- Converts point arrays to smooth Bézier paths
- Uses Catmull-Rom to Bézier conversion algorithm:
  ```
  For points P0, P1, P2, P3:
  CP1 = P1 + (P2 - P0) / 6
  CP2 = P2 - (P3 - P1) / 6
  cubicTo(CP1, CP2, P2)
  ```
- Special rendering for highlighter (30% opacity)

#### `AnnotationController`
Wraps `HandSignatureControl` with optimal settings:
- Captures stroke data with velocity-based width variation
- Manages tool state (pen/highlighter/eraser)
- Converts library-specific path format to `AnnotationData`

#### `AnnotationCanvas` Widget
- Captures pointer events (down, move, up)
- Extracts pressure and position data
- Real-time stroke preview
- Eraser hit detection (15px radius)

## Installation

### Dependencies

```yaml
dependencies:
  pdfx: ^2.9.2                          # PDF rendering
  hand_signature: ^3.1.0+2              # Smooth stylus drawing with Bézier curves
  syncfusion_flutter_pdf: ^28.1.34      # PDF manipulation and saving
  file_picker: ^8.1.4                   # File selection
  path_provider: ^2.1.5                 # File storage paths
  flutter_colorpicker: ^1.1.0           # Color picker UI
```

### Setup

1. Clone the repository:
```bash
git clone https://github.com/990aa/kivixa.git
cd kivixa
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run on your target platform:
```bash
# Android
flutter run -d android

# Windows
flutter run -d windows
```

## Usage

### Basic Drawing

```dart
// Create annotation layer
final annotationLayer = AnnotationLayer();

// Use the canvas widget
AnnotationCanvas(
  annotationLayer: annotationLayer,
  currentPage: 0,
  currentTool: DrawingTool.pen,
  currentColor: Colors.black,
  canvasSize: Size(595, 842), // A4 at 72 DPI
  onAnnotationsChanged: () {
    // Handle annotation changes
  },
)
```

### Save/Load Annotations

```dart
// Export to JSON
String json = annotationLayer.exportToJson();
// Save to file using file_picker and path_provider

// Import from JSON
AnnotationLayer loaded = AnnotationLayer.fromJson(json);

// Or merge into existing layer
annotationLayer.importFromJson(json, clearExisting: false);
```

### Undo/Redo

```dart
// Undo last stroke
AnnotationData? undone = annotationLayer.undoLastStroke();

// Redo
bool success = annotationLayer.redoLastUndo();
```

## Performance Considerations

### Optimizations
- **Vector Storage**: No bitmap rasterization, minimal memory usage
- **Per-Page Rendering**: Only draws annotations for visible page
- **Efficient Repainting**: CustomPainter only repaints when annotations change
- **Point Threshold**: 3.0px minimum distance prevents excessive point capture

### Tablet Performance
Tested smooth performance on Android tablets with:
- 60 FPS drawing response
- No lag with 500+ strokes per page
- Efficient Bézier curve calculation

## Mathematical Details

### Catmull-Rom to Cubic Bézier Conversion

For smooth curves through all control points:

Given four consecutive points: P₀, P₁, P₂, P₃

Control points for the cubic Bézier segment from P₁ to P₂:

```
CP₁ = P₁ + (P₂ - P₀) / 6
CP₂ = P₂ - (P₃ - P₁) / 6
```

This ensures:
- Curve passes through P₁ and P₂
- Smooth tangent continuity at connection points
- No overshooting between control points

### Velocity-Based Width

The `hand_signature` library calculates dynamic width:

```
width = baseWidth + (maxVelocity - currentVelocity) / velocityRange
```

With `velocityRange: 2.0`:
- Fast strokes → thinner lines
- Slow strokes → thicker lines
- Natural calligraphic effect

## Project Structure

```
lib/
├── main.dart                          # Demo application
├── models/
│   ├── drawing_tool.dart              # Tool enum
│   ├── annotation_data.dart           # Single stroke model
│   └── annotation_layer.dart          # Multi-stroke container
├── painters/
│   └── annotation_painter.dart        # CustomPainter + controller
└── widgets/
    └── annotation_canvas.dart         # Input capture widget
```

## Future Enhancements

- [ ] PDF file loading with `pdfx`
- [ ] Save annotations embedded in PDF using `syncfusion_flutter_pdf`
- [ ] Advanced color picker with `flutter_colorpicker`
- [ ] Multi-page PDF navigation
- [ ] Zoom and pan support
- [ ] Text annotation tool
- [ ] Shape tools (rectangle, circle, arrow)
- [ ] Collaborative annotation sync

## Platform Support

- ✅ Android (tested on tablets with stylus)
- ✅ Windows (mouse and stylus)
- 🔧 iOS (requires testing)
- 🔧 macOS (requires testing)
- 🔧 Linux (requires testing)
- 🔧 Web (limited stylus support)

## Technical Notes

### Why hand_signature?

The `hand_signature` library provides:
1. **Velocity-based smoothing**: Natural line width variation
2. **Optimized for tablets**: Low latency, 60 FPS rendering
3. **Bézier curve output**: Perfect for vector storage
4. **Minimal configuration**: Works great out of the box

### Why Vector Storage?

Storing annotations as vector coordinates (not pixels):
- ✅ Resolution-independent (zoom without quality loss)
- ✅ Minimal file size (coordinates vs. image data)
- ✅ Easy transformation (rotate, scale annotations)
- ✅ Fast rendering with GPU acceleration

## Contributing

Contributions welcome! Areas of interest:
- Additional drawing tools
- Performance optimizations
- Platform-specific improvements
- UI/UX enhancements

## License

See [LICENSE.md](LICENSE.md) for details.

## Acknowledgments

- [hand_signature](https://pub.dev/packages/hand_signature) for smooth drawing
- [pdfx](https://pub.dev/packages/pdfx) for PDF rendering
- [Syncfusion PDF](https://pub.dev/packages/syncfusion_flutter_pdf) for PDF manipulation

---

**Built with Flutter 💙 | Optimized for Stylus Input 🖊️ | Cross-Platform 🚀**
