// TemplatesService: Manages templates and provides a small in-memory cache.
class Template {
  final String id;
  final String orientation; // 'portrait' or 'landscape'
  final String size; // e.g., 'A4', 'borderless'
  final String backgroundColor;
  final String backgroundTexture;
  final double gridSpacing;
  final double lineSpacing;
  final double dotSpacing;
  final int columns;
  final String styleCategory; // e.g., 'study', 'professional', 'plan'
  final String coverImage;
  final bool isDefaultQuickNote;

  Template({
    required this.id,
    required this.orientation,
    required this.size,
    required this.backgroundColor,
    required this.backgroundTexture,
    required this.gridSpacing,
    required this.lineSpacing,
    required this.dotSpacing,
    required this.columns,
    required this.styleCategory,
    required this.coverImage,
    required this.isDefaultQuickNote,
  });
}

class TemplatesService {
  final Map<String, Template> _templates = {};
  Template? _cache;
  String? _cacheId;

  // Add or update a template
  void upsertTemplate(Template template) {
    _templates[template.id] = template;
    _invalidateCache();
  }

  // Get a template by id (with cache)
  Template? getTemplate(String id) {
    if (_cacheId == id && _cache != null) return _cache;
    _cache = _templates[id];
    _cacheId = id;
    return _cache;
  }

  // Invalidate cache
  void _invalidateCache() {
    _cache = null;
    _cacheId = null;
  }

  // List all templates
  List<Template> getAllTemplates() => _templates.values.toList();
}
