import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/messaging_service.dart';
import 'services/notification_service.dart';
import 'services/time_zone_service.dart';
import 'state/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  TimeZoneService.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  final launchPayload = await notifications.init();

  final services = AppServices(prefs: prefs, notifications: notifications);
  runApp(ClockApp(services: services));
  await services.start(launchPayload: launchPayload);

  // Push messages are optional; never let Firebase delay the clock.
  if (await MessagingService.initFirebase()) {
    MessagingService.listen(notifications, services.navigatorKey);
  }
}
