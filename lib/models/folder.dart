class Folder {
  int? id;
  String name;
  String cover;
  DateTime createdAt;
  int? colorValue; // Store color as int (nullable for backward compatibility)

  Folder({
    this.id,
    required this.name,
    required this.cover,
    required this.createdAt,
    this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cover': cover,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      cover: map['cover'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      colorValue: map['colorValue'] as int?,
    );
  }
}
