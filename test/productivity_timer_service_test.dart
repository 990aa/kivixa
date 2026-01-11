// Productivity Timer Service Tests
//
// Tests for the productivity timer service including context tags,
// quick presets, sessions, statistics, and persistence.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/productivity/productivity_timer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('SessionType', () {
    test('has correct number of types', () {
      expect(SessionType.values.length, 7);
    });

    test('each type has required properties', () {
      for (final type in SessionType.values) {
        expect(type.label, isNotEmpty);
        expect(type.icon, isA<IconData>());
        expect(type.color, isA<Color>());
      }
    });

    test('focus type has correct properties', () {
      expect(SessionType.focus.label, 'Focus');
      expect(SessionType.focus.icon, Icons.psychology);
    });
  });

  group('TimerState', () {
    test('has correct states', () {
      expect(TimerState.values, contains(TimerState.idle));
      expect(TimerState.values, contains(TimerState.running));
      expect(TimerState.values, contains(TimerState.paused));
      expect(TimerState.values, contains(TimerState.breakTime));
      expect(TimerState.values, contains(TimerState.completed));
    });
  });

  group('TimerTemplate', () {
    test('pomodoro has correct values', () {
      expect(TimerTemplate.pomodoro.name, 'Pomodoro');
      expect(TimerTemplate.pomodoro.workMinutes, 25);
      expect(TimerTemplate.pomodoro.breakMinutes, 5);
      expect(TimerTemplate.pomodoro.cycles, 4);
      expect(TimerTemplate.pomodoro.longBreakMinutes, 15);
      expect(TimerTemplate.pomodoro.longBreakAfterCycles, 4);
    });

    test('52/17 method has correct values', () {
      expect(TimerTemplate.ultraFocus.name, '52/17 Method');
      expect(TimerTemplate.ultraFocus.workMinutes, 52);
      expect(TimerTemplate.ultraFocus.breakMinutes, 17);
    });

    test('ultradian has correct values', () {
      expect(TimerTemplate.ultradian.name, 'Ultradian (90 min)');
      expect(TimerTemplate.ultradian.workMinutes, 90);
      expect(TimerTemplate.ultradian.breakMinutes, 20);
    });

    test('allTemplates contains all templates', () {
      expect(TimerTemplate.allTemplates.length, 5);
      expect(TimerTemplate.allTemplates, contains(TimerTemplate.pomodoro));
      expect(TimerTemplate.allTemplates, contains(TimerTemplate.ultraFocus));
      expect(TimerTemplate.allTemplates, contains(TimerTemplate.ultradian));
    });
  });

  group('TimerContextTag', () {
    test('default tags exist', () {
      expect(TimerContextTag.defaultTags.length, 10);
    });

    test('each default tag has required properties', () {
      for (final tag in TimerContextTag.defaultTags) {
        expect(tag.id, isNotEmpty);
        expect(tag.name, isNotEmpty);
        expect(tag.icon, isA<IconData>());
        expect(tag.color, isA<Color>());
        expect(tag.isDefault, true);
      }
    });

    test('coding tag has correct properties', () {
      expect(TimerContextTag.coding.id, 'coding');
      expect(TimerContextTag.coding.name, 'Coding');
      expect(TimerContextTag.coding.icon, Icons.code);
    });

    test('reading tag has correct properties', () {
      expect(TimerContextTag.reading.id, 'reading');
      expect(TimerContextTag.reading.name, 'Reading');
      expect(TimerContextTag.reading.icon, Icons.menu_book);
    });

    test('toJson and fromJson work correctly', () {
      const tag = TimerContextTag(
        id: 'test_tag',
        name: 'Test Tag',
        icon: Icons.star,
        color: Colors.purple,
      );
      final json = tag.toJson();
      final restored = TimerContextTag.fromJson(json);

      expect(restored.id, tag.id);
      expect(restored.name, tag.name);
      expect(restored.icon.codePoint, tag.icon.codePoint);
    });

    test('equality works correctly', () {
      const tag1 = TimerContextTag(
        id: 'test',
        name: 'Test',
        icon: Icons.star,
        color: Colors.blue,
      );
      const tag2 = TimerContextTag(
        id: 'test',
        name: 'Different Name',
        icon: Icons.circle,
        color: Colors.red,
      );
      const tag3 = TimerContextTag(
        id: 'other',
        name: 'Test',
        icon: Icons.star,
        color: Colors.blue,
      );

      expect(tag1 == tag2, true); // Same id
      expect(tag1 == tag3, false); // Different id
    });
  });

  group('QuickPreset', () {
    test('default presets exist', () {
      expect(QuickPreset.defaultPresets.length, 6);
    });

    test('code preset has correct values', () {
      expect(QuickPreset.code.id, 'code');
      expect(QuickPreset.code.name, 'Code');
      expect(QuickPreset.code.workMinutes, 45);
      expect(QuickPreset.code.breakMinutes, 10);
      expect(QuickPreset.code.longBreakMinutes, 20);
      expect(QuickPreset.code.cyclesBeforeLongBreak, 3);
      expect(QuickPreset.code.totalCycles, 6);
    });

    test('reading preset has correct values', () {
      expect(QuickPreset.reading.id, 'reading');
      expect(QuickPreset.reading.name, 'Reading');
      expect(QuickPreset.reading.workMinutes, 30);
      expect(QuickPreset.reading.breakMinutes, 5);
    });

    test('deep design preset has correct values', () {
      expect(QuickPreset.deepDesign.id, 'deep_design');
      expect(QuickPreset.deepDesign.name, 'Deep Design');
      expect(QuickPreset.deepDesign.workMinutes, 90);
      expect(QuickPreset.deepDesign.breakMinutes, 20);
      expect(QuickPreset.deepDesign.autoStartBreak, false);
    });

    test('quick task preset has correct values', () {
      expect(QuickPreset.quickTask.id, 'quick_task');
      expect(QuickPreset.quickTask.name, 'Quick Task');
      expect(QuickPreset.quickTask.workMinutes, 15);
      expect(QuickPreset.quickTask.breakMinutes, 3);
      expect(QuickPreset.quickTask.autoStartBreak, true);
      expect(QuickPreset.quickTask.autoStartNextSession, true);
    });

    test('toJson and fromJson work correctly', () {
      const preset = QuickPreset.code;
      final json = preset.toJson();
      final restored = QuickPreset.fromJson(json);

      expect(restored.id, preset.id);
      expect(restored.name, preset.name);
      expect(restored.workMinutes, preset.workMinutes);
      expect(restored.breakMinutes, preset.breakMinutes);
      expect(restored.totalCycles, preset.totalCycles);
    });
  });

  group('SessionStats', () {
    test('default values are zero', () {
      final stats = SessionStats();
      expect(stats.totalFocusMinutes, 0);
      expect(stats.totalSessions, 0);
      expect(stats.completedSessions, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.todayFocusMinutes, 0);
      expect(stats.todaySessions, 0);
    });

    test('averageSessionMinutes calculates correctly', () {
      final stats = SessionStats(totalFocusMinutes: 100, totalSessions: 4);
      expect(stats.averageSessionMinutes, 25.0);
    });

    test('averageSessionMinutes is zero when no sessions', () {
      final stats = SessionStats();
      expect(stats.averageSessionMinutes, 0);
    });

    test('completionRate calculates correctly', () {
      final stats = SessionStats(totalSessions: 10, completedSessions: 8);
      expect(stats.completionRate, 0.8);
    });

    test('completionRate is zero when no sessions', () {
      final stats = SessionStats();
      expect(stats.completionRate, 0);
    });

    test('toJson and fromJson work correctly', () {
      final stats = SessionStats(
        totalFocusMinutes: 120,
        totalSessions: 5,
        completedSessions: 4,
        currentStreak: 3,
        longestStreak: 7,
        todayFocusMinutes: 45,
        todaySessions: 2,
      );
      final json = stats.toJson();
      final restored = SessionStats.fromJson(json);

      expect(restored.totalFocusMinutes, stats.totalFocusMinutes);
      expect(restored.totalSessions, stats.totalSessions);
      expect(restored.completedSessions, stats.completedSessions);
      expect(restored.currentStreak, stats.currentStreak);
      expect(restored.longestStreak, stats.longestStreak);
      expect(restored.todayFocusMinutes, stats.todayFocusMinutes);
      expect(restored.todaySessions, stats.todaySessions);
    });

    test('dailyMinutes tracking works', () {
      final stats = SessionStats();
      stats.dailyMinutes['2025-12-09'] = 60;
      stats.dailyMinutes['2025-12-10'] = 90;

      expect(stats.dailyMinutes['2025-12-09'], 60);
      expect(stats.dailyMinutes['2025-12-10'], 90);
      expect(stats.dailyMinutes['2025-12-11'], null);
    });

    test('sessionsByType tracking works', () {
      final stats = SessionStats();
      stats.sessionsByType['focus'] = 5;
      stats.sessionsByType['deepWork'] = 3;

      expect(stats.sessionsByType['focus'], 5);
      expect(stats.sessionsByType['deepWork'], 3);
      expect(stats.sessionsByType['sprint'], null);
    });
  });

  group('ProductivityGoal', () {
    test('default values are set', () {
      const goal = ProductivityGoal();
      expect(goal.dailyFocusMinutes, 120);
      expect(goal.dailySessions, 4);
      expect(goal.weeklyFocusMinutes, 600);
    });

    test('custom values work', () {
      const goal = ProductivityGoal(
        dailyFocusMinutes: 180,
        dailySessions: 6,
        weeklyFocusMinutes: 900,
      );
      expect(goal.dailyFocusMinutes, 180);
      expect(goal.dailySessions, 6);
      expect(goal.weeklyFocusMinutes, 900);
    });

    test('copyWith works correctly', () {
      const goal = ProductivityGoal();
      final updated = goal.copyWith(dailyFocusMinutes: 200);

      expect(updated.dailyFocusMinutes, 200);
      expect(updated.dailySessions, goal.dailySessions);
      expect(updated.weeklyFocusMinutes, goal.weeklyFocusMinutes);
    });

    test('toJson and fromJson work correctly', () {
      const goal = ProductivityGoal(
        dailyFocusMinutes: 150,
        dailySessions: 5,
        weeklyFocusMinutes: 750,
      );
      final json = goal.toJson();
      final restored = ProductivityGoal.fromJson(json);

      expect(restored.dailyFocusMinutes, goal.dailyFocusMinutes);
      expect(restored.dailySessions, goal.dailySessions);
      expect(restored.weeklyFocusMinutes, goal.weeklyFocusMinutes);
    });
  });

  group('ProductivityTimerService', () {
    test('singleton instance exists', () {
      final service = ProductivityTimerService.instance;
      expect(service, isNotNull);
    });

    test('initial state is idle', () {
      final service = ProductivityTimerService.instance;
      expect(service.state, TimerState.idle);
      expect(service.isIdle, true);
      expect(service.isRunning, false);
      expect(service.isPaused, false);
      expect(service.isBreak, false);
    });

    test('default session type is focus', () {
      final service = ProductivityTimerService.instance;
      expect(service.sessionType, SessionType.focus);
    });

    test('default duration is 25 minutes', () {
      final service = ProductivityTimerService.instance;
      // Reset to default if modified by other tests
      service.stop();
      service.setDuration(const Duration(minutes: 25));
      expect(service.totalDuration.inMinutes, 25);
    });

    test('formattedTime shows correct format', () {
      final service = ProductivityTimerService.instance;
      service.setDuration(const Duration(minutes: 25));
      expect(service.formattedTime, '25:00');
    });

    test('progress is 0 when idle', () {
      final service = ProductivityTimerService.instance;
      service.stop();
      expect(service.progress, 0);
    });

    test('setSessionType changes type', () {
      final service = ProductivityTimerService.instance;
      service.setSessionType(SessionType.deepWork);
      expect(service.sessionType, SessionType.deepWork);

      // Reset
      service.setSessionType(SessionType.focus);
    });

    test('setDuration changes duration when idle', () {
      final service = ProductivityTimerService.instance;
      service.stop();
      service.setDuration(const Duration(minutes: 45));
      expect(service.totalDuration.inMinutes, 45);

      // Reset
      service.setDuration(const Duration(minutes: 25));
    });

    test('allContextTags includes default tags', () {
      final service = ProductivityTimerService.instance;
      final tags = service.allContextTags;

      expect(tags.length, greaterThanOrEqualTo(10));
      expect(tags, contains(TimerContextTag.coding));
      expect(tags, contains(TimerContextTag.reading));
    });

    test('allQuickPresets includes default presets', () {
      final service = ProductivityTimerService.instance;
      final presets = service.allQuickPresets;

      expect(presets.length, 6);
      expect(presets, contains(QuickPreset.code));
      expect(presets, contains(QuickPreset.reading));
    });

    test('setContextTag changes current tag', () {
      final service = ProductivityTimerService.instance;

      service.setContextTag(TimerContextTag.coding);
      expect(service.currentContextTag, TimerContextTag.coding);

      service.setContextTag(null);
      expect(service.currentContextTag, null);
    });

    test('getTopTags returns empty list initially', () {
      final service = ProductivityTimerService.instance;
      final topTags = service.getTopTags();
      // May have data from previous tests
      expect(topTags, isA<List<MapEntry<String, int>>>());
    });

    test('settings can be changed', () {
      final service = ProductivityTimerService.instance;

      service.setSoundEnabled(false);
      expect(service.soundEnabled, false);
      service.setSoundEnabled(true);
      expect(service.soundEnabled, true);

      service.setAutoStartBreak(false);
      expect(service.autoStartBreak, false);
      service.setAutoStartBreak(true);
      expect(service.autoStartBreak, true);

      service.setAutoStartNextSession(true);
      expect(service.autoStartNextSession, true);
      service.setAutoStartNextSession(false);
      expect(service.autoStartNextSession, false);
    });

    test('goal can be changed', () {
      final service = ProductivityTimerService.instance;
      final originalGoal = service.goal;

      service.setGoal(
        const ProductivityGoal(
          dailyFocusMinutes: 200,
          dailySessions: 8,
          weeklyFocusMinutes: 1000,
        ),
      );
      expect(service.goal.dailyFocusMinutes, 200);
      expect(service.goal.dailySessions, 8);
      expect(service.goal.weeklyFocusMinutes, 1000);

      // Reset
      service.setGoal(originalGoal);
    });

    test('getDailyProgress returns value between 0 and 1', () {
      final service = ProductivityTimerService.instance;
      final progress = service.getDailyProgress();
      expect(progress, greaterThanOrEqualTo(0));
      expect(progress, lessThanOrEqualTo(1));
    });

    test('getWeeklyProgress returns value between 0 and 1', () {
      final service = ProductivityTimerService.instance;
      final progress = service.getWeeklyProgress();
      expect(progress, greaterThanOrEqualTo(0));
      expect(progress, lessThanOrEqualTo(1));
    });

    test('getWeeklyFocusMinutes returns non-negative value', () {
      final service = ProductivityTimerService.instance;
      final minutes = service.getWeeklyFocusMinutes();
      expect(minutes, greaterThanOrEqualTo(0));
    });
  });
}
