import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds exactly on every wall-clock second boundary.
class SecondTicker extends StatefulWidget {
  const SecondTicker({Key? key, required this.builder}) : super(key: key);

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<SecondTicker> createState() => _SecondTickerState();
}

class _SecondTickerState extends State<SecondTicker> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final now = DateTime.now();
    final delay = Duration(milliseconds: 1000 - now.millisecond + 5);
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

/// Rebuilds on every frame while [active] (for smooth running displays).
/// Uses a [Ticker], so it pauses automatically inside a disabled [TickerMode].
class FrameTicker extends StatefulWidget {
  const FrameTicker({Key? key, required this.active, required this.builder})
      : super(key: key);

  final bool active;
  final WidgetBuilder builder;

  @override
  State<FrameTicker> createState() => _FrameTickerState();
}

class _FrameTickerState extends State<FrameTicker>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}));
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(FrameTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ticker.isActive) _ticker.start();
    if (!widget.active && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
