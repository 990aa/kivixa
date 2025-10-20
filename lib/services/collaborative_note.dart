import 'dart:async';
import 'dart:convert';
import 'package:crdt/crdt.dart';
import 'package:flutter/foundation.dart';
import '../models/stroke.dart';
import '../models/canvas_element.dart';

/// Collaborative note using CRDT for conflict-free editing
class CollaborativeNote extends ChangeNotifier {
  final String noteId;
  final Crdt crdt;

  // CRDT maps for strokes and elements
  final Map<String, Stroke> _strokes = {};
  final Map<String, CanvasElement> _elements = {};
  final Map<String, dynamic> _metadata = {};

  // Change listeners
  final StreamController<CrdtChange> _changesController =
      StreamController<CrdtChange>.broadcast();

  Stream<CrdtChange> get onChanges => _changesController.stream;

  List<Stroke> get strokes => _strokes.values.toList();
  List<CanvasElement> get elements => _elements.values.toList();

  CollaborativeNote({required this.noteId, String? canonicalNodeId})
    : crdt = Crdt(canonicalNodeId ?? noteId) {
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    // Listen to CRDT changes
    crdt.onUpdate = () {
      _handleRemoteChanges();
      notifyListeners();
    };
  }

  /// Add a local stroke
  void addStroke(Stroke stroke) {
    _strokes[stroke.id] = stroke;

    // Serialize stroke to CRDT
    final strokeData = _serializeStroke(stroke);
    crdt.put('stroke:${stroke.id}', strokeData);

    _changesController.add(
      CrdtChange(type: CrdtChangeType.strokeAdded, id: stroke.id, data: stroke),
    );

    notifyListeners();
  }

  /// Update a stroke
  void updateStroke(Stroke stroke) {
    if (_strokes.containsKey(stroke.id)) {
      _strokes[stroke.id] = stroke;

      final strokeData = _serializeStroke(stroke);
      crdt.put('stroke:${stroke.id}', strokeData);

      _changesController.add(
        CrdtChange(
          type: CrdtChangeType.strokeUpdated,
          id: stroke.id,
          data: stroke,
        ),
      );

      notifyListeners();
    }
  }

  /// Remove a stroke
  void removeStroke(String strokeId) {
    if (_strokes.containsKey(strokeId)) {
      _strokes.remove(strokeId);
      crdt.delete('stroke:$strokeId');

      _changesController.add(
        CrdtChange(
          type: CrdtChangeType.strokeRemoved,
          id: strokeId,
          data: null,
        ),
      );

      notifyListeners();
    }
  }

  /// Add a canvas element
  void addElement(CanvasElement element) {
    _elements[element.id] = element;

    final elementData = _serializeElement(element);
    crdt.put('element:${element.id}', elementData);

    _changesController.add(
      CrdtChange(
        type: CrdtChangeType.elementAdded,
        id: element.id,
        data: element,
      ),
    );

    notifyListeners();
  }

  /// Update an element
  void updateElement(CanvasElement element) {
    if (_elements.containsKey(element.id)) {
      _elements[element.id] = element;

      final elementData = _serializeElement(element);
      crdt.put('element:${element.id}', elementData);

      _changesController.add(
        CrdtChange(
          type: CrdtChangeType.elementUpdated,
          id: element.id,
          data: element,
        ),
      );

      notifyListeners();
    }
  }

  /// Remove an element
  void removeElement(String elementId) {
    if (_elements.containsKey(elementId)) {
      _elements.remove(elementId);
      crdt.delete('element:$elementId');

      _changesController.add(
        CrdtChange(
          type: CrdtChangeType.elementRemoved,
          id: elementId,
          data: null,
        ),
      );

      notifyListeners();
    }
  }

  /// Update metadata (title, modified date, etc.)
  void updateMetadata(String key, dynamic value) {
    _metadata[key] = value;
    crdt.put('meta:$key', value);
    notifyListeners();
  }

  /// Get metadata value
  dynamic getMetadata(String key) => _metadata[key];

