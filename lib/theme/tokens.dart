import 'package:flutter/widgets.dart';

/// Spacing scale (4-pt grid). Use these instead of ad-hoc numbers.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner radii.
abstract final class Radii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double sheet = 28;
}

/// Motion durations and curves. Read through [Motion.of] so that reduced-motion
/// preferences collapse every duration to zero.
class Motion {
  const Motion._(this.scale);

  final double scale;

  static const Motion full = Motion._(1);
  static const Motion none = Motion._(0);

  static Motion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? none : full;

  Duration _d(int ms) => Duration(milliseconds: (ms * scale).round());

  Duration get tileSlide => _d(110);
  Duration get tileSpawn => _d(170);
  Duration get tileMerge => _d(180);
  Duration get ui => _d(200);
  Duration get overlay => _d(260);
  Duration get scoreDelta => _d(700);
  Duration get nudge => _d(180);

  /// How long the provider keeps merge/spawn flags before settling tiles.
  static const Duration settle = Duration(milliseconds: 190);

  static const Curve slide = Curves.easeOutCubic;
  static const Curve spawn = Curves.easeOutBack;
  static const Curve uiCurve = Curves.easeOutCubic;
}

/// Layout constants.
abstract final class Layout {
  static const double maxBoardSize = 600;
  static const double maxContentWidth = 620;
  static const double wideBreakpoint = 680;
  static const double minTouchTarget = 48;
  static const double maxTextScale = 1.3;
}
