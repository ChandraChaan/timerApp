import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// One scrolling column of a wheel picker (hours, minutes, ...).
class WheelColumn extends StatefulWidget {
  const WheelColumn({
    Key? key,
    required this.itemCount,
    required this.initialItem,
    required this.onChanged,
    required this.labelBuilder,
    this.looping = true,
    this.width = 84,
    this.itemExtent = 64,
    this.fontSize = 44,
    this.haptics = true,
    this.controller,
  }) : super(key: key);

  final int itemCount;
  final int initialItem;
  final ValueChanged<int> onChanged;
  final String Function(int index) labelBuilder;
  final bool looping;
  final double width;
  final double itemExtent;
  final double fontSize;
  final bool haptics;

  /// Optional external controller (lets a parent jump the wheel, e.g. when a
  /// preset is tapped).
  final FixedExtentScrollController? controller;

  @override
  State<WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<WheelColumn> {
  late final FixedExtentScrollController _ownController =
      FixedExtentScrollController(initialItem: widget.initialItem);
  late int _selected = widget.initialItem;

  FixedExtentScrollController get _controller =>
      widget.controller ?? _ownController;

  @override
  void dispose() {
    _ownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(int index) {
      final selected = index == _selected;
      return Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w300,
            color: selected
                ? scheme.onSurface
                : scheme.onSurface.withOpacity(0.35),
            fontFeatures: kTabularFigures,
          ),
          child: Text(widget.labelBuilder(index)),
        ),
      );
    }

    final children = List<Widget>.generate(widget.itemCount, (i) => item(i));
    return SizedBox(
      width: widget.width,
      height: widget.itemExtent * 3.4,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: widget.itemExtent,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.6,
        perspective: 0.004,
        overAndUnderCenterOpacity: 0.85,
        onSelectedItemChanged: (raw) {
          final index = raw % widget.itemCount;
          if (widget.haptics) HapticFeedback.selectionClick();
          setState(() => _selected = index);
          widget.onChanged(index);
        },
        childDelegate: widget.looping
            ? ListWheelChildLoopingListDelegate(children: children)
            : ListWheelChildListDelegate(children: children),
      ),
    );
  }
}

/// Rounded highlight band drawn behind the wheel columns' selected row.
class WheelFrame extends StatelessWidget {
  const WheelFrame({Key? key, required this.child, this.itemExtent = 64})
      : super(key: key);

  final Widget child;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          height: itemExtent,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withOpacity(0.25)),
          ),
        ),
        child,
      ],
    );
  }
}

/// Small static separator/label used between wheel columns (":" or "h").
class WheelSeparator extends StatelessWidget {
  const WheelSeparator(this.text, {Key? key, this.fontSize = 40})
      : super(key: key);

  static const double width = 24;

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
