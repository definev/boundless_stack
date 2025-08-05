import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

part 'stack_position.mapper.dart';

/// Configuration for resizing a [StackPosition] widget.
///
/// This class defines how a stack position can be resized, including its
/// dimensions, resize handle appearance, and callbacks.
class StackResize {
  /// Creates a stack resize configuration.
  ///
  /// The [width], [preferredWidth], [height], and [preferredHeight] parameters
  /// define the dimensions of the widget.
  const StackResize({
    required this.width,
    required this.preferredWidth,
    required this.height,
    required this.preferredHeight,
    this.preferredOverFixedSize = false,
    this.thumb,
    this.onSizeChanged,
  });

  /// Whether to prioritize preferred size over fixed size.
  ///
  /// When true, preferred dimensions take precedence over fixed dimensions.
  final bool preferredOverFixedSize;

  /// The fixed width of the widget.
  ///
  /// If null, the widget will use [preferredWidth] or its natural width.
  final double? width;

  /// The preferred width of the widget.
  ///
  /// Used when [width] is null or [preferredOverFixedSize] is true.
  final double? preferredWidth;

  /// The fixed height of the widget.
  ///
  /// If null, the widget will use [preferredHeight] or its natural height.
  final double? height;

  /// The preferred height of the widget.
  ///
  /// Used when [height] is null or [preferredOverFixedSize] is true.
  final double? preferredHeight;

  /// The widget to use as a resize handle.
  ///
  /// This widget will be positioned at the bottom-right corner of the stack position.
  final Widget? thumb;

  /// Callback that is called when the size is changed by user interaction.
  ///
  /// The notifier is already updated, so there's no need to update it manually.
  final ValueChanged<Size>? onSizeChanged;
}

/// Configuration for snapping a [StackPosition] to a grid.
///
/// This class defines the grid dimensions for snapping during movement.
class StackSnap {
  /// Creates a stack snap configuration with separate horizontal and vertical snapping.
  ///
  /// The [heightSnap] and [widthSnap] parameters define the grid cell dimensions.
  const StackSnap({
    required this.heightSnap,
    required this.widthSnap,
    this.offset = Offset.zero,
  });

  /// Creates a stack snap configuration with equal horizontal and vertical snapping.
  ///
  /// The [snap] parameter defines the grid cell size for both dimensions.
  const factory StackSnap.square({
    required double snap,
    Offset offset,
  }) = _StackSnapSquare;

  /// The vertical grid cell size for snapping.
  final double heightSnap;

  /// The horizontal grid cell size for snapping.
  final double widthSnap;

  /// The offset for calibrate cell position
  final Offset offset;
}

class _StackSnapSquare extends StackSnap {
  const _StackSnapSquare({required double snap, Offset offset = Offset.zero})
      : super(
          heightSnap: snap,
          widthSnap: snap,
          offset: offset,
        );
}

/// Configuration for moving a [StackPosition] widget.
///
/// This class defines how a stack position can be moved, including optional
/// snap-to-grid behavior.
class StackMove {
  /// Creates a stack move configuration.
  ///
  /// The [snap] parameter defines optional snap-to-grid behavior.
  const StackMove({this.snap});

  /// Optional snap-to-grid configuration.
  ///
  /// When provided, the stack position will snap to a grid during movement.
  final StackSnap? snap;
}

/// Data class that holds position and size information for a [StackPosition].
///
/// This class is immutable and can be copied with new values using [copyWith].
@MappableClass()
class StackPositionData with StackPositionDataMappable {
  /// Creates a stack position data object.
  ///
  /// The [id], [layer], and [offset] parameters are required.
  const StackPositionData({
    required this.id,
    required this.layer,
    required this.offset,
    this.keepAlive = false,
    this.width,
    this.preferredWidth,
    this.height,
    this.preferredHeight,
  });

  /// Unique identifier for the stack position.
  final String id;

  /// Z-index layer for rendering order.
  ///
  /// Higher values are rendered on top of lower values.
  final int layer;

  /// Position in the 2D space.
  ///
  /// The offset is in world coordinates, not screen coordinates.
  final Offset offset;

  /// Fixed width of the stack position.
  ///
  /// If null, the widget will use [preferredWidth] or its natural width.
  final double? width;

  /// Preferred width of the stack position.
  ///
  /// Used when [width] is null or when preferred size takes precedence.
  final double? preferredWidth;

  /// Fixed height of the stack position.
  ///
  /// If null, the widget will use [preferredHeight] or its natural height.
  final double? height;

  /// Preferred height of the stack position.
  ///
  /// Used when [height] is null or when preferred size takes precedence.
  final double? preferredHeight;

  /// Whether to keep the widget alive when it's off-screen.
  ///
  /// When true, the widget will not be disposed when it's scrolled out of view.
  final bool keepAlive;

  /// Calculates the offset adjusted for the current scale factor.
  ///
  /// This is used for positioning the widget in the viewport.
  Offset calculateScaledOffset(double scaleFactor) => offset * scaleFactor;
}

