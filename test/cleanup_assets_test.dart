import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  test('Unused assets should be deleted', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupMockPathProvider();
    SharedPreferences.setMockInitialValues({});

    FlavorConfig.setup();
    await FileManager.init();

    const kvxPath = '/test/kvx_examples/v19_separate_assets.kvx';

    final usedFiles = [
      FileManager.getFile(kvxPath),
      FileManager.getFile('$kvxPath.0'),
      FileManager.getFile('$kvxPath.1'),
    ];
    final unusedFiles = [
      FileManager.getFile('$kvxPath.2'),
      FileManager.getFile('$kvxPath.3'),
      FileManager.getFile('$kvxPath.4'),
      FileManager.getFile('$kvxPath.5'),
    ];

    // create files
    await Future.wait([
      for (final file in [...usedFiles, ...unusedFiles])
        file.create(recursive: true),
    ]);

    FileManager.removeUnusedAssets(kvxPath, numAssets: usedFiles.length - 1);

    // check that used files are still there
    for (final file in usedFiles) {
      expect(file.existsSync(), isTrue);
    }
    // check that unused files are deleted
    for (final file in unusedFiles) {
      expect(file.existsSync(), isFalse);
    }
  });
}
