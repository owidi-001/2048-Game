import 'package:flutter/material.dart';

import '../models/tile.dart';
import '../theme/game_theme.dart';
import '../theme/tokens.dart';
import '../utils/constants.dart';

/// A single numbered tile. Handles its own spawn (scale-in) and merge (pop)
/// animations; position is animated by the board.
class TileWidget extends StatefulWidget {
  const TileWidget({super.key, required this.tile, required this.cellSize});

  final Tile tile;
  final double cellSize;

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Animation<double> _scale = const AlwaysStoppedAnimation(1.0);
  bool _configured = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;
    final motion = Motion.of(context);
    if (widget.tile.isNew) {
      _playSpawn(motion);
    } else if (widget.tile.isMerged) {
      _playMerge(motion);
    }
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tile.isMerged && !oldWidget.tile.isMerged) {
      _playMerge(Motion.of(context));
    } else if (widget.tile.isNew && !oldWidget.tile.isNew) {
      _playSpawn(Motion.of(context));
    }
  }

  void _playSpawn(Motion motion) {
    if (motion.tileSpawn == Duration.zero) return;
    _controller.duration = motion.tileSpawn;
    _scale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.spawn));
    _controller
      ..reset()
      ..forward();
  }

  void _playMerge(Motion motion) {
    if (motion.tileMerge == Duration.zero) return;
    _controller.duration = motion.tileMerge;
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.gameTheme.tiles.of(widget.tile.value);
    final radius = tileRadius(widget.cellSize);
    final fontSize = tileFontSize(widget.cellSize, widget.tile.value);
    final ring = style.ring;

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(radius),
            border: ring != null
                ? Border.all(
                    color: ring,
                    width: (widget.cellSize * 0.045).clamp(1.5, 3.0),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0x66000000),
                blurRadius: widget.cellSize * 0.12,
                offset: Offset(0, widget.cellSize * 0.04),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.cellSize * 0.06,
                ),
                child: Text(
                  widget.tile.value.toString(),
                  maxLines: 1,
                  style: GameTypography.tile(fontSize, style.foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
