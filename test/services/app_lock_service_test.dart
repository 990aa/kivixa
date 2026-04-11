import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/app_lock_service.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:stow/stow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLockService service;

  setUpAll(() async {
    // Mock the FlutterSecureStorage MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return null;
        } else if (methodCall.method == 'write') {
          return null;
        } else if (methodCall.method == 'delete') {
          return null;
        } else if (methodCall.method == 'deleteAll') {
          return null;
        }
        return null;
      },
    );

    FlavorConfig.setup(
      flavor: 'test',
      appStore: 'test',
      shouldCheckForUpdatesByDefault: false,
    );
    Stows.markAsOnMainIsolate();
  });

  setUp(() {
    service = AppLockService();
  });

  test('setPin generates PBKDF2 format', () async {
    String? writtenKey;
    String? writtenValue;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          writtenKey = methodCall.arguments['key'];
          writtenValue = methodCall.arguments['value'];
        }
        return null;
      },
    );

    final success = await service.setPin('1234');
    expect(success, isTrue);
    expect(writtenKey, 'app_lock_pin_hash');
    expect(writtenValue, isNotNull);
    expect(writtenValue!.startsWith('pbkdf2:sha256:10000:'), isTrue);
  });

  test('verifyPin handles PBKDF2 format', () async {
    // Generate a valid PBKDF2 hash by mocking the storage correctly across set/read
    String? storedValue;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          storedValue = methodCall.arguments['value'];
        } else if (methodCall.method == 'read') {
          return storedValue;
        }
        return null;
      },
    );

    // Set the PIN
    await service.setPin('5678');

    // Verify valid PIN
    final isValid = await service.verifyPin('5678');
    expect(isValid, isTrue);

    // Verify invalid PIN
    final isInvalid = await service.verifyPin('1234');
    expect(isInvalid, isFalse);
  });

  test('verifyPin handles legacy SHA256 migration', () async {
    // '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4' is SHA256 for '1234'
    String storedValue = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';
    bool migrationTriggered = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return storedValue;
        } else if (methodCall.method == 'write') {
          storedValue = methodCall.arguments['value'];
          migrationTriggered = true;
        }
        return null;
      },
    );

    final isValid = await service.verifyPin('1234');
    expect(isValid, isTrue);

    // Verify migration triggered
    expect(migrationTriggered, isTrue);
    expect(storedValue.startsWith('pbkdf2:sha256:10000:'), isTrue);
  });
}
