import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AnimatedBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  AnimatedBorderPainter({
    required this.animation,
    required this.color,
    this.strokeWidth = 4.0,
    this.borderRadius = 20.0,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Tạo một đường dẫn hình chữ nhật bo góc
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    // Phân tích đường dẫn để lấy các thông số như độ dài
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    final ui.PathMetric pathMetric = pathMetrics.first;

    // Độ dài của đoạn thẳng động (ví dụ: 1/4 chu vi)
    final double segmentLength = pathMetric.length / 4;
    // Vị trí bắt đầu của đoạn thẳng, dựa trên tiến trình animation
    final double start = pathMetric.length * animation.value;
    // Vị trí kết thúc của đoạn thẳng
    final double end = (start + segmentLength) % pathMetric.length;

    // Trích xuất và vẽ đoạn đường dẫn động
    final Path animatedPath = pathMetric.extractPath(start, end);
    
    // Nếu đoạn thẳng đi qua điểm nối (quay về đầu), cần vẽ thêm phần còn lại
    if (start + segmentLength > pathMetric.length) {
      final Path remainingPath = pathMetric.extractPath(0, (start + segmentLength) % pathMetric.length);
      animatedPath.addPath(remainingPath, Offset.zero);
    }

    canvas.drawPath(animatedPath, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedBorderPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}