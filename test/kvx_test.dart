import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:kivixa/components/canvas/canvas.dart';
import 'package:kivixa/components/canvas/image/editor_image.dart';
import 'package:kivixa/components/canvas/pencil_shader.dart';
import 'package:kivixa/components/theming/font_fallbacks.dart';
import 'package:kivixa/data/editor/editor_core_info.dart';
import 'package:kivixa/data/editor/editor_exporter.dart';
import 'package:kivixa/data/editor/page.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/tools/laser_pointer.dart';
import 'package:kivixa/data/tools/stroke_properties.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('Test kvx parsing:', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    BackgroundIsolateBinaryMessenger.ensureInitialized(
      ServicesBinding.rootIsolateToken!,
    );

    setupMockPathProvider();
    setupMockPrinting();

    FlavorConfig.setup();
    SharedPreferences.setMockInitialValues({});

    setUpAll(() => Future.wait([FileManager.init(), PencilShader.init()]));

    const laserkvx = 'v17_laser_pointer.kvx';
    final kvxExamplesDir = Directory('test/kvx_examples/');

    // Skip tests if kvx_examples directory doesn't exist
    if (!kvxExamplesDir.existsSync()) {
      test('kvx_examples directory not found - skipping tests', () {
        // Skip tests if examples directory is missing
      });
      return;
    }

    final kvxExamples =
        kvxExamplesDir
            .listSync()
            .whereType<File>()
            .where(
              (file) =>
                  file.path.endsWith('.kvx') || file.path.endsWith('.kvx'),
            )
            .map((file) => file.path.substring('test/kvx_examples/'.length))
            .toList()
          ..add(laserkvx);

    for (final kvxName in kvxExamples) {
      group(kvxName, () {
        final path = kvxName == laserkvx
            ? 'test/kvx_examples/v17_squiggles.kvx'
            : 'test/kvx_examples/$kvxName';
        final pathWithoutExtension = path.substring(0, path.lastIndexOf('.'));

        late final EditorCoreInfo coreInfo;
        late final page = coreInfo.pages.first;

        setUpAll(() async {
          StrokeOptionsExtension.setDefaults();
          FileManager.shouldUseRawFilePath = true;
          EditorImage.shouldLoadOutImmediately = true;
          if (kvxName.endsWith('.kvx')) {
            coreInfo = await EditorCoreInfo.loadFromFileContents(
              bsonBytes: File(path).readAsBytesSync(),
              path: pathWithoutExtension,
              readOnly: false,
              onlyFirstPage: true,
            );
          } else {
            coreInfo = await EditorCoreInfo.loadFromFileContents(
              jsonString: File(path).readAsStringSync(),
              path: pathWithoutExtension,
              readOnly: false,
              onlyFirstPage: true,
            );
          }
          if (kvxName == laserkvx) {
            final page = coreInfo.pages.first;
            page.laserStrokes.addAll(
              page.strokes.map(LaserStroke.convertStroke),
            );
            page.strokes.clear();
          }
          if (coreInfo.pages.length > 1 && coreInfo.pages.last.isEmpty) {
            coreInfo.pages.removeLast();
          }
        });
        tearDownAll(() {
          FileManager.shouldUseRawFilePath = false;
          EditorImage.shouldLoadOutImmediately = false;
        });

        testGoldens('(Light)', (tester) async {
          await tester.runAsync(
            () => _precacheImages(
              context: tester.binding.rootElement!,
              page: page,
            ),
          );
          await tester.loadFonts(overriddenFonts: kivixaSansSerifFontFallbacks);
          await tester.pumpWidget(
            _buildCanvas(
              brightness: Brightness.light,
              path: path,
              page: page,
              coreInfo: coreInfo,
            ),
          );
          await tester.pumpAndSettle();

          tester.useFuzzyComparator(allowedDiffPercent: 0.1);
          await expectLater(
            find.byType(Canvas),
            matchesGoldenFile('kvx_examples/$kvxName.light.png'),
          );
        });

        testGoldens('(Dark)', (tester) async {
          await tester.runAsync(
            () => _precacheImages(
              context: tester.binding.rootElement!,
              page: page,
            ),
          );
          await tester.loadFonts(overriddenFonts: kivixaSansSerifFontFallbacks);
          await tester.pumpWidget(
            _buildCanvas(
              brightness: Brightness.dark,
              path: path,
              page: page,
              coreInfo: coreInfo,
            ),
          );
          await tester.pumpAndSettle();

          tester.useFuzzyComparator(allowedDiffPercent: 0.1);
          await expectLater(
            find.byType(Canvas),
            matchesGoldenFile('kvx_examples/$kvxName.dark.png'),
          );
        });

        testGoldens('(LOD)', (tester) async {
          await tester.runAsync(
            () => _precacheImages(
              context: tester.binding.rootElement!,
              page: page,
            ),
          );
          await tester.loadFonts(overriddenFonts: kivixaSansSerifFontFallbacks);
          await tester.pumpWidget(
            _buildCanvas(
              brightness: Brightness.light,
              path: path,
              page: page,
              coreInfo: coreInfo,
              currentScale: double.minPositive, // Very zoomed out
            ),
          );
          await tester.pumpAndSettle();

          tester.useFuzzyComparator(allowedDiffPercent: 0.1);
          await expectLater(
            find.byType(Canvas),
            matchesGoldenFile('kvx_examples/$kvxName.lod.png'),
          );
        });

        if (kvxName != laserkvx) {
          var hasGhostscript = true;
          final gsCheck = Process.runSync('gs', [
            '--version',
          ], runInShell: true);
          if (gsCheck.exitCode != 0) {
            debugPrint('Please install Ghostscript to test PDF exports.');
            hasGhostscript = false;
          }

          testGoldens('(PDF)', (tester) async {
            final context = await _getBuildContext(tester, page.size);

            final pdfFile = File(p.join(tmpDir!.path, '$kvxName.pdf'));
            final pngFile = File(p.join(tmpDir!.path, '$kvxName.pdf.png'));

            // Generate PDF file and write to disk
            await tester.runAsync(() async {
              final doc = await EditorExporter.generatePdf(coreInfo, context);
              final bytes = await doc.save();
              await pdfFile.writeAsBytes(bytes);
            });

            // Convert PDF to PNG with Ghostscript
            await tester.runAsync(
              () => Process.run('gs', [
                '-sDEVICE=pngalpha',
                '-o',
                pngFile.path,
                pdfFile.path,
              ], runInShell: true),
            );

            // Load PNG from disk
            final pdfImage = await tester.runAsync(() => pngFile.readAsBytes());

            // Precache image and render it
            final pdfImageProvider = MemoryImage(pdfImage!);
            await tester.runAsync(
              () => precacheImage(pdfImageProvider, context),
            );
            await tester.pumpWidget(
              Center(
                child: RepaintBoundary(child: Image(image: pdfImageProvider)),
              ),
            );

            tester.useFuzzyComparator(allowedDiffPercent: 0.1);
            await expectLater(
              find.byType(Image),
              matchesGoldenFile('kvx_examples/$kvxName.pdf.png'),
            );
          }, skip: !hasGhostscript);
        }
      });
    }

    testGoldens('kvx export and import', (tester) async {
      const path = 'test/kvx_examples/v19_separate_assets.kvx';
      final pathWithoutExtension = path.substring(0, path.lastIndexOf('.'));

      EditorImage.shouldLoadOutImmediately = true;
      addTearDown(() => EditorImage.shouldLoadOutImmediately = false);

      // copy the file to the temporary directory
      await tester.runAsync(
        () => Future.wait([
          FileManager.getFile(
            '/$path',
          ).create(recursive: true).then((file) => File(path).copy(file.path)),
          FileManager.getFile('/$path.0')
              .create(recursive: true)
              .then((file) => File('$path.0').copy(file.path)),
        ]),
      );

      final coreInfo = await tester.runAsync(
        () => EditorCoreInfo.loadFromFilePath('/$pathWithoutExtension'),
      );
      if (coreInfo == null) fail('Failed to load core info');

      final kvx = await tester.runAsync(
        () => coreInfo.saveToSba(currentPageIndex: null),
      );
      if (kvx == null) fail('Failed to save kvx');

      final kvxFile = File('$pathWithoutExtension.kvx');
      await tester.runAsync(() => kvxFile.writeAsBytes(kvx));
      addTearDown(() async {
        // Wait a bit before deleting to avoid file locking issues on Windows
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          kvxFile.delete();
        } catch (e) {
          // Ignore deletion errors (file may be locked on Windows)
          // print('Warning: Could not delete ${kvxFile.path}: $e');
        }
      });

      final importedPath = await tester.runAsync(
        () => FileManager.importFile(kvxFile.path, null),
      );
      if (importedPath == null) fail('Failed to import kvx');

      final importedCoreInfo = await tester.runAsync(
        () => EditorCoreInfo.loadFromFilePath(importedPath),
      );
      if (importedCoreInfo == null) fail('Failed to load imported core info');

      if (importedCoreInfo.pages.length > 1 &&
          importedCoreInfo.pages.last.isEmpty) {
        importedCoreInfo.pages.removeLast();
      }

      await tester.runAsync(
        () => _precacheImages(
          context: tester.binding.rootElement!,
          page: importedCoreInfo.pages.first,
        ),
      );
      await tester.loadFonts(overriddenFonts: kivixaSansSerifFontFallbacks);
      await tester.pumpWidget(
        _buildCanvas(
          brightness: Brightness.light,
          path: importedPath,
          page: importedCoreInfo.pages.first,
          coreInfo: importedCoreInfo,
        ),
      );
      await tester.pumpAndSettle();

      tester.useFuzzyComparator(allowedDiffPercent: 0.1);
      await expectLater(
        find.byType(Canvas),
        matchesGoldenFile('kvx_examples/v19_separate_assets.kvx.light.png'),
      );
    });
  });
}

