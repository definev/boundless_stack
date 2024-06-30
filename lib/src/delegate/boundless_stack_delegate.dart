import 'package:boundless_stack/src/data/stack_position.dart';
import 'package:boundless_stack/src/rendering/render_boundless_stack_viewport.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BoundlessStackDelegate extends TwoDimensionalChildDelegate {
  BoundlessStackDelegate({required this.childrenBuilder});

  final List<StackPosition> Function(
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) childrenBuilder;

  late RenderBoundlessStackViewport? _viewport;
  set viewport(RenderBoundlessStackViewport value) {
    _viewport = value;
  }

  double? scaleFactor;

  @override
  Widget? build(BuildContext context, covariant ChildVicinity vicinity) {
    if (vicinity == const ChildVicinity(xIndex: 0, yIndex: 0)) {
      return const SizedBox();
    }
    if (_viewport == null) return null;
    return _viewport?.childWidgets![vicinity];
  }

  @override
  bool shouldRebuild(BoundlessStackDelegate oldDelegate) =>
      scaleFactor != oldDelegate.scaleFactor ||
      childrenBuilder != oldDelegate.childrenBuilder;
}

class BoundlessStackListDelegate extends BoundlessStackDelegate {
  BoundlessStackListDelegate._({
    required this.children,
    required super.childrenBuilder,
  });

  factory BoundlessStackListDelegate({
    required List<StackPosition> children,
  }) {
    return BoundlessStackListDelegate._(
      children: children,
      childrenBuilder:
          (ViewportOffset verticalOffset, ViewportOffset horizontalOffset) =>
              children,
    );
  }

  final List<StackPosition> children;
}
