import 'dart:developer';
import 'dart:math' as math;

import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZoomStackGestureDetector extends StatefulWidget {
  const ZoomStackGestureDetector({
    super.key,
    required this.scaleFactor,
    this.supportedDevices = const {...PointerDeviceKind.values},
    required this.stack,
    this.onScaleStart,
    this.onScaleEnd,
  });

  final ValueNotifier<double> scaleFactor;
  final BoundlessStack Function(
    GlobalKey<BoundlessStackState> key,
    ValueNotifier<double> scaleFactor,
  ) stack;
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
  late final _scaleAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

  final GlobalKey<BoundlessStackState> _stackKey = GlobalKey();

  double? _scaleStart;
  Offset referencefocalOriginal = Offset.zero;

  late ValueNotifier<double> scaleFactor = widget.scaleFactor;

  BoundlessStack get stack => widget.stack(_stackKey, scaleFactor);

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

  void onScaleStart(ScaleStartDetails details) {
    _scaleStart = scaleFactor.value;
    referencefocalOriginal =
        toViewportOffsetOriginal(details.localFocalPoint, scaleFactor.value);
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    var desiredScale = _scaleStart! * details.scale;
    if (desiredScale < 1.0 && desiredScale > 0.99) desiredScale = 1.0;
    if (desiredScale >= 1.0) desiredScale = 1.0;
    scaleFactor.value = desiredScale;

    final scaledfocalPointOriginal =
        toViewportOffsetOriginal(details.localFocalPoint, desiredScale);
    move((referencefocalOriginal - scaledfocalPointOriginal) * desiredScale);
  }

  void onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
  }

  late final ScaleGestureRecognizer _scaleGestureRecognizer =
      ScaleGestureRecognizer()
        ..onStart = (details) {
          widget.onScaleStart?.call();
          onScaleStart(details);
        }
        ..onUpdate = (details) {
          onScaleUpdate(details);
        }
        ..onEnd = (details) {
          widget.onScaleEnd?.call();
          onScaleEnd(details);
        }
        ..supportedDevices = {PointerDeviceKind.trackpad};

  bool _isControlPressed = false;

  bool onKeyPressed(KeyEvent event) {
    if (_isControlPressed != HardwareKeyboard.instance.isControlPressed) {
      _isControlPressed = HardwareKeyboard.instance.isControlPressed;
      setState(() {});
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
  }

  @override
  void didUpdateWidget(covariant ZoomStackGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleFactor != widget.scaleFactor) {
      scaleFactor = widget.scaleFactor;
    }
  }

  VoidCallback? _zoomAnimationListener;

  @override
  Widget build(BuildContext context) {
    assert(stack.horizontalDetails.controller != null,
        'Horizontal controller is null');
    assert(stack.verticalDetails.controller != null,
        'Vertical controller is null');

    return Listener(
      onPointerDown: _scaleGestureRecognizer.addPointer,
      onPointerPanZoomStart: _scaleGestureRecognizer.addPointerPanZoom,
      onPointerSignal: switch (kIsWasm || kIsWeb) {
        true => (event) {
            switch (event) {
              /// This event from web only
              case PointerScaleEvent():
                log('Scale start by pointer');
                widget.onScaleStart?.call();
                onScaleStart(
                    ScaleStartDetails(localFocalPoint: event.localPosition));
                onScaleUpdate(
                  ScaleUpdateDetails(
                    scale: event.scale,
                    focalPoint: event.position,
                    localFocalPoint: event.localPosition,
                  ),
                );
                onScaleEnd(ScaleEndDetails());
                widget.onScaleEnd?.call();
              case PointerScrollEvent():
                if (event.kind == PointerDeviceKind.mouse &&
                    _isControlPressed) {
                  onScaleByMouseWheel(event);
                } else if (event.kind == PointerDeviceKind.mouse) {
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    move(Offset(event.scrollDelta.dx, -event.scrollDelta.dx));
                  }
                }
            }
          },
        _ => (event) {
            switch (event) {
              case PointerScrollEvent():
                if (event.kind == PointerDeviceKind.mouse &&
                    _isControlPressed) {
                  onScaleByMouseWheel(event);
                }
            }
          },
      },
      child: RawGestureDetector(
        gestures: {
          SerialTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  SerialTapGestureRecognizer>(
              SerialTapGestureRecognizer.new,
              (instance) =>
                  instance.onSerialTapDown = (SerialTapDownDetails details) {
                    if (_zoomAnimationListener != null) {
                      _animationController.stop();
                      _animationController
                          .removeListener(_zoomAnimationListener!);
                      _animationController.reset();
                      _zoomAnimationListener = null;
                    }

                    if (details.count == 2) {
                      widget.onScaleStart?.call();
                      onScaleStart(ScaleStartDetails(
                        focalPoint: details.globalPosition,
                        localFocalPoint: details.localPosition,
                      ));

                      _zoomAnimationListener = () {
                        if (_animationController.isCompleted) {
                          onScaleEnd(ScaleEndDetails());
                          widget.onScaleEnd?.call();
                        } else {
                          onScaleUpdate(ScaleUpdateDetails(
                            scale: 1 + _scaleAnimation.value * 0.8,
                            focalPoint: details.globalPosition,
                            localFocalPoint: details.localPosition,
                          ));
                        }
                      };

                      _animationController.addListener(_zoomAnimationListener!);
                      _animationController.forward();
                    }
                    if (details.count == 3) {
                      widget.onScaleStart?.call();
                      onScaleStart(ScaleStartDetails(
                        focalPoint: details.globalPosition,
                        localFocalPoint: details.localPosition,
                      ));
                      _zoomAnimationListener = () {
                        if (_animationController.isCompleted) {
                          onScaleEnd(ScaleEndDetails());
                          widget.onScaleEnd?.call();
                        } else {
                          onScaleUpdate(ScaleUpdateDetails(
                            scale: 1 - _scaleAnimation.value * 0.6,
                            focalPoint: details.globalPosition,
                            localFocalPoint: details.localPosition,
                          ));
                        }
                      };
                      _animationController.addListener(_zoomAnimationListener!);
                      _animationController.forward();
                    }
                  }),
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(),
            (ScaleGestureRecognizer instance) => instance
              ..onStart = (details) {
                widget.onScaleStart?.call();
                onScaleStart(details);
              }
              ..onUpdate = (details) {
                onScaleUpdate(details);
              }
              ..onEnd = (details) {
                widget.onScaleEnd?.call();
                onScaleEnd(details);
              }
              ..supportedDevices = ({...widget.supportedDevices}
                ..remove(PointerDeviceKind.trackpad)),
          ),
        },
        child: ColoredBox(
          color: Colors.transparent,
          child: IgnorePointer(
            ignoring: _isControlPressed,
            child: stack,
          ),
        ),
      ),
    );
  }

  void onScaleByMouseWheel(PointerScrollEvent event) {
    const scaleSensitivity = 0.01;
    final delta = event.scrollDelta;

    double scaleAction = math.exp(-delta.dy * scaleSensitivity);
    scaleAction = scaleAction.clamp(0.8, 1.3);

    log('Scale start by scroll wheel');
    widget.onScaleStart?.call();
    onScaleStart(
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
    onScaleEnd(ScaleEndDetails());
    widget.onScaleEnd?.call();
  }
}
