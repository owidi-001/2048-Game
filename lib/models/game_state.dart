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

  String get storageKey => 'best_score_$gridSize';

  static Difficulty fromString(String s) =>
      Difficulty.values.firstWhere((d) => d.name == s, orElse: () => Difficulty.easy);
}

enum GameEvent { won, over, newBestScore }

class GameState {
  final List<Tile> tiles;
  final int score;
  final GameStatus status;
  final Difficulty difficulty;
  final bool hasWonAlready;

  const GameState({
    required this.tiles,
    required this.score,
    required this.status,
    required this.difficulty,
    this.hasWonAlready = false,
  });

  GameState copyWith({
    List<Tile>? tiles,
    int? score,
    GameStatus? status,
    Difficulty? difficulty,
    bool? hasWonAlready,
  }) {
    return GameState(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      hasWonAlready: hasWonAlready ?? this.hasWonAlready,
    );
  }

  List<Tile> get activeTiles => tiles.where((t) => !t.isAbsorbed).toList();

  String toJson() {
    return jsonEncode({
      'tiles': activeTiles.map((t) => t.toJson()).toList(),
      'score': score,
      'difficulty': difficulty.name,
      'hasWonAlready': hasWonAlready,
    });
  }

  factory GameState.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return GameState(
      tiles: (map['tiles'] as List)
          .map((e) => Tile.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: map['score'] as int,
      status: GameStatus.playing,
      difficulty: DifficultyX.fromString(map['difficulty'] as String),
      hasWonAlready: (map['hasWonAlready'] as bool?) ?? false,
    );
  }
}
