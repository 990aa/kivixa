# Usage Examples & Code Snippets

## Quick Start

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:kivixa/models/annotation_layer.dart';
import 'package:kivixa/models/drawing_tool.dart';
import 'package:kivixa/widgets/annotation_canvas.dart';

void main() {
  runApp(MyAnnotationApp());
}

class MyAnnotationApp extends StatefulWidget {
  @override
  State<MyAnnotationApp> createState() => _MyAnnotationAppState();
}

class _MyAnnotationAppState extends State<MyAnnotationApp> {
  final AnnotationLayer _annotationLayer = AnnotationLayer();
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AnnotationCanvas(
          annotationLayer: _annotationLayer,
          currentPage: 0,
          currentTool: _currentTool,
          currentColor: _currentColor,
          canvasSize: Size(595, 842), // A4 size
        ),
      ),
    );
  }
}
```

## Working with Annotations

### Creating Annotations Manually

```dart
import 'package:kivixa/models/annotation_data.dart';
import 'package:kivixa/models/drawing_tool.dart';
import 'package:flutter/material.dart';

// Create a simple line annotation
final lineAnnotation = AnnotationData(
  strokePath: [
    Offset(100, 100),
    Offset(200, 100),
    Offset(300, 150),
  ],
  colorValue: Colors.blue.value,
  strokeWidth: 3.0,
  toolType: DrawingTool.pen,
  pageNumber: 0,
);

// Add to layer
annotationLayer.addAnnotation(lineAnnotation);
```

### Creating Highlighter Annotations

```dart
// Highlighter with wide, semi-transparent stroke
final highlightAnnotation = AnnotationData(
  strokePath: [
    Offset(50, 200),
    Offset(150, 200),
    Offset(250, 205),
    Offset(350, 200),
  ],
  colorValue: Colors.yellow.value,
  strokeWidth: 12.0,
  toolType: DrawingTool.highlighter,
  pageNumber: 0,
);

annotationLayer.addAnnotation(highlightAnnotation);
```

## Undo/Redo Operations

### Basic Undo/Redo

```dart
// Undo last stroke
AnnotationData? undoneStroke = annotationLayer.undoLastStroke();
if (undoneStroke != null) {
  print('Undid stroke with ${undoneStroke.strokePath.length} points');
}

// Redo last undo
bool redoSuccess = annotationLayer.redoLastUndo();
if (redoSuccess) {
  print('Redo successful');
}
```

### Undo with UI Feedback

```dart
void handleUndo() {
  final undone = annotationLayer.undoLastStroke();
  
  setState(() {}); // Trigger repaint
  
  if (undone != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Undid ${undone.toolType.name} stroke')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nothing to undo')),
    );
  }
}
```

## Page Management

### Clear Specific Page

```dart
// Clear all annotations from page 0
annotationLayer.clearPage(0);

// Trigger UI update
setState(() {});
```

### Clear All Pages

```dart
// Clear all annotations from all pages
annotationLayer.clearAll();

// Trigger UI update
setState(() {});
```

### Get Page Statistics

```dart
// Get annotations for specific page
List<AnnotationData> pageAnnotations = 
    annotationLayer.getAnnotationsForPage(0);

print('Page 0 has ${pageAnnotations.length} annotations');

// Get total annotation count
int total = annotationLayer.totalAnnotationCount;
print('Total annotations: $total');

// Get list of annotated pages
List<int> pages = annotationLayer.annotatedPages;
print('Pages with annotations: $pages');
```

## Serialization & Persistence

### Export to JSON

```dart
// Export all annotations to JSON string
String json = annotationLayer.exportToJson();

print('Exported JSON:');
print(json);

// JSON structure:
// {
//   "version": "1.0.0",
//   "totalAnnotations": 5,
//   "pages": {
//     "0": [
//       {
//         "strokePath": [100.0, 100.0, 200.0, 100.0, ...],
//         "colorValue": 4278190080,
//         "strokeWidth": 3.0,
//         "toolType": "pen",
//         "pageNumber": 0,
//         "timestamp": "2025-10-13T10:30:00.000"
//       },
//       ...
//     ]
//   }
// }
```

### Import from JSON

```dart
// Load annotations from JSON string
String jsonString = '{"version":"1.0.0", ...}';
AnnotationLayer loaded = AnnotationLayer.fromJson(jsonString);

