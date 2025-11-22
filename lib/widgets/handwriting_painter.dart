import 'package:flutter/material.dart';

/// 手寫板的畫筆，負責把 points 畫在畫布上
///
/// points 的格式：
/// - 每個 Offset 代表一個手寫軌跡上的點
/// - 用 null 分隔不同的筆畫（stroke）
///
/// 例如： [p1, p2, p3, null, p4, p5] 代表兩筆：
/// 1. p1 -> p2 -> p3
/// 2. p4 -> p5
class HandwritingPainter extends CustomPainter {
  /// 所有筆畫的點，使用 Offset? + null 分隔
  final List<Offset?> points;

  /// 筆跡顏色（如果外部沒有特別指定，預設為黑色）
  final Color color;

  /// 筆跡粗細
  final double strokeWidth;

  HandwritingPainter(
    this.points, {
    this.color = Colors.black,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path();
    final List<Offset> isolatedDots = [];

    Offset? lastPoint;
    bool currentStrokeHasMovement = false;

    for (final p in points) {
      if (p == null) {
        // 一筆結束：如果這一筆只有一個點，當成「點」來畫
        if (lastPoint != null && !currentStrokeHasMovement) {
          isolatedDots.add(lastPoint);
        }
        lastPoint = null;
        currentStrokeHasMovement = false;
        continue;
      }

      if (lastPoint == null) {
        // 新的一筆開始
        path.moveTo(p.dx, p.dy);
        lastPoint = p;
        currentStrokeHasMovement = false;
      } else {
        // 使用二次貝茲曲線平滑連線：lastPoint -> midPoint -> p
        currentStrokeHasMovement = true;
        final midPoint = Offset(
          (lastPoint.dx + p.dx) / 2,
          (lastPoint.dy + p.dy) / 2,
        );
        path.quadraticBezierTo(
          lastPoint.dx,
          lastPoint.dy,
          midPoint.dx,
          midPoint.dy,
        );
        lastPoint = p;
      }
    }

    // 如果最後一筆只點了一下沒有移動，也要把它當成點
    if (lastPoint != null && !currentStrokeHasMovement) {
      isolatedDots.add(lastPoint);
    }

    // 先畫所有平滑過的筆畫
    canvas.drawPath(path, paint);

    // 再補畫「單點」的情況（例如輕點一下）
    if (isolatedDots.isNotEmpty) {
      for (final dot in isolatedDots) {
        canvas.drawCircle(dot, strokeWidth / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    // 通常外部是用「同一個 List，不斷增加/修改內容」來更新 points，
    // 為了確保畫面即時更新，這裡直接回傳 true。
    // 若未來改成每次都給新的 List，可再優化成比較內容。
    return true;
  }
}

