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

    test('addProject saves project', () async {
      final project = Project(
        id: 'test-1',
        title: 'Test Project',
        description: 'Test Description',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(project);

      final projects = await ProjectStorage.loadProjects();
      expect(projects.length, 1);
      expect(projects[0].id, 'test-1');
      expect(projects[0].title, 'Test Project');
      expect(projects[0].description, 'Test Description');
      expect(projects[0].status, ProjectStatus.upcoming);
    });

    test('loadProjects returns saved projects', () async {
      final project1 = Project(
        id: 'p1',
        title: 'Project 1',
        description: 'Description 1',
        status: ProjectStatus.upcoming,
        color: Colors.red,
        createdAt: DateTime(2024, 1, 1),
      );
      final project2 = Project(
        id: 'p2',
        title: 'Project 2',
        description: 'Description 2',
        status: ProjectStatus.ongoing,
        color: Colors.green,
        createdAt: DateTime(2024, 1, 2),
      );

      await ProjectStorage.addProject(project1);
      await ProjectStorage.addProject(project2);

      final projects = await ProjectStorage.loadProjects();

      expect(projects.length, 2);
      expect(projects[0].title, 'Project 1');
      expect(projects[1].title, 'Project 2');
    });

    test('updateProject modifies existing project', () async {
      final original = Project(
        id: 'p1',
        title: 'Original Title',
        description: 'Original Description',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(original);

      final updated = original.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
        status: ProjectStatus.ongoing,
        completedAt: DateTime(2024, 2, 1),
        color: Colors.red,
      );

      await ProjectStorage.updateProject(updated);

      final projects = await ProjectStorage.loadProjects();
      final found = projects.firstWhere((p) => p.id == original.id);

      expect(found.title, 'Updated Title');
      expect(found.description, 'Updated Description');
      expect(found.status, ProjectStatus.ongoing);
      expect(found.completedAt, DateTime(2024, 2, 1));
    });

    test('deleteProject removes project', () async {
      final project1 = Project(
        id: 'p1',
        title: 'Project 1',
        description: '',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );
      final project2 = Project(
        id: 'p2',
        title: 'Project 2',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.green,
        createdAt: DateTime(2024, 1, 2),
      );

      await ProjectStorage.addProject(project1);
      await ProjectStorage.addProject(project2);

      await ProjectStorage.deleteProject(project1.id);

      final projects = await ProjectStorage.loadProjects();

      expect(projects.length, 1);
      expect(projects[0].id, project2.id);
    });

    test('getProjectById returns correct project', () async {
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: 'Test',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(project);

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
      final project1 = Project(
        id: 'p1',
        title: 'Upcoming 1',
        description: '',
        status: ProjectStatus.upcoming,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );
      final project2 = Project(
        id: 'p2',
        title: 'Ongoing 1',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.green,
        createdAt: DateTime(2024, 1, 2),
      );
      final project3 = Project(
        id: 'p3',
        title: 'Upcoming 2',
        description: '',
        status: ProjectStatus.upcoming,
        color: Colors.red,
        createdAt: DateTime(2024, 1, 3),
      );

      await ProjectStorage.addProject(project1);
      await ProjectStorage.addProject(project2);
      await ProjectStorage.addProject(project3);

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
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(project);

      final change1 = ProjectChange(
        id: 'c1',
        description: 'First change',
        timestamp: DateTime(2024, 1, 2),
        isCompleted: false,
      );
      final change2 = ProjectChange(
        id: 'c2',
        description: 'Second change',
        timestamp: DateTime(2024, 1, 3),
        isCompleted: false,
      );

      await ProjectStorage.addChangeToProject(project.id, change1);
      await ProjectStorage.addChangeToProject(project.id, change2);

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.changes.length, 2);
      expect(updated.changes[0].description, 'First change');
      expect(updated.changes[1].description, 'Second change');
      expect(updated.changes.every((c) => !c.isCompleted), true);
    });

    test('updateChangeInProject modifies existing change', () async {
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(project);

      final change = ProjectChange(
        id: 'c1',
        description: 'Test change',
        timestamp: DateTime(2024, 1, 2),
        isCompleted: false,
      );

      await ProjectStorage.addChangeToProject(project.id, change);

      final updatedChange = change.copyWith(
        description: 'Updated description',
        isCompleted: true,
      );

      await ProjectStorage.updateChangeInProject(project.id, updatedChange);

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.changes[0].description, 'Updated description');
      expect(updated.changes[0].isCompleted, true);
    });

    test('addTaskToProject adds task ID', () async {
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(project);

      await ProjectStorage.addTaskToProject(project.id, 'task-1');
      await ProjectStorage.addTaskToProject(project.id, 'task-2');

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.taskIds, ['task-1', 'task-2']);
    });

    test('removeTaskFromProject removes task ID', () async {
      final project = Project(
        id: 'p1',
        title: 'Test Project',
        description: '',
        status: ProjectStatus.ongoing,
        color: Colors.blue,
        createdAt: DateTime(2024, 1, 1),
        taskIds: ['task-1', 'task-2', 'task-3'],
      );

      await ProjectStorage.addProject(project);

      await ProjectStorage.removeTaskFromProject(project.id, 'task-2');

      final updated = await ProjectStorage.getProjectById(project.id);

      expect(updated!.taskIds, ['task-1', 'task-3']);
    });

    test('maintains data persistence across operations', () async {
      final project = Project(
        id: 'p1',
        title: 'Persistent Project',
        description: 'Testing persistence',
        status: ProjectStatus.ongoing,
        color: Colors.purple,
        createdAt: DateTime(2024, 1, 1),
      );

      await ProjectStorage.addProject(project);

      final change1 = ProjectChange(
        id: 'c1',
        description: 'Change 1',
        timestamp: DateTime(2024, 1, 2),
        isCompleted: false,
      );
      final change2 = ProjectChange(
        id: 'c2',
        description: 'Change 2',
        timestamp: DateTime(2024, 1, 3),
        isCompleted: false,
      );

      await ProjectStorage.addChangeToProject(project.id, change1);
      await ProjectStorage.addChangeToProject(project.id, change2);
      await ProjectStorage.addTaskToProject(project.id, 'task-1');

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
  });
}
