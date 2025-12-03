// Vector Database Service
//
// Provides semantic search capabilities using vector embeddings.
// Stores embeddings for all notes and enables similarity-based retrieval.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:path_provider/path_provider.dart';

/// An embedded note entry
class NoteEmbedding {
  final String noteId;
  final String title;
  final List<double> vector;
  final String? preview;
  final DateTime updatedAt;

  const NoteEmbedding({
    required this.noteId,
    required this.title,
    required this.vector,
    this.preview,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'title': title,
    'vector': vector,
    'preview': preview,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteEmbedding.fromJson(Map<String, dynamic> json) {
    return NoteEmbedding(
      noteId: json['noteId'] as String,
      title: json['title'] as String,
      vector: (json['vector'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      preview: json['preview'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Result of a semantic search
class SearchResult {
  final String noteId;
  final String title;
  final double score; // 0.0 to 1.0 (cosine similarity)
  final String? preview;

  const SearchResult({
    required this.noteId,
    required this.title,
    required this.score,
    this.preview,
  });
}

/// Vector Database Service singleton
class VectorDBService {
  static final _instance = VectorDBService._internal();
  factory VectorDBService() => _instance;
  VectorDBService._internal();

  final _inference = InferenceService();

  var _isInitialized = false;
  final Map<String, NoteEmbedding> _embeddings = {};

  /// Embedding dimension (from the model)
  var _dimension = 3072; // Phi-4 default, will be updated when model loads

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Number of indexed notes
  int get indexedCount => _embeddings.length;

  /// Initialize the vector database
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load cached embeddings from disk
    await _loadFromDisk();

    // Update dimension from model if available
    if (_inference.isModelLoaded && _inference.embeddingDimension != null) {
      _dimension = _inference.embeddingDimension!;
    }

    _isInitialized = true;
    debugPrint('VectorDBService initialized with $_dimension dimensions');
  }

  /// Index a note (compute and store its embedding)
  Future<void> indexNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    await initialize();

    if (!_inference.isModelLoaded) {
      debugPrint('Cannot index: model not loaded');
      return;
    }

    try {
      // Combine title and content for embedding
      final text = '$title\n\n$content';

      // Get embedding from inference service
      final vector = await _inference.getEmbedding(text);

      // Create preview
      final preview = content.length > 200
          ? '${content.substring(0, 200)}...'
          : content;

      final embedding = NoteEmbedding(
        noteId: noteId,
        title: title,
        vector: vector,
        preview: preview,
        updatedAt: DateTime.now(),
      );

      _embeddings[noteId] = embedding;

      // Persist to disk
      await _saveToDisk();

      debugPrint('Indexed note: $noteId');
    } catch (e) {
      debugPrint('Failed to index note $noteId: $e');
    }
  }

  /// Remove a note from the index
  Future<void> removeNote(String noteId) async {
    await initialize();

    _embeddings.remove(noteId);
    await _saveToDisk();
  }

  /// Semantic search for notes similar to the query
  Future<List<SearchResult>> search(
    String query, {
    int topK = 10,
    double threshold = 0.5,
  }) async {
    await initialize();

    if (!_inference.isModelLoaded) {
      debugPrint('Cannot search: model not loaded');
      return [];
    }

    if (_embeddings.isEmpty) {
      return [];
    }

    try {
      // Get embedding for query
      final queryVector = await _inference.getEmbedding(query);

      // Compute similarities
      final results = <SearchResult>[];

      for (final entry in _embeddings.values) {
        final score = _cosineSimilarity(queryVector, entry.vector);

        if (score >= threshold) {
          results.add(
            SearchResult(
              noteId: entry.noteId,
              title: entry.title,
              score: score,
              preview: entry.preview,
            ),
          );
        }
      }

      // Sort by score descending
      results.sort((a, b) => b.score.compareTo(a.score));

      // Return top-k
      return results.take(topK).toList();
    } catch (e) {
      debugPrint('Search failed: $e');
      return [];
    }
  }

  /// Find notes similar to a given note
  Future<List<SearchResult>> findSimilar(
    String noteId, {
    int topK = 5,
    double threshold = 0.6,
  }) async {
    await initialize();

    final embedding = _embeddings[noteId];
    if (embedding == null) {
      debugPrint('Note not indexed: $noteId');
      return [];
    }

    final results = <SearchResult>[];

    for (final entry in _embeddings.values) {
      if (entry.noteId == noteId) continue; // Skip self

      final score = _cosineSimilarity(embedding.vector, entry.vector);

      if (score >= threshold) {
        results.add(
          SearchResult(
            noteId: entry.noteId,
            title: entry.title,
            score: score,
            preview: entry.preview,
          ),
        );
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(topK).toList();
  }

  /// Cluster notes by semantic similarity
  Future<List<List<String>>> clusterNotes({double threshold = 0.7}) async {
    await initialize();

    final noteIds = _embeddings.keys.toList();
    final visited = <String>{};
    final clusters = <List<String>>[];

    for (final noteId in noteIds) {
      if (visited.contains(noteId)) continue;

      final cluster = <String>[noteId];
      visited.add(noteId);

      final embedding = _embeddings[noteId]!;

      for (final otherId in noteIds) {
        if (visited.contains(otherId)) continue;

        final otherEmbedding = _embeddings[otherId]!;
        final score = _cosineSimilarity(
          embedding.vector,
          otherEmbedding.vector,
        );

        if (score >= threshold) {
          cluster.add(otherId);
          visited.add(otherId);
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  /// Re-index all notes
  Future<void> reindexAll(
    Future<List<Map<String, dynamic>>> Function() getNotes,
  ) async {
    await initialize();

    _embeddings.clear();

    final notes = await getNotes();

    for (final note in notes) {
      await indexNote(
        noteId: note['id'] as String,
        title: note['title'] as String? ?? 'Untitled',
        content: note['content'] as String? ?? '',
      );
    }

    await _saveToDisk();
    debugPrint('Re-indexed ${_embeddings.length} notes');
  }

  /// Clear all embeddings
  Future<void> clear() async {
    _embeddings.clear();
    await _saveToDisk();
  }

  /// Compute cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = normA > 0 ? normA.sqrt() : 0;
    normB = normB > 0 ? normB.sqrt() : 0;

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (normA * normB);
  }

  /// Get the path to the embeddings cache file
  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/vector_db/embeddings.json');
  }

  /// Save embeddings to disk
  Future<void> _saveToDisk() async {
    try {
      final file = await _getCacheFile();
      await file.parent.create(recursive: true);

      final data = _embeddings.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save embeddings: $e');
    }
  }

  /// Load embeddings from disk
  Future<void> _loadFromDisk() async {
    try {
      final file = await _getCacheFile();
      // ignore: avoid_slow_async_io
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      for (final entry in data.entries) {
        _embeddings[entry.key] = NoteEmbedding.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      debugPrint('Loaded ${_embeddings.length} embeddings from disk');
    } catch (e) {
      debugPrint('Failed to load embeddings: $e');
    }
  }
}

extension on double {
  double sqrt() => this > 0 ? _sqrtDouble() : 0;
  double _sqrtDouble() {
    // Newton's method for square root
    if (this <= 0) return 0;
    double guess = this / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}
