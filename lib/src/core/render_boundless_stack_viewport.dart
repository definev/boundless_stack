import 'package:boundless_stack/src/core/stack_position.dart';
import 'package:boundless_stack/src/core/boundless_stack_delegate.dart';
import 'package:boundless_stack/src/utils/vicinity_manager.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Render object for the boundless stack viewport.
///
/// This class handles the layout and painting of the children based on the current
/// viewport position and scale factor.
class RenderBoundlessStackViewport extends RenderTwoDimensionalViewport {
  /// Creates a render boundless stack viewport.
  ///
  /// All parameters except [cacheExtent] and [clipBehavior] are required.
  RenderBoundlessStackViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required super.childManager,
    required double scaleFactor,
    required Size biggest,
    super.cacheExtent,
    super.clipBehavior,
  })  : _scaleFactor = scaleFactor,
        _biggest = biggest;

  /// The maximum size of the scrollable area.
  Size _biggest;

  /// Gets the maximum size of the scrollable area.
  Size get biggest => _biggest;

  /// Sets the maximum size of the scrollable area.
  set biggest(Size value) {
    if (_biggest == value) return;
    _biggest = value;
    markNeedsLayout();
  }

  /// The current scale factor.
  double _scaleFactor;

  /// Gets the current scale factor.
  double get scaleFactor => _scaleFactor;

  /// Sets the current scale factor.
  set scaleFactor(double value) {
    if (_scaleFactor == value) return;
    _scaleFactor = value;
    _forceLayout = true;
    markNeedsLayout();
  }

  /// Whether to force a layout on the next layout pass.
  bool _forceLayout = false;

  /// Map of child vicinities to widgets.
  Map<ChildVicinity, Widget>? _childWidgets = {};

  /// Gets the map of child vicinities to widgets.
  Map<ChildVicinity, Widget>? get childWidgets => _childWidgets;

  /// List of stack position notifiers.
  List<ValueNotifier<StackPositionData>>? _stackPositionNotifiers = [];

  /// Map of stack position IDs to data.
  Map<String, StackPositionData>? _cachedStackPositionData = {};

  /// List of render box children.
  List<RenderBox>? _renderBoxChildren = [];

  /// Manager for child vicinities.
  VicinityManager? _vicinityManager = MapVicinityManager();

  /// Gets the vicinity manager.
  VicinityManager get vicinityManager => _vicinityManager!;

  @override
  void dispose() {
    _vicinityManager?.dispose();
    _vicinityManager = null;
    _childWidgets?.clear();
    _childWidgets = null;
    _stackPositionNotifiers?.clear();
    _stackPositionNotifiers = null;
    _cachedStackPositionData?.clear();
    _cachedStackPositionData = null;
    _renderBoxChildren = null;
    super.dispose();
  }

  /// Sets the boundary for the viewport.
  ///
  /// This allows infinite scrolling in both directions.
  void setBoundary() {
    verticalOffset.applyContentDimensions(
      double.negativeInfinity,
      double.infinity,
    );
    horizontalOffset.applyContentDimensions(
      double.negativeInfinity,
      double.infinity,
    );
  }

  /// Determines whether a stack position is in the viewport.
  ///
  /// A stack position is in the viewport if it's visible or within the cache extent.
  bool stackPositionInViewport(StackPositionData data) {
    if (data.keepAlive) return true;

    double horizontalPixels = horizontalOffset.pixels - cacheExtent;
    double verticalPixels = verticalOffset.pixels - cacheExtent;
    double viewportWidth = viewportDimension.width + cacheExtent;
    double viewportHeight = viewportDimension.height + cacheExtent;

    final Offset actualOffset = data.calculateScaledOffset(scaleFactor);
    final double width = data.width ?? data.preferredWidth ?? biggest.width;
    final double height = data.height ?? data.preferredHeight ?? biggest.height;

    return !(actualOffset.dx > horizontalPixels + viewportWidth ||
        actualOffset.dx + width < horizontalPixels ||
        actualOffset.dy > verticalPixels + viewportHeight ||
        actualOffset.dy + height < verticalPixels);
  }

  /// Builds a placeholder child at the origin.
  ///
  /// This is used as a workaround for the viewport to have at least one child.
  void buildPlaceholderChild() {
    if (buildOrObtainChildFor(const ChildVicinity(xIndex: 0, yIndex: 0))
        case final placeholder?) {
      placeholder.layout(BoxConstraints.tight(Size.zero));

      parentDataOf(placeholder).layoutOffset = Offset(
        horizontalOffset.pixels,
        verticalOffset.pixels,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in _renderBoxChildren!.reversed) {
      final TwoDimensionalViewportParentData childParentData =
          parentDataOf(child);
      if (!childParentData.isVisible) {
        // Can't hit a child that is not visible.
        continue;
      }
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.paintOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.paintOffset!);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a data change affected the layout.
  ///
  /// This is used to determine whether a child needs to be relaid out.
  bool _checkIfDataChangeAffectedLayout(
    StackPositionData? oldData,
    StackPositionData newData,
  ) {
    if (oldData == null) return true;

    if (oldData.layer != newData.layer) return true;
    if (oldData.width != newData.width) return true;
    if (oldData.height != newData.height) return true;
    if (oldData.preferredHeight != newData.preferredHeight) return true;
    if (oldData.preferredWidth != newData.preferredWidth) return true;

    return false;
  }

  @override
  void layoutChildSequence() {
    final delegate = this.delegate as BoundlessStackDelegate;

    final newGenerationCachedStackPositionData = <String, StackPositionData>{};

    _stackPositionNotifiers ??= [];

    /// Clear the linear children
    _renderBoxChildren = null;
    _renderBoxChildren = [];

    /// Remove all listeners from the old generation notifiers
    for (final notifier in _stackPositionNotifiers!) {
      notifier.removeListener(markNeedsLayout);
    }
    _stackPositionNotifiers = null;
    _stackPositionNotifiers = [];

    /// Clear the child widgets
    _childWidgets = null;
    _childWidgets = {};

    setBoundary();

    // workaround for placeholder child
    buildPlaceholderChild();

    delegate.viewport = this;

    List<StackPosition> children = delegate.childrenBuilder(
      horizontalOffset,
      verticalOffset,
    );

    if (delegate.layerSorted == false) {
      children.sort(
        (a, b) => a.notifier.value.layer.compareTo(b.notifier.value.layer),
      );
    }

    for (final child in children) {
      final data = child.notifier.value;

      // index must increase by 1 incase it conflicts with the placeholder child
      var vicinity = vicinityManager.getVicinity(data.id);
      vicinity ??= vicinityManager.produceVicinity(data.layer, data.id);
      childWidgets![vicinity] = child;

      final isInViewport = stackPositionInViewport(data);
      if (!isInViewport) continue;

      if (buildOrObtainChildFor(vicinity) case final renderBox?) {
        newGenerationCachedStackPositionData[data.id] = data;
        _renderBoxChildren!.add(renderBox);

        /// Obtain the child and listen to its notifier and notify layout when it changes
        _obtainChild(child);

        final shouldLayout = _forceLayout ||
            _checkIfDataChangeAffectedLayout(
              _cachedStackPositionData?[data.id],
              data,
            );

        if (shouldLayout) {
          /// Layout the child
          renderBox.layout(_calculateScaledConstraints(data, scaleFactor));
        }

        /// Set the position of the child
        final parentData = parentDataOf(renderBox);
        parentData.layoutOffset = data.calculateScaledOffset(scaleFactor) -
            Offset(
              horizontalOffset.pixels,
              verticalOffset.pixels,
            );
      }
    }

    _cachedStackPositionData = newGenerationCachedStackPositionData;

    _forceLayout = false;
  }

  /// Calculates the scaled constraints for a child.
  ///
  /// This adjusts the constraints based on the current scale factor.
  BoxConstraints _calculateScaledConstraints(
    StackPositionData data,
    double scaleFactor,
  ) {
    assert(data.width != double.infinity, 'Width must be finite');
    assert(data.height != double.infinity, 'Height must be finite');
    if (scaleFactor < 1) scaleFactor = 1;

    return BoxConstraints(
      minWidth: (data.width ?? 0) * scaleFactor,
      maxWidth: (data.width ?? biggest.width) * scaleFactor,
      minHeight: (data.height ?? 0) * scaleFactor,
      maxHeight: (data.height ?? biggest.height) * scaleFactor,
    );
  }

  /// Obtains a child and listens to its notifier.
  ///
  /// This is used to update the layout when the child's data changes.
  void _obtainChild(StackPosition child) {
    final notifier = child.state?.notifier;
    if (notifier == null) return;

    notifier.addListener(markNeedsLayout);
    _stackPositionNotifiers!.add(notifier);
  }
}
