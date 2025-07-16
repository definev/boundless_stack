import 'package:boundless_stack/src/boundless_stack_viewport.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

class BoundlessStackScrollView extends TwoDimensionalScrollView {
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

  final double scaleFactor;
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
