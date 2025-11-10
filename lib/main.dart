import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/canvas/pencil_shader.dart';
import 'package:kivixa/components/theming/dynamic_material_app.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/data/tools/stroke_properties.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/home/home.dart';
import 'package:kivixa/pages/logs.dart';
import 'package:kivixa/pages/markdown/markdown_editor.dart';
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
  });

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
    'subpage': HomePage.recentSubpage,
  });
  static final _router = GoRouter(
    initialLocation: initialLocation,
    routes: <GoRoute>[
      GoRoute(path: '/', redirect: (context, state) => initialLocation),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => HomePage(
          subpage: state.pathParameters['subpage'] ?? HomePage.recentSubpage,
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
  @override
  Widget build(BuildContext context) {
    return DynamicMaterialApp(title: 'kivixa', router: App._router);
  }
}
