import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jameel/models/user_model.dart';

/// Encrypted Hive wrapper backed by Android Keystore / Keychain via
/// [FlutterSecureStorage]. Falls back to unencrypted Hive only in headless
/// environments (e.g. unit tests) where platform secure storage is unavailable.
class CacheHelper {
  CacheHelper._();

  static const _boxName = 'jameel_cache';
  static const _userKey = 'user';
  static const _themeModeKey = 'theme_mode';
  static const _notifyPrefix = 'notify_';
  static const _watermarkNameKey = 'privacy_watermark_name';
  static const _pinHashKey = 'security_pin_hash';
  static const _pinSaltKey = 'security_pin_salt';
  static const _pinAttemptsKey = 'security_pin_attempts';
  static const _pinLockedUntilKey = 'security_pin_locked_until';
  static const _pendingCheckInsKey = 'pending_checkins';
  static const _secureKeyName = 'jameel_hive_aes_key_v1';

  static HiveCipher? _cipher;
  static bool _encryptionEnabled = true;

  /// Exposes the AES-256 Hive cipher backed by Android Keystore / Keychain so
  /// all local Hive boxes (including offline inspections) share the same key.
  static Future<HiveCipher?> resolveCipher() => _resolveCipher();

  static Future<HiveCipher?> _resolveCipher() async {
    if (!_encryptionEnabled) return null;
    if (_cipher != null) return _cipher;
    try {
      const storage = FlutterSecureStorage();
      final encoded = await storage.read(key: _secureKeyName);
      List<int> keyBytes;
      if (encoded == null || encoded.isEmpty) {
        final random = Random.secure();
        keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
        await storage.write(
          key: _secureKeyName,
          value: base64UrlEncode(keyBytes),
        );
      } else {
        keyBytes = base64Url.decode(encoded);
        if (keyBytes.length != 32) {
          final random = Random.secure();
          keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
          await storage.write(
            key: _secureKeyName,
            value: base64UrlEncode(keyBytes),
          );
        }
      }
      _cipher = HiveAesCipher(keyBytes);
      return _cipher;
    } catch (_) {
      return null;
    }
  }

  static Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    final cipher = await _resolveCipher();
    try {
      return await Hive.openBox(_boxName, encryptionCipher: cipher);
    } catch (_) {
      // Migrate from a previously unencrypted box by recreating with cipher.
      await Hive.deleteBoxFromDisk(_boxName);
      return Hive.openBox(_boxName, encryptionCipher: cipher);
    }
  }

  static Future<void> init({bool enableEncryption = true}) async {
    _encryptionEnabled = enableEncryption;
    if (!enableEncryption) _cipher = null;
    await _box();
  }

  static Future<JameelUserModel?> getCachedUser() async {
    final value = (await _box()).get(_userKey);
    if (value is Map) {
      return JameelUserModel.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static Future<void> cacheUser(JameelUserModel user) async {
    await (await _box()).put(_userKey, user.toMap());
  }

  static Future<void> clearUser() async {
    await (await _box()).delete(_userKey);
  }

  static Future<ThemeMode> getThemeMode() async {
    final raw = (await _box()).get(_themeModeKey) as String?;
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await (await _box()).put(_themeModeKey, mode.name);
  }

  static Future<bool> getNotificationPref(
    String category, {
    bool defaultValue = true,
  }) async {
    final value = (await _box()).get('$_notifyPrefix$category');
    return value is bool ? value : defaultValue;
  }

  static Future<void> setNotificationPref(String category, bool enabled) async {
    await (await _box()).put('$_notifyPrefix$category', enabled);
  }

  static Future<bool> getIncludeNameInWatermark() async {
    final value = (await _box()).get(_watermarkNameKey);
    return value is bool ? value : true;
  }

  static Future<void> setIncludeNameInWatermark(bool enabled) async {
    await (await _box()).put(_watermarkNameKey, enabled);
  }

  static Future<String?> getSecurityPinHash() async {
    final value = (await _box()).get(_pinHashKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  static Future<void> setSecurityPinHash(String? hash) async {
    final box = await _box();
    if (hash == null || hash.isEmpty) {
      await box.delete(_pinHashKey);
      await box.delete(_pinSaltKey);
      await box.delete(_pinAttemptsKey);
      await box.delete(_pinLockedUntilKey);
    } else {
      await box.put(_pinHashKey, hash);
    }
  }

  static Future<String?> getPinSalt() async {
    final value = (await _box()).get(_pinSaltKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  static Future<String> getOrCreatePinSalt() async {
    final existing = await getPinSalt();
    if (existing != null) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64UrlEncode(bytes);
    await (await _box()).put(_pinSaltKey, salt);
    return salt;
  }

  static Future<int> getFailedPinAttempts() async {
    final value = (await _box()).get(_pinAttemptsKey);
    return value is int ? value : 0;
  }

  static Future<void> setFailedPinAttempts(int attempts) async {
    await (await _box()).put(_pinAttemptsKey, attempts);
  }

  static Future<DateTime?> getPinLockedUntil() async {
    final raw = (await _box()).get(_pinLockedUntilKey);
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  static Future<void> setPinLockedUntil(DateTime? until) async {
    final box = await _box();
    if (until == null) {
      await box.delete(_pinLockedUntilKey);
    } else {
      await box.put(_pinLockedUntilKey, until.toIso8601String());
    }
  }

  static Future<void> clearSessionSecurity() async {
    await clearUser();
    await setSecurityPinHash(null);
  }

  static Future<List<Map<String, dynamic>>> getPendingCheckIns() async {
    final raw = (await _box()).get(_pendingCheckInsKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> setPendingCheckIns(
    List<Map<String, dynamic>> items,
  ) async {
    await (await _box()).put(_pendingCheckInsKey, items);
  }
}
