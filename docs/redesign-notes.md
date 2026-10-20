# 2048 UI/UX reengineering notes

Working document for the redesign. Keeps the design rationale, token decisions and the bug
investigations in one place so future changes stay coherent.

## 1. Repository reconnaissance (before changes)

| Area | Finding |
|---|---|
| Framework | Flutter (Dart SDK ^3.11), Material 3, `provider` for state, `shared_preferences` for persistence, `google_fonts` (runtime download of Nunito). |
| Structure | Single screen `lib/screens/home_screen.dart` (~950 lines: layouts, dialogs, sheets, buttons). Engine in `lib/services/game_engine.dart`, state in `lib/providers/game_provider.dart`, widgets for board/tile/score/difficulty. |
| Engine | Pure functions: `GameEngine.newGame`, `GameEngine.move` (line compaction + merge, spawn 2/4 at 90/10, win at 2048 once, game over when no merges and board full). Correct; left unchanged except for public `canMove` and injectable `Random`. |
| Tests | One placeholder test. No engine, provider, or widget tests. |
| Visual tooling | No simulator/emulator available in the sandbox. Screenshots are produced by Flutter widget tests that render the real app at device sizes with the bundled fonts (`test/screenshots_test.dart`, run with `GAME_SCREENSHOTS=1`). |

### Pre-existing defects found (recorded separately from the redesign)

1. **Bug A – record announcement.** `GameProvider.move()` set `pendingEvent = newBestScore` after *every*
   move where `score > best`, so a SnackBar was queued on each swipe once the player passed the record,
   and the event was also overwritten by `won`/`over` at the actual terminal state.
2. **Bug B – swipes after difficulty change.** Not reproducible as a deterministic logic failure
   (a 12-transition × 4-direction widget-test matrix passed on the original code, including the
   dialog path and switching mid-animation). The input pipeline had several real robustness defects
   that produce dropped or mis-timed swipes on devices:
   - a 220 ms `_isAnimating` lock silently dropped any swipe made during the previous move's
     animation (reproduced by `test/game_provider_test.dart` "rapid moves");
   - `Future.delayed` cleanup closures captured the *previous* game's `MoveResult` and could fire
     into a new board after a difficulty change (stale win/over events, stale persistence);
   - `newGame()` reset the tile id counter to 0, so the new board's `ValueKey(1)`/`ValueKey(2)`
     re-used widget elements and animation state from the previous board;
   - `newGame()` awaited two storage writes before `notifyListeners()`, so the UI could keep
     showing the old board while the provider already held the new one.
3. `DifficultySelectorWidget` `Row` overflowed horizontally on 390 px wide screens.
4. `_HomeScreenState.dispose` called `context.read` (unsafe ancestor lookup on unmount).
5. Saved games were always restored with `status: playing`, even if already won/over.

## 2. Design direction

Candidates evaluated against the brief's criteria (appeal, identity, tile readability, colour
quality, age suitability, originality, focus, usability, accessibility, feasibility, performance,
maintainability):

| Direction | Verdict |
|---|---|
| Warm editorial paper (cream background, taupe board) | Safe but reads as the 2014 original; fails "distinctive". |
| Candy pastel | Friendly for kids, but pastel-on-pastel contrast is weak and tile values blur at 8×8. |
| Neon glow dark | Distinctive but glow halos hurt number legibility and feel generic "gamer". |
| **Midnight Arcade (chosen)** | Deep navy-ink surfaces, one amber accent, and a saturated **sticker-tile ramp** with dark ink numerals. High contrast everywhere, vivid for children, restrained enough for adults, and the board is the only saturated area so it stays the focal point. |

Key decisions:

- **Dark-first single theme.** The board and tiles carry all the colour; chrome is quiet navy so the
  tile ramp reads clearly at every board size. Tokens live in one `ThemeExtension` so a light
  variant can be added without touching widgets.
- **Tile ramp** moves through hue as values climb (slate → sky → teal → mint → lime → lemon → orange →
  coral → pink), the goal tile 2048 is gold with a light ring, and super tiles turn deep
  (violet → indigo → crimson → platinum). Dark ink numerals on every tile up to 2048 (contrast ≥ 5.8:1);
  paper numerals on super tiles (≥ 4.5:1). Contrast is asserted by `test/theme_test.dart`.
- **Typography:** Rubik (OFL, bundled, weights 500–900). Geometric with soft corners, compact
  numerals, tabular figures for scores. Tile numerals scale with cell size and digit count.
- **Spacing/radius:** 4-pt spacing scale; radii 10/14/18/22; board gap shrinks with grid size.
- **Motion:** slide 110 ms, spawn 170 ms, merge pop 180 ms, UI 200 ms, overlay 260 ms. All
  durations collapse to zero when the platform requests reduced motion.
- **Feedback:** score delta chip, merge pop, light haptic on merge, board nudge on invalid move,
  integrated board overlay for win / game over with a "New record" ribbon only at the terminal state.

## 3. Record (Bug A) semantics

- `bestAtStart` is captured when a game starts and persisted with the game.
- Best score is persisted silently during play (so a crash never loses it) and the BEST card shows
  the live value; the *announcement* is only shown as part of the game-over overlay when
  `score > bestAtStart`. Reaching 2048 shows the win overlay with a compact "new best" chip when
  applicable, following the existing keep-going semantics.
