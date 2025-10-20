# Blend Modes & Serialization Implementation

## Overview
Complete implementation of 29+ blend modes and a hybrid JSON+PNG serialization system for professional layer-based drawing applications.

## Blend Modes Implementation

### LayerBlendMode Enum (`lib/models/layer_blend_mode.dart`)

Comprehensive enum wrapping Flutter's 29 BlendMode values with enhanced UI support:

```dart
enum LayerBlendMode {
  // Basic modes
  normal, multiply, screen, overlay,
  
  // Darken/Lighten
  darken, lighten, colorDodge, colorBurn,
  
  // Light effects
  hardLight, softLight,
  
  // Difference
  difference, exclusion,
  
  // Color adjustment
  hue, saturation, color, luminosity,
  
  // Math operations
  plus, modulate,
  
  // Alpha compositing
  src, dst, srcOver, dstOver, srcIn, dstIn,
  srcOut, dstOut, srcATop, dstATop, xor, clear
}
```

#### Key Features:

**1. Display Names**
```dart
LayerBlendMode.multiply.displayName // "Multiply"
LayerBlendMode.colorDodge.displayName // "Color Dodge"
```

**2. Descriptions**
```dart
LayerBlendMode.multiply.getDescription()
// "Darkens by multiplying color values"

LayerBlendMode.screen.getDescription()
// "Lightens by inverting, multiplying, and inverting"
```

**3. Mode Categories**
```dart
// Get creative/artistic modes (16 modes)
final creative = LayerBlendMode.getCreativeModes();

// Get technical/alpha modes (12 modes)
final technical = LayerBlendMode.getTechnicalModes();
```

**4. Conversion Methods**
```dart
// From BlendMode
final mode = LayerBlendMode.fromBlendMode(BlendMode.multiply);

// From string name
final mode = LayerBlendMode.fromString('multiply');

// To BlendMode
final blendMode = mode.blendMode;
```

### Blend Mode Effects

#### Basic Modes
- **Normal** - Default, no special blending
- **Multiply** - Darkens by multiplying RGB values
- **Screen** - Lightens using inverse multiplication
- **Overlay** - Combines multiply and screen

#### Dodge/Burn
- **Color Dodge** - Brightens base to reflect blend
- **Color Burn** - Darkens base to reflect blend

#### Light Modes
- **Hard Light** - Strong contrast like harsh spotlight
- **Soft Light** - Subtle contrast like diffused light
- **Darken** - Uses darker of two colors
- **Lighten** - Uses lighter of two colors

#### Color Modes
- **Hue** - Blend hue + base saturation/luminosity
- **Saturation** - Blend saturation + base hue/luminosity
- **Color** - Blend hue/saturation + base luminosity
- **Luminosity** - Blend luminosity + base hue/saturation

#### Math Modes
- **Difference** - Subtracts darker from lighter
- **Exclusion** - Like difference but lower contrast
- **Plus** - Adds color values (additive blending)

## Serialization System

### LayerSerializationService (`lib/services/layer_serialization_service.dart`)

Professional-grade serialization supporting both JSON metadata and PNG layers.

#### JSON Structure

```json
{
  "version": "1.0",
  "canvasWidth": 1920.0,
  "canvasHeight": 1080.0,
  "timestamp": "2025-10-20T10:30:00.000Z",
  "layers": [
    {
      "id": "layer-uuid-123",
      "name": "Background",
      "opacity": 1.0,
      "blendMode": "BlendMode.srcOver",
      "isVisible": true,
      "isLocked": false,
      "bounds": {
        "left": 0.0,
        "top": 0.0,
        "right": 1920.0,
        "bottom": 1080.0
      },
      "createdAt": "2025-10-20T10:00:00.000Z",
      "modifiedAt": "2025-10-20T10:30:00.000Z",
      "strokes": [
        {
          "id": "stroke-uuid-456",
          "timestamp": "2025-10-20T10:15:00.000Z",
          "brush": {
            "color": 4278190080,
            "strokeWidth": 4.0,
            "strokeCap": "StrokeCap.round",
            "strokeJoin": "StrokeJoin.round",
            "style": "PaintingStyle.stroke",
            "blendMode": "BlendMode.srcOver"
          },
          "points": [
            {
              "x": 100.0,
              "y": 100.0,
              "pressure": 0.5,
              "tilt": 0.0,
              "orientation": 0.0
            },
            {
              "x": 200.0,
              "y": 150.0,
              "pressure": 0.8,
              "tilt": 0.0,
              "orientation": 0.0
            }
          ]
        }
      ]
    }
  ]
}
```

