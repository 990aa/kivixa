import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/stroke.dart' as stroke_model;
import '../models/canvas_element.dart' as element_model;
import '../models/drawing_tool.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';
import '../services/database_service.dart';
import '../services/layer_rendering_service.dart';

/// State management for canvas with Provider/ChangeNotifier and Layer support
class CanvasState extends ChangeNotifier {
  // Legacy stroke system (for backward compatibility)
  List<stroke_model.Stroke> _strokes = [];
  List<element_model.CanvasElement> _elements = [];

  // New layer system
  List<DrawingLayer> _layers = [DrawingLayer(name: 'Background')];
  int _activeLayerIndex = 0;

  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;
  double _strokeWidth = 4.0;
  int _activeLayer = 0;

  // Current note ID
  int? _currentNoteId;

  // Canvas size for layer caching
  Size _canvasSize = const Size(1000, 1000);

  // Undo/Redo stack
  final List<CanvasSnapshot> _undoStack = [];
  final List<CanvasSnapshot> _redoStack = [];
  static const int _maxUndoStackSize = 50;

  // Background auto-save
  Timer? _saveTimer;
  final DatabaseService _databaseService;

  // Getters
  List<stroke_model.Stroke> get strokes => _strokes;
  List<element_model.CanvasElement> get elements => _elements;
  DrawingTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  List<DrawingLayer> get layers => _layers;
  DrawingLayer get activeLayer => _layers[_activeLayerIndex];
  int get activeLayerIndex => _activeLayerIndex;
  int? get currentNoteId => _currentNoteId;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  Size get canvasSize => _canvasSize;

