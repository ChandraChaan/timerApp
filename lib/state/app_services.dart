import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'alarm_controller.dart';
import 'settings_controller.dart';
import 'stopwatch_controller.dart';
import 'timer_controller.dart';
import 'world_clock_controller.dart';

/// Tab indexes of the home screen.
class AppTab {
  AppTab._();

  static const int clock = 0;
  static const int alarm = 1;
  static const int stopwatch = 2;
  static const int timer = 3;
}

/// Holds every controller of the app so widgets can reach them via
/// [AppScope.of].
class AppServices {
  AppServices({
    required this.prefs,
    required this.notifications,
    DateTime Function()? clock,
  })  : settings = SettingsController(prefs),
        worldClock = WorldClockController(prefs),
        stopwatch = StopwatchController(prefs, clock: clock),
        timer = TimerController(prefs, notifications, clock: clock) {
    alarms = AlarmController(prefs, notifications, settings, clock: clock);
    currentTab = ValueNotifier<int>(settings.lastTab);
    currentTab.addListener(() => settings.setLastTab(currentTab.value));
    notifications.onTap = handleNotificationPayload;
  }

  final SharedPreferences prefs;
  final NotificationService notifications;
  final SettingsController settings;
  final WorldClockController worldClock;
  final StopwatchController stopwatch;
  final TimerController timer;
  late final AlarmController alarms;
  late final ValueNotifier<int> currentTab;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> start({String? launchPayload}) async {
    await alarms.start();
    if (launchPayload != null) handleNotificationPayload(launchPayload);
  }

  void handleNotificationPayload(String payload) {
    if (payload.startsWith(kAlarmPayloadPrefix) ||
        payload.startsWith(kSnoozePayloadPrefix)) {
      currentTab.value = AppTab.alarm;
      alarms.ringFromNotification(payload);
    } else if (payload == kTimerPayload) {
      currentTab.value = AppTab.timer;
    }
  }

  void dispose() {
    alarms.dispose();
    timer.dispose();
    stopwatch.dispose();
    worldClock.dispose();
    settings.dispose();
    currentTab.dispose();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    Key? key,
    required this.services,
    required Widget child,
  }) : super(key: key, child: child);

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
