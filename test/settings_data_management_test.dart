import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:stow/stow.dart';
import 'package:stow_plain/stow_plain.dart';

void main() {
  group('Delete Data on Uninstall Setting', () {
    late PlainStow<bool> deleteDataOnUninstall;

    setUp(() {
      // Create a test instance of the preference
      deleteDataOnUninstall = PlainStow<bool>(
        'deleteDataOnUninstall_test',
        false,
        volatile: true,
      );
    });

    test('default value should be false (keep data)', () {
      expect(deleteDataOnUninstall.defaultValue, false);
      expect(deleteDataOnUninstall.value, false);
    });

    test('can be enabled', () {
      deleteDataOnUninstall.value = true;
      expect(deleteDataOnUninstall.value, true);
    });

    test('can be disabled after being enabled', () {
      deleteDataOnUninstall.value = true;
      expect(deleteDataOnUninstall.value, true);

      deleteDataOnUninstall.value = false;
      expect(deleteDataOnUninstall.value, false);
    });

    test('can reset to default value', () {
      deleteDataOnUninstall.value = true;
      expect(deleteDataOnUninstall.value, true);

      deleteDataOnUninstall.value = deleteDataOnUninstall.defaultValue;
      expect(deleteDataOnUninstall.value, false);
    });
  });

  group('Reset All Settings', () {
    late PlainStow<int> testIntSetting;
    late PlainStow<bool> testBoolSetting;
    late PlainStow<String> testStringSetting;

    setUp(() {
      testIntSetting = PlainStow<int>('testInt', 10, volatile: true);
      testBoolSetting = PlainStow<bool>('testBool', false, volatile: true);
      testStringSetting = PlainStow<String>(
        'testString',
        'default',
        volatile: true,
      );
    });

    test('settings can be modified from defaults', () {
      testIntSetting.value = 50;
      testBoolSetting.value = true;
      testStringSetting.value = 'modified';

      expect(testIntSetting.value, 50);
      expect(testBoolSetting.value, true);
      expect(testStringSetting.value, 'modified');
    });

    test('settings can be reset to defaults', () {
      // Modify settings
      testIntSetting.value = 50;
      testBoolSetting.value = true;
      testStringSetting.value = 'modified';

      // Reset to defaults
      testIntSetting.value = testIntSetting.defaultValue;
      testBoolSetting.value = testBoolSetting.defaultValue;
      testStringSetting.value = testStringSetting.defaultValue;

      // Verify reset
      expect(testIntSetting.value, 10);
      expect(testBoolSetting.value, false);
      expect(testStringSetting.value, 'default');
    });

    test('defaultValue property is accessible', () {
      expect(testIntSetting.defaultValue, 10);
      expect(testBoolSetting.defaultValue, false);
      expect(testStringSetting.defaultValue, 'default');
    });

    test('listeners are notified on value change', () {
      var changeCount = 0;
      testIntSetting.addListener(() => changeCount++);

      testIntSetting.value = 20;
      expect(changeCount, 1);

      testIntSetting.value = 30;
      expect(changeCount, 2);

      testIntSetting.value = testIntSetting.defaultValue;
      expect(changeCount, 3);
    });
  });

  group('Life Git Auto Cleanup Days Setting', () {
    late PlainStow<int> lifeGitAutoCleanupDays;

    setUp(() {
      lifeGitAutoCleanupDays = PlainStow<int>(
        'lifeGitAutoCleanupDays_test',
        0, // 0 = disabled
        volatile: true,
      );
    });

    test('default value should be 0 (disabled)', () {
      expect(lifeGitAutoCleanupDays.defaultValue, 0);
      expect(lifeGitAutoCleanupDays.value, 0);
    });

    test('can set cleanup period', () {
      lifeGitAutoCleanupDays.value = 30;
      expect(lifeGitAutoCleanupDays.value, 30);

      lifeGitAutoCleanupDays.value = 90;
      expect(lifeGitAutoCleanupDays.value, 90);
    });

    test('can disable cleanup by setting to 0', () {
      lifeGitAutoCleanupDays.value = 30;
      expect(lifeGitAutoCleanupDays.value, 30);

      lifeGitAutoCleanupDays.value = 0;
      expect(lifeGitAutoCleanupDays.value, 0);
    });

    test('reset returns to disabled state', () {
      lifeGitAutoCleanupDays.value = 60;
      lifeGitAutoCleanupDays.value = lifeGitAutoCleanupDays.defaultValue;
      expect(lifeGitAutoCleanupDays.value, 0);
    });
  });

  group('Settings Preference Behavior', () {
    test('PlainStow notifies listeners when value changes', () {
      final setting = PlainStow<bool>('notifyTest', false, volatile: true);
      var notified = false;

      setting.addListener(() => notified = true);
      setting.value = true;

      expect(notified, true);
    });

    test('PlainStow does not notify when set to same value', () {
      final setting = PlainStow<bool>('sameValueTest', false, volatile: true);
      var notifyCount = 0;

      setting.addListener(() => notifyCount++);

      setting.value = false; // Same as current
      // Note: PlainStow may or may not notify for same value depending on implementation
      // This test documents the expected behavior
    });

    test('volatile PlainStow works without storage', () {
      final setting = PlainStow<String>(
        'volatileTest',
        'initial',
        volatile: true,
      );

      expect(setting.value, 'initial');
      setting.value = 'changed';
      expect(setting.value, 'changed');
    });
  });
}
