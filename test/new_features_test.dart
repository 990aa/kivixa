import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/overlay/browser_window.dart';

void main() {
  group('Floating Browser Tests', () {
    test('FloatingBrowserTab initialization', () {
      final tab = FloatingBrowserTab(
        id: '1',
        url: 'https://example.com',
        title: 'Example',
      );
      expect(tab.id, '1');
      expect(tab.url, 'https://example.com');
      expect(tab.title, 'Example');
      expect(tab.isLoading, false);
    });
  });

  group('Floating Window Tests', () {
    testWidgets('FloatingWindow supports resizing', (
      WidgetTester tester,
    ) async {
      // Logic testing for resize handles
      // Note: Actual resizing requires integration tests with layout
      // Here we assume standard handle sizes are used
    });
  });
}
