// Multi Timer Service Tests
//
// Tests for parallel secondary timers functionality.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/productivity/multi_timer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecondaryTimer', () {
    test('creates with required properties', () {
      final timer = SecondaryTimer(
        id: 'test_timer',
        name: 'Test Timer',
        duration: const Duration(minutes: 5),
      );

      expect(timer.id, 'test_timer');
      expect(timer.name, 'Test Timer');
      expect(timer.duration, const Duration(minutes: 5));
      expect(timer.icon, Icons.timer);
      expect(timer.color, Colors.blue);
      expect(timer.repeat, false);
    });

    test('creates with custom properties', () {
      final timer = SecondaryTimer(
        id: 'custom_timer',
        name: 'Custom Timer',
        duration: const Duration(minutes: 10),
        icon: Icons.coffee,
        color: Colors.brown,
        message: 'Test message',
        repeat: true,
      );

      expect(timer.icon, Icons.coffee);
      expect(timer.color, Colors.brown);
      expect(timer.message, 'Test message');
      expect(timer.repeat, true);
    });

    test('initial state is idle', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );

      expect(timer.isIdle, true);
      expect(timer.isRunning, false);
      expect(timer.isPaused, false);
      expect(timer.isCompleted, false);
    });

    test('progress is 1 initially (full time remaining)', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );

      // Progress is 1 when idle (full time remaining, no time elapsed)
      expect(timer.progress, 1.0);
    });

    test('formattedTime shows minutes and seconds', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 5, seconds: 30),
      );
      timer.start();

      expect(timer.formattedTime, '05:30');
      timer.dispose();
    });

    test('formattedTime shows hours when needed', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(hours: 1, minutes: 30, seconds: 45),
      );
      timer.start();

      expect(timer.formattedTime, '01:30:45');
      timer.dispose();
    });

    test('start changes state to running', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );
      timer.start();

      expect(timer.isRunning, true);
      expect(timer.isIdle, false);
      timer.dispose();
    });

    test('pause changes state to paused', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );
      timer.start();
      timer.pause();

      expect(timer.isPaused, true);
      expect(timer.isRunning, false);
      timer.dispose();
    });

    test('resume changes state back to running', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );
      timer.start();
      timer.pause();
      timer.resume();

      expect(timer.isRunning, true);
      expect(timer.isPaused, false);
      timer.dispose();
    });

    test('stop resets the timer', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );
      timer.start();
      timer.stop();

      expect(timer.isIdle, true);
      expect(timer.isRunning, false);
      expect(timer.remainingTime, Duration.zero);
      timer.dispose();
    });

    test('reset sets time back to original duration', () {
      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 5),
      );
      timer.start();
      timer.reset();

      expect(timer.isIdle, true);
      expect(timer.remainingTime, const Duration(minutes: 5));
      timer.dispose();
    });

    test('toJson and fromJson work correctly', () {
      final timer = SecondaryTimer(
        id: 'test_timer',
        name: 'Test Timer',
        duration: const Duration(minutes: 5),
        icon: Icons.coffee,
        color: Colors.brown,
        message: 'Test message',
        repeat: true,
      );
      final json = timer.toJson();
      final restored = SecondaryTimer.fromJson(json);

      expect(restored.id, timer.id);
      expect(restored.name, timer.name);
      expect(restored.duration, timer.duration);
      expect(restored.icon.codePoint, timer.icon.codePoint);
      expect(restored.message, timer.message);
      expect(restored.repeat, timer.repeat);
    });
  });

  group('SecondaryTimerPreset', () {
    test('tea preset has correct values', () {
      expect(SecondaryTimerPreset.tea.name, 'Tea Timer');
      expect(SecondaryTimerPreset.tea.duration, const Duration(minutes: 5));
      expect(SecondaryTimerPreset.tea.repeat, false);
    });

    test('commit reminder has correct values', () {
      expect(SecondaryTimerPreset.commitReminder.name, 'Commit Reminder');
      expect(
        SecondaryTimerPreset.commitReminder.duration,
        const Duration(minutes: 30),
      );
      expect(SecondaryTimerPreset.commitReminder.repeat, true);
    });

    test('eye rest follows 20-20-20 rule', () {
      expect(SecondaryTimerPreset.eyeRest.name, 'Eye Rest (20-20-20)');
      expect(
        SecondaryTimerPreset.eyeRest.duration,
        const Duration(minutes: 20),
      );
      expect(SecondaryTimerPreset.eyeRest.repeat, true);
    });

    test('presets list contains all presets', () {
      expect(SecondaryTimerPreset.presets.length, 8);
      expect(SecondaryTimerPreset.presets, contains(SecondaryTimerPreset.tea));
      expect(
        SecondaryTimerPreset.presets,
        contains(SecondaryTimerPreset.commitReminder),
      );
      expect(
        SecondaryTimerPreset.presets,
        contains(SecondaryTimerPreset.eyeRest),
      );
    });

    test('toTimer creates valid SecondaryTimer', () {
      final timer = SecondaryTimerPreset.tea.toTimer();

      expect(timer.name, SecondaryTimerPreset.tea.name);
      expect(timer.duration, SecondaryTimerPreset.tea.duration);
      expect(timer.icon.codePoint, SecondaryTimerPreset.tea.icon.codePoint);
      expect(timer.repeat, SecondaryTimerPreset.tea.repeat);
      expect(timer.id, isNotEmpty);
    });

    test('toTimer with custom id uses provided id', () {
      final timer = SecondaryTimerPreset.tea.toTimer(customId: 'my_custom_id');
      expect(timer.id, 'my_custom_id');
    });
  });

  group('MultiTimerService', () {
    test('singleton instance exists', () {
      final service = MultiTimerService.instance;
      expect(service, isNotNull);
    });

    test('initial state has no timers', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();
      expect(service.timers, isEmpty);
      expect(service.activeCount, 0);
      expect(service.hasActiveTimers, false);
    });

    test('addTimer adds a timer', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      final timer = SecondaryTimer(
        id: 'test',
        name: 'Test',
        duration: const Duration(minutes: 1),
      );
      service.addTimer(timer);

      expect(service.timers.length, 1);
      expect(service.timers.first.id, 'test');

      service.clearAllTimers();
    });

    test('addFromPreset adds timer from preset', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      service.addFromPreset(SecondaryTimerPreset.tea);

      expect(service.timers.length, 1);
      expect(service.timers.first.name, 'Tea Timer');

      service.clearAllTimers();
    });

    test('removeTimer removes a timer', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      final timer = SecondaryTimer(
        id: 'to_remove',
        name: 'Remove Me',
        duration: const Duration(minutes: 1),
      );
      service.addTimer(timer);
      expect(service.timers.length, 1);

      service.removeTimer('to_remove');
      expect(service.timers, isEmpty);

      service.clearAllTimers();
    });

    test('startTimer starts a timer', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      final timer = SecondaryTimer(
        id: 'to_start',
        name: 'Start Me',
        duration: const Duration(minutes: 1),
      );
      service.addTimer(timer);
      service.startTimer('to_start');

      expect(service.timers.first.isRunning, true);
      expect(service.activeCount, 1);
      expect(service.hasActiveTimers, true);

      service.clearAllTimers();
    });

    test('pauseTimer pauses a timer', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      final timer = SecondaryTimer(
        id: 'to_pause',
        name: 'Pause Me',
        duration: const Duration(minutes: 1),
      );
      service.addTimer(timer);
      service.startTimer('to_pause');
      service.pauseTimer('to_pause');

      expect(service.timers.first.isPaused, true);
      expect(service.activeCount, 1); // Still active when paused

      service.clearAllTimers();
    });

    test('resumeTimer resumes a paused timer', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      final timer = SecondaryTimer(
        id: 'to_resume',
        name: 'Resume Me',
        duration: const Duration(minutes: 1),
      );
      service.addTimer(timer);
      service.startTimer('to_resume');
      service.pauseTimer('to_resume');
      service.resumeTimer('to_resume');

      expect(service.timers.first.isRunning, true);

      service.clearAllTimers();
    });

    test('stopTimer stops a timer', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      final timer = SecondaryTimer(
        id: 'to_stop',
        name: 'Stop Me',
        duration: const Duration(minutes: 1),
      );
      service.addTimer(timer);
      service.startTimer('to_stop');
      service.stopTimer('to_stop');

      expect(service.timers.first.isIdle, true);
      expect(service.activeCount, 0);

      service.clearAllTimers();
    });

    test('stopAllTimers stops all timers', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      service.addFromPreset(SecondaryTimerPreset.tea);
      service.addFromPreset(SecondaryTimerPreset.commitReminder);

      for (final timer in service.timers) {
        service.startTimer(timer.id);
      }
      expect(service.activeCount, 2);

      service.stopAllTimers();
      expect(service.activeCount, 0);

      service.clearAllTimers();
    });

    test('clearAllTimers removes all timers', () {
      final service = MultiTimerService.instance;
      service.clearAllTimers();

      service.addFromPreset(SecondaryTimerPreset.tea);
      service.addFromPreset(SecondaryTimerPreset.commitReminder);
      expect(service.timers.length, 2);

      service.clearAllTimers();
      expect(service.timers, isEmpty);
    });
  });
}
