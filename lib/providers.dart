import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_service.dart';
import 'data/database.dart';
import 'data/repository.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final themeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeModeSetting>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).asData!.value;
  return ThemeModeNotifier(prefs);
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DocumentRepository(db);
});

final documentsProvider = StreamProvider<List<DocumentData>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.watchDocuments();
});
