import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/game_engine.dart';
import '../utils/constants.dart';

/// Turns touch drags, mouse drags and keyboard arrows / WASD into
/// [Direction]s.
///
/// Uses a single pan recognizer and resolves the dominant axis itself, so
/// horizontal and vertical recognizers never compete in the gesture arena and
/// a slightly diagonal swipe always produces exactly one move. A move fires as
/// soon as the drag passes [kSwipeMinDistance] (snappy), or on release when the
/// fling velocity is high enough; each pointer-down yields at most one move.
class SwipeDetector extends StatefulWidget {
  const SwipeDetector({
    super.key,
    required this.onSwipe,
    required this.child,
    this.enabled = true,
    this.autofocus = true,
  });

  final ValueChanged<Direction> onSwipe;
  final Widget child;
  final bool enabled;
  final bool autofocus;

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  Offset _start = Offset.zero;
  Offset _delta = Offset.zero;
  bool _fired = false;

  void _onStart(DragStartDetails d) {
    _start = d.localPosition;
    _delta = Offset.zero;
    _fired = false;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_fired || !widget.enabled) return;
    _delta = d.localPosition - _start;
    if (_delta.distance >= kSwipeMinDistance) {
      _fire(_direction(_delta));
    }
  }

  void _onEnd(DragEndDetails d) {
    if (_fired || !widget.enabled) return;
    final v = d.velocity.pixelsPerSecond;
    if (v.distance >= kSwipeMinVelocity && _delta.distance > 4) {
      _fire(_direction(_delta));
    } else if (v.distance >= kSwipeMinVelocity * 3) {
      _fire(_direction(v));
    }
  }

  void _fire(Direction direction) {
    _fired = true;
    widget.onSwipe(direction);
  }

  static Direction _direction(Offset o) {
    if (o.dx.abs() >= o.dy.abs()) {
      return o.dx > 0 ? Direction.right : Direction.left;
    }
    return o.dy > 0 ? Direction.down : Direction.up;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => Direction.left,
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.keyD => Direction.right,
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => Direction.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => Direction.down,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    widget.onSwipe(direction);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(
                  supportedDevices: const {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.unknown,
                  },
                ),
                (r) => r
                  ..onStart = _onStart
                  ..onUpdate = _onUpdate
                  ..onEnd = _onEnd
                  ..dragStartBehavior = DragStartBehavior.down,
              ),
        },
        child: widget.child,
      ),
    );
  }
}
