# Bézier Curve Implementation Guide

## Overview

This document explains the mathematical foundation of the smooth drawing system in the Kivixa .

## Problem Statement

When a user draws with a stylus or finger, we capture discrete points at intervals. Simply connecting these points with straight lines results in jagged, unnatural-looking strokes. We need to create smooth curves that pass through all captured points.

## Solution: Catmull-Rom to Cubic Bézier Conversion

### Why Catmull-Rom?

Catmull-Rom splines have two key properties:
1. **Interpolation**: The curve passes through all control points (not just near them)
2. **Smooth tangents**: Natural-looking curves without manual tangent adjustment

### Why Convert to Bézier?

- Canvas rendering APIs natively support cubic Bézier curves
- GPU acceleration for Bézier curve rendering
- Industry-standard format for vector graphics

## Mathematical Foundation

### Cubic Bézier Curve Definition

A cubic Bézier curve is defined by 4 points:
- P₁: Start point
- CP₁: First control point
- CP₂: Second control point  
- P₂: End point

The curve is calculated using the parametric equation (t ∈ [0, 1]):

```
B(t) = (1-t)³·P₁ + 3(1-t)²t·CP₁ + 3(1-t)t²·CP₂ + t³·P₂
```

### Catmull-Rom Spline Definition

A Catmull-Rom segment uses 4 consecutive points (P₀, P₁, P₂, P₃) to define a curve from P₁ to P₂. The tangent at any point is determined by its neighbors:

```
Tangent at P₁ = (P₂ - P₀) / 2
Tangent at P₂ = (P₃ - P₁) / 2
```

### Conversion Formula

To convert a Catmull-Rom segment to cubic Bézier:

Given: P₀, P₁, P₂, P₃ (four consecutive points)

Calculate control points:

```
CP₁ = P₁ + (P₂ - P₀) / 6
CP₂ = P₂ - (P₃ - P₁) / 6
```

Result: Cubic Bézier from P₁ to P₂ with control points CP₁ and CP₂

## Implementation in Code

```dart
Path _createBezierPath(List<Offset> points) {
  final path = Path();
  
  if (points.isEmpty) return path;
  
  // Start at first point
  path.moveTo(points[0].dx, points[0].dy);
  
  // Process each segment
  for (int i = 0; i < points.length - 1; i++) {
    // Get 4 consecutive points (with boundary handling)
    final p0 = i > 0 ? points[i - 1] : points[i];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];
    
    // Calculate Bézier control points
    final cp1 = Offset(
      p1.dx + (p2.dx - p0.dx) / 6.0,
      p1.dy + (p2.dy - p0.dy) / 6.0,
    );
    
    final cp2 = Offset(
      p2.dx - (p3.dx - p1.dx) / 6.0,
      p2.dy - (p3.dy - p1.dy) / 6.0,
    );
    
    // Draw cubic Bézier segment
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
  }
  
  return path;
}
```

## Boundary Handling

### First Point (i = 0)
- P₀ doesn't exist, so we duplicate P₁
- This creates a tangent pointing toward P₂

### Last Point (i = n-1)  
- P₃ doesn't exist, so we duplicate P₂
- This creates a tangent pointing away from P₁

This ensures smooth start and end to strokes without special cases.

## Visual Example

```
Input points (captured from stylus):
P₀────P₁────P₂────P₃────P₄

Catmull-Rom segments:
[P₀, P₁, P₂, P₃] → Curve from P₁ to P₂
[P₁, P₂, P₃, P₄] → Curve from P₂ to P₃

Each segment becomes a cubic Bézier:
P₁ ──CP₁───CP₂── P₂ ──CP₃───CP₄── P₃

Final smooth path:
    ╱‾‾‾╲___╱‾‾‾╲
P₁              P₃
```

## Why 1/6 Factor?

The division by 6 comes from the relationship between Catmull-Rom tangent weights (1/2) and the cubic Bézier basis function coefficient (3):

```
Catmull-Rom tangent weight: 1/2
Bézier control point distance: 1/3 of tangent
Combined factor: (1/2) × (1/3) = 1/6
```

This ensures the Bézier curve exactly matches the Catmull-Rom curve.

## Performance Characteristics

### Time Complexity
- **Per stroke**: O(n) where n = number of points
- **Per segment**: O(1) - just two control point calculations

### Space Complexity
- **Storage**: O(n) - only original points stored
- **Rendering**: O(n) - path generated on-demand

### Optimization
The `hand_signature` library's `threshold: 3.0` setting ensures points are at least 3 pixels apart, preventing excessive point capture while maintaining smoothness.

## Advantages Over Alternatives

### vs. Straight Lines
- ✅ Smooth, natural appearance
- ✅ No visible corners
- ✅ Professional look

### vs. Quadratic Bézier
- ✅ Better control over curve shape
- ✅ Smoother connections between segments
- ✅ More natural-looking strokes

### vs. B-Splines
- ✅ Simpler mathematics
- ✅ Passes through all points (not approximation)
- ✅ Better for handwriting/annotation

### vs. NURBS
- ✅ Much simpler implementation
- ✅ Faster rendering
- ✅ Sufficient for annotation use case

## Velocity-Based Width Variation

The `hand_signature` library adds dynamic width using velocity:

```
width(v) = baseWidth × (1 + (maxVelocity - v) / velocityRange)
```

Where:
- `v` = current drawing velocity
- `velocityRange = 2.0` (our setting)
- Fast strokes → thin lines
- Slow strokes → thick lines

This creates natural calligraphic effects without manual pressure sensitivity.

## Testing Your Implementation

To verify the Bézier curve implementation works correctly:

1. **Smoothness Test**: Draw slow curves - should be smooth, not jagged
2. **Point Pass-Through**: Verify curve passes through all captured points
3. **Tangent Continuity**: Check no sharp corners at segment boundaries
4. **Performance Test**: Draw complex paths - should maintain 60 FPS
5. **Boundary Test**: Verify first/last points render correctly

## Further Reading

- [Cubic Bézier Curves](https://en.wikipedia.org/wiki/B%C3%A9zier_curve)
- [Catmull-Rom Splines](https://en.wikipedia.org/wiki/Cubic_Hermite_spline#Catmull%E2%80%93Rom_spline)
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Canvas Path Operations](https://api.flutter.dev/flutter/dart-ui/Path-class.html)

## References

Implementation based on:
1. Catmull, E., & Rom, R. (1974). "A class of local interpolating splines"
2. Bézier, P. (1972). "Numerical control: mathematics and applications"
3. Flutter rendering engine documentation
4. hand_signature library implementation

