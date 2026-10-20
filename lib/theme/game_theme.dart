import 'package:flutter/material.dart';

import 'tokens.dart';

/// Semantic colour and surface tokens for the game. Exposed as a
/// [ThemeExtension] so widgets read `context.gameTheme` instead of
/// hard-coding colours, and so a second (light) variant can be added later.
@immutable
class GameTheme extends ThemeExtension<GameTheme> {
  const GameTheme({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.board,
    required this.boardOutline,
    required this.emptyCell,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.danger,
    required this.scrim,
    required this.tiles,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color outline;
  final Color board;
  final Color boardOutline;
  final Color emptyCell;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color success;
  final Color danger;
  final Color scrim;
  final TilePalette tiles;

  /// "Midnight Arcade": deep navy chrome, one amber accent, saturated tiles.
  static const GameTheme midnight = GameTheme(
    background: Color(0xFF0F1420),
    surface: Color(0xFF1A2232),
    surfaceRaised: Color(0xFF232D40),
    outline: Color(0x14FFFFFF),
    board: Color(0xFF171E2E),
    boardOutline: Color(0x12FFFFFF),
    emptyCell: Color(0xFF26304A),
    textPrimary: Color(0xFFF4F6FB),
    textSecondary: Color(0xFF9AA5B8),
    textMuted: Color(0xFF6B7689),
    accent: Color(0xFFFFB547),
    onAccent: Color(0xFF141A2A),
    accentSoft: Color(0x29FFB547),
    success: Color(0xFF5EDB9D),
    danger: Color(0xFFFF6B6B),
    scrim: Color(0xF5131A2B),
    tiles: TilePalette.midnight,
  );

  @override
  GameTheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? outline,
    Color? board,
    Color? boardOutline,
    Color? emptyCell,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? danger,
    Color? scrim,
    TilePalette? tiles,
  }) {
    return GameTheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      outline: outline ?? this.outline,
      board: board ?? this.board,
      boardOutline: boardOutline ?? this.boardOutline,
      emptyCell: emptyCell ?? this.emptyCell,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      scrim: scrim ?? this.scrim,
      tiles: tiles ?? this.tiles,
    );
  }

  @override
  GameTheme lerp(ThemeExtension<GameTheme>? other, double t) {
    if (other is! GameTheme) return this;
    return GameTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      board: Color.lerp(board, other.board, t)!,
      boardOutline: Color.lerp(boardOutline, other.boardOutline, t)!,
      emptyCell: Color.lerp(emptyCell, other.emptyCell, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      tiles: t < 0.5 ? tiles : other.tiles,
    );
  }
}

/// Colours for one tile value.
@immutable
class TileStyle {
  const TileStyle(this.background, this.foreground, {this.ring});

  final Color background;
  final Color foreground;

  /// Optional highlight ring (used for the 2048 goal tile).
  final Color? ring;
}

/// The value → colour progression. Low values are cool and pale, mid values
/// warm up through teal, mint, lime and lemon, high values heat to orange,
/// coral and pink, the goal tile is gold, and super tiles turn deep.
@immutable
class TilePalette {
  const TilePalette(this._styles, this._fallback);

  final Map<int, TileStyle> _styles;
  final TileStyle _fallback;

  static const Color ink = Color(0xFF141A2A);
  static const Color paper = Color(0xFFF6F7FB);

  static const TilePalette midnight = TilePalette({
    2: TileStyle(Color(0xFFE6EAF2), ink),
    4: TileStyle(Color(0xFFC5D9F4), ink),
    8: TileStyle(Color(0xFF8FC6FA), ink),
    16: TileStyle(Color(0xFF5ED2CF), ink),
    32: TileStyle(Color(0xFF5EDB9D), ink),
    64: TileStyle(Color(0xFFB8E25C), ink),
    128: TileStyle(Color(0xFFF9E076), ink),
    256: TileStyle(Color(0xFFFFAE4A), ink),
    512: TileStyle(Color(0xFFFF8162), ink),
    1024: TileStyle(Color(0xFFF5629A), ink),
    2048: TileStyle(Color(0xFFFFC53D), ink, ring: Color(0xFFFFF1C2)),
    4096: TileStyle(Color(0xFF6E3FF3), paper),
    8192: TileStyle(Color(0xFF4433D6), paper),
    16384: TileStyle(Color(0xFFC2185B), paper),
    32768: TileStyle(Color(0xFFECEFF4), ink),
  }, TileStyle(Color(0xFF2B3550), paper));

  TileStyle of(int value) => _styles[value] ?? _fallback;

  Iterable<int> get values => _styles.keys;
}

/// Typography built on the bundled Rubik family.
abstract final class GameTypography {
  static const String family = 'Rubik';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle _base(
    double size,
    FontWeight weight,
    Color color, {
    double? letterSpacing,
    double height = 1.1,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle display(Color c) =>
      _base(32, FontWeight.w900, c, letterSpacing: -0.5, height: 1.0);
  static TextStyle title(Color c) =>
      _base(22, FontWeight.w800, c, letterSpacing: -0.2);
  static TextStyle heading(Color c) => _base(17, FontWeight.w700, c);
  static TextStyle body(Color c) => _base(15, FontWeight.w500, c, height: 1.35);
  static TextStyle bodyStrong(Color c) =>
      _base(15, FontWeight.w700, c, height: 1.3);
  static TextStyle button(Color c) =>
      _base(15, FontWeight.w700, c, letterSpacing: 0.1);
  static TextStyle caption(Color c) => _base(12, FontWeight.w600, c);
  static TextStyle label(Color c) =>
      _base(11, FontWeight.w700, c, letterSpacing: 1.2, height: 1.0);
  static TextStyle scoreLarge(Color c) => _base(
    26,
    FontWeight.w800,
    c,
    letterSpacing: -0.5,
    height: 1.0,
  ).copyWith(fontFeatures: tabular);
  static TextStyle scoreSmall(Color c) => _base(
    18,
    FontWeight.w700,
    c,
    letterSpacing: -0.3,
    height: 1.0,
  ).copyWith(fontFeatures: tabular);
  static TextStyle tile(double size, Color c) => _base(
    size,
    FontWeight.w800,
    c,
    letterSpacing: size > 24 ? -1.0 : -0.3,
    height: 1.0,
  ).copyWith(fontFeatures: tabular);
}

extension GameThemeContext on BuildContext {
  GameTheme get gameTheme => Theme.of(this).extension<GameTheme>()!;
}

/// Builds the app-wide [ThemeData] from a [GameTheme].
ThemeData buildAppTheme(GameTheme g) {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: g.accent,
    onPrimary: g.onAccent,
    secondary: g.success,
    onSecondary: g.onAccent,
    error: g.danger,
    onError: g.onAccent,
    surface: g.surface,
    onSurface: g.textPrimary,
    surfaceContainerHighest: g.surfaceRaised,
    outline: g.outline,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: g.background,
    fontFamily: GameTypography.family,
    splashFactory: InkSparkle.splashFactory,
    extensions: [g],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: g.textPrimary,
      displayColor: g.textPrimary,
      fontFamily: GameTypography.family,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: g.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: g.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
      showDragHandle: true,
      dragHandleColor: g.textMuted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: g.accent,
        foregroundColor: g.onAccent,
        minimumSize: const Size(0, 52),
        textStyle: GameTypography.button(g.onAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: g.textSecondary,
        minimumSize: const Size(0, 48),
        textStyle: GameTypography.button(g.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: g.outline, thickness: 1, space: 1),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: g.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      textStyle: GameTypography.caption(g.textPrimary),
    ),
  );
}