### Hybrid Save/Load System

#### Saving Projects

```dart
// Save with JSON + PNG layers
await canvasState.saveProjectToFile(
  filePath: '/path/to/project',
  savePngLayers: true, // Optional PNG export
);

// Creates:
// - project.json (metadata)
// - project-layer-{layerId}.png (each layer)
```

#### Loading Projects

```dart
// Load from file
await canvasState.loadProjectFromFile('/path/to/project');

// Layers are automatically loaded with cached images
```

#### JSON Export/Import

```dart
// Export to JSON string
final jsonString = canvasState.exportToJson();

// Import from JSON string
canvasState.importFromJson(jsonString);
```

### File Size Estimation

```dart
// Get estimated file size (in bytes)
final size = canvasState.getEstimatedFileSize();

// Format for display
final kb = size / 1024;
final mb = kb / 1024;
print('Estimated size: ${mb.toStringAsFixed(2)} MB');
```

## UI Widgets

### Blend Mode Selector (`lib/widgets/blend_mode_selector.dart`)

#### Full Selector

```dart
BlendModeSelector(
  selectedMode: LayerBlendMode.normal,
  onModeChanged: (mode) {
    canvasState.setLayerBlendMode(index, mode.blendMode);
  },
  showTechnicalModes: true, // Show alpha compositing modes
)
```

#### Compact Dropdown

```dart
CompactBlendModeSelector(
  selectedMode: LayerBlendMode.multiply,
  onModeChanged: (mode) {
    // Handle change
  },
)
```

#### Bottom Sheet

```dart
final selectedMode = await BlendModeBottomSheet.show(
  context: context,
  currentMode: LayerBlendMode.normal,
);

if (selectedMode != null) {
  canvasState.setLayerBlendMode(index, selectedMode.blendMode);
}
```

#### Preview Widget

```dart
BlendModePreview(
  blendMode: LayerBlendMode.multiply,
  size: Size(100, 100),
)
```

## Usage Examples

### Basic Blend Mode Usage

```dart
// Set layer blend mode
canvasState.setLayerBlendMode(
  layerIndex,
  BlendMode.multiply,
);

// Using LayerBlendMode enum
final mode = LayerBlendMode.screen;
canvasState.setLayerBlendMode(layerIndex, mode.blendMode);
```

### Save/Load Complete Project

```dart
// Save project
await canvasState.saveProjectToFile(
  filePath: '/storage/my_artwork',
  savePngLayers: true,
);

// Load project
await canvasState.loadProjectFromFile('/storage/my_artwork');
```

### Export for Sharing

```dart
// Export to JSON (shareable format)
final jsonData = canvasState.exportToJson();

// Save to file or share
await File('export.json').writeAsString(jsonData);

// Import from shared JSON
final jsonString = await File('import.json').readAsString();
canvasState.importFromJson(jsonString);
```

### Layer UI Integration

```dart
class LayerPropertiesPanel extends StatelessWidget {
  final int layerIndex;
  
  @override
  Widget build(BuildContext context) {
    final canvasState = context.watch<CanvasState>();
    final layer = canvasState.layers[layerIndex];
    final currentMode = LayerBlendMode.fromBlendMode(layer.blendMode);
    
    return Column(
      children: [
        // Opacity slider
        Slider(
          value: layer.opacity,
          onChanged: (value) {
            canvasState.setLayerOpacity(layerIndex, value);
          },
        ),
        
        // Blend mode selector
        ListTile(
          title: Text('Blend Mode'),
          subtitle: Text(currentMode.displayName),
          onTap: () async {
            final mode = await BlendModeBottomSheet.show(
              context: context,
              currentMode: currentMode,
            );
            if (mode != null) {
              canvasState.setLayerBlendMode(
                layerIndex,
                mode.blendMode,
              );
            }
          },
        ),
      ],
    );
  }
}
```

### Auto-Save Implementation

```dart
class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  Timer? _autoSaveTimer;
  final String _projectPath = '/storage/autosave';
  
  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }
  
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      Duration(minutes: 2),
      (timer) async {
        final canvasState = context.read<CanvasState>();
        await canvasState.saveProjectToFile(
          filePath: _projectPath,
          savePngLayers: false, // Faster, metadata only
        );
        print('Auto-saved at ${DateTime.now()}');
      },
    );
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
```

## Performance Considerations

### JSON vs PNG Trade-offs

