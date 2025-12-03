// ObjectBox Entity Models for Vector Search
//
// These entities use ObjectBox's native HNSW vector index for
// fast nearest-neighbor search (<10ms for 1M vectors).

import 'package:objectbox/objectbox.dart';

/// Embedding dimension for Phi-4 Mini model
/// Note: Verify this by checking the actual model output dimension
const kEmbeddingDimension = 3072;

/// A note with its vector embedding for semantic search
@Entity()
class NoteEmbedding {
  @Id()
  var id = 0;

  /// The unique identifier of the note (e.g., file path or UUID)
  @Unique()
  String noteId;

  /// The note title for display
  String title;

  /// A preview of the note content
  String? preview;

  /// The vector embedding for semantic search
  /// Using HNSW index for fast nearest-neighbor queries
  @HnswIndex(dimensions: kEmbeddingDimension)
  @Property(type: PropertyType.floatVector)
  List<double>? vector;

  /// When this embedding was last updated
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  /// Optional metadata as JSON string
  String? metadata;

  NoteEmbedding({
    required this.noteId,
    required this.title,
    this.preview,
    this.vector,
    DateTime? updatedAt,
    this.metadata,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

/// A topic hub node in the knowledge graph
@Entity()
class TopicHub {
  @Id()
  var id = 0;

  /// Unique topic identifier (lowercase, underscored)
  @Unique()
  String topicId;

  /// Display label for the topic
  String label;

  /// Color for visualization (hex string)
  String? color;

  /// Number of notes connected to this topic
  int noteCount;

  /// Average embedding of all connected notes (for topic similarity)
  @HnswIndex(dimensions: kEmbeddingDimension)
  @Property(type: PropertyType.floatVector)
  List<double>? centroidVector;

  TopicHub({
    required this.topicId,
    required this.label,
    this.color,
    this.noteCount = 0,
    this.centroidVector,
  });
}

/// A link between a note and a topic
@Entity()
class NoteTopicLink {
  @Id()
  var id = 0;

  /// The note ID
  String noteId;

  /// The topic ID
  String topicId;

  /// Link strength (1.0 = primary topic, lower = secondary)
  double weight;

  NoteTopicLink({
    required this.noteId,
    required this.topicId,
    this.weight = 1.0,
  });
}

/// A direct link between two notes
@Entity()
class NoteLinkEntity {
  @Id()
  var id = 0;

  /// Source note ID
  String sourceNoteId;

  /// Target note ID
  String targetNoteId;

  /// Link type: "explicit" (user-created), "similarity" (auto-detected)
  String linkType;

  /// Similarity score if auto-detected
  double? similarityScore;

  NoteLinkEntity({
    required this.sourceNoteId,
    required this.targetNoteId,
    required this.linkType,
    this.similarityScore,
  });
}
