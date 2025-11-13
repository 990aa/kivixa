import 'dart:convert';

import 'package:kivixa/data/models/project.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectStorage {
  static const _key = 'projects';

  static Future<List<Project>> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveProjects(List<Project> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        projects.map((project) => project.toJson()).toList(),
      );
      await prefs.setString(_key, jsonString);
    } catch (e) {
      // Handle error
    }
  }

  static Future<void> addProject(Project project) async {
    final projects = await loadProjects();
    projects.add(project);
    await saveProjects(projects);
  }

  static Future<void> updateProject(Project project) async {
    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      await saveProjects(projects);
    }
  }

  static Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }

  static Future<Project?> getProjectById(String projectId) async {
    final projects = await loadProjects();
    try {
      return projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Project>> getProjectsByStatus(ProjectStatus status) async {
    final projects = await loadProjects();
    return projects.where((p) => p.status == status).toList();
  }

  static Future<void> addChangeToProject(
    String projectId,
    ProjectChange change,
  ) async {
    final project = await getProjectById(projectId);
    if (project != null) {
      final updatedChanges = [...project.changes, change];
      await updateProject(project.copyWith(changes: updatedChanges));
    }
  }

  static Future<void> updateChangeInProject(
    String projectId,
    ProjectChange change,
  ) async {
    final project = await getProjectById(projectId);
    if (project != null) {
      final changes = [...project.changes];
      final index = changes.indexWhere((c) => c.id == change.id);
      if (index != -1) {
        changes[index] = change;
        await updateProject(project.copyWith(changes: changes));
      }
    }
  }

  static Future<void> addTaskToProject(String projectId, String taskId) async {
    final project = await getProjectById(projectId);
    if (project != null) {
      final taskIds = [...project.taskIds, taskId];
      await updateProject(project.copyWith(taskIds: taskIds));
    }
  }

  static Future<void> removeTaskFromProject(
    String projectId,
    String taskId,
  ) async {
    final project = await getProjectById(projectId);
    if (project != null) {
      final taskIds = [...project.taskIds]..remove(taskId);
      await updateProject(project.copyWith(taskIds: taskIds));
    }
  }
}
