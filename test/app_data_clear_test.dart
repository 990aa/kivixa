import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/app_data_clear_service.dart';

void main() {
  group('AppDataClearService', () {
    group('DataType enum', () {
      test('has all expected data types', () {
        expect(DataType.values.length, 4);
        expect(DataType.values.contains(DataType.notes), true);
        expect(DataType.values.contains(DataType.calendarEvents), true);
        expect(DataType.values.contains(DataType.projects), true);
        expect(DataType.values.contains(DataType.preferences), true);
      });

      test('displayName returns proper names', () {
        expect(DataType.notes.displayName, 'Notes & Documents');
        expect(DataType.calendarEvents.displayName, 'Calendar Events');
        expect(DataType.projects.displayName, 'Projects');
        expect(DataType.preferences.displayName, 'App Preferences');
      });

      test('description returns informative text', () {
        expect(DataType.notes.description.isNotEmpty, true);
        expect(DataType.calendarEvents.description.isNotEmpty, true);
        expect(DataType.projects.description.isNotEmpty, true);
        expect(DataType.preferences.description.isNotEmpty, true);
      });

      test('icon returns valid icons', () {
        for (final dataType in DataType.values) {
          expect(dataType.icon, isNotNull);
        }
      });

      test('descriptions contain expected keywords', () {
        expect(DataType.notes.description.toLowerCase().contains('note'), true);
        expect(
          DataType.calendarEvents.description.toLowerCase().contains(
            'calendar',
          ),
          true,
        );
        expect(
          DataType.projects.description.toLowerCase().contains('project'),
          true,
        );
        expect(
          DataType.preferences.description.toLowerCase().contains('setting'),
          true,
        );
      });
    });

    group('ClearResult', () {
      test('successful result has no error', () {
        const result = ClearResult(
          success: true,
          message: 'Successfully cleared',
        );

        expect(result.success, true);
        expect(result.error, null);
        expect(result.message, 'Successfully cleared');
      });

      test('failed result has error', () {
        const result = ClearResult(
          success: false,
          message: 'Failed to clear',
          error: 'Permission denied',
        );

        expect(result.success, false);
        expect(result.error, 'Permission denied');
        expect(result.message, 'Failed to clear');
      });
    });

    group('Service methods existence', () {
      // These tests verify the service API exists
      // Actual clearing requires mocking file system and SharedPreferences

      test('clearNotes method exists', () {
        expect(AppDataClearService.clearNotes, isA<Function>());
      });

      test('clearCalendarEvents method exists', () {
        expect(AppDataClearService.clearCalendarEvents, isA<Function>());
      });

      test('clearProjects method exists', () {
        expect(AppDataClearService.clearProjects, isA<Function>());
      });

      test('clearPreferences method exists', () {
        expect(AppDataClearService.clearPreferences, isA<Function>());
      });

      test('clearAllData method exists', () {
        expect(AppDataClearService.clearAllData, isA<Function>());
      });

      test('clearSelectedData method exists', () {
        expect(AppDataClearService.clearSelectedData, isA<Function>());
      });
    });

    group('DataType iteration', () {
      test('can iterate through all data types', () {
        final types = <DataType>[];
        for (final type in DataType.values) {
          types.add(type);
        }
        expect(types.length, DataType.values.length);
      });

      test('each data type has unique display name', () {
        final displayNames = DataType.values.map((t) => t.displayName).toSet();
        expect(displayNames.length, DataType.values.length);
      });
    });
  });
}
