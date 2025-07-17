import 'package:boundless_stack/src/core/render_boundless_stack_viewport.dart';
import 'package:flutter/widgets.dart';

/// A two-dimensional viewport for the boundless stack.
///
/// This widget creates a [RenderBoundlessStackViewport] to render the children.
/// It handles the layout and painting of the children based on the current
/// viewport position and scale factor.
class BoundlessStackViewport extends TwoDimensionalViewport {
  /// Creates a boundless stack viewport.
  ///
  /// All parameters except [cacheExtent] and [clipBehavior] are required.
  const BoundlessStackViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required this.scaleFactor,
    required this.biggest,
    super.cacheExtent,
    super.clipBehavior,
  });

  /// The current scale factor.
  ///
  /// This affects the size of the children and the viewport calculations.
  final double scaleFactor;

  /// The maximum size of the scrollable area.
  ///
  /// Defaults to infinite in both dimensions.
  final Size biggest;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderBoundlessStackViewport(
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