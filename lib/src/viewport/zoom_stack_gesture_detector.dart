import 'dart:async';

import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  double get scaleFactor => widget.scaleFactor;

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

  void onScaleStart(ScaleStartDetails details) {
    _scaleStart = scaleFactor;
    referencefocalOriginal =
        toViewportOffsetOriginal(details.localFocalPoint, scaleFactor);
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      final desiredScale = _scaleStart! * details.scale;
      if (desiredScale >= 1.0) return;
      widget.onScaleFactorChanged.call(desiredScale);

      final scaledfocalPointOriginal =
          toViewportOffsetOriginal(details.localFocalPoint, desiredScale);
      move((referencefocalOriginal - scaledfocalPointOriginal) * desiredScale);
    });
  }

  void onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
  }

  final _Debouncer _debouncer = _Debouncer(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    assert(stack.horizontalDetails.controller != null,
        'Horizontal controller is null');
    assert(stack.verticalDetails.controller != null,
        'Vertical controller is null');

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScaleEvent) {
          onScaleStart(ScaleStartDetails(localFocalPoint: event.localPosition));
          onScaleUpdate(
            ScaleUpdateDetails(
              scale: event.scale,
              focalPoint: event.position,
              localFocalPoint: event.localPosition,
            ),
          );
          onScaleEnd(ScaleEndDetails());
        }
        if (event is PointerScrollEvent) {
          _stackKey.currentState?.overrideScrollBehavior();
          move(event.scrollDelta);
          _debouncer.run(() => _stackKey.currentState?.restoreScrollBehavior());
        }
      },
      child: RawGestureDetector(
        gestures: {
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(),
            (ScaleGestureRecognizer instance) {
              instance
                ..onStart = (details) {
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
                ..supportedDevices = widget.supportedDevices;
            },
          ),
        },
        child: ColoredBox(
          color: Colors.transparent,
          child: stack,
        ),
      ),
    );
  }
}
