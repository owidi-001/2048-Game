import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ScoreCardWidget extends StatefulWidget {
  final String label;
  final int score;
  final bool highlight;

  const ScoreCardWidget({
    super.key,
    required this.label,
    required this.score,
    this.highlight = false,
  });

  @override
  State<ScoreCardWidget> createState() => _ScoreCardWidgetState();
}

class _ScoreCardWidgetState extends State<ScoreCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;
  int _displayed = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.score;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ScoreCardWidget old) {
    super.didUpdateWidget(old);
    if (widget.score != _displayed) {
      setState(() => _displayed = widget.score);
    }
    if (widget.highlight && !old.highlight) {
      _shakeController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _shakeAnim.value),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.scoreCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.scoreLabel,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _displayed.toString(),
                key: ValueKey(_displayed),
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.scoreValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
