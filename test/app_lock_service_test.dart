import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/flavor_config.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlavorConfig.setup(
      flavor: 'test',
      appStore: 'test',
      shouldCheckForUpdatesByDefault: false,
    );
  });

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final log = <MethodCall>[];

  void setupMockSecureStorage(MethodChannel channel, {Map<String, String>? initialData}) {
    final data = initialData ?? {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'write':
          data[methodCall.arguments['key']] = methodCall.arguments['value'];
          return null;
        case 'read':
          return data[methodCall.arguments['key']];
        case 'delete':
          data.remove(methodCall.arguments['key']);
          return null;
        case 'containsKey':
          return data.containsKey(methodCall.arguments['key']);
        case 'deleteAll':
          data.clear();
          return null;
      }
      return null;
    });
  }

  setUp(() {
    log.clear();
    stows.appLockEnabled.value = false;
    stows.appLockPinSet.value = false;
    setupMockSecureStorage(channel);
  });

  group('AppLockService.setPin', () {
    test('returns false and logs error when storage throws exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          throw Exception('Storage error');
        }
        return null;
      });

      final service = AppLockService();
      final result = await service.setPin('1234');

      expect(result, isFalse);
      expect(stows.appLockPinSet.value, isFalse);
      expect(stows.appLockEnabled.value, isFalse);
    });

    test('returns true and updates state on success', () async {
      final service = AppLockService();
      final result = await service.setPin('1234');

      expect(result, isTrue);
      expect(stows.appLockPinSet.value, isTrue);
      expect(stows.appLockEnabled.value, isTrue);

      final writeCall = log.firstWhere((c) => c.method == 'write');
      expect(writeCall.arguments['key'], 'app_lock_pin_hash');
      expect(writeCall.arguments['value'], isNotNull);
    });

    test('returns false for PIN shorter than 4 characters', () async {
      final service = AppLockService();
      final result = await service.setPin('123');

      expect(result, isFalse);
      expect(stows.appLockPinSet.value, isFalse);
    });
  });

  group('AppLockService.verifyPin', () {
    test('returns true for correct PIN', () async {
      final service = AppLockService();
      await service.setPin('1234');
      log.clear();

      final result = await service.verifyPin('1234');
      expect(result, isTrue);
    });

    test('returns false for incorrect PIN', () async {
      final service = AppLockService();
      await service.setPin('1234');
      log.clear();

      final result = await service.verifyPin('5678');
      expect(result, isFalse);
    });

    test('returns false when no PIN is set', () async {
      final service = AppLockService();
      final result = await service.verifyPin('1234');
      expect(result, isFalse);
    });

    test('returns false when storage throws exception', () async {
      final service = AppLockService();
      await service.setPin('1234');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          throw Exception('Read error');
        }
        return null;
      });

      final result = await service.verifyPin('1234');
      expect(result, isFalse);
    });
  });

  group('AppLockService.changePin', () {
    test('returns true and updates PIN when old PIN is correct', () async {
      final service = AppLockService();
      await service.setPin('1234');
      log.clear();

      final result = await service.changePin('1234', '5678');
      expect(result, isTrue);

      final isVerifyNewPin = await service.verifyPin('5678');
      expect(isVerifyNewPin, isTrue);
    });

    test('returns false when old PIN is incorrect', () async {
      final service = AppLockService();
      await service.setPin('1234');
      log.clear();

      final result = await service.changePin('0000', '5678');
      expect(result, isFalse);

      final isVerifyOldPin = await service.verifyPin('1234');
      expect(isVerifyOldPin, isTrue);
    });
  });

  group('AppLockService.removePin', () {
    test('returns true and clears state when PIN is correct', () async {
      final service = AppLockService();
      await service.setPin('1234');
      log.clear();

      final result = await service.removePin('1234');
      expect(result, isTrue);
      expect(stows.appLockPinSet.value, isFalse);
      expect(stows.appLockEnabled.value, isFalse);

      final deleteCall = log.firstWhere((c) => c.method == 'delete');
      expect(deleteCall.arguments['key'], 'app_lock_pin_hash');
    });

    test('returns false when PIN is incorrect', () async {
      final service = AppLockService();
      await service.setPin('1234');
      log.clear();

      final result = await service.removePin('5678');
      expect(result, isFalse);
      expect(stows.appLockPinSet.value, isTrue);
    });

    test('returns false when storage throws exception during deletion', () async {
      // SHA256 of '1234'
      const hash1234 = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'read') return hash1234;
        if (methodCall.method == 'delete') throw Exception('Delete error');
        return null;
      });

      final service = AppLockService();
      final result = await service.removePin('1234');
      expect(result, isFalse);
    });
  });

  group('AppLockService PBKDF2 formats and Migration', () {
    test('setPin generates PBKDF2 format', () async {
      final service = AppLockService();
      final success = await service.setPin('1234');

      expect(success, isTrue);
      final writeCall = log.firstWhere((c) => c.method == 'write');
      final writtenValue = writeCall.arguments['value'] as String;
      expect(writtenValue.startsWith('pbkdf2:sha256:10000:'), isTrue);
    });

    test('verifyPin handles legacy SHA256 migration without changing enabled state', () async {
      final service = AppLockService();

      // '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4' is SHA256 for '1234'
      final storedData = {
        'app_lock_pin_hash': '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'
      };

      setupMockSecureStorage(channel, initialData: storedData);

      stows.appLockEnabled.value = false;
      stows.appLockPinSet.value = true;
      log.clear();

      final isValid = await service.verifyPin('1234');
      expect(isValid, isTrue);

      // Verify migration triggered a write
      final writeCall = log.firstWhere((c) => c.method == 'write');
      final writtenValue = writeCall.arguments['value'] as String;
      expect(writtenValue.startsWith('pbkdf2:sha256:10000:'), isTrue);

      // Verify enabled state wasn't changed
      expect(stows.appLockEnabled.value, isFalse);
    });
  });

  group('AppLockService UI controls', () {
    test('enable() should enable app lock if PIN is set', () {
      final service = AppLockService();
      stows.appLockPinSet.value = true;
      stows.appLockEnabled.value = false;

      service.enable();
      expect(stows.appLockEnabled.value, isTrue);
    });

    test('enable() should NOT enable app lock if PIN is not set', () {
      final service = AppLockService();
      stows.appLockPinSet.value = false;
      stows.appLockEnabled.value = false;

      service.enable();
      expect(stows.appLockEnabled.value, isFalse);
    });

    test('disable() should disable app lock', () {
      final service = AppLockService();
      stows.appLockEnabled.value = true;

      service.disable();
      expect(stows.appLockEnabled.value, isFalse);
    });

    test('toggle() should switch enabled state', () {
      final service = AppLockService();
      stows.appLockPinSet.value = true;

      stows.appLockEnabled.value = true;
      service.toggle();
      expect(stows.appLockEnabled.value, isFalse);

      service.toggle();
      expect(stows.appLockEnabled.value, isTrue);
    });
  });
}
