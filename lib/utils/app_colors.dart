import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFFAF8EF);
  static const boardBackground = Color(0xFFBBADA0);
  static const emptyCell = Color(0xFFCDC1B4);
  static const scoreCard = Color(0xFFBBADA0);
  static const scoreLabel = Color(0xFFEEE4DA);
  static const scoreValue = Colors.white;
  static const titleColor = Color(0xFF776E65);
  static const buttonBackground = Color(0xFF8F7A66);
  static const buttonText = Colors.white;
  static const textDark = Color(0xFF776E65);
  static const textLight = Color(0xFFF9F6F2);

  static const _tileColors = <int, Color>{
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
    4096: Color(0xFF3C3A32),
    8192: Color(0xFF6C3483),
    16384: Color(0xFF1A5276),
    32768: Color(0xFF117A65),
  };

  static Color tileColor(int value) {
    if (_tileColors.containsKey(value)) return _tileColors[value]!;
    // For very high values, cycle through a set of rich colors
    return const Color(0xFF3C3A32);
  }

  static Color tileForeground(int value) {
    return value <= 4 ? textDark : textLight;
  }

  static BoxShadow tileShadow(int value) {
    final opacity = value >= 64 ? 0.25 : 0.15;
    return BoxShadow(
      color: Colors.black.withAlpha((opacity * 255).round()),
      blurRadius: 6,
      offset: const Offset(0, 3),
    );
  }
}
