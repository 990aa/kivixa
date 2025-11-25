import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/app_data_clear_service.dart';

void main() {
  group('AppDataClearService', () {
    group('AppDataType enum', () {
      test('has all expected data types', () {
        expect(AppDataType.values.length, 7);
        expect(AppDataType.values.contains(AppDataType.notes), true);
        expect(AppDataType.values.contains(AppDataType.markdown), true);
        expect(AppDataType.values.contains(AppDataType.projects), true);
        expect(AppDataType.values.contains(AppDataType.calendar), true);
        expect(AppDataType.values.contains(AppDataType.preferences), true);
        expect(AppDataType.values.contains(AppDataType.recentFiles), true);
        expect(AppDataType.values.contains(AppDataType.all), true);
      });

      test('displayName returns proper names', () {
        expect(AppDataType.notes.displayName, 'Notes & Documents');
        expect(AppDataType.markdown.displayName, 'Markdown Files');
        expect(AppDataType.projects.displayName, 'Projects');
        expect(AppDataType.calendar.displayName, 'Calendar Events');
        expect(AppDataType.preferences.displayName, 'Preferences');
        expect(AppDataType.recentFiles.displayName, 'Recent Files');
        expect(AppDataType.all.displayName, 'All Data');
      });

      test('description returns informative text', () {
        for (final dataType in AppDataType.values) {
          expect(dataType.description.isNotEmpty, true);
        }
      });

      test('descriptions contain expected keywords', () {
        expect(
          AppDataType.notes.description.toLowerCase().contains('note'),
          true,
        );
        expect(
          AppDataType.markdown.description.toLowerCase().contains('markdown'),
          true,
        );
        expect(
          AppDataType.projects.description.toLowerCase().contains('project'),
          true,
        );
        expect(
          AppDataType.calendar.description.toLowerCase().contains('calendar'),
          true,
        );
      });
    });

    group('Service methods existence', () {
      test('clearData method exists', () {
        expect(AppDataClearService.clearData, isA<Function>());
      });

      test('getDataSizes method exists', () {
        expect(AppDataClearService.getDataSizes, isA<Function>());
      });

      test('formatBytes method exists', () {
        expect(AppDataClearService.formatBytes, isA<Function>());
      });
    });

    group('formatBytes', () {
      test('formats bytes correctly', () {
        expect(AppDataClearService.formatBytes(0), '0 B');
        expect(AppDataClearService.formatBytes(500), '500 B');
        expect(AppDataClearService.formatBytes(1023), '1023 B');
      });

      test('formats kilobytes correctly', () {
        expect(AppDataClearService.formatBytes(1024), '1.0 KB');
        expect(AppDataClearService.formatBytes(2048), '2.0 KB');
        expect(AppDataClearService.formatBytes(1536), '1.5 KB');
      });

      test('formats megabytes correctly', () {
        expect(AppDataClearService.formatBytes(1024 * 1024), '1.0 MB');
        expect(AppDataClearService.formatBytes(5 * 1024 * 1024), '5.0 MB');
      });

      test('formats gigabytes correctly', () {
        expect(AppDataClearService.formatBytes(1024 * 1024 * 1024), '1.0 GB');
        expect(
          AppDataClearService.formatBytes(2 * 1024 * 1024 * 1024),
          '2.0 GB',
        );
      });
    });

    group('AppDataType iteration', () {
      test('can iterate through all data types', () {
        final types = <AppDataType>[];
        for (final type in AppDataType.values) {
          types.add(type);
        }
        expect(types.length, AppDataType.values.length);
      });

      test('each data type has unique display name', () {
        final displayNames = AppDataType.values
            .map((t) => t.displayName)
            .toSet();
        expect(displayNames.length, AppDataType.values.length);
      });
    });
  });
}
