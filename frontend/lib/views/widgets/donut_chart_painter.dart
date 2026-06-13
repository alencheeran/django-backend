import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutChartPainter extends CustomPainter {
  final Map<String, double> assetValues;
  final List<Color> colors;
  final bool isDark;

  DonutChartPainter({
    required this.assetValues,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = assetValues.values.fold(0.0, (sum, val) => sum + val);
    if (total <= 0.0) return;

    final double width = size.width;
    final double height = size.height;
    final double center = math.min(width, height) / 2;
    final Offset centerOffset = Offset(width / 2, height / 2);

    final double radius = center - 20.0;
    final Rect rect = Rect.fromCircle(center: centerOffset, radius: radius);

    double startAngle = -math.pi / 2; // Start at the top (12 o'clock)
    int index = 0;

    for (var entry in assetValues.entries) {
      final double value = entry.value;
      if (value <= 0.0) continue;

      final double sweepAngle = (value / total) * 2 * math.pi;
      
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22.0
        ..strokeCap = StrokeCap.round // Rounded segments
        ..color = colors[index % colors.length];

      // Draw the arc segment with a slight gap for aesthetic spacing
      final double gapAngle = 0.06; // Spacing gap
      if (sweepAngle > gapAngle * 2) {
        canvas.drawArc(
          rect,
          startAngle + gapAngle,
          sweepAngle - (gapAngle * 2),
          false,
          paint,
        );
      } else {
        canvas.drawArc(
          rect,
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }

      startAngle += sweepAngle;
      index++;
    }

    // Draw central details label
    final textPainter = TextPainter(
      text: TextSpan(
        text: "Asset\nAllocation",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerOffset.dx - (textPainter.width / 2),
        centerOffset.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.assetValues != assetValues ||
        oldDelegate.colors != colors ||
        oldDelegate.isDark != isDark;
  }
}
