import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/world_city.dart';
import '../../services/time_zone_service.dart';
import '../../state/app_services.dart';
import '../widgets/analog_clock.dart';
import '../widgets/common.dart';
import '../widgets/ticking.dart';
import 'city_picker_screen.dart';

class ClockScreen extends StatelessWidget {
  const ClockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        services.settings,
        services.worldClock,
      ]),
      builder: (context, _) {
        final cities = services.worldClock.cities;
        return CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: ScreenHeader(title: 'Clock')),
            const SliverToBoxAdapter(child: _LocalClockHero()),
            const SliverToBoxAdapter(child: _NextAlarmBanner()),
            SliverToBoxAdapter(
              child: SectionLabel(
                'World clock',
                trailing: TextButton.icon(
                  onPressed: () => openCityPicker(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add city'),
                ),
              ),
            ),
            if (cities.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.public_rounded,
                  title: 'Around the world',
                  message:
                      'Add cities to see their time at a glance and compare it with yours.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: SecondTicker(
                    builder: (context, now) => Column(
                      children: <Widget>[
                        for (var i = 0; i < cities.length; i++)
                          _CityTile(
                            key: ValueKey<String>(cities[i].key),
                            city: cities[i],
                            index: i,
                            count: cities.length,
                            now: now,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        );
      },
    );
  }
}

Future<void> openCityPicker(BuildContext context) async {
  final services = AppScope.of(context);
  final city = await Navigator.of(context).push<WorldCity>(
    MaterialPageRoute<WorldCity>(
      fullscreenDialog: true,
      builder: (_) => const CityPickerScreen(),
    ),
  );
  if (city == null) return;
  services.worldClock.add(city);
  services.settings.tap();
}

class _LocalClockHero extends StatelessWidget {
  const _LocalClockHero({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final scheme = Theme.of(context).colorScheme;
    final use24h = settings.use24h(context);
    final width = MediaQuery.of(context).size.width;
    final clockSize = math.min(width - 96, 290.0);

    return SecondTicker(
      builder: (context, now) {
        final hm = formatHourMinute(now.hour, now.minute, use24h: use24h);
        final seconds = settings.showSeconds ? ':${twoDigits(now.second)}' : '';
        final muted = scheme.onSurface.withOpacity(0.6);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Column(
            children: <Widget>[
              if (settings.analogClock) ...<Widget>[
                AnalogClock(
                  size: clockSize,
                  smooth: settings.smoothSeconds,
                  showSeconds: settings.showSeconds,
                ),
                const SizedBox(height: 28),
              ],
              TimeLabel(
                text: '$hm$seconds',
                suffix: use24h ? null : amPm(now.hour),
                fontSize: settings.analogClock ? 52 : 84,
                weight:
                    settings.analogClock ? FontWeight.w300 : FontWeight.w200,
              ),
              const SizedBox(height: 6),
              Text(
                formatLongDate(now),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${now.timeZoneName} · ${formatUtcOffset(now.timeZoneOffset)}',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextAlarmBanner extends StatelessWidget {
  const _NextAlarmBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: services.alarms,
      builder: (context, _) => SecondTicker(
        builder: (context, now) {
          final next = services.alarms.nextRing;
          if (next == null) return const SizedBox(height: 4);
          final at = next.value;
          final use24h = services.settings.use24h(context);
          final time = formatHourMinute(at.hour, at.minute, use24h: use24h);
          final day = _relativeDay(at, now);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => services.currentTab.value = AppTab.alarm,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.alarm_rounded, color: scheme.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Next alarm · $day $time'
                              '${use24h ? '' : ' ${amPm(at.hour)}'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              next.key.label.isEmpty
                                  ? formatTimeUntil(at.difference(now))
                                  : '${next.key.label} · ${formatTimeUntil(at.difference(now))}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: scheme.onSurface.withOpacity(0.4)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _relativeDay(DateTime at, DateTime now) {
  final a = DateTime(at.year, at.month, at.day);
  final b = DateTime(now.year, now.month, now.day);
  final days = (a.difference(b).inHours / 24).round();
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days == -1) return 'Yesterday';
  return kWeekdayShort[at.weekday - 1];
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    Key? key,
    required this.city,
    required this.index,
    required this.count,
    required this.now,
  }) : super(key: key);

  final WorldCity city;
  final int index;
  final int count;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final use24h = services.settings.use24h(context);
    final there = TimeZoneService.nowIn(city.timeZone, now);
    final diff =
        TimeZoneService.offsetOf(city.timeZone, now) - now.timeZoneOffset;
    final day = _relativeDay(there, now);
    final night = there.hour < 6 || there.hour >= 18;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey<String>('dismiss-${city.key}'),
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
        onDismissed: (_) {
          final removedAt = services.worldClock.remove(city);
          services.settings.thud();
          showAppSnack(context, '${city.name} removed',
              actionLabel: 'Undo',
              onAction: () => services.worldClock.insert(removedAt, city));
        },
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onLongPress: () => _showOptions(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
              child: Row(
                children: <Widget>[
                  AnalogClock(
                    size: 52,
                    timeZone: city.timeZone,
                    compact: true,
                    smooth: false,
                    showSeconds: false,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          city.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              night
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              size: 14,
                              color: night
                                  ? const Color(0xFF9DA8FF)
                                  : const Color(0xFFFFB020),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$day · ${formatOffsetDifference(diff)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: TimeLabel(
                        text: formatHourMinute(there.hour, there.minute,
                            use24h: use24h),
                        suffix: use24h ? null : amPm(there.hour),
                        fontSize: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final services = AppScope.of(context);
    services.settings.thud();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Text(city.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              '${city.country} · ${formatUtcOffset(TimeZoneService.offsetOf(city.timeZone))}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Move up'),
                onTap: () {
                  services.worldClock.move(index, index - 1);
                  Navigator.pop(sheetContext);
                },
              ),
            if (index < count - 1)
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: const Text('Move down'),
                onTap: () {
                  services.worldClock.move(index, index + 1);
                  Navigator.pop(sheetContext);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Remove'),
              onTap: () {
                Navigator.pop(sheetContext);
                final removedAt = services.worldClock.remove(city);
                showAppSnack(context, '${city.name} removed',
                    actionLabel: 'Undo',
                    onAction: () =>
                        services.worldClock.insert(removedAt, city));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