  /// Handle remote changes from CRDT
  void _handleRemoteChanges() {
    final Map<String, dynamic> crdtMap = crdt.map;

    // Process strokes
    final strokeKeys = crdtMap.keys.where((k) => k.startsWith('stroke:'));
    for (final key in strokeKeys) {
      final strokeId = key.substring(7); // Remove 'stroke:' prefix
      if (!_strokes.containsKey(strokeId)) {
        final strokeData = crdtMap[key] as Map<String, dynamic>;
        final stroke = _deserializeStroke(strokeId, strokeData);
        if (stroke != null) {
          _strokes[strokeId] = stroke;
        }
      }
    }

    // Process elements
    final elementKeys = crdtMap.keys.where((k) => k.startsWith('element:'));
    for (final key in elementKeys) {
      final elementId = key.substring(8); // Remove 'element:' prefix
      if (!_elements.containsKey(elementId)) {
        final elementData = crdtMap[key] as Map<String, dynamic>;
        final element = _deserializeElement(elementId, elementData);
        if (element != null) {
          _elements[elementId] = element;
        }
      }
    }

    // Process metadata
    final metaKeys = crdtMap.keys.where((k) => k.startsWith('meta:'));
    for (final key in metaKeys) {
      final metaKey = key.substring(5); // Remove 'meta:' prefix
      _metadata[metaKey] = crdtMap[key];
    }
  }

  /// Get pending operations to send to server
  Map<String, dynamic> getPendingOperations() {
    return {
      'noteId': noteId,
      'operations': crdt.map,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Apply remote operations
  void applyOperations(Map<String, dynamic> operations) {
    try {
      final remoteMap = operations['operations'] as Map<String, dynamic>;
      crdt.merge(remoteMap);
    } catch (e) {
      debugPrint('Error applying operations: $e');
    }
  }

  /// Serialize stroke to JSON-compatible map
  Map<String, dynamic> _serializeStroke(Stroke stroke) {
    return {
      'points': stroke.points.map((p) => [p.x, p.y, p.p]).toList(),
      'color': stroke.color.value,
      'strokeWidth': stroke.strokeWidth,
      'isHighlighter': stroke.isHighlighter,
    };
  }

  /// Deserialize stroke from map
  Stroke? _deserializeStroke(String id, Map<String, dynamic> data) {
    try {
      // Note: Cannot reconstruct with original ID since Stroke auto-generates
      // This is a limitation that needs refactoring
      return null; // TODO: Refactor Stroke to accept ID parameter
    } catch (e) {
      debugPrint('Error deserializing stroke: $e');
      return null;
    }
  }

  /// Serialize element to JSON-compatible map
  Map<String, dynamic> _serializeElement(CanvasElement element) {
    if (element is TextElement) {
      return {
        'type': 'text',
        'text': element.text,
        'fontSize': element.fontSize,
        'color': element.color.value,
        'position': [element.position.dx, element.position.dy],
      };
    } else if (element is ImageElement) {
      return {
        'type': 'image',
        'imagePath': element.imagePath,
        'width': element.width,
        'height': element.height,
        'position': [element.position.dx, element.position.dy],
      };
    }
    return {};
  }

  /// Deserialize element from map
  CanvasElement? _deserializeElement(String id, Map<String, dynamic> data) {
    try {
      final type = data['type'] as String;
      // Note: Cannot reconstruct with original ID since CanvasElement auto-generates
      // This is a limitation that needs refactoring
      return null; // TODO: Refactor CanvasElement to accept ID parameter
    } catch (e) {
      debugPrint('Error deserializing element: $e');
      return null;
    }
  }

  /// Clear all data
  void clear() {
    _strokes.clear();
    _elements.clear();
    _metadata.clear();
    crdt.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _changesController.close();
    super.dispose();
  }
}

/// CRDT change event
class CrdtChange {
  final CrdtChangeType type;
  final String id;
  final dynamic data;

  CrdtChange({required this.type, required this.id, this.data});
}

/// Change type enum
enum CrdtChangeType {
  strokeAdded,
  strokeUpdated,
  strokeRemoved,
  elementAdded,
  elementUpdated,
  elementRemoved,
  metadataUpdated,
}
