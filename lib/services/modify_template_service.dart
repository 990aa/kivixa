/// Represents the minimal set of instructions the UI needs to re-render.
class ReRenderPlan {
  /// List of page IDs whose content needs a full redraw.
  final List<String> pagesToRedraw;

  /// List of thumbnail IDs that need to be regenerated.
  final List<String> thumbnailsToInvalidate;

  ReRenderPlan({
    required this.pagesToRedraw,
    required this.thumbnailsToInvalidate,
  });

  bool get isEmpty => pagesToRedraw.isEmpty && thumbnailsToInvalidate.isEmpty;
}

/// Represents the properties of a page template that can be modified.
class TemplateProperties {
  final String? backgroundColor;
  final String? linePattern; // e.g., 'dotted', 'lined', 'grid'
  final double? lineSpacing;

  TemplateProperties({this.backgroundColor, this.linePattern, this.lineSpacing});
}

// Assume a service exists for managing thumbnail caches.
class _ThumbnailCacheService {
  void invalidate(List<String> thumbnailIds) {
    print('Invalidating thumbnails: $thumbnailIds');
  }
}

class ModifyTemplateService {
  static final ModifyTemplateService _instance = ModifyTemplateService._internal();
  factory ModifyTemplateService() => _instance;
  ModifyTemplateService._internal();

  final _ThumbnailCacheService _thumbnailCache = _ThumbnailCacheService();

  /// Updates the properties of a template and returns a plan for the UI to re-render.
  ///
  /// [templateId] The ID of the template to modify.
  /// [affectedPageIds] A list of all page IDs that use this template.
  /// [newProperties] The new properties to apply to the template.
  Future<ReRenderPlan> updateTemplate({
    required String templateId,
    required List<String> affectedPageIds,
    required TemplateProperties newProperties,
  }) async {
    // 1. Persist the template property changes to the database (simulated).
    await _updateTemplateInDatabase(templateId, newProperties);

    // 2. Invalidate the thumbnail cache for all affected pages.
    // We assume a naming convention or mapping from page ID to thumbnail ID.
    final thumbnailIdsToInvalidate = affectedPageIds.map((id) => 'thumb_$id').toList();
    _thumbnailCache.invalidate(thumbnailIdsToInvalidate);

    // 3. Return a re-render plan.
    // For a template change, all pages using it need to be redrawn.
    return ReRenderPlan(
      pagesToRedraw: affectedPageIds,
      thumbnailsToInvalidate: thumbnailIdsToInvalidate,
    );
  }

  Future<void> _updateTemplateInDatabase(String templateId, TemplateProperties properties) async {
    // Simulate a database update.
    await Future.delayed(const Duration(milliseconds: 150));
    print('Updated template $templateId in database.');
  }
}
