import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kivixa/data/prefs.dart';

/// Service to manage app lock functionality with PIN/password protection.
///
/// Uses FlutterSecureStorage to securely store the hashed PIN.
class AppLockService {
  static const _pinKey = 'app_lock_pin_hash';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final AppLockService _instance = AppLockService._internal();
  factory AppLockService() => _instance;
  AppLockService._internal();

  /// Whether app lock is currently enabled
  bool get isEnabled => stows.appLockEnabled.value && stows.appLockPinSet.value;

  /// Whether a PIN has been set
  bool get isPinSet => stows.appLockPinSet.value;

  /// Hash a PIN using SHA256
  String _hashPin(String pin) {
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
      final hashedPin = _hashPin(pin);
      await _storage.write(key: _pinKey, value: hashedPin);
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

      final inputHash = _hashPin(pin);
      return storedHash == inputHash;
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
