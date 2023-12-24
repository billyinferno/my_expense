import 'dart:math';
import 'package:flutter/material.dart';

class PieChartPainter extends CustomPainter {
  final Color backgroundColor;
  final List<Color> chartColors;
  final List<double> chartAmount;

  PieChartPainter({required this.backgroundColor, required this.chartColors, required this.chartAmount});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);

    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width / 2;

    double startRadian = -pi / 2;

    double totalAmount = 0;
    chartAmount.forEach((amt) { totalAmount += amt; });

    for(int index = 0; index < chartAmount.length; index++) {
      // for color we need to see, which one is bigger?
      // if we have less color compare to the amount, then we can use same color
      // for 2 amount.
      if(chartColors.length < chartAmount.length) {
        paint.color = chartColors[index % chartColors.length];
      }
      else {
        paint.color = chartColors[index % chartAmount.length];
      }
      double sweepRadian = chartAmount[index] / totalAmount * 2 * pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startRadian, sweepRadian, true, paint);
      startRadian += sweepRadian;
    }

    Paint paintCenter = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width / 4;
    paintCenter.color = backgroundColor;
    double radiusCenter = radius / 2;
    canvas.drawCircle(center, radiusCenter, paintCenter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}