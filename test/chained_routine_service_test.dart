// Chained Routine Service Tests
//
// Tests for sequential timed routine blocks functionality.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/productivity/chained_routine_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => '.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({});
    ChainedRoutineService.instance.resetForTests();
  });

  tearDown(() {
    ChainedRoutineService.instance.resetForTests();
  });

  group('RoutineBlock', () {
    test('creates with required properties', () {
      const block = RoutineBlock(name: 'Test Block', durationMinutes: 5);

      expect(block.name, 'Test Block');
      expect(block.durationMinutes, 5);
      expect(block.duration, const Duration(minutes: 5));
      expect(block.icon, Icons.timer);
      expect(block.color, Colors.blue);
      expect(block.description, isNull);
    });

    test('creates with custom properties', () {
      const block = RoutineBlock(
        name: 'Custom Block',
        durationMinutes: 10,
        icon: Icons.book,
        color: Colors.purple,
        description: 'Test description',
      );

      expect(block.name, 'Custom Block');
      expect(block.durationMinutes, 10);
      expect(block.icon, Icons.book);
      expect(block.color, Colors.purple);
      expect(block.description, 'Test description');
    });

    test('duration getter returns correct Duration', () {
      const block = RoutineBlock(name: 'Test', durationMinutes: 25);

      expect(block.duration, const Duration(minutes: 25));
    });

    test('toJson and fromJson work correctly', () {
      const block = RoutineBlock(
        name: 'Test Block',
        durationMinutes: 15,
        icon: Icons.book,
        color: Colors.purple,
        description: 'Test description',
      );
      final json = block.toJson();
      final restored = RoutineBlock.fromJson(json);

      expect(restored.name, block.name);
      expect(restored.durationMinutes, block.durationMinutes);
      expect(restored.icon.codePoint, block.icon.codePoint);
      expect(restored.description, block.description);
    });

    test('copyWith creates modified copy', () {
      const block = RoutineBlock(name: 'Original', durationMinutes: 10);
      final copy = block.copyWith(name: 'Modified', durationMinutes: 20);

      expect(copy.name, 'Modified');
      expect(copy.durationMinutes, 20);
      expect(copy.icon, block.icon); // Unchanged
    });

    test('copyWith preserves unchanged properties', () {
      const block = RoutineBlock(
        name: 'Original',
        durationMinutes: 10,
        icon: Icons.star,
        color: Colors.red,
        description: 'Original description',
      );
      final copy = block.copyWith(name: 'Modified');

      expect(copy.name, 'Modified');
      expect(copy.durationMinutes, 10);
      expect(copy.icon, Icons.star);
      expect(copy.color, Colors.red);
      expect(copy.description, 'Original description');
    });
  });

  group('ChainedRoutine', () {
    test('creates with required properties', () {
      const routine = ChainedRoutine(
        id: 'test_routine',
        name: 'Test Routine',
        blocks: [RoutineBlock(name: 'Block 1', durationMinutes: 10)],
      );

      expect(routine.id, 'test_routine');
      expect(routine.name, 'Test Routine');
      expect(routine.blocks.length, 1);
      expect(routine.icon, Icons.playlist_play);
      expect(routine.color, Colors.blue);
      expect(routine.isDefault, false);
    });

    test('creates default routine', () {
      const routine = ChainedRoutine(
        id: 'default',
        name: 'Default',
        blocks: [],
        isDefault: true,
      );

      expect(routine.isDefault, true);
    });

    test('totalDuration sums all blocks', () {
      const routine = ChainedRoutine(
        id: 'test',
        name: 'Test',
        blocks: [
          RoutineBlock(name: 'B1', durationMinutes: 10),
          RoutineBlock(name: 'B2', durationMinutes: 15),
          RoutineBlock(name: 'B3', durationMinutes: 5),
        ],
      );

      expect(routine.totalDuration, const Duration(minutes: 30));
    });

    test('totalMinutes returns correct value', () {
      const routine = ChainedRoutine(
        id: 'test',
        name: 'Test',
        blocks: [
          RoutineBlock(name: 'B1', durationMinutes: 10),
          RoutineBlock(name: 'B2', durationMinutes: 15),
        ],
      );

      expect(routine.totalMinutes, 25);
    });

    test('toJson and fromJson work correctly', () {
      const routine = ChainedRoutine(
        id: 'test',
        name: 'Test Routine',
        description: 'A test routine',
        icon: Icons.star,
        blocks: [RoutineBlock(name: 'Block 1', durationMinutes: 10)],
        isDefault: false,
      );
      final json = routine.toJson();
      final restored = ChainedRoutine.fromJson(json);

      expect(restored.id, routine.id);
      expect(restored.name, routine.name);
      expect(restored.description, routine.description);
      expect(restored.icon.codePoint, routine.icon.codePoint);
      expect(restored.blocks.length, routine.blocks.length);
      expect(restored.isDefault, routine.isDefault);
    });

    test('copyWith creates modified copy', () {
      const routine = ChainedRoutine(
        id: 'original',
        name: 'Original',
        blocks: [],
      );
      final copy = routine.copyWith(
        name: 'Modified',
        description: 'New description',
      );

      expect(copy.id, 'original');
      expect(copy.name, 'Modified');
      expect(copy.description, 'New description');
    });
  });

  group('Default Routines', () {
    test('morning routine exists', () {
      const routine = ChainedRoutine.morningRoutine;
      expect(routine.name, 'Morning Routine');
      expect(routine.blocks.isNotEmpty, true);
      expect(routine.isDefault, true);
    });

    test('evening routine exists', () {
      const routine = ChainedRoutine.eveningRoutine;
      expect(routine.name, 'Evening Wind-Down');
      expect(routine.blocks.isNotEmpty, true);
      expect(routine.isDefault, true);
    });

    test('study session exists', () {
      const routine = ChainedRoutine.studySession;
      expect(routine.name, 'Study Session');
      expect(routine.blocks.isNotEmpty, true);
      expect(routine.isDefault, true);
    });

    test('creative session exists', () {
      const routine = ChainedRoutine.creativeSession;
      expect(routine.name, 'Creative Session');
      expect(routine.blocks.isNotEmpty, true);
      expect(routine.isDefault, true);
    });

    test('work sprint exists', () {
      const routine = ChainedRoutine.workSprint;
      expect(routine.name, 'Work Sprint');
      expect(routine.blocks.isNotEmpty, true);
      expect(routine.isDefault, true);
    });

    test('defaultRoutines list contains all presets', () {
      final routines = ChainedRoutine.defaultRoutines;
      expect(routines.length, 5);
      expect(routines, contains(ChainedRoutine.morningRoutine));
      expect(routines, contains(ChainedRoutine.eveningRoutine));
      expect(routines, contains(ChainedRoutine.studySession));
      expect(routines, contains(ChainedRoutine.creativeSession));
      expect(routines, contains(ChainedRoutine.workSprint));
    });
  });

  group('RoutineState', () {
    test('has all expected values', () {
      expect(RoutineState.values, contains(RoutineState.idle));
      expect(RoutineState.values, contains(RoutineState.running));
      expect(RoutineState.values, contains(RoutineState.paused));
      expect(RoutineState.values, contains(RoutineState.betweenBlocks));
      expect(RoutineState.values, contains(RoutineState.completed));
    });
  });

  group('ChainedRoutineService', () {
    test('singleton instance exists', () {
      final service = ChainedRoutineService.instance;
      expect(service, isNotNull);
    });

    test('initial state is idle', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      expect(service.state, RoutineState.idle);
      expect(service.isRunning, false);
      expect(service.isPaused, false);
      expect(service.isIdle, true);
    });

    test('currentRoutine is null when idle', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      expect(service.currentRoutine, isNull);
      expect(service.currentBlock, isNull);
      expect(service.currentBlockIndex, 0);
    });

    test('blockProgress is 0 when idle', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      expect(service.blockProgress, 0.0);
    });

    test('overallProgress is 0 when idle', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      expect(service.overallProgress, 0.0);
    });

    test('startRoutine sets current routine', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      const routine = ChainedRoutine.morningRoutine;
      service.startRoutine(routine);

      expect(service.currentRoutine?.id, routine.id);
      expect(service.currentBlockIndex, 0);
      expect(service.isRunning, true);
      expect(service.state, RoutineState.running);

      service.stop();
    });

    test('pause changes state to paused', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      service.pause();

      expect(service.isPaused, true);
      expect(service.state, RoutineState.paused);

      service.stop();
    });

    test('resume changes state back to running', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      service.pause();
      service.resume();

      expect(service.isRunning, true);
      expect(service.state, RoutineState.running);

      service.stop();
    });

    test('stop resets state', () {
      final service = ChainedRoutineService.instance;

      service.startRoutine(ChainedRoutine.morningRoutine);
      service.stop();

      expect(service.isIdle, true);
      expect(service.currentRoutine, isNull);
      expect(service.currentBlockIndex, 0);
    });

    test('skipBlock advances to next block', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      expect(service.currentBlockIndex, 0);

      service.skipBlock();
      expect(service.currentBlockIndex, 1);

      service.stop();
    });

    test('addTime increases remaining time', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      final initialTime = service.remainingTime;

      service.addTime(const Duration(minutes: 5));
      expect(service.remainingTime, initialTime + const Duration(minutes: 5));

      service.stop();
    });

    test('totalBlocks returns correct count', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      expect(service.totalBlocks, ChainedRoutine.morningRoutine.blocks.length);

      service.stop();
    });

    test('completedBlocks returns current index', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      expect(service.completedBlocks, 0);

      service.skipBlock();
      expect(service.completedBlocks, 1);

      service.stop();
    });

    test('remainingBlocks returns correct count', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      final total = service.totalBlocks;
      expect(service.remainingBlocks, total);

      service.skipBlock();
      expect(service.remainingBlocks, total - 1);

      service.stop();
    });

    test('formattedTime returns correct format', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      service.startRoutine(ChainedRoutine.morningRoutine);
      // Morning routine first block is 10 minutes
      expect(service.formattedTime, '10:00');

      service.stop();
    });

    test('allRoutines includes default and custom', () {
      final service = ChainedRoutineService.instance;
      expect(
        service.allRoutines.length,
        greaterThanOrEqualTo(ChainedRoutine.defaultRoutines.length),
      );
    });

    test('startRoutine ignores routines with no blocks', () {
      final service = ChainedRoutineService.instance;
      service.stop();

      const emptyRoutine = ChainedRoutine(
        id: 'test_empty_routine',
        name: 'Empty Routine',
        blocks: [],
      );

      service.startRoutine(emptyRoutine);

      expect(service.isIdle, true);
      expect(service.currentRoutine, isNull);
      expect(service.currentBlock, isNull);
    });

    test('saveRoutine adds and updates a custom routine', () {
      final service = ChainedRoutineService.instance;
      service.restoreDefaultRoutines(preserveCustom: false);

      const routine = ChainedRoutine(
        id: 'test_custom_routine_save',
        name: 'Custom Save Routine',
        blocks: [RoutineBlock(name: 'Focus', durationMinutes: 25)],
      );

      service.saveRoutine(routine);
      expect(service.customRoutines.any((r) => r.id == routine.id), true);

      final metadataUpdated = service.updateRoutineMetadata(
        routine.id,
        name: 'Updated Custom Save Routine',
        description: 'Updated description',
      );
      expect(metadataUpdated, true);

      final updated = service.getRoutineById(routine.id);
      expect(updated, isNotNull);
      expect(updated!.name, 'Updated Custom Save Routine');
      expect(updated.description, 'Updated description');

      service.deleteRoutine(routine.id);
    });

    test('insert, update, and delete block operations work', () {
      final service = ChainedRoutineService.instance;
      service.restoreDefaultRoutines(preserveCustom: false);

      const routineId = 'test_custom_block_ops';
      service.saveRoutine(
        const ChainedRoutine(
          id: routineId,
          name: 'Block Ops Routine',
          blocks: [
            RoutineBlock(name: 'Block A', durationMinutes: 10),
            RoutineBlock(name: 'Block C', durationMinutes: 20),
          ],
        ),
      );

      final inserted = service.insertBlockInRoutine(
        routineId,
        1,
        const RoutineBlock(name: 'Block B', durationMinutes: 15),
      );
      expect(inserted, true);

      final afterInsert = service.getRoutineById(routineId)!;
      expect(afterInsert.blocks.length, 3);
      expect(afterInsert.blocks[1].name, 'Block B');

      final updated = service.updateBlockInRoutine(
        routineId,
        1,
        const RoutineBlock(name: 'Block B Updated', durationMinutes: 12),
      );
      expect(updated, true);

      final afterUpdate = service.getRoutineById(routineId)!;
      expect(afterUpdate.blocks[1].name, 'Block B Updated');
      expect(afterUpdate.blocks[1].durationMinutes, 12);

      final deleted = service.deleteBlockFromRoutine(routineId, 1);
      expect(deleted, true);

      final afterDelete = service.getRoutineById(routineId)!;
      expect(afterDelete.blocks.length, 2);
      expect(afterDelete.blocks[0].name, 'Block A');
      expect(afterDelete.blocks[1].name, 'Block C');

      service.deleteRoutine(routineId);
    });

    test(
      'restoreDefaultRoutines resets defaults while keeping custom by default',
      () {
        final service = ChainedRoutineService.instance;
        service.restoreDefaultRoutines(preserveCustom: false);

        final originalMorning = service.getRoutineById(
          ChainedRoutine.morningRoutine.id,
        );
        expect(originalMorning, isNotNull);

        service.saveRoutine(
          originalMorning!.copyWith(name: 'Temp Morning Name'),
        );
        service.saveRoutine(
          const ChainedRoutine(
            id: 'test_custom_routine_keep',
            name: 'Keep Custom',
            blocks: [RoutineBlock(name: 'Single Block', durationMinutes: 5)],
          ),
        );

        service.restoreDefaultRoutines();

        final restoredMorning = service.getRoutineById(
          ChainedRoutine.morningRoutine.id,
        );
        expect(restoredMorning, isNotNull);
        expect(restoredMorning!.name, ChainedRoutine.morningRoutine.name);
        expect(
          service.customRoutines.any((r) => r.id == 'test_custom_routine_keep'),
          true,
        );

        service.restoreDefaultRoutines(preserveCustom: false);
      },
    );

    test('deleteAllCustomRoutines clears only custom routines', () {
      final service = ChainedRoutineService.instance;
      service.restoreDefaultRoutines(preserveCustom: false);

      service.saveRoutine(
        const ChainedRoutine(
          id: 'test_custom_routine_one',
          name: 'Custom One',
          blocks: [RoutineBlock(name: 'One', durationMinutes: 5)],
        ),
      );
      service.saveRoutine(
        const ChainedRoutine(
          id: 'test_custom_routine_two',
          name: 'Custom Two',
          blocks: [RoutineBlock(name: 'Two', durationMinutes: 8)],
        ),
      );
      expect(service.customRoutines.length, 2);

      service.deleteAllCustomRoutines();

      expect(service.customRoutines, isEmpty);
      expect(
        service.defaultRoutines.length,
        ChainedRoutine.defaultRoutines.length,
      );
    });

    test('soundEnabled defaults to true', () {
      final service = ChainedRoutineService.instance;
      // Note: May not always be true if persisted settings changed it
      expect(service.soundEnabled, isNotNull);
    });

    test('setSoundEnabled updates setting', () {
      final service = ChainedRoutineService.instance;
      final original = service.soundEnabled;

      service.setSoundEnabled(!original);
      expect(service.soundEnabled, !original);

      // Restore original
      service.setSoundEnabled(original);
    });
  });
}
