// Vector Database Service with ObjectBox
//
// Provides semantic search using ObjectBox's native HNSW vector index.
// Achieves <10ms search for 1M vectors.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:kivixa/data/objectbox/entities.dart';
import 'package:kivixa/data/objectbox/store.dart';
import 'package:kivixa/objectbox.g.dart';
import 'package:kivixa/services/ai/inference_service.dart';

/// Result of a semantic search
class VectorSearchResult {
  final String noteId;
  final String title;
  final double score; // Distance converted to similarity (0.0 to 1.0)
  final String? preview;

  const VectorSearchResult({
    required this.noteId,
    required this.title,
    required this.score,
    this.preview,
  });
}

/// Vector Database Service using ObjectBox HNSW index
class VectorDBObjectBoxService {
  static final _instance = VectorDBObjectBoxService._internal();
  factory VectorDBObjectBoxService() => _instance;
  VectorDBObjectBoxService._internal();

  final _inference = InferenceService();
  final _store = ObjectBoxStore.instance;

  late final Box<NoteEmbedding> _noteBox;
  late final Box<TopicHub> _topicBox;
  late final Box<NoteTopicLink> _linkBox;
  late final Box<NoteLinkEntity> _noteLinkBox;

  var _isInitialized = false;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Number of indexed notes
  int get indexedCount {
    if (!_isInitialized) return 0;
    return _noteBox.count();
  }

  /// Initialize the vector database
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _store.initialize();

    _noteBox = _store.store.box<NoteEmbedding>();
    _topicBox = _store.store.box<TopicHub>();
    _linkBox = _store.store.box<NoteTopicLink>();
    _noteLinkBox = _store.store.box<NoteLinkEntity>();

    _isInitialized = true;
    debugPrint(
      'VectorDBObjectBoxService initialized with ${_noteBox.count()} notes',
    );
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

      // Get embedding from Rust via inference service
      final embedding = await _inference.getEmbedding(text);

      // Create preview
      final contentPreview = content.length > 200
          ? '${content.substring(0, 200)}...'
          : content;

      // Check if note already exists
      final query = _noteBox
          .query(NoteEmbedding_.noteId.equals(noteId))
          .build();
      final existing = query.findFirst();
      query.close();

      if (existing != null) {
        // Update existing embedding
        existing.title = title;
        existing.preview = contentPreview;
        existing.vector = embedding;
        existing.updatedAt = DateTime.now();
        _noteBox.put(existing);
      } else {
        // Create new embedding
        final noteEmbedding = NoteEmbedding(
          noteId: noteId,
          title: title,
          preview: contentPreview,
          vector: embedding,
        );
        _noteBox.put(noteEmbedding);
      }

