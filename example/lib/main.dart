import 'dart:math';

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

  Random rand = Random();
  int sampleSize = 1000;

  late List<GlobalKey> globalKeys = [
    for (int index = 0; index < sampleSize; index += 1)
      GlobalKey(debugLabel: 'key_$index'),
  ];
  late List<StackPositionData> data = [
    for (int index = 0; index < sampleSize; index += 1)
      StackPositionData(
        layer: 0,
        offset: Offset(
          rand.nextDouble() * 30000,
          rand.nextDouble() * 30000,
        ),
        height: 200 + rand.nextDouble() * 300,
        width: 200 + rand.nextDouble() * 300,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ZoomStackGestureDetector(
        enableMoveByTouch: true,
        enableMoveByMouse: true,
        onScaleFactorChanged: (scaleFactor) =>
            setState(() => this.scaleFactor = scaleFactor),
        scaleFactor: scaleFactor,
        stack: (stackKey, scaleFactor) => BoundlessStack(
          key: stackKey,
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
              for (int index = 0; index < sampleSize; index += 1)
                StackPosition(
                  key: globalKeys[index],
                  data: data[index],
                  onDataUpdated: (value) => data[index] = value,
                  scaleFactor: scaleFactor,
                  moveable: const StackMove(),
                  builder: (context, notifier, child) => StackChild(
                    notifier: notifier,
                    child: child,
                  ),
                ),
            ],
          ),
          scaleFactor: scaleFactor,
        ),
      ),
    );
  }
}

class StackChild extends StatefulWidget {
  const StackChild({
    super.key,
    required this.notifier,
    this.child,
  });

  final ValueNotifier<StackPositionData> notifier;
  final Widget? child;

  @override
  State<StackChild> createState() => _StackChildState();
}

class _StackChildState extends State<StackChild>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boundless Stack'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) => ListTile(
          title: Text('Item $index'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final data = widget.notifier.value;
          widget.notifier.value = data.copyWith(
            offset: Offset(
              data.offset.dx + 100,
              data.offset.dy + 100,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
