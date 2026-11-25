import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('jameel_prefs_test_');
    Hive.init(tempDir.path);
    await CacheHelper.init(enableEncryption: false);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    userModel = null;
  });

  group('AppPreferencesCubit', () {
    test('persists and restores themeMode and notification preferences', () async {
      final cubit = AppPreferencesCubit();
      await cubit.setThemeMode(ThemeMode.dark);
      await cubit.setNotificationPref('loan', false);
      await cubit.setIncludeNameInWatermark(false);

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.notifyLoan, isFalse);
      expect(cubit.state.isCategoryEnabled('loan'), isFalse);
      expect(cubit.state.isCategoryEnabled('leave'), isTrue);
      expect(cubit.state.includeNameInWatermark, isFalse);

      final loaded = await AppPreferencesCubit.loadInitialState();
      expect(loaded.themeMode, ThemeMode.dark);
      expect(loaded.notifyLoan, isFalse);
      expect(loaded.includeNameInWatermark, isFalse);

      await cubit.close();
    });

    test('sets salted SHA-256 PIN, verifies, unlocks, and removes PIN', () async {
      final cubit = AppPreferencesCubit();
      cubit.setSessionUser(const JameelUserModel(uId: 'u1', userName: 'Ali'));
      await cubit.setSecurityPin('2580');

      expect(cubit.state.hasSecurityPin, isTrue);
      expect(cubit.state.pinHash?.length, 64);
      expect(cubit.state.pinSalt, isNotEmpty);

      cubit.lockIfEnabled();
      expect(cubit.state.isLocked, isTrue);
      expect(cubit.verifyAndUnlock('0000'), isFalse);
      expect(cubit.state.isLocked, isTrue);
      expect(cubit.verifyAndUnlock('2580'), isTrue);
      expect(cubit.state.isLocked, isFalse);

      await cubit.removeSecurityPin();
      expect(cubit.state.hasSecurityPin, isFalse);
      await cubit.close();
    });

    test('locks PIN verification temporarily after 5 consecutive failures', () async {
      final cubit = AppPreferencesCubit();
      cubit.setSessionUser(const JameelUserModel(uId: 'u1', userName: 'Ali'));
      await cubit.setSecurityPin('4321');
      cubit.lockIfEnabled();

      for (var i = 0; i < AppPreferencesCubit.maxPinAttempts; i++) {
        expect(cubit.verifyAndUnlock('0000'), isFalse);
      }

      expect(cubit.state.isPinCooldownActive, isTrue);
      expect(cubit.verifyAndUnlock('4321'), isFalse);

      await cubit.removeSecurityPin();
      await cubit.close();
    });
  });
}
