# Boundless Stack API Documentation

## Overview

Boundless Stack is a Flutter package that provides infinite scrolling and scaling capabilities in a two-dimensional space. This document provides comprehensive API documentation for all classes and methods.

## Core Classes

### BoundlessStack

The main widget that creates an infinite scrollable stack.

```dart
class BoundlessStack extends StatefulWidget {
  const BoundlessStack({
    Key? key,
    this.primary,
    this.mainAxis = Axis.vertical,
    this.verticalDetails = const ScrollableDetails.vertical(),
    this.horizontalDetails = const ScrollableDetails.horizontal(),
    required this.delegate,
    this.cacheExtent,
    this.diagonalDragBehavior = DiagonalDragBehavior.free,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    required this.scaleFactor,
    this.backgroundBuilder,
    this.foregroundBuilder,
  });
}
```

#### Properties

- **delegate** (`BoundlessStackDelegate`): Provides children for the stack
- **scaleFactor** (`ValueNotifier<double>`): Controls zoom level
- **backgroundBuilder** (`TwoDimensionalViewportBuilder?`): Custom background renderer
- **foregroundBuilder** (`TwoDimensionalViewportBuilder?`): Custom foreground renderer
- **cacheExtent** (`double?`): Number of items to pre-render around viewport
- **diagonalDragBehavior** (`DiagonalDragBehavior`): Controls diagonal scrolling behavior
- **verticalDetails** (`ScrollableDetails`): Vertical scrolling configuration
- **horizontalDetails** (`ScrollableDetails`): Horizontal scrolling configuration

#### Methods

- **overrideScrollBehavior()**: Temporarily disables scrolling (used during gestures)
- **restoreScrollBehavior()**: Restores original scroll behavior

### StackPosition

Represents a positioned widget within the boundless stack.

```dart
class StackPosition extends StatefulWidget {
  const StackPosition({
    Key? key,
    required this.scaleFactor,
    this.moveable,
    this.resizable,
    required this.notifier,
    required this.builder,
    this.child,
  });
}
```

#### Properties

- **scaleFactor** (`ValueNotifier<double>`): Current scale factor
- **moveable** (`StackMove?`): Movement configuration
- **resizable** (`StackResize?`): Resize configuration
- **notifier** (`ValueNotifier<StackPositionData>`): Position data notifier
- **builder** (`StackPositionWidgetBuilder`): Widget builder function
- **child** (`Widget?`): Optional child widget

### StackPositionData

Data class that holds position and size information for stack items.

```dart
@MappableClass()
class StackPositionData {
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
}
```

#### Properties

- **id** (`String`): Unique identifier
- **layer** (`int`): Z-index layer
- **offset** (`Offset`): Position in 2D space
- **width/height** (`double?`): Fixed dimensions
- **preferredWidth/preferredHeight** (`double?`): Preferred dimensions
- **keepAlive** (`bool`): Whether to keep widget alive when off-screen

#### Methods

- **calculateScaledOffset(double scaleFactor)**: Calculates the offset adjusted for scale
- **copyWith()**: Creates a copy with optional new values

### ZoomStackGestureDetector

Handles zoom and pan gestures for the boundless stack.

```dart
class ZoomStackGestureDetector extends StatefulWidget {
  const ZoomStackGestureDetector({
    Key? key,
    required this.scaleFactor,
    this.enableMoveByTouch = false,
    this.enableMoveByMouse = false,
    this.supportedDevices = const {...PointerDeviceKind.values},
    required this.stack,
    this.onScaleFactorChanged,
    this.onScaleStart,
    this.onScaleEnd,
  });
}
```

#### Properties

- **scaleFactor** (`ValueNotifier<double>`): Scale factor notifier
- **enableMoveByTouch** (`bool`): Whether to enable movement by touch
- **enableMoveByMouse** (`bool`): Whether to enable movement by mouse
- **supportedDevices** (`Set<PointerDeviceKind>`): Supported input devices
- **stack** (`BoundlessStack Function(...)`): Stack builder function
- **onScaleFactorChanged** (`Function(double)?`): Scale change callback
- **onScaleStart/onScaleEnd** (`VoidCallback?`): Scale event callbacks

## Delegates

### BoundlessStackDelegate

Abstract base class for providing children to the boundless stack.

