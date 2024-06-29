import 'package:boundless_stack/src/data/stack_position.dart';
import 'package:boundless_stack/src/delegate/boundless_stack_delegate.dart';
import 'package:flutter/widgets.dart';

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
    super.cacheExtent,
    super.clipBehavior,
  }) : _scaleFactor = scaleFactor;

  double _scaleFactor;
  double get scaleFactor => _scaleFactor;
  set scaleFactor(double value) {
    if (_scaleFactor == value) return;
    _scaleFactor = value;
    markNeedsLayout();
  }

  Map<ChildVicinity, Widget>? childWidgets = {};
  List<ValueNotifier<StackPositionData>>? _stackPositionNotifiers = [];

  @override
  void dispose() {
    childWidgets?.clear();
    childWidgets = null;
    _stackPositionNotifiers?.clear();
    _stackPositionNotifiers = null;
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
    double horizontalPixels = horizontalOffset.pixels - cacheExtent;
    double verticalPixels = verticalOffset.pixels - cacheExtent;
    double viewportWidth = viewportDimension.width + cacheExtent;
    double viewportHeight = viewportDimension.height + cacheExtent;

    final actualOffset = data.offset;

    horizontalPixels /= scaleFactor;
    verticalPixels /= scaleFactor;
    viewportHeight /= scaleFactor;
    viewportWidth /= scaleFactor;

    final width = data.width ?? constraints.maxWidth;
    final height = data.height ?? constraints.maxHeight;

    if (actualOffset.dx > horizontalPixels + viewportWidth) return false;
    if (actualOffset.dx + width < horizontalPixels) return false;
    if (actualOffset.dy > verticalPixels + viewportHeight) return false;
    if (actualOffset.dy + height < verticalPixels) return false;

    return true;
  }

  @override
  void layoutChildSequence() {
    setBoundary();

    final builderDelegate = delegate as BoundlessStackDelegate;
    builderDelegate.viewport = this;
    builderDelegate.scaleFactor = scaleFactor;

    final children = builderDelegate.childrenBuilder(
      verticalOffset,
      horizontalOffset,
    )..sort((a, b) => a.data.layer.compareTo(b.data.layer));

    for (final notifier in _stackPositionNotifiers!) {
      notifier.removeListener(markNeedsLayout);
    }
    _stackPositionNotifiers = [];
    childWidgets = {};

    for (final (index, child) in children.indexed) {
      final data = child.state?.notifier.value ?? child.data;
      final vicinity = ChildVicinity(xIndex: index, yIndex: data.layer);
      childWidgets![vicinity] = child;

      if (stackPositionInViewport(data)) {
        if (buildOrObtainChildFor(vicinity) case final renderBox?) {
          final notifier = child.state?.notifier;
          notifier?.addListener(markNeedsLayout);
          if (notifier != null) _stackPositionNotifiers!.add(notifier);

          renderBox.layout(calculateScaledConstraints(data, scaleFactor));
          final parentData = parentDataOf(renderBox);
          parentData.layoutOffset = data.calculateScaledOffset(scaleFactor) -
              Offset(
                horizontalOffset.pixels,
                verticalOffset.pixels,
              );
        }
      }
    }
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

    final result = BoxConstraints(
      minWidth: (data.width ?? 0) * scaleFactor,
      maxWidth: (data.width ?? constraints.maxWidth) * scaleFactor,
      minHeight: (data.height ?? 0) * scaleFactor,
      maxHeight: (data.height ?? constraints.maxHeight) * scaleFactor,
    );

    return result;
  }
}
