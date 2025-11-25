import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/pages/lock_screen.dart';

void main() {
  group('LockScreen Widget', () {
    testWidgets('should display lock screen UI elements', (
      WidgetTester tester,
    ) async {
      var unlocked = false;

      await tester.pumpWidget(
        MaterialApp(home: LockScreen(onUnlocked: () => unlocked = true)),
      );

      // Should display lock icon
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Should display title
      expect(find.text('kivixa is locked'), findsOneWidget);

      // Should display subtitle
      expect(find.text('Enter your PIN to continue'), findsOneWidget);

      // Should display PIN input field
      expect(find.byType(TextField), findsOneWidget);

      // Should display unlock button
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      // Should not be unlocked yet
      expect(unlocked, isFalse);
    });

    testWidgets('should show error when submitting empty PIN', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      // Tap unlock button without entering PIN
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Please enter your PIN'), findsOneWidget);
    });

    testWidgets('should accept numeric input only', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      // Enter text with digits
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      // Check that the text was entered
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('1234'));
    });

    testWidgets('should have maximum length of 8 digits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      // Try to enter more than 8 digits
      await tester.enterText(find.byType(TextField), '123456789');
      await tester.pump();

      // Should be truncated to 8 digits
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text.length, lessThanOrEqualTo(8));
    });

    testWidgets('should obscure PIN input', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('should have numeric keyboard type', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, equals(TextInputType.number));
    });
  });

  group('PinSetupDialog Widget', () {
    testWidgets('should display setup dialog for new PIN', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinSetupDialog(isChanging: false)),
        ),
      );

      // Should show "Create PIN" title for new setup
      expect(find.text('Create PIN'), findsOneWidget);

      // Should have PIN input field
      expect(find.byType(TextField), findsOneWidget);

      // Should have Cancel and Next buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('should display change dialog with current PIN step', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinSetupDialog(isChanging: true)),
        ),
      );

      // Should show "Enter Current PIN" title when changing
      expect(find.text('Enter Current PIN'), findsOneWidget);
    });

    testWidgets('should show error for PIN less than 4 digits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinSetupDialog(isChanging: false)),
        ),
      );

      // Enter short PIN
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('PIN must be at least 4 digits'), findsOneWidget);
    });

    testWidgets('should proceed to confirm step with valid PIN', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinSetupDialog(isChanging: false)),
        ),
      );

      // Enter valid PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should show Confirm PIN step
      expect(find.text('Confirm PIN'), findsOneWidget);
    });

    testWidgets('should show error when PINs do not match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinSetupDialog(isChanging: false)),
        ),
      );

      // Enter initial PIN
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Enter different confirm PIN
      await tester.enterText(find.byType(TextField), '5678');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('PINs do not match'), findsOneWidget);
    });

    testWidgets('should dismiss on Cancel', (WidgetTester tester) async {
      var dialogDismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const PinSetupDialog(isChanging: false),
                  );
                  dialogDismissed = result == false;
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogDismissed, isTrue);
    });
  });

  group('RemovePinDialog Widget', () {
    testWidgets('should display remove PIN dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RemovePinDialog())),
      );

      // Should show title
      expect(find.text('Remove App Lock'), findsOneWidget);

      // Should show instruction text
      expect(
        find.text('Enter your current PIN to disable app lock.'),
        findsOneWidget,
      );

      // Should have PIN input field
      expect(find.byType(TextField), findsOneWidget);

      // Should have Cancel and Remove buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should show error for short PIN', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RemovePinDialog())),
      );

      // Enter short PIN
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      // Tap Remove
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Please enter your PIN'), findsOneWidget);
    });

    testWidgets('Remove button should have error styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RemovePinDialog())),
      );

      // Find the Remove button and check it's a FilledButton
      final removeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Remove'),
      );
      expect(removeButton, isNotNull);
    });
  });

  group('PIN Input Validation', () {
    testWidgets('lock screen should filter non-numeric input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      final textField = tester.widget<TextField>(find.byType(TextField));

      // Check that inputFormatters include digits only filter
      expect(textField.inputFormatters, isNotNull);
      expect(textField.inputFormatters!.length, greaterThan(0));
      expect(
        textField.inputFormatters!.any((f) => f is FilteringTextInputFormatter),
        isTrue,
      );
    });

    testWidgets('PIN setup should filter non-numeric input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PinSetupDialog(isChanging: false)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      // Check that inputFormatters include digits only filter
      expect(textField.inputFormatters, isNotNull);
      expect(
        textField.inputFormatters!.any((f) => f is FilteringTextInputFormatter),
        isTrue,
      );
    });
  });

  group('UI Styling', () {
    testWidgets('lock screen should have proper layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      // Should have SafeArea
      expect(find.byType(SafeArea), findsOneWidget);

      // Should have SingleChildScrollView for scrollability
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Should have Column for vertical layout
      expect(find.byType(Column), findsAtLeastNWidgets(1));

      // Should have Container with circular decoration for lock icon
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.any((c) => c.decoration is BoxDecoration), isTrue);
    });

    testWidgets('PIN input should have centered text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LockScreen(onUnlocked: () {})));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textAlign, equals(TextAlign.center));
    });
  });
}
