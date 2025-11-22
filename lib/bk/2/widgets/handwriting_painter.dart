import 'package:flutter/material.dart';

/// 手寫板的畫筆，負責把 points 畫在畫布上
class HandwritingPainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;

  const HandwritingPainter({
    required this.points,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    Offset? previousPoint;
    for (final p in points) {
      if (p != null && previousPoint != null) {
        canvas.drawLine(previousPoint!, p, paint);
      }
      previousPoint = p;
    }
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    // points 或線條粗細有變就重畫
    return oldDelegate.points != points ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

