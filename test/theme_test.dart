import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndoto_2048/theme/game_theme.dart';
import 'package:ndoto_2048/utils/constants.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final g = GameTheme.midnight;

  group('tile legibility', () {
    final values = [for (var v = 2; v <= 131072; v *= 2) v];
    for (final v in values) {
      test('tile $v text contrast ≥ 4.5:1 (WCAG AA)', () {
        final s = g.tiles.of(v);
        expect(
          contrast(s.foreground, s.background),
          greaterThanOrEqualTo(4.5),
          reason: 'tile $v fg ${s.foreground} on bg ${s.background}',
        );
      });
    }

    test(
      'adjacent powers of two use distinguishable backgrounds up to 2048',
      () {
        for (var v = 2; v < 2048; v *= 2) {
          final a = g.tiles.of(v).background, b = g.tiles.of(v * 2).background;
          expect(a, isNot(b), reason: '$v and ${v * 2} share a colour');
        }
      },
    );
  });

  group('chrome contrast', () {
    test('primary and secondary text on surfaces meet AA', () {
      for (final bg in [g.background, g.surface, g.surfaceRaised, g.board]) {
        expect(contrast(g.textPrimary, bg), greaterThanOrEqualTo(4.5));
        expect(contrast(g.textSecondary, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('accent button label is readable', () {
      expect(contrast(g.onAccent, g.accent), greaterThanOrEqualTo(4.5));
    });
  });

  group('tile font sizing', () {
    test('scales with cell size and shrinks for longer numbers', () {
      final big4 = tileFontSize(80, 2), big8 = tileFontSize(36, 2);
      expect(big4, greaterThan(big8));
      expect(tileFontSize(36, 2), greaterThan(tileFontSize(36, 2048)));
      // 8x8 on a 328px board → ~36px cells: still a readable size for 4 digits.
      expect(tileFontSize(36, 2048), greaterThanOrEqualTo(11));
    });
  });
}
