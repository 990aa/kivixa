
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';

class KeyVault {
  final _storage = const FlutterSecureStorage();

  Future<void> setApiKey(String provider, String apiKey) async {
    await _storage.write(key: 'api_key_$provider', value: apiKey);
  }

  Future<String?> getApiKey(String provider) async {
    return await _storage.read(key: 'api_key_$provider');
  }

  Future<void> deleteApiKey(String provider) async {
    await _storage.delete(key: 'api_key_$provider');
  }

  // Fallback for Windows if flutter_secure_storage fails.
  // This is a simplified example. In a real-world scenario, you would need
  // a more robust way to handle the key and salt.
  Future<void> _setApiKeyFallback(String provider, String apiKey) async {
    if (!Platform.isWindows) return;

    final key = await _getDeviceScopedKey();
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = encrypter.encrypt(apiKey, iv: iv);
    final file = await _getEncryptedStoreFile();
    final storedData = await _readEncryptedStore(file);

    storedData['api_key_$provider'] = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };

    await file.writeAsString(jsonEncode(storedData));
  }

  Future<String?> _getApiKeyFallback(String provider) async {
    if (!Platform.isWindows) return null;

    final file = await _getEncryptedStoreFile();
    if (!await file.exists()) return null;

    final storedData = await _readEncryptedStore(file);
    final providerData = storedData['api_key_$provider'];
    if (providerData == null) return null;

    final key = await _getDeviceScopedKey();
    final iv = enc.IV.fromBase64(providerData['iv']);
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = enc.Encrypted.fromBase64(providerData['data']);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<Map<String, dynamic>> _readEncryptedStore(File file) async {
    if (!await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString());
    } catch (e) {
      return {};
    }
  }

  Future<File> _getEncryptedStoreFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/.kv');
  }

  Future<enc.Key> _getDeviceScopedKey() async {
    // This is a simplified example. In a real-world scenario, you would want
    // to use a more secure, device-specific salt.
    const salt = 'a-very-salty-salt';
    final deviceId = await _getDeviceId();
    final key = sha256.convert(utf8.encode('$deviceId$salt')).bytes;
    return enc.Key.fromBase64(base64Url.encode(key).substring(0, 32));
  }

  Future<String> _getDeviceId() async {
    // This is not a reliable way to get a unique device ID.
    // A better approach would be to use a library that provides a stable device ID.
    return Platform.localHostname;
  }
}
