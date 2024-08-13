import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_logger/simple_logger.dart';

class _Debouncer {
  final int milliseconds;
  Timer? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

final logger = SimpleLogger(
    // Optionally, specify a log level (defaults to Level.debug).
    // Optionally, specify a custom `LogTheme` to override log styles.
    );

class ZoomStackGestureDetector extends StatefulWidget {
  const ZoomStackGestureDetector({
    super.key,
    this.scaleFactor = 0.5,
    required this.supportedDevices,
    required this.onScaleFactorChanged,
    required this.stack,
    this.onScaleStart,
    this.onScaleEnd,
  });

  final double scaleFactor;
  final BoundlessStack Function(
    GlobalKey<BoundlessStackState> key,
    double scaleFactor,
  ) stack;
  final ValueChanged<double> onScaleFactorChanged;
  final VoidCallback? onScaleStart;
  final VoidCallback? onScaleEnd;
  final Set<PointerDeviceKind> supportedDevices;

  @override
  State<ZoomStackGestureDetector> createState() =>
      _ZoomStackGestureDetectorState();
}

class _ZoomStackGestureDetectorState extends State<ZoomStackGestureDetector>
    with SingleTickerProviderStateMixin {
  final GlobalKey<BoundlessStackState> _stackKey = GlobalKey();

  double? _scaleStart;
  Offset referencefocalOriginal = Offset.zero;

  late double scaleFactor = widget.scaleFactor;

  BoundlessStack get stack => widget.stack(_stackKey, scaleFactor);

  Offset get topLeft {
    return Offset(
      stack.horizontalDetails.controller!.offset,
      stack.verticalDetails.controller!.offset,
    );
  }

  void move(Offset offset) {
    final topLeft = this.topLeft;
    stack.horizontalDetails.controller!.jumpTo(topLeft.dx + offset.dx);
    stack.verticalDetails.controller!.jumpTo(topLeft.dy + offset.dy);
  }

  Offset toViewportOffsetOriginal(Offset focalPoint, double scaleFactor) {
    return (topLeft + focalPoint) / scaleFactor;
  }

  void onUpdateScaleFactor(double newScaleFactor) {
    scaleFactor = newScaleFactor;
    widget.onScaleFactorChanged.call(newScaleFactor);
  }

  void onScaleStart(ScaleStartDetails details) {
    _scaleStart = scaleFactor;
    referencefocalOriginal =
        toViewportOffsetOriginal(details.localFocalPoint, scaleFactor);
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final desiredScale = _scaleStart! * details.scale;
      if (desiredScale >= 1.0) {
        return;
      }
      onUpdateScaleFactor(desiredScale);

      final scaledfocalPointOriginal =
          toViewportOffsetOriginal(details.localFocalPoint, desiredScale);
      move((referencefocalOriginal - scaledfocalPointOriginal) * desiredScale);
    });
  }

  void onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
  }

  final _Debouncer _debouncer = _Debouncer(milliseconds: 100);

  late final ScaleGestureRecognizer _scaleGestureRecognizer =
      ScaleGestureRecognizer()
        ..onStart = (details) {
          log('Scale start by gesture listener');
          widget.onScaleStart?.call();
          onScaleStart(details);
        }
        ..onUpdate = (details) {
          onScaleUpdate(details);
        }
        ..onEnd = (details) {
          widget.onScaleEnd?.call();
          onScaleEnd(details);
        }
        ..supportedDevices = {PointerDeviceKind.trackpad};

  bool _isControlPressed = false;

  bool onKeyPressed(KeyEvent event) {
    if (_isControlPressed != HardwareKeyboard.instance.isControlPressed) {
      _isControlPressed = HardwareKeyboard.instance.isControlPressed;
      setState(() {});
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(onKeyPressed);
  }

  @override
  void dispose() {
    super.dispose();
    HardwareKeyboard.instance.removeHandler(onKeyPressed);
  }

  @override
  void didUpdateWidget(covariant ZoomStackGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleFactor != widget.scaleFactor) {
      scaleFactor = widget.scaleFactor;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(stack.horizontalDetails.controller != null,
        'Horizontal controller is null');
    assert(stack.verticalDetails.controller != null,
        'Vertical controller is null');

    return Listener(
      onPointerDown: _scaleGestureRecognizer.addPointer,
      onPointerPanZoomStart: _scaleGestureRecognizer.addPointerPanZoom,
      onPointerSignal: switch (kIsWasm || kIsWeb) {
        true => (event) {
            switch (event) {
              /// This event from web only
              case PointerScaleEvent():
                log('Scale start by pointer');
                widget.onScaleStart?.call();
                onScaleStart(
                    ScaleStartDetails(localFocalPoint: event.localPosition));
                onScaleUpdate(
                  ScaleUpdateDetails(
                    scale: event.scale,
                    focalPoint: event.position,
                    localFocalPoint: event.localPosition,
                  ),
                );
                onScaleEnd(ScaleEndDetails());
                widget.onScaleEnd?.call();
              case PointerScrollEvent():
                if (event.kind == PointerDeviceKind.mouse &&
                    _isControlPressed) {
                  onScaleByMouseWheel(event);
                } else if (event.kind == PointerDeviceKind.mouse) {
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    move(Offset(event.scrollDelta.dx, -event.scrollDelta.dx));
                  }
                } else {
                  move(event.scrollDelta);
                }
            }
          },
        _ => (event) {
            switch (event) {
              case PointerScrollEvent():
                if (event.kind == PointerDeviceKind.mouse &&
                    _isControlPressed) {
                  onScaleByMouseWheel(event);
                }
            }
          },
      },
      child: RawGestureDetector(
        gestures: {
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(),
            (ScaleGestureRecognizer instance) => instance
              ..onStart = (details) {
                log('Scale start by gesture recognizer');
                widget.onScaleStart?.call();
                onScaleStart(details);
              }
              ..onUpdate = (details) {
                onScaleUpdate(details);
              }
              ..onEnd = (details) {
                widget.onScaleEnd?.call();
                onScaleEnd(details);
              }
              ..supportedDevices = ({...widget.supportedDevices}
                ..remove(PointerDeviceKind.trackpad)),
          ),
        },
        child: ColoredBox(
          color: Colors.transparent,
          child: IgnorePointer(
            ignoring: _isControlPressed,
            child: stack,
          ),
        ),
      ),
    );
  }

  void onScaleByMouseWheel(PointerScrollEvent event) {
    const scaleSensitivity = 0.01;
    final delta = event.scrollDelta;

    double scaleAction = math.exp(-delta.dy * scaleSensitivity);
    scaleAction = scaleAction.clamp(0.8, 1.3);

    log('Scale start by scroll wheel');
    widget.onScaleStart?.call();
    onScaleStart(
      ScaleStartDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
      ),
    );
    onScaleUpdate(
      ScaleUpdateDetails(
        scale: scaleAction,
        focalPoint: event.localPosition,
        localFocalPoint: event.localPosition,
      ),
    );
    onScaleEnd(ScaleEndDetails());
    widget.onScaleEnd?.call();
  }
}
