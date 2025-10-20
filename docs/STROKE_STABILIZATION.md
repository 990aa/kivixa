# Stroke Stabilization System

## Overview

The Kivixa stroke stabilization system provides professional-grade line smoothing to reduce hand tremor and create cleaner, more precise strokes. It includes **9 different algorithms** ranging from real-time jitter reduction to high-quality curve interpolation.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Input (Raw Points)                   │
│                  [Jittery, High Frequency]                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   StrokeStabilizer                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Stabilization Algorithms:                            │  │
│  │ • StreamLine (Real-time)                             │  │
│  │ • Moving Average                                     │  │
│  │ • Weighted Moving Average                            │  │
│  │ • Catmull-Rom Spline                                 │  │
│  │ • Bezier Spline                                      │  │
│  │ • Chaikin Corner Cutting                             │  │
│  │ • Pull String                                        │  │
│  │ • Adaptive Smoothing                                 │  │
│  │ • Combined Multi-Stage                               │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Smoothed Points Output                      │
│              [Clean, Professional Lines]                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  BrushEngine Rendering                       │
└─────────────────────────────────────────────────────────────┘
```

## Stabilization Algorithms

### 1. StreamLine (Real-Time)

**Best For**: Real-time drawing, immediate feedback

**How It Works**: Uses exponential smoothing to create a lag effect that dampens high-frequency hand tremors.

```dart
final stabilizer = StrokeStabilizer();
final smoothed = stabilizer.streamLine(points, 0.5);
```

**Parameters**:
- `amount` (0.0-1.0): Smoothing strength
  - 0.0 = No smoothing
  - 0.3 = Light smoothing (natural feel)
  - 0.5 = Medium smoothing (recommended)
  - 0.8+ = Heavy smoothing (may feel laggy)

**Performance**: ⚡ Excellent (O(n))

**Use Cases**:
- Stylus input during drawing
- Mouse/trackpad smoothing
- Touch input stabilization

---

### 2. Moving Average

**Best For**: Post-processing, noise removal

**How It Works**: Replaces each point with the average of its neighbors within a sliding window.

```dart
final stabilizer = StrokeStabilizer(windowSize: 5);
final smoothed = stabilizer.movingAverage(points);
```

**Parameters**:
- `windowSize`: Number of neighbors to average (set in constructor)
  - 3 = Light smoothing
  - 5 = Medium smoothing (default)
  - 7+ = Heavy smoothing

**Performance**: ⚡ Excellent (O(n))

**Use Cases**:
- Cleaning up completed strokes
- Removing sensor noise
- Pre-processing before curve fitting

---

### 3. Weighted Moving Average

**Best For**: High-quality smoothing with minimal distortion

**How It Works**: Like moving average but uses Gaussian-like weights, giving more influence to nearby points.

```dart
final smoothed = stabilizer.weightedMovingAverage(points, sigma: 1.5);
```

**Parameters**:
- `sigma` (0.5-3.0): Controls weight distribution
  - Lower = sharper features preserved
  - Higher = smoother but more blurred

**Performance**: ⚡ Good (O(n × window))

**Use Cases**:
- Professional illustration
- Preserving intentional details
- High-quality post-processing

---

### 4. Catmull-Rom Spline

**Best For**: Creating flowing, natural curves

**How It Works**: Generates smooth curves that pass through all control points using polynomial interpolation.

```dart
final smoothed = stabilizer.catmullRomSpline(points, 2); // 2 subdivisions
```

**Parameters**:
- `subdivisions` (1-5): Points generated between each pair
  - 1 = Slight smoothing, fewer points
  - 2 = Balanced (recommended)
  - 5 = Very smooth, many points

**Performance**: ⚠️ Moderate (O(n × subdivisions))

**Use Cases**:
- Artistic strokes
- Calligraphy
- Vector-like smoothness

**Note**: Requires at least 4 input points.

---

### 5. Bezier Spline

**Best For**: Professional-quality smooth curves, vector graphics

**How It Works**: Converts stroke into connected cubic Bezier curves with automatically calculated control points.

```dart
final smoothed = stabilizer.bezierSpline(points, 3);
```

**Parameters**:
- `subdivisions` (1-5): Points per segment
  - Higher = smoother but more points

**Performance**: ⚠️ Moderate (O(n × subdivisions))

**Use Cases**:
- Vector art
- Logo design
- Maximum smoothness required

---

### 6. Chaikin Corner Cutting

**Best For**: Quick smoothing with adjustable quality

**How It Works**: Iteratively cuts corners by creating new points at 1/4 and 3/4 positions along each segment.

```dart
final smoothed = stabilizer.chaikinSmooth(points, 2); // 2 iterations
```

**Parameters**:
- `iterations` (1-4): Number of refinement passes
  - 1 = Subtle smoothing
  - 2 = Medium smoothing (recommended)
  - 3-4 = Very smooth (many points)

**Performance**: ⚠️ Good (O(n × 2^iterations))

**Use Cases**:
- CAD-style drawings
- Geometric shapes
- Progressive smoothing

**Note**: Doubles points per iteration!

---

### 7. Pull String

**Best For**: Straightening shaky lines while preserving intent

**How It Works**: Simulates pulling a string tight through points, creating a more direct path.

```dart
final smoothed = stabilizer.pullString(
  points,
  iterations: 3,
  strength: 0.5,
);
```

**Parameters**:
- `iterations`: Number of pulling passes
- `strength` (0.0-1.0): How much to pull
  - 0.3 = Gentle straightening
  - 0.5 = Moderate (recommended)
  - 0.8+ = Aggressive straightening

**Performance**: ⚡ Good (O(n × iterations))

**Use Cases**:
- Technical drawing
- Straight lines with minor wobbles
- Gesture-based input

---

### 8. Adaptive Smoothing

**Best For**: Intelligent smoothing that preserves intentional features

**How It Works**: Analyzes stroke curvature and applies more smoothing to high-frequency (shaky) sections.

```dart
final smoothed = stabilizer.adaptiveSmooth(points, threshold: 0.3);
```

**Parameters**:
- `threshold` (0.1-0.7): Minimum angle change to trigger smoothing
  - Lower = smooth more sections
  - Higher = preserve more details

**Performance**: ⚡ Good (O(n))

**Use Cases**:
- Preserving sharp corners
- Mixed content (smooth curves + sharp angles)
- Smart auto-smoothing

---

### 9. Combined Multi-Stage

**Best For**: Highest quality results, post-processing

**How It Works**: Applies multiple algorithms in sequence:
1. StreamLine for jitter reduction
2. Moving Average for noise removal
3. Catmull-Rom for final smoothing

```dart
final smoothed = stabilizer.combinedSmooth(
  points,
  streamLineAmount: 0.3,
  subdivisions: 2,
);
```

**Parameters**:
- `streamLineAmount`: Initial jitter reduction
- `subdivisions`: Final curve quality

**Performance**: ⚠️ Slower (O(n × subdivisions))

**Use Cases**:
- Professional illustration
- Maximum quality required
- Final artwork cleanup

---

## Integration Guide

### Basic Usage with BrushStrokeRenderer

The `BrushStrokeRenderer` automatically applies stabilization based on `BrushSettings.stabilization`:

```dart
// Automatic stabilization (uses StreamLine by default)
final settings = BrushSettings.pen().copyWith(stabilization: 0.5);
renderer.renderStroke(canvas, points, settings);
```

### Manual Stabilization with Custom Modes

For more control, use the stabilization methods directly:

```dart
final renderer = BrushStrokeRenderer();

