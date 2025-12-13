# Productivity Clock Testing Guide

This document provides a comprehensive testing guide for the Kivixa Productivity Clock feature, including the main timer, multi-timer orchestration, and chained routines.

## Table of Contents

- [Overview](#overview)
- [Test Files](#test-files)
- [Running Tests](#running-tests)
- [Unit Tests Coverage](#unit-tests-coverage)
  - [Productivity Timer Service](#productivity-timer-service)
  - [Multi-Timer Service](#multi-timer-service)
  - [Chained Routine Service](#chained-routine-service)
- [Manual Testing Guide](#manual-testing-guide)
- [Integration Testing](#integration-testing)
- [Performance Testing](#performance-testing)
- [Accessibility Testing](#accessibility-testing)

---

## Overview

The Productivity Clock feature consists of three main components:

1. **Productivity Timer Service** - Core Pomodoro-style timer with context tags and quick presets
2. **Multi-Timer Service** - Parallel secondary timers for reminders and tracking
3. **Chained Routine Service** - Sequential timed routine blocks for structured workflows

## Test Files

| Test File | Component | Test Count |
|-----------|-----------|------------|
| `test/productivity_timer_service_test.dart` | ProductivityTimerService, TimerContextTag, QuickPreset | 52 |
| `test/multi_timer_service_test.dart` | SecondaryTimer, SecondaryTimerPreset, MultiTimerService | 30 |
| `test/chained_routine_service_test.dart` | RoutineBlock, ChainedRoutine, ChainedRoutineService | 33 |

## Running Tests

### Run All Productivity Tests

```bash
flutter test test/productivity_timer_service_test.dart test/multi_timer_service_test.dart test/chained_routine_service_test.dart
```

### Run Individual Test File

```bash
# Productivity Timer
flutter test test/productivity_timer_service_test.dart

# Multi-Timer
flutter test test/multi_timer_service_test.dart

# Chained Routines
flutter test test/chained_routine_service_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage test/productivity_timer_service_test.dart test/multi_timer_service_test.dart test/chained_routine_service_test.dart
```

### Run Specific Test Group

```bash
# Example: Run only QuickPreset tests
flutter test test/productivity_timer_service_test.dart --name "QuickPreset"
```

---

## Unit Tests Coverage

### Productivity Timer Service

#### SessionType Enum
- ✅ Has correct number of types (5)
- ✅ Each type has required properties (name, defaultMinutes, color, icon)
- ✅ Focus type has correct properties (25 min, blue)

#### TimerState Enum
- ✅ Has all expected states (idle, running, paused, completed)

#### TimerTemplate
- ✅ Pomodoro has correct values (25/5/4)
- ✅ 52/17 method has correct values
- ✅ Ultradian has correct values (90/20/2)
- ✅ allTemplates contains all templates

#### TimerContextTag
- ✅ Default tags exist (9 built-in)
- ✅ Each default tag has required properties
- ✅ Coding tag has correct properties (blue, code icon)
- ✅ Reading tag has correct properties (purple, book icon)
- ✅ toJson and fromJson work correctly
- ✅ Equality works correctly

#### QuickPreset
- ✅ Default presets exist (5 built-in)
- ✅ Code preset has correct values (90/20)
- ✅ Reading preset has correct values (45/10)
- ✅ Deep Design preset has correct values (120/25)
- ✅ Quick Task preset has correct values (15/5)
- ✅ toJson and fromJson work correctly

#### SessionStats
- ✅ Default values are zero
- ✅ averageSessionMinutes calculates correctly
- ✅ averageSessionMinutes is zero when no sessions
- ✅ completionRate calculates correctly
- ✅ completionRate is zero when no sessions
- ✅ toJson and fromJson work correctly
- ✅ dailyMinutes tracking works
- ✅ sessionsByType tracking works

#### ProductivityGoal
- ✅ Default values are set
- ✅ Custom values work
- ✅ copyWith works correctly
- ✅ toJson and fromJson work correctly

#### ProductivityTimerService
- ✅ Singleton instance exists
- ✅ Initial state is idle
- ✅ Default session type is focus
- ✅ Default duration is 25 minutes
- ✅ formattedTime shows correct format
- ✅ Progress is 0 when idle
- ✅ setSessionType changes type
- ✅ setDuration changes duration when idle
- ✅ allContextTags includes default tags
- ✅ allQuickPresets includes default presets
- ✅ setContextTag changes current tag
- ✅ getTopTags returns empty list initially
- ✅ Settings can be changed
- ✅ Goal can be changed
- ✅ getDailyProgress returns value between 0 and 1

### Multi-Timer Service

#### SecondaryTimer
- ✅ Creates with required properties
- ✅ Creates with custom properties
- ✅ Initial state is idle
- ✅ Progress is 1 initially (full time remaining)
- ✅ formattedTime shows minutes and seconds
- ✅ formattedTime shows hours when needed
- ✅ Start changes state to running
- ✅ Pause changes state to paused
- ✅ Resume changes state back to running
- ✅ Stop resets the timer
- ✅ Reset sets time back to original duration
- ✅ toJson and fromJson work correctly

#### SecondaryTimerPreset
- ✅ Tea preset has correct values (5 min)
- ✅ Commit reminder has correct values (30 min, repeat)
- ✅ Eye rest follows 20-20-20 rule (20 min, repeat)
- ✅ Presets list contains all presets (8 total)
- ✅ toTimer creates valid SecondaryTimer
- ✅ toTimer with custom id uses provided id

#### MultiTimerService
- ✅ Singleton instance exists
- ✅ Initial state has no timers
- ✅ addTimer adds a timer
- ✅ addFromPreset adds timer from preset
- ✅ removeTimer removes a timer
- ✅ startTimer starts a timer
- ✅ pauseTimer pauses a timer
- ✅ resumeTimer resumes a paused timer
- ✅ stopTimer stops a timer
- ✅ stopAllTimers stops all timers
- ✅ clearAllTimers removes all timers

### Chained Routine Service

#### RoutineBlock
- ✅ Creates with required properties
- ✅ Creates with custom properties
- ✅ Duration getter returns correct Duration
- ✅ toJson and fromJson work correctly
- ✅ copyWith creates modified copy
- ✅ copyWith preserves unchanged properties

#### ChainedRoutine
- ✅ Creates with required properties
- ✅ Creates default routine
- ✅ totalDuration sums all blocks
- ✅ totalMinutes returns correct value
- ✅ toJson and fromJson work correctly
- ✅ copyWith creates modified copy

#### Default Routines
- ✅ Morning routine exists
- ✅ Evening routine exists
- ✅ Study session exists
- ✅ Creative session exists
- ✅ Work sprint exists
- ✅ defaultRoutines list contains all presets

#### RoutineState Enum
- ✅ Has all expected values (idle, running, paused, betweenBlocks, completed)

#### ChainedRoutineService
- ✅ Singleton instance exists
- ✅ Initial state is idle
- ✅ currentRoutine is null when idle
- ✅ blockProgress is 0 when idle
- ✅ overallProgress is 0 when idle
- ✅ startRoutine sets current routine
- ✅ pause changes state to paused
- ✅ resume changes state back to running
- ✅ stop resets state
- ✅ skipBlock advances to next block
- ✅ addTime increases remaining time
- ✅ totalBlocks returns correct count
- ✅ completedBlocks returns current index
- ✅ remainingBlocks returns correct count
- ✅ formattedTime returns correct format
- ✅ allRoutines includes default and custom
- ✅ soundEnabled defaults to true
- ✅ setSoundEnabled updates setting

---

## Manual Testing Guide

### Floating Clock Widget

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Display timer | Open floating clock | Shows 25:00 by default |
| Start timer | Tap play button | Timer starts counting down |
| Pause timer | Tap pause button while running | Timer pauses, shows pause icon |
| Resume timer | Tap play button while paused | Timer resumes from paused time |
| Reset timer | Tap reset button | Timer resets to initial duration |
| Change session type | Select different type | Duration changes accordingly |
| Expand/Collapse | Tap expand button | Widget expands to show more controls |

### Clock Page (Sidebar)

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Navigate to Clock | Click Clock in sidebar | Clock page opens with tabs |
| Timer tab | Select Timer tab | Shows main timer controls |
| Multi-Timer tab | Select Multi-Timer tab | Shows secondary timer list |
| Routines tab | Select Routines tab | Shows routine templates |
| Stats tab | Select Stats tab | Shows session statistics |
| Settings tab | Select Settings tab | Shows timer settings |

### Context Tags

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View available tags | Open tag selector | Shows 9 default tags |
| Apply tag to session | Select a tag before starting | Tag is associated with session |
| Filter stats by tag | Go to Stats, select tag filter | Shows only sessions with that tag |

### Quick Presets

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View presets | Open preset selector | Shows 5 default presets |
| Apply Code preset | Select "Code" preset | Timer: 90 min work, 20 min break |
| Apply Reading preset | Select "Reading" preset | Timer: 45 min work, 10 min break |

### Multi-Timer

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Add timer from preset | Tap + and select preset | New timer appears in list |
| Add custom timer | Tap + and configure | Custom timer created |
| Start secondary timer | Tap play on secondary timer | Timer starts independently |
| Multiple timers | Start 3+ timers | All run in parallel |
| Stop all | Tap "Stop All" | All timers stop |

### Chained Routines

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View built-in routines | Open Routines tab | Shows 5 default routines |
| Start Morning Routine | Select and start Morning Routine | Begins with first block |
| Auto-advance | Let first block complete | Automatically starts next block |
| Skip block | Tap skip button | Advances to next block |
| Pause routine | Tap pause | Routine pauses |
| Complete routine | Finish all blocks | Shows completion notification |

### Settings Synchronization

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Floating → Page | Change timer in floating clock | Clock page reflects changes |
| Page → Floating | Change timer in Clock page | Floating clock reflects changes |
| Persist settings | Change settings and restart app | Settings are preserved |

---

## Integration Testing

### Notifications

```dart
// Test notification delivery
testWidgets('timer completion triggers notification', (tester) async {
  // Setup
  final service = ProductivityTimerService.instance;
  await service.initialize();
  
  // Start a 1-second timer for testing
  service.setDuration(const Duration(seconds: 1));
  service.start();
  
  // Wait for completion
  await Future.delayed(const Duration(seconds: 2));
  
  // Verify notification was shown
  // (Requires notification testing framework)
});
```

### Data Persistence

```dart
// Test data persistence across restarts
test('session stats persist correctly', () async {
  final service = ProductivityTimerService.instance;
  await service.initialize();
  
  // Complete a session
  service.start();
  await service.completeCurrentSession();
  
  // Create new instance (simulating app restart)
  final newService = ProductivityTimerService.instance;
  await newService.initialize();
  
  // Verify stats were persisted
  expect(newService.stats.totalSessions, greaterThan(0));
});
```

---

## Performance Testing

### Timer Accuracy

```dart
test('timer maintains accuracy over extended periods', () async {
  final timer = SecondaryTimer(
    id: 'accuracy_test',
    name: 'Accuracy Test',
    duration: const Duration(minutes: 5),
  );
  
  final startTime = DateTime.now();
  timer.start();
  
  // Wait for completion
  await Future.delayed(const Duration(minutes: 5, seconds: 5));
  
  final elapsed = DateTime.now().difference(startTime);
  
  // Allow 1 second tolerance
  expect(elapsed.inSeconds, closeTo(300, 1));
});
```

### Memory Usage

- Monitor memory usage with multiple secondary timers running
- Verify no memory leaks when creating/disposing timers
- Test with 10+ parallel timers

### Battery Impact

- Run timer in background for 1 hour
- Measure battery consumption
- Optimize notification frequency if needed

---

## Accessibility Testing

### Screen Reader Support

| Element | Expected Announcement |
|---------|----------------------|
| Timer display | "25 minutes 0 seconds remaining" |
| Play button | "Start timer" |
| Pause button | "Pause timer" |
| Progress indicator | "Timer progress: 50 percent" |
| Context tag | "Coding tag selected" |

### Color Contrast

- All text meets WCAG 2.1 AA standards
- Session type colors have sufficient contrast
- Timer states are distinguishable without color alone

### Touch Targets

- All interactive elements are at least 48x48dp
- Sufficient spacing between touch targets
- Clear focus indicators

---

## Troubleshooting

### Common Test Failures

**MissingPluginException for SharedPreferences**
- This is expected in unit tests
- Tests still pass, just can't persist data
- For integration tests, use `SharedPreferences.setMockInitialValues({})`

**Timer-related flaky tests**
- Use `fakeAsync` for time-dependent tests
- Avoid real delays when possible

### Debug Tips

```dart
// Enable debug logging
ProductivityTimerService.instance.enableDebugLogging = true;

// Inspect current state
debugPrint('State: ${service.state}');
debugPrint('Remaining: ${service.remainingTime}');
debugPrint('Current tag: ${service.currentTag?.name}');
```

---

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Group related tests using `group()`
3. Use descriptive test names
4. Mock external dependencies
5. Test edge cases (null, empty, max values)
6. Run all tests before submitting PR

```bash
# Run all tests before submitting
flutter test
```
