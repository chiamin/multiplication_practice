import 'package:flutter/material.dart';

/// 手寫板的畫筆，負責把 points 畫在畫布上
class HandwritingPainter extends CustomPainter {
  final List<Offset?> points;

  HandwritingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    Offset? previousPoint;
    for (final p in points) {
      if (p != null && previousPoint != null) {
        canvas.drawLine(previousPoint, p, paint);
      }
      previousPoint = p;
    }
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    // 因為 points 的內容一直在變，直接重畫即可
    return true;
  }
}

