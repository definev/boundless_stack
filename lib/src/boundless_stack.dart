import 'package:boundless_stack/src/viewport/boundless_stack_viewport.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'delegate/boundless_stack_delegate.dart';

class BoundlessStackScrollView extends TwoDimensionalScrollView {
  const BoundlessStackScrollView({
    this.scaleFactor = 1.0,
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    required super.delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.free,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
  });

  final double scaleFactor;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return BoundlessStackViewport(
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

typedef BackgroundBuilder = Widget Function(
  BuildContext context,
  ViewportOffset horizontalOffset,
  ViewportOffset verticalOffset,
);

class BoundlessStack extends StatefulWidget {
  const BoundlessStack({
    super.key,
    this.primary,
    this.mainAxis = Axis.vertical,
    this.verticalDetails = const ScrollableDetails.vertical(),
    this.horizontalDetails = const ScrollableDetails.horizontal(),
    required this.delegate,
    this.cacheExtent,
    this.diagonalDragBehavior = DiagonalDragBehavior.free,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    required this.scaleFactor,
    this.backgroundBuilder,
  });

  /// A delegate that provides the children for the [TwoDimensionalScrollView].
  final BoundlessStackDelegate delegate;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// Whether scrolling gestures should lock to one axes, allow free movement
  /// in both axes, or be evaluated on a weighted scale.
  ///
  /// Defaults to [DiagonalDragBehavior.none], locking axes to receive input one
  /// at a time.
  final DiagonalDragBehavior diagonalDragBehavior;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// The main axis of the two.
  ///
  /// Used to determine how to apply [primary] when true.
  ///
  /// This value should also be provided to the subclass of
  /// [TwoDimensionalViewport], where it is used to determine paint order of
  /// children.
  final Axis mainAxis;

  /// The configuration of the vertical Scrollable.
  ///
  /// These [ScrollableDetails] can be used to set the [AxisDirection],
  /// [ScrollController], [ScrollPhysics] and more for the vertical axis.
  final ScrollableDetails verticalDetails;

  /// The configuration of the horizontal Scrollable.
  ///
  /// These [ScrollableDetails] can be used to set the [AxisDirection],
  /// [ScrollController], [ScrollPhysics] and more for the horizontal axis.
  final ScrollableDetails horizontalDetails;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  final double scaleFactor;

  final BackgroundBuilder? backgroundBuilder;

  @override
  State<BoundlessStack> createState() => _BoundlessStackState();
}

class _BoundlessStackState extends State<BoundlessStack> {
  late ScrollableDetails _horizontalDetails;
  late ScrollableDetails _verticalDetails;

  @override
  void initState() {
    super.initState();

    _horizontalDetails = widget.horizontalDetails.copyWith(
      controller: widget.horizontalDetails.controller ?? ScrollController(),
      physics: kIsWeb ? const NeverScrollableScrollPhysics() : null,
    );
    _verticalDetails = widget.verticalDetails.copyWith(
      controller: widget.verticalDetails.controller ?? ScrollController(),
      physics: kIsWeb ? const NeverScrollableScrollPhysics() : null,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  didUpdateWidget(BoundlessStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.horizontalDetails != oldWidget.horizontalDetails) {
      _horizontalDetails = widget.horizontalDetails.copyWith(
        controller: widget.horizontalDetails.controller ?? ScrollController(),
      );
    }

    if (widget.verticalDetails != oldWidget.verticalDetails) {
      _verticalDetails = widget.verticalDetails.copyWith(
        controller: widget.verticalDetails.controller ?? ScrollController(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.backgroundBuilder case final backgroundBuilder?)
          Positioned.fill(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                _horizontalDetails.controller!,
                _verticalDetails.controller!,
              ]),
              builder: (context, child) {
                if (!_horizontalDetails.controller!.hasClients) {
                  return const SizedBox.shrink();
                }
                if (!_verticalDetails.controller!.hasClients) {
                  return const SizedBox.shrink();
                }

                return backgroundBuilder.call(
                  context,
                  _horizontalDetails.controller!.position,
                  _verticalDetails.controller!.position,
                );
              },
            ),
          ),
        Positioned.fill(
          child: BoundlessStackScrollView(
            delegate: widget.delegate,
            cacheExtent: widget.cacheExtent,
            clipBehavior: widget.clipBehavior,
            diagonalDragBehavior: widget.diagonalDragBehavior,
            dragStartBehavior: widget.dragStartBehavior,
            horizontalDetails: _horizontalDetails,
            verticalDetails: _verticalDetails,
            keyboardDismissBehavior: widget.keyboardDismissBehavior,
            mainAxis: widget.mainAxis,
            primary: widget.primary,
            scaleFactor: widget.scaleFactor,
          ),
        ),
      ],
    );
  }
}
