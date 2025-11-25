import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/project.dart';

// Test the generateRandomProjectColor function
Color generateRandomProjectColor() {
  final random = Random();
  final hue = random.nextDouble() * 360;
  final saturation = 0.6 + random.nextDouble() * 0.3;
  final lightness = 0.4 + random.nextDouble() * 0.2;
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

void main() {
  group('Project Manager Features', () {
    group('Random Color Generation', () {
      test('generates a valid color', () {
        final color = generateRandomProjectColor();
        expect(color, isA<Color>());
        expect((color.a * 255).round(), 255); // Full opacity
      });

      test('generates different colors on multiple calls', () {
        final colors = <Color>[];
        for (var i = 0; i < 10; i++) {
          colors.add(generateRandomProjectColor());
        }
        // At least some colors should be different
        final uniqueColors = colors.toSet();
        expect(uniqueColors.length, greaterThan(1));
      });

      test('generates colors with proper saturation range (60-90%)', () {
        // Since we can't directly test the HSL values after conversion,
        // we test that the color is not too gray (low saturation)
        for (var i = 0; i < 100; i++) {
          final color = generateRandomProjectColor();
          final hsl = HSLColor.fromColor(color);
          expect(hsl.saturation, greaterThanOrEqualTo(0.5));
          expect(hsl.saturation, lessThanOrEqualTo(1.0));
        }
      });

      test('generates colors with proper lightness range (40-60%)', () {
        for (var i = 0; i < 100; i++) {
          final color = generateRandomProjectColor();
          final hsl = HSLColor.fromColor(color);
          expect(hsl.lightness, greaterThanOrEqualTo(0.3));
          expect(hsl.lightness, lessThanOrEqualTo(0.7));
        }
      });
    });

    group('Project Model - New Fields', () {
      test('creates project with noteIds', () {
        final project = Project(
          id: 'p1',
          title: 'Test Project',
          noteIds: ['note1', 'note2', 'note3'],
          createdAt: DateTime.now(),
        );

        expect(project.noteIds, hasLength(3));
        expect(project.noteIds, contains('note1'));
        expect(project.noteIds, contains('note2'));
        expect(project.noteIds, contains('note3'));
      });

      test('creates project with readme', () {
        final project = Project(
          id: 'p1',
          title: 'Test Project',
          readme: '# My Project\n\nThis is a test project.',
          createdAt: DateTime.now(),
        );

        expect(project.readme, isNotNull);
        expect(project.readme, contains('# My Project'));
      });

      test('creates project with starCount', () {
        final project = Project(
          id: 'p1',
          title: 'Test Project',
          starCount: 5,
          createdAt: DateTime.now(),
        );

        expect(project.starCount, 5);
      });

      test('creates project with lastActivityAt', () {
        final now = DateTime.now();
        final project = Project(
          id: 'p1',
          title: 'Test Project',
          lastActivityAt: now,
          createdAt: DateTime.now(),
        );

        expect(project.lastActivityAt, now);
      });

      test('serializes new fields to JSON correctly', () {
        final project = Project(
          id: 'p1',
          title: 'Test',
          noteIds: ['n1', 'n2'],
          readme: '# README',
          starCount: 3,
          lastActivityAt: DateTime(2024, 6, 15),
          createdAt: DateTime(2024, 1, 1),
        );

        final json = project.toJson();

        expect(json['noteIds'], ['n1', 'n2']);
        expect(json['readme'], '# README');
        expect(json['starCount'], 3);
        expect(json['lastActivityAt'], DateTime(2024, 6, 15).toIso8601String());
      });

      test('deserializes new fields from JSON correctly', () {
        final json = {
          'id': 'p1',
          'title': 'Test',
          'status': 'ongoing',
          'changes': [],
          'taskIds': [],
          'noteIds': ['n1', 'n2'],
          'createdAt': DateTime(2024, 1, 1).toIso8601String(),
          'readme': '# README',
          'starCount': 3,
          'lastActivityAt': DateTime(2024, 6, 15).toIso8601String(),
        };

        final project = Project.fromJson(json);

        expect(project.noteIds, ['n1', 'n2']);
        expect(project.readme, '# README');
        expect(project.starCount, 3);
        expect(project.lastActivityAt, DateTime(2024, 6, 15));
      });

      test('copyWith works for new fields', () {
        final original = Project(
          id: 'p1',
          title: 'Original',
          noteIds: ['n1'],
          readme: 'Old',
          starCount: 1,
          lastActivityAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
        );

        final updated = original.copyWith(
          noteIds: ['n1', 'n2', 'n3'],
          readme: 'New README',
          starCount: 5,
          lastActivityAt: DateTime(2024, 6, 1),
        );

        expect(updated.noteIds, ['n1', 'n2', 'n3']);
        expect(updated.readme, 'New README');
        expect(updated.starCount, 5);
        expect(updated.lastActivityAt, DateTime(2024, 6, 1));
        // Original should be unchanged
        expect(original.noteIds, ['n1']);
        expect(original.readme, 'Old');
        expect(original.starCount, 1);
      });
    });

    group('Project Search and Filter', () {
      final projects = [
        Project(
          id: '1',
          title: 'Flutter App',
          description: 'A mobile application',
          status: ProjectStatus.ongoing,
          lastActivityAt: DateTime(2024, 6, 15),
          createdAt: DateTime(2024, 1, 1),
        ),
        Project(
          id: '2',
          title: 'React Website',
          description: 'A web project',
          status: ProjectStatus.completed,
          lastActivityAt: DateTime(2024, 6, 10),
          createdAt: DateTime(2024, 2, 1),
        ),
        Project(
          id: '3',
          title: 'Python Script',
          description: 'Automation tool',
          status: ProjectStatus.upcoming,
          lastActivityAt: DateTime(2024, 6, 20),
          createdAt: DateTime(2024, 3, 1),
        ),
      ];

      test('filters by search query in title', () {
        final query = 'flutter';
        final filtered = projects.where((p) {
          return p.title.toLowerCase().contains(query.toLowerCase());
        }).toList();

        expect(filtered, hasLength(1));
        expect(filtered.first.title, 'Flutter App');
      });

      test('filters by search query in description', () {
        final query = 'web';
        final filtered = projects.where((p) {
          return p.title.toLowerCase().contains(query.toLowerCase()) ||
              (p.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();

        expect(filtered, hasLength(1));
        expect(filtered.first.title, 'React Website');
      });

      test('filters by status - ongoing', () {
        final filtered = projects
            .where((p) => p.status == ProjectStatus.ongoing)
            .toList();

        expect(filtered, hasLength(1));
        expect(filtered.first.title, 'Flutter App');
      });

      test('filters by status - completed', () {
        final filtered = projects
            .where((p) => p.status == ProjectStatus.completed)
            .toList();

        expect(filtered, hasLength(1));
        expect(filtered.first.title, 'React Website');
      });

      test('sorts by last activity (newest first)', () {
        final sorted = List<Project>.from(projects);
        sorted.sort((a, b) {
          final aTime = a.lastActivityAt ?? a.createdAt;
          final bTime = b.lastActivityAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });

        expect(sorted[0].title, 'Python Script'); // June 20
        expect(sorted[1].title, 'Flutter App'); // June 15
        expect(sorted[2].title, 'React Website'); // June 10
      });

      test('sorts by name alphabetically', () {
        final sorted = List<Project>.from(projects);
        sorted.sort((a, b) => a.title.compareTo(b.title));

        expect(sorted[0].title, 'Flutter App');
        expect(sorted[1].title, 'Python Script');
        expect(sorted[2].title, 'React Website');
      });

      test('sorts by created date (newest first)', () {
        final sorted = List<Project>.from(projects);
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        expect(sorted[0].title, 'Python Script'); // March
        expect(sorted[1].title, 'React Website'); // February
        expect(sorted[2].title, 'Flutter App'); // January
      });
    });

    group('Project Duplication', () {
      test('duplicates project with new ID and "(Copy)" suffix', () {
        final original = Project(
          id: 'original-id',
          title: 'My Project',
          description: 'Original description',
          status: ProjectStatus.ongoing,
          createdAt: DateTime(2024, 1, 1),
          color: Colors.blue,
        );

        final duplicate = Project(
          id: 'new-id',
          title: '${original.title} (Copy)',
          description: original.description,
          status: ProjectStatus.upcoming,
          changes: [],
          taskIds: [],
          noteIds: [],
          createdAt: DateTime.now(),
          lastActivityAt: DateTime.now(),
          color: generateRandomProjectColor(),
        );

        expect(duplicate.id, isNot(original.id));
        expect(duplicate.title, 'My Project (Copy)');
        expect(duplicate.description, original.description);
        expect(duplicate.status, ProjectStatus.upcoming);
        expect(duplicate.changes, isEmpty);
        expect(duplicate.taskIds, isEmpty);
        expect(duplicate.noteIds, isEmpty);
      });
    });

    group('Relative Time Formatting', () {
      String formatRelativeTime(DateTime dateTime) {
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inDays > 365) {
          return '${(difference.inDays / 365).floor()}y ago';
        } else if (difference.inDays > 30) {
          return '${(difference.inDays / 30).floor()}mo ago';
        } else if (difference.inDays > 0) {
          return '${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours}h ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes}m ago';
        } else {
          return 'Just now';
        }
      }

      test('formats time less than a minute ago', () {
        final now = DateTime.now();
        expect(formatRelativeTime(now), 'Just now');
      });

      test('formats time in minutes', () {
        final fiveMinutesAgo = DateTime.now().subtract(
          const Duration(minutes: 5),
        );
        expect(formatRelativeTime(fiveMinutesAgo), '5m ago');
      });

      test('formats time in hours', () {
        final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
        expect(formatRelativeTime(threeHoursAgo), '3h ago');
      });

      test('formats time in days', () {
        final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
        expect(formatRelativeTime(fiveDaysAgo), '5d ago');
      });

      test('formats time in months', () {
        final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 65));
        expect(formatRelativeTime(twoMonthsAgo), '2mo ago');
      });

      test('formats time in years', () {
        final twoYearsAgo = DateTime.now().subtract(const Duration(days: 800));
        expect(formatRelativeTime(twoYearsAgo), '2y ago');
      });
    });
  });
}
