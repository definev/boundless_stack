/// A Flutter package that enables seamless scrolling and scaling of content
/// within a two-dimensional space.
///
/// Boundless Stack provides an infinite canvas where you can scroll endlessly
/// in all directions, zoom in and out, and arrange items with layers and movement.
///
/// ## Features
///
/// * **Infinite Scrolling:** Boundless Stack offers an infinite two-dimensional
///   scrolling area for your widgets.
/// * **Zoom Functionality:** Allows users to scale the content displayed on the
///   canvas by zooming in and out.
/// * **Layer Support:** Easily position widgets on different layers to create
///   visual depth and hierarchy.
/// * **Movement:** The package enables drag-and-drop interactions with the widgets.
/// * **Background Customization:** Add custom backgrounds to create a visually
///   appealing environment.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:boundless_stack/boundless_stack.dart';
/// import 'package:flutter/material.dart';
///
/// void main() {
///   runApp(const MyApp());
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return const MaterialApp(
///       home: HomeView(),
///     );
///   }
/// }
///
/// class HomeView extends StatefulWidget {
///   const HomeView({super.key});
///
///   @override
///   State<HomeView> createState() => _HomeViewState();
/// }
///
/// class _HomeViewState extends State<HomeView> {
///   final ValueNotifier<double> _scaleFactor = ValueNotifier(1.0);
///   final List<StackPositionData> _data = [
///     for (int index = 0; index < 10; index += 1)
///       StackPositionData(
///         id: 'item_$index',
///         layer: index,
///         offset: Offset(index * 200.0, index * 200.0),
///         height: 200,
///         width: 200,
///       )
///   ];
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: ZoomStackGestureDetector(
///         scaleFactor: _scaleFactor,
///         stack: (stackKey, scaleFactor) => BoundlessStack(
///           key: stackKey,
///           scaleFactor: scaleFactor,
///           backgroundBuilder: gridBackgroundBuilder(
///             gridThickness: 1.0,
///             gridWidth: 100,
///             gridHeight: 100,
///             gridColor: Colors.grey,
///             scaleFactor: scaleFactor,
///           ),
///           delegate: BoundlessStackListDelegate(
///             children: [
///               for (int index = 0; index < 10; index += 1)
///                 StackPosition(
///                   key: GlobalKey(),
///                   scaleFactor: scaleFactor,
///                   notifier: ValueNotifier(_data[index]),
///                   moveable: StackMove(
///                     snap: StackSnap.square(snap: 50.0),
///                   ),
///                   builder: (context, notifier, child) => Container(
///                     height: 200,
///                     width: 200,
///                     color: Colors.red,
///                     child: Center(
///                       child: Text('Item $index'),
///                     ),
///                   ),
///                 ),
///             ],
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
library boundless_stack;

// Core components
export 'src/core/boundless_stack.dart';
export 'src/core/boundless_stack_delegate.dart';
export 'src/core/stack_position.dart';

// Gesture handling
export 'src/gestures/zoom_stack_gesture_detector.dart';

// Background builders
export 'src/backgrounds/grid.dart';