  CanvasState({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  // ============ Canvas Size Management ============

  void setCanvasSize(Size size) {
    if (_canvasSize != size) {
      _canvasSize = size;
      // Invalidate all layer caches when canvas size changes
      LayerRenderingService.invalidateAllCaches(_layers);
      notifyListeners();
    }
  }

  // ============ Tool & Color Management ============

  void setCurrentTool(DrawingTool tool) {
    _currentTool = tool;
    // Adjust stroke width based on tool
    if (tool == DrawingTool.highlighter) {
      _strokeWidth = 12.0;
    } else if (tool == DrawingTool.pen) {
      _strokeWidth = 4.0;
    }
    notifyListeners();
  }

  void setCurrentColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  // ============ Layer Management ============

  void addLayer({String? name}) {
    _captureSnapshotForUndo();
    final newLayer = DrawingLayer(
      name: name ?? 'Layer ${_layers.length + 1}',
    );
    _layers.add(newLayer);
    _activeLayerIndex = _layers.length - 1;
    notifyListeners();
  }

  void setActiveLayer(int index) {
    if (index >= 0 && index < _layers.length) {
      _activeLayerIndex = index;
      notifyListeners();
    }
  }

  void deleteLayer(int index) {
    if (_layers.length > 1 && index >= 0 && index < _layers.length) {
      _captureSnapshotForUndo();
      _layers.removeAt(index);
      if (_activeLayerIndex >= _layers.length) {
        _activeLayerIndex = _layers.length - 1;
      }
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void duplicateLayer(int index) {
    if (index >= 0 && index < _layers.length) {
      _captureSnapshotForUndo();
      final layer = _layers[index];
      final duplicated = layer.copyWith(
        name: '${layer.name} Copy',
      );
      _layers.insert(index + 1, duplicated);
      _activeLayerIndex = index + 1;
      notifyListeners();
    }
  }

  void moveLayer(int fromIndex, int toIndex) {
    if (fromIndex >= 0 &&
        fromIndex < _layers.length &&
        toIndex >= 0 &&
        toIndex < _layers.length) {
      _captureSnapshotForUndo();
      final layer = _layers.removeAt(fromIndex);
      _layers.insert(toIndex, layer);
      _activeLayerIndex = toIndex;
      notifyListeners();
    }
  }

  void renameLayer(int index, String newName) {
    if (index >= 0 && index < _layers.length) {
      _layers[index].name = newName;
      notifyListeners();
    }
  }

  void setLayerOpacity(int index, double opacity) {
    if (index >= 0 && index < _layers.length) {
      _layers[index].opacity = opacity.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void setLayerBlendMode(int index, BlendMode blendMode) {
    if (index >= 0 && index < _layers.length) {
      _layers[index].blendMode = blendMode;
      notifyListeners();
    }
  }

  void toggleLayerVisibility(int index) {
    if (index >= 0 && index < _layers.length) {
      _layers[index].isVisible = !_layers[index].isVisible;
      notifyListeners();
    }
  }

  void toggleLayerLock(int index) {
    if (index >= 0 && index < _layers.length) {
      _layers[index].isLocked = !_layers[index].isLocked;
      notifyListeners();
    }
  }

  void mergeLayerDown(int index) {
    if (index > 0 && index < _layers.length) {
      _captureSnapshotForUndo();
      final upperLayer = _layers[index];
      final lowerLayer = _layers[index - 1];

      // Merge strokes
      lowerLayer.strokes.addAll(upperLayer.strokes);
      lowerLayer.updateBounds();
      lowerLayer.invalidateCache();

      // Remove upper layer
      _layers.removeAt(index);
      _activeLayerIndex = index - 1;

      _scheduleAutoSave();
      notifyListeners();
    }
  }

  /// Cache all layers for better performance
  Future<void> cacheAllLayers() async {
    await LayerRenderingService.cacheAllLayers(_layers, _canvasSize);
    notifyListeners();
  }

  /// Update cache for active layer
  Future<void> updateActiveLayerCache() async {
    await LayerRenderingService.updateLayerCache(
      activeLayer,
      _canvasSize,
    );
    notifyListeners();
  }

  // ============ Stroke Management (New Layer System) ============

  /// Add a stroke to the active layer using new layer system
  void addLayerStroke(LayerStroke stroke) {
    if (activeLayer.isLocked) return;

    _captureSnapshotForUndo();
    activeLayer.addStroke(stroke);
    activeLayer.invalidateCache();
    _scheduleAutoSave();
    notifyListeners();
  }

  /// Create and add a stroke from points (helper method)
  void addStrokeFromPoints(List<StrokePoint> points) {
    final paint = Paint()
      ..color = _currentColor
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final stroke = LayerStroke(
      points: points,
      brushProperties: paint,
    );

    addLayerStroke(stroke);
  }

  /// Legacy stroke support (for backward compatibility)
  void addStroke(stroke_model.Stroke stroke) {
    _captureSnapshotForUndo();
    _strokes.add(stroke);
    _scheduleAutoSave();
    notifyListeners();
  }

  void removeStroke(String strokeId) {
    _captureSnapshotForUndo();
    _strokes.removeWhere((s) => s.id == strokeId);

    // Also remove from layers
    for (final layer in _layers) {
      layer.removeStroke(strokeId);
    }
    _scheduleAutoSave();
    notifyListeners();
  }

  void clearStrokes() {
    _captureSnapshotForUndo();
    _strokes.clear();
    for (final layer in _layers) {
      layer.clearStrokes();
    }
    _scheduleAutoSave();
    notifyListeners();
  }

  // ============ Element Management ============

  void addElement(element_model.CanvasElement element) {
    _captureSnapshotForUndo();
    _elements.add(element);
    _scheduleAutoSave();
    notifyListeners();
  }

  void updateElement(
    String elementId,
    element_model.CanvasElement updatedElement,
  ) {
    _captureSnapshotForUndo();
    final index = _elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      _elements[index] = updatedElement;
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void removeElement(String elementId) {
    _captureSnapshotForUndo();
    _elements.removeWhere((e) => e.id == elementId);
    _scheduleAutoSave();
    notifyListeners();
  }

  void clearElements() {
    _captureSnapshotForUndo();
    _elements.clear();
    _scheduleAutoSave();
    notifyListeners();
  }

  // ============ Undo/Redo System ============

  void undo() {
    if (_undoStack.isNotEmpty) {
      final snapshot = _undoStack.removeLast();
      _redoStack.add(_captureSnapshot());
      _restoreSnapshot(snapshot);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final snapshot = _redoStack.removeLast();
      _undoStack.add(_captureSnapshot());
      _restoreSnapshot(snapshot);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void _captureSnapshotForUndo() {
    _undoStack.add(_captureSnapshot());
    // Limit stack size
    if (_undoStack.length > _maxUndoStackSize) {
      _undoStack.removeAt(0);
    }
    // Clear redo stack on new action
    _redoStack.clear();
  }

  CanvasSnapshot _captureSnapshot() {
    return CanvasSnapshot(
      strokes: List.from(_strokes),
      elements: List.from(_elements),
      layers: _layers.map((layer) => layer.copyWith()).toList(),
      activeLayerIndex: _activeLayerIndex,
    );
  }

  void _restoreSnapshot(CanvasSnapshot snapshot) {
    _strokes = List.from(snapshot.strokes);
    _elements = List.from(snapshot.elements);
    _layers = snapshot.layers.map((layer) => layer.copyWith()).toList();
    _activeLayerIndex = snapshot.activeLayerIndex;
  }

  // ============ Note Management ============

  void setCurrentNote(int noteId) {
    _currentNoteId = noteId;
  }

  Future<void> loadNote(int noteId) async {
    _currentNoteId = noteId;

    // Load strokes
    final loadedStrokes = await _databaseService.loadStrokesForNote(noteId);
    _strokes = loadedStrokes;

    // Rebuild layers from loaded strokes
    _layers = {0: []};
    _layers[0] = List.from(_strokes);
    _activeLayer = 0;

    // Load elements
    _elements = await _databaseService.loadElementsForNote(noteId);

    // Clear undo/redo stacks
    _undoStack.clear();
    _redoStack.clear();

    notifyListeners();
  }

  Future<void> createNewNote(String title, {String? content}) async {
    final noteId = await _databaseService.createNote(
      title: title,
      content: content,
    );
    _currentNoteId = noteId;

    // Clear current canvas
    _strokes.clear();
    _elements.clear();
    _layers = {0: []};
    _activeLayer = 0;
    _undoStack.clear();
    _redoStack.clear();

    notifyListeners();
  }

  // ============ Auto-Save System ============

  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), () => _saveToDatabase());
  }

  Future<void> _saveToDatabase() async {
    if (_currentNoteId == null) return;

    try {
      // Save strokes
      await _databaseService.saveStrokesForNote(_currentNoteId!, _strokes);

      // Save elements
      await _databaseService.saveElementsForNote(_currentNoteId!, _elements);

      // Update note's modified timestamp
      final note = await _databaseService.getNoteById(_currentNoteId!);
      if (note != null) {
        await _databaseService.updateNote(
          note.copyWith(modifiedAt: DateTime.now()),
        );
      }
    } catch (e) {
      debugPrint('Error saving to database: $e');
    }
  }

  /// Force immediate save (useful before navigation)
  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await _saveToDatabase();
  }

  // ============ Cleanup ============

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

/// Snapshot of canvas state for undo/redo
class CanvasSnapshot {
  final List<stroke_model.Stroke> strokes;
  final List<element_model.CanvasElement> elements;
  final Map<int, List<stroke_model.Stroke>> layers;
  final int activeLayer;

  CanvasSnapshot({
    required this.strokes,
    required this.elements,
    required this.layers,
    required this.activeLayer,
  });
}
