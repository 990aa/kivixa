class Pdf {
  int? id;
  String name;
  String path;
  int folderId;

  Pdf({
    this.id,
    required this.name,
    required this.path,
    required this.folderId,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'path': path, 'folderId': folderId};
  }

  factory Pdf.fromMap(Map<String, dynamic> map) {
    return Pdf(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      folderId: map['folderId'],
    );
  }
}
