# Stroke Stabilization - Quick Reference

## 🎯 Choose Your Algorithm

### Real-Time Drawing (Choose One)

#### 1. StreamLine (Default, Recommended)
```dart
final settings = BrushSettings.pen().copyWith(stabilization: 0.5);
// ✅ Automatic - no mode needed
```
**When**: General drawing, stylus input  
**Speed**: ⚡⚡⚡⚡⚡  
**Quality**: ⭐⭐⭐  

#### 2. Weighted Average (Better Quality)
```dart
final smoothed = renderer.stabilizePoints(points, 0.5, mode: 'weighted');
```
**When**:  work, preserving details  
**Speed**: ⚡⚡⚡⚡  
**Quality**: ⭐⭐⭐⭐  

#### 3. Pull String (For Straightening)
```dart
final smoothed = renderer.stabilizePoints(points, 0.5, mode: 'pull');
```
**When**: Technical drawing, shaky straight lines  
**Speed**: ⚡⚡⚡⚡  
**Quality**: ⭐⭐⭐  

---

### Post-Processing (Best Quality)

#### 4. Combined (Highest Quality)
```dart
final smoothed = renderer.stabilizePoints(points, 0.6, mode: 'combined');
```
**When**: Final artwork, maximum smoothness  
**Speed**: ⚡⚡  
**Quality**: ⭐⭐⭐⭐⭐  

#### 5. Catmull-Rom (Flowing Curves)
```dart
final smoothed = renderer.stabilizePoints(points, 0.5, mode: 'catmull');
```
**When**: Artistic strokes, calligraphy  
**Speed**: ⚡⚡⚡  
**Quality**: ⭐⭐⭐⭐⭐  

#### 6. Bezier (Vector Quality)
```dart
final smoothed = renderer.stabilizePoints(points, 0.5, mode: 'bezier');
```
**When**: Vector art, logo design  
**Speed**: ⚡⚡⚡  
**Quality**: ⭐⭐⭐⭐⭐  

---

## 🎨 Recommended Values

| Use Case | Stabilization | Mode | Why |
|----------|---------------|------|-----|
| **Sketching** | 0.2 | streamline | Light touch, preserve gesture |
| **Digital Painting** | 0.4 | weighted | Smooth but responsive |
| **Technical Drawing** | 0.6 | pull | Straighten lines |
| **Calligraphy** | 0.3 | catmull | Preserve pressure variation |
| **Illustration** | 0.5 | combined | Best final quality |

---

## ⚡ Quick Integration

### Option 1: Automatic (Easiest)
```dart
// Works automatically with BrushSettings
final settings = BrushSettings.pen().copyWith(
  stabilization: 0.5, // 0.0 = off, 1.0 = maximum
);

renderer.renderStroke(canvas, points, settings);
```

### Option 2: Manual Control
```dart
// Choose specific algorithm
final smoothed = renderer.stabilizePoints(
  points,
  _stabilizationAmount, // From slider
  mode: 'streamline',   // Or any other mode
);

renderer.renderStroke(canvas, smoothed, settings);
```

### Option 3: Smart Preset
```dart
// Different settings for different tools
Map<String, double> presets = {
  'pen': 0.5,
  'pencil': 0.2,
  'watercolor': 0.4,
  'marker': 0.3,
};

final amount = presets[brushType] ?? 0.5;
final settings = BrushSettings.pen().copyWith(stabilization: amount);
```

---

## 🎯 Decision Tree

```
Do you need REAL-TIME smoothing?
├─ YES → Use StreamLine (default)
│   └─ Need better quality?
│       └─ YES → Use Weighted Average
│
└─ NO (Post-processing)
    ├─ Maximum quality needed?
    │   └─ YES → Use Combined
    │
    ├─ Need flowing curves?
    │   └─ YES → Use Catmull-Rom or Bezier
    │
    └─ Need to straighten?
        └─ YES → Use Pull String
```

---

## 🔧 Common Patterns

### Pattern 1: During Drawing
```dart
void onPanUpdate(DragUpdateDetails details) {
  _currentPoints.add(StrokePoint(
    position: details.localPosition,
    pressure: 0.7,
  ));
  
  // Automatic stabilization
  renderer.renderStroke(
    canvas,
    _currentPoints,
    _brushSettings, // Contains stabilization: 0.5
  );
}
```

### Pattern 2: On Stroke Complete
```dart
void onPanEnd(DragEndDetails details) {
  // Apply high-quality smoothing to finished stroke
  final smoothed = renderer.stabilizePoints(
    _currentPoints,
    0.6,
    mode: 'combined',
  );
  
  // Save smoothed version
  currentLayer.addStroke(LayerStroke(
    points: smoothed,
    settings: _brushSettings,
  ));
}
```

### Pattern 3: With User Control
```dart
// UI slider
Slider(
  value: _stabilization,
  min: 0.0,
  max: 1.0,
  onChanged: (value) {
    setState(() {
      _stabilization = value;
      _brushSettings = _brushSettings.copyWith(
        stabilization: value,
      );
    });
  },
)
```

---

## 🚨 Common Issues

### Issue: Stroke feels laggy
**Solution**: Reduce stabilization (try 0.3 or lower)

### Issue: Not smooth enough
**Solution**: Increase stabilization OR use 'combined' mode

### Issue: Too many points
**Solution**: Use simplification after smoothing:
```dart
final smoothed = renderer.stabilizePoints(points, 0.5, mode: 'catmull');
final simplified = renderer.simplifyStroke(smoothed, tolerance: 2.0);
```

### Issue: Loss of detail
**Solution**: Use 'adaptive' mode OR reduce stabilization

---

## 📊 Performance Guide

### For Strokes < 100 Points
✅ All modes work fine

### For Strokes 100-500 Points
✅ Real-time modes (streamline, weighted, pull, adaptive)  
⚠️ Post-processing modes may lag

### For Strokes > 500 Points
✅ Only use real-time modes during drawing  
✅ Apply post-processing modes on stroke completion

---

## 🎓 Best Practices

1. **Use automatic integration** - Simplest and works great
2. **Lower stabilization for fast strokes** - Preserve gesture
3. **Higher stabilization for slow strokes** - Clean up tremor
4. **Apply post-processing on completion** - Best quality
5. **Test with real stylus** - Pressure makes a difference
6. **Let users adjust** - Personal preference varies

---

## 🔗 More Information

- Full Guide: `docs/STROKE_STABILIZATION.md`
- Interactive Demo: `lib/examples/stroke_stabilization_example.dart`
- API Reference: See full guide

---

**Quick Start**: Just add `stabilization: 0.5` to your BrushSettings!

