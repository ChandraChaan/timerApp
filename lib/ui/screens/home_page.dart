import 'package:flutter/material.dart';

import '../../state/app_services.dart';
import '../../state/timer_controller.dart';
import 'alarm_screen.dart';
import 'clock_screen.dart';
import 'ring_screen.dart';
import 'stopwatch_screen.dart';
import 'timer_screen.dart';

/// Works with both the nullable (Flutter 2) and non-nullable (Flutter 3)
/// `WidgetsBinding.instance`.
T? _ambiguate<T>(T? value) => value;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late AppServices _services;
  bool _listening = false;
  Route<void>? _alarmRoute;
  Route<void>? _timerRoute;

  static const List<Widget> _screens = <Widget>[
    ClockScreen(),
    AlarmScreen(),
    StopwatchScreen(),
    TimerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ambiguate(WidgetsBinding.instance)!.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listening) return;
    _listening = true;
    _services = AppScope.of(context);
    _services.alarms.ringing.addListener(_onAlarmRinging);
    _services.timer.addListener(_onTimerChanged);
    // Something may already be ringing (e.g. launched from a notification).
    _ambiguate(WidgetsBinding.instance)!.addPostFrameCallback((_) {
      _onAlarmRinging();
      _onTimerChanged();
    });
  }

  @override
  void dispose() {
    _ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    if (_listening) {
      _services.alarms.ringing.removeListener(_onAlarmRinging);
      _services.timer.removeListener(_onTimerChanged);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _services.alarms.checkDue();
      _services.timer.checkFinished();
    }
  }

  void _onAlarmRinging() {
    if (!mounted) return;
    final alarm = _services.alarms.ringing.value;
    if (alarm == null) {
      _closeRoute(_alarmRoute);
      _alarmRoute = null;
      return;
    }
    if (_alarmRoute != null) return;
    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RingScreen(
        kind: RingKind.alarm,
        title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
        vibrate: alarm.vibrate,
        primaryLabel: 'Dismiss',
        onPrimary: _services.alarms.dismiss,
        secondaryLabel: 'Snooze ${alarm.snoozeMinutes} min',
        onSecondary: _services.alarms.snooze,
      ),
    );
    _alarmRoute = route;
    Navigator.of(context).push(route).then((_) {
      if (_alarmRoute == route) _alarmRoute = null;
    });
  }

  void _onTimerChanged() {
    if (!mounted) return;
    final timer = _services.timer;
    if (timer.status != TimerStatus.ringing) {
      _closeRoute(_timerRoute);
      _timerRoute = null;
      return;
    }
    if (_timerRoute != null) return;
    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RingScreen(
        kind: RingKind.timer,
        title: timer.label.isEmpty ? "Time's up!" : timer.label,
        primaryLabel: 'Stop',
        onPrimary: timer.dismiss,
        secondaryLabel: '+1 min',
        onSecondary: () => timer.addTime(const Duration(minutes: 1)),
      ),
    );
    _timerRoute = route;
    _services.currentTab.value = AppTab.timer;
    Navigator.of(context).push(route).then((_) {
      if (_timerRoute == route) _timerRoute = null;
    });
  }

  void _closeRoute(Route<void>? route) {
    if (route == null || !route.isActive) return;
    Navigator.of(context).removeRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: services.currentTab,
      builder: (context, index, _) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: index,
              children: <Widget>[
                for (var i = 0; i < _screens.length; i++)
                  TickerMode(enabled: i == index, child: _screens[i]),
              ],
            ),
          ),
          floatingActionButton: index == AppTab.alarm
              ? FloatingActionButton(
                  tooltip: 'Add alarm',
                  onPressed: () => addAlarm(context),
                  child: const Icon(Icons.add_rounded, size: 30),
                )
              : null,
          bottomNavigationBar: AnimatedBuilder(
            animation: Listenable.merge(
                <Listenable>[services.stopwatch, services.timer]),
            builder: (context, _) => NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) {
                services.settings.tick();
                services.currentTab.value = i;
              },
              destinations: <Widget>[
                const NavigationDestination(
                  icon: Icon(Icons.schedule_outlined),
                  selectedIcon: Icon(Icons.schedule_rounded),
                  label: 'Clock',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.alarm_outlined),
                  selectedIcon: Icon(Icons.alarm_rounded),
                  label: 'Alarm',
                ),
                NavigationDestination(
                  icon: _Dot(
                    show: services.stopwatch.isRunning,
                    child: const Icon(Icons.timer_outlined),
                  ),
                  selectedIcon: _Dot(
                    show: services.stopwatch.isRunning,
                    child: const Icon(Icons.timer_rounded),
                  ),
                  label: 'Stopwatch',
                ),
                NavigationDestination(
                  icon: _Dot(
                    show: services.timer.isActive,
                    child: const Icon(Icons.hourglass_empty_rounded),
                  ),
                  selectedIcon: _Dot(
                    show: services.timer.isActive,
                    child: const Icon(Icons.hourglass_bottom_rounded),
                  ),
                  label: 'Timer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small "running" indicator on a navigation icon.
class _Dot extends StatelessWidget {
  const _Dot({Key? key, required this.show, required this.child})
      : super(key: key);

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        if (show)
          Positioned(
            right: -3,
            top: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
