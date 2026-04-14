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

  /// Constant-time byte array comparison to prevent timing side-channels
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generate a PBKDF2 hash using the provided salt
  Uint8List _hashPinPbkdf2(String pin, Uint8List salt) {
    final pinBytes = Uint8List.fromList(utf8.encode(pin));
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, 32));
    return pbkdf2.process(pinBytes);
  }

  /// Legacy SHA256 hash for backward compatibility
  Uint8List _hashPinLegacy(String pin) {
    final bytes = utf8.encode(pin);
    return Uint8List.fromList(sha256.convert(bytes).bytes);
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
      final hashedPin = base64.encode(_hashPinPbkdf2(pin, salt));

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
        final storedHashBytes = base64.decode(parts[4]);

        final salt = base64.decode(saltStr);
        final inputHashBytes = _hashPinPbkdf2(pin, salt);

        return _constantTimeEquals(inputHashBytes, storedHashBytes);
      } else {
        // Fallback to legacy SHA256 format
        final storedHashBytes = Uint8List.fromList(
          List.generate(
            storedHash.length ~/ 2,
            (i) => int.parse(storedHash.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
        final inputHashBytes = _hashPinLegacy(pin);
        final isValid = _constantTimeEquals(inputHashBytes, storedHashBytes);

        // Transparent migration to PBKDF2 if verification succeeds,
        // preserving current enabled/disabled state
        if (isValid) {
          final random = Random.secure();
          final salt = Uint8List(16);
          for (int i = 0; i < 16; i++) {
            salt[i] = random.nextInt(256);
          }
          final saltStr = base64.encode(salt);
          final hashedPin = base64.encode(_hashPinPbkdf2(pin, salt));
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
