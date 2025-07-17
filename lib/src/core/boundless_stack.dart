import 'package:boundless_stack/src/core/boundless_stack_scroll_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'boundless_stack_delegate.dart';

/// A widget that creates an infinite scrollable and zoomable stack.
///
/// [BoundlessStack] provides a two-dimensional scrollable area where widgets can be
/// positioned at arbitrary locations and layers. It supports zooming, panning, and
/// custom background/foreground rendering.
///
/// ## Key Features
///
/// * Infinite scrolling in both directions
/// * Zoom functionality with scale factor control
/// * Layer-based widget positioning
/// * Custom background and foreground rendering
/// * Configurable scroll physics and behavior
///
/// ## Example
///
/// ```dart
/// BoundlessStack(
///   scaleFactor: scaleNotifier,
///   delegate: BoundlessStackListDelegate(
///     children: stackPositions,
///   ),
///   horizontalDetails: ScrollableDetails.horizontal(),
///   verticalDetails: ScrollableDetails.vertical(),
///   backgroundBuilder: gridBackgroundBuilder(
///     gridWidth: 100,
///     gridHeight: 100,
///     gridColor: Colors.grey,
///     gridThickness: 1.0,
///     scaleFactor: scaleNotifier,
///   ),
/// )
/// ```
class BoundlessStack extends StatefulWidget {
  /// Creates a boundless stack widget.
  ///
  /// The [delegate] and [scaleFactor] parameters are required.
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
    this.foregroundBuilder,
  });

  /// A delegate that provides the children for the [BoundlessStack].
  ///
  /// The delegate is responsible for providing the children that will be displayed
  /// in the stack. It also handles layer sorting and child positioning.
  final BoundlessStackDelegate delegate;

  /// The number of pixels to cache on each side of the viewport.
  ///
  /// Caching items helps reduce the number of rebuilds when scrolling, improving
  /// performance at the cost of memory usage.
  ///
  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// Controls how diagonal drag gestures are handled.
  ///
  /// When set to [DiagonalDragBehavior.free], users can scroll freely in both
  /// directions simultaneously. When set to [DiagonalDragBehavior.none], scrolling
  /// is locked to one axis at a time.
  ///
  /// Defaults to [DiagonalDragBehavior.free].
  final DiagonalDragBehavior diagonalDragBehavior;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// The main axis of the two dimensions.
  ///
  /// Used to determine how to apply [primary] when true.
  ///
  /// This value is also used to determine paint order of children.
  final Axis mainAxis;

  /// The configuration of the vertical scrollable.
  ///
  /// These [ScrollableDetails] can be used to set the [AxisDirection],
  /// [ScrollController], [ScrollPhysics] and more for the vertical axis.
  final ScrollableDetails verticalDetails;

  /// The configuration of the horizontal scrollable.
  ///
  /// These [ScrollableDetails] can be used to set the [AxisDirection],
  /// [ScrollController], [ScrollPhysics] and more for the horizontal axis.
  final ScrollableDetails horizontalDetails;

  /// Determines when a drag formally begins.
  ///
  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// Determines how the keyboard is dismissed when this scrollable is in use.
  ///
  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Controls how the stack clips its content.
  ///
  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Controls the zoom level of the stack.
  ///
  /// A value of 1.0 represents the original size, values greater than 1.0 zoom in,
  /// and values less than 1.0 zoom out.
  final ValueNotifier<double> scaleFactor;

  /// Optional builder for creating a background widget.
  ///
  /// The background is rendered behind all stack children and receives the current
  /// horizontal and vertical viewport offsets.
  final TwoDimensionalViewportBuilder? backgroundBuilder;

  /// Optional builder for creating a foreground widget.
  ///
  /// The foreground is rendered in front of all stack children and receives the current
  /// horizontal and vertical viewport offsets.
  final TwoDimensionalViewportBuilder? foregroundBuilder;

  @override
  State<BoundlessStack> createState() => BoundlessStackState();
}

/// The state for a [BoundlessStack] widget.
///
/// This state manages the scroll controllers and handles scroll behavior overrides
/// during gestures.
class BoundlessStackState extends State<BoundlessStack> {
  late ScrollableDetails _horizontalDetails;
  late ScrollableDetails _verticalDetails;

  /// Overrides the scroll physics to prevent scrolling.
  ///
  /// This is typically used during gestures like pinch-to-zoom where scrolling
  /// should be temporarily disabled.
  void overrideScrollBehavior() {
    _horizontalDetails = _horizontalDetails.copyWith(
      physics: const NeverScrollableScrollPhysics(),
    );
    _verticalDetails = _verticalDetails.copyWith(
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  /// Restores the original scroll physics.
  ///
  /// This is typically called after a gesture like pinch-to-zoom has completed.
  void restoreScrollBehavior() {
    _horizontalDetails = _horizontalDetails.copyWith(
      physics:
          widget.horizontalDetails.physics ?? const ClampingScrollPhysics(),
    );
    _verticalDetails = _verticalDetails.copyWith(
      physics: widget.verticalDetails.physics ?? const ClampingScrollPhysics(),
    );
  }

  @override
  void initState() {
    super.initState();

    _horizontalDetails = widget.horizontalDetails.copyWith(
      controller: widget.horizontalDetails.controller ?? ScrollController(),
    );
    _verticalDetails = widget.verticalDetails.copyWith(
      controller: widget.verticalDetails.controller ?? ScrollController(),
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
          child: RepaintBoundary(
            child: ListenableBuilder(
              listenable: widget.scaleFactor,
              builder: (context, child) => BoundlessStackScrollView(
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
                scaleFactor: widget.scaleFactor.value,
              ),
            ),
          ),
        ),
        if (widget.foregroundBuilder case final foregroundBuilder?)
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

                return foregroundBuilder.call(
                  context,
                  _horizontalDetails.controller!.position,
                  _verticalDetails.controller!.position,
                );
              },
            ),
          ),
      ],
    );
  }
}