/// Provides a [BuildContext] with the necessary inherited widgets
Future<BuildContext> _getBuildContext(
  WidgetTester tester,
  Size pageSize,
) async {
  final completer = Completer<BuildContext>();

  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: FittedBox(
          child: SizedBox(
            width: pageSize.width,
            height: pageSize.height,
            child: Builder(
              builder: (context) {
                completer.complete(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    ),
  );

  return completer.future;
}

Widget _buildCanvas({
  required Brightness brightness,
  required String path,
  required EditorPage page,
  required EditorCoreInfo coreInfo,
  double currentScale = double.maxFinite,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Center(
      child: FittedBox(
        child: SizedBox(
          width: page.size.width,
          height: page.size.height,
          child: RepaintBoundary(
            child: Canvas(
              path: coreInfo.filePath,
              page: page,
              pageIndex: 0,
              textEditing: false,
              coreInfo: coreInfo,
              currentStroke: null,
              currentStrokeDetectedShape: null,
              currentSelection: null,
              setAsBackground: null,
              currentToolIsSelect: false,
              currentScale: currentScale,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _precacheImages({
  required BuildContext context,
  required EditorPage page,
}) async {
  // FileImages aren't working in tests, so replace them with MemoryImages
  final backgroundImage = page.backgroundImage;
  await Future.wait([
    for (final image in page.images)
      if (image is PngEditorImage)
        if (image.imageProvider is FileImage)
          (image.imageProvider as FileImage).file.readAsBytes().then(
            (bytes) => image.imageProvider = MemoryImage(bytes),
          ),
    if (backgroundImage is PngEditorImage)
      if (backgroundImage.imageProvider is FileImage)
        (backgroundImage.imageProvider as FileImage).file.readAsBytes().then(
          (bytes) => (page.backgroundImage as PngEditorImage).imageProvider =
              MemoryImage(bytes),
        ),
  ]);

  // Precache images
  await Future.wait([
    for (final image in page.images) image.precache(context),
    if (page.backgroundImage != null) page.backgroundImage!.precache(context),
  ]);
}
