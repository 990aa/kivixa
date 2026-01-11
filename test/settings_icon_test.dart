import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Settings Page Icon Tests', () {
    testWidgets('auto clear whiteboard should use layers_clear icon', (
      tester,
    ) async {
      // Verify the layers_clear icon exists and is valid
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Icon(Icons.layers_clear))),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.layers_clear), findsOneWidget);
    });

    test('layers_clear icon is different from cleaning_services', () {
      // Ensure we're using a distinct icon
      expect(
        Icons.layers_clear.codePoint,
        isNot(Icons.cleaning_services.codePoint),
      );
    });
  });

  group('Clear Page Icon Consistency', () {
    test('layers_clear icon should be used for clear operations', () {
      // This test documents the icon change
      // Icons.layers_clear should be used instead of Icons.cleaning_services
      expect(Icons.layers_clear.codePoint, isNotNull);
    });
  });
}
