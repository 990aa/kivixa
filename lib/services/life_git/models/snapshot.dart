/// Represents a snapshot of a file at a specific point in time
class FileSnapshot {
  final String path;
  final String blobHash;
  final bool exists;
  final DateTime modifiedAt;

  const FileSnapshot({
    required this.path,
    required this.blobHash,
    required this.exists,
    required this.modifiedAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'blobHash': blobHash,
    'exists': exists,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  factory FileSnapshot.fromJson(Map<String, dynamic> json) => FileSnapshot(
    path: json['path'] as String,
    blobHash: json['blobHash'] as String,
    exists: json['exists'] as bool,
    modifiedAt: DateTime.parse(json['modifiedAt'] as String),
  );

  FileSnapshot copyWith({
    String? path,
    String? blobHash,
    bool? exists,
    DateTime? modifiedAt,
  }) => FileSnapshot(
    path: path ?? this.path,
    blobHash: blobHash ?? this.blobHash,
    exists: exists ?? this.exists,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileSnapshot &&
          other.path == path &&
          other.blobHash == blobHash &&
          other.exists == exists;

  @override
  int get hashCode => Object.hash(path, blobHash, exists);
}
