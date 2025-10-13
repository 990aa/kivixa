# Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Kivixa PDF Annotator                     │
│                     Cross-Platform Flutter App                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          UI Layer (main.dart)                    │
├─────────────────────────────────────────────────────────────────┤
│  • PDFAnnotatorDemo Widget                                       │
│  • Toolbar (tool/color selection)                                │
│  • Action buttons (undo/redo/clear)                              │
│  • Annotation statistics                                         │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Widget Layer (annotation_canvas.dart)          │
├─────────────────────────────────────────────────────────────────┤
│  AnnotationCanvas                                                │
│  ├─ Listener (pointer events)                                    │
│  ├─ CustomPaint (rendering)                                      │
│  └─ Container (layout)                                           │
│                                                                   │
│  Responsibilities:                                               │
│  • Capture touch/stylus input                                    │
│  • Extract pressure & position data                              │
│  • Manage real-time stroke preview                               │
│  • Handle eraser hit detection                                   │
└───────────────┬────────────────────────┬────────────────────────┘
                │                        │
                ▼                        ▼
┌───────────────────────────┐  ┌──────────────────────────────────┐
│  Rendering Layer          │  │  Input Processing                │
│  (annotation_painter.dart)│  │  (annotation_painter.dart)       │
├───────────────────────────┤  ├──────────────────────────────────┤
│  AnnotationPainter        │  │  AnnotationController            │
│  (CustomPainter)          │  │  (HandSignatureControl wrapper)  │
│                           │  │                                  │
│  • Render completed       │  │  • Manage hand_signature         │
│    strokes                │  │  • Configure smoothing           │
│  • Render current stroke  │  │  • Convert paths to              │
│  • Bézier curve creation  │  │    AnnotationData                │
│  • Highlighter opacity    │  │  • Tool-specific settings        │
│  • Efficient repainting   │  │  • Stroke completion callback    │
└───────────┬───────────────┘  └──────────────┬───────────────────┘
            │                                 │
            │                                 │
            └──────────┬──────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Data Model Layer                              │
