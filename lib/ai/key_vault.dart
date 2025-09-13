import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

class KeyVault {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> setApiKey(String provider, String apiKey) async {
    if (Platform.isAndroid || Platform.isWindows) {
      await _secureStorage.write(key: 'api_key_$provider', value: apiKey);
    } else {
      await _setApiKeyEncryptedFile(provider, apiKey);
    }
  }

  Future<String?> getApiKey(String provider) async {
    if (Platform.isAndroid || Platform.isWindows) {
      return await _secureStorage.read(key: 'api_key_$provider');
    } else {
      return await _getApiKeyEncryptedFile(provider);
    }
  }

  Future<void> _setApiKeyEncryptedFile(String provider, String apiKey) async {
    final file = await _getEncryptedFile(provider);
    final salt = _generateSalt();
    final key = await _getKey(salt);
    final iv = _generateIv();

    final cipher = GCMBlockCipher(AESFastEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final encrypted = cipher.process(utf8.encode(apiKey));

    await file.writeAsBytes(salt + iv + encrypted);
  }

  Future<String?> _getApiKeyEncryptedFile(String provider) async {
    try {
      final file = await _getEncryptedFile(provider);
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsBytes();
      final salt = contents.sublist(0, 16);
      final iv = contents.sublist(16, 28);
      final encrypted = contents.sublist(28);

      final key = await _getKey(salt);
      final cipher = GCMBlockCipher(AESFastEngine())
        ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

      final decrypted = cipher.process(encrypted);
      return utf8.decode(decrypted);
    } catch (e) {
      // Handle decryption errors, e.g., by deleting the file
      return null;
    }
  }

  Future<File> _getEncryptedFile(String provider) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/api_key_$provider.enc');
  }

  Future<Uint8List> _getKey(Uint8List salt) async {
    // In a real app, use a more secure way to get a device-scoped key
    final deviceId = await _getDeviceId();
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), KeyParameter(Uint8List(0))))
      ..init(Pbkdf2Parameters(salt, 1000, 32));
    return pbkdf2.process(utf8.encode(deviceId));
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  Uint8List _generateIv() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(12, (_) => random.nextInt(256)));
  }

  Future<String> _getDeviceId() async {
    // This is a placeholder. In a real app, use a more robust method
    // to get a unique and stable device ID.
    return 'some_unique_device_id';
  }
}