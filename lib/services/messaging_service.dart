import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'notification_service.dart';

/// Must be a top-level function so it can run in a background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background push received: ${message.messageId}');
}

/// Firebase Cloud Messaging: initialises Firebase, shows pushes that arrive in
/// the foreground and opens a dialog when a push notification is tapped.
/// Everything is optional: the clock works fully without Firebase.
class MessagingService {
  MessagingService._();

  static bool _ready = false;

  static Future<bool> initFirebase() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 15));
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _ready = true;
    } catch (e) {
      debugPrint('Firebase not configured, push messages disabled: $e');
      _ready = false;
    }
    return _ready;
  }

  static void listen(
    NotificationService notifications,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    if (!_ready) return;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        notifications.showPush(
            notification.hashCode, notification.title, notification.body);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final notification = message.notification;
      final context = navigatorKey.currentContext;
      if (notification == null || context == null) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(notification.title ?? 'Message'),
          content: SingleChildScrollView(
            child: Text(notification.body ?? ''),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}
