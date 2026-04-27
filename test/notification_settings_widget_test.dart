import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/settings/notification_settings_widget.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:kivixa/services/notification_sound_catalog_service.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
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

  tearDown(() async {
    final soundsDir = Directory('notification_sounds');
    if (soundsDir.existsSync()) {
      await soundsDir.delete(recursive: true);
    }
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
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);

      // Lead-time selection is now dropdown-style menu, not horizontal chips.
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byTooltip('Select lead-time reminders'), findsOneWidget);
    },
  );

  testWidgets('sound and vibration toggles persist independent combinations', (
    tester,
  ) async {
    await pumpWidgetUnderTest(tester);

    final soundTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Sound'),
    );
    final vibrationTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Vibration'),
    );

    soundTile.onChanged?.call(false);
    vibrationTile.onChanged?.call(true);
    await tester.pumpAndSettle();

    var settings = await NotificationSettingsStorage.loadSettings();
    expect(settings.notificationSoundEnabled, isFalse);
    expect(settings.notificationVibrationEnabled, isTrue);
    expect(
      settings.notificationFeedbackMode,
      NotificationFeedbackMode.vibrationOnly,
    );

    final updatedSoundTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Sound'),
    );
    updatedSoundTile.onChanged?.call(true);
    await tester.pumpAndSettle();

    settings = await NotificationSettingsStorage.loadSettings();
    expect(settings.notificationSoundEnabled, isTrue);
    expect(settings.notificationVibrationEnabled, isTrue);
    expect(
      settings.notificationFeedbackMode,
      NotificationFeedbackMode.soundAndVibration,
    );
  });

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

  testWidgets(
    'deleting downloaded selected sound falls back to default and refreshes UI',
    (tester) async {
      final option = NotificationSoundCatalogService.reminderSoundOptions
          .firstWhere((it) => it.id == 'alarm_wind_chimes');
      final soundsDir = Directory('notification_sounds')
        ..createSync(recursive: true);
      File(
        '${soundsDir.path}${Platform.pathSeparator}${option.fileName}',
      ).writeAsBytesSync([1, 2, 3, 4]);

      await NotificationSettingsStorage.saveSettings(
        NotificationSettings(reminderSoundId: option.id),
      );

      await pumpWidgetUnderTest(tester);

      final windChimesTile = find.widgetWithText(ListTile, 'Wind Chimes');
      expect(windChimesTile, findsOneWidget);
      expect(
        find.descendant(of: windChimesTile, matching: find.text('Delete')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: windChimesTile, matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();

      final settings = await NotificationSettingsStorage.loadSettings();
      expect(
        settings.reminderSoundId,
        NotificationSoundCatalogService.defaultReminderSoundId,
      );
      expect(
        find.descendant(of: windChimesTile, matching: find.text('Download')),
        findsOneWidget,
      );
    },
  );
}
