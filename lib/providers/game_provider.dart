import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/tile.dart';
import '../services/game_engine.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  final StorageService _storage;

  late GameState _state;
  int _idCounter = 0;
  bool _isAnimating = false;
  GameEvent? _pendingEvent;
  bool _isNewBestScore = false;

  final _undoStack = <GameState>[];

  GameProvider({required StorageService storage}) : _storage = storage;

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  GameState get state => _state;
  bool get isAnimating => _isAnimating;
  GameEvent? get pendingEvent => _pendingEvent;
  bool get isNewBestScore => _isNewBestScore;
  bool get canUndo => _undoStack.isNotEmpty;

  int bestScore(Difficulty difficulty) => _storage.getBestScore(difficulty);

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    final savedDifficulty = _storage.getSavedDifficulty() ?? Difficulty.easy;
    final savedGame = _storage.getSavedGame();

    if (savedGame != null) {
      _idCounter = _maxId(savedGame.tiles) + 1;
      _state = savedGame;
    } else {
      _state = GameEngine.newGame(savedDifficulty, _nextId);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Game actions
  // ---------------------------------------------------------------------------

  void move(Direction direction) {
    if (_isAnimating) return;
    if (_state.status == GameStatus.over) return;

    final result = GameEngine.move(
      state: _state,
      direction: direction,
      nextId: _nextId,
    );
    if (!result.moved) return;

    _pushUndo(_state);
    _isAnimating = true;
    _state = result.state;
    notifyListeners();

    Future.delayed(kAnimationCleanupDelay, () {
      if (!hasListeners) return;

      // Remove absorbed tiles and reset animation flags
      _state = _state.copyWith(
        tiles: _state.tiles
            .where((t) => !t.isAbsorbed)
            .map((t) => t.copyWith(isNew: false, isMerged: false))
            .toList(),
      );
      _isAnimating = false;

      // Update best score
      final current = _state.score;
      final best = _storage.getBestScore(_state.difficulty);
      if (current > best) {
        _storage.saveBestScore(_state.difficulty, current);
        _isNewBestScore = true;
        _pendingEvent = GameEvent.newBestScore;
      }

      // Persist game state
      _storage.saveGame(_state);

      // Trigger win / game-over dialogs after animations finish
      if (result.state.status == GameStatus.won) {
        _pendingEvent = GameEvent.won;
      } else if (result.state.status == GameStatus.over) {
        _pendingEvent = GameEvent.over;
      }

      notifyListeners();
    });
  }

  void consumeEvent() {
    _pendingEvent = null;
    _isNewBestScore = false;
  }

  void continueAfterWin() {
    _state = _state.copyWith(status: GameStatus.continueAfterWin);
    notifyListeners();
  }

  void undo() {
    if (_isAnimating || _undoStack.isEmpty) return;
    _state = _undoStack.removeLast();
    notifyListeners();
  }

  Future<void> newGame({Difficulty? difficulty}) async {
    final d = difficulty ?? _state.difficulty;
    _undoStack.clear();
    _idCounter = 0;
    _pendingEvent = null;
    _isNewBestScore = false;
    _state = GameEngine.newGame(d, _nextId);
    await _storage.saveDifficulty(d);
    await _storage.clearSavedGame();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  int _nextId() => ++_idCounter;

  void _pushUndo(GameState state) {
    _undoStack.add(state.copyWith(
      tiles: state.activeTiles
          .map((t) => t.copyWith(isNew: false, isMerged: false))
          .toList(),
    ));
    if (_undoStack.length > kUndoStackDepth) _undoStack.removeAt(0);
  }

  static int _maxId(List<Tile> tiles) =>
      tiles.isEmpty ? 0 : tiles.map((t) => t.id).reduce((a, b) => a > b ? a : b);
}
