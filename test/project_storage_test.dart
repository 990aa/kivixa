import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/project.dart';
import 'package:kivixa/data/project_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProjectStorage', () {
    test('loadProjects returns empty list initially', () async {
      final projects = await ProjectStorage.loadProjects();
      expect(projects, isEmpty);
    });

    test('addProject saves and returns project with ID', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test Project',
        description: 'Test Description',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
      );

      expect(project.id, isNotEmpty);
      expect(project.title, 'Test Project');
      expect(project.description, 'Test Description');
      expect(project.status, ProjectStatus.upcoming);
      expect(project.color, Colors.blue);
      expect(project.changes, isEmpty);
      expect(project.taskIds, isEmpty);
      expect(project.completedAt, isNull);
    });

    test('loadProjects returns saved projects', () async {
      await ProjectStorage.addProject(
        title: 'Project 1',
        description: 'Description 1',
        status: ProjectStatus.upcoming,
        color: Colors.red,
      );
      await ProjectStorage.addProject(
        title: 'Project 2',
        description: 'Description 2',
        status: ProjectStatus.ongoing,
        color: Colors.green,
      );

      final projects = await ProjectStorage.loadProjects();

      expect(projects.length, 2);
      expect(projects[0].title, 'Project 1');
      expect(projects[1].title, 'Project 2');
    });

    test('updateProject modifies existing project', () async {
      final original = await ProjectStorage.addProject(
        title: 'Original Title',
        description: 'Original Description',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
      );

      final updated = Project(
        id: original.id,
        title: 'Updated Title',
        description: 'Updated Description',
        status: ProjectStatus.ongoing,
        changes: original.changes,
        taskIds: original.taskIds,
        createdAt: original.createdAt,
        completedAt: DateTime(2024, 1, 1),
        color: Colors.red,
      );

      await ProjectStorage.updateProject(updated);

      final projects = await ProjectStorage.loadProjects();
      final found = projects.firstWhere((p) => p.id == original.id);

      expect(found.title, 'Updated Title');
      expect(found.description, 'Updated Description');
      expect(found.status, ProjectStatus.ongoing);
      expect(found.color, Colors.red);
      expect(found.completedAt, DateTime(2024, 1, 1));
    });

    test('deleteProject removes project', () async {
      final project1 = await ProjectStorage.addProject(
        title: 'Project 1',
        description: '',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
      );
      final project2 = await ProjectStorage.addProject(
        title: 'Project 2',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.green,
      );

      await ProjectStorage.deleteProject(project1.id);

      final projects = await ProjectStorage.loadProjects();

      expect(projects.length, 1);
      expect(projects[0].id, project2.id);
    });

    test('getProjectById returns correct project', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test Project',
        description: 'Test',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
      );

      final found = await ProjectStorage.getProjectById(project.id);

      expect(found, isNotNull);
      expect(found!.id, project.id);
      expect(found.title, 'Test Project');
    });

    test('getProjectById returns null for non-existent ID', () async {
      final found = await ProjectStorage.getProjectById('non-existent-id');
      expect(found, isNull);
    });

    test('getProjectsByStatus returns projects with matching status', () async {
      await ProjectStorage.addProject(
        title: 'Upcoming 1',
        description: '',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
      );
      await ProjectStorage.addProject(
        title: 'Ongoing 1',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.green,
      );
      await ProjectStorage.addProject(
        title: 'Upcoming 2',
        description: '',
        status: ProjectStatus.upcoming,
        color: Colors.red,
      );

      final upcoming = await ProjectStorage.getProjectsByStatus(
        ProjectStatus.upcoming,
      );
      final ongoing = await ProjectStorage.getProjectsByStatus(
        ProjectStatus.ongoing,
      );

      expect(upcoming.length, 2);
      expect(upcoming.every((p) => p.status == ProjectStatus.upcoming), true);
      expect(ongoing.length, 1);
      expect(ongoing[0].status, ProjectStatus.ongoing);
    });

    test('addChangeToProject adds change to project', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
      );

      await ProjectStorage.addChangeToProject(project.id, 'First change');
      await ProjectStorage.addChangeToProject(project.id, 'Second change');

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.changes.length, 2);
      expect(updated.changes[0].description, 'First change');
      expect(updated.changes[1].description, 'Second change');
      expect(updated.changes.every((c) => !c.isCompleted), true);
    });

    test('updateChangeInProject modifies existing change', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
      );

      await ProjectStorage.addChangeToProject(project.id, 'Test change');

      final loaded = await ProjectStorage.getProjectById(project.id);
      final changeId = loaded!.changes[0].id;

      final updatedChange = ProjectChange(
        id: changeId,
        description: 'Updated description',
        timestamp: loaded.changes[0].timestamp,
        isCompleted: true,
      );

      await ProjectStorage.updateChangeInProject(project.id, updatedChange);

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.changes[0].description, 'Updated description');
      expect(updated.changes[0].isCompleted, true);
    });

    test('addTaskToProject adds task ID', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
      );

      await ProjectStorage.addTaskToProject(project.id, 'task-1');
      await ProjectStorage.addTaskToProject(project.id, 'task-2');

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.taskIds, ['task-1', 'task-2']);
    });

    test('removeTaskFromProject removes task ID', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
      );

      await ProjectStorage.addTaskToProject(project.id, 'task-1');
      await ProjectStorage.addTaskToProject(project.id, 'task-2');
      await ProjectStorage.addTaskToProject(project.id, 'task-3');

      await ProjectStorage.removeTaskFromProject(project.id, 'task-2');

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.taskIds, ['task-1', 'task-3']);
    });

    test('addChangeToProject returns null for non-existent project', () async {
      final result = await ProjectStorage.addChangeToProject(
        'non-existent',
        'Test',
      );
      expect(result, isNull);
    });

    test(
      'updateChangeInProject returns null for non-existent project',
      () async {
        final change = ProjectChange(
          id: '1',
          description: 'Test',
          timestamp: DateTime.now(),
          isCompleted: false,
        );
        final result = await ProjectStorage.updateChangeInProject(
          'non-existent',
          change,
        );
        expect(result, isNull);
      },
    );

    test('maintains data persistence across operations', () async {
      // Add project
      final project = await ProjectStorage.addProject(
        title: 'Persistent Project',
        description: 'Testing persistence',
        status: ProjectStatus.ongoing,
        color: Colors.purple,
      );

      // Add changes
      await ProjectStorage.addChangeToProject(project.id, 'Change 1');
      await ProjectStorage.addChangeToProject(project.id, 'Change 2');

      // Add tasks
      await ProjectStorage.addTaskToProject(project.id, 'task-1');

      // Load and verify
      final loaded = await ProjectStorage.getProjectById(project.id);

      expect(loaded, isNotNull);
      expect(loaded!.title, 'Persistent Project');
      expect(loaded.changes.length, 2);
      expect(loaded.taskIds, ['task-1']);
    });

    test('handles empty project lists correctly', () async {
      final all = await ProjectStorage.loadProjects();
      final upcoming = await ProjectStorage.getProjectsByStatus(
        ProjectStatus.upcoming,
      );

      expect(all, isEmpty);
      expect(upcoming, isEmpty);
    });

    test('change timestamps are automatically set', () async {
      final project = await ProjectStorage.addProject(
        title: 'Test',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
      );

      final before = DateTime.now();
      await ProjectStorage.addChangeToProject(project.id, 'Test change');
      final after = DateTime.now();

      final updated = await ProjectStorage.getProjectById(project.id);
      final changeTimestamp = updated!.changes[0].timestamp;

      expect(
        changeTimestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        changeTimestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });
}
