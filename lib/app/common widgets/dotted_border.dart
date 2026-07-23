import 'package:flutter/material.dart';

class DottedBorderWrapper extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;
  final EdgeInsets padding;

  const DottedBorderWrapper({
    super.key,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 1.2,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.borderRadius = 6,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(
        color: color ?? const Color(0xFFC7CCD1),
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DottedBorderPainter({
    required this.color,
    this.backgroundColor,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Fill background if provided
    if (backgroundColor != null) {
      final fillPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw dashed rectangle
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
    final dashPath = Path();

    double distance = 0.0;
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
