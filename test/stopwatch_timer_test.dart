import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerapp/services/notification_service.dart';
import 'package:timerapp/state/stopwatch_controller.dart';
import 'package:timerapp/state/timer_controller.dart';

void main() {
  late DateTime now;
  late SharedPreferences prefs;

  setUp(() async {
    now = DateTime(2026, 10, 29, 12);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  group('StopwatchController', () {
    test('measures, pauses and laps', () {
      final sw = StopwatchController(prefs, clock: () => now);
      expect(sw.isPristine, isTrue);
      sw.start();
      now = now.add(const Duration(seconds: 10));
      sw.lap();
      now = now.add(const Duration(seconds: 4));
      sw.lap();
      now = now.add(const Duration(seconds: 7));
      sw.lap();
      expect(sw.elapsed, const Duration(seconds: 21));
      expect(sw.laps.map((l) => l.number), <int>[3, 2, 1]);
      expect(sw.fastestLap, 2);
      expect(sw.slowestLap, 1);

      sw.pause();
      now = now.add(const Duration(minutes: 5));
      expect(sw.elapsed, const Duration(seconds: 21));
      sw.start();
      now = now.add(const Duration(seconds: 1));
      expect(sw.elapsed, const Duration(seconds: 22));
      expect(sw.currentLap, const Duration(seconds: 1));
    });

    test('survives a restart', () {
      final sw = StopwatchController(prefs, clock: () => now);
      sw.start();
      now = now.add(const Duration(seconds: 3));
      sw.lap();
      final restored = StopwatchController(prefs, clock: () => now);
      now = now.add(const Duration(seconds: 2));
      expect(restored.isRunning, isTrue);
      expect(restored.elapsed, const Duration(seconds: 5));
      expect(restored.laps.single.split, const Duration(seconds: 3));
      restored.reset();
      expect(restored.isPristine, isTrue);
    });
  });

  group('TimerController', () {
    test('counts down, pauses, finishes', () {
      final t = TimerController(prefs, NotificationService.disabled(),
          clock: () => now);
      t.start(const Duration(minutes: 1), label: 'Tea');
      expect(t.status, TimerStatus.running);
      now = now.add(const Duration(seconds: 15));
      expect(t.remaining, const Duration(seconds: 45));
      expect(t.progress, closeTo(0.75, 0.001));

      t.pause();
      now = now.add(const Duration(minutes: 10));
      expect(t.remaining, const Duration(seconds: 45));
      t.resume();
      now = now.add(const Duration(seconds: 45));
      t.checkFinished();
      expect(t.status, TimerStatus.ringing);

      t.addTime(const Duration(minutes: 1));
      expect(t.status, TimerStatus.running);
      expect(t.remaining, const Duration(minutes: 1));
      t.cancel();
      expect(t.status, TimerStatus.idle);
      expect(t.recent.first, const Duration(minutes: 1));
      expect(t.lastDuration, const Duration(minutes: 1));
      t.dispose();
    });

    test('restores a running timer and drops a finished one', () {
      final t = TimerController(prefs, NotificationService.disabled(),
          clock: () => now);
      t.start(const Duration(minutes: 5));
      now = now.add(const Duration(minutes: 2));
      final restored = TimerController(prefs, NotificationService.disabled(),
          clock: () => now);
      expect(restored.status, TimerStatus.running);
      expect(restored.remaining, const Duration(minutes: 3));
      now = now.add(const Duration(minutes: 5));
      final justDone = TimerController(prefs, NotificationService.disabled(),
          clock: () => now);
      expect(justDone.status, TimerStatus.ringing);
      now = now.add(const Duration(hours: 1));
      final later = TimerController(prefs, NotificationService.disabled(),
          clock: () => now);
      expect(later.status, TimerStatus.idle);
      t.dispose();
      restored.dispose();
      justDone.dispose();
      later.dispose();
    });
  });
}
