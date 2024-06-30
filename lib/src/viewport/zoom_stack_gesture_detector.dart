import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/widgets.dart';

class ZoomStackGestureDetector extends StatefulWidget {
  const ZoomStackGestureDetector({
    super.key,
    this.initialScaleFactor = 0.5,
    this.onScaleFactorChanged,
    required this.stack,
  });

  final double initialScaleFactor;
  final BoundlessStack Function(double scaleFactor) stack;
  final ValueChanged<double>? onScaleFactorChanged;

  @override
  State<ZoomStackGestureDetector> createState() =>
      _ZoomStackGestureDetectorState();
}

class _ZoomStackGestureDetectorState extends State<ZoomStackGestureDetector> {
  late double _scaleStart = widget.initialScaleFactor;
  late double scaleFactor = widget.initialScaleFactor;

  Offset referencefocalOriginal = Offset.zero;

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

  Offset toViewportOffsetOriginal(Offset focalPoint) {
    return (topLeft + focalPoint) / scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    assert(stack.horizontalDetails.controller != null,
        'Horizontal controller is null');
    assert(stack.verticalDetails.controller != null,
        'Vertical controller is null');

    return GestureDetector(
      onScaleStart: (details) {
        _scaleStart = scaleFactor;
        referencefocalOriginal =
            toViewportOffsetOriginal(details.localFocalPoint);
      },
      onScaleUpdate: (details) => setState(() {
        final desiredScale = _scaleStart * details.scale;
        if (desiredScale >= 1.0) return;
        scaleFactor = desiredScale;

        final scaledfocalPointOriginal =
            toViewportOffsetOriginal(details.localFocalPoint);
        move((referencefocalOriginal - scaledfocalPointOriginal) * scaleFactor);
        widget.onScaleFactorChanged?.call(scaleFactor);
      }),
      child: stack,
    );
  }
}