```dart
abstract class BoundlessStackDelegate extends TwoDimensionalChildDelegate {
  BoundlessStackDelegate({
    required this.childrenBuilder,
    this.layerSorted = false,
  });
}
```

#### Properties

- **childrenBuilder** (`List<StackPosition> Function(Rect viewport)`): Function that builds children
- **layerSorted** (`bool`): Whether to sort children by layer

### BoundlessStackListDelegate

Concrete implementation that provides a static list of children.

```dart
class BoundlessStackListDelegate extends BoundlessStackDelegate {
  factory BoundlessStackListDelegate({
    bool layerSorted = false,
    required List<StackPosition> children,
  });
}
```

## Movement and Interaction

### StackMove

Configuration for item movement behavior.

```dart
class StackMove {
  const StackMove({this.snap});
  
  final StackSnap? snap;
}
```

### StackSnap

Defines snap-to-grid behavior.

```dart
class StackSnap {
  const StackSnap({
    required this.heightSnap,
    required this.widthSnap,
  });
  
  factory StackSnap.square({required double snap});
}
```

### StackResize

Configuration for item resizing behavior.

```dart
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
}
```

#### Properties

- **width/height** (`double?`): Fixed dimensions
- **preferredWidth/preferredHeight** (`double?`): Preferred dimensions
- **preferredOverFixedSize** (`bool`): Whether to prioritize preferred size
- **thumb** (`Widget?`): Resize handle widget
- **onSizeChanged** (`ValueChanged<Size>?`): Size change callback

## Background Builders

### gridBackgroundBuilder

Creates a grid background for the boundless stack.

```dart
TwoDimensionalViewportBuilder gridBackgroundBuilder({
  required double gridThickness,
  required double gridWidth,
  required double gridHeight,
  required Color gridColor,
  required ValueNotifier<double> scaleFactor,
});
```

#### Parameters

- **gridThickness** (`double`): Thickness of grid lines
- **gridWidth/gridHeight** (`double`): Size of grid cells
- **gridColor** (`Color`): Color of grid lines
- **scaleFactor** (`ValueNotifier<double>`): Current scale factor

## Type Definitions

```dart
typedef StackPositionWidgetBuilder = Widget Function(
  BuildContext context,
  ValueNotifier<StackPositionData> notifier,
  Widget? child,
);

typedef TwoDimensionalViewportBuilder = Widget Function(
  BuildContext context,
  ViewportOffset horizontalOffset,
  ViewportOffset verticalOffset,
);
```

## Usage Patterns

### Basic Setup

```dart
BoundlessStack(
  scaleFactor: scaleNotifier,
  delegate: BoundlessStackListDelegate(
    children: stackPositions,
  ),
  horizontalDetails: ScrollableDetails.horizontal(),
  verticalDetails: ScrollableDetails.vertical(),
)
```

### With Zoom Gestures

```dart
ZoomStackGestureDetector(
  scaleFactor: scaleNotifier,
  stack: (key, scaleFactor) => BoundlessStack(
    key: key,
    scaleFactor: scaleFactor,
    delegate: BoundlessStackListDelegate(
      children: stackPositions,
    ),
  ),
)
```

### Moveable Items

```dart
StackPosition(
  moveable: StackMove(
    snap: StackSnap.square(snap: 50.0),
  ),
  // ... other properties
)
```

### Resizable Items

```dart
StackPosition(
  resizable: StackResize(
    width: 200,
    height: 200,
    preferredWidth: 200,
    preferredHeight: 200,
    thumb: Container(
      width: 20,
      height: 20,
      color: Colors.blue,
    ),
  ),
  // ... other properties
)
```

### Custom Background

```dart
BoundlessStack(
  backgroundBuilder: gridBackgroundBuilder(
    gridWidth: 100,
    gridHeight: 100,
    gridColor: Colors.grey,
    gridThickness: 1.0,
    scaleFactor: scaleNotifier,
  ),
  // ... other properties
)
```

### Layer-Based Rendering

```dart
BoundlessStackListDelegate(
  layerSorted: true,
  children: [
    StackPosition(
      notifier: ValueNotifier(StackPositionData(
        id: 'background',
        layer: 0,
        offset: Offset.zero,
      )),
      // ... other properties
    ),
    StackPosition(
      notifier: ValueNotifier(StackPositionData(
        id: 'foreground',
        layer: 1,
        offset: Offset(100, 100),
      )),
      // ... other properties
    ),
  ],
)
```