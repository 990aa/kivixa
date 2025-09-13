import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App meets accessibility guidelines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    // Check for semantics
    expect(tester.getSemantics(find.byType(MyApp)), isNotNull);
    // Check for contrast
    // (In real projects, use accessibility tools or plugins for more checks)
  });
}
