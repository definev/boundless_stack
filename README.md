## Boundless Stack: A Flutter Package for Infinite Scrolling with Scalable Content

**Boundless Stack** is a Flutter package that enables seamless scrolling and scaling of content within a two-dimensional space. Imagine a canvas where you can scroll endlessly in all directions, zoom in and out, and arrange items with layers and movement. This package provides the foundation for creating infinite scrolling experiences for brainstorming, data visualization, interactive maps, and more.

### Features

* **Infinite Scrolling:** Boundless Stack offers an infinite two-dimensional scrolling area for your widgets. Users can explore content in all directions without constraints. 
* **Zoom Functionality:** Allows users to scale the content displayed on the canvas by zooming in and out, providing flexibility for exploring details or getting a broader perspective.
* **Layer Support:** Easily position widgets on different layers to create visual depth and a sense of hierarchy within your application.
* **Movement:** The package enables drag-and-drop interactions with the widgets, allowing users to reposition them across the infinite canvas. 
* **Background Customization:** Users can add custom backgrounds (using the `backgroundBuilder` property) to create a visually appealing environment for their content.

### Installation

To use Boundless Stack in your Flutter project, follow these steps:

1. **Add the dependency:** In your `pubspec.yaml`, add the following line under `dependencies`: 
    ```yaml
    boundless_stack: ^0.0.1 
    ```
2. **Run `pub get` to fetch the package.**

### Usage

Here's a simple example to illustrate how to implement Boundless Stack:

```dart
import 'package:boundless_stack/boundless_stack.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ValueNotifier<double> _scaleFactor = ValueNotifier(1.0);
  final List<StackPositionData> _data = [
    for (int index = 0; index < 10; index += 1)
      StackPositionData(
        id: 'item_$index',
        layer: index,
        offset: Offset(index * 200.0, index * 200.0),
        height: 200,
        width: 200,
      )
  ];

  late List<GlobalKey> _globalKeys = [
    for (int index = 0; index < 10; index += 1)
      GlobalKey(debugLabel: 'key_$index'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ZoomStackGestureDetector(
        enableMoveByTouch: true,
        enableMoveByMouse: true,
        scaleFactor: _scaleFactor,
        onScaleFactorChanged: (scaleFactor) =>
            setState(() => _data = _data.map((data) {
                  return data.copyWith(
                    width: data.width! * scaleFactor,
                    height: data.height! * scaleFactor,
                  );
                }).toList()),
        stack: (stackKey, scaleFactor) => BoundlessStack(
          key: stackKey,
          cacheExtent: 0,
          backgroundBuilder: gridBackgroundBuilder(
            gridThickness: 1.0,
            gridWidth: 100,
            gridHeight: 100,
            gridColor: Colors.green,
            scaleFactor: scaleFactor,
          ),
          horizontalDetails: ScrollableDetails.horizontal(),
          verticalDetails: ScrollableDetails.vertical(),
          delegate: BoundlessStackListDelegate(
            children: [
              for (int index = 0; index < 10; index += 1)
                StackPosition(
                  key: _globalKeys[index],
                  notifier: ValueNotifier(_data[index]),
                  scaleFactor: scaleFactor,
                  moveable: StackMove(
                      snap: StackSnap.square(snap: 50.0)), // Snap to grid
                  builder: (context, notifier, child) => Container(
                    key: _globalKeys[index],
                    height: 200,
                    width: 200,
                    color: Colors.red,
                    child: Center(
                      child: Text('Item $index'),
                    ),
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
```

In this example:

1. We define a `ValueNotifier` for the scale factor to control the zoom level.
2. A list of `StackPositionData` is generated to hold the data for each element (layer, position, and size). 
3. We use `StackPosition` with a `StackMove` to enable the ability to drag elements around the canvas.
4. We use `gridBackgroundBuilder` to create a grid background.

**Important:** You can use any Flutter widget inside a `StackPosition` to represent the content of each item within the `BoundlessStack`.

### Configuration

* **`backgroundBuilder`:** Allows you to define a custom background builder to render content behind the stack. It receives the current horizontal and vertical viewport offsets and returns a Flutter widget. (See the example for using the `gridBackgroundBuilder`). 
* **`foregroundBuilder`:** This works like `backgroundBuilder`, but renders a widget on top of the stack content.
* **`cacheExtent`:** Controls the number of items around the current viewport position to pre-render (similar to the `cacheExtent` in a regular `ListView`). Defaults to `0`.
* **`scaleFactor`:** This double value controls the initial zoom level.
* **`horizontalDetails` and `verticalDetails`:** Allow users to define more complex behaviours for scrolling using `AxisDirection`, `ScrollPhysics`, `ScrollController`, etc.
* **`diagonalDragBehavior`:** Enables or restricts diagonal movement (default `DiagonalDragBehavior.free`).
* **`moveable`:** Use a `StackMove` with a `StackSnap` to implement snap-to-grid functionality for item movements.
* **`resizable`:** This property controls the resizing ability of individual stack items.

### Documentation

For more detailed documentation, please refer to:

* [API Documentation](doc/API.md): Comprehensive API reference for all classes and methods.
* [Architecture](doc/ARCHITECTURE.md): Detailed explanation of the internal architecture and design decisions.

### Contribution Guidelines

Contributions to Boundless Stack are welcomed. Here's how you can contribute:

1. **Fork the repository.**
2. **Create a branch for your feature.**
3. **Write your code and tests.**
4. **Open a Pull Request.**

For detailed contribution guidelines and code style recommendations, please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file (which should be included in the repository if you are accepting contributions). 

### Testing Instructions

The package includes unit and integration tests within the `example` module:

* **Run the example application:** `flutter run -d web --target=example/web` (or use your desired platform) to view the example code.
* **Execute unit tests:**  `flutter test` from the project root.

### License

Boundless Stack is released under the MIT License. See the [LICENSE](LICENSE) file for more information. 

### Acknowledgements and Credits

* **Flutter:** [https://flutter.dev](https://flutter.dev)
* **Boxy:** [https://pub.dev/packages/boxy](https://pub.dev/packages/boxy)
* **Dart Mappable:** [https://pub.dev/packages/dart_mappable](https://pub.dev/packages/dart_mappable)