- Overlays are declarative (driven by `GameState.status`), so re-renders cannot re-trigger them.

## 4. Input pipeline (Bug B) design

- `GameProvider` no longer has an input lock. Each successful move starts a cancellable
  `_settleTimer` (`Motion.settle`, 190 ms) that strips the transient `isNew` / `isMerged` /
  `isAbsorbed` flags. A move or undo issued before it fires calls `_settleNow()` first, so the
  second swipe is applied to a clean board instead of being dropped.
- `newGame()` cancels the timer, clears undo/effects, swaps the state and notifies **before** any
  storage await; the board widget is keyed by `(difficulty, gridSize)` and tile ids are monotonic
  for the provider's lifetime, so no element from the previous board is ever reused.
- Gesture recognition is a single `PanGestureRecognizer` (via `RawGestureDetector`) with distance
  (24 px) and velocity (120 px/s) thresholds, plus arrow-key handling. Animations were kept.

## 5. Evaluation-and-refinement cycles

All renders are widget-test screenshots of the real app (`docs/screenshots/`), produced with
`GAME_SCREENSHOTS=1 flutter test test/screenshots_test.dart`. No iOS/Android simulator was
available in the environment, so device-specific behaviour (haptics, system gestures, real GPU
timing) is **not** covered by these renders.

### Cycle 1 - structure and visual foundation

Rendered: fresh 4×4, mid-game 4×4/5×5/6×6/8×8 (390×844), game over with/without record, win,
how-to-play, confirm dialog, difficulty sheet, 360×640 8×8, iPhone SE 4×4, tablet landscape 6×6,
phone landscape 4×4, tablet portrait 5×5, 1.3× text scale.

Findings and fixes:

| Finding | Fix |
|---|---|
| Large dead space above/below the board on tall phones | `_BoardArea` sizes board + status strip together and sits them slightly above centre; status strip (highest tile · moves) only appears when there is room. |
| Game-over panel cramped, board numbers showing through the scrim | Scrim alpha raised (0xF5), compact panel layout below 440 px, tighter stat chips. |
| Phone landscape sidebar needed scrolling to reach actions | Short-height variant of the wide layout: inline brand + score, segmented selector, horizontal action bar; fits in 390 px. |
| Tablet portrait chrome stretched to 820 px while the board capped at 520 | Portrait content column capped at 620 px; board cap raised to 600 px. |
| Sidebar action captions truncated ("How to p…") on tablets | Full-width horizontal `ActionButton` variant in the sidebar. |
| Header overflowed by 31 px at 1.3× text scale; brand glyph wrapped "204 / 8" | Glyph text no longer scales; header rebuilt around a shrinkable score panel. |

### Cycle 2 - interaction and state correctness

- Added `test/game_engine_test.dart` (slides, merges, scoring, win-once, dead-board detection,
  JSON round-trip, record semantics), `test/game_provider_test.dart` (rapid moves, settle timer,
  mid-animation `newGame`, monotonic ids, all 12 difficulty transitions, Bug A semantics, undo
  depth/over, persistence of legacy saves, invalid-move effect) and
  `test/widget/home_screen_test.dart` (12 directed transitions × {chip + confirm, mid-animation}
  followed by swipes in all four directions, a full round trip through every size, confirmation
  rules, record overlay only at game over, win → keep going, six viewports × four difficulties with
  no overflow, 1.3× text scale, 8×8 font floor, keyboard input, two quick swipes both applied).
- Fixture bug caught by the tests: the "one move from over" boards in the first draft still had a
  merge available after the spawn; replaced with a three-family layout that is provably dead.
- The `BoardOverlay` host is always mounted (it animates in/out), so tests assert on the panel
  key rather than the host type.

### Cycle 3 - polish and stress

Rendered additionally: seven-digit score on 360 px at 1.3× text, game over with a seven-digit
score on 360 px.

| Finding | Fix |
|---|---|
| Brand glyph shrank to a dot when the score panel got wide | Brand keeps natural size; score panel is `Expanded` and its digits `FittedBox`-shrink on one line. |
| Score panel grew taller when digits were squeezed (text wrapped inside the intrinsic-height row) | `maxLines: 1, softWrap: false` on the value text. |
| "How to pl…" at 1.3× on 360 px | Action captions shrink instead of truncating. |
| Win panel filled the whole 4×4 board edge to edge | Win panel no longer repeats the score/best row (visible in the header); game-over keeps it. |

Final state of the suite: `flutter analyze` clean, `dart format` clean, `flutter test` 109 passed
(19 screenshot tests skipped unless opted in; 19/19 pass when enabled), `flutter build web --release`
succeeds.

## 6. Known limitations

- No device/simulator run: haptics, safe-area insets on notched devices, system back gestures and
  real frame timing are unverified. The layouts were validated at 360×640, 375×667, 390×844,
  844×390, 820×1180 and 1180×820 logical sizes via widget tests.
- Bug B was never reproducible as a deterministic logic failure; the fix removes the identified
  robustness defects (dropped swipes, stale timers, reused tile keys, late notify) and is covered
  by the regression matrix, but a device test is still recommended.
- Single dark theme. The token layer supports a light variant, none was added.
