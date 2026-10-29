import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/alarm.dart';
import '../../state/app_services.dart';
import '../widgets/alarm_editor.dart';
import '../widgets/common.dart';
import '../widgets/ticking.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return AnimatedBuilder(
      animation:
          Listenable.merge(<Listenable>[services.alarms, services.settings]),
      builder: (context, _) {
        final alarms = services.alarms.alarms;
        return CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: ScreenHeader(title: 'Alarm')),
            const SliverToBoxAdapter(child: _NextAlarmSummary()),
            if (alarms.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.alarm_add_rounded,
                    title: 'No alarms yet',
                    message:
                        'Tap + to wake up on time. Alarms ring even when the app is closed.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _AlarmCard(
                      key: ValueKey<int>(alarms[i].id),
                      alarm: alarms[i],
                    ),
                    childCount: alarms.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Opens the editor to create a new alarm.
Future<void> addAlarm(BuildContext context) async {
  final services = AppScope.of(context);
  final now = DateTime.now().add(const Duration(minutes: 1));
  final result = await showAlarmEditor(
    context,
    initial: Alarm(
      id: -1,
      hour: now.hour,
      minute: now.minute,
      snoozeMinutes: services.settings.defaultSnooze,
    ),
    isNew: true,
  );
  if (result == null || result.deleted) return;
  final a = result.alarm;
  final created = services.alarms.create(
    hour: a.hour,
    minute: a.minute,
    label: a.label,
    days: a.days,
    vibrate: a.vibrate,
    snoozeMinutes: a.snoozeMinutes,
  );
  _announce(context, created);
}

void _announce(BuildContext context, Alarm alarm) {
  final services = AppScope.of(context);
  if (!alarm.enabled) return;
  final now = DateTime.now();
  final at = alarm.repeats
      ? alarm.nextOccurrence(now)
      : (alarm.oneShotAt ?? alarm.nextOccurrence(now));
  services.settings.tap();
  showAppSnack(context,
      'Alarm set for ${formatTimeUntil(at.difference(now)).substring(3)} from now');
}

class _NextAlarmSummary extends StatelessWidget {
  const _NextAlarmSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SecondTicker(
      builder: (context, now) {
        final next = services.alarms.nextRing;
        final title = next == null
            ? 'All alarms are off'
            : 'Rings ${formatTimeUntil(next.value.difference(now))}';
        final subtitle = next == null
            ? 'Turn one on or add a new alarm'
            : '${formatShortDate(next.value)} · '
                '${formatHourMinute(next.value.hour, next.value.minute, use24h: services.settings.use24h(context))}'
                '${services.settings.use24h(context) ? '' : ' ${amPm(next.value.hour)}'}'
                '${next.key.label.isEmpty ? '' : ' · ${next.key.label}'}';
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: next == null
                      ? scheme.onSurface.withOpacity(0.7)
                      : scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({Key? key, required this.alarm}) : super(key: key);

  final Alarm alarm;

  Future<void> _edit(BuildContext context) async {
    final services = AppScope.of(context);
    final result = await showAlarmEditor(context, initial: alarm);
    if (result == null) return;
    if (result.deleted) {
      _delete(context);
      return;
    }
    final updated = result.alarm.copyWith(enabled: true);
    services.alarms.update(updated);
    final stored = services.alarms.byId(updated.id);
    if (stored != null) _announce(context, stored);
  }

  void _delete(BuildContext context) {
    final services = AppScope.of(context);
    services.alarms.delete(alarm);
    services.settings.thud();
    showAppSnack(context, 'Alarm deleted',
        actionLabel: 'Undo', onAction: () => services.alarms.restore(alarm));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final use24h = services.settings.use24h(context);
    final on = alarm.enabled;
    final snoozed = services.alarms.snoozedUntil(alarm.id);
    final faded = scheme.onSurface.withOpacity(0.4);

    final details = <String>[
      if (alarm.label.isNotEmpty) alarm.label,
      describeRepeatDays(alarm.days),
      if (snoozed != null)
        'Snoozed until ${formatHourMinute(snoozed.hour, snoozed.minute, use24h: use24h)}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey<String>('alarm-dismiss-${alarm.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 28),
          decoration: BoxDecoration(
            color: scheme.error,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (_) => _delete(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: on
                  ? scheme.primary.withOpacity(0.35)
                  : scheme.onSurface.withOpacity(0.04),
            ),
            gradient: on
                ? LinearGradient(
                    colors: <Color>[
                      scheme.primary.withOpacity(0.12),
                      scheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _edit(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TimeLabel(
                            text: formatHourMinute(alarm.hour, alarm.minute,
                                use24h: use24h),
                            suffix: use24h ? null : amPm(alarm.hour),
                            fontSize: 46,
                            color: on ? scheme.onSurface : faded,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: on
                                  ? scheme.onSurface.withOpacity(0.7)
                                  : faded,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DayDots(days: alarm.days, active: on),
                        ],
                      ),
                    ),
                    Switch(
                      value: on,
                      onChanged: (v) {
                        services.settings.tick();
                        services.alarms.setEnabled(alarm, v);
                        if (v) {
                          final stored = services.alarms.byId(alarm.id);
                          if (stored != null) _announce(context, stored);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDots extends StatelessWidget {
  const _DayDots({Key? key, required this.days, required this.active})
      : super(key: key);

  final Set<int> days;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        for (var d = 1; d <= 7; d++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days.contains(d)
                    ? scheme.primary.withOpacity(active ? 0.9 : 0.3)
                    : scheme.onSurface.withOpacity(0.06),
              ),
              child: Text(
                kWeekdayShort[d - 1].substring(0, 1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: days.contains(d)
                      ? Colors.white
                      : scheme.onSurface.withOpacity(0.45),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
