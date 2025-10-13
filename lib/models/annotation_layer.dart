import 'dart:convert';
import 'annotation_data.dart';
import 'image_annotation.dart';

/// Model that manages multiple annotations for a PDF document
///
/// This class acts as a container for all annotations across all pages,
/// providing methods to add, remove, undo strokes, and persist the annotation state.
/// It maintains separate lists for each page for efficient rendering.
class AnnotationLayer {
  /// Map of page numbers to lists of annotations for that page
  /// Using a map allows fast lookup and efficient per-page rendering
  final Map<int, List<AnnotationData>> _annotationsByPage;

  /// Map of page numbers to lists of image annotations for that page
  final Map<int, List<ImageAnnotation>> _imageAnnotationsByPage;

  /// History stack for undo functionality
  /// Stores removed annotations in reverse chronological order
  final List<AnnotationData> _undoStack;

  /// Maximum size of undo stack to prevent memory issues
  final int maxUndoStackSize;

  AnnotationLayer({
    Map<int, List<AnnotationData>>? annotationsByPage,
    Map<int, List<ImageAnnotation>>? imageAnnotationsByPage,
    this.maxUndoStackSize = 100,
  }) : _annotationsByPage = annotationsByPage ?? {},
       _imageAnnotationsByPage = imageAnnotationsByPage ?? {},
       _undoStack = [];

  /// Gets all annotations for a specific page
  /// Returns an empty list if the page has no annotations
  List<AnnotationData> getAnnotationsForPage(int pageNumber) {
    return _annotationsByPage[pageNumber] ?? [];
  }

  /// Gets all image annotations for a specific page
  /// Returns an empty list if the page has no image annotations
  List<ImageAnnotation> getImageAnnotationsForPage(int pageNumber) {
    return _imageAnnotationsByPage[pageNumber] ?? [];
  }

  /// Adds a new annotation to the layer
  /// Automatically groups it by page number for efficient rendering
  void addAnnotation(AnnotationData annotation) {
    final pageNumber = annotation.pageNumber;

    if (!_annotationsByPage.containsKey(pageNumber)) {
      _annotationsByPage[pageNumber] = [];
    }

    _annotationsByPage[pageNumber]!.add(annotation);
  }

  /// Adds a new image annotation to the layer
  void addImageAnnotation(ImageAnnotation imageAnnotation) {
    final pageNumber = imageAnnotation.pageNumber;

    if (!_imageAnnotationsByPage.containsKey(pageNumber)) {
      _imageAnnotationsByPage[pageNumber] = [];
    }

    _imageAnnotationsByPage[pageNumber]!.add(imageAnnotation);
  }

  /// Updates an existing image annotation
  void updateImageAnnotation(ImageAnnotation updatedImage) {
    final pageNumber = updatedImage.pageNumber;
    final pageImages = _imageAnnotationsByPage[pageNumber];

    if (pageImages != null) {
      final index = pageImages.indexWhere((img) => img.id == updatedImage.id);
      if (index != -1) {
        pageImages[index] = updatedImage;
      }
    }
  }

  /// Removes an image annotation from the layer
  bool removeImageAnnotation(ImageAnnotation imageAnnotation) {
    final pageNumber = imageAnnotation.pageNumber;
    final pageImages = _imageAnnotationsByPage[pageNumber];

    if (pageImages != null) {
      final initialLength = pageImages.length;
      pageImages.removeWhere((img) => img.id == imageAnnotation.id);
      final removed = pageImages.length < initialLength;

      // Clean up empty page entries
      if (pageImages.isEmpty) {
        _imageAnnotationsByPage.remove(pageNumber);
      }

      return removed;
    }

    return false;
  }

  /// Removes a specific annotation from the layer
  /// Adds it to the undo stack for potential restoration
  bool removeAnnotation(AnnotationData annotation) {
    final pageNumber = annotation.pageNumber;
    final pageAnnotations = _annotationsByPage[pageNumber];

    if (pageAnnotations != null) {
      final removed = pageAnnotations.remove(annotation);

      if (removed) {
        // Add to undo stack
        _undoStack.add(annotation);

        // Maintain max stack size
        if (_undoStack.length > maxUndoStackSize) {
          _undoStack.removeAt(0);
        }

        // Clean up empty page entries
        if (pageAnnotations.isEmpty) {
          _annotationsByPage.remove(pageNumber);
        }
      }

      return removed;
    }

    return false;
  }

