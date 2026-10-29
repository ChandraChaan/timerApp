import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../services/time_zone_service.dart';

/// A crisp analog clock face. With [smooth] the second hand sweeps
/// continuously; otherwise it ticks once per second.
class AnalogClock extends StatefulWidget {
  const AnalogClock({
    Key? key,
    required this.size,
    this.timeZone,
    this.smooth = true,
    this.showSeconds = true,
    this.compact = false,
  }) : super(key: key);

  final double size;

  /// IANA zone to display; null means the device's local time.
  final String? timeZone;
  final bool smooth;
  final bool showSeconds;

  /// Small variant for list rows: no numerals or minute ticks.
  final bool compact;

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<DateTime> _time = ValueNotifier<DateTime>(_read());
  late final Ticker _ticker;
  Timer? _timer;

  DateTime _read() {
    final zone = widget.timeZone;
    return zone == null ? DateTime.now() : TimeZoneService.nowIn(zone);
  }

  bool get _sweeping => widget.smooth && widget.showSeconds;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _time.value = _read());
    _configure();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.smooth != widget.smooth ||
        oldWidget.showSeconds != widget.showSeconds ||
        oldWidget.timeZone != widget.timeZone) {
      _configure();
    }
  }

  void _configure() {
    _timer?.cancel();
    if (_ticker.isActive) _ticker.stop();
    _time.value = _read();
    if (_sweeping) {
      _ticker.start();
    } else {
      _scheduleTick();
    }
  }

  void _scheduleTick() {
    final now = DateTime.now();
    _timer = Timer(Duration(milliseconds: 1000 - now.millisecond + 5), () {
      if (!mounted) return;
      _time.value = _read();
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      label: 'Analog clock',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _ClockPainter(
            time: _time,
            showSeconds: widget.showSeconds,
            compact: widget.compact,
            sweeping: _sweeping,
            face: scheme.surface,
            ink: scheme.onSurface,
            accent: scheme.primary,
            secondary: scheme.secondary,
            dark: dark,
          ),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.time,
    required this.showSeconds,
    required this.compact,
    required this.sweeping,
    required this.face,
    required this.ink,
    required this.accent,
    required this.secondary,
    required this.dark,
  }) : super(repaint: time);

  final ValueNotifier<DateTime> time;
  final bool showSeconds;
  final bool compact;
  final bool sweeping;
  final Color face;
  final Color ink;
  final Color accent;
  final Color secondary;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final now = time.value;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final night = now.hour < 6 || now.hour >= 18;

    // Face with a soft glow ring.
    final faceRect = Rect.fromCircle(center: center, radius: radius);
    if (compact) {
      final fill = night
          ? (dark ? const Color(0xFF0B0C10) : const Color(0xFF23252E))
          : (dark ? const Color(0xFF2A2C35) : const Color(0xFFFFFFFF));
      canvas.drawCircle(center, radius, Paint()..color = fill);
      canvas.drawCircle(
        center,
        radius - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink.withOpacity(0.12),
      );
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Color.lerp(face, accent, dark ? 0.06 : 0.03)!,
              face,
            ],
          ).createShader(faceRect),
      );
      canvas.drawCircle(
        center,
        radius - 1.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..shader = SweepGradient(
            colors: <Color>[
              accent.withOpacity(0.55),
              secondary.withOpacity(0.35),
              accent.withOpacity(0.55),
            ],
          ).createShader(faceRect),
      );
    }

    final handInk = compact && night ? Colors.white : ink;

    // Tick marks.
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      if (compact && !major) continue;
      final angle = i * math.pi / 30;
      final outer = radius * (compact ? 0.86 : 0.9);
      final length =
          compact ? radius * 0.1 : (major ? radius * 0.09 : radius * 0.04);
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = compact ? 1.2 : (major ? 3 : 1.4)
        ..color = handInk.withOpacity(major ? 0.75 : 0.25);
      canvas.drawLine(
        center + _polar(angle, outer - length),
        center + _polar(angle, outer),
        paint,
      );
    }

    // Numerals.
    if (!compact) {
      for (var n = 1; n <= 12; n++) {
        final quarter = n % 3 == 0;
        final painter = TextPainter(
          text: TextSpan(
            text: '$n',
            style: TextStyle(
              color: ink.withOpacity(quarter ? 0.9 : 0.45),
              fontSize: radius * (quarter ? 0.15 : 0.1),
              fontWeight: quarter ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = center + _polar(n * math.pi / 6, radius * 0.66);
        painter.paint(
            canvas, pos - Offset(painter.width / 2, painter.height / 2));
      }
    }

    final seconds = now.second + (sweeping ? now.millisecond / 1000 : 0);
    final minutes = now.minute + seconds / 60;
    final hours = (now.hour % 12) + minutes / 60;

    void hand(double angle, double length, double width, Color color,
        {double tail = 0}) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center - _polar(angle, tail),
        center + _polar(angle, length),
        paint,
      );
    }

    // Shadowed hour & minute hands.
    if (!compact) {
      final shadow = Colors.black.withOpacity(dark ? 0.35 : 0.12);
      canvas.save();
      canvas.translate(1.5, 2.5);
      hand(hours * math.pi / 6, radius * 0.48, radius * 0.06, shadow);
      hand(minutes * math.pi / 30, radius * 0.72, radius * 0.04, shadow);
      canvas.restore();
    }

    hand(hours * math.pi / 6, radius * (compact ? 0.45 : 0.48),
        radius * (compact ? 0.09 : 0.06), handInk);
    hand(minutes * math.pi / 30, radius * (compact ? 0.68 : 0.72),
        radius * (compact ? 0.06 : 0.04), handInk);

    if (showSeconds) {
      hand(seconds * math.pi / 30, radius * 0.82,
          compact ? 1.2 : radius * 0.016, accent,
          tail: radius * (compact ? 0.1 : 0.16));
    }

    canvas.drawCircle(center, radius * (compact ? 0.08 : 0.055),
        Paint()..color = showSeconds ? accent : handInk);
    if (!compact) {
      canvas.drawCircle(center, radius * 0.022, Paint()..color = face);
    }
  }

  static Offset _polar(double angle, double length) =>
      Offset(math.sin(angle) * length, -math.cos(angle) * length);

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.time != time ||
      old.showSeconds != showSeconds ||
      old.compact != compact ||
      old.sweeping != sweeping ||
      old.face != face ||
      old.ink != ink ||
      old.accent != accent ||
      old.secondary != secondary ||
      old.dark != dark;
}
