import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZoomStackGestureController {
  ZoomStackGestureController({required this.scaleFactor});

  final ValueNotifier<double> scaleFactor;

  late BoundlessStack stack;
  double? _scaleStart;
  Offset referencefocalOriginal = Offset.zero;

  void init(BoundlessStack stack) {
    this.stack = stack;
  }

  Offset get topLeft {
    return Offset(
      stack.horizontalDetails.controller!.offset,
      stack.verticalDetails.controller!.offset,
    );
  }

  void move(Offset offset) {
    final topLeft = this.topLeft;
    stack.horizontalDetails.controller!.jumpTo(topLeft.dx + offset.dx);
    stack.verticalDetails.controller!.jumpTo(topLeft.dy + offset.dy);
  }

  Offset toViewportOffsetOriginal(Offset focalPoint, double scaleFactor) {
    return (topLeft + focalPoint) / scaleFactor;
  }

  void updateScaleFactor(double scaleFactor) {
    final stackRenderBox =
        (stack.key as GlobalKey<BoundlessStackState>).currentContext!
                .findRenderObject()
            as RenderBox;

    final center = stackRenderBox.size.center(Offset.zero);
    onScaleStart(ScaleStartDetails(focalPoint: center));
    onScaleUpdate(ScaleUpdateDetails(scale: scaleFactor, focalPoint: center));
    onScaleEnd(ScaleEndDetails());
  }

  void onScaleStart(ScaleStartDetails details) {
    _scaleStart = scaleFactor.value;
    referencefocalOriginal = toViewportOffsetOriginal(
      details.localFocalPoint,
      scaleFactor.value,
    );
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_scaleStart == null) return;
    var desiredScale = _scaleStart! * details.scale;
    if (desiredScale < 1.0 && desiredScale > 0.99) desiredScale = 1.0;
    if (desiredScale >= 1.0) desiredScale = 1.0;
    scaleFactor.value = desiredScale;

    final scaledfocalPointOriginal = toViewportOffsetOriginal(
      details.localFocalPoint,
      desiredScale,
    );
    move((referencefocalOriginal - scaledfocalPointOriginal) * desiredScale);
  }

  void onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
  }

  void onScaleByMouseWheel(
    PointerScrollEvent event, {
    VoidCallback? onScaleStart,
    VoidCallback? onScaleEnd,
  }) {
    const scaleSensitivity = 0.01;
    final delta = event.scrollDelta;

    double scaleAction = math.exp(-delta.dy * scaleSensitivity);
    scaleAction = scaleAction.clamp(0.8, 1.3);

    log('Scale start by scroll wheel');
    onScaleStart?.call();
    this.onScaleStart(
      ScaleStartDetails(
        focalPoint: event.position,
        localFocalPoint: event.localPosition,
      ),
    );
    onScaleUpdate(
      ScaleUpdateDetails(
        scale: scaleAction,
        focalPoint: event.localPosition,
        localFocalPoint: event.localPosition,
      ),
    );
    this.onScaleEnd(ScaleEndDetails());
    onScaleEnd?.call();
  }
}

class ZoomStackGestureDetector extends StatefulWidget {
  const ZoomStackGestureDetector({
    super.key,
    required this.controller,
    this.supportedDevices = const {...PointerDeviceKind.values},
    required this.stack,
    this.onScaleStart,
    this.onScaleEnd,
  });

  final ZoomStackGestureController controller;
  final BoundlessStack stack;
  final VoidCallback? onScaleStart;
  final VoidCallback? onScaleEnd;
  final Set<PointerDeviceKind> supportedDevices;

  @override
  State<ZoomStackGestureDetector> createState() =>
      _ZoomStackGestureDetectorState();
}

