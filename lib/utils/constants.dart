// Gameplay layout constants. Visual tokens live in `lib/theme/`.

const kUndoStackDepth = 10;

/// Gap between cells, shrinking with grid density so tiles keep their size.
double boardGap(int gridSize) {
  if (gridSize <= 4) return 10.0;
  if (gridSize <= 5) return 8.0;
  if (gridSize <= 6) return 7.0;
  return 5.0;
}

/// Outer padding of the board (same as the gap so cells sit evenly).
double boardPadding(int gridSize) => boardGap(gridSize);

/// Tile numeral size for a given cell size and value. Scales with the digit
/// count so 4- and 5-digit values stay inside the tile on dense boards.
double tileFontSize(double cellSize, int value) {
  final digits = value.toString().length;
  final factor = switch (digits) {
    1 => 0.52,
    2 => 0.48,
    3 => 0.40,
    4 => 0.32,
    _ => 0.26,
  };
  return (cellSize * factor).clamp(9.0, 44.0);
}

/// Tile corner radius as a function of cell size.
double tileRadius(double cellSize) => (cellSize * 0.16).clamp(5.0, 14.0);

/// Minimum swipe distance (logical px) and velocity (px/s) to count as a move.
const kSwipeMinDistance = 24.0;
const kSwipeMinVelocity = 120.0;
