import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../utils/app_colors.dart';

class DifficultySelectorWidget extends StatelessWidget {
  final Difficulty current;
  final ValueChanged<Difficulty> onChanged;

  const DifficultySelectorWidget({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Difficulty.values.map((d) => _DiffChip(
        difficulty: d,
        isSelected: d == current,
        onTap: () => onChanged(d),
      )).toList(),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiffChip({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonBackground : AppColors.emptyCell,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  difficulty.label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  difficulty.gridLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withAlpha(200)
                        : AppColors.textDark.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
