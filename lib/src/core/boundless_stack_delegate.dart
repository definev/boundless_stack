import 'package:boundless_stack/src/core/render_boundless_stack_viewport.dart';
import 'package:flutter/rendering.dart' show ViewportOffset;
import 'package:flutter/widgets.dart';

import 'stack_position.dart';

/// Abstract base class for providing children to a [BoundlessStack].
///
/// This delegate is responsible for providing the children that will be displayed
/// in the stack. It also handles layer sorting and child positioning.
///
/// Subclasses must implement the [childrenBuilder] method to provide the children.
abstract class BoundlessStackDelegate extends TwoDimensionalChildDelegate {
  /// Creates a boundless stack delegate.
  ///
  /// The [childrenBuilder] parameter is required.
  BoundlessStackDelegate({
    required this.childrenBuilder,
    this.layerSorted = false,
  });

  /// Function that builds the children for the stack.
  ///
  /// This function is called with the current viewport to determine which
  /// children should be built.
  final List<StackPosition> Function(
    ViewportOffset horizontalOffset,
    ViewportOffset verticalOffset,
  ) childrenBuilder;

  /// Whether the children should be sorted by layer.
  ///
  /// When true, children with higher layer values are rendered on top of
  /// children with lower layer values.
  final bool layerSorted;

  /// The viewport that is currently being built.
  ///
  /// This is set by the [BoundlessStack] when the delegate is used.
  late RenderBoundlessStackViewport? _viewport;
  void bindViewport(RenderBoundlessStackViewport value) {
    _viewport = value;
  }
}

/// A delegate that provides a static list of children to a [BoundlessStack].
///
/// This delegate is useful when the children are known in advance and don't
/// change dynamically.
///
/// ## Example
///
/// ```dart
/// BoundlessStackListDelegate(
///   children: [
///     StackPosition(
///       notifier: ValueNotifier(StackPositionData(
///         id: 'item1',
///         layer: 0,
///         offset: Offset(100, 100),
///       )),
///       builder: (context, notifier, child) => Container(
///         width: 200,
///         height: 200,
///         color: Colors.red,
///       ),
///     ),
///     // ... more stack positions
///   ],
/// )
/// ```
class BoundlessStackListDelegate extends BoundlessStackDelegate {
  /// Creates a boundless stack list delegate.
  ///
  /// The [children] parameter is required.
  factory BoundlessStackListDelegate({
    bool layerSorted = false,
    required List<StackPosition> children,
  }) {
    return BoundlessStackListDelegate._(
      layerSorted: layerSorted,
      childrenBuilder: (_, __) => children,
    );
  }

  /// Internal constructor for creating a boundless stack list delegate.
  BoundlessStackListDelegate._({
    required super.layerSorted,
    required super.childrenBuilder,
  });

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
