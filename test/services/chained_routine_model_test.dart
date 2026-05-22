import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/productivity/chained_routine_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('RoutineBlock & ChainedRoutine Model Tests', () {
    test('RoutineBlock initialization and duration calculation', () {
      final block = RoutineBlock(
        id: 'b1',
        title: 'Focus',
        durationMinutes: 25,
        durationSeconds: 30,
        color: Colors.blue,
      );

      expect(block.durationMinutes, 25);
      expect(block.durationSeconds, 30);
      expect(block.totalDuration.inSeconds, (25 * 60) + 30);
    });

    test('RoutineBlock JSON serialization and deserialization', () {
      final block = RoutineBlock(
        id: 'b1',
        title: 'Break',
        durationMinutes: 5,
        durationSeconds: 15,
        color: Colors.green,
      );

      final json = block.toJson();
      expect(json['id'], 'b1');
      expect(json['title'], 'Break');
      expect(json['durationMinutes'], 5);
      expect(json['durationSeconds'], 15);
      expect(json['colorValue'], Colors.green.value);

      final decodedBlock = RoutineBlock.fromJson(json);
      expect(decodedBlock.id, 'b1');
      expect(decodedBlock.title, 'Break');
      expect(decodedBlock.durationMinutes, 5);
      expect(decodedBlock.durationSeconds, 15);
      expect(decodedBlock.color, Colors.green);
      expect(decodedBlock.totalDuration.inSeconds, 315);
    });

    test('ChainedRoutine total duration calculation', () {
      final routine = ChainedRoutine(
        id: 'r1',
        title: 'Morning Routine',
        blocks: [
          RoutineBlock(
            id: 'b1',
            title: 'Block 1',
            durationMinutes: 10,
            durationSeconds: 30,
            color: Colors.red,
          ),
          RoutineBlock(
            id: 'b2',
            title: 'Block 2',
            durationMinutes: 5,
            durationSeconds: 15,
            color: Colors.blue,
          ),
        ],
        createdAt: DateTime.now(),
      );

      final total = routine.totalDuration;
      // Block 1: 630 seconds
      // Block 2: 315 seconds
      // Total: 945 seconds
      expect(total.inSeconds, 945);
    });
  });
}
