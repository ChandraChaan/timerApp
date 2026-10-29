import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress ring with a gradient arc, a glowing head and optional
/// dial ticks. [progress] goes from 0 to 1.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    Key? key,
    required this.progress,
    required this.size,
    this.strokeWidth = 14,
    this.showTicks = true,
    this.child,
  }) : super(key: key);

  final double progress;
  final double size;
  final double strokeWidth;
  final bool showTicks;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          track: scheme.onSurface.withOpacity(0.07),
          tick: scheme.onSurface.withOpacity(0.18),
          start: scheme.primary,
          end: scheme.secondary,
          showTicks: showTicks,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.track,
    required this.tick,
    required this.start,
    required this.end,
    required this.showTicks,
  });

  final double progress;
  final double strokeWidth;
  final Color track;
  final Color tick;
  final Color start;
  final Color end;
  final bool showTicks;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - strokeWidth / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = track,
    );

    if (showTicks) {
      final inner = radius - strokeWidth / 2 - 10;
      for (var i = 0; i < 60; i++) {
        final major = i % 5 == 0;
        final angle = i * math.pi / 30;
        final dir = Offset(math.sin(angle), -math.cos(angle));
        canvas.drawLine(
          center + dir * (inner - (major ? 10 : 5)),
          center + dir * inner,
          Paint()
            ..strokeWidth = major ? 2 : 1
            ..strokeCap = StrokeCap.round
            ..color = major ? tick : tick.withOpacity(tick.opacity * 0.5),
        );
      }
    }

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: <Color>[start, end, start],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);

    // Glowing head at the end of the arc.
    final headAngle = -math.pi / 2 + sweep;
    final head =
        center + Offset(math.cos(headAngle), math.sin(headAngle)) * radius;
    final headColor = Color.lerp(start, end, progress)!;
    canvas.drawCircle(
      head,
      strokeWidth * 0.95,
      Paint()
        ..color = headColor.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(head, strokeWidth * 0.32, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.track != track ||
      old.tick != tick ||
      old.start != start ||
      old.end != end ||
      old.showTicks != showTicks;
}
