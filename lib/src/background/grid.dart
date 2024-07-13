import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

TwoDimensionalViewportBuilder gridBackgroundBuilder({
  required double gridThickness,
  required double gridWidth,
  required double gridHeight,
  required Color gridColor,
  required double scaleFactor,
}) {
  return (context, horizontalOffset, verticalOffset) {
    return CustomPaint(
      painter: _GridPainter(
          gridThickness: gridThickness,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          gridColor: gridColor,
          scaleFactor: scaleFactor,
          horizontalOffset: horizontalOffset,
          verticalOffset: verticalOffset),
    );
  };
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.gridThickness,
    required this.gridWidth,
    required this.gridHeight,
    required this.gridColor,
    required this.scaleFactor,
    required this.horizontalOffset,
    required this.verticalOffset,
  });

  final double gridThickness;
  late final double scaledGridThickness = gridThickness * scaleFactor;
  final double gridWidth;
  late final double scaledGridWidth = gridWidth * scaleFactor;
  final double gridHeight;
  late final double scaledGridHeight = gridHeight * scaleFactor;
  final Color gridColor;
  final double scaleFactor;

  final ViewportOffset horizontalOffset;
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

    for (var x = -1; x < size.width / scaledGridWidth + 1; x++) {
      final xPosition = x * scaledGridWidth - topLeft.dx;
      canvas.drawLine(
        Offset(xPosition, 0),
        Offset(xPosition, size.height),
        paint,
      );
    }

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
