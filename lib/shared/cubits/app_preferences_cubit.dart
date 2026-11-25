import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/shared/app_config.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

class AppPreferencesState {
  const AppPreferencesState({
    this.themeMode = ThemeMode.light,
    this.notifyLeave = true,
    this.notifyLoan = true,
    this.notifyAnnouncement = true,
    this.notifyCheckIn = true,
    this.includeNameInWatermark = true,
    this.pinHash,
    this.pinSalt,
    this.failedPinAttempts = 0,
    this.pinLockedUntil,
    this.isLocked = false,
    this.currentUser,
  });

  final ThemeMode themeMode;
  final bool notifyLeave;
  final bool notifyLoan;
  final bool notifyAnnouncement;
  final bool notifyCheckIn;
  final bool includeNameInWatermark;
  final String? pinHash;
  final String? pinSalt;
  final int failedPinAttempts;
  final DateTime? pinLockedUntil;
  final bool isLocked;
  final JameelUserModel? currentUser;

  bool get hasSecurityPin => pinHash != null && pinHash!.isNotEmpty;

  bool get isPinCooldownActive =>
      pinLockedUntil != null && DateTime.now().isBefore(pinLockedUntil!);

  int get pinCooldownRemainingSeconds {
    final until = pinLockedUntil;
    if (until == null) return 0;
    final secs = until.difference(DateTime.now()).inSeconds + 1;
    return secs > 0 ? secs : 0;
  }

  bool isCategoryEnabled(String type) {
    switch (type) {
      case 'leave':
        return notifyLeave;
      case 'loan':
        return notifyLoan;
      case 'announcement':
        return notifyAnnouncement;
      default:
        return true;
    }
  }

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    bool? notifyLeave,
    bool? notifyLoan,
    bool? notifyAnnouncement,
    bool? notifyCheckIn,
    bool? includeNameInWatermark,
    String? pinHash,
    bool clearPinHash = false,
    String? pinSalt,
    bool clearPinSalt = false,
    int? failedPinAttempts,
    DateTime? pinLockedUntil,
    bool clearPinLockedUntil = false,
    bool? isLocked,
    JameelUserModel? currentUser,
    bool clearUser = false,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      notifyLeave: notifyLeave ?? this.notifyLeave,
      notifyLoan: notifyLoan ?? this.notifyLoan,
      notifyAnnouncement: notifyAnnouncement ?? this.notifyAnnouncement,
      notifyCheckIn: notifyCheckIn ?? this.notifyCheckIn,
      includeNameInWatermark:
          includeNameInWatermark ?? this.includeNameInWatermark,
      pinHash: clearPinHash ? null : (pinHash ?? this.pinHash),
      pinSalt: clearPinSalt ? null : (pinSalt ?? this.pinSalt),
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      pinLockedUntil: clearPinLockedUntil
          ? null
          : (pinLockedUntil ?? this.pinLockedUntil),
      isLocked: isLocked ?? this.isLocked,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
    );
  }
}

/// Global preferences, theme mode, security PIN lock, and reactive session
/// state backed by [CacheHelper].
class AppPreferencesCubit extends Cubit<AppPreferencesState> {
  AppPreferencesCubit({AppPreferencesState? initialState})
      : super(initialState ?? AppPreferencesState(currentUser: userModel));

  static const int maxPinAttempts = 5;
  static const Duration pinLockoutDuration = Duration(seconds: 30);
  static const String _defaultSalt = 'jameel_pin_v2_default_salt';

  DateTime? _backgroundedAt;
  bool _suppressNextAutoLock = false;

  static AppPreferencesCubit get(BuildContext context) =>
      BlocProvider.of<AppPreferencesCubit>(context);

  /// Loads persisted settings before `runApp` or on startup.
  static Future<AppPreferencesState> loadInitialState() async {
    final themeMode = await CacheHelper.getThemeMode();
    final notifyLeave = await CacheHelper.getNotificationPref('leave');
    final notifyLoan = await CacheHelper.getNotificationPref('loan');
    final notifyAnnouncement =
        await CacheHelper.getNotificationPref('announcement');
    final notifyCheckIn = await CacheHelper.getNotificationPref('check_in');
    final watermarkName = await CacheHelper.getIncludeNameInWatermark();
    final pinHash = await CacheHelper.getSecurityPinHash();
    final pinSalt = await CacheHelper.getPinSalt();
    final failedAttempts = await CacheHelper.getFailedPinAttempts();
    final lockedUntil = await CacheHelper.getPinLockedUntil();
    final hasPin = pinHash != null && pinHash.isNotEmpty;

    return AppPreferencesState(
      themeMode: themeMode,
      notifyLeave: notifyLeave,
      notifyLoan: notifyLoan,
      notifyAnnouncement: notifyAnnouncement,
      notifyCheckIn: notifyCheckIn,
      includeNameInWatermark: watermarkName,
      pinHash: pinHash,
      pinSalt: pinSalt,
      failedPinAttempts: failedAttempts,
      pinLockedUntil: lockedUntil,
      isLocked: hasPin && userModel != null,
      currentUser: userModel,
    );
  }

