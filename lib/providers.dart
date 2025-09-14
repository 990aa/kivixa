import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_service.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'package:kivixa/features/library/documents_notifier.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Added import

final documentsNotifierProvider =
    StateNotifierProvider<DocumentsNotifier, AsyncValue<List<DocumentData>>>((
      ref,
    ) {
      final repository = ref.watch(documentRepositoryProvider);
      return DocumentsNotifier(repository);
    });

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
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

// Added connectivityProvider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  // Updated to handle List<ConnectivityResult> from onConnectivityChanged
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet) || results.contains(ConnectivityResult.vpn)) {
      // Return the first found active connection, prioritizing more stable ones if needed
      // For now, just picking the first one that's not 'none'.
      // Order of check can be adjusted based on preference (e.g., ethernet, wifi, mobile, vpn)
      if (results.contains(ConnectivityResult.ethernet)) return ConnectivityResult.ethernet;
      if (results.contains(ConnectivityResult.wifi)) return ConnectivityResult.wifi;
      if (results.contains(ConnectivityResult.mobile)) return ConnectivityResult.mobile;
      if (results.contains(ConnectivityResult.vpn)) return ConnectivityResult.vpn; 
    }
    return ConnectivityResult.none; // Default to none if no active connection or only 'none' is present
  });
});
