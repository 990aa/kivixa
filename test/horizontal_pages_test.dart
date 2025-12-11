import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/canvas/_asset_cache.dart';
import 'package:kivixa/data/editor/page.dart';

void main() {
  group('PageOrientation', () {
    test('portrait orientation has correct default size', () {
      expect(
        PageOrientation.portrait.defaultSize,
        equals(EditorPage.defaultPortraitSize),
      );
      expect(
        PageOrientation.portrait.defaultSize.width,
        lessThan(PageOrientation.portrait.defaultSize.height),
      );
    });

    test('landscape orientation has correct default size', () {
      expect(
        PageOrientation.landscape.defaultSize,
        equals(EditorPage.defaultLandscapeSize),
      );
      expect(
        PageOrientation.landscape.defaultSize.width,
        greaterThan(PageOrientation.landscape.defaultSize.height),
      );
    });

    test('opposite returns the other orientation', () {
      expect(PageOrientation.portrait.opposite, PageOrientation.landscape);
      expect(PageOrientation.landscape.opposite, PageOrientation.portrait);
    });
  });

  group('EditorPage orientation', () {
    test('default page is portrait', () {
      final page = EditorPage();
      expect(page.orientation, PageOrientation.portrait);
      expect(page.isPortrait, true);
      expect(page.isLandscape, false);
    });

    test('explicit portrait orientation creates portrait page', () {
      final page = EditorPage(orientation: PageOrientation.portrait);
      expect(page.orientation, PageOrientation.portrait);
      expect(page.size.width, lessThan(page.size.height));
    });

    test('explicit landscape orientation creates landscape page', () {
      final page = EditorPage(orientation: PageOrientation.landscape);
      expect(page.orientation, PageOrientation.landscape);
      expect(page.size.width, greaterThan(page.size.height));
      expect(page.isLandscape, true);
      expect(page.isPortrait, false);
    });

    test('landscape page has swapped dimensions', () {
      final portrait = EditorPage(orientation: PageOrientation.portrait);
      final landscape = EditorPage(orientation: PageOrientation.landscape);

      expect(portrait.size.width, equals(landscape.size.height));
      expect(portrait.size.height, equals(landscape.size.width));
    });

    test('copyWith preserves orientation', () {
      final original = EditorPage(orientation: PageOrientation.landscape);
      final copy = original.copyWith();
      expect(copy.orientation, PageOrientation.landscape);
    });

    test('copyWith can change orientation', () {
      final original = EditorPage(orientation: PageOrientation.landscape);
      final copy = original.copyWith(orientation: PageOrientation.portrait);
      expect(copy.orientation, PageOrientation.portrait);
    });
  });

  group('EditorPage JSON serialization', () {
    test('portrait page serializes without orientation field', () {
      final page = EditorPage(orientation: PageOrientation.portrait);
      final json = page.toJson(OrderedAssetCache());
      expect(json.containsKey('o'), false);
    });

    test('landscape page serializes with orientation field', () {
      final page = EditorPage(orientation: PageOrientation.landscape);
      final json = page.toJson(OrderedAssetCache());
      expect(json['o'], PageOrientation.landscape.index);
    });

    test('page size is correctly serialized', () {
      final landscape = EditorPage(orientation: PageOrientation.landscape);
      final json = landscape.toJson(OrderedAssetCache());
      expect(json['w'], EditorPage.defaultLandscapeSize.width);
      expect(json['h'], EditorPage.defaultLandscapeSize.height);
    });
  });
}