/// Builder function for creating a widget for a [StackPosition].
///
/// The [context] is the build context, [notifier] is the position data notifier,
/// and [child] is an optional child widget.
typedef StackPositionWidgetBuilder = Widget Function(
  BuildContext context,
  ValueNotifier<StackPositionData> notifier,
  Widget? child,
);

/// A widget that represents a positioned item within a [BoundlessStack].
///
/// This widget handles positioning, movement, and resizing of items in the stack.
/// It can be configured to be moveable, resizable, and to snap to a grid.
///
/// ## Example
///
/// ```dart
/// StackPosition(
///   scaleFactor: scaleNotifier,
///   notifier: ValueNotifier(StackPositionData(
///     id: 'item1',
///     layer: 0,
///     offset: Offset(100, 100),
///   )),
///   moveable: StackMove(
///     snap: StackSnap.square(snap: 50.0),
///   ),
///   builder: (context, notifier, child) => Container(
///     width: 200,
///     height: 200,
///     color: Colors.red,
///     child: child,
///   ),
///   child: Text('Draggable Item'),
/// )
/// ```
class StackPosition extends StatefulWidget {
  /// Creates a stack position widget.
  ///
  /// The [scaleFactor], [notifier], and [builder] parameters are required.
  const StackPosition({
    super.key,
    required this.scaleFactor,
    this.moveable,
    this.resizable,
    required this.notifier,
    required this.builder,
    this.child,
  });

  /// The current scale factor of the parent stack.
  ///
  /// This is used to adjust the position and size of the widget.
  final ValueNotifier<double> scaleFactor;

  /// Configuration for movement behavior.
  ///
  /// When provided, the widget can be moved by dragging.
  final StackMove? moveable;

  /// Configuration for resize behavior.
  ///
  /// When provided, the widget can be resized using the resize handle.
  final StackResize? resizable;

  /// Notifier for the position data.
  ///
  /// This notifier is updated when the widget is moved or resized.
  final ValueNotifier<StackPositionData> notifier;

  /// Builder function for creating the widget.
  ///
  /// This function is called with the current context, position data notifier,
  /// and optional child widget.
  final StackPositionWidgetBuilder builder;

  /// Optional child widget.
  ///
  /// This widget is passed to the [builder] function.
  final Widget? child;

  /// Gets the current state of this widget.
  ///
  /// This is used by the parent stack to access the state.
  _StackPositionState? get state =>
      (key as GlobalKey).currentState as _StackPositionState?;

  @override
  State<StackPosition> createState() => _StackPositionState();
}

