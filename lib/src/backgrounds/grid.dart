import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Creates a grid background builder for a [BoundlessStack].
///
/// This function returns a builder that creates a grid background with customizable
/// properties. The grid adjusts automatically to the current scale factor and
/// viewport position.
///
/// ## Parameters
///
/// * [gridThickness] - The thickness of the grid lines.
/// * [gridWidth] - The width of each grid cell.
/// * [gridHeight] - The height of each grid cell.
/// * [gridColor] - The color of the grid lines.
/// * [scaleFactor] - A notifier for the current scale factor.
///
/// ## Example
///
/// ```dart
/// BoundlessStack(
///   backgroundBuilder: gridBackgroundBuilder(
///     gridThickness: 1.0,
///     gridWidth: 100,
///     gridHeight: 100,
///     gridColor: Colors.grey,
///     scaleFactor: scaleNotifier,
///   ),
///   // ... other properties
/// )
/// ```
TwoDimensionalViewportBuilder gridBackgroundBuilder({
  required double gridThickness,
  required double gridWidth,
  required double gridHeight,
  required Color gridColor,
  required ValueNotifier<double> scaleFactor,
}) {
  return (context, horizontalOffset, verticalOffset) {
    return ListenableBuilder(
      listenable: scaleFactor,
      builder: (context, child) {
        if (scaleFactor.value < 0.05) return const SizedBox.shrink();

        return CustomPaint(
          painter: _GridPainter(
              gridThickness: gridThickness,
              gridWidth: gridWidth,
              gridHeight: gridHeight,
              gridColor: gridColor,
              scaleFactor: scaleFactor.value,
              horizontalOffset: horizontalOffset,
              verticalOffset: verticalOffset),
        );
      },
    );
  };
}

/// A custom painter that draws a grid background.
///
/// This painter draws horizontal and vertical lines to create a grid pattern.
/// The grid adjusts to the current scale factor and viewport position.
class _GridPainter extends CustomPainter {
  /// Creates a grid painter.
  ///
  /// All parameters are required.
  _GridPainter({
    required this.gridThickness,
    required this.gridWidth,
    required this.gridHeight,
    required this.gridColor,
    required this.scaleFactor,
    required this.horizontalOffset,
    required this.verticalOffset,
  });

  /// The thickness of the grid lines.
  final double gridThickness;

  /// The thickness of the grid lines adjusted for the current scale factor.
  late final double scaledGridThickness = gridThickness * scaleFactor;

  /// The width of each grid cell.
  final double gridWidth;

  /// The width of each grid cell adjusted for the current scale factor.
  late final double scaledGridWidth = gridWidth * scaleFactor;

  /// The height of each grid cell.
  final double gridHeight;

  /// The height of each grid cell adjusted for the current scale factor.
  late final double scaledGridHeight = gridHeight * scaleFactor;

  /// The color of the grid lines.
  final Color gridColor;

  /// The current scale factor.
  final double scaleFactor;

  /// The horizontal viewport offset.
  final ViewportOffset horizontalOffset;

  /// The vertical viewport offset.
  final ViewportOffset verticalOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = scaledGridThickness;

    var topLeft = Offset(
      horizontalOffset.pixels,
      verticalOffset.pixels,
    );

    final closestTopLeft = Offset(
      (topLeft.dx / scaledGridWidth).ceil() * scaledGridWidth,
      (topLeft.dy / scaledGridHeight).ceil() * scaledGridHeight,
    );

    topLeft = topLeft - closestTopLeft;

    // Draw vertical grid lines
    for (var x = -1; x < size.width / scaledGridWidth + 1; x++) {
      final xPosition = x * scaledGridWidth - topLeft.dx;
      canvas.drawLine(
        Offset(xPosition, 0),
        Offset(xPosition, size.height),
        paint,
      );
    }

    // Draw horizontal grid lines
    for (var y = -1; y < size.height / scaledGridHeight + 1; y++) {
      final yPosition = y * scaledGridHeight - topLeft.dy;
      canvas.drawLine(
        Offset(0, yPosition),
        Offset(size.width, yPosition),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return true;
  }
}
