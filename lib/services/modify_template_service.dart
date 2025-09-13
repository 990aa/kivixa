import 'package:flutter/painting.dart';

/// Represents the visual properties of a page template.
class TemplateProperties {
  final Color? backgroundColor;
  final String? linePattern; // e.g., 'dotted', 'ruled', 'grid'
  final Color? lineColor;
  final double? lineSpacing;

  TemplateProperties({
    this.backgroundColor,
    this.linePattern,
    this.lineColor,
    this.lineSpacing,
  });
}

/// Describes the minimal set of UI updates required after a template change.
///
/// This allows the UI to avoid a full document re-render.
class ReRenderPlan {
  /// The list of page IDs whose thumbnails need to be redrawn.
  final List<String> invalidatedThumbnails;

  /// The list of page IDs whose main canvas needs a background redraw.
  final List<String> pagesToRedraw;

  ReRenderPlan({
    required this.invalidatedThumbnails,
    required this.pagesToRedraw,
  });
}

/// A service for modifying page templates and calculating the necessary UI updates.
class ModifyTemplateService {

  // A stub for a thumbnail cache. In a real app, this would be a more
  // sophisticated cache management system.
  final Set<String> _thumbnailCache = {'page1', 'page2', 'page3'};

  /// Updates the template properties for a given set of pages.
  ///
  /// This invalidates the thumbnail cache for the affected pages and returns
  /// a minimal re-render plan for the UI to apply.
  Future<ReRenderPlan> updateTemplateProperties(
    List<String> pageIds,
    TemplateProperties newProperties,
  ) async {
    // 1. Persist the template changes.
    // In a real implementation, this would update the page models in the database.
    print("Updating template for pages: $pageIds with properties: ${newProperties.linePattern}");

    // 2. Invalidate the thumbnail cache for the affected pages.
    final invalidated = <String>[];
    for (final pageId in pageIds) {
      if (_thumbnailCache.contains(pageId)) {
        _thumbnailCache.remove(pageId);
        invalidated.add(pageId);
      }
    }
    print("Invalidated thumbnails for pages: $invalidated");


    // 3. Return a minimal re-render plan.
    // For this stub, we'll just assume the currently visible pages need a full redraw.
    // A more complex implementation would check which of the pageIds are visible.
    return ReRenderPlan(
      invalidatedThumbnails: invalidated,
      pagesToRedraw: pageIds,
    );
  }
}