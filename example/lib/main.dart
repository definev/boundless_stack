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
  ValueNotifier<double> scaleFactor = ValueNotifier(0.4);

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
  int sampleSize = 5000;

  late List<GlobalKey> globalKeys = [
    for (int index = 0; index < sampleSize; index += 1)
      GlobalKey(debugLabel: 'key_$index'),
  ];
  late List<ValueNotifier<StackPositionData>> data = [
    for (int index = 0; index < sampleSize; index += 1)
      ValueNotifier(
        StackPositionData(
          id: 'item_$index',
          layer: index % 50,
          offset: Offset(
            rand.nextDouble() * 100000,
            rand.nextDouble() * 100000,
          ),
          height: 200 + rand.nextDouble() * 300,
          width: 200 + rand.nextDouble() * 300,
        ),
      ),
  ];
  late List<StackPosition> children = [
    for (int index = 0; index < sampleSize; index += 1)
      StackPosition(
        key: globalKeys[index],
        notifier: data[index],
        scaleFactor: scaleFactor,
        moveable: const StackMove(
          snap: StackSnap.square(snap: 100),
        ),
        builder: (context, notifier, child) => MaterialSample(
          notifier: notifier,
          child: child,
        ),
      ),
  ]..sort((a, b) => a.notifier.value.layer.compareTo(b.notifier.value.layer));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: Colors.black),
        ),
        Positioned.fill(
          child: ZoomStackGestureDetector(
            controller: ZoomStackGestureController(scaleFactor: scaleFactor),
            stack: BoundlessStack(
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
                layerSorted: true,
                children: children,
              ),
              scaleFactor: scaleFactor,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 40,
              child: Material(
                color: Colors.transparent,
                child: ListenableBuilder(
                  listenable: scaleFactor,
                  builder: (context, child) => Slider(
                    value: scaleFactor.value,
                    onChanged: (value) => scaleFactor.value = value,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MaterialSample extends StatefulWidget {
  const MaterialSample({
    super.key,
    required this.notifier,
    this.child,
  });

  final ValueNotifier<StackPositionData> notifier;
  final Widget? child;

  @override
  State<MaterialSample> createState() => _MaterialSampleState();
}

class _MaterialSampleState extends State<MaterialSample>
    with AutomaticKeepAliveClientMixin {
  void _update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_update);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      color: switch (widget.notifier.value.layer) {
        0 => Colors.red,
        1 => Colors.blue,
        2 => Colors.green,
        3 => Colors.yellow,
        4 => Colors.purple,
        5 => Colors.orange,
        6 => Colors.pink,
        7 => Colors.brown,
        8 => Colors.grey,
        9 => Colors.teal,
        10 => Colors.indigo,
        11 => Colors.lime,
        12 => Colors.cyan,
        13 => Colors.amber,
        14 => Colors.deepPurple,
        15 => Colors.deepOrange,
        16 => Colors.lightBlue,
        17 => Colors.lightGreen,
        _ => Colors.white,
      },
      child: const Center(
        child: Text(
          'Hello, World!',
          style: TextStyle(
            fontSize: 20,
            decoration: TextDecoration.none,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}
