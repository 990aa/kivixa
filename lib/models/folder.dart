class Folder {
  int? id;
  String name;
  String cover;
  DateTime createdAt;

  Folder({
    this.id,
    required this.name,
    required this.cover,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cover': cover,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