  /// Removes the most recently added annotation (undo last stroke)
  /// Returns the removed annotation or null if there are no annotations
  AnnotationData? undoLastStroke() {
    if (_annotationsByPage.isEmpty) return null;

    // Find the most recent annotation across all pages
    AnnotationData? mostRecent;
    int? targetPage;

    for (var entry in _annotationsByPage.entries) {
      final pageAnnotations = entry.value;
      if (pageAnnotations.isNotEmpty) {
        final lastAnnotation = pageAnnotations.last;
        if (mostRecent == null ||
            lastAnnotation.timestamp.isAfter(mostRecent.timestamp)) {
          mostRecent = lastAnnotation;
          targetPage = entry.key;
        }
      }
    }

    if (mostRecent != null && targetPage != null) {
      _annotationsByPage[targetPage]!.removeLast();

      // Add to undo stack
      _undoStack.add(mostRecent);
      if (_undoStack.length > maxUndoStackSize) {
        _undoStack.removeAt(0);
      }

      // Clean up empty page entries
      if (_annotationsByPage[targetPage]!.isEmpty) {
        _annotationsByPage.remove(targetPage);
      }
    }

    return mostRecent;
  }

  /// Restores the last undone annotation (redo)
  /// Returns true if successful, false if undo stack is empty
  bool redoLastUndo() {
    if (_undoStack.isEmpty) return false;

    final annotation = _undoStack.removeLast();
    addAnnotation(annotation);

    return true;
  }

  /// Clears all annotations from a specific page
  void clearPage(int pageNumber) {
    final pageAnnotations = _annotationsByPage[pageNumber];
    if (pageAnnotations != null) {
      _undoStack.addAll(pageAnnotations);

      // Maintain max stack size
      while (_undoStack.length > maxUndoStackSize) {
        _undoStack.removeAt(0);
      }

      _annotationsByPage.remove(pageNumber);
    }
  }

  /// Clears all annotations from all pages
  void clearAll() {
    for (var annotations in _annotationsByPage.values) {
      _undoStack.addAll(annotations);
    }

    // Maintain max stack size
    while (_undoStack.length > maxUndoStackSize) {
      _undoStack.removeAt(0);
    }

    _annotationsByPage.clear();
  }

  /// Gets the total number of annotations across all pages
  int get totalAnnotationCount {
    return _annotationsByPage.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Gets all page numbers that have annotations
  List<int> get annotatedPages {
    return _annotationsByPage.keys.toList()..sort();
  }

  /// Exports all annotations to JSON format for persistence
  ///
  /// The resulting JSON can be saved to a file and later loaded
  /// to restore the complete annotation state
  String exportToJson() {
    final Map<String, dynamic> data = {
      'version': '1.0.0', // Version for future compatibility
      'totalAnnotations': totalAnnotationCount,
      'pages': _annotationsByPage.map(
        (pageNumber, annotations) => MapEntry(
          pageNumber.toString(),
          annotations.map((a) => a.toJson()).toList(),
        ),
      ),
    };

    return jsonEncode(data);
  }

  /// Imports annotations from JSON format
  ///
  /// This replaces the current annotations with those from the JSON.
  /// To merge with existing annotations, use importFromJson with merge option.
  factory AnnotationLayer.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final Map<String, dynamic> pagesData =
        data['pages'] as Map<String, dynamic>;

    final Map<int, List<AnnotationData>> annotationsByPage = {};

    for (var entry in pagesData.entries) {
      final pageNumber = int.parse(entry.key);
      final List<dynamic> annotationsJson = entry.value;

      annotationsByPage[pageNumber] = annotationsJson
          .map((json) => AnnotationData.fromJson(json))
          .toList();
    }

    return AnnotationLayer(annotationsByPage: annotationsByPage);
  }

  /// Merges annotations from JSON into the current layer
  /// Useful for collaborative editing or merging multiple annotation files
  void importFromJson(String jsonString, {bool clearExisting = false}) {
    if (clearExisting) {
      clearAll();
    }

    final importedLayer = AnnotationLayer.fromJson(jsonString);

    for (var entry in importedLayer._annotationsByPage.entries) {
      for (var annotation in entry.value) {
        addAnnotation(annotation);
      }
    }
  }

  @override
  String toString() {
    return 'AnnotationLayer(pages: ${annotatedPages.length}, '
        'total annotations: $totalAnnotationCount)';
  }
}
