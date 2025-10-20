# Display vs Export Separation Architecture

## Critical Design Pattern

**FUNDAMENTAL PRINCIPLE**: Display rendering (shows background) is completely SEPARATE from export rendering (transparent).

This separation ensures that:
1. Users see a visual background during editing (white canvas)
2. Exports contain NO background - only drawn pixels
3. Alpha channel is preserved in all exports
4. Eraser creates genuine transparency (not white pixels)

---

## Architecture Overview

### Two Separate Painters

#### 1. **CanvasDisplayPainter** (For Visual Display)
- **Purpose**: Show canvas in editor with visual aids
- **Background**: Draws white (or custom color) background
- **Use Case**: Interactive editing, real-time preview
- **File**: `lib/painters/display_export_painter.dart`

```dart
class CanvasDisplayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // FOR DISPLAY ONLY: Show white background
    if (showBackground) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );
    }
    
    // Render layers on top
    _renderLayers(canvas, layers, size);
  }
}
```

#### 2. **CanvasExportPainter** (For Export)
- **Purpose**: Export canvas to image file
- **Background**: NO background drawn (transparent by default)
- **Use Case**: PNG/WebP export, sharing, saving
- **File**: `lib/painters/display_export_painter.dart`

```dart
class CanvasExportPainter {
  static Future<ui.Image> renderForExport(
    List<DrawingLayer> layers,
    Size size, {
    double scaleFactor = 1.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // CRITICAL: NO background color drawn here!
    // Canvas is transparent by default
    
    _renderLayers(canvas, layers, size);
    
    final picture = recorder.endRecording();
    return await picture.toImage(outputWidth, outputHeight);
  }
}
```

---

## Why This Separation Matters

### Problem Without Separation
```dart
// BAD: Single painter for both display and export
class UniversalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background always drawn
    canvas.drawRect(rect, Paint()..color = Colors.white);
    
    // Result: White background exported with artwork
    // User can't have transparent PNG
  }
}
```

### Solution With Separation
```dart
// GOOD: Display painter
canvas.drawRect(rect, Paint()..color = Colors.white); // Visual aid

// GOOD: Export painter
// NO background drawn - transparent by default
```

**Result**: 
- ✅ White background shown during editing
- ✅ Transparent PNG exported
- ✅ Alpha channel preserved
- ✅ Eraser works correctly

---

## Implementation Details

### Display Rendering

**File**: `lib/painters/display_export_painter.dart`

```dart
// Widget for displaying canvas
class CanvasDisplayWidget extends StatelessWidget {
  final List<DrawingLayer> layers;
  final Size canvasSize;
  final Color backgroundColor;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CanvasDisplayPainter(
        layers: layers,
        backgroundColor: backgroundColor,
        showBackground: showBackground, // Toggle on/off
      ),
      size: canvasSize,
    );
  }
}
```

**Key Points**:
- Background is **optional** (can toggle on/off)
- Background color is **configurable**
- Used only for **visual display**
- Never affects exported image

### Export Rendering

**File**: `lib/painters/display_export_painter.dart`

```dart
// Export to image (transparent)
final image = await CanvasExportPainter.renderForExport(
  layers,
  Size(800, 600),
  scaleFactor: 2.0, // High-resolution export
);

final byteData = await image.toByteData(
  format: ui.ImageByteFormat.png, // PNG preserves alpha
);

final bytes = byteData!.buffer.asUint8List();
```

**Key Points**:
- NO background drawn
- Supports **scale factor** for high-res export
- Uses **async rendering** (non-blocking)
- Returns **ui.Image** with alpha channel
- PNG format **preserves transparency**

---

## Alpha Channel Verification

**File**: `lib/services/alpha_channel_verifier.dart`

Use `AlphaChannelVerifier` to confirm transparency is preserved:

```dart
// Verify exported image has transparency
final hasTransparency = await AlphaChannelVerifier.verifyTransparency(
  pngBytes,
);

print('Has transparency: $hasTransparency');
// Expected: true

// Get detailed statistics
final stats = await AlphaChannelVerifier.getTransparencyStats(pngBytes);
print('Transparent pixels: ${stats['transparentPixels']}');
print('Transparency %: ${stats['transparencyPercentage']}');

// Generate human-readable report
final report = await AlphaChannelVerifier.generateTransparencyReport(pngBytes);
print(report);
/*
=== Transparency Verification Report ===
Total Pixels: 320000
Transparent Pixels: 256000
Opaque Pixels: 64000
Transparency: 80.00%
Average Alpha: 51.20
Alpha Range: 0 - 255

✅ Alpha channel preserved - transparency verified!
*/
```

### Verification Methods