class _ZoomStackGestureDetectorState extends State<ZoomStackGestureDetector>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final _scaleAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.decelerate)).animate(_animationController);

  late ValueNotifier<double> scaleFactor = widget.controller.scaleFactor;

  late final ZoomStackGestureController _controller = widget.controller
    ..init(stack);

  BoundlessStack get stack => widget.stack;

  late final ScaleGestureRecognizer _scaleGestureRecognizer =
      ScaleGestureRecognizer()
        ..onStart = (details) {
          widget.onScaleStart?.call();
          _controller.onScaleStart(details);
        }
        ..onUpdate = (details) {
          _controller.onScaleUpdate(details);
        }
        ..onEnd = (details) {
          widget.onScaleEnd?.call();
          _controller.onScaleEnd(details);
        }
        ..supportedDevices = {PointerDeviceKind.trackpad};

  bool _isControlPressed = false;

  bool onKeyPressed(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isControlPressed = true;
        setState(() {});
      }
    }
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isControlPressed = false;
        setState(() {});
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(onKeyPressed);
  }

  @override
  void dispose() {
    super.dispose();
    HardwareKeyboard.instance.removeHandler(onKeyPressed);
    _animationController.dispose();
    _scaleGestureRecognizer.dispose();
    _zoomAnimationListener = null;
    _zoomAnimationTimer?.cancel();
  }

  VoidCallback? _zoomAnimationListener;
  Timer? _zoomAnimationTimer;

  @override
  Widget build(BuildContext context) {
    assert(
      stack.horizontalDetails.controller != null,
      'Horizontal controller is null',
    );
    assert(
      stack.verticalDetails.controller != null,
      'Vertical controller is null',
    );

    return Listener(
      onPointerDown: _scaleGestureRecognizer.addPointer,
      onPointerPanZoomStart: _scaleGestureRecognizer.addPointerPanZoom,
      onPointerSignal: switch (kIsWasm || kIsWeb) {
        true => (event) {
          switch (event) {
            /// This event from web only
            case PointerScaleEvent():
              widget.onScaleStart?.call();
              _controller.onScaleStart(
                ScaleStartDetails(localFocalPoint: event.localPosition),
              );
              _controller.onScaleUpdate(
                ScaleUpdateDetails(
                  scale: event.scale,
                  focalPoint: event.position,
                  localFocalPoint: event.localPosition,
                ),
              );
              _controller.onScaleEnd(ScaleEndDetails());
              widget.onScaleEnd?.call();
            case PointerScrollEvent():
              if (event.kind == PointerDeviceKind.mouse && _isControlPressed) {
                _controller.onScaleByMouseWheel(event);
              } else if (event.kind == PointerDeviceKind.mouse) {
                if (HardwareKeyboard.instance.isShiftPressed) {
                  _controller.move(
                    Offset(event.scrollDelta.dx, -event.scrollDelta.dx),
                  );
                }
              }
          }
        },
        _ => (event) {
          switch (event) {
            case PointerScrollEvent():
              if (event.kind == PointerDeviceKind.mouse && _isControlPressed) {
                _controller.onScaleByMouseWheel(event);
              }
          }
        },
      },
      child: IgnorePointer(
        ignoring: _isControlPressed,
        child: RawGestureDetector(
          gestures: {
            // SerialTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            //         SerialTapGestureRecognizer>(
            //     SerialTapGestureRecognizer.new,
            //     (instance) =>
            //         instance.onSerialTapDown = (SerialTapDownDetails details) {
            //           if (_zoomAnimationListener != null) {
            //             _animationController.stop();
            //             _animationController
            //                 .removeListener(_zoomAnimationListener!);
            //             _animationController.reset();
            //             _zoomAnimationListener = null;
            //             _zoomAnimationTimer?.cancel();
            //           }

            //           if (details.count == 2) {
            //             widget.onScaleStart?.call();
            //             _controller.onScaleStart(ScaleStartDetails(
            //               focalPoint: details.globalPosition,
            //               localFocalPoint: details.localPosition,
            //             ));

            //             _zoomAnimationListener = () {
            //               if (_animationController.isCompleted) {
            //                 _controller.onScaleEnd(ScaleEndDetails());
            //                 widget.onScaleEnd?.call();
            //               } else {
            //                 _controller.onScaleUpdate(ScaleUpdateDetails(
            //                   scale: 1 + _scaleAnimation.value * 0.8,
            //                   focalPoint: details.globalPosition,
            //                   localFocalPoint: details.localPosition,
            //                 ));
            //               }
            //             };

            //             _animationController
            //                 .addListener(_zoomAnimationListener!);

            //             _zoomAnimationTimer = Timer(
            //               const Duration(milliseconds: 100),
            //               () => _animationController.forward(),
            //             );
            //           }
            //           if (details.count == 3) {
            //             widget.onScaleStart?.call();
            //             _controller.onScaleStart(ScaleStartDetails(
            //               focalPoint: details.globalPosition,
            //               localFocalPoint: details.localPosition,
            //             ));
            //             _zoomAnimationListener = () {
            //               if (_animationController.isCompleted) {
            //                 _controller.onScaleEnd(ScaleEndDetails());
            //                 widget.onScaleEnd?.call();
            //               } else {
            //                 _controller.onScaleUpdate(ScaleUpdateDetails(
            //                   scale: 1 - _scaleAnimation.value * 0.6,
            //                   focalPoint: details.globalPosition,
            //                   localFocalPoint: details.localPosition,
            //                 ));
            //               }
            //             };
            //             _animationController
            //                 .addListener(_zoomAnimationListener!);
            //             _animationController.forward();
            //           }
            //         }),
            ScaleGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                  () => ScaleGestureRecognizer(),
                  (ScaleGestureRecognizer instance) => instance
                    ..onStart = (details) {
                      widget.onScaleStart?.call();
                      _controller.onScaleStart(details);
                    }
                    ..onUpdate = (details) {
                      _controller.onScaleUpdate(details);
                    }
                    ..onEnd = (details) {
                      widget.onScaleEnd?.call();
                      _controller.onScaleEnd(details);
                    }
                    ..supportedDevices = ({...widget.supportedDevices}
                      ..remove(PointerDeviceKind.trackpad)),
                ),
          },
          child: ColoredBox(color: Colors.transparent, child: stack),
        ),
      ),
    );
  }
}
