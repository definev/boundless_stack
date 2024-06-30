import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ZoomStackGestureDetector extends StatefulWidget {
  const ZoomStackGestureDetector({
    super.key,
    this.scaleFactor = 0.5,
    required this.onScaleFactorChanged,
    required this.stack,
  });

  final double scaleFactor;
  final BoundlessStack Function(double scaleFactor) stack;
  final ValueChanged<double> onScaleFactorChanged;

  @override
  State<ZoomStackGestureDetector> createState() =>
      _ZoomStackGestureDetectorState();
}

class _ZoomStackGestureDetectorState extends State<ZoomStackGestureDetector> {
  double? _scaleStart;
  Offset referencefocalOriginal = Offset.zero;

  double get scaleFactor => widget.scaleFactor;

  BoundlessStack get stack => widget.stack(scaleFactor);

  void move(Offset offset) {
    final topLeft = this.topLeft;
    stack.horizontalDetails.controller!.jumpTo(topLeft.dx + offset.dx);
    stack.verticalDetails.controller!.jumpTo(topLeft.dy + offset.dy);
  }

  Offset get topLeft {
    return Offset(
      stack.horizontalDetails.controller!.offset,
      stack.verticalDetails.controller!.offset,
    );
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

  bool onEventScroll = false;

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
          // This should minus the the scroll offset that TwoDimensionalViewport handle
          move(event.scrollDelta);
        }
      },
      child: GestureDetector(
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onScaleEnd: onScaleEnd,
        child: IgnorePointer(
          ignoring: onEventScroll,
          child: stack,
        ),
      ),
    );
  }
}