#### 1. **Basic Transparency Check**
```dart
final hasTransparency = await verifyTransparency(pngBytes);
// Returns: true if any pixel has alpha < 255
```

#### 2. **Detailed Statistics**
```dart
final stats = await getTransparencyStats(pngBytes);
// Returns:
// - totalPixels
// - transparentPixels
// - opaquePixels
// - averageAlpha
// - minAlpha
// - maxAlpha
// - transparencyPercentage
```

#### 3. **Region-Specific Verification**
```dart
final regions = [
  Rect.fromLTWH(0, 0, 100, 100), // Top-left corner
  Rect.fromLTWH(300, 300, 100, 100), // Bottom-right corner
];

final hasTransparency = await verifyRegionTransparency(pngBytes, regions);
// Returns: true if specified regions contain transparency
```

#### 4. **Eraser Verification**
```dart
final eraserPoints = [
  Offset(100, 100),
  Offset(200, 200),
];

final eraserWorks = await verifyEraserTransparency(
  pngBytes,
  eraserPoints,
  eraserRadius: 20.0,
);
// Returns: true if eraser created transparent pixels (alpha = 0)
```

#### 5. **Compare Display vs Export**
```dart
final difference = await compareAlphaChannels(
  displayImageBytes,
  exportImageBytes,
);
// Returns: Percentage of pixels with different alpha values
// Expected: High % (display has opaque background, export transparent)
```

---

## Integration Guide

### Step 1: Replace Existing Painters

**Before** (Old approach):
```dart
// Single painter for everything
class MyCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: UniversalCanvasPainter(layers: layers),
    );
  }
}
```

**After** (Separated approach):
```dart
// Display painter for visual rendering
class MyCanvas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CanvasDisplayWidget(
      layers: layers,
      canvasSize: Size(800, 600),
      backgroundColor: Colors.white,
      showBackground: true, // Visual aid
    );
  }
}
```

### Step 2: Update Export Logic

**Before** (Old approach):
```dart
// Export uses same painter (includes background)
Future<Uint8List> exportCanvas() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Problem: Background drawn
  canvas.drawRect(rect, Paint()..color = Colors.white);
  
  UniversalCanvasPainter(layers).paint(canvas, size);
  // ...
}
```

**After** (Separated approach):
```dart
// Export uses dedicated painter (NO background)
Future<Uint8List> exportCanvas() async {
  // NO background drawn
  final image = await CanvasExportPainter.renderForExport(
    layers,
    Size(800, 600),
    scaleFactor: 2.0,
  );
  
  final byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  
  return byteData!.buffer.asUint8List();
}
```

### Step 3: Add Verification (Optional but Recommended)

```dart
Future<void> exportAndVerify() async {
  final bytes = await exportCanvas();
  
  // Verify transparency preserved
  final hasTransparency = await AlphaChannelVerifier.verifyTransparency(bytes);
  
  if (hasTransparency) {
    print('✅ Export successful - transparency preserved');
  } else {
    print('❌ Export failed - no transparency detected');
  }
}
```

---

## Common Patterns

### Pattern 1: Toggle Background During Editing

```dart
class CanvasScreen extends StatefulWidget {
  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  bool _showBackground = true;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle control
        SwitchListTile(
          title: Text('Show Background'),
          value: _showBackground,
          onChanged: (value) {
            setState(() {
              _showBackground = value;
            });
          },
        ),
        
        // Canvas display
        CanvasDisplayWidget(
          layers: layers,
          canvasSize: Size(800, 600),
          showBackground: _showBackground,
        ),
      ],
    );
  }
}
```

### Pattern 2: Export with Progress Tracking

```dart
Future<Uint8List> exportWithProgress(
  Function(double) onProgress,
) async {
  onProgress(0.0);
  
  // Render image
  final image = await CanvasExportPainter.renderForExport(
    layers,
    Size(800, 600),
    scaleFactor: 2.0,
  );
  onProgress(0.5);
  
  // Convert to PNG
  final byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  onProgress(0.8);
  
  // Verify transparency
  final bytes = byteData!.buffer.asUint8List();
  await AlphaChannelVerifier.verifyTransparency(bytes);
  onProgress(1.0);
  
  return bytes;
}
```

### Pattern 3: Side-by-Side Comparison

```dart
Row(
  children: [
    // Display rendering (with background)
    Column(
      children: [
        Text('Display (with background)'),
        CanvasDisplayWidget(
          layers: layers,
          canvasSize: Size(400, 400),
          showBackground: true,
        ),
      ],
    ),
    
    // Export rendering (transparent)
    Column(
      children: [
        Text('Export (transparent)'),
        FutureBuilder<ui.Image>(
          future: CanvasExportPainter.renderForExport(
            layers,
            Size(400, 400),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }
            return RawImage(image: snapshot.data);
          },
        ),
      ],
    ),
  ],
)
```

