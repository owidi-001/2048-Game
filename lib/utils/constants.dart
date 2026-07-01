const kMoveAnimationDuration = Duration(milliseconds: 120);
const kSpawnAnimationDuration = Duration(milliseconds: 180);
const kMergeAnimationDuration = Duration(milliseconds: 160);
const kAnimationCleanupDelay = Duration(milliseconds: 220);

const kBoardPadding = 8.0;
const kUndoStackDepth = 10;

double boardGap(int gridSize) {
  if (gridSize <= 4) return 10.0;
  if (gridSize <= 6) return 8.0;
  return 6.0;
}

double tileFontSize(double cellSize, int value) {
  final digits = value.toString().length;
  double factor;
  if (digits <= 2) {
    factor = 0.44;
  } else if (digits <= 3) {
    factor = 0.36;
  } else if (digits <= 4) {
    factor = 0.29;
  } else {
    factor = 0.22;
  }
  return (cellSize * factor).clamp(8.0, 40.0);
}

double tileRadius(double cellSize) => (cellSize * 0.12).clamp(6.0, 12.0);

const kMaxBoardWidth = 500.0;

/// Threshold velocity (logical pixels/sec) to register a swipe.
const kSwipeVelocityThreshold = 200.0;
