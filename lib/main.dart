import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/canvas/pencil_shader.dart';
import 'package:kivixa/components/dialogs/terms_and_conditions_dialog.dart';
import 'package:kivixa/components/theming/dynamic_material_app.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/data/tools/stroke_properties.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/home/home.dart';
import 'package:kivixa/pages/lock_screen.dart';
import 'package:kivixa/pages/logs.dart';
import 'package:kivixa/pages/markdown/markdown_editor.dart';
import 'package:kivixa/pages/textfile/text_file_editor.dart';
import 'package:kivixa/services/app_lock_service.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:kivixa/services/terms_and_conditions_service.dart';
import 'package:logging/logging.dart';
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:window_manager/window_manager.dart';
import 'package:worker_manager/worker_manager.dart';

Future<void> main(List<String> args) async {
  /// To set the flavor config e.g. for the Play Store, use:
  /// flutter build \
  ///   --dart-define=FLAVOR="Google Play" \
  ///   --dart-define=APP_STORE="Google Play" \
  ///   --dart-define=UPDATE_CHECK="false" \
  ///   --dart-define=DIRTY="false"
  FlavorConfig.setupFromEnvironment();
  await appRunner(args);
}

Future<void> appRunner(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final parser = ArgParser()..addFlag('verbose', abbr: 'v', negatable: false);
  final parsedArgs = parser.parse(args);

  Logger.root.level = (kDebugMode || parsedArgs.flag('verbose'))
      ? Level.INFO
      : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    logsHistory.add(record);
    // Also print to console in debug mode for better visibility
    if (kDebugMode) {
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('Stack trace:\n${record.stackTrace}');
      }
    }
  });

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    final log = Logger('FlutterError');
    log.severe(
      'Flutter error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
    // In debug mode, also use the default error handler which shows the red screen
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Catch async errors that aren't caught by FlutterError
  PlatformDispatcher.instance.onError = (error, stack) {
    final log = Logger('PlatformDispatcher');
    log.severe('Uncaught error', error, stack);
    if (kDebugMode) {
      print('=== UNCAUGHT ERROR ===');
      print('Error: $error');
      print('Stack trace:\n$stack');
      print('=====================');
    }
    return true; // Mark as handled
  };

  // For some reason, logging errors breaks hot reload while debugging.

  StrokeOptionsExtension.setDefaults();
  Stows.markAsOnMainIsolate();

  // i18n system removed - using hardcoded English strings
  // LocaleSettings.setLocaleSync(AppLocale.en);

  await Future.wait([
    stows.customDataDir.waitUntilRead().then((_) => FileManager.init()),
    if (Platform.isWindows) windowManager.ensureInitialized(),
    workerManager.init(),
    PencilShader.init(),
    // PencilSound.preload(), // Audio functionality removed
    Printing.info().then((info) {
      Editor.canRasterPdf = info.canRaster;
    }),
    NotificationService.instance.initialize(),
  ]);

  stows.customDataDir.addListener(FileManager.migrateDataDir);
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);

  LicenseRegistry.addLicense(() async* {
    for (final licenseFile in const [
      'assets/google_fonts/Atkinson_Hyperlegible_Next/OFL.txt',
      'assets/google_fonts/Dekko/OFL.txt',
      'assets/google_fonts/Fira_Mono/OFL.txt',
      'assets/google_fonts/Neucha/OFL.txt',
    ]) {
      final license = await rootBundle.loadString(licenseFile);
      yield LicenseEntryWithLineBreaks(const ['google_fonts'], license);
    }
  });

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  static final log = Logger('App');

  static String initialLocation = pathToFunction(RoutePaths.home)({
    'subpage': HomePage.browseSubpage,
  });
  static final _router = GoRouter(
    initialLocation: initialLocation,
    routes: <GoRoute>[
      GoRoute(path: '/', redirect: (context, state) => initialLocation),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => HomePage(
          subpage: state.pathParameters['subpage'] ?? HomePage.browseSubpage,
          path: state.uri.queryParameters['path'],
        ),
      ),
      GoRoute(
        path: RoutePaths.edit,
        builder: (context, state) => Editor(
          path: state.uri.queryParameters['path'],
          pdfPath: state.uri.queryParameters['pdfPath'],
        ),
      ),
      GoRoute(
        path: RoutePaths.markdown,
        builder: (context, state) =>
            MarkdownEditor(filePath: state.uri.queryParameters['path']),
      ),
      GoRoute(
        path: RoutePaths.logs,
        builder: (context, state) => const LogsPage(),
      ),
      GoRoute(
        path: RoutePaths.textFile,
        builder: (context, state) =>
            TextFileEditor(filePath: state.uri.queryParameters['path']),
      ),
    ],
  );

  static void openFile(String path) async {
    log.info('Opening file: $path');

    final String extension;
    if (path.contains('.')) {
      extension = path.split('.').last.toLowerCase();
    } else {
      extension = 'kvx';
    }

    if (extension == 'kvx' || extension == 'kvx' || extension == 'kvx') {
      final newPath = await FileManager.importFile(
        path,
        null,
        extension: '.$extension',
      );
      if (newPath == null) return;

      // allow file to finish writing
      await Future.delayed(const Duration(milliseconds: 100));

      _router.push(RoutePaths.editFilePath(newPath));
    } else if (extension == 'pdf' && Editor.canRasterPdf) {
      final fileNameWithoutExtension = path
          .split(RegExp(r'[\\/]'))
          .last
          .substring(0, path.length - '.pdf'.length);
      final kvxFilePath = await FileManager.suffixFilePathToMakeItUnique(
        '/$fileNameWithoutExtension',
      );
      _router.push(RoutePaths.editImportPdf(kvxFilePath, path));
    } else {
      log.warning('openFile: Unsupported file type: $extension');
    }
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  var _termsChecked = false;
  var _termsAccepted = false;
  var _isLocked = false;
  final _appLockService = AppLockService();

  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
    _checkLockStatus();
  }

  Future<void> _checkTermsAcceptance() async {
    final hasAccepted = await TermsAndConditionsService.hasAcceptedTerms();
    if (mounted) {
      setState(() {
        _termsChecked = true;
        _termsAccepted = hasAccepted;
      });
    }
  }

  void _checkLockStatus() {
    // Check if app lock is enabled
    setState(() {
      _isLocked = _appLockService.isEnabled;
    });
  }

  void _onUnlocked() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checking terms
    if (!_termsChecked) {
      return const MaterialApp(
        title: 'kivixa',
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // If terms not accepted, show the terms dialog wrapper
    if (!_termsAccepted) {
      return _TermsWrapper(
        onAccepted: () {
          setState(() => _termsAccepted = true);
        },
      );
    }

    // If app is locked, show lock screen
    if (_isLocked) {
      return MaterialApp(
        title: 'kivixa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: LockScreen(onUnlocked: _onUnlocked),
      );
    }

    // Terms accepted and unlocked, show the main app
    return DynamicMaterialApp(title: 'kivixa', router: App._router);
  }
}

class _TermsWrapper extends StatelessWidget {
  const _TermsWrapper({required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kivixa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: _TermsAcceptancePage(onAccepted: onAccepted),
    );
  }
}

class _TermsAcceptancePage extends StatefulWidget {
  const _TermsAcceptancePage({required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<_TermsAcceptancePage> createState() => _TermsAcceptancePageState();
}

class _TermsAcceptancePageState extends State<_TermsAcceptancePage> {
  @override
  void initState() {
    super.initState();
    // Show terms dialog after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTermsDialog();
    });
  }

  Future<void> _showTermsDialog() async {
    final accepted = await TermsAndConditionsDialog.showIfNeeded(context);
    if (accepted) {
      widget.onAccepted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Kivixa',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please accept our Terms and Conditions to continue',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showTermsDialog,
              icon: const Icon(Icons.gavel),
              label: const Text('View Terms'),
            ),
          ],
        ),
      ),
    );
  }
}
