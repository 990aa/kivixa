class Notebook {
  final int? id;
  final String title;
  final int createdAt;
  final int updatedAt;

  Notebook({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
    id: json['id'] as int?,
    title: json['title'] as String,
    createdAt: json['created_at'] as int,
    updatedAt: json['updated_at'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

// Repeat similar model classes for Document, Page, Layer, StrokeChunk, etc.