// Choose specific algorithm
final smoothed = renderer.stabilizePoints(
  points,
  0.5,
  mode: 'catmull', // or 'bezier', 'pull', etc.
);

// Render the smoothed stroke
renderer.renderStroke(canvas, smoothed, settings);
```

### Real-Time Drawing Integration

Apply stabilization during drawing for immediate feedback:

```dart
class DrawingCanvas extends StatefulWidget {
  // ...
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final BrushStrokeRenderer _renderer = BrushStrokeRenderer();
  List<StrokePoint> _currentStroke = [];

  void onPointerMove(PointerEvent event, BrushSettings settings) {
    setState(() {
      _currentStroke.add(StrokePoint(
        position: event.localPosition,
        pressure: event.pressure,
        tilt: event.tilt,
        orientation: event.orientation,
      ));

      // Apply real-time stabilization if enabled
      if (settings.stabilization > 0) {
        _currentStroke = _renderer.stabilizePoints(
          _currentStroke,
          settings.stabilization,
          mode: 'streamline', // Fast for real-time
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StrokePainter(
        stroke: _currentStroke,
        settings: _brushSettings,
        renderer: _renderer,
      ),
    );
  }
}
```

### Post-Processing for Saved Strokes

Apply high-quality stabilization to completed strokes:

```dart
// When stroke is complete
void onStrokeComplete(List<StrokePoint> rawPoints) {
  // Apply high-quality smoothing
  final smoothed = _renderer.stabilizePoints(
    rawPoints,
    0.6,
    mode: 'combined', // Best quality
  );

  // Save the smoothed version
  final stroke = LayerStroke(
    points: smoothed,
    settings: _brushSettings,
  );
  
  currentLayer.addStroke(stroke);
}
```

---

## Performance Comparison

| Algorithm            | Speed     | Quality   | Point Count | Best For              |
|----------------------|-----------|-----------|-------------|-----------------------|
| StreamLine           | ⚡⚡⚡⚡⚡ | ⭐⭐⭐     | Same        | Real-time             |
| Moving Average       | ⚡⚡⚡⚡⚡ | ⭐⭐⭐     | Same        | Quick cleanup         |
| Weighted Average     | ⚡⚡⚡⚡   | ⭐⭐⭐⭐   | Same        | Quality + speed       |
| Catmull-Rom          | ⚡⚡⚡     | ⭐⭐⭐⭐⭐ | 2-5× more   | Flowing curves        |
| Bezier               | ⚡⚡⚡     | ⭐⭐⭐⭐⭐ | 2-5× more   | Vector quality        |
| Chaikin              | ⚡⚡⚡     | ⭐⭐⭐⭐   | 2-16× more  | Geometric shapes      |
| Pull String          | ⚡⚡⚡⚡   | ⭐⭐⭐     | Same        | Straightening         |
| Adaptive             | ⚡⚡⚡⚡   | ⭐⭐⭐⭐   | Same        | Smart smoothing       |
| Combined             | ⚡⚡       | ⭐⭐⭐⭐⭐ | 2-5× more   | Maximum quality       |

---

## Recommended Settings by Use Case

### Digital Painting
```dart
final settings = BrushSettings.watercolor().copyWith(
  stabilization: 0.4,
);
// Use: streamline or weighted modes
```

### Technical Drawing
```dart
final settings = BrushSettings.pen().copyWith(
  stabilization: 0.6,
);
// Use: pull or adaptive modes
```

### Calligraphy
```dart
final settings = BrushSettings.pen().copyWith(
  stabilization: 0.3,
  usePressure: true,
);
// Use: catmull or bezier modes
```

### Sketching
```dart
final settings = BrushSettings.pencil().copyWith(
  stabilization: 0.2, // Light touch
);
// Use: streamline mode
```

### Professional Illustration
```dart
final settings = BrushSettings.pen().copyWith(
  stabilization: 0.5,
);
// Use: combined mode for final strokes
```

---

## Troubleshooting

### Stroke Feels Laggy

**Problem**: Too much stabilization creates noticeable lag

**Solution**:
- Reduce `stabilization` amount (try 0.2-0.4)
- Use StreamLine instead of Catmull-Rom for real-time
- Apply heavy smoothing only on stroke completion

### Loss of Detail

**Problem**: Fine details are being smoothed away

**Solution**:
- Use Adaptive mode (preserves sharp features)
- Lower stabilization amount
- Use Weighted Average instead of Moving Average

### Too Many Points

**Problem**: Spline algorithms creating excessive points

**Solution**:
- Reduce `subdivisions` parameter
- Apply Douglas-Peucker simplification after smoothing:
  ```dart
  final smoothed = stabilizer.catmullRomSpline(points, 2);
  final simplified = renderer.simplifyStroke(smoothed, tolerance: 2.0);
  ```

### Not Smooth Enough

**Problem**: Stroke still looks jittery

**Solution**:
- Increase stabilization amount
- Try Combined mode for best results
- Check if input points are too sparse (add interpolation)
- Use Chaikin with 2-3 iterations

---

## Advanced Techniques

### Progressive Smoothing

Apply different smoothing based on stroke speed:

```dart
double calculateStabilization(List<StrokePoint> points) {
  if (points.length < 2) return 0.5;
  
  // Calculate average speed
  double totalSpeed = 0;
  for (int i = 1; i < points.length; i++) {
    final distance = (points[i].position - points[i-1].position).distance;
    totalSpeed += distance;
  }
  
  final avgSpeed = totalSpeed / points.length;
  
  // Faster strokes need less smoothing
  if (avgSpeed > 50) return 0.2;
  if (avgSpeed > 20) return 0.4;
  return 0.6; // Slow strokes get more smoothing
}
```

### Pressure-Aware Smoothing

Preserve pressure variation while smoothing position:

```dart
List<StrokePoint> smoothPositionOnly(List<StrokePoint> points) {
  final smoothed = stabilizer.streamLine(points, 0.5);
  
  // Restore original pressure values
  for (int i = 0; i < smoothed.length && i < points.length; i++) {
    smoothed[i] = StrokePoint(
      position: smoothed[i].position,
      pressure: points[i].pressure, // Original pressure
      tilt: smoothed[i].tilt,
      orientation: smoothed[i].orientation,
    );
  }
  
  return smoothed;
}
```

### Hybrid Smoothing

Combine algorithms for custom effects:

```dart
List<StrokePoint> customSmooth(List<StrokePoint> points) {
  // Step 1: Remove jitter
  var smoothed = stabilizer.streamLine(points, 0.3);
  
  // Step 2: Straighten if needed
  smoothed = stabilizer.pullString(smoothed, iterations: 2, strength: 0.4);
  
  // Step 3: Final polish
  smoothed = stabilizer.weightedMovingAverage(smoothed, sigma: 1.0);
  
  return smoothed;
}
```

---

## API Reference

### StrokeStabilizer Class

```dart
class StrokeStabilizer {
  StrokeStabilizer({int windowSize = 5});
  
  // Core algorithms
  List<StrokePoint> streamLine(List<StrokePoint> points, double amount);
  List<StrokePoint> movingAverage(List<StrokePoint> points);
  List<StrokePoint> weightedMovingAverage(List<StrokePoint> points, {double sigma = 1.0});
  List<StrokePoint> catmullRomSpline(List<StrokePoint> points, int subdivisions);
  List<StrokePoint> bezierSpline(List<StrokePoint> points, int subdivisions);
  List<StrokePoint> chaikinSmooth(List<StrokePoint> points, int iterations);
  List<StrokePoint> pullString(List<StrokePoint> points, {int iterations = 3, double strength = 0.5});
  List<StrokePoint> adaptiveSmooth(List<StrokePoint> points, {double threshold = 0.3});
  List<StrokePoint> combinedSmooth(List<StrokePoint> points, {double streamLineAmount = 0.3, int subdivisions = 2});
  
  void clear(); // Clear internal buffer
}
```

### BrushStrokeRenderer Integration

```dart
class BrushStrokeRenderer {
  List<StrokePoint> stabilizePoints(
    List<StrokePoint> points,
    double stabilization, {
    String mode = 'streamline',
  });
}
```

**Available Modes**:
- `'streamline'` (default)
- `'moving'`
- `'weighted'`
- `'catmull'`
- `'bezier'`
- `'chaikin'`
- `'pull'`
- `'adaptive'`
- `'combined'`

---

## Examples

See `lib/examples/stroke_stabilization_example.dart` for a comprehensive interactive demo with:
- Side-by-side comparison of all algorithms
- Real-time stabilization visualization
- Adjustable parameters
- Performance metrics

---

## Best Practices

1. **Real-Time Drawing**: Use StreamLine with amount 0.3-0.5
2. **Post-Processing**: Use Combined or Bezier modes
3. **Performance**: Avoid spline algorithms for long strokes (>500 points)
4. **Quality**: Apply simplification after smoothing to reduce point count
5. **User Choice**: Let users adjust stabilization amount (like Procreate)
6. **Testing**: Test with real stylus input (pressure/tilt) for best results

---

## Future Enhancements

Potential improvements for future versions:

- **GPU Acceleration**: Shader-based smoothing for real-time performance
- **Machine Learning**: Adaptive algorithms that learn user's drawing style
- **Velocity-Based**: Adjust smoothing based on stroke velocity
- **Directional**: Different smoothing for horizontal vs vertical movements
- **Undo-Friendly**: Stabilization that preserves undo history
