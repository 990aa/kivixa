import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/settings/notification_settings_widget.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => '.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NotificationService.forceIsSupported = false;
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({
      'notification_settings': NotificationSettings().toJsonString(),
    });
  });

  Future<void> pumpWidgetUnderTest(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: NotificationSettingsWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows unified notifications sections and dropdown lead selector',
    (tester) async {
      await pumpWidgetUnderTest(tester);

      expect(find.text('Calendar Notifications'), findsOneWidget);
      expect(find.text('Sound & Vibration'), findsOneWidget);
      expect(find.text('Productivity Timer Notifications'), findsOneWidget);

      // Lead-time selection is now dropdown-style menu, not horizontal chips.
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byTooltip('Select lead-time reminders'), findsOneWidget);
    },
  );

  testWidgets(
    'lead time popup toggles reminder options and persists settings',
    (tester) async {
      await pumpWidgetUnderTest(tester);

      final leadTimeMenu = tester.widget<PopupMenuButton<int>>(
        find.byType(PopupMenuButton<int>),
      );
      leadTimeMenu.onSelected?.call(5);
      await tester.pumpAndSettle();

      var settings = await NotificationSettingsStorage.loadSettings();
      expect(settings.leadTimesInMinutes, contains(5));

      leadTimeMenu.onSelected?.call(5);
      await tester.pumpAndSettle();

      settings = await NotificationSettingsStorage.loadSettings();
      expect(settings.leadTimesInMinutes, isNot(contains(5)));
    },
  );

  testWidgets('timer sound toggle updates productivity timer service', (
    tester,
  ) async {
    final timerService = ProductivityTimerService.instance;
    timerService.setSoundEnabled(true);

    await pumpWidgetUnderTest(tester);

    final soundTileFinder = find.widgetWithText(
      SwitchListTile,
      'Timer Sound Alerts',
    );
    expect(soundTileFinder, findsOneWidget);
    final soundTile = tester.widget<SwitchListTile>(soundTileFinder);

    final initial = timerService.soundEnabled;
    expect(initial, isTrue);

    soundTile.onChanged?.call(!initial);
    await tester.pumpAndSettle();

    expect(timerService.soundEnabled, isNot(initial));

    // Restore for test isolation.
    timerService.setSoundEnabled(true);
  });
}
