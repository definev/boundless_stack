import 'package:boundless_stack/src/core/boundless_stack_viewport.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

/// A two-dimensional scroll view for the boundless stack.
///
/// This widget provides scrolling in both horizontal and vertical directions.
/// It creates a [BoundlessStackViewport] to render the children.
class BoundlessStackScrollView extends TwoDimensionalScrollView {
  /// Creates a boundless stack scroll view.
  ///
  /// The [delegate] parameter is required.
  const BoundlessStackScrollView({
    this.scaleFactor = 1.0,
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    this.biggest = const Size(double.maxFinite, double.maxFinite),
    required super.delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.free,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
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
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return BoundlessStackViewport(
      biggest: biggest,
      scaleFactor: scaleFactor,
      verticalOffset: verticalOffset,
      verticalAxisDirection: AxisDirection.down,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: AxisDirection.right,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      delegate: delegate,
      mainAxis: mainAxis,
    );
  }
}