print('Loaded ${loaded.totalAnnotationCount} annotations');
```

### Merge Annotations

```dart
// Import and merge with existing annotations
String importedJson = '...';
annotationLayer.importFromJson(importedJson, clearExisting: false);

// Import and replace existing annotations
annotationLayer.importFromJson(importedJson, clearExisting: true);
```

## File I/O Operations

### Save to File

```dart
import 'package:kivixa/utils/annotation_persistence.dart';

// Save annotations for a PDF file
Future<void> saveAnnotations() async {
  try {
    String filePath = await AnnotationPersistence.saveAnnotations(
      annotationLayer,
      'my_document.pdf',
    );
    
    print('Saved to: $filePath');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Annotations saved!')),
    );
  } catch (e) {
    print('Error saving: $e');
  }
}
```

### Load from File

```dart
// Load annotations for a PDF file
Future<void> loadAnnotations() async {
  try {
    String path = await AnnotationPersistence.getAnnotationPath('my_document.pdf');
    AnnotationLayer loaded = await AnnotationPersistence.loadAnnotations(path);
    
    setState(() {
      _annotationLayer = loaded;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${loaded.totalAnnotationCount} annotations')),
    );
  } catch (e) {
    print('Error loading: $e');
  }
}
```

### Check if Annotations Exist

```dart
// Check before loading
Future<void> checkAndLoad() async {
  bool exists = await AnnotationPersistence.annotationsExist('my_document.pdf');
  
  if (exists) {
    await loadAnnotations();
  } else {
    print('No saved annotations found');
  }
}
```

### List All Saved Annotations

```dart
// Get all annotation files
Future<void> listAllAnnotations() async {
  List<String> files = await AnnotationPersistence.listAnnotationFiles();
  
  print('Found ${files.length} annotation files:');
  for (String file in files) {
    print('  - $file');
  }
}
```

## Tool Management

### Switch Drawing Tools

```dart
void selectTool(DrawingTool tool) {
  setState(() {
    _currentTool = tool;
  });
}

// Usage:
selectTool(DrawingTool.pen);
selectTool(DrawingTool.highlighter);
selectTool(DrawingTool.eraser);
```

### Tool-Specific Settings

```dart
// Get stroke width for current tool
double getStrokeWidth(DrawingTool tool) {
  switch (tool) {
    case DrawingTool.pen:
      return 3.0;
    case DrawingTool.highlighter:
      return 12.0;
    case DrawingTool.eraser:
      return 10.0;
  }
}

// Get opacity for current tool
double getOpacity(DrawingTool tool) {
  return tool == DrawingTool.highlighter ? 0.3 : 1.0;
}
```

## Custom Painter Integration

### Using AnnotationPainter Directly

```dart
import 'package:kivixa/painters/annotation_painter.dart';

class MyCustomWidget extends StatelessWidget {
  final AnnotationLayer annotationLayer;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AnnotationPainter(
        annotations: annotationLayer.getAnnotationsForPage(currentPage),
        currentStroke: null,
      ),
      child: Container(
        width: 595,
        height: 842,
      ),
    );
  }
}
```

### Real-Time Preview

```dart
class DrawingWidget extends StatefulWidget {
  @override
  _DrawingWidgetState createState() => _DrawingWidgetState();
}

class _DrawingWidgetState extends State<DrawingWidget> {
  AnnotationData? _currentStroke;
  List<Offset> _currentPoints = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
      _currentStroke = AnnotationData(
        strokePath: _currentPoints,
        colorValue: Colors.black.value,
        strokeWidth: 3.0,
        toolType: DrawingTool.pen,
        pageNumber: 0,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints.add(details.localPosition);
      _currentStroke = _currentStroke?.copyWith(
        strokePath: List.from(_currentPoints),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null) {
      annotationLayer.addAnnotation(_currentStroke!);
    }
    setState(() {
      _currentStroke = null;
      _currentPoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: AnnotationPainter(
          annotations: annotationLayer.getAnnotationsForPage(0),
          currentStroke: _currentStroke,
        ),
        child: Container(width: 595, height: 842),
      ),
    );
  }
}
```

## Advanced Features

### Filter Annotations by Tool

```dart
// Get all pen strokes on page 0
List<AnnotationData> penStrokes = annotationLayer
    .getAnnotationsForPage(0)
    .where((annotation) => annotation.toolType == DrawingTool.pen)
    .toList();

