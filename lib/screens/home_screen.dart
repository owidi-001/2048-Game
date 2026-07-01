import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/difficulty_selector_widget.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/score_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _dialogActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted || _dialogActive) return;
    final provider = context.read<GameProvider>();
    final event = provider.pendingEvent;
    if (event == null) return;

    provider.consumeEvent();

    if (event == GameEvent.won) {
      _dialogActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWinDialog(provider);
      });
    } else if (event == GameEvent.over) {
      _dialogActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOverDialog(provider);
      });
    } else if (event == GameEvent.newBestScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'New best score! 🎉',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: AppColors.buttonBackground,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showWinDialog(GameProvider provider) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameDialog(
        icon: '🎉',
        title: 'You Win!',
        subtitle: 'You reached 2048!',
        score: provider.state.score,
        bestScore: provider.bestScore(provider.state.difficulty),
        primaryLabel: 'Keep Going',
        secondaryLabel: 'New Game',
        onPrimary: () {
          Navigator.pop(context);
          _dialogActive = false;
          provider.continueAfterWin();
        },
        onSecondary: () {
          Navigator.pop(context);
          _dialogActive = false;
          provider.newGame();
        },
      ),
    );
  }

  void _showGameOverDialog(GameProvider provider) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GameDialog(
        icon: '😔',
        title: 'Game Over',
        subtitle: 'No moves remaining',
        score: provider.state.score,
        bestScore: provider.bestScore(provider.state.difficulty),
        primaryLabel: 'Play Again',
        secondaryLabel: 'Change Difficulty',
        onPrimary: () {
          Navigator.pop(context);
          _dialogActive = false;
          provider.newGame();
        },
        onSecondary: () {
          Navigator.pop(context);
          _dialogActive = false;
          _showDifficultyPicker(provider);
        },
      ),
    );
  }

  void _showDifficultyPicker(GameProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DifficultySheet(
        current: provider.state.difficulty,
        onSelected: (d) {
          Navigator.pop(context);
          provider.newGame(difficulty: d);
        },
      ),
    );
  }

  void _confirmNewGame(GameProvider provider) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: Text(
          'Start New Game?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: AppColors.titleColor,
          ),
        ),
        content: Text(
          'Your current progress will be lost.',
          style: GoogleFonts.nunito(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(color: AppColors.textDark),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              provider.newGame();
            },
            child: Text(
              'New Game',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: Text(
          'How to Play',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: AppColors.titleColor,
            fontSize: 22,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HowToRow(icon: Icons.swipe, text: 'Swipe or use arrow keys to move tiles'),
            const SizedBox(height: 12),
            _HowToRow(icon: Icons.join_inner_rounded, text: 'Matching tiles merge and double in value'),
            const SizedBox(height: 12),
            _HowToRow(icon: Icons.emoji_events_rounded, text: 'Reach the 2048 tile to win!'),
            const SizedBox(height: 12),
            _HowToRow(icon: Icons.undo_rounded, text: 'Use Undo to reverse your last move'),
            const SizedBox(height: 12),
            _HowToRow(icon: Icons.tune_rounded, text: 'Choose difficulty for different board sizes'),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.buttonBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            return isWide ? _WideLayout(
              onNewGame: _confirmNewGame,
              onHowToPlay: _showHowToPlay,
              onDifficulty: _showDifficultyPicker,
            ) : _NarrowLayout(
              onNewGame: _confirmNewGame,
              onHowToPlay: _showHowToPlay,
              onDifficulty: _showDifficultyPicker,
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layouts
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  final void Function(GameProvider) onNewGame;
  final VoidCallback onHowToPlay;
  final void Function(GameProvider) onDifficulty;

  const _NarrowLayout({
    required this.onNewGame,
    required this.onHowToPlay,
    required this.onDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Column(
      children: [
        _Header(provider: provider, onNewGame: () => onNewGame(provider)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DifficultySelectorWidget(
            current: provider.state.difficulty,
            onChanged: (d) {
              if (d == provider.state.difficulty) return;
              _confirmDifficulty(context, provider, d);
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const GameBoardWidget(),
          ),
        ),
        const SizedBox(height: 8),
        _BottomControls(
          onRestart: () => onNewGame(provider),
          onUndo: provider.canUndo ? provider.undo : null,
          onHelp: onHowToPlay,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final void Function(GameProvider) onNewGame;
  final VoidCallback onHowToPlay;
  final void Function(GameProvider) onDifficulty;

  const _WideLayout({
    required this.onNewGame,
    required this.onHowToPlay,
    required this.onDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleText(),
                const SizedBox(height: 20),
                _ScoreRow(provider: provider),
                const SizedBox(height: 24),
                Text(
                  'DIFFICULTY',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark.withAlpha(160),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _VerticalDifficultySelector(
                  current: provider.state.difficulty,
                  onChanged: (d) {
                    if (d == provider.state.difficulty) return;
                    _confirmDifficulty(context, provider, d);
                  },
                ),
                const Spacer(),
                _VerticalControls(
                  onRestart: () => onNewGame(provider),
                  onUndo: provider.canUndo ? provider.undo : null,
                  onHelp: onHowToPlay,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: const GameBoardWidget(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final GameProvider provider;
  final VoidCallback onNewGame;

  const _Header({required this.provider, required this.onNewGame});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TitleText(),
          const Spacer(),
          _ScoreRow(provider: provider),
        ],
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '2048',
      style: GoogleFonts.nunito(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        color: AppColors.titleColor,
        height: 1.0,
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final GameProvider provider;

  const _ScoreRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isNewBest = provider.isNewBestScore;
    return Row(
      children: [
        ScoreCardWidget(label: 'SCORE', score: provider.state.score),
        const SizedBox(width: 8),
        ScoreCardWidget(
          label: 'BEST',
          score: provider.bestScore(provider.state.difficulty),
          highlight: isNewBest,
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback? onUndo;
  final VoidCallback onHelp;

  const _BottomControls({
    required this.onRestart,
    required this.onUndo,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlBtn(
            icon: Icons.refresh_rounded,
            label: 'New Game',
            onTap: onRestart,
          ),
          _ControlBtn(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: onUndo,
          ),
          _ControlBtn(
            icon: Icons.help_outline_rounded,
            label: 'How to Play',
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}

class _VerticalControls extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback? onUndo;
  final VoidCallback onHelp;

  const _VerticalControls({
    required this.onRestart,
    required this.onUndo,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WideBtn(icon: Icons.refresh_rounded, label: 'New Game', onTap: onRestart),
        const SizedBox(height: 8),
        _WideBtn(icon: Icons.undo_rounded, label: 'Undo', onTap: onUndo),
        const SizedBox(height: 8),
        _WideBtn(icon: Icons.help_outline_rounded, label: 'How to Play', onTap: onHelp),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ControlBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: enabled ? AppColors.buttonBackground : AppColors.textDark.withAlpha(80),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.textDark : AppColors.textDark.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _WideBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled ? AppColors.buttonBackground : AppColors.textDark.withAlpha(80),
          side: BorderSide(
            color: enabled
                ? AppColors.buttonBackground.withAlpha(160)
                : AppColors.textDark.withAlpha(60),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _VerticalDifficultySelector extends StatelessWidget {
  final Difficulty current;
  final ValueChanged<Difficulty> onChanged;

  const _VerticalDifficultySelector({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Difficulty.values.map((d) {
        final isSelected = d == current;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.buttonBackground : AppColors.emptyCell,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () => onChanged(d),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      d.label,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      d.gridLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
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
      }).toList(),
    );
  }
}

class _HowToRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HowToRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.buttonBackground),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Game dialogs
// ---------------------------------------------------------------------------

class _GameDialog extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final int score;
  final int bestScore;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _GameDialog({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.bestScore,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  State<_GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<_GameDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.background,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.textDark.withAlpha(180),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ScoreInfo(label: 'Score', value: widget.score),
                  const SizedBox(width: 20),
                  _ScoreInfo(label: 'Best', value: widget.bestScore),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onPrimary,
                child: Text(
                  widget.primaryLabel,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: BorderSide(color: AppColors.textDark.withAlpha(100)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onSecondary,
                child: Text(
                  widget.secondaryLabel,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreInfo extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scoreCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.scoreLabel,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toString(),
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultySheet extends StatelessWidget {
  final Difficulty current;
  final ValueChanged<Difficulty> onSelected;

  const _DifficultySheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose Difficulty',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.titleColor,
            ),
          ),
          const SizedBox(height: 16),
          ...Difficulty.values.map((d) {
            final isSelected = d == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelected(d),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.buttonBackground
                        : AppColors.emptyCell,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        d.label,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        d.gridLabel,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withAlpha(200)
                              : AppColors.textDark.withAlpha(160),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: confirm difficulty change
// ---------------------------------------------------------------------------

void _confirmDifficulty(
    BuildContext context, GameProvider provider, Difficulty newDifficulty) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.background,
      title: Text(
        'Change Difficulty?',
        style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900, color: AppColors.titleColor),
      ),
      content: Text(
        'Switching to ${newDifficulty.label} (${newDifficulty.gridLabel}) will start a new game.',
        style: GoogleFonts.nunito(color: AppColors.textDark),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.nunito(color: AppColors.textDark)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.buttonBackground,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            provider.newGame(difficulty: newDifficulty);
          },
          child: Text(
            'Switch',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
