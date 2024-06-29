import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class StackSnap {
  const StackSnap({
    required this.snap,
    required this.heightSnap,
    required this.widthSnap,
  });

  final bool snap;
  final double heightSnap;
  final double widthSnap;
}

class StackMove {
  const StackMove({
    required this.enable,
    required this.snap,
  });

  final bool enable;
  final StackSnap? snap;
}

class StackPositionData with EquatableMixin {
  const StackPositionData({
    required this.layer,
    required this.offset,
    this.width,
    this.height,
  });

  final int layer;
  final Offset offset;

  final double? width;
  final double? height;

  @override
  List<Object?> get props => [layer, offset, width, height];

  Offset calculateScaledOffset(double scaleFactor) =>
      Offset(offset.dx * scaleFactor, offset.dy * scaleFactor);

  StackPositionData copyWith({
    int? layer,
    Offset? offset,
    double? width,
    double? height,
  }) {
    return StackPositionData(
      layer: layer ?? this.layer,
      offset: offset ?? this.offset,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
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
    this.moveable = const StackMove(enable: false, snap: null),
  });

  factory StackPosition({
    required GlobalKey key,
    required StackPositionData data,
    required StackPositionWidgetBuilder builder,
    required double scaleFactor,
    StackMove? moveable,
    Widget? child,
  }) {
    return StackPosition._(
      key: key,
      data: data,
      builder: builder,
      scaleFactor: scaleFactor,
      moveable: moveable ?? const StackMove(enable: false, snap: null),
      child: child,
    );
  }

  final double scaleFactor;
  final StackPositionData data;
  final StackPositionWidgetBuilder builder;
  final Widget? child;
  final StackMove moveable;

  _StackPositionState? get state =>
      (key as GlobalKey).currentState as _StackPositionState?;

  @override
  State<StackPosition> createState() => _StackPositionState();
}

class _StackPositionState extends State<StackPosition> {
  late var notifier = ValueNotifier<StackPositionData>(widget.data);

  Offset initialLocalPosition = Offset.zero;
  Offset initialOffset = Offset.zero;

  @override
  void dispose() {
    super.dispose();
    notifier.dispose();
  }

  @override
  void didUpdateWidget(covariant StackPosition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      notifier.value = widget.data;
    }
  }

  Widget moveable({
    required Widget child,
  }) {
    return GestureDetector(
      onPanStart: (details) {
        initialLocalPosition = details.localPosition;
        initialOffset = notifier.value.offset;
      },
      onPanUpdate: (details) {
        final delta = details.localPosition - initialLocalPosition;
        if (widget.moveable.snap case final snap?) {
          final snapOffset = Offset(
            snap.snap
                ? (delta.dx / snap.widthSnap).round() * snap.widthSnap
                : delta.dx,
            snap.snap
                ? (delta.dy / snap.heightSnap).round() * snap.heightSnap
                : delta.dy,
          );
          notifier.value = notifier.value.copyWith(
            offset: initialOffset + snapOffset,
          );
        } else {
          notifier.value = notifier.value.copyWith(
            offset: initialOffset + delta,
          );
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: notifier.value.height ?? constraints.maxHeight,
          width: notifier.value.width ?? constraints.maxWidth,
          child: Transform.scale(
            transformHitTests: true,
            scale: widget.scaleFactor,
            alignment: Alignment.topLeft,
            child: switch (widget.moveable.enable) {
              false => widget.builder(context, notifier, widget.child),
              true => moveable(
                  child: widget.builder(context, notifier, widget.child),
                ),
            },
          ),
        ),
      ),
    );
  }
}