│                    (models/*.dart)                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────┐  ┌────────────────────┐                │
│  │  DrawingTool       │  │  AnnotationData    │                │
│  │  (Enum)            │  │  (Model)           │                │
│  ├────────────────────┤  ├────────────────────┤                │
│  │  • pen             │  │  • strokePath      │                │
│  │  • highlighter     │  │  • colorValue      │                │
│  │  • eraser          │  │  • strokeWidth     │                │
│  └────────────────────┘  │  • toolType        │                │
│                          │  • pageNumber      │                │
│                          │  • timestamp       │                │
│                          │  • toJson()        │                │
│                          │  • fromJson()      │                │
│                          └────────────────────┘                │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  AnnotationLayer (Container Model)                       │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  • Map<pageNumber, List<AnnotationData>>                 │  │
│  │  • addAnnotation()                                        │  │
│  │  • removeAnnotation()                                     │  │
│  │  • undoLastStroke() / redoLastUndo()                      │  │
│  │  • clearPage() / clearAll()                               │  │
│  │  • exportToJson() / fromJson()                            │  │
│  │  • Undo stack (max 100 items)                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Persistence Layer                             │
│                    (utils/annotation_persistence.dart)           │
├─────────────────────────────────────────────────────────────────┤
│  AnnotationPersistence (Static Utilities)                        │
│  ├─ saveAnnotations()       → File I/O                           │
│  ├─ loadAnnotations()       → File I/O                           │
│  ├─ annotationsExist()      → Check existence                    │
│  ├─ listAnnotationFiles()   → Directory listing                  │
│  └─ deleteAnnotations()     → File deletion                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    External Dependencies                         │
├─────────────────────────────────────────────────────────────────┤
│  • pdfx                    → PDF rendering (future use)          │
│  • hand_signature          → Smooth Bézier drawing               │
│  • syncfusion_flutter_pdf  → PDF manipulation (future use)       │
│  • file_picker             → File selection (future use)         │
│  • path_provider           → Platform-agnostic paths             │
│  • flutter_colorpicker     → Advanced color selection (future)   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Drawing Flow (Pen/Highlighter)

```
User draws with stylus
       │
       ▼
AnnotationCanvas captures PointerEvent
  ├─ Position (x, y)
  ├─ Pressure (0.0-1.0)
  └─ Timestamp
       │
       ▼
AnnotationController processes input
  ├─ HandSignatureControl smoothing
  ├─ Velocity calculation
  └─ Bézier curve generation
       │
       ▼
Stroke completed → AnnotationData created
       │
       ▼
AnnotationLayer stores stroke
  └─ Organized by page number
       │
       ▼
AnnotationPainter renders
  ├─ Convert to Bézier path
  ├─ Apply tool-specific styling
  └─ Draw on canvas
       │
       ▼
Visual feedback to user
```

### 2. Eraser Flow

```
User touches with eraser tool
       │
       ▼
AnnotationCanvas captures position
       │
       ▼
For each pointer move:
  ├─ Check all strokes on current page
  ├─ Calculate distance to each point
  └─ Remove strokes within 15px radius
       │
       ▼
AnnotationLayer removes strokes
  └─ Adds to undo stack
       │
       ▼
AnnotationPainter re-renders
       │
       ▼
Visual feedback (annotations disappear)
```

### 3. Undo/Redo Flow

```
User clicks Undo
       │
       ▼
AnnotationLayer.undoLastStroke()
  ├─ Find most recent stroke (by timestamp)
  ├─ Remove from active annotations
  └─ Add to undo stack
       │
       ▼
UI setState() triggers repaint
       │
       ▼
AnnotationPainter renders without removed stroke
       │
       ▼
Visual feedback (stroke disappears)

────────────────────────────────────────

User clicks Redo
       │
       ▼
AnnotationLayer.redoLastUndo()
  ├─ Pop from undo stack
  └─ Add back to active annotations
       │
       ▼
UI setState() triggers repaint
       │
       ▼
AnnotationPainter renders restored stroke
       │
       ▼
Visual feedback (stroke reappears)
```

### 4. Save/Load Flow

```
User clicks Export
       │
       ▼
AnnotationLayer.exportToJson()
  ├─ Serialize all annotations
  ├─ Convert Offset to flat arrays
  └─ Generate JSON string
       │
       ▼
AnnotationPersistence.saveAnnotations()
  ├─ Get documents directory
  ├─ Create filename (pdf_annotations.json)
  └─ Write to file
       │
       ▼
Success notification

────────────────────────────────────────

User clicks Import
       │
       ▼
AnnotationPersistence.loadAnnotations()
  ├─ Read JSON file
  └─ Parse JSON string
       │
       ▼
AnnotationLayer.fromJson()
  ├─ Deserialize annotations
  ├─ Reconstruct Offset points
  └─ Restore page mapping
       │
       ▼
UI setState() triggers repaint
       │
       ▼
All annotations rendered
       │
       ▼
Success notification
```

## Bézier Curve Processing

```
Raw points from stylus:
P₀ P₁ P₂ P₃ P₄ P₅
 •──•──•──•──•──•

       │
       ▼

Sliding window (4 points at a time):
[P₀, P₁, P₂, P₃] → Segment 1
[P₁, P₂, P₃, P₄] → Segment 2
[P₂, P₃, P₄, P₅] → Segment 3

       │
       ▼

For each segment, calculate control points:
CP₁ = P₁ + (P₂ - P₀) / 6
CP₂ = P₂ - (P₃ - P₁) / 6

       │
       ▼

Generate cubic Bézier:
path.cubicTo(CP₁, CP₂, P₂)

       │
       ▼

Smooth curve through all points:
    ╱───╲___╱───╲
P₀              P₅
```

## Performance Optimizations

```
┌────────────────────────────────────────┐
│  Optimization Strategy                  │
├────────────────────────────────────────┤
│                                         │
│  1. Vector Storage                      │
│     ✓ No bitmap rasterization          │
│     ✓ Minimal memory footprint          │
│     ✓ Fast serialization                │
│                                         │
│  2. Per-Page Rendering                  │
│     ✓ Only render active page           │
│     ✓ O(1) page lookup (Map)            │
│     ✓ Skip off-screen annotations       │
│                                         │
│  3. Efficient Repainting                │
│     ✓ shouldRepaint checks state        │
│     ✓ Only repaint when changed         │
│     ✓ CustomPainter caching             │
│                                         │
│  4. Point Threshold                     │
│     ✓ 3.0px minimum distance            │
│     ✓ Prevents over-capture             │
│     ✓ Maintains smoothness              │
│                                         │
│  5. Undo Stack Limit                    │
│     ✓ Max 100 items                     │
│     ✓ FIFO when exceeded                │
│     ✓ Prevents memory leaks             │
│                                         │
└────────────────────────────────────────┘
```

## State Management

```
                   ┌──────────────────┐
                   │   Flutter App    │
                   └────────┬─────────┘
                            │
                   ┌────────▼─────────┐
                   │  StatefulWidget  │
                   │  (Demo Page)     │
                   └────────┬─────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
       ┌──────▼──────┐ ┌───▼────┐ ┌─────▼──────┐
       │ Annotation  │ │Current │ │  Current   │
       │   Layer     │ │ Tool   │ │  Color     │
       │  (Model)    │ │(State) │ │  (State)   │
       └──────┬──────┘ └───┬────┘ └─────┬──────┘
              │            │            │
              └────────────┼────────────┘
                           │
                  ┌────────▼─────────┐
                  │   setState()     │
                  │  triggers rebuild│
                  └────────┬─────────┘
                           │
                  ┌────────▼─────────┐
                  │ AnnotationCanvas │
                  │   (re-renders)   │
                  └──────────────────┘
```

---

**Visual representation helps understanding! 📊**
