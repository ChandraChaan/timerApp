import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerapp/app.dart';
import 'package:timerapp/services/notification_service.dart';
import 'package:timerapp/services/time_zone_service.dart';
import 'package:timerapp/state/app_services.dart';
import 'package:timerapp/ui/screens/stopwatch_screen.dart';
import 'package:timerapp/ui/screens/ring_screen.dart';

/// Pumps frames for [duration] so route, sheet and FAB transitions finish.
/// (pumpAndSettle never settles here: the clocks tick continuously.)
Future<void> settle(WidgetTester tester,
    [Duration duration = const Duration(milliseconds: 800)]) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < duration; t += step) {
    await tester.pump(step);
  }
}

void main() {
  setUpAll(TimeZoneService.ensureInitialized);

  Future<AppServices> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final services = AppServices(
      prefs: prefs,
      notifications: NotificationService.disabled(),
    );
    tester.binding.window.physicalSizeTestValue = const Size(1080, 2340);
    tester.binding.window.devicePixelRatioTestValue = 3;
    await tester.pumpWidget(ClockApp(services: services));
    await settle(tester);
    return services;
  }

  Future<void> tearDownApp(WidgetTester tester, AppServices services) async {
    await tester.pumpWidget(const SizedBox());
    services.dispose();
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  }

  testWidgets('shows clock with default world cities', (tester) async {
    final services = await pumpApp(tester);
    expect(find.text('Clock'), findsWidgets);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);
    await tearDownApp(tester, services);
  });

  testWidgets('navigates tabs and runs the stopwatch', (tester) async {
    final services = await pumpApp(tester);

    await tester.tap(find.text('Stopwatch').last);
    await settle(tester);
    expect(find.text('00:00.00'), findsOneWidget);

    Finder inStopwatch(Finder f) =>
        find.descendant(of: find.byType(StopwatchScreen), matching: f);
    await tester.tap(inStopwatch(find.byTooltip('Start')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(services.stopwatch.isRunning, isTrue);

    await tester.tap(inStopwatch(find.byTooltip('Pause')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(services.stopwatch.isRunning, isFalse);

    await tester.tap(find.text('Alarm').last);
    await settle(tester);
    expect(find.text('No alarms yet'), findsOneWidget);

    await tester.tap(find.text('Timer').last);
    await settle(tester);
    expect(find.text('Quick start'.toUpperCase()), findsOneWidget);

    await tearDownApp(tester, services);
  });

  testWidgets('adds an alarm through the editor', (tester) async {
    final services = await pumpApp(tester);
    services.currentTab.value = AppTab.alarm;
    await settle(tester);

    await tester.tap(find.byTooltip('Add alarm'));
    await settle(tester);
    expect(find.text('New alarm'), findsOneWidget);

    await tester.tap(find.text('Weekdays'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(services.alarms.alarms.length, 1);
    expect(services.alarms.alarms.single.days, <int>{1, 2, 3, 4, 5});
    expect(find.textContaining('Weekdays'), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
    await tearDownApp(tester, services);
  });

  testWidgets('a finished timer opens the ring screen', (tester) async {
    final services = await pumpApp(tester);
    services.timer.start(const Duration(seconds: 1), label: 'Pasta');
    await tester.pump(const Duration(milliseconds: 50));
    // Force completion without waiting on the real clock.
    services.timer.addTime(const Duration(seconds: -2));
    services.timer.checkFinished();
    await settle(tester);
    expect(find.byType(RingScreen), findsOneWidget);
    expect(find.text('Pasta'), findsWidgets);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await settle(tester);
    expect(find.text('Stop'), findsNothing);
    await tearDownApp(tester, services);
  });
}
