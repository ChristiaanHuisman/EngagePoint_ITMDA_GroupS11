import 'dart:math';
import 'package:flutter/material.dart';
import '../models/rewards_data.dart';

class WheelPainter extends CustomPainter {
  final List<RewardItem> rewards;

  WheelPainter(this.rewards);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double segmentAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final Paint paint = Paint()..color = rewards[i].color;
      
      // THE FIX: This calculation ensures the middle of the first segment (index 0) is at the top.
      final double startAngle = (i * segmentAngle) - (pi / 2) - (segmentAngle / 2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      final double segmentCenterAngle = startAngle + segmentAngle / 2;
      canvas.rotate(segmentCenterAngle);

      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      const TextStyle textStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      );

      textPainter.text = TextSpan(
        text: rewards[i].name,
        style: textStyle,
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(radius * 0.6 - textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return oldDelegate.rewards != rewards;
  }
}