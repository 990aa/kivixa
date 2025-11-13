import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/project.dart';

void main() {
  group('ProjectChange', () {
    test('creates a ProjectChange with all properties', () {
      final change = ProjectChange(
        id: '1',
        description: 'Initial setup',
        timestamp: DateTime(2024, 1, 1),
        isCompleted: false,
      );

      expect(change.id, '1');
      expect(change.description, 'Initial setup');
      expect(change.timestamp, DateTime(2024, 1, 1));
      expect(change.isCompleted, false);
    });

    test('serializes to JSON correctly', () {
      final change = ProjectChange(
        id: '1',
        description: 'Test change',
        timestamp: DateTime(2024, 1, 1),
        isCompleted: true,
      );

      final json = change.toJson();

      expect(json['id'], '1');
      expect(json['description'], 'Test change');
      expect(json['timestamp'], DateTime(2024, 1, 1).toIso8601String());
      expect(json['isCompleted'], true);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': '1',
        'description': 'Test change',
        'timestamp': DateTime(2024, 1, 1).toIso8601String(),
        'isCompleted': true,
      };

      final change = ProjectChange.fromJson(json);

      expect(change.id, '1');
      expect(change.description, 'Test change');
      expect(change.timestamp, DateTime(2024, 1, 1));
      expect(change.isCompleted, true);
    });

    test('handles roundtrip JSON serialization', () {
      final original = ProjectChange(
        id: '123',
        description: 'Roundtrip test',
        timestamp: DateTime(2024, 6, 15, 10, 30),
        isCompleted: false,
      );

      final json = original.toJson();
      final deserialized = ProjectChange.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.description, original.description);
      expect(deserialized.timestamp, original.timestamp);
      expect(deserialized.isCompleted, original.isCompleted);
    });
  });

  group('Project', () {
    test('creates a Project with all properties', () {
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: 'A test project',
        status: ProjectStatus.ongoing,
        changes: [],
        taskIds: ['t1', 't2'],
        createdAt: DateTime(2024, 1, 1),
        completedAt: null,
        color: Colors.blue,
      );

      expect(project.id, 'p1');
      expect(project.title, 'Test Project');
      expect(project.description, 'A test project');
      expect(project.status, ProjectStatus.ongoing);
      expect(project.changes, isEmpty);
      expect(project.taskIds, ['t1', 't2']);
      expect(project.createdAt, DateTime(2024, 1, 1));
      expect(project.completedAt, isNull);
      expect(project.color, Colors.blue);
    });

    test('allChanges returns all changes unsorted', () {
      final project = Project(
        id: 'p1',
        title: 'Test',
        description: '',
        status: ProjectStatus.ongoing,
        changes: [
          ProjectChange(
            id: '1',
            description: 'First',
            timestamp: DateTime(2024, 1, 3),
            isCompleted: false,
          ),
          ProjectChange(
            id: '2',
            description: 'Second',
            timestamp: DateTime(2024, 1, 1),
            isCompleted: false,
          ),
          ProjectChange(
            id: '3',
            description: 'Third',
            timestamp: DateTime(2024, 1, 2),
            isCompleted: true,
          ),
        ],
        taskIds: [],
        createdAt: DateTime(2024, 1, 1),
        completedAt: null,
        color: Colors.blue,
      );

      final allChanges = project.allChanges;

      expect(allChanges.length, 3);
      // allChanges returns in original order
      expect(allChanges[0].timestamp, DateTime(2024, 1, 3));
      expect(allChanges[1].timestamp, DateTime(2024, 1, 1));
      expect(allChanges[2].timestamp, DateTime(2024, 1, 2));
    });

    test('completedChanges returns only completed changes', () {
      final project = Project(
        id: 'p1',
        title: 'Test',
        description: '',
        status: ProjectStatus.ongoing,
        changes: [
          ProjectChange(
            id: '1',
            description: 'Completed 1',
            timestamp: DateTime(2024, 1, 1),
            isCompleted: true,
          ),
          ProjectChange(
            id: '2',
            description: 'Not completed',
            timestamp: DateTime(2024, 1, 2),
            isCompleted: false,
          ),
          ProjectChange(
            id: '3',
            description: 'Completed 2',
            timestamp: DateTime(2024, 1, 3),
            isCompleted: true,
          ),
        ],
        taskIds: [],
        createdAt: DateTime(2024, 1, 1),
        completedAt: null,
        color: Colors.blue,
      );

      final completed = project.completedChanges;

      expect(completed.length, 2);
      expect(completed.every((c) => c.isCompleted), true);
    });

    test('pendingChanges returns only incomplete changes', () {
      final project = Project(
        id: 'p1',
        title: 'Test',
        description: '',
        status: ProjectStatus.ongoing,
        changes: [
          ProjectChange(
            id: '1',
            description: 'Completed',
            timestamp: DateTime(2024, 1, 1),
            isCompleted: true,
          ),
          ProjectChange(
            id: '2',
            description: 'Pending 1',
            timestamp: DateTime(2024, 1, 2),
            isCompleted: false,
          ),
          ProjectChange(
            id: '3',
            description: 'Pending 2',
            timestamp: DateTime(2024, 1, 3),
            isCompleted: false,
          ),
        ],
        taskIds: [],
        createdAt: DateTime(2024, 1, 1),
        completedAt: null,
        color: Colors.blue,
      );

      final pending = project.pendingChanges;

      expect(pending.length, 2);
      expect(pending.every((c) => !c.isCompleted), true);
    });

    test('timeline returns sorted list in descending order', () {
      final project = Project(
        id: 'p1',
        title: 'Test',
        description: '',
        status: ProjectStatus.ongoing,
        changes: [
          ProjectChange(
            id: '3',
            description: 'Latest',
            timestamp: DateTime(2024, 1, 5),
            isCompleted: false,
          ),
          ProjectChange(
            id: '1',
            description: 'Earliest',
            timestamp: DateTime(2024, 1, 1),
            isCompleted: true,
          ),
          ProjectChange(
            id: '2',
            description: 'Middle',
            timestamp: DateTime(2024, 1, 3),
            isCompleted: false,
          ),
        ],
        taskIds: [],
        createdAt: DateTime(2024, 1, 1),
        completedAt: null,
        color: Colors.blue,
      );

      final timeline = project.timeline;

      expect(timeline.length, 3);
      // Timeline is descending (newest first)
      expect(timeline[0].description, 'Latest');
      expect(timeline[1].description, 'Middle');
      expect(timeline[2].description, 'Earliest');
    });

    test('serializes to JSON correctly', () {
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: 'Description',
        status: ProjectStatus.upcoming,
        changes: [
          ProjectChange(
            id: '1',
            description: 'Change 1',
            timestamp: DateTime(2024, 1, 1),
            isCompleted: false,
          ),
        ],
        taskIds: ['t1', 't2'],
        createdAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 2, 1),
        color: Colors.red,
      );

      final json = project.toJson();

      expect(json['id'], 'p1');
      expect(json['title'], 'Test Project');
      expect(json['description'], 'Description');
      expect(json['status'], 'upcoming');
      expect(json['changes'], isA<List>());
      expect(json['taskIds'], ['t1', 't2']);
      expect(json['createdAt'], DateTime(2024, 1, 1).toIso8601String());
      expect(json['completedAt'], DateTime(2024, 2, 1).toIso8601String());
      expect(json['color'], Colors.red.toARGB32());
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'p1',
        'title': 'Test Project',
        'description': 'Description',
        'status': 'completed',
        'changes': [
          {
            'id': '1',
            'description': 'Change 1',
            'timestamp': DateTime(2024, 1, 1).toIso8601String(),
            'isCompleted': true,
          },
        ],
        'taskIds': ['t1'],
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'completedAt': DateTime(2024, 2, 1).toIso8601String(),
        'color': Colors.green.toARGB32(),
      };

      final project = Project.fromJson(json);

      expect(project.id, 'p1');
      expect(project.title, 'Test Project');
      expect(project.description, 'Description');
      expect(project.status, ProjectStatus.completed);
      expect(project.changes.length, 1);
      expect(project.taskIds, ['t1']);
      expect(project.createdAt, DateTime(2024, 1, 1));
      expect(project.completedAt, DateTime(2024, 2, 1));
      expect(project.color?.value, Colors.green.value);
    });

    test('handles roundtrip JSON serialization', () {
      final original = Project(
        id: 'p123',
        title: 'Roundtrip Project',
        description: 'Testing roundtrip',
        status: ProjectStatus.ongoing,
        changes: [
          ProjectChange(
            id: 'c1',
            description: 'Change A',
            timestamp: DateTime(2024, 1, 1),
            isCompleted: true,
          ),
          ProjectChange(
            id: 'c2',
            description: 'Change B',
            timestamp: DateTime(2024, 1, 2),
            isCompleted: false,
          ),
        ],
        taskIds: ['task1', 'task2', 'task3'],
        createdAt: DateTime(2024, 1, 1, 10, 30),
        completedAt: null,
        color: Colors.purple,
      );

      final json = original.toJson();
      final deserialized = Project.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.title, original.title);
      expect(deserialized.description, original.description);
      expect(deserialized.status, original.status);
      expect(deserialized.changes.length, original.changes.length);
      expect(deserialized.taskIds, original.taskIds);
      expect(deserialized.createdAt, original.createdAt);
      expect(deserialized.completedAt, original.completedAt);
      expect(deserialized.color?.value, original.color?.value);
    });

    test('handles null completedAt in JSON', () {
      final json = {
        'id': 'p1',
        'title': 'Test',
        'description': '',
        'status': 'ongoing',
        'changes': [],
        'taskIds': [],
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'completedAt': null,
        'color': Colors.blue.toARGB32(),
      };

      final project = Project.fromJson(json);

      expect(project.completedAt, isNull);
    });
  });

  group('ProjectStatus', () {
    test('converts to string correctly', () {
      expect(ProjectStatus.upcoming.toString(), 'ProjectStatus.upcoming');
      expect(ProjectStatus.ongoing.toString(), 'ProjectStatus.ongoing');
      expect(ProjectStatus.completed.toString(), 'ProjectStatus.completed');
    });

    test('all status values are unique', () {
      const statuses = ProjectStatus.values;
      expect(statuses.length, 3);
      expect(statuses.toSet().length, 3);
    });
  });
}
