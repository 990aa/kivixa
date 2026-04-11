import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:pointycastle/export.dart';

/// Service to manage app lock functionality with PIN/password protection.
///
/// Uses FlutterSecureStorage to securely store the hashed PIN.
class AppLockService {
  static const _pinKey = 'app_lock_pin_hash';
  static const _storage = FlutterSecureStorage();

  static final _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  /// Whether app lock is currently enabled
  bool get isEnabled => stows.appLockEnabled.value && stows.appLockPinSet.value;

  /// Whether a PIN has been set
  bool get isPinSet => stows.appLockPinSet.value;

  /// Generate a PBKDF2 hash using the provided salt
  String _hashPinPbkdf2(String pin, Uint8List salt) {
    final pinBytes = Uint8List.fromList(utf8.encode(pin));
    final pbkdf2 = PBKDF2KeyDerivator(Mac('SHA-256/HMAC'))
      ..init(Pbkdf2Parameters(salt, 10000, 32));
    final hash = pbkdf2.process(pinBytes);
    return base64.encode(hash);
  }

  /// Legacy SHA256 hash for backward compatibility
  String _hashPinLegacy(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Set up a new PIN
  /// Returns true if successful
  Future<bool> setPin(String pin) async {
    if (pin.length < 4) {
      return false;
    }

    try {
      final random = Random.secure();
      final salt = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        salt[i] = random.nextInt(256);
      }

      final saltStr = base64.encode(salt);
      final hashedPin = _hashPinPbkdf2(pin, salt);

      final storedFormat = 'pbkdf2:sha256:10000:$saltStr:$hashedPin';

      await _storage.write(key: _pinKey, value: storedFormat);
      stows.appLockPinSet.value = true;
      stows.appLockEnabled.value = true;
      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    }
  }

  /// Verify if the provided PIN matches the stored PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      if (storedHash == null) {
        return false;
      }

      // Check if it's the new PBKDF2 format
      if (storedHash.startsWith('pbkdf2:sha256:10000:')) {
        final parts = storedHash.split(':');
        if (parts.length != 5) return false;

        final saltStr = parts[3];
        final hashStr = parts[4];

        final salt = base64.decode(saltStr);
        final expectedHashBytes = base64.decode(hashStr);

        final pinBytes = Uint8List.fromList(utf8.encode(pin));
        final pbkdf2 = PBKDF2KeyDerivator(Mac('SHA-256/HMAC'))
          ..init(Pbkdf2Parameters(salt, 10000, 32));
        final actualHashBytes = pbkdf2.process(pinBytes);

        if (expectedHashBytes.length != actualHashBytes.length) return false;

        var result = 0;
        for (var i = 0; i < expectedHashBytes.length; i++) {
          result |= expectedHashBytes[i] ^ actualHashBytes[i];
        }

        return result == 0;
      } else {
        // Fallback to legacy SHA256 format
        final inputHash = _hashPinLegacy(pin);

        final expectedBytes = utf8.encode(storedHash);
        final actualBytes = utf8.encode(inputHash);

        if (expectedBytes.length != actualBytes.length) return false;

        var result = 0;
        for (var i = 0; i < expectedBytes.length; i++) {
          result |= expectedBytes[i] ^ actualBytes[i];
        }

        final isValid = result == 0;

        // Transparent migration to PBKDF2 if verification succeeds
        if (isValid) {
          // Re-hash and store without changing the enabled state
          final random = Random.secure();
          final salt = Uint8List(16);
          for (int i = 0; i < 16; i++) {
            salt[i] = random.nextInt(256);
          }

          final saltStr = base64.encode(salt);
          final hashedPin = _hashPinPbkdf2(pin, salt);
          final storedFormat = 'pbkdf2:sha256:10000:$saltStr:$hashedPin';

          await _storage.write(key: _pinKey, value: storedFormat);
        }

        return isValid;
      }
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Change the PIN (requires old PIN verification first)
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!await verifyPin(oldPin)) {
      return false;
    }

    return await setPin(newPin);
  }

  /// Remove the PIN and disable app lock
  Future<bool> removePin(String currentPin) async {
    if (!await verifyPin(currentPin)) {
      return false;
    }

    try {
      await _storage.delete(key: _pinKey);
      stows.appLockPinSet.value = false;
      stows.appLockEnabled.value = false;
      return true;
    } catch (e) {
      debugPrint('Error removing PIN: $e');
      return false;
    }
  }

  /// Enable app lock (PIN must already be set)
  void enable() {
    if (stows.appLockPinSet.value) {
      stows.appLockEnabled.value = true;
    }
  }

  /// Disable app lock (doesn't remove the PIN)
  void disable() {
    stows.appLockEnabled.value = false;
  }

  /// Toggle app lock enabled state
  void toggle() {
    if (stows.appLockEnabled.value) {
      disable();
    } else {
      enable();
    }
  }
}
