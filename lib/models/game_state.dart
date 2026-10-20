import 'dart:convert';
import 'tile.dart';

enum GameStatus { playing, won, over, continueAfterWin }

enum Difficulty { easy, medium, hard, expert }

extension DifficultyX on Difficulty {
  int get gridSize => const {
    Difficulty.easy: 4,
    Difficulty.medium: 5,
    Difficulty.hard: 6,
    Difficulty.expert: 8,
  }[this]!;

  String get label => const {
    Difficulty.easy: 'Easy',
    Difficulty.medium: 'Medium',
    Difficulty.hard: 'Hard',
    Difficulty.expert: 'Expert',
  }[this]!;

  String get gridLabel => '$gridSize×$gridSize';

  String get description => const {
    Difficulty.easy: 'The classic board. Quick games, tight decisions.',
    Difficulty.medium: 'More room to plan, more tiles to track.',
    Difficulty.hard: 'Long games with big merges and high scores.',
    Difficulty.expert: 'A huge board for marathon runs and record chasing.',
  }[this]!;

  String get storageKey => 'best_score_$gridSize';

  static Difficulty fromString(String s) => Difficulty.values.firstWhere(
    (d) => d.name == s,
    orElse: () => Difficulty.easy,
  );
}

/// Transient gameplay effects the UI may react to (haptics, sounds).
/// Terminal states (win / game over) are *not* events: they are derived
/// from [GameState.status] so re-renders can never re-trigger them.
enum GameEffect { merge, invalidMove, won, over, undo }

class GameState {
  final List<Tile> tiles;
  final int score;
  final GameStatus status;
  final Difficulty difficulty;
  final bool hasWonAlready;

  /// Persisted best score for [difficulty] at the moment this game started.
  /// A game sets a new record when `score > bestAtStart` at its terminal state.
  final int bestAtStart;

  /// Number of successful moves made in this game.
  final int moves;

  const GameState({
    required this.tiles,
    required this.score,
    required this.status,
    required this.difficulty,
    this.hasWonAlready = false,
    this.bestAtStart = 0,
    this.moves = 0,
  });

  bool get isOver => status == GameStatus.over;
  bool get isWonPending => status == GameStatus.won;
  bool get hasProgress => moves > 0 || score > 0;
  bool get isNewRecord => score > 0 && score > bestAtStart;
  int get highestTile =>
      activeTiles.fold(0, (m, t) => t.value > m ? t.value : m);

  GameState copyWith({
    List<Tile>? tiles,
    int? score,
    GameStatus? status,
    Difficulty? difficulty,
    bool? hasWonAlready,
    int? bestAtStart,
    int? moves,
  }) {
    return GameState(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      hasWonAlready: hasWonAlready ?? this.hasWonAlready,
      bestAtStart: bestAtStart ?? this.bestAtStart,
      moves: moves ?? this.moves,
    );
  }

  List<Tile> get activeTiles => tiles.where((t) => !t.isAbsorbed).toList();

  String toJson() {
    return jsonEncode({
      'tiles': activeTiles.map((t) => t.toJson()).toList(),
      'score': score,
      'difficulty': difficulty.name,
      'hasWonAlready': hasWonAlready,
      'status': status.name,
      'bestAtStart': bestAtStart,
      'moves': moves,
    });
  }

  factory GameState.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final hasWon = (map['hasWonAlready'] as bool?) ?? false;
    final statusName = map['status'] as String?;
    final status = statusName == null
        ? (hasWon ? GameStatus.continueAfterWin : GameStatus.playing)
        : GameStatus.values.firstWhere(
            (s) => s.name == statusName,
            orElse: () => GameStatus.playing,
          );
    return GameState(
      tiles: (map['tiles'] as List)
          .map((e) => Tile.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: map['score'] as int,
      status: status,
      difficulty: DifficultyX.fromString(map['difficulty'] as String),
      hasWonAlready: hasWon,
      bestAtStart: (map['bestAtStart'] as int?) ?? 0,
      moves: (map['moves'] as int?) ?? 0,
    );
  }
}
