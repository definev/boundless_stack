import 'dart:math';

import 'package:boxy/boxy.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

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

/// /Movable

class StackPositionData with EquatableMixin {
  const StackPositionData._({
    required this.id,
    required this.layer,
    required this.offset,
    this.keepAlive = false,
    this.width,
    this.preferredWidth,
    this.height,
    this.preferredHeight,
  });

  factory StackPositionData({
    String? id,
    required int layer,
    required Offset offset,
    double? width,
    double? preferredWidth,
    double? height,
    double? preferredHeight,
    bool keepAlive = false,
  }) {
    return StackPositionData._(
      id: id ?? UniqueKey().toString(),
      layer: layer,
      offset: offset,
      width: width,
      preferredWidth: preferredWidth,
      height: height,
      preferredHeight: preferredHeight,
      keepAlive: keepAlive,
    );
  }

  final String id;
  final int layer;
  final Offset offset;

  final double? width;
  final double? preferredWidth;
  final double? height;
  final double? preferredHeight;

  final bool keepAlive;

  @override
  List<Object?> get props => [
        id,
        layer,
        offset,
        width,
        height,
        preferredWidth,
        preferredHeight,
        keepAlive
      ];

  Offset calculateScaledOffset(double scaleFactor) => offset * scaleFactor;

  StackPositionData copyWith({
    int? layer,
    Offset? offset,
    double? width,
    double? preferredWidth,
    double? height,
    double? preferredHeight,
    bool? keepAlive,
  }) {
    return StackPositionData(
      id: id,
      layer: layer ?? this.layer,
      offset: offset ?? this.offset,
      width: width ?? this.width,
      preferredWidth: preferredWidth ?? this.preferredWidth,
      height: height ?? this.height,
      preferredHeight: preferredHeight ?? this.preferredHeight,
      keepAlive: keepAlive ?? this.keepAlive,
    );
  }

  @override
  String toString() => 'StackPositionData(id: $id, layer: $layer, offset: $offset, width: $width, height: $height, preferredWidth: $preferredWidth, preferredHeight: $preferredHeight, keepAlive: $keepAlive)';
}

typedef StackPositionWidgetBuilder = Widget Function(
  BuildContext context,
  ValueNotifier<StackPositionData> notifier,
  Widget? child,
);

class StackPosition extends StatefulWidget {
  const StackPosition._({
    super.key,
    required this.scaleFactor,
    required this.data,
    required this.builder,
    required this.child,
    this.onDataUpdated,
    this.moveable,
    this.resizable,
  });

  factory StackPosition({
    required GlobalKey key,
    required StackPositionData data,
    required StackPositionWidgetBuilder builder,
    required double scaleFactor,
    void Function(StackPositionData newValue)? onDataUpdated,
    StackMove? moveable,
    StackResize? resizable,
    Widget? child,
  }) {
    return StackPosition._(
      key: key,
      data: data,
      onDataUpdated: onDataUpdated,
      builder: builder,
      scaleFactor: scaleFactor,
      moveable: moveable,
      resizable: resizable,
      child: child,
    );
  }

  final double scaleFactor;
  final StackPositionData data;
  final void Function(StackPositionData newValue)? onDataUpdated;
  final StackPositionWidgetBuilder builder;
  final Widget? child;
  final StackMove? moveable;
  final StackResize? resizable;

  _StackPositionState? get state =>
      (key as GlobalKey).currentState as _StackPositionState?;

  @override
  State<StackPosition> createState() => _StackPositionState();
}

class _StackPositionState extends State<StackPosition>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => notifier.value.keepAlive;

  late var notifier = ValueNotifier<StackPositionData>(widget.data);

  Offset initialLocalPosition = Offset.zero;
  Offset initialOffset = Offset.zero;

  void onDataUpdated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataUpdated?.call(notifier.value);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.onDataUpdated != null) notifier.addListener(onDataUpdated);
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.onDataUpdated != null) notifier.removeListener(onDataUpdated);
  }

  @override
  void didUpdateWidget(covariant StackPosition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      notifier.value = widget.data.copyWith(
        keepAlive: notifier.value.keepAlive,
      );
    }
    if (widget.onDataUpdated != oldWidget.onDataUpdated) {
      if (oldWidget.onDataUpdated != null) {
        notifier.removeListener(onDataUpdated);
      }
      if (widget.onDataUpdated != null) {
        notifier.addListener(onDataUpdated);
      }
    }
  }

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
        if (widget.data.keepAlive == false) {
          notifier.value = notifier.value.copyWith(keepAlive: false);
        }
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
        widget.onDataUpdated?.call(newValue);
      },
      child: child,
    );
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
            scaleFactor: widget.scaleFactor,

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
            scaleFactor: widget.scaleFactor,

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
              scale: widget.scaleFactor,
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
