import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_services.dart';
import '../../state/stopwatch_controller.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';
import '../widgets/ticking.dart';

class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final sw = services.stopwatch;
    final settings = services.settings;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final dial = math.min(size.width - 72, math.min(size.height * 0.4, 320.0));

    return AnimatedBuilder(
      animation: sw,
      builder: (context, _) {
        final laps = sw.laps;
        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: 'Stopwatch',
                actions: <Widget>[
                  if (laps.isNotEmpty)
                    IconButton(
                      tooltip: 'Copy laps',
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: sw.exportText(formatStopwatch)));
                        settings.tap();
                        showAppSnack(context, 'Laps copied to clipboard');
                      },
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: FrameTicker(
                    active: sw.isRunning,
                    builder: (context) {
                      final elapsed = sw.elapsed;
                      final secondsFraction =
                          (elapsed.inMilliseconds % 60000) / 60000;
                      return ProgressRing(
                        size: dial,
                        strokeWidth: 10,
                        progress: sw.isPristine ? 0 : secondsFraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            FittedBox(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 36),
                                child: Text(
                                  formatStopwatch(elapsed),
                                  style: TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -1,
                                    color: scheme.onSurface,
                                    fontFeatures: kTabularFigures,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: laps.isEmpty ? 0 : 1,
                              child: Text(
                                'Lap ${laps.length + 1} · ${formatStopwatch(sw.currentLap)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: scheme.onSurface.withOpacity(0.6),
                                  fontFeatures: kTabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    CircleActionButton(
                      icon: sw.isRunning
                          ? Icons.flag_rounded
                          : Icons.restart_alt_rounded,
                      label: sw.isRunning ? 'Lap' : 'Reset',
                      onPressed: sw.isPristine
                          ? null
                          : () {
                              settings.tap();
                              sw.isRunning ? sw.lap() : sw.reset();
                            },
                    ),
                    CircleActionButton(
                      primary: true,
                      size: 88,
                      icon: sw.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      label: sw.isRunning ? 'Pause' : 'Start',
                      color: sw.isRunning ? const Color(0xFFFF7A59) : null,
                      onPressed: () {
                        settings.thud();
                        sw.toggle();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (laps.isNotEmpty) ...<Widget>[
              const SliverToBoxAdapter(child: SectionLabel('Laps')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _LapRow(
                      lap: laps[i],
                      fastest: sw.fastestLap == laps[i].number,
                      slowest: sw.slowestLap == laps[i].number,
                    ),
                    childCount: laps.length,
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({
    Key? key,
    required this.lap,
    required this.fastest,
    required this.slowest,
  }) : super(key: key);

  final Lap lap;
  final bool fastest;
  final bool slowest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const good = Color(0xFF2BD38A);
    const bad = Color(0xFFFF6B6B);
    final accent = fastest ? good : (slowest ? bad : null);
    final style = TextStyle(
      fontSize: 16,
      fontFeatures: kTabularFigures,
      color: accent ?? scheme.onSurface,
      fontWeight: accent != null ? FontWeight.w600 : FontWeight.w400,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: accent?.withOpacity(0.08) ?? scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 70,
            child: Text('Lap ${lap.number}', style: style),
          ),
          if (accent != null)
            Icon(
              fastest ? Icons.bolt_rounded : Icons.hourglass_bottom_rounded,
              size: 16,
              color: accent,
            ),
          const Spacer(),
          Text('+${formatStopwatch(lap.split)}', style: style),
          const SizedBox(width: 18),
          Text(
            formatStopwatch(lap.total),
            style: style.copyWith(
              color: scheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
