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
  List<DrawingLayer> _layers = [
    DrawingLayer(name: 'Background'),
  ];
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

  void addLayer() {
    final newLayerId = _layers.keys.reduce((a, b) => a > b ? a : b) + 1;
    _layers[newLayerId] = [];
    notifyListeners();
  }

  void setActiveLayer(int layerId) {
    if (_layers.containsKey(layerId)) {
      _activeLayer = layerId;
      notifyListeners();
    }
  }

  void deleteLayer(int layerId) {
    if (_layers.length > 1 && _layers.containsKey(layerId)) {
      _layers.remove(layerId);
      if (_activeLayer == layerId) {
        _activeLayer = _layers.keys.first;
      }
      _rebuildStrokesFromLayers();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void _rebuildStrokesFromLayers() {
    _strokes.clear();
    final sortedLayers = _layers.keys.toList()..sort();
    for (final layerId in sortedLayers) {
      _strokes.addAll(_layers[layerId]!);
    }
  }

  // ============ Stroke Management ============

  void addStroke(stroke_model.Stroke stroke) {
    _captureSnapshotForUndo();
    _layers[_activeLayer]!.add(stroke);
    _strokes.add(stroke);
    _scheduleAutoSave();
    notifyListeners();
  }

  void removeStroke(String strokeId) {
    _captureSnapshotForUndo();
    _strokes.removeWhere((s) => s.id == strokeId);
    // Remove from layers
    for (final layer in _layers.values) {
      layer.removeWhere((s) => s.id == strokeId);
    }
    _scheduleAutoSave();
    notifyListeners();
  }

  void clearStrokes() {
    _captureSnapshotForUndo();
    _strokes.clear();
    _layers = {0: []};
    _activeLayer = 0;
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
      layers: Map.from(
        _layers.map((key, value) => MapEntry(key, List.from(value))),
      ),
      activeLayer: _activeLayer,
    );
  }

  void _restoreSnapshot(CanvasSnapshot snapshot) {
    _strokes = List.from(snapshot.strokes);
    _elements = List.from(snapshot.elements);
    _layers = Map.from(
      snapshot.layers.map((key, value) => MapEntry(key, List.from(value))),
    );
    _activeLayer = snapshot.activeLayer;
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

  // ============ Cleanup ======