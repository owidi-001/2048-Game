import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tile.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class TileWidget extends StatefulWidget {
  final Tile tile;
  final double cellSize;

  const TileWidget({super.key, required this.tile, required this.cellSize});

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    if (widget.tile.isNew) {
      _controller.duration = kSpawnAnimationDuration;
      _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );
      _controller.forward();
    } else if (widget.tile.isMerged) {
      _controller.duration = kMergeAnimationDuration;
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward();
    } else {
      _controller.duration = Duration.zero;
      _scale = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tile.isMerged && !oldWidget.tile.isMerged) {
      _controller.duration = kMergeAnimationDuration;
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = tileRadius(widget.cellSize);
    final fontSize = tileFontSize(widget.cellSize, widget.tile.value);
    final bg = AppColors.tileColor(widget.tile.value);
    final fg = AppColors.tileForeground(widget.tile.value);

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [AppColors.tileShadow(widget.tile.value)],
        ),
        child: Center(
          child: Text(
            widget.tile.value.toString(),
            style: GoogleFonts.nunito(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: fg,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