  /// Prevents the next app pause/resume (e.g. camera or Google picker) from
  /// locking the PIN screen.
  void suppressNextAutoLock() {
    _suppressNextAutoLock = true;
  }

  void onAppBackgrounded() {
    if (_suppressNextAutoLock) return;
    _backgroundedAt ??= DateTime.now();
  }

  void onAppResumed() {
    if (_suppressNextAutoLock) {
      _suppressNextAutoLock = false;
      _backgroundedAt = null;
      return;
    }
    final bgAt = _backgroundedAt;
    _backgroundedAt = null;
    if (bgAt == null) return;
    if (DateTime.now().difference(bgAt) >= AppConfig.autoLockGracePeriod) {
      lockIfEnabled();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await CacheHelper.setThemeMode(mode);
  }

  Future<void> setNotificationPref(String category, bool enabled) async {
    switch (category) {
      case 'leave':
        emit(state.copyWith(notifyLeave: enabled));
        break;
      case 'loan':
        emit(state.copyWith(notifyLoan: enabled));
        break;
      case 'announcement':
        emit(state.copyWith(notifyAnnouncement: enabled));
        break;
      case 'check_in':
        emit(state.copyWith(notifyCheckIn: enabled));
        break;
    }
    await CacheHelper.setNotificationPref(category, enabled);
  }

  Future<void> setIncludeNameInWatermark(bool enabled) async {
    emit(state.copyWith(includeNameInWatermark: enabled));
    await CacheHelper.setIncludeNameInWatermark(enabled);
  }

  void setSessionUser(JameelUserModel? user) {
    userModel = user;
    if (user == null) {
      emit(state.copyWith(clearUser: true, isLocked: false));
    } else {
      emit(state.copyWith(currentUser: user));
    }
  }

  Future<void> updateCachedUser(JameelUserModel user) async {
    userModel = user;
    emit(state.copyWith(currentUser: user));
    await CacheHelper.cacheUser(user);
  }

  Future<void> setSecurityPin(String pin) async {
    final salt = await CacheHelper.getOrCreatePinSalt();
    final hash = hashPin(pin, salt: salt);
    await CacheHelper.setSecurityPinHash(hash);
    await CacheHelper.setFailedPinAttempts(0);
    await CacheHelper.setPinLockedUntil(null);
    emit(
      state.copyWith(
        pinHash: hash,
        pinSalt: salt,
        failedPinAttempts: 0,
        clearPinLockedUntil: true,
        isLocked: false,
      ),
    );
  }

  Future<void> removeSecurityPin() async {
    await CacheHelper.setSecurityPinHash(null);
    emit(
      state.copyWith(
        clearPinHash: true,
        clearPinSalt: true,
        failedPinAttempts: 0,
        clearPinLockedUntil: true,
        isLocked: false,
      ),
    );
  }

  bool verifyPin(String pin) {
    if (!state.hasSecurityPin) return true;
    final salt = state.pinSalt ?? _defaultSalt;
    if (hashPin(pin, salt: salt) == state.pinHash) return true;
    // Backward compatibility with legacy 16-char FNV-1a hashes before upgrade.
    if (state.pinHash?.length == 16 && _legacyFnv1a(pin) == state.pinHash) {
      return true;
    }
    return false;
  }

  bool verifyAndUnlock(String pin) {
    if (!state.hasSecurityPin) return true;
    if (state.isPinCooldownActive) return false;

    if (verifyPin(pin)) {
      CacheHelper.setFailedPinAttempts(0);
      CacheHelper.setPinLockedUntil(null);
      emit(
        state.copyWith(
          isLocked: false,
          failedPinAttempts: 0,
          clearPinLockedUntil: true,
        ),
      );
      return true;
    }

    final attempts = state.failedPinAttempts + 1;
    if (attempts >= maxPinAttempts) {
      final lockedUntil = DateTime.now().add(pinLockoutDuration);
      CacheHelper.setFailedPinAttempts(0);
      CacheHelper.setPinLockedUntil(lockedUntil);
      emit(
        state.copyWith(
          failedPinAttempts: 0,
          pinLockedUntil: lockedUntil,
        ),
      );
    } else {
      CacheHelper.setFailedPinAttempts(attempts);
      emit(state.copyWith(failedPinAttempts: attempts));
    }
    return false;
  }

  void clearCooldownIfExpired() {
    if (state.pinLockedUntil != null && !state.isPinCooldownActive) {
      CacheHelper.setPinLockedUntil(null);
      emit(state.copyWith(clearPinLockedUntil: true));
    }
  }

  void lockIfEnabled() {
    if (state.hasSecurityPin && state.currentUser != null) {
      emit(state.copyWith(isLocked: true));
    }
  }

  /// Cryptographic SHA-256 PIN digest with per-device random salt.
  static String hashPin(String pin, {String salt = _defaultSalt}) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static String _legacyFnv1a(String pin) {
    const salt = 'jameel_pin_v1_salt:';
    final input = '$salt$pin';
    var h1 = 0x811C9DC5;
    var h2 = 0xCBF29CE4;
    for (var i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      h1 ^= code;
      h1 = (h1 * 0x01000193) & 0xFFFFFFFF;
      h2 ^= (code + i);
      h2 = (h2 * 0x01000193) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}';
  }
}