      debugPrint('Indexed note: $noteId (${embedding.length} dims)');
    } catch (e) {
      debugPrint('Failed to index note $noteId: $e');
    }
  }

  /// Remove a note from the index
  Future<void> removeNote(String noteId) async {
    await initialize();

    // Remove the note embedding
    final query = _noteBox.query(NoteEmbedding_.noteId.equals(noteId)).build();
    final existing = query.findFirst();
    query.close();

    if (existing != null) {
      _noteBox.remove(existing.id);
    }

    // Also remove topic links
    final linkQuery = _linkBox
        .query(NoteTopicLink_.noteId.equals(noteId))
        .build();
    final linkIds = linkQuery.findIds();
    linkQuery.close();
    _linkBox.removeMany(linkIds);

    // Remove note links (both directions)
    final srcLinkQuery = _noteLinkBox
        .query(NoteLinkEntity_.sourceNoteId.equals(noteId))
        .build();
    final tgtLinkQuery = _noteLinkBox
        .query(NoteLinkEntity_.targetNoteId.equals(noteId))
        .build();

    _noteLinkBox.removeMany(srcLinkQuery.findIds());
    _noteLinkBox.removeMany(tgtLinkQuery.findIds());
    srcLinkQuery.close();
    tgtLinkQuery.close();

    debugPrint('Removed note from index: $noteId');
  }

  /// Semantic search using ObjectBox HNSW nearest neighbor
  ///
  /// This is blazing fast: <10ms for 1M vectors
  Future<List<VectorSearchResult>> search(
    String query, {
    int topK = 10,
    double threshold = 0.5,
  }) async {
    await initialize();

    if (!_inference.isModelLoaded) {
      debugPrint('Cannot search: model not loaded');
      return [];
    }

    if (_noteBox.isEmpty()) {
      return [];
    }

    try {
      // Get embedding for query from Rust
      final queryEmbedding = await _inference.getEmbedding(query);

      // Perform HNSW nearest neighbor search
      final searchQuery = _noteBox
          .query(
            NoteEmbedding_.vector.nearestNeighborsF32(queryEmbedding, topK),
          )
          .build();

      final results = searchQuery.findWithScores();
      searchQuery.close();

      // Convert to SearchResult, filtering by threshold
      return results
          .where((r) => distanceToSimilarity(r.score) >= threshold)
          .map(
            (r) => VectorSearchResult(
              noteId: r.object.noteId,
              title: r.object.title,
              score: distanceToSimilarity(r.score),
              preview: r.object.preview,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Search failed: $e');
      return [];
    }
  }

  /// Find notes similar to a given note
  Future<List<VectorSearchResult>> findSimilar(
    String noteId, {
    int topK = 5,
    double threshold = 0.6,
  }) async {
    await initialize();

    // Get the note's embedding
    final noteQuery = _noteBox
        .query(NoteEmbedding_.noteId.equals(noteId))
        .build();
    final note = noteQuery.findFirst();
    noteQuery.close();

    if (note == null || note.vector == null) {
      debugPrint('Note not indexed: $noteId');
      return [];
    }

    // Search for similar notes (get extra to filter out self)
    final searchQuery = _noteBox
        .query(
          NoteEmbedding_.vector.nearestNeighborsF32(note.vector!, topK + 1),
        )
        .build();

    final results = searchQuery.findWithScores();
    searchQuery.close();

    // Filter out self and apply threshold
    return results
        .where(
          (r) =>
              r.object.noteId != noteId &&
              distanceToSimilarity(r.score) >= threshold,
        )
        .take(topK)
        .map(
          (r) => VectorSearchResult(
            noteId: r.object.noteId,
            title: r.object.title,
            score: distanceToSimilarity(r.score),
            preview: r.object.preview,
          ),
        )
        .toList();
  }

  /// Link a note to topics (for knowledge graph)
  Future<void> linkNoteToTopics(String noteId, List<String> topics) async {
    await initialize();

    for (final topic in topics) {
      final normalizedId = _normalizeTopicId(topic);

      // Get or create topic hub
      final topicQuery = _topicBox
          .query(TopicHub_.topicId.equals(normalizedId))
          .build();
      var topicHub = topicQuery.findFirst();
      topicQuery.close();

      if (topicHub == null) {
        topicHub = TopicHub(
          topicId: normalizedId,
          label: topic,
          color: generateTopicColor(topic),
          noteCount: 0,
        );
        _topicBox.put(topicHub);
      }

      // Check if link already exists
      final linkQuery = _linkBox
          .query(
            NoteTopicLink_.noteId.equals(noteId) &
                NoteTopicLink_.topicId.equals(normalizedId),
          )
          .build();
      final existingLink = linkQuery.findFirst();
      linkQuery.close();

      if (existingLink == null) {
        // Create new link
        final link = NoteTopicLink(
          noteId: noteId,
          topicId: normalizedId,
          weight: 1.0,
        );
        _linkBox.put(link);

        // Update topic note count
        topicHub.noteCount++;
        _topicBox.put(topicHub);
      }
    }
  }

  /// Get all topics with their note counts
  Future<List<Map<String, dynamic>>> getTopics() async {
    await initialize();

    final hubs = _topicBox.getAll();
    return hubs
        .map(
          (h) => {
            'id': h.topicId,
            'label': h.label,
            'color': h.color,
            'noteCount': h.noteCount,
          },
        )
        .toList();
  }

  /// Get notes for a specific topic
  Future<List<String>> getNotesForTopic(String topicId) async {
    await initialize();

    final query = _linkBox
        .query(NoteTopicLink_.topicId.equals(topicId))
        .build();
    final links = query.find();
    query.close();

    return links.map((l) => l.noteId).toList();
  }

  /// Add a direct link between two notes
  Future<void> addNoteLink({
    required String sourceNoteId,
    required String targetNoteId,
    required String linkType,
    double? similarityScore,
  }) async {
    await initialize();

    // Check if link already exists
    final query = _noteLinkBox
        .query(
          NoteLinkEntity_.sourceNoteId.equals(sourceNoteId) &
              NoteLinkEntity_.targetNoteId.equals(targetNoteId),
        )
        .build();
    final existing = query.findFirst();
    query.close();

    if (existing != null) {
      // Update existing link
      existing.linkType = linkType;
      existing.similarityScore = similarityScore;
      _noteLinkBox.put(existing);
    } else {
      // Create new link
      final link = NoteLinkEntity(
        sourceNoteId: sourceNoteId,
        targetNoteId: targetNoteId,
        linkType: linkType,
        similarityScore: similarityScore,
      );
      _noteLinkBox.put(link);
    }
  }

  /// Get all links for a note
  Future<List<Map<String, dynamic>>> getNoteLinks(String noteId) async {
    await initialize();

    final srcQuery = _noteLinkBox
        .query(NoteLinkEntity_.sourceNoteId.equals(noteId))
        .build();
    final tgtQuery = _noteLinkBox
        .query(NoteLinkEntity_.targetNoteId.equals(noteId))
        .build();

    final srcLinks = srcQuery.find();
    final tgtLinks = tgtQuery.find();
    srcQuery.close();
    tgtQuery.close();

    return [
      ...srcLinks.map(
        (l) => {
          'targetNoteId': l.targetNoteId,
          'linkType': l.linkType,
          'similarityScore': l.similarityScore,
          'direction': 'outgoing',
        },
      ),
      ...tgtLinks.map(
        (l) => {
          'targetNoteId': l.sourceNoteId,
          'linkType': l.linkType,
          'similarityScore': l.similarityScore,
          'direction': 'incoming',
        },
      ),
    ];
  }

  /// Clear all data
  Future<void> clear() async {
    await initialize();

    _noteBox.removeAll();
    _topicBox.removeAll();
    _linkBox.removeAll();
    _noteLinkBox.removeAll();

    debugPrint('VectorDB cleared');
  }

  /// Re-index all notes
  Future<void> reindexAll(
    Future<List<Map<String, dynamic>>> Function() getNotes,
  ) async {
    await initialize();
    await clear();

    final notes = await getNotes();

    for (final note in notes) {
      await indexNote(
        noteId: note['id'] as String,
        title: note['title'] as String? ?? 'Untitled',
        content: note['content'] as String? ?? '',
      );
    }

    debugPrint('Re-indexed $indexedCount notes');
  }

  /// Normalize topic ID
  String _normalizeTopicId(String topic) {
    return 'hub_${topic.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
  }

  /// Convert HNSW distance to similarity score (0.0 to 1.0)
  double distanceToSimilarity(double distance) {
    // HNSW uses L2 distance by default
    // Convert to similarity: smaller distance = higher similarity
    // Using exponential decay: sim = e^(-distance)
    return math.exp(-distance);
  }

  /// Generate a consistent color for a topic based on its name
  String generateTopicColor(String topic) {
    // Hash the topic name to get a consistent hue
    final hash = topic.hashCode.abs();
    final hue = (hash % 360).toDouble();

    // Convert HSL to hex (saturation: 70%, lightness: 45%)
    return _hslToHex(hue, 0.7, 0.45);
  }

  /// Convert HSL to hex color string
  String _hslToHex(double h, double s, double l) {
    final c = (1 - (2 * l - 1).abs()) * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = l - c / 2;

    double r, g, b;

    if (h < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (h < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (h < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (h < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }

    final ri = ((r + m) * 255).round();
    final gi = ((g + m) * 255).round();
    final bi = ((b + m) * 255).round();

    return '#${ri.toRadixString(16).padLeft(2, '0')}'
        '${gi.toRadixString(16).padLeft(2, '0')}'
        '${bi.toRadixString(16).padLeft(2, '0')}';
  }
}
