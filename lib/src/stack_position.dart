import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

part 'stack_position.mapper.dart';

class StackResize {
  const StackResize({
    required this.width,
    required this.preferredWidth,
    required this.height,
    required this.preferredHeight,
    this.preferredOverFixedSize = false,
    this.thumb,
    this.onSizeChanged,
  });

  final bool preferredOverFixedSize;

  /// The width of the widget
  final double? width;

  /// The preferred width of the widget
  final double? preferredWidth;

  /// The height of the widget
  final double? height;

  /// The preferred height of the widget
  final double? preferredHeight;

  /// This will be the thumb widget that will be used to resize the widget
  final Widget? thumb;

  /// This will call when the size is changed by user action
  ///
  /// So it update the notifier already dont need to call notifier.value = newValue
  final ValueChanged<Size>? onSizeChanged;
}

/// Movable
class StackSnap {
  const StackSnap({
    required this.heightSnap,
    required this.widthSnap,
  });

  factory StackSnap.square({
    required double snap,
  }) =>
      StackSnap(
        heightSnap: snap,
        widthSnap: snap,
      );

  final double heightSnap;
  final double widthSnap;
}

class StackMove {
  const StackMove({this.snap});

  final StackSnap? snap;
}

@MappableClass()
class StackPositionData with StackPositionDataMappable {
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

  final String id;
  final int layer;
  final Offset offset;

  final double? width;
  final double? preferredWidth;
  final double? height;
  final double? preferredHeight;

  final bool keepAlive;

  Offset calculateScaledOffset(double scaleFactor) => offset * scaleFactor;
}

typedef StackPositionWidgetBuilder = Widget Function(
  BuildContext context,
  ValueNotifier<StackPositionData> notifier,
  Widget? child,
);

class StackPosition extends StatefulWidget {
  const StackPosition({
    super.key,
    required this.scaleFactor,
    this.moveable,
    this.resizable,
    required this.notifier,
    required this.builder,
    this.child,
  });

  final ValueNotifier<double> scaleFactor;
  final StackMove? moveable;
  final StackResize? resizable;
  final ValueNotifier<StackPositionData> notifier;
  final StackPositionWidgetBuilder builder;
  final Widget? child;

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
            offset: snapInitialOffset + snapOffset,
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
