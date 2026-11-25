import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:jameel/data/repositories/auth_repository.dart';

/// Configures Firebase Cloud Messaging (FCM) permissions, token sync, and
/// foreground message notifications.
class PushNotificationsService {
  PushNotificationsService({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  Future<void> initForEmployee(
    String? uid, {
    void Function(String title, String body)? onForegroundMessage,
  }) async {
    if (uid == null || uid.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        try {
          await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e) {
          debugPrint('FCM permission request skipped: $e');
        }
      }
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _authRepository.saveFcmToken(uid: uid, token: token);
      }

      await _tokenSub?.cancel();
      _tokenSub = messaging.onTokenRefresh.listen((newToken) {
        _authRepository.saveFcmToken(uid: uid, token: newToken);
      });

      await _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        final notif = message.notification;
        if (notif != null && onForegroundMessage != null) {
          onForegroundMessage(notif.title ?? '', notif.body ?? '');
        }
      });
    } catch (e) {
      debugPrint('FCM initialization skipped: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _foregroundSub?.cancel();
  }
}