---

## Testing Checklist

### Visual Tests

- [ ] Display shows white background during editing
- [ ] Background can be toggled on/off
- [ ] Canvas appears identical with/without background (except color)
- [ ] All strokes render correctly in both modes

### Export Tests

- [ ] Exported PNG has transparent background
- [ ] `AlphaChannelVerifier.verifyTransparency()` returns `true`
- [ ] Transparent regions show checkered pattern in image viewers
- [ ] No white/black pixels where transparency expected

### Eraser Tests

- [ ] Eraser creates transparent regions (not white)
- [ ] Erased regions have alpha = 0
- [ ] `verifyEraserTransparency()` confirms transparency
- [ ] Can see through erased regions to layers below

### Alpha Channel Tests

- [ ] Transparent pixels have alpha < 255
- [ ] Semi-transparent strokes maintain correct alpha
- [ ] Layer opacity preserved in export
- [ ] Blend modes work correctly

---

## Performance Considerations

### Display Rendering
- **Fast**: Native Flutter painter
- **Hardware Accelerated**: GPU rendering
- **Real-time**: 60 FPS typical
- **Memory**: Minimal overhead

### Export Rendering
- **Slower**: Software rendering
- **Blocking**: Use async methods
- **Memory**: Scales with resolution
- **Optimization**: Use scale factor wisely

```dart
// High-resolution export
final image = await CanvasExportPainter.renderForExport(
  layers,
  Size(800, 600),
  scaleFactor: 4.0, // 3200x2400 output
);
// Memory usage: ~40MB for this size
```

---

## Troubleshooting

### Issue: Exported image has white background

**Cause**: Used display painter for export

**Solution**: Use `CanvasExportPainter.renderForExport()` instead

```dart
// BAD
final image = CanvasDisplayPainter(...).toImage();

// GOOD
final image = await CanvasExportPainter.renderForExport(layers, size);
```

### Issue: No transparency detected

**Cause**: JPEG format or wrong rendering

**Solution**: Always use PNG format

```dart
// BAD
final byteData = await image.toByteData(
  format: ui.ImageByteFormat.rawRgba, // No compression
);

// GOOD
final byteData = await image.toByteData(
  format: ui.ImageByteFormat.png, // Preserves alpha
);
```

### Issue: Eraser draws white, not transparent

**Cause**: Not using `BlendMode.clear` with `saveLayer`

**Solution**: See `transparent_eraser.dart` implementation

```dart
// BAD
canvas.drawPath(eraserPath, Paint()..color = Colors.white);

// GOOD
canvas.saveLayer(rect, Paint());
canvas.drawPath(eraserPath, Paint()..blendMode = BlendMode.clear);
canvas.restore();
```

---

## Key Insights

1. **Canvas background is purely cosmetic** - only for visual aid during editing

2. **Display ≠ Export** - they use different painters with different purposes

3. **PNG is mandatory** - only format that preserves full alpha channel

4. **Verification is essential** - always check transparency after export

5. **Separation enables features**:
   - Toggle background on/off during editing
   - Export with/without background (user choice)
   - Proper eraser with genuine transparency
   - Layer compositing with correct alpha

---

## Example: Complete Implementation

**File**: `lib/examples/display_export_separation_example.dart`

See the full interactive example demonstrating:
- Side-by-side display vs export
- Background toggle control
- Export with verification
- Transparency statistics
- Checkered background visualization

Run the example:
```dart
MaterialApp(
  home: DisplayVsExportExample(),
)
```

---

## Related Documentation

- **Canvas Clipping**: `docs/CANVAS_CLIPPING_SYSTEM.md`
- **Transparent Export**: `docs/TRANSPARENT_EXPORT_ARCHITECTURE.md`
- **Eraser Implementation**: `lib/services/transparent_eraser.dart`
- **Export System**: `lib/services/transparent_exporter.dart`

---

## Summary

**Critical Architecture Pattern**:
```
Display Rendering → Shows background (visual aid)
       ↓
   User edits canvas
       ↓
Export Rendering → NO background (transparent)
       ↓
Alpha Verification → Confirms transparency
       ↓
  PNG Export → Preserved alpha channel
```

**Key Files**:
1. `lib/painters/display_export_painter.dart` - Both painters
2. `lib/services/alpha_channel_verifier.dart` - Verification
3. `lib/examples/display_export_separation_example.dart` - Demo

**Remember**: Canvas background is only for display. Export should NEVER include it unless explicitly requested by user.
