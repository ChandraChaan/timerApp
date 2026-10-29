import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_services.dart';
import '../../state/timer_controller.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';
import '../widgets/ticking.dart';
import '../widgets/wheel_picker.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timer = AppScope.of(context).timer;
    return AnimatedBuilder(
      animation: timer,
      builder: (context, _) {
        return CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: ScreenHeader(title: 'Timer')),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.96, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: timer.isActive
                    ? const _RunningTimer(key: ValueKey<String>('running'))
                    : const _TimerSetup(key: ValueKey<String>('setup')),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

class _TimerSetup extends StatefulWidget {
  const _TimerSetup({Key? key}) : super(key: key);

  @override
  State<_TimerSetup> createState() => _TimerSetupState();
}

class _TimerSetupState extends State<_TimerSetup> {
  late int _h;
  late int _m;
  late int _s;
  late final FixedExtentScrollController _hc;
  late final FixedExtentScrollController _mc;
  late final FixedExtentScrollController _sc;
  final TextEditingController _label = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final last = AppScope.of(context).timer.lastDuration;
    _h = last.inHours.clamp(0, 23);
    _m = last.inMinutes.remainder(60);
    _s = last.inSeconds.remainder(60);
    _hc = FixedExtentScrollController(initialItem: _h);
    _mc = FixedExtentScrollController(initialItem: _m);
    _sc = FixedExtentScrollController(initialItem: _s);
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    _sc.dispose();
    _label.dispose();
    super.dispose();
  }

  Duration get _duration => Duration(hours: _h, minutes: _m, seconds: _s);

  void _start(Duration d) {
    final services = AppScope.of(context);
    services.settings.thud();
    services.timer.start(d, label: _label.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final scheme = Theme.of(context).colorScheme;
    final recent = services.timer.recent;

    Widget column(int count, int value, FixedExtentScrollController c,
        ValueChanged<int> onChanged) {
      return WheelColumn(
        controller: c,
        itemCount: count,
        initialItem: value,
        width: 90,
        haptics: settings.haptics,
        labelBuilder: (i) => twoDigits(i),
        onChanged: (i) => setState(() => onChanged(i)),
      );
    }

    Widget caption(String text) => SizedBox(
          width: 90,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ),
        );

    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        WheelFrame(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              column(24, _h, _hc, (i) => _h = i),
              const WheelSeparator(':'),
              column(60, _m, _mc, (i) => _m = i),
              const WheelSeparator(':'),
              column(60, _s, _sc, (i) => _s = i),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            caption('HOURS'),
            const SizedBox(width: WheelSeparator.width),
            caption('MIN'),
            const SizedBox(width: WheelSeparator.width),
            caption('SEC'),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _label,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Label (optional)',
              prefixIcon: Icon(Icons.label_outline_rounded),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 20),
        CircleActionButton(
          primary: true,
          size: 88,
          icon: Icons.play_arrow_rounded,
          label: 'Start',
          onPressed: _duration > Duration.zero ? () => _start(_duration) : null,
        ),
        if (recent.isNotEmpty) ...<Widget>[
          const SectionLabel('Recent'),
          _chips(recent, Icons.history_rounded),
        ],
        const SectionLabel('Quick start'),
        _chips(TimerController.presets, Icons.bolt_rounded),
      ],
    );
  }

  Widget _chips(List<Duration> durations, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final d in durations)
              Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _start(d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(icon, size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          formatDurationWords(d),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RunningTimer extends StatelessWidget {
  const _RunningTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final timer = services.timer;
    final settings = services.settings;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final dial = math.min(size.width - 56, math.min(size.height * 0.45, 340.0));
    final running = timer.status == TimerStatus.running;
    final use24h = settings.use24h(context);

    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        FrameTicker(
          active: running,
          builder: (context) {
            final endAt = timer.endAt;
            return ProgressRing(
              size: dial,
              strokeWidth: 16,
              showTicks: false,
              progress: timer.progress,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (timer.label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        timer.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        formatCountdown(timer.remaining),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1.5,
                          fontFeatures: kTabularFigures,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (endAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.notifications_active_outlined,
                            size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          formatHourMinute(endAt.hour, endAt.minute,
                                  use24h: use24h) +
                              (use24h ? '' : ' ${amPm(endAt.hour)}'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      timer.status == TimerStatus.ringing
                          ? "Time's up"
                          : 'Paused',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'of ${formatDurationWords(timer.total)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              CircleActionButton(
                icon: Icons.close_rounded,
                label: 'Cancel',
                onPressed: () {
                  settings.tap();
                  timer.cancel();
                },
              ),
              CircleActionButton(
                primary: true,
                size: 88,
                icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                label: running ? 'Pause' : 'Resume',
                color: running ? const Color(0xFFFF7A59) : null,
                onPressed: timer.status == TimerStatus.ringing
                    ? null
                    : () {
                        settings.thud();
                        timer.toggle();
                      },
              ),
              CircleActionButton(
                icon: Icons.more_time_rounded,
                label: 'Add 1 minute',
                onPressed: () {
                  settings.tap();
                  timer.addTime(const Duration(minutes: 1));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
