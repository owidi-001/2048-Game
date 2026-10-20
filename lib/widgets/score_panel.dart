import 'package:flutter/material.dart';

import '../theme/game_theme.dart';
import '../theme/tokens.dart';

/// Score and best score in one compact card.
///
/// * The score counts up to its new value and a "+N" chip floats away on
///   every merge (driven by [gainTick]).
/// * When the running game is above the best it started against, the best
///   value turns accent-coloured with a trophy. This is a quiet live cue; the
///   celebratory "New record" announcement belongs to the game-over overlay.
class ScorePanel extends StatefulWidget {
  const ScorePanel({
    super.key,
    required this.score,
    required this.best,
    required this.isBeatingRecord,
    required this.gainTick,
    required this.lastGain,
    this.vertical = false,
  });

  final int score;
  final int best;
  final bool isBeatingRecord;
  final int gainTick;
  final int lastGain;

  /// Stack the two stats (used in the wide sidebar layout).
  final bool vertical;

  @override
  State<ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<ScorePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _delta = AnimationController(vsync: this);
  int _seenTick = 0;
  int _shownGain = 0;

  @override
  void initState() {
    super.initState();
    _seenTick = widget.gainTick;
  }

  @override
  void didUpdateWidget(ScorePanel old) {
    super.didUpdateWidget(old);
    if (widget.gainTick != _seenTick && widget.lastGain > 0) {
      _seenTick = widget.gainTick;
      _shownGain = widget.lastGain;
      final motion = Motion.of(context);
      if (motion.scoreDelta > Duration.zero) {
        _delta
          ..duration = motion.scoreDelta
          ..forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _delta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    final motion = Motion.of(context);

    final scoreStat = _Stat(
      label: 'SCORE',
      valueStyle: GameTypography.scoreLarge(g.textPrimary),
      value: widget.score,
      duration: motion.ui,
      trailing: null,
      overlay: AnimatedBuilder(
        animation: _delta,
        builder: (context, _) {
          if (_delta.isDismissed || _delta.value >= 1) {
            return const SizedBox.shrink();
          }
          final t = Curves.easeOut.transform(_delta.value);
          return Opacity(
            opacity: (1 - t).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -18 * t),
              child: Text(
                '+$_shownGain',
                style: GameTypography.scoreSmall(g.success),
              ),
            ),
          );
        },
      ),
    );

    final bestStat = _Stat(
      label: 'BEST',
      valueStyle: GameTypography.scoreSmall(
        widget.isBeatingRecord ? g.accent : g.textSecondary,
      ),
      value: widget.best,
      duration: motion.ui,
      trailing: widget.isBeatingRecord
          ? Icon(Icons.emoji_events_rounded, size: 14, color: g.accent)
          : null,
      overlay: null,
    );

    final divider = widget.vertical
        ? Divider(color: g.outline, height: Space.lg)
        : VerticalDivider(color: g.outline, width: Space.lg);

    return Semantics(
      container: true,
      liveRegion: true,
      label:
          'Score ${widget.score}. Best ${widget.best}.'
          '${widget.isBeatingRecord ? ' Beating your best.' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        decoration: BoxDecoration(
          color: g.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: g.outline),
        ),
        child: widget.vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [scoreStat, divider, bestStat],
              )
            : IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [scoreStat, divider, bestStat],
                ),
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.duration,
    required this.trailing,
    required this.overlay,
  });

  final String label;
  final int value;
  final TextStyle valueStyle;
  final Duration duration;
  final Widget? trailing;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final g = context.gameTheme;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GameTypography.label(g.textMuted)),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
          const SizedBox(height: 5),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: value, end: value),
                duration: duration,
                builder: (context, v, _) => Text('$v', style: valueStyle),
              ),
              if (overlay != null)
                Positioned(right: -4, top: -6, child: overlay!),
            ],
          ),
        ],
      ),
    );
  }
}
