/// Represents a Lua plugin
class Plugin {
  final String name;
  final String description;
  final String version;
  final String author;
  final String path;
  final String fullPath;
  final bool isEnabled;

  const Plugin({
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.path,
    required this.fullPath,
    required this.isEnabled,
  });

  Plugin copyWith({
    String? name,
    String? description,
    String? version,
    String? author,
    String? path,
    String? fullPath,
    bool? isEnabled,
  }) => Plugin(
    name: name ?? this.name,
    description: description ?? this.description,
    version: version ?? this.version,
    author: author ?? this.author,
    path: path ?? this.path,
    fullPath: fullPath ?? this.fullPath,
    isEnabled: isEnabled ?? this.isEnabled,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plugin && other.name == name && other.path == path;

  @override
  int get hashCode => Object.hash(name, path);
}
