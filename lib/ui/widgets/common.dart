import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../screens/settings_screen.dart';

/// Large page title with a settings shortcut, used at the top of each tab.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({Key? key, required this.title, this.actions})
      : super(key: key);

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          ...?actions,
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {Key? key, this.trailing}) : super(key: key);

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: scheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Big round button used for start / pause / lap actions.
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.size = 72,
    this.color,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final base = color ?? scheme.primary;
    final background =
        primary ? base : scheme.onSurface.withOpacity(enabled ? 0.08 : 0.04);
    final foreground = primary
        ? Colors.white
        : scheme.onSurface.withOpacity(enabled ? 0.9 : 0.3);
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.6,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: primary && enabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: base.withOpacity(0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: background,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(icon,
                        key: ValueKey<IconData>(icon),
                        color: foreground,
                        size: size * 0.42),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped button with text, for secondary actions.
class PillButton extends StatelessWidget {
  const PillButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
    this.color,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = color ?? scheme.primary;
    final fg = filled ? Colors.white : base;
    return Material(
      color: filled ? base : base.withOpacity(0.12),
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  scheme.primary.withOpacity(0.25),
                  scheme.secondary.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, size: 44, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hour:minute text with a smaller AM/PM suffix in 12-hour mode.
class TimeLabel extends StatelessWidget {
  const TimeLabel({
    Key? key,
    required this.text,
    this.suffix,
    this.fontSize = 40,
    this.weight = FontWeight.w300,
    this.color,
  }) : super(key: key);

  final String text;
  final String? suffix;
  final double fontSize;
  final FontWeight weight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.onSurface;
    return RichText(
      textScaleFactor: MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.3),
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: base,
          letterSpacing: -fontSize * 0.02,
          fontFeatures: kTabularFigures,
        ),
        children: <InlineSpan>[
          TextSpan(text: text),
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: TextStyle(
                fontSize: fontSize * 0.36,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: base.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message,
    {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}
