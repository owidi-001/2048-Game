# Ndoto 2048

A Flutter 2048 with four board sizes (4×4 Easy, 5×5 Medium, 6×6 Hard, 8×8 Expert), per-board
best scores, undo (10 moves), persistence between launches, and a "Midnight Arcade" visual
system with a WCAG-checked tile palette.

## Run

```sh
flutter pub get
flutter run            # any connected device / simulator
flutter build web --release
```

## Test

```sh
flutter analyze
flutter test                                   # engine, provider, theme and widget suites
GAME_SCREENSHOTS=1 flutter test test/screenshots_test.dart   # renders docs/screenshots/*.png
```

The screenshot suite renders the real app at phone, small-phone, landscape and tablet sizes
(and at 1.3× text scale) using the bundled fonts, so visual review does not depend on a simulator.

## Layout

| Path | Purpose |
|---|---|
| `lib/services/game_engine.dart` | Pure move/merge/spawn logic |
| `lib/providers/game_provider.dart` | Game state, undo, persistence, settle timer, UI effects |
| `lib/theme/` | Design tokens (`tokens.dart`) and the `GameTheme` extension + tile palette |
| `lib/screens/home_screen.dart` | Portrait and wide layouts, user flows |
| `lib/widgets/` | Board, tiles, swipe detector, score panel, selector, overlay, dialogs, sheets |
| `docs/redesign-notes.md` | Design rationale, bug analyses, iteration log |

Fonts: Rubik (SIL Open Font License, see `assets/fonts/OFL-Rubik.txt`).
