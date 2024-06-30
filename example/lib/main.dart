import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey _stack0PositionKey = GlobalKey();

  Offset referencefocalOriginal = Offset.zero;
  double scaleFactor = 0.4;

  final ScrollableDetails _horizontalDetails = ScrollableDetails.horizontal(
    controller: ScrollController(
      initialScrollOffset: -100,
    ),
  );
  final ScrollableDetails _verticalDetails = ScrollableDetails.vertical(
    controller: ScrollController(
      initialScrollOffset: -100,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ZoomStackGestureDetector(
        onScaleFactorChanged: (scaleFactor) => setState(() => this.scaleFactor = scaleFactor),
        scaleFactor: scaleFactor,
        stack: (scaleFactor) => BoundlessStack(
          clipBehavior: Clip.none,
          cacheExtent: 0,
          backgroundBuilder: gridBackgroundBuilder(
            gridThickness: 1.0,
            gridWidth: 100,
            gridHeight: 100,
            gridColor: Colors.green,
            scaleFactor: scaleFactor,
          ),
          horizontalDetails: _horizontalDetails,
          verticalDetails: _verticalDetails,
          delegate: BoundlessStackListDelegate(
            children: [
              StackPosition(
                key: _stack0PositionKey,
                scaleFactor: scaleFactor,
                data: const StackPositionData(
                  layer: 0,
                  offset: Offset(400, 100),
                  height: 300,
                  width: 700,
                ),
                moveable: const StackMove(
                  enable: true,
                  snap: StackSnap(
                    heightSnap: 50,
                    widthSnap: 50,
                  ),
                ),
                builder: (context, notifier, child) {
                  return ColoredBox(
                    color: Colors.amber.shade50,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: FilledButton(
                            onPressed: () {
                              notifier.value = notifier.value.copyWith(
                                height: notifier.value.height! + 10,
                                width: notifier.value.width! + 10,
                              );
                            },
                            child: const Text('Top Left'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: FilledButton(
                            onPressed: () {
                              notifier.value = notifier.value.copyWith(
                                height: notifier.value.height! - 10,
                                width: notifier.value.width! - 10,
                              );
                            },
                            child: const Text('Bottom Right'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // StackPosition(
              //   key: _stack1PositionKey,
              //   scaleFactor: scaleFactor,
              //   data: const StackPositionData(
              //     layer: 0,
              //     offset: Offset(400, 500),
              //     height: 300,
              //     width: 700,
              //   ),
              //   moveable: const StackMove(
              //     enable: true,
              //     // snap: StackSnap(
              //     //   snap: true,
              //     //   heightSnap: 50,
              //     //   widthSnap: 50,
              //     // ),
              //   ),
              //   builder: (context, notifier, child) {
              //     return ColoredBox(
              //       color: Colors.amber.shade50,
              //       child: Stack(
              //         children: [
              //           Align(
              //             alignment: Alignment.topLeft,
              //             child: FilledButton(
              //               onPressed: () {
              //                 notifier.value = notifier.value.copyWith(
              //                   height: notifier.value.height! + 10,
              //                   width: notifier.value.width! + 10,
              //                 );
              //               },
              //               child: const Text('Top Left'),
              //             ),
              //           ),
              //           Align(
              //             alignment: Alignment.bottomRight,
              //             child: FilledButton(
              //               onPressed: () {
              //                 notifier.value = notifier.value.copyWith(
              //                   height: notifier.value.height! - 10,
              //                   width: notifier.value.width! - 10,
              //                 );
              //               },
              //               child: const Text('Bottom Right'),
              //             ),
              //           ),
              //         ],
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
          scaleFactor: scaleFactor,
        ),
      ),
    );
  }
}