class _StackPositionState extends State<StackPosition>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => notifier.value.keepAlive;

  late var notifier = widget.notifier;

  StackPositionData get data => notifier.value;

  Offset initialLocalPosition = Offset.zero;
  Offset initialOffset = Offset.zero;

  Widget moveable({required Widget child}) {
    return GestureDetector(
      supportedDevices: {...PointerDeviceKind.values}
        ..remove(PointerDeviceKind.trackpad),
      onPanStart: (details) {
        initialLocalPosition = details.localPosition;
        initialOffset = notifier.value.offset;
        notifier.value = notifier.value.copyWith(keepAlive: true);
      },
      onPanEnd: (details) {
        notifier.value = notifier.value.copyWith(keepAlive: false);
      },
      onPanUpdate: (details) {
        StackPositionData newValue;
        final delta = details.localPosition - initialLocalPosition;
        if (widget.moveable?.snap case final snap?) {
          final snapInitialOffset = Offset(
            (initialOffset.dx / snap.widthSnap).round() * snap.widthSnap,
            (initialOffset.dy / snap.heightSnap).round() * snap.heightSnap,
          );
          final snapOffset = Offset(
            (delta.dx / snap.widthSnap).round() * snap.widthSnap,
            (delta.dy / snap.heightSnap).round() * snap.heightSnap,
          );

          newValue = notifier.value.copyWith(
            offset: snapInitialOffset + snapOffset - snap.offset,
          );
        } else {
          newValue = notifier.value.copyWith(
            offset: initialOffset + delta,
          );
        }

        notifier.value = newValue;
      },
      child: child,
    );
  }

  void _updateScaleFactor() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.scaleFactor.addListener(_updateScaleFactor);
  }

  @override
  void dispose() {
    widget.scaleFactor.removeListener(_updateScaleFactor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child = widget.builder(context, notifier, widget.child);
        if (widget.moveable != null) {
          child = moveable(child: child);
        }

        if (widget.resizable case final resizable?) {
          child = _ResizableStackPosition(
            notifier: notifier,
            scaleFactor: widget.scaleFactor.value,

            /// Constraints for the widget
            preferredOverFixedSize: resizable.preferredOverFixedSize,
            width: resizable.width,
            preferredWidth: resizable.preferredWidth,
            height: resizable.height,
            preferredHeight: resizable.preferredHeight,

            ///
            onSizeChanged: resizable.onSizeChanged,
            thumb: resizable.thumb,
            child: child,
          );
        } else {
          child = _ResizableStackPosition(
            notifier: notifier,
            scaleFactor: widget.scaleFactor.value,

            /// Constraints for the widget
            preferredOverFixedSize: true,
            width: notifier.value.width,
            preferredWidth: notifier.value.preferredWidth,
            height: notifier.value.height,
            preferredHeight: notifier.value.preferredHeight,

            /// This will call when the size is changed by user action
            thumb: null,
            onSizeChanged: null,
            child: child,
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: notifier.value.height ?? constraints.maxHeight,
            width: notifier.value.width ?? constraints.maxWidth,
            child: Transform.scale(
              transformHitTests: true,
              scale: widget.scaleFactor.value,
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ResizableStackPosition extends StatefulWidget {
  const _ResizableStackPosition({
    required this.notifier,
    required this.scaleFactor,
    required this.thumb,
    required this.child,
    required this.width,
    required this.preferredWidth,
    required this.height,
    required this.preferredHeight,
    required this.onSizeChanged,
    required this.preferredOverFixedSize,
  });

  final ValueNotifier<StackPositionData> notifier;
  final double scaleFactor;

  final bool preferredOverFixedSize;

  /// Constraints for the widget
  final double? width;
  final double? preferredWidth;
  final double? height;
  final double? preferredHeight;

  final Widget? thumb;
  final Widget child;
  final void Function(Size size)? onSizeChanged;

  @override
  State<_ResizableStackPosition> createState() =>
      _ResizableStackPositionState();
}

class _ResizableStackPositionState extends State<_ResizableStackPosition> {
  Size startSize = Size.zero;
  Offset startOffset = Offset.zero;

  StackPositionData get data => widget.notifier.value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: CustomBoxy(
        delegate: _ResizableStackPositionDelegate(
          onSizeChanged: (size) {
            bool usePreferredWidth =
                widget.width == null || widget.preferredOverFixedSize;
            bool usePreferredHeight =
                widget.height == null || widget.preferredOverFixedSize;

            double width = switch (usePreferredWidth) {
              true => widget.preferredWidth ?? size.width,
              false => widget.width ?? size.width,
            };
            double height = switch (usePreferredHeight) {
              true => size.height,
              false => widget.height ?? size.height,
            };

            WidgetsBinding.instance.addPostFrameCallback((_) {
              bool needUpdate = false;
              var newData = data.copyWith();
              if (usePreferredHeight) {
                if (newData.preferredHeight != height) {
                  newData = newData.copyWith(preferredHeight: height);
                  needUpdate = true;
                }
              } else {
                if (newData.height != height) {
                  newData = newData.copyWith(height: height);
                  needUpdate = true;
                }
              }
              if (usePreferredWidth) {
                if (newData.preferredWidth != width) {
                  newData = newData.copyWith(preferredWidth: width);
                  needUpdate = true;
                }
              } else {
                if (newData.width != width) {
                  newData = newData.copyWith(width: width);
                  needUpdate = true;
                }
              }
              if (needUpdate) {
                widget.notifier.value = newData;
              }
            });
          },
          thumbBuilder: switch (widget.thumb) {
            final thumb? => (size) {
                return GestureDetector(
                  supportedDevices: {...PointerDeviceKind.values}
                    ..remove(PointerDeviceKind.trackpad),
                  trackpadScrollCausesScale: false,
                  onPanStart: (details) {
                    startSize = Size(
                      widget.notifier.value.width ?? size.width,
                      widget.notifier.value.height ?? size.height,
                    );
                    startOffset = details.globalPosition;
                  },
                  onPanUpdate: (details) {
                    final delta = (details.globalPosition - startOffset) /
                        widget.scaleFactor;
                    double? newPreferredWidth =
                        max(100.0, startSize.width + delta.dx);

                    widget.notifier.value = widget.notifier.value.copyWith(
                      preferredWidth: newPreferredWidth,
                    );
                  },
                  child: thumb,
                );
              },
            null => null,
          },
        ),
        children: [
          BoxyId(
            id: #_child,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ResizableStackPositionDelegate extends BoxyDelegate {
  _ResizableStackPositionDelegate({
    required this.thumbBuilder,
    required this.onSizeChanged,
  });

  final void Function(Size size) onSizeChanged;
  final Widget Function(Size size)? thumbBuilder;

  @override
  Size layout() {
    var firstChild = getChild(#_child);

    var firstSize = firstChild.layout(constraints);
    firstChild.position(Offset.zero);

    if (thumbBuilder == null) {
      onSizeChanged(firstSize);
      return firstSize;
    }

    var child = Align(
      alignment: Alignment.bottomRight,
      child: thumbBuilder!(firstSize),
    );

    onSizeChanged(firstSize);

    // Inflate the text widget
    var secondChild = inflate(child, id: #second);

    var secondSize = secondChild.layout(
      constraints.tighten(
        height: firstSize.height,
        width: firstSize.width,
      ),
    );

    secondChild.position(Offset.zero);

    return Size(
      firstSize.width,
      firstSize.height + secondSize.height,
    );
  }
}
