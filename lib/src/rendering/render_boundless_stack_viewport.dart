import 'package:boundless_stack/src/data/stack_position.dart';
import 'package:boundless_stack/src/delegate/boundless_stack_delegate.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

abstract class VicinityManager<IDType> {
  ChildVicinity produceVicinity(int layer, IDType id);
  ChildVicinity? getVicinity(String id);
  void dispose();
}

class MapVicinityManager implements VicinityManager<String> {
  MapVicinityManager();

  /// The first axis is [layer] and the second axis is [id] of the child.
  final Map<String, ChildVicinity> _vicinities = {};

  /// The highest [ChildVicinity] in the [layer] axis.
  final Map<int, ChildVicinity> _highestVicinities = {};

  @override
  void dispose() {
    _vicinities.clear();
    _highestVicinities.clear();
  }

  @override
  ChildVicinity produceVicinity(int layer, String id) {
    final vicinity = _highestVicinities[layer];
    final newVicinity = ChildVicinity(
      xIndex: (vicinity?.xIndex ?? 0) + 1,
      yIndex: layer,
    );
    _highestVicinities[layer] = newVicinity;
    _vicinities[id] = newVicinity;
    return newVicinity;
  }

  @override
  ChildVicinity? getVicinity(String id) {
    return _vicinities[id];
  }
}

class RenderBoundlessStackViewport extends RenderTwoDimensionalViewport {
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
    required bool cacheStackPosition,
    super.cacheExtent,
    super.clipBehavior,
  })  : _scaleFactor = scaleFactor,
        _cacheStackPosition = cacheStackPosition,
        _biggest = biggest;

  bool _cacheStackPosition;
  bool get cacheStackPosition => _cacheStackPosition;
  set cacheStackPosition(bool value) {
    if (_cacheStackPosition == value) return;
    _cacheStackPosition = value;
    if (!value) {
      _cachedStackPositionData?.clear();
      _cachedStackPositionData = null;
    }
  }

  Size _biggest;
  Size get biggest => _biggest;
  set biggest(Size value) {
    if (_biggest == value) return;
    _biggest = value;
    markNeedsChildrenRelayout();
  }

  double _scaleFactor;
  double get scaleFactor => _scaleFactor;
  set scaleFactor(double value) {
    if (_scaleFactor == value) return;
    _scaleFactor = value;
    markNeedsLayout();
  }

  Map<ChildVicinity, Widget>? childWidgets = {};
  List<ValueNotifier<StackPositionData>>? _stackPositionNotifiers = [];
  Map<String, StackPositionData>? _cachedStackPositionData = {};
  Map<String, StackPositionData>? _newCachedStackPositionData = {};

  List<RenderBox>? _linearChildren = [];
  VicinityManager? vicinityManager = MapVicinityManager();

  bool _needsRelayoutChildren = true;
  void markNeedsChildrenRelayout() {
    _needsRelayoutChildren = true;
    markNeedsLayout();
  }

  @override
  void dispose() {
    vicinityManager?.dispose();
    vicinityManager = null;
    childWidgets?.clear();
    childWidgets = null;
    _stackPositionNotifiers?.clear();
    _stackPositionNotifiers = null;
    _cachedStackPositionData?.clear();
    _cachedStackPositionData = null;
    _newCachedStackPositionData?.clear();
    _newCachedStackPositionData = null;
    _linearChildren = null;
    super.dispose();
  }

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
    for (final RenderBox child in _linearChildren!.reversed) {
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
    assert(vicinityManager != null);

    _linearChildren = null;
    _linearChildren = [];
    for (final notifier
        in _stackPositionNotifiers ?? <ValueNotifier<StackPositionData>>[]) {
      notifier.removeListener(markNeedsLayout);
    }
    if (_cacheStackPosition) {
      _newCachedStackPositionData?.clear();
    }

    _stackPositionNotifiers = null;
    _stackPositionNotifiers = [];
    childWidgets = null;
    childWidgets = {};

    setBoundary();

    // workaround for placeholder child
    buildPlaceholderChild();

    final builderDelegate = delegate as BoundlessStackDelegate;
    builderDelegate.viewport = this;

    List<StackPosition> children = builderDelegate.childrenBuilder(
      verticalOffset,
      horizontalOffset,
    );
    if (builderDelegate.layerSorted == false) {
      children.sort((a, b) => a.data.layer.compareTo(b.data.layer));
    }

    for (final child in children) {
      StackPositionData data;
      if (child.state?.notifier.value case final value?) {
        data = value;
      } else {
        data = child.data;
      }
      // index must increase by 1 incase it conflicts with the placeholder child
      var vicinity = vicinityManager!.getVicinity(data.id);
      vicinity ??= vicinityManager!.produceVicinity(data.layer, data.id);
      childWidgets![vicinity] = child;

      final isInViewport = stackPositionInViewport(data);
      if (!isInViewport) continue;

      if (buildOrObtainChildFor(vicinity) case final renderBox?) {
        _linearChildren!.add(renderBox);
        final notifier = child.state?.notifier;
        if (notifier != null) {
          notifier.addListener(markNeedsLayout);
          _stackPositionNotifiers!.add(notifier);
        }

        bool needsLayout = true;

        if (_cacheStackPosition) {
          final oldData = _cachedStackPositionData?[data.id];
          _newCachedStackPositionData?[data.id] = data;
          if (oldData != null) {
            if (_checkIfDataChangeAffectedLayout(oldData, data)) {
              needsLayout = true;
            } else {
              needsLayout = false;
            }
          }
        }

        needsLayout = needsLayout || _needsRelayoutChildren;

        if (needsLayout) {
          renderBox.layout(calculateScaledConstraints(data, scaleFactor));
        }

        final parentData = parentDataOf(renderBox);
        parentData.layoutOffset = data.calculateScaledOffset(scaleFactor) -
            Offset(
              horizontalOffset.pixels,
              verticalOffset.pixels,
            );
      }
    }

    if (_cacheStackPosition) {
      _cachedStackPositionData = _newCachedStackPositionData;
    }
    _needsRelayoutChildren = false;
  }

  BoxConstraints calculateScaledConstraints(
    StackPositionData data,
    double scaleFactor,
  ) {
    assert(data.width != double.infinity, 'Width must be finite');
    assert(data.height != double.infinity, 'Height must be finite');

    if (scaleFactor < 1) {
      scaleFactor = 1;
    }

    return BoxConstraints(
      minWidth: (data.width ?? 0) * scaleFactor,
      maxWidth: (data.width ?? biggest.width) * scaleFactor,
      minHeight: (data.height ?? 0) * scaleFactor,
      maxHeight: (data.height ?? biggest.height) * scaleFactor,
    );
  }
}