print('Found ${penStrokes.length} pen strokes');
```

### Filter by Time Range

```dart
// Get annotations created in last 5 minutes
DateTime cutoffTime = DateTime.now().subtract(Duration(minutes: 5));

List<AnnotationData> recentAnnotations = annotationLayer
    .getAnnotationsForPage(0)
    .where((annotation) => annotation.timestamp.isAfter(cutoffTime))
    .toList();

print('Recent annotations: ${recentAnnotations.length}');
```

### Calculate Bounding Box

```dart
// Get bounding box of all annotations on page
Rect? getBoundingBox(int pageNumber) {
  final annotations = annotationLayer.getAnnotationsForPage(pageNumber);
  
  if (annotations.isEmpty) return null;
  
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;
  
  for (final annotation in annotations) {
    for (final point in annotation.strokePath) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }
  }
  
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
```

### Clone Annotations

```dart
// Clone all annotations from one page to another
void clonePageAnnotations(int fromPage, int toPage) {
  final sourceAnnotations = annotationLayer.getAnnotationsForPage(fromPage);
  
  for (final annotation in sourceAnnotations) {
    final cloned = annotation.copyWith(pageNumber: toPage);
    annotationLayer.addAnnotation(cloned);
  }
  
  print('Cloned ${sourceAnnotations.length} annotations');
}
```

## UI Components

### Tool Selector Widget

```dart
class ToolSelector extends StatelessWidget {
  final DrawingTool currentTool;
  final Function(DrawingTool) onToolSelected;

  const ToolSelector({
    required this.currentTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildToolButton(DrawingTool.pen, Icons.edit, 'Pen'),
        _buildToolButton(DrawingTool.highlighter, Icons.highlight, 'Highlighter'),
        _buildToolButton(DrawingTool.eraser, Icons.auto_fix_high, 'Eraser'),
      ],
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = currentTool == tool;
    return ElevatedButton.icon(
      onPressed: () => onToolSelected(tool),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey,
      ),
    );
  }
}
```

### Color Picker Widget

```dart
class SimpleColorPicker extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;
  
  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        final isSelected = currentColor == color;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

### Statistics Panel

```dart
class AnnotationStats extends StatelessWidget {
  final AnnotationLayer annotationLayer;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final pageAnnotations = annotationLayer.getAnnotationsForPage(currentPage);
    final totalAnnotations = annotationLayer.totalAnnotationCount;
    
    final penCount = pageAnnotations
        .where((a) => a.toolType == DrawingTool.pen)
        .length;
    final highlighterCount = pageAnnotations
        .where((a) => a.toolType == DrawingTool.highlighter)
        .length;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Page: ${pageAnnotations.length} annotations'),
            Text('  • Pen: $penCount'),
            Text('  • Highlighter: $highlighterCount'),
            SizedBox(height: 8),
            Text('Total: $totalAnnotations annotations'),
            Text('Pages: ${annotationLayer.annotatedPages.length}'),
          ],
        ),
      ),
    );
  }
}
```

## Testing Examples

### Unit Test for AnnotationData

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/models/annotation_data.dart';

void main() {
  test('AnnotationData serialization', () {
    final annotation = AnnotationData(
      strokePath: [Offset(100, 100), Offset(200, 200)],
      colorValue: Colors.black.value,
      strokeWidth: 3.0,
      toolType: DrawingTool.pen,
      pageNumber: 0,
    );

    // Serialize to JSON
    final json = annotation.toJson();
    
    // Deserialize back
    final loaded = AnnotationData.fromJson(json);
    
    // Verify
    expect(loaded.strokePath.length, equals(2));
    expect(loaded.strokeWidth, equals(3.0));
    expect(loaded.toolType, equals(DrawingTool.pen));
  });
}
```
