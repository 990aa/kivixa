import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/modify_template_service.dart';

void main() {
  group('ModifyTemplateService', () {
    test('updateTemplateProperties invalidates correct thumbnails', () async {
      // Arrange
      final service = ModifyTemplateService();
      final pagesToUpdate = ['page1', 'page3'];
      final newProperties = TemplateProperties(linePattern: 'grid');

      // Act
      final reRenderPlan = await service.updateTemplateProperties(
        pagesToUpdate,
        newProperties,
      );

      // Assert
      // It should identify that page1 and page3 were in the "cache" and are now invalidated.
      expect(reRenderPlan.invalidatedThumbnails, unorderedEquals(['page1', 'page3']));

      // It should also request a redraw for the pages that were modified.
      expect(reRenderPlan.pagesToRedraw, unorderedEquals(['page1', 'page3']));

      // It should not invalidate thumbnails that were not part of the update.
      expect(reRenderPlan.invalidatedThumbnails, isNot(contains('page2')));
    });

     test('updateTemplateProperties handles pages not in cache', () async {
      // Arrange
      final service = ModifyTemplateService();
      final pagesToUpdate = ['page4', 'page5']; // These are not in the initial cache
      final newProperties = TemplateProperties(backgroundColor: const Color(0xFFFFFF00));

      // Act
      final reRenderPlan = await service.updateTemplateProperties(
        pagesToUpdate,
        newProperties,
      );

      // Assert
      // No thumbnails should be invalidated because they weren't in the cache to begin with.
      expect(reRenderPlan.invalidatedThumbnails, isEmpty);

      // It should still request a redraw for the modified pages.
      expect(reRenderPlan.pagesToRedraw, unorderedEquals(['page4', 'page5']));
    });
  });
}
