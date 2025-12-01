import 'package:kivixa/services/life_git/models/snapshot.dart';

/// Represents a commit in Life Git
class LifeGitCommit {
  final String hash;
  final String message;
  final DateTime timestamp;
  final String? parentHash;
  final List<FileSnapshot> snapshots;

  const LifeGitCommit({
    required this.hash,
    required this.message,
    required this.timestamp,
    this.parentHash,
    required this.snapshots,
  });

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'parentHash': parentHash,
    'snapshots': snapshots.map((s) => s.toJson()).toList(),
  };

  factory LifeGitCommit.fromJson(Map<String, dynamic> json) => LifeGitCommit(
    hash: json['hash'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    parentHash: json['parentHash'] as String?,
    snapshots: (json['snapshots'] as List<dynamic>)
        .map((s) => FileSnapshot.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  LifeGitCommit copyWith({
    String? hash,
    String? message,
    DateTime? timestamp,
    String? parentHash,
    List<FileSnapshot>? snapshots,
  }) => LifeGitCommit(
    hash: hash ?? this.hash,
    message: message ?? this.message,
    timestamp: timestamp ?? this.timestamp,
    parentHash: parentHash ?? this.parentHash,
    snapshots: snapshots ?? this.snapshots,
  );

  /// Get the age of this commit as a human-readable string
  String get ageString {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} years ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  /// Short hash for display
  String get shortHash => hash.length > 7 ? hash.substring(0, 7) : hash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LifeGitCommit && other.hash == hash;

  @override
  int get hashCode => hash.hashCode;
}