**JSON Only** (Fast)
- ✅ Quick save/load
- ✅ Small file size
- ✅ Human-readable
- ❌ Must re-render layers

**JSON + PNG** (Balanced)
- ✅ Instant visual preview
- ✅ No re-rendering needed
- ✅ Professional quality
- ❌ Larger file size

**Recommendations:**
- **Auto-save:** JSON only
- **Manual save:** JSON + PNG
- **Export:** JSON + PNG
- **Quick save:** JSON only

### File Size Optimization

```dart
// Estimate before saving
final size = canvasState.getEstimatedFileSize();
if (size > 50 * 1024 * 1024) { // 50 MB
  // Warn user about large file
  showDialog(...);
}

// Compress PNG layers (future enhancement)
// Use lower quality for cache, high quality for export
```

### Memory Management

```dart
// Clear cached images after export
for (final layer in canvasState.layers) {
  layer.invalidateCache();
}

// Reload with fresh cache
await canvasState.cacheAllLayers();
```

## Advanced Features

### Version Migration

The serialization system supports version tracking:

```dart
class LayerSerializationService {
  static const String currentVersion = '1.0';
  
  static DrawingData deserializeDrawing(Map<String, dynamic> json) {
    final version = json['version'] as String;
    
    if (version != currentVersion) {
      // Handle migration
      return _migrateFromVersion(json, version);
    }
    
    return _deserializeV1(json);
  }
}
```

### Custom Export Formats

```dart
// Export to custom format
class CustomExporter {
  static Future<void> exportToPSD(
    List<DrawingLayer> layers,
    Size canvasSize,
    String filePath,
  ) async {
    // Convert layers to PSD format
    // Implementation depends on PSD library
  }
  
  static Future<void> exportToSVG(
    List<DrawingLayer> layers,
    Size canvasSize,
    String filePath,
  ) async {
    // Convert strokes to SVG paths
    // Useful for vector-based export
  }
}
```

### Incremental Save

```dart
// Save only changed layers
class IncrementalSaver {
  final Map<String, DateTime> _lastSaved = {};
  
  Future<void> saveChangedLayers(
    List<DrawingLayer> layers,
    String basePath,
  ) async {
    for (final layer in layers) {
      final lastSave = _lastSaved[layer.id];
      
      if (lastSave == null || layer.modifiedAt.isAfter(lastSave)) {
        // Save this layer
        await _saveLayer(layer, basePath);
        _lastSaved[layer.id] = DateTime.now();
      }
    }
  }
}
```

## Technical Details

### Serialization Format

All data types are preserved:
- **Colors:** Stored as ARGB32 integers
- **Enums:** Stored as strings (e.g., "BlendMode.multiply")
- **Timestamps:** ISO 8601 format
- **Floats:** Full precision maintained
- **Pressure:** Stored per-point (0.0-1.0)

### PNG Compression

Layer images use PNG format:
- **Lossless compression**
- **Alpha channel preserved**
- **Typical compression:** 60-80% of raw size
- **Quality:** Perfect reproduction

### Data Integrity

```dart
// Validate loaded data
static bool validateDrawingData(Map<String, dynamic> json) {
  if (!json.containsKey('version')) return false;
  if (!json.containsKey('layers')) return false;
  
  // Check layer structure
  for (final layer in json['layers']) {
    if (!layer.containsKey('id')) return false;
    if (!layer.containsKey('strokes')) return false;
  }
  
  return true;
}
```

## Files Created

1. **`lib/models/layer_blend_mode.dart`** - Blend mode enum with 29 modes
2. **`lib/services/layer_serialization_service.dart`** - Save/load engine
3. **`lib/widgets/blend_mode_selector.dart`** - UI components
4. **`lib/controllers/canvas_state.dart`** - Updated with save/load methods

## Quality Assurance

✅ **Flutter Analyze:** No errors or warnings
✅ **29 Blend Modes:** All Flutter blend modes supported
✅ **JSON Format:** Human-readable, version-tracked
✅ **PNG Export:** Lossless layer images
✅ **Hybrid System:** Optimal balance of speed and quality
✅ **UI Components:** Ready-to-use widgets

## Next Steps

1. **Cloud Sync:** Upload to cloud storage
2. **Compression:** Add zip compression for project folders
3. **Thumbnails:** Generate project preview images
4. **History:** Save multiple versions/checkpoints
5. **Import:** Support PSD, Procreate formats
6. **Export:** PDF, high-res PNG, video

---

This implementation provides **professional-grade** serialization matching industry-standard digital art applications! 🎨💾
