bool matchesSettingsQuery({
  required String query,
  required String category,
  String? description,
  List<String> keywords = const <String>[],
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }

  final haystack = <String>[
    category,
    ?description,
    ...keywords,
  ].join(' ').toLowerCase();

  return haystack.contains(normalizedQuery);
}
