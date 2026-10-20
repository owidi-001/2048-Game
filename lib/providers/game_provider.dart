import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../models/tile.dart';
import '../services/game_engine.dart';
import '../services/storage_service.dart';
import '../theme/tokens.dart';
import '../utils/constants.dart';

/// Owns the current game, the undo history, persistence and transient
/// gameplay effects.
///
/// Design notes:
/// * Input is never locked behind animations. A new move first *settles* the
///   previous one (absorbed tiles removed, spawn/merge flags cleared), then
///   applies. `AnimatedPositioned` copes with interrupted slides, so rapid
///   swipes are all honoured.
/// * The settle step is a cancellable [Timer] stored on the provider, so a
///   new game or undo can never be touched by a stale closure from the
///   previous board.
/// * Tile ids are monotonic for the lifetime of the provider so widget keys
///   never collide across games.
/// * Terminal states (won / over) are derived from [GameState.status].
///   Only side-effects (haptics) go through [GameEffect]s.
class GameProvider extends ChangeNotifier {
  GameProvider({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  GameState _state = const GameState(
    tiles: [],
    score: 0,
    status: GameStatus.playing,
    difficulty: Difficulty.easy,
  );
  int _idCounter = 0;
  Timer? _settleTimer;
  final _undoStack = <GameState>[];

  int _lastGain = 0;
  int _gainTick = 0;
  Direction? _lastInvalidDirection;
  int _invalidTick = 0;
  final _effects = <GameEffect>[];
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  GameState get state => _state;
  Difficulty get difficulty => _state.difficulty;
  bool get canUndo => _undoStack.isNotEmpty && !_state.isOver;
  int get undoDepth => _undoStack.length;

  /// Points earned by the most recent successful move.
  int get lastGain => _lastGain;

  /// Increments whenever points are earned; lets the UI replay the delta chip.
  int get gainTick => _gainTick;

  /// Direction of the most recent rejected swipe, and a counter so the UI can
  /// play a nudge each time.
  Direction? get lastInvalidDirection => _lastInvalidDirection;
  int get invalidTick => _invalidTick;

  int bestScore(Difficulty difficulty) => _storage.getBestScore(difficulty);

  /// Best score for the current difficulty, including the live game.
  int get currentBest {
    final stored = _storage.getBestScore(_state.difficulty);
    return _state.score > stored ? _state.score : stored;
  }

  /// True while the running game is above the best it started against.
  bool get isBeatingRecord => _state.isNewRecord;

  /// Pops all queued effects (haptics, sounds). Empty when nothing happened.
  List<GameEffect> takeEffects() {
    final out = List<GameEffect>.unmodifiable(_effects);
    _effects.clear();
    return out;
  }

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    final savedDifficulty = _storage.getSavedDifficulty() ?? Difficulty.easy;
    final savedGame = _storage.getSavedGame();

    if (savedGame != null && savedGame.tiles.isNotEmpty) {
      _idCounter = _maxId(savedGame.tiles) + 1;
      var restored = savedGame.copyWith(
        tiles: savedGame.activeTiles
            .map((t) => t.copyWith(isNew: false, isMerged: false))
            .toList(),
      );
      // Older saves did not store status; derive it so a finished board is
      // shown as finished instead of silently accepting no moves.
      if (!restored.isOver && !GameEngine.canMove(restored)) {
        restored = restored.copyWith(status: GameStatus.over);
      }
      _state = restored;
    } else {
      _state = GameEngine.newGame(
        savedDifficulty,
        _nextId,
        bestAtStart: _storage.getBestScore(savedDifficulty),
      );
      unawaited(_persist());
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Game actions
  // ---------------------------------------------------------------------------

  void move(Direction direction) {
    if (_state.isOver || _state.isWonPending) return;

    _settleNow();

    final result = GameEngine.move(
      state: _state,
      direction: direction,
      nextId: _nextId,
    );

    if (!result.moved) {
      _lastInvalidDirection = direction;
      _invalidTick++;
      _effects.add(GameEffect.invalidMove);
      notifyListeners();
      return;
    }

    _pushUndo(_state);
    _state = result.state;
    _lastGain = result.scoreGain;
    if (result.scoreGain > 0) {
      _gainTick++;
      _effects.add(GameEffect.merge);
    }
    if (_state.status == GameStatus.won) _effects.add(GameEffect.won);
    if (_state.isOver) _effects.add(GameEffect.over);

    // Persist the record silently so it survives a crash; the announcement
    // itself is driven by the terminal state (see GameState.isNewRecord).
    final stored = _storage.getBestScore(_state.difficulty);
    if (_state.score > stored) {
      unawaited(_storage.saveBestScore(_state.difficulty, _state.score));
    }
    unawaited(_persist());

    _settleTimer = Timer(Motion.settle, _settle);
    notifyListeners();
  }

  void continueAfterWin() {
    if (_state.status != GameStatus.won) return;
    _state = _state.copyWith(status: GameStatus.continueAfterWin);
    unawaited(_persist());
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty || _state.isOver) return;
    _settleNow();
    _state = _undoStack.removeLast();
    _lastGain = 0;
    _effects.add(GameEffect.undo);
    unawaited(_persist());
    notifyListeners();
  }

  Future<void> newGame({Difficulty? difficulty}) async {
    final d = difficulty ?? _state.difficulty;
    _cancelSettle();
    _undoStack.clear();
    _effects.clear();
    _lastGain = 0;
    _lastInvalidDirection = null;
    _state = GameEngine.newGame(
      d,
      _nextId,
      bestAtStart: _storage.getBestScore(d),
    );
    // Notify first so the UI never shows a stale board while storage writes.
    notifyListeners();
    _settleTimer = Timer(Motion.settle, _settle);
    try {
      await _storage.saveDifficulty(d);
      await _persist();
    } catch (e, st) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
    }
  }

  /// Replaces the current game. Intended for tests and fixtures only.
  @visibleForTesting
  void debugSetState(GameState state) {
    _cancelSettle();
    _undoStack.clear();
    _idCounter = state.tiles.isEmpty ? _idCounter : _maxId(state.tiles) + 1;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSettle();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  int _nextId() => ++_idCounter;

  void _cancelSettle() {
    _settleTimer?.cancel();
    _settleTimer = null;
  }

  /// Finalises the previous move immediately (used before applying the next).
  void _settleNow() {
    if (_settleTimer == null) return;
    _cancelSettle();
    _applySettle();
  }

  void _settle() {
    _settleTimer = null;
    if (_disposed) return;
    if (_applySettle()) notifyListeners();
  }

  bool _applySettle() {
    final needs = _state.tiles.any(
      (t) => t.isAbsorbed || t.isNew || t.isMerged,
    );
    if (!needs) return false;
    _state = _state.copyWith(
      tiles: _state.tiles
          .where((t) => !t.isAbsorbed)
          .map((t) => t.copyWith(isNew: false, isMerged: false))
          .toList(),
    );
    return true;
  }

  Future<void> _persist() => _storage.saveGame(_state);

  void _pushUndo(GameState state) {
    _undoStack.add(
      state.copyWith(
        tiles: state.activeTiles
            .map((t) => t.copyWith(isNew: false, isMerged: false))
            .toList(),
      ),
    );
    if (_undoStack.length > kUndoStackDepth) _undoStack.removeAt(0);
  }

  static int _maxId(List<Tile> tiles) => tiles.isEmpty
      ? 0
      : tiles.map((t) => t.id).reduce((a, b) => a > b ? a : b);
}
