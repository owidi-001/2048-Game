import 'package:flutter/material.dart';

import '../theme/game_theme.dart';
import '../theme/tokens.dart';

/// Filled accent button for the single most important action in a context.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: Space.sm),
        ],
        Text(label),
      ],
    );
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: g.accent,
        foregroundColor: g.onAccent,
        disabledBackgroundColor: g.surfaceRaised,
        disabledForegroundColor: g.textMuted,
        minimumSize: Size(expand ? double.infinity : 0, 52),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        textStyle: GameTypography.button(g.onAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      child: child,
    );
  }
}

/// Tonal button for secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: g.surfaceRaised,
        foregroundColor: g.textPrimary,
        disabledBackgroundColor: g.surface,
        disabledForegroundColor: g.textMuted,
        minimumSize: Size(expand ? double.infinity : 0, 48),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        textStyle: GameTypography.button(g.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: g.outline),
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: Space.sm),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// Compact icon + label control used in the action bar. Equal-width when
/// placed in a Row via [Expanded] by the caller.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasis = false,
    this.badge,
    this.tooltip,
    this.horizontal = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Accent-coloured icon for the primary action.
  final bool emphasis;

  /// Small counter rendered next to the icon (e.g. remaining undos).
  final int? badge;
  final String? tooltip;

  /// Icon and label side by side, full width (sidebar layout).
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final enabled = onPressed != null;
    final fg = !enabled
        ? g.textMuted.withValues(alpha: 0.55)
        : emphasis
        ? g.accent
        : g.textPrimary;

    Widget button = Material(
      color: g.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: g.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: horizontal ? 52 : 56),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal ? Space.lg : Space.sm,
              vertical: Space.sm,
            ),
            child: horizontal
                ? Row(
                    children: [
                      Icon(icon, size: 22, color: fg),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameTypography.bodyStrong(
                            enabled ? g.textPrimary : fg,
                          ),
                        ),
                      ),
                      if (badge != null && enabled) _Badge(count: badge!),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 22, color: fg),
                          if (badge != null && enabled) ...[
                            const SizedBox(width: 4),
                            _Badge(count: badge!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Shrink rather than truncate at large text scales.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: GameTypography.caption(
                            enabled ? g.textSecondary : fg,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: button,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: g.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: g.outline),
      ),
      child: Text(
        '$count',
        style: GameTypography.caption(g.textSecondary).copyWith(fontSize: 10),
      ),
    );
  }
}
