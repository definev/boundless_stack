# Boundless Stack Architecture

## Overview

This document describes the internal architecture of the Boundless Stack package, explaining how the various components work together to provide infinite scrolling and scaling capabilities.

## Code Organization

The package is organized into the following directory structure:

```
lib/
├── boundless_stack.dart       # Main library file
└── src/
    ├── backgrounds/           # Background builders
    │   └── grid.dart          # Grid background implementation
    ├── core/                  # Core components
    │   ├── boundless_stack.dart
    │   ├── boundless_stack_delegate.dart
    │   ├── boundless_stack_scroll_view.dart
    │   ├── boundless_stack_viewport.dart
    │   ├── render_boundless_stack_viewport.dart
    │   └── stack_position.dart
    ├── gestures/              # Gesture handling
    │   └── zoom_stack_gesture_detector.dart
    └── utils/                 # Utility classes
        └── vicinity_manager.dart
```

## Component Hierarchy

```
ZoomStackGestureDetector
├── BoundlessStack
    ├── BoundlessStackScrollView
    │   └── BoundlessStackViewport
    │       └── RenderBoundlessStackViewport
    └── Background/Foreground Builders
```

## Data Flow

1. **User Input** → ZoomStackGestureDetector
2. **Gesture Processing** → Scale/Pan calculations
3. **State Updates** → BoundlessStack state changes
4. **Viewport Updates** → BoundlessStackViewport rendering
5. **Child Management** → StackPosition widgets

## Key Components

### 1. ZoomStackGestureDetector

**Purpose**: Handles all user input gestures including zoom, pan, and scroll.

**Responsibilities**:
- Detect and process scale gestures (pinch-to-zoom)
- Handle mouse wheel zoom with Ctrl key
- Manage pan gestures for moving the viewport
- Coordinate with keyboard input for modifier keys

**Key Methods**:
- `onScaleStart()`: Initialize scaling operation
- `onScaleUpdate()`: Update scale and viewport position
- `onScaleEnd()`: Finalize scaling operation

### 2. BoundlessStack

**Purpose**: Main widget that orchestrates the infinite scrollable area.

**Responsibilities**:
- Manage scroll controllers for both axes
- Coordinate background/foreground rendering
- Handle scale factor changes
- Provide viewport configuration

**State Management**:
- Maintains horizontal and vertical scroll controllers
- Listens to scale factor changes
- Manages scroll behavior overrides during gestures

### 3. BoundlessStackDelegate

**Purpose**: Abstract interface for providing children to the stack.

**Implementations**:
- `BoundlessStackListDelegate`: Static list of children
- Custom delegates can be created for dynamic content

**Key Features**:
- Layer-based sorting support
- Viewport-aware child building
- Efficient child management

### 4. StackPosition

**Purpose**: Individual positioned widget within the stack.

**Capabilities**:
- Movement with optional snap-to-grid
- Resizing with custom handles
- Scale-aware rendering
- Keep-alive functionality

**Interaction Handling**:
- Pan gestures for movement
- Resize gestures with custom thumbs
- Automatic state management

## Rendering Pipeline

### 1. Viewport Calculation

```dart
// Calculate visible area based on scroll positions and scale
Rect viewport = Rect.fromLTWH(
  horizontalOffset / scaleFactor,
  verticalOffset / scaleFactor,
  viewportWidth / scaleFactor,
  viewportHeight / scaleFactor,
);
```

### 2. Child Culling

The system determines which children are visible or near-visible based on:
- Current viewport bounds
- Cache extent settings
- Child positions and sizes

### 3. Layer Management

Children are rendered in layer order:
1. Background builder (if provided)
2. Stack children (sorted by layer)
3. Foreground builder (if provided)

### 4. Transform Application

Each child receives appropriate transforms:
- Scale transformation based on current zoom level
- Position transformation based on viewport offset
- Hit-test adjustments for interaction

## Memory Management

### Efficient Rendering

- **Viewport Culling**: Only visible items are rendered
- **Cache Extent**: Configurable pre-rendering of nearby items
- **Keep Alive**: Optional persistent rendering for specific items

### State Management

- **ValueNotifier Pattern**: Efficient reactive updates
- **Automatic Disposal**: Proper cleanup of listeners and controllers
- **Minimal Rebuilds**: Targeted updates using RepaintBoundary

## Coordinate Systems

### 1. World Coordinates

The infinite 2D space where items are positioned:
- Origin at (0, 0)
- Unlimited bounds in all directions
- Item positions stored in world coordinates

### 2. Viewport Coordinates

The visible area on screen:
- Affected by scroll position
- Scaled by zoom factor
- Used for rendering calculations

### 3. Screen Coordinates

Final pixel positions on device:
- Result of world → viewport → screen transformations
- Used for hit testing and gesture handling

## Performance Optimizations

### 1. Lazy Loading

- Children built only when needed
- Delegate pattern allows for dynamic content
- Efficient memory usage for large datasets

### 2. Gesture Optimization

- Hardware-accelerated transformations
- Minimal state updates during gestures
- Efficient coordinate calculations

### 3. Rendering Optimizations

- RepaintBoundary usage to isolate repaints
- Custom painters for backgrounds
- Efficient layer management

## Extension Points

### Custom Delegates

Implement `BoundlessStackDelegate` for:
- Dynamic content loading
- Database-backed items
- Infinite procedural generation

### Custom Backgrounds

Implement `TwoDimensionalViewportBuilder` for:
- Custom grid patterns
- Image backgrounds
- Dynamic visual effects

### Custom Gestures

Extend gesture handling for:
- Multi-touch interactions
- Custom input devices
- Specialized interaction patterns

## Thread Safety

The package is designed for single-threaded use within Flutter's main isolate:
- All state changes occur on the main thread
- Gesture handling is synchronous
- Background computations should use separate isolates

## Testing Strategy

### Unit Tests
- Individual component behavior
- Coordinate transformations
- State management logic

### Widget Tests
- User interaction scenarios
- Gesture handling
- Visual rendering

### Integration Tests
- End-to-end workflows
- Performance characteristics
- Memory usage patterns