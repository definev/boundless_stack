import 'package:boundless_stack/src/data/stack_position.dart';
import 'package:boundless_stack/src/rendering/render_boundless_stack_viewport.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BoundlessStackDelegate extends TwoDimensionalChildDelegate {
  BoundlessStackDelegate({
    required this.childrenBuilder,
    this.layerSorted = false,
  });

  final List<StackPosition> Function(
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) childrenBuilder;

  late RenderBoundlessStackViewport? _viewport;
  set viewport(RenderBoundlessStackViewport value) {
    _viewport = value;
  }

  final bool layerSorted;

  @override
  Widget? build(BuildContext context, covariant ChildVicinity vicinity) {
    if (vicinity == const ChildVicinity(xIndex: 0, yIndex: 0)) {
      return const SizedBox();
    }
    if (_viewport == null) return null;
    return _viewport?.childWidgets?[vicinity];
  }

  @override
  bool shouldRebuild(BoundlessStackDelegate oldDelegate) =>
      childrenBuilder != oldDelegate.childrenBuilder;
}

class BoundlessStackListDelegate extends BoundlessStackDelegate {
  BoundlessStackListDelegate._({
    required this.children,
     super.layerSorted,
    required super.childrenBuilder,
  });

  factory BoundlessStackListDelegate({
    bool layerSorted = false,
    required List<StackPosition> children,
  }) {
    return BoundlessStackListDelegate._(
      children: children,
      layerSorted: layerSorted,
      childrenBuilder:
          (ViewportOffset verticalOffset, ViewportOffset horizontalOffset) =>
              children,
    );
  }

  final List<StackPosition> children;
}
