import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/productivity/chained_routine_service.dart';

void main() {
  group('RoutineBlock & ChainedRoutine Model Tests', () {
    test('RoutineBlock initialization and duration calculation', () {
      final block = const RoutineBlock(
        name: 'Focus',
        durationMinutes: 25,
        durationSeconds: 30,
        color: Colors.blue,
      );

      expect(block.durationMinutes, 25);
      expect(block.durationSeconds, 30);
      expect(block.duration.inSeconds, (25 * 60) + 30);
    });

    test('RoutineBlock JSON serialization and deserialization', () {
      final block = const RoutineBlock(
        name: 'Break',
        durationMinutes: 5,
        durationSeconds: 15,
        color: Colors.green,
      );

      final json = block.toJson();
      expect(json['name'], 'Break');
      expect(json['durationMinutes'], 5);
      expect(json['durationSeconds'], 15);

      final decodedBlock = RoutineBlock.fromJson(json);
      expect(decodedBlock.name, 'Break');
      expect(decodedBlock.durationMinutes, 5);
      expect(decodedBlock.durationSeconds, 15);
      expect(decodedBlock.color.toARGB32(), Colors.green.toARGB32());
      expect(decodedBlock.duration.inSeconds, 315);
    });

    test('ChainedRoutine total duration calculation', () {
      final routine = const ChainedRoutine(
        id: 'r1',
        name: 'Morning Routine',
        blocks: [
          const RoutineBlock(
            name: 'Block 1',
            durationMinutes: 10,
            durationSeconds: 30,
            color: Colors.red,
          ),
          const RoutineBlock(
            name: 'Block 2',
            durationMinutes: 5,
            durationSeconds: 15,
            color: Colors.blue,
          ),
        ],
      );

      final total = routine.totalDuration;
      // Block 1: 630 seconds
      // Block 2: 315 seconds
      // Total: 945 seconds
      expect(total.inSeconds, 945);
    });
  });
}
