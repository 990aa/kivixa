import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kivixa/services/notification_sound_catalog_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => '.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    final soundsDir = Directory('notification_sounds')
      ..createSync(recursive: true);
    // ensure a clean state
    for (final f in soundsDir.listSync()) {
      try {
        if (f is File) f.deleteSync();
      } catch (_) {}
    }
  });

  tearDown(() async {
    final soundsDir = Directory('notification_sounds');
    if (soundsDir.existsSync()) {
      await soundsDir.delete(recursive: true);
    }
  });

  test('downloadReminderSound writes file from network', () async {
    final option = NotificationSoundCatalogService.reminderSoundOptions
        .firstWhere((it) => it.id == 'alarm_wind_chimes');

    final client = MockClient((request) async {
      return http.Response.bytes([10, 20, 30, 40], 200);
    });

    await NotificationSoundCatalogService.instance.downloadReminderSound(
      option.id,
      client: client,
    );

    final file = await NotificationSoundCatalogService.instance
        .localPathForReminderSound(option.id);

    expect(file, isNotNull);
    final bytes = File(file!).readAsBytesSync();
    expect(bytes, equals([10, 20, 30, 40]));
  });

  test('downloadStates reflects existing files', () async {
    final option = NotificationSoundCatalogService.reminderSoundOptions.first;
    final soundsDir = Directory('notification_sounds');
    final target = File(
      '${soundsDir.path}${Platform.pathSeparator}${option.fileName}',
    );
    target.writeAsBytesSync([1, 2, 3]);

    final states = await NotificationSoundCatalogService.instance
        .downloadStates();
    expect(states[option.id], isTrue);
  });
}
