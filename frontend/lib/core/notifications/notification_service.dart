import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watt_sense/core/network/api_client.dart';

/// Global background handler for FCM messages.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For now we just log; foreground UX is handled in-app.
  log('BG FCM: ${message.messageId} data=${message.data}');
}

/// Centralised notification bootstrap for WattWise.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permissions (iOS/web). Android auto-grants normal notifications.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log('Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Register the background handler once.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Get or refresh the device token.
    await _syncTokenWithBackend();

    // Keep backend in sync when token changes.
    _messaging.onTokenRefresh.listen((token) {
      _sendTokenToBackend(token);
    });
  }

  Future<void> _syncTokenWithBackend() async {
    try {
      if (Platform.isIOS) {
        // Wait for APNs token to be available before fetching FCM token.
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          // Can take a brief moment on fresh starts
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _messaging.getAPNSToken();
        }
        if (apnsToken == null) {
          log('APNS token is not available (this is normal on iOS simulators). Skipping FCM token registration.');
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token == null) return;
      await _sendTokenToBackend(token);
    } catch (e) {
      log('Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      if (FirebaseAuth.instance.currentUser == null)
        return; // Only send if logged in

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'unknown';

      await ApiClient.instance.post(
        '/notifications/device-token',
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      log('Failed to register device token: $e');
    }
  }
}
