import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_services.dart';
import '../widgets/ticking.dart';

enum RingKind { alarm, timer }

/// Full-screen "it's ringing" page for alarms and finished timers. Pulses,
/// vibrates and plays the system alert until the user acts.
class RingScreen extends StatefulWidget {
  const RingScreen({
    Key? key,
    required this.kind,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.vibrate = true,
  }) : super(key: key);

  final RingKind kind;
  final String title;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final bool vibrate;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  Timer? _buzz;

  @override
  void initState() {
    super.initState();
    _alert();
    _buzz = Timer.periodic(const Duration(milliseconds: 1600), (_) => _alert());
  }

  void _alert() {
    SystemSound.play(SystemSoundType.alert);
    if (widget.vibrate) HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _buzz?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _act(VoidCallback action) {
    _buzz?.cancel();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final scheme = Theme.of(context).colorScheme;
    final use24h = settings.use24h(context);
    final icon = widget.kind == RingKind.alarm
        ? Icons.alarm_rounded
        : Icons.hourglass_bottom_rounded;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color.lerp(scheme.background, scheme.primary, 0.35)!,
                scheme.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                SecondTicker(
                  builder: (context, now) => Column(
                    children: <Widget>[
                      Text(
                        formatHourMinute(now.hour, now.minute, use24h: use24h) +
                            (use24h ? '' : ' ${amPm(now.hour)}'),
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -2,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                      Text(
                        formatLongDate(now),
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = _pulse.value;
                    final wobble =
                        math.sin(t * math.pi * 8) * 0.12 * (t < 0.35 ? 1 : 0);
                    return SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          for (final offset in <double>[0, 0.5])
                            Opacity(
                              opacity: (1 - ((t + offset) % 1)) * 0.5,
                              child: Container(
                                width: 110 + 110 * ((t + offset) % 1),
                                height: 110 + 110 * ((t + offset) % 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withOpacity(0.35),
                                ),
                              ),
                            ),
                          Transform.rotate(angle: wobble, child: child),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[scheme.primary, scheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(icon, size: 56, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _RingButton(
                          label: widget.secondaryLabel,
                          filled: false,
                          onTap: () => _act(widget.onSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _RingButton(
                          label: widget.primaryLabel,
                          filled: true,
                          onTap: () => _act(widget.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  const _RingButton({
    Key? key,
    required this.label,
    required this.filled,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.primary : scheme.onSurface.withOpacity(0.1),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
