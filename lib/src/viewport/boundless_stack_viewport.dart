import 'package:boundless_stack/src/rendering/render_boundless_stack_viewport.dart';
import 'package:flutter/widgets.dart';

class BoundlessStackViewport extends TwoDimensionalViewport {
  const BoundlessStackViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required this.cacheStackPosition,
    required this.scaleFactor,
    required this.biggest,
    super.cacheExtent,
    super.clipBehavior,
  });

  final bool cacheStackPosition;
  final double scaleFactor;
  final Size biggest;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderBoundlessStackViewport(
      cacheStackPosition: cacheStackPosition,
      scaleFactor: scaleFactor,
      biggest: biggest,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      delegate: delegate,
      mainAxis: mainAxis,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBoundlessStackViewport renderObject,
  ) {
    renderObject
      ..cacheStackPosition = cacheStackPosition
      ..scaleFactor = scaleFactor
      ..biggest = biggest
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..delegate = delegate
      ..mainAxis = mainAxis
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}
