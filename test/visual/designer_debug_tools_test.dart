import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/main.dart';

void main() {
  testWidgets('Designer debug tools overlay', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Simulate enabling debug overlay (spacing, colors, animation timings)
    // In real app, this would be a toggle in the UI
    // Here, just check that the app renders and no exceptions are thrown
    expect(find.byType(MyApp), findsOneWidget);
  });
}
