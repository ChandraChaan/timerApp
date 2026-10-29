import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerapp/models/alarm.dart';
import 'package:timerapp/services/notification_service.dart';
import 'package:timerapp/state/alarm_controller.dart';
import 'package:timerapp/state/settings_controller.dart';

void main() {
  // Thursday 29 October 2026, 08:00.
  final thursday8am = DateTime(2026, 10, 29, 8);

  group('Alarm.nextOccurrence', () {
    test('one-shot later today', () {
      const alarm = Alarm(id: 1, hour: 9, minute: 15);
      expect(alarm.nextOccurrence(thursday8am), DateTime(2026, 10, 29, 9, 15));
    });

    test('one-shot already passed rolls to tomorrow', () {
      const alarm = Alarm(id: 1, hour: 7, minute: 0);
      expect(alarm.nextOccurrence(thursday8am), DateTime(2026, 10, 30, 7));
    });

    test('exactly now is not "next"', () {
      const alarm = Alarm(id: 1, hour: 8, minute: 0);
      expect(alarm.nextOccurrence(thursday8am), DateTime(2026, 10, 30, 8));
    });

    test('repeating picks the next matching weekday', () {
      const weekend = Alarm(id: 1, hour: 10, minute: 0, days: <int>{6, 7});
      expect(weekend.nextOccurrence(thursday8am), DateTime(2026, 10, 31, 10));
      const thursday = Alarm(id: 2, hour: 7, minute: 0, days: <int>{4});
      expect(thursday.nextOccurrence(thursday8am), DateTime(2026, 11, 5, 7));
    });
  });

  test('json round trip', () {
    final alarm = Alarm(
      id: 7,
      hour: 6,
      minute: 45,
      label: 'Gym',
      days: const <int>{1, 3, 5},
      vibrate: false,
      snoozeMinutes: 5,
      oneShotAt: DateTime(2026, 1, 1, 6, 45),
    );
    final decoded = Alarm.decodeList(Alarm.encodeList(<Alarm>[alarm])).single;
    expect(decoded.id, 7);
    expect(decoded.label, 'Gym');
    expect(decoded.days, <int>{1, 3, 5});
    expect(decoded.vibrate, isFalse);
    expect(decoded.snoozeMinutes, 5);
    expect(decoded.oneShotAt, DateTime(2026, 1, 1, 6, 45));
    expect(Alarm.decodeList('not json'), isEmpty);
  });

  group('AlarmController', () {
    late DateTime now;
    late SharedPreferences prefs;

    Future<AlarmController> build() async {
      final settings = SettingsController(prefs);
      return AlarmController(prefs, NotificationService.disabled(), settings,
          clock: () => now);
    }

    setUp(() async {
      now = thursday8am;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('create, sort, persist and compute next ring', () async {
      final c = await build();
      c.create(hour: 9, minute: 0);
      c.create(hour: 7, minute: 30, days: <int>{6});
      expect(c.alarms.map((a) => a.hour), <int>[7, 9]);
      expect(c.nextRing!.value, DateTime(2026, 10, 29, 9));

      final reloaded = await build();
      expect(reloaded.alarms.length, 2);
      expect(reloaded.alarms.first.days, <int>{6});
    });

    test('rings when due, one-shot switches off after dismiss', () async {
      final c = await build();
      final alarm = c.create(hour: 8, minute: 1);
      now = DateTime(2026, 10, 29, 8, 1, 2);
      c.checkDue();
      expect(c.ringing.value?.id, alarm.id);
      c.dismiss();
      expect(c.ringing.value, isNull);
      expect(c.byId(alarm.id)!.enabled, isFalse);
      // Does not ring again within the same minute.
      c.checkDue();
      expect(c.ringing.value, isNull);
    });

    test('repeating alarm only rings on its days', () async {
      final c = await build();
      c.create(hour: 8, minute: 1, days: <int>{5}); // Fridays
      now = DateTime(2026, 10, 29, 8, 1);
      c.checkDue();
      expect(c.ringing.value, isNull);
      now = DateTime(2026, 10, 30, 8, 1);
      c.checkDue();
      expect(c.ringing.value, isNotNull);
      c.dismiss();
      expect(c.alarms.single.enabled, isTrue);
    });

    test('snooze rings again later', () async {
      final c = await build();
      final alarm = c.create(hour: 8, minute: 1, snoozeMinutes: 5);
      now = DateTime(2026, 10, 29, 8, 1);
      c.checkDue();
      c.snooze();
      expect(c.ringing.value, isNull);
      expect(c.snoozedUntil(alarm.id), DateTime(2026, 10, 29, 8, 6));
      expect(c.nextRing!.value, DateTime(2026, 10, 29, 8, 6));
      now = DateTime(2026, 10, 29, 8, 6);
      c.checkDue();
      expect(c.ringing.value?.id, alarm.id);
    });

    test('expired one-shot alarms are switched off on load', () async {
      final c = await build();
      c.create(hour: 9, minute: 0);
      now = DateTime(2026, 10, 29, 12);
      final reloaded = await build();
      expect(reloaded.alarms.single.enabled, isFalse);
    });

    test('notification tap opens ring screen only near ring time', () async {
      final c = await build();
      final alarm = c.create(hour: 8, minute: 30);
      now = DateTime(2026, 10, 29, 8, 40);
      c.ringFromNotification('$kAlarmPayloadPrefix${alarm.id}');
      expect(c.ringing.value?.id, alarm.id);
      c.dismiss();
      now = DateTime(2026, 10, 29, 11);
      c.ringFromNotification('$kAlarmPayloadPrefix${alarm.id}');
      expect(c.ringing.value, isNull);
    });

    test('delete and restore', () async {
      final c = await build();
      final alarm = c.create(hour: 6, minute: 0);
      c.delete(alarm);
      expect(c.alarms, isEmpty);
      c.restore(alarm);
      expect(c.alarms.single.id, alarm.id);
    });
  